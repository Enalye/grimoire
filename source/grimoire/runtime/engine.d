/**
    Grimoire virtual machine.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.runtime.engine;

import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.math;

import grimoire.core.indexedarray;
import grimoire.compiler;
import grimoire.assembly;
import grimoire.runtime.context;
import grimoire.runtime.dynamic;
import grimoire.runtime.array;
import grimoire.runtime.object;

/** Grimoire virtual machine */
class GrEngine {
    private {
        /// Opcodes.
        immutable(uint)[] _opcodes;
        /// Integral constants.
        immutable(int)[] _iconsts;
        /// Floating point constants.
        immutable(float)[] _fconsts;
        /// String constants.
        immutable(dstring)[] _sconsts;
        /// Events
        uint[dstring] _events;

        /// Global integral variables.
        int* _iglobals;
        /// Global floating point variables.
        float* _fglobals;
        /// Global string variables.
        dstring* _sglobals;
        GrDynamicValue[]* _nglobals;
        GrDynamicValue* _aglobals;
        GrObjectValue* _oglobals;
        void** _uglobals;



        /// Global integral stack.
        int[] _iglobalStack;
        /// Global floating point stack.
        float[] _fglobalStack;
        /// Global string stack.
        dstring[] _sglobalStack;
        /// Global array stack.
        GrDynamicValue[][] _nglobalStack;
        /// Global dynamic value stack.
        GrDynamicValue[] _aglobalStack;
        /// Global object stack.
        GrObjectValue[] _oglobalStack;
        /// Global user data stack.
        void*[] _uglobalStack;

        /// Context array.
	    DynamicIndexedArray!GrContext _contexts;
    
        /// Global panic state.
        /// It means that the throwing context didn't handle the exception.
        bool _isPanicking;
        /// Unhandled panic message.
        dstring _panicMessage;

        /// Extra type compiler information.
        dstring _meta;
    }

    __gshared bool isRunning = true;

    @property {
        /// Check if there is a coroutine currently running.
        bool hasCoroutines() const { return _contexts.length > 0uL; }

        /// Whether the whole VM has panicked, true if an unhandled error occurred.
        bool isPanicking() const { return _isPanicking; }

        /// The unhandled error message.
        dstring panicMessage() const { return _panicMessage; }

        /// Extra type compiler information.
        dstring meta() const { return _meta; }
        dstring meta(dstring newMeta) { return _meta = newMeta; }
    }

    /// Default.
	this() {
        setupGlobals(512);
        _contexts = new DynamicIndexedArray!GrContext;
    }

    /// Load the bytecode.
	this(GrBytecode bytecode) {
		load(bytecode);
	}

    /// Load the bytecode.
	void load(GrBytecode bytecode) {
		_iconsts = bytecode.iconsts.idup;
		_fconsts = bytecode.fconsts.idup;
		_sconsts = bytecode.sconsts.idup;
		_opcodes = bytecode.opcodes.idup;
        _events = bytecode.events;
	}

    /// Current max global variable available.
    private uint _globalsLimit;

    /// Initialize the global variable stacks.
    void setupGlobals(uint size) {
        _globalsLimit = size;
        _iglobals = (new int[_globalsLimit]).ptr;
        _fglobals = (new float[_globalsLimit]).ptr;
        _sglobals = (new dstring[_globalsLimit]).ptr;
        _nglobals = (new GrDynamicValue[][_globalsLimit]).ptr;
        _aglobals = (new GrDynamicValue[_globalsLimit]).ptr;
        _oglobals = (new GrObjectValue[_globalsLimit]).ptr;
        _uglobals = (new void*[_globalsLimit]).ptr;
    }

    /**
        Create the main context.
        You must call this function before running the vm.
    */
    void spawn() {
		_contexts.push(new GrContext(this));
	}

    bool hasEvent(dstring eventName) {
        return (eventName in _events) !is null;
    }

    GrContext spawnEvent(dstring eventName) {
        auto event = eventName in _events;
        if(event is null)
            throw new Exception("No event \'" ~ to!string(eventName) ~ "\' in script");
        GrContext context = new GrContext(this);
        context.pc = *event;
        _contexts.push(context);
        return context;
    }

    package(grimoire) void pushContext(GrContext context) {
        _contexts.push(context);
    }

    /**
        Captures an unhandled error and kill the VM.
    */
    void panic() {
        _contexts.reset();
    }

    void raise(GrContext context, dstring message) {
        if(context.isPanicking)
            return;
        //Error message.
        _sglobalStack ~= message;
        
        //We indicate that the coroutine is in a panic state until a catch is found.
        context.isPanicking = true;
        
        //Exception handler found in the current function, just jump.
        if(context.exceptionHandlers[context.exceptionHandlersPos].length) {
            context.pc = context.exceptionHandlers[context.exceptionHandlersPos][$ - 1];
        }
        //No exception handler in the current function, unwinding the deferred code, then return.
        
        //Check for deferred calls as we will exit the current function.
        else if(context.deferStack[context.deferPos].length) {
            //Pop the last defer and run it.
            context.pc = context.deferStack[context.deferPos][$ - 1];
            context.deferStack[context.deferPos].length --;
            //The search for an exception handler will be done by Unwind after all defer
            //has been called for this function.
        }
        else if(context.stackPos) {
            //Pop the defer scope.
            context.deferPos --;

            //Pop the exception handlers as well.
            context.exceptionHandlersPos --;

            //Then returns to the last context, raise will be run again.
            context.stackPos -= 2;
            context.localsPos -= context.callStack[context.stackPos];
        }
        else {
            //Kill the others.
            foreach(coroutine; _contexts) {
                coroutine.pc = cast(uint)(_opcodes.length - 1);
                coroutine.isKilled = true;
            }

            //The VM is now panicking.
            _isPanicking = true;
            _panicMessage = _sglobalStack[$ - 1];
            _sglobalStack.length --;
        }
    }

    /// Run the vm until all the contexts are finished or in yield.
	void process() {
		contextsLabel: for(uint index = 0u; index < _contexts.length; index ++) {
			GrContext context = _contexts.data[index];
			while(isRunning) {
				uint opcode = _opcodes[context.pc];
				switch (grGetInstructionOpcode(opcode)) with(GrOpcode) {
                case Nop:
                    context.pc ++;
                    break;
                case Raise:
                    if(!context.isPanicking) {
                        //Error message.
                        _sglobalStack ~= context.sstack[context.sstackPos];
                        context.sstackPos --;

                        //We indicate that the coroutine is in a panic state until a catch is found.
                        context.isPanicking = true;
                    }

                    //Exception handler found in the current function, just jump.
                    if(context.exceptionHandlers[context.exceptionHandlersPos].length) {
                        context.pc = context.exceptionHandlers[context.exceptionHandlersPos][$ - 1];
                    }
                    //No exception handler in the current function, unwinding the deferred code, then return.
                    
                    //Check for deferred calls as we will exit the current function.
                    else if(context.deferStack[context.deferPos].length) {
                        //Pop the last defer and run it.
                        context.pc = context.deferStack[context.deferPos][$ - 1];
                        context.deferStack[context.deferPos].length --;
                        //The search for an exception handler will be done by Unwind after all defer
                        //has been called for this function.
                    }
                    else if(context.stackPos) {
                        //Pop the defer scope.
                        context.deferPos --;

                        //Pop the exception handlers as well.
                        context.exceptionHandlersPos --;

                        //Then returns to the last context, raise will be run again.
                        context.stackPos -= 2;
                        context.localsPos -= context.callStack[context.stackPos];
                    }
                    else {
                        //Kill the others.
                        foreach(coroutine; _contexts) {
                            coroutine.pc = cast(uint)(_opcodes.length - 1);
                            coroutine.isKilled = true;
                        }

                        //The VM is now panicking.
                        _isPanicking = true;
                        _panicMessage = _sglobalStack[$ - 1];
                        _sglobalStack.length --;

                        //Every deferred call has been executed, now die.
                        _contexts.markInternalForRemoval(index);
                        continue contextsLabel;
                    }
                    break;
                case Try:
                    context.exceptionHandlers[context.exceptionHandlersPos] ~= context.pc + grGetInstructionSignedValue(opcode);
                    context.pc ++;
                    break;
                case Catch:
                    context.exceptionHandlers[context.exceptionHandlersPos].length --;
                    if(context.isPanicking) {
                        context.isPanicking = false;
                        context.pc ++;
                    }
                    else {
                        context.pc += grGetInstructionSignedValue(opcode);
                    }
                    break;
				case Task:
					GrContext newCoro = new GrContext(this);
					newCoro.pc = grGetInstructionUnsignedValue(opcode);
					_contexts.push(newCoro);
					context.pc ++;
					break;
				case AnonymousTask:
					GrContext newCoro = new GrContext(this);
					newCoro.pc = context.istack[context.istackPos];
					context.istackPos --;
					_contexts.push(newCoro);
					context.pc ++;
					break;
				case Kill:
                    //Check for deferred calls.
                    if(context.deferStack[context.deferPos].length) {
                        //Pop the last defer and run it.
                        context.pc = context.deferStack[context.deferPos][$ - 1];
                        context.deferStack[context.deferPos].length --;

                        //Flag as killed so the entire stack will be unwinded.
                        context.isKilled = true;
                    }
                    else if(context.stackPos) {
                        //Pop the defer scope.
                        context.deferPos --;

                        //Then returns to the last context.
                        context.stackPos -= 2;
                        context.pc = context.callStack[context.stackPos + 1u];
                        context.localsPos -= context.callStack[context.stackPos];

                        //Flag as killed so the entire stack will be unwinded.
                        context.isKilled = true;
                    }
                    else {
                        //No need to flag if the call stac is empty without any deferred statement.
                        _contexts.markInternalForRemoval(index);
					    continue contextsLabel;
                    }
					break;
				case Yield:
					context.pc ++;
					continue contextsLabel;
                case New:
                    context.ustackPos ++;
					context.ustack[context.ustackPos] = cast(void*)new GrObjectValue(grGetInstructionUnsignedValue(opcode));
					context.pc ++;
                    break;
				case ShiftStack_Int:
					context.istackPos += grGetInstructionSignedValue(opcode);
					context.pc ++;
					break;
				case ShiftStack_Float:
					context.fstackPos += grGetInstructionSignedValue(opcode);
					context.pc ++;
					break;
				case ShiftStack_String:
					context.sstackPos += grGetInstructionSignedValue(opcode);
					context.pc ++;
					break;
                case ShiftStack_Array:
					context.nstackPos += grGetInstructionSignedValue(opcode);
					context.pc ++;
					break;
				case ShiftStack_Any:
					context.astackPos += grGetInstructionSignedValue(opcode);
					context.pc ++;
					break;
                case ShiftStack_UserData:
					context.ustackPos += grGetInstructionSignedValue(opcode);
					context.pc ++;
					break;
				case LocalStore_Int:
					context.ilocals[context.localsPos + grGetInstructionUnsignedValue(opcode)] = context.istack[context.istackPos];
                    context.istackPos --;	
					context.pc ++;
					break;
				case LocalStore_Float:
					context.flocals[context.localsPos + grGetInstructionUnsignedValue(opcode)] = context.fstack[context.fstackPos];
                    context.fstackPos --;	
					context.pc ++;
					break;
				case LocalStore_String:
					context.slocals[context.localsPos + grGetInstructionUnsignedValue(opcode)] = context.sstack[context.sstackPos];		
                    context.sstackPos --;	
					context.pc ++;
					break;
                case LocalStore_Array:
					context.nlocals[context.localsPos + grGetInstructionUnsignedValue(opcode)] = context.nstack[context.nstackPos];		
                    context.nstackPos --;	
					context.pc ++;
					break;
				case LocalStore_Any:
					context.alocals[context.localsPos + grGetInstructionUnsignedValue(opcode)] = context.astack[context.astackPos];
                    context.astackPos --;	
					context.pc ++;
					break;
                case LocalStore_Ref:
                    context.astack[context.astackPos - 1].setRef(context, context.astack[context.astackPos]);
                    context.astackPos -= 2;
                    context.pc ++;
                    break;
                case LocalStore_UserData:
					context.ulocals[context.localsPos + grGetInstructionUnsignedValue(opcode)] = context.ustack[context.ustackPos];
                    context.ustackPos --;	
					context.pc ++;
					break;
                case LocalStore2_Int:
					context.ilocals[context.localsPos + grGetInstructionUnsignedValue(opcode)] = context.istack[context.istackPos];
					context.pc ++;
					break;
				case LocalStore2_Float:
					context.flocals[context.localsPos + grGetInstructionUnsignedValue(opcode)] = context.fstack[context.fstackPos];
					context.pc ++;
					break;
				case LocalStore2_String:
					context.slocals[context.localsPos + grGetInstructionUnsignedValue(opcode)] = context.sstack[context.sstackPos];		
					context.pc ++;
					break;
                case LocalStore2_Array:
					context.nlocals[context.localsPos + grGetInstructionUnsignedValue(opcode)] = context.nstack[context.nstackPos];		
					context.pc ++;
					break;
				case LocalStore2_Any:
					context.alocals[context.localsPos + grGetInstructionUnsignedValue(opcode)] = context.astack[context.astackPos];
					context.pc ++;
					break;
                case LocalStore2_Ref:
                    context.astackPos --;
                    context.astack[context.astackPos].setRef(context, context.astack[context.astackPos + 1]);
                    context.pc ++;
                    break;
                case LocalStore2_UserData:
					context.ulocals[context.localsPos + grGetInstructionUnsignedValue(opcode)] = context.ustack[context.ustackPos];
					context.pc ++;
					break;
				case LocalLoad_Int:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.ilocals[context.localsPos + grGetInstructionUnsignedValue(opcode)];
                    context.pc ++;
					break;
				case LocalLoad_Float:
                    context.fstackPos ++;
					context.fstack[context.fstackPos] = context.flocals[context.localsPos + grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
				case LocalLoad_String:
                    context.sstackPos ++;
					context.sstack[context.sstackPos] = context.slocals[context.localsPos + grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
                case LocalLoad_Array:
                    context.nstackPos ++;
					context.nstack[context.nstackPos] = context.nlocals[context.localsPos + grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
				case LocalLoad_Any:
                    context.astackPos ++;
					context.astack[context.astackPos] = context.alocals[context.localsPos + grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
                case LocalLoad_Ref:
                    GrDynamicValue value;
                    value.setRefArray(&context.nlocals[context.localsPos + grGetInstructionUnsignedValue(opcode)]);
                    context.astackPos ++;
                    context.astack[context.astackPos] = value;			
					context.pc ++;
					break;
                case LocalLoad_UserData:
                    context.ustackPos ++;
					context.ustack[context.ustackPos] = context.ulocals[context.localsPos + grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
                case GlobalStore_Int:
					_iglobals[grGetInstructionUnsignedValue(opcode)] = context.istack[context.istackPos];
                    context.istackPos --;	
					context.pc ++;
					break;
				case GlobalStore_Float:
					_fglobals[grGetInstructionUnsignedValue(opcode)] = context.fstack[context.fstackPos];
                    context.fstackPos --;	
					context.pc ++;
					break;
				case GlobalStore_String:
					_sglobals[grGetInstructionUnsignedValue(opcode)] = context.sstack[context.sstackPos];		
                    context.sstackPos --;	
					context.pc ++;
					break;
                case GlobalStore_Array:
					_nglobals[grGetInstructionUnsignedValue(opcode)] = context.nstack[context.nstackPos];		
                    context.nstackPos --;	
					context.pc ++;
					break;
				case GlobalStore_Any:
					_aglobals[grGetInstructionUnsignedValue(opcode)] = context.astack[context.astackPos];
                    context.astackPos --;	
					context.pc ++;
					break;
                case GlobalStore_Ref:
                    context.astack[context.astackPos - 1].setRef(context, context.astack[context.astackPos]);
                    context.astackPos -= 2;
                    context.pc ++;
                    break;
                case GlobalStore_UserData:
					_uglobals[grGetInstructionUnsignedValue(opcode)] = context.ustack[context.ustackPos];
                    context.ustackPos --;	
					context.pc ++;
					break;
                case GlobalStore2_Int:
					_iglobals[grGetInstructionUnsignedValue(opcode)] = context.istack[context.istackPos];
					context.pc ++;
					break;
				case GlobalStore2_Float:
					_fglobals[grGetInstructionUnsignedValue(opcode)] = context.fstack[context.fstackPos];
					context.pc ++;
					break;
				case GlobalStore2_String:
					_sglobals[grGetInstructionUnsignedValue(opcode)] = context.sstack[context.sstackPos];		
					context.pc ++;
					break;
                case GlobalStore2_Array:
					_nglobals[grGetInstructionUnsignedValue(opcode)] = context.nstack[context.nstackPos];		
					context.pc ++;
					break;
				case GlobalStore2_Any:
					_aglobals[grGetInstructionUnsignedValue(opcode)] = context.astack[context.astackPos];
					context.pc ++;
					break;
                case GlobalStore2_Ref:
                    context.astackPos --;
                    context.astack[context.astackPos].setRef(context, context.astack[context.astackPos + 1]);
                    context.pc ++;
                    break;
                case GlobalStore2_UserData:
					_uglobals[grGetInstructionUnsignedValue(opcode)] = context.ustack[context.ustackPos];
					context.pc ++;
					break;
				case GlobalLoad_Int:
                    context.istackPos ++;
					context.istack[context.istackPos] = _iglobals[grGetInstructionUnsignedValue(opcode)];
                    context.pc ++;
					break;
				case GlobalLoad_Float:
                    context.fstackPos ++;
					context.fstack[context.fstackPos] = _fglobals[grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
				case GlobalLoad_String:
                    context.sstackPos ++;
					context.sstack[context.sstackPos] = _sglobals[grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
                case GlobalLoad_Array:
                    context.nstackPos ++;
					context.nstack[context.nstackPos] = _nglobals[grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
				case GlobalLoad_Any:
                    context.astackPos ++;
					context.astack[context.astackPos] = _aglobals[grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
                case GlobalLoad_Ref:
                    GrDynamicValue value;
                    value.setRefArray(&_nglobals[grGetInstructionUnsignedValue(opcode)]);
                    context.astackPos ++;
                    context.astack[context.astackPos] = value;			
					context.pc ++;
					break;
                case GlobalLoad_UserData:
                    context.ustackPos ++;
					context.ustack[context.ustackPos] = _uglobals[grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
                case GetField:
					context.ustack[context.ustackPos] = cast(void*)((cast(GrObjectValue)context.ustack[context.ustackPos]).fields[grGetInstructionUnsignedValue(opcode)]);
					context.pc ++;
                    break;
                case FieldStore_Int:
                    (cast(GrFieldValue)context.ustack[context.ustackPos]).ivalue = context.istack[context.istackPos];
                    context.istackPos += grGetInstructionSignedValue(opcode);
                    context.ustackPos --;
					context.pc ++;
                    break;
                case FieldLoad_Int:
                    context.istackPos ++;
					context.istack[context.istackPos] = (cast(GrFieldValue)context.ustack[context.ustackPos]).ivalue;
                    context.ustackPos += grGetInstructionSignedValue(opcode);
					context.pc ++;
                    break;
				case Const_Int:
                    context.istackPos ++;
					context.istack[context.istackPos] = _iconsts[grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
				case Const_Float:
                    context.fstackPos ++;
					context.fstack[context.fstackPos] = _fconsts[grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
				case Const_Bool:
                    context.istackPos ++;
					context.istack[context.istackPos] = grGetInstructionUnsignedValue(opcode);
					context.pc ++;
					break;
				case Const_String:
                    context.sstackPos ++;
					context.sstack[context.sstackPos] = _sconsts[grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
                case Const_Meta:
					_meta = _sconsts[grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
                    break;
				case GlobalPush_Int:
					uint nbParams = grGetInstructionUnsignedValue(opcode);
					for(uint i = 1u; i <= nbParams; i++)
						_iglobalStack ~= context.istack[(context.istackPos - nbParams) + i];
					context.istackPos -= nbParams;
					context.pc ++;
					break;
				case GlobalPush_Float:
					uint nbParams = grGetInstructionUnsignedValue(opcode);
					for(uint i = 1u; i <= nbParams; i++)
						_fglobalStack ~= context.fstack[(context.fstackPos - nbParams) + i];
					context.fstackPos -= nbParams;
					context.pc ++;
					break;
				case GlobalPush_String:
					uint nbParams = grGetInstructionUnsignedValue(opcode);
					for(uint i = 1u; i <= nbParams; i++)
						_sglobalStack ~= context.sstack[(context.sstackPos - nbParams) + i];
					context.sstackPos -= nbParams;
					context.pc ++;
					break;
                case GlobalPush_Array:
					uint nbParams = grGetInstructionUnsignedValue(opcode);
					for(uint i = 1u; i <= nbParams; i++)
						_nglobalStack ~= context.nstack[(context.nstackPos - nbParams) + i];
					context.nstackPos -= nbParams;
					context.pc ++;
					break;
				case GlobalPush_Any:
					uint nbParams = grGetInstructionUnsignedValue(opcode);
					for(uint i = 1u; i <= nbParams; i++)
						_aglobalStack ~= context.astack[(context.astackPos - nbParams) + i];
					context.astackPos -= nbParams;
					context.pc ++;
					break;
                case GlobalPush_UserData:
					uint nbParams = grGetInstructionUnsignedValue(opcode);
					for(uint i = 1u; i <= nbParams; i++)
						_uglobalStack ~= context.ustack[(context.ustackPos - nbParams) + i];
					context.ustackPos -= nbParams;
					context.pc ++;
					break;
				case GlobalPop_Int:
                    context.istackPos ++;
					context.istack[context.istackPos] = _iglobalStack[$ - 1];
					_iglobalStack.length --;
					context.pc ++;
					break;
				case GlobalPop_Float:
                    context.fstackPos ++;
					context.fstack[context.fstackPos] = _fglobalStack[$ - 1];
					_fglobalStack.length --;
					context.pc ++;
					break;
				case GlobalPop_String:
                    context.sstackPos ++;
					context.sstack[context.sstackPos] = _sglobalStack[$ - 1];
					_sglobalStack.length --;
					context.pc ++;
					break;
                case GlobalPop_Array:
                    context.nstackPos ++;
					context.nstack[context.nstackPos] = _nglobalStack[$ - 1];
					_nglobalStack.length --;
					context.pc ++;
					break;
				case GlobalPop_Any:
                    context.astackPos ++;
					context.astack[context.astackPos] = _aglobalStack[$ - 1];
					_aglobalStack.length --;
					context.pc ++;
					break;
                case GlobalPop_UserData:
                    context.ustackPos ++;
					context.ustack[context.ustackPos] = _uglobalStack[$ - 1];
					_uglobalStack.length --;
					context.pc ++;
					break;
				case Equal_Int:
                    context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] == context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case Equal_Float:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.fstack[context.fstackPos - 1] == context.fstack[context.fstackPos];
					context.fstackPos -= 2;
					context.pc ++;
					break;
				case Equal_String:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.sstack[context.sstackPos - 1] == context.sstack[context.sstackPos];
					context.sstackPos -= 2;
					context.pc ++;
					break;
				//Equal_Any
				case NotEqual_Int:
					context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] != context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case NotEqual_Float:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.fstack[context.fstackPos - 1] != context.fstack[context.fstackPos];
					context.fstackPos -= 2;
					context.pc ++;
					break;
				case NotEqual_String:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.sstack[context.sstackPos - 1] != context.sstack[context.sstackPos];
					context.sstackPos -= 2;
					context.pc ++;
					break;
				//NotEqual_Any
				case GreaterOrEqual_Int:
					context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] >= context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case GreaterOrEqual_Float:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.fstack[context.fstackPos - 1] >= context.fstack[context.fstackPos];
					context.fstackPos -= 2;
					context.pc ++;
					break;
					//Any
				case LesserOrEqual_Int:
					context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] <= context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case LesserOrEqual_Float:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.fstack[context.fstackPos - 1] <= context.fstack[context.fstackPos];
					context.fstackPos -= 2;
					context.pc ++;
					break;
					//any
				case GreaterInt:
					context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] > context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case GreaterFloat:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.fstack[context.fstackPos - 1] > context.fstack[context.fstackPos];
					context.fstackPos -= 2;
					context.pc ++;
					break;
					//any
				case LesserInt:
					context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] < context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case LesserFloat:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.fstack[context.fstackPos - 1] < context.fstack[context.fstackPos];
					context.fstackPos -= 2;
					context.pc ++;
					break;
					//any
				case AndInt:
					context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] && context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case OrInt:
					context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] || context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case NotInt:
					context.istack[context.istackPos] = !context.istack[context.istackPos];
					context.pc ++;
					break;
					//any
				case AddInt:
					context.istackPos --;
					context.istack[context.istackPos] += context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case AddFloat:
					context.fstackPos --;
					context.fstack[context.fstackPos] += context.fstack[context.fstackPos + 1];
					context.pc ++;
					break;
				case AddAny:
					context.astackPos --;
					context.astack[context.astackPos] += context.astack[context.astackPos + 1];
					context.pc ++;
					break;
				case ConcatenateString:
					context.sstackPos --;
					context.sstack[context.sstackPos] ~= context.sstack[context.sstackPos + 1];
					context.pc ++;
					break;
				case ConcatenateAny:
					context.astackPos --;
					context.astack[context.astackPos] ~= context.astack[context.astackPos + 1];
					context.pc ++;
					break;
				case SubstractInt:
					context.istackPos --;
					context.istack[context.istackPos] -= context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case SubstractFloat:
					context.fstackPos --;
					context.fstack[context.fstackPos] -= context.fstack[context.fstackPos + 1];
					context.pc ++;
					break;
				case SubstractAny:
					context.astackPos --;
					context.astack[context.astackPos] -= context.astack[context.astackPos + 1];
					context.pc ++;
					break;
				case MultiplyInt:
					context.istackPos --;
					context.istack[context.istackPos] *= context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case MultiplyFloat:
					context.fstackPos --;
					context.fstack[context.fstackPos] *= context.fstack[context.fstackPos + 1];
					context.pc ++;
					break;
				case MultiplyAny:
					context.astackPos --;
					context.astack[context.astackPos] *= context.astack[context.astackPos + 1];
					context.pc ++;
					break;
				case DivideInt:
					context.istackPos --;
					context.istack[context.istackPos] /= context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case DivideFloat:
					context.fstackPos --;
					context.fstack[context.fstackPos] /= context.fstack[context.fstackPos + 1];
					context.pc ++;
					break;
				case DivideAny:
					context.astackPos --;
					context.astack[context.astackPos] /= context.astack[context.astackPos + 1];
					context.pc ++;
					break;
				case RemainderInt:
					context.istackPos --;
					context.istack[context.istackPos] %= context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case RemainderFloat:
					context.fstackPos --;
					context.fstack[context.fstackPos] %= context.fstack[context.fstackPos + 1];
					context.pc ++;
					break;
				case RemainderAny:
					context.astackPos --;
					context.astack[context.astackPos] %= context.astack[context.astackPos + 1];
					context.pc ++;
					break;
				case NegativeInt:
					context.istack[context.istackPos] = -context.istack[context.istackPos];
					context.pc ++;
					break;
				case NegativeFloat:
					context.fstack[context.fstackPos] = -context.fstack[context.fstackPos];
					context.pc ++;
					break;
				case NegativeAny:
					context.astack[context.astackPos] = -context.astack[context.astackPos];
					context.pc ++;
					break;
				case IncrementInt:
					context.istack[context.istackPos] ++;
					context.pc ++;
					break;
				case IncrementFloat:
					context.fstack[context.fstackPos] += 1f;
					context.pc ++;
					break;
				case IncrementAny:
					context.astack[context.astackPos] ++;
					context.pc ++;
					break;
				case DecrementInt:
					context.istack[context.istackPos] --;
					context.pc ++;
					break;
				case DecrementFloat:
					context.fstack[context.fstackPos] -= 1f;
					context.pc ++;
					break;
				case DecrementAny:
					context.astack[context.astackPos] --;
					context.pc ++;
					break;
				case SetupIterator:
					if(context.istack[context.istackPos] < 0)
						context.istack[context.istackPos] = 0;
					context.istack[context.istackPos] ++;
					context.pc ++;
					break;
				case Return:
                    //If another task was killed by an exception,
                    //we might end up there if the task has just been spawned.
                    if(!context.deferPos && context.isKilled) {
                        _contexts.markInternalForRemoval(index);
					    continue contextsLabel;
                    }
                    //Check for deferred calls.
                    else if(context.deferStack[context.deferPos].length) {
                        //Pop the last defer and run it.
                        context.pc = context.deferStack[context.deferPos][$ - 1];
                        context.deferStack[context.deferPos].length --;
                    }
                    else {
                        //Pop the defer scope.
                        context.deferPos --;

                        //Pop the exception handlers as well.
                        context.exceptionHandlersPos --;

                        //Then returns to the last context.
                        context.stackPos -= 2;
                        context.pc = context.callStack[context.stackPos + 1u];
                        context.localsPos -= context.callStack[context.stackPos];
                    }
					break;
                case Unwind:
                    //If another task was killed by an exception,
                    //we might end up there if the task has just been spawned.
                    if(!context.deferPos) {
                        _contexts.markInternalForRemoval(index);
					    continue contextsLabel;
                    }
                    //Check for deferred calls.
                    else if(context.deferStack[context.deferPos].length) {
                        //Pop the next defer and run it.
                        context.pc = context.deferStack[context.deferPos][$ - 1];
                        context.deferStack[context.deferPos].length --;
                    }
                    else if(context.isKilled) {
                        if(context.stackPos) {
                            //Pop the defer scope.
                            context.deferPos --;

                            //Pop the exception handlers as well.
                            context.exceptionHandlersPos --;

                            //Then returns to the last context without modifying the pc.
                            context.stackPos -= 2;
                            context.localsPos -= context.callStack[context.stackPos];
                        }
                        else {
                            //Every deferred call has been executed, now die.
                            _contexts.markInternalForRemoval(index);
					        continue contextsLabel;
                        }
                    }
                    else if(context.isPanicking) {
                        //An exception has been raised without any try/catch inside the function.
                        //So all deferred code is run here before searching in the parent function.
                        if(context.stackPos) {
                            //Pop the defer scope.
                            context.deferPos --;

                            //Pop the exception handlers as well.
                            context.exceptionHandlersPos --;

                            //Then returns to the last context without modifying the pc.
                            context.stackPos -= 2;
                            context.localsPos -= context.callStack[context.stackPos];

                            //Exception handler found in the current function, just jump.
                            if(context.exceptionHandlers[context.exceptionHandlersPos].length) {
                                context.pc = context.exceptionHandlers[context.exceptionHandlersPos][$ - 1];
                            }
                        }
                        else {
                            //Kill the others.
                            foreach(coroutine; _contexts) {
                                coroutine.pc = cast(uint)(_opcodes.length - 1);
                                coroutine.isKilled = true;
                            }

                            //The VM is now panicking.
                            _isPanicking = true;
                            _panicMessage = _sglobalStack[$ - 1];
                            _sglobalStack.length --;

                            //Every deferred call has been executed, now die.
                            _contexts.markInternalForRemoval(index);
					        continue contextsLabel;
                        }
                    }
                    else {
                        //Pop the defer scope.
                        context.deferPos --;

                        //Pop the exception handlers as well.
                        context.exceptionHandlersPos --;

                        //Then returns to the last context.
                        context.stackPos -= 2;
                        context.pc = context.callStack[context.stackPos + 1u];
                        context.localsPos -= context.callStack[context.stackPos];
                    }
                    break;
                case Defer:
                    context.deferStack[context.deferPos] ~= context.pc + grGetInstructionSignedValue(opcode);
					context.pc ++;
                    break;
				case LocalStack:
                    const auto stackSize = grGetInstructionUnsignedValue(opcode);
					context.callStack[context.stackPos] = stackSize;
                    context.deferPos ++;
                    context.exceptionHandlersPos ++;
					context.pc ++;
					break;
				case Call:
                    if(((context.stackPos >> 1) + 1) >= context.callStackLimit)
                        context.doubleCallStackSize();
					context.localsPos += context.callStack[context.stackPos];
					context.callStack[context.stackPos + 1u] = context.pc + 1u;
					context.stackPos += 2;
					context.pc = grGetInstructionUnsignedValue(opcode);
					break;
				case AnonymousCall:
                    if((context.stackPos >> 1) >= context.callStackLimit)
                        context.doubleCallStackSize();
					context.localsPos += context.callStack[context.stackPos];
					context.callStack[context.stackPos + 1u] = context.pc + 1u;
					context.stackPos += 2;
					context.pc = context.istack[context.istackPos];
					context.istackPos --;
					break;
                case DynamicCall:
                    _meta = _sconsts[grGetInstructionUnsignedValue(opcode)];
                    context.astack[context.astackPos].call(context);
                    break;
				case PrimitiveCall:
					primitives[grGetInstructionUnsignedValue(opcode)].callObject.call(context);
					context.pc ++;
					break;
				case Jump:
					context.pc += grGetInstructionSignedValue(opcode);
					break;
				case JumpEqual:
					if(context.istack[context.istackPos])
						context.pc ++;
					else
						context.pc += grGetInstructionSignedValue(opcode);
					context.istackPos --;
					break;
				case JumpNotEqual:
					if(context.istack[context.istackPos])
						context.pc += grGetInstructionSignedValue(opcode);
					else
						context.pc ++;
					context.istackPos --;
					break;
                case Build_Array:
                    GrDynamicValue[] ary;
                    const auto arySize = grGetInstructionUnsignedValue(opcode);
                    for(int i = arySize - 1; i >= 0; i --) {
                        ary ~= context.astack[context.astackPos - i];
                    }
                    context.astackPos -= arySize;
                    context.nstackPos ++;
                    context.nstack[context.nstackPos] = ary;
                    context.pc ++;
                    break;
				case Length_Array:
                    context.istackPos ++;
					context.istack[context.istackPos] = cast(int)context.nstack[context.nstackPos].length;
                    context.nstackPos --;
					context.pc ++;
					break;
				case Index_Array:
					GrDynamicValue[] ary = context.nstack[context.nstackPos];
                    const auto idx = context.istack[context.istackPos];
                    if(idx >= ary.length) {
                        raise(context, "Array overflow");
                        break;
                    }
                    context.astackPos ++;
                    context.astack[context.astackPos] = ary[idx];
					context.nstackPos --;					
					context.istackPos --;					
					context.pc ++;
					break;
                case IndexRef_Array:
                    context.astack[context.astackPos].setArrayIndex(context, context.istack[context.istackPos]);
                    context.istackPos --;
					context.pc ++;
					break;
				default:
					throw new Exception("Invalid instruction at (" ~ to!string(context.pc) ~ "): " ~ to!string(grGetInstructionOpcode(opcode)));
                }
			}
		}
		_contexts.sweepMarkedData();
    }
}