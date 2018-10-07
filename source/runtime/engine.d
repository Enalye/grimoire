/**
    Grimoire virtual machine.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module runtime.engine;

import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.math;

import core.indexedarray;
import compiler.all;
import assembly.all;
import runtime.context;
import runtime.dynamic;
import runtime.array;

/** Grimoire virtual machine */
class GrEngine {
    private {
        uint[] _opcodes;

        int[] _iconsts;
        float[] _fconsts;
        dstring[] _sconsts;

        int[] _iglobals;
        float[] _fglobals;
        dstring[] _sglobals;

        int[] _iglobalStack;
        float[] _fglobalStack;
        dstring[] _sglobalStack;
        GrDynamicValue[][] _nglobalStack;
        GrDynamicValue[] _aglobalStack;
        void*[] _oglobalStack;
	    IndexedArray!(GrContext, 256u) _contexts = new IndexedArray!(GrContext, 256u)();
    
        //Panic state.
        bool _isPanicking;
        dstring _panicMessage;
    }

    __gshared bool isRunning = true;

    @property {
        /// Check if there is a coroutine currently running.
        bool hasCoroutines() const { return _contexts.length > 0uL; }

        /// Whether the whole VM has panicked, true if an unhandled error occurred.
        bool isPanicking() const { return _isPanicking; }

        /// The unhandled error message.
        dstring panicMessage() const { return _panicMessage; }
    }

    /// Default.
	this() {}

    /// Load the bytecode.
	this(GrBytecode bytecode) {
		load(bytecode);
	}

    /// Load the bytecode.
	void load(GrBytecode bytecode) {
		_iconsts = bytecode.iconsts;
		_fconsts = bytecode.fconsts;
		_sconsts = bytecode.sconsts;
		_opcodes = bytecode.opcodes;
	}

    /**
        Create the main context.
        You must call this function before running the vm.
    */
    void spawn() {
		_contexts.push(new GrContext(this));
	}

    /**
        Captures an unhandled error and kill the VM.
    */
    void panic() {
        
    }

    /// Run the vm until all the contexts are finished or in yield.
	void process() {
		contextsLabel: for(uint index = 0u; index < _contexts.length; index ++) {
			GrContext context = _contexts.data[index];
			while(isRunning) {
				uint opcode = _opcodes[context.pc];
				switch (grBytecode_getOpcode(opcode)) with(GrOpcode) {
                case Nop:
                    context.pc ++;
                    break;
                case Raise:
                    if(!context.isPanicking) {
                        //Error message.
                        _sglobalStack ~= context.sstack[$ - 1];
                        context.sstack.length --;

                        //We indicate that the coroutine is in a panic state until a catch is found.
                        context.isPanicking = true;
                    }

                    //Exception handler found in the current function, just jump.
                    if(context.exceptionHandlers[$ - 1].length) {
                        context.pc = context.exceptionHandlers[$ - 1][$ - 1];
                    }
                    //No exception handler in the current function, unwinding the deferred code, then return.
                    
                    //Check for deferred calls as we will exit the current function.
                    else if(context.deferStack[$ - 1].length) {
                        //Pop the last defer and run it.
                        context.pc = context.deferStack[$ - 1][$ - 1];
                        context.deferStack[$ - 1].length --;
                        //The search for an exception handler will be done by Unwind after all defer
                        //has been called for this function.
                    }
                    else if(context.stackPos) {
                        //Pop the defer scope.
                        context.deferStack.length --;

                        //Pop the exception handlers as well.
                        context.exceptionHandlers.length --;

                        //Then returns to the last context, raise will be run again.
                        context.stackPos -= 2;
                        context.valuesPos -= context.callStack[context.stackPos];
                    }
                    else {
                        //Kill the others.
                        foreach(coroutine; _contexts) {
                            coroutine.pc = context.pc;
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
                    context.exceptionHandlers[$ - 1] ~= context.pc + grBytecode_getSignedValue(opcode);
                    context.pc ++;
                    break;
                case Catch:
                    context.exceptionHandlers[$ - 1].length --;
                    if(context.isPanicking) {
                        context.isPanicking = false;
                        context.pc ++;
                    }
                    else {
                        context.pc += grBytecode_getSignedValue(opcode);
                    }
                    break;
				case Task:
					GrContext newCoro = new GrContext(this);
					newCoro.pc = grBytecode_getUnsignedValue(opcode);
					_contexts.push(newCoro);
					context.pc ++;
					break;
				case AnonymousTask:
					GrContext newCoro = new GrContext(this);
					newCoro.pc = context.istack[$ - 1];
					context.istack.length --;
					_contexts.push(newCoro);
					context.pc ++;
					break;
				case Kill:
                    //Check for deferred calls.
                    if(context.deferStack[$ - 1].length) {
                        //Pop the last defer and run it.
                        context.pc = context.deferStack[$ - 1][$ - 1];
                        context.deferStack[$ - 1].length --;

                        //Flag as killed so the entire stack will be unwinded.
                        context.isKilled = true;
                    }
                    else if(context.stackPos) {
                        //Pop the defer scope.
                        context.deferStack.length --;

                        //Then returns to the last context.
                        context.stackPos -= 2;
                        context.pc = context.callStack[context.stackPos + 1u];
                        context.valuesPos -= context.callStack[context.stackPos];

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
				case PopStack_Int:
					context.istack.length -= grBytecode_getUnsignedValue(opcode);
					context.pc ++;
					break;
				case PopStack_Float:
					context.fstack.length -= grBytecode_getUnsignedValue(opcode);
					context.pc ++;
					break;
				case PopStack_String:
					context.sstack.length -= grBytecode_getUnsignedValue(opcode);
					context.pc ++;
					break;
                case PopStack_Array:
					context.nstack.length -= grBytecode_getUnsignedValue(opcode);
					context.pc ++;
					break;
				case PopStack_Any:
					context.astack.length -= grBytecode_getUnsignedValue(opcode);
					context.pc ++;
					break;
				case PopStack_Object:
					context.ostack.length -= grBytecode_getUnsignedValue(opcode);
					context.pc ++;
					break;
				case LocalStore_Int:
					context.ivalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)] = context.istack[$ - 1];
                    context.istack.length --;	
					context.pc ++;
					break;
				case LocalStore_Float:
					context.fvalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)] = context.fstack[$ - 1];
                    context.fstack.length --;	
					context.pc ++;
					break;
				case LocalStore_String:
					context.svalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)] = context.sstack[$ - 1];		
                    context.sstack.length --;	
					context.pc ++;
					break;
                case LocalStore_Array:
					context.nvalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)] = context.nstack[$ - 1];		
                    context.nstack.length --;	
					context.pc ++;
					break;
				case LocalStore_Any:
					context.avalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)] = context.astack[$ - 1];
                    context.astack.length --;	
					context.pc ++;
					break;
                case LocalStore_Ref:
                    context.astack[$ - 2].setRef(context.astack[$ - 1]);
                    context.astack.length -= 2;
                    context.pc ++;
                    break;
				case LocalStore_Object:
					context.ovalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)] = context.ostack[$ - 1];
                    context.ostack.length --;	
					context.pc ++;
					break;
                case LocalStore2_Int:
					context.ivalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)] = context.istack[$ - 1];
					context.pc ++;
					break;
				case LocalStore2_Float:
					context.fvalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)] = context.fstack[$ - 1];
					context.pc ++;
					break;
				case LocalStore2_String:
					context.svalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)] = context.sstack[$ - 1];		
					context.pc ++;
					break;
                case LocalStore2_Array:
					context.nvalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)] = context.nstack[$ - 1];		
					context.pc ++;
					break;
				case LocalStore2_Any:
					context.avalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)] = context.astack[$ - 1];
					context.pc ++;
					break;
                case LocalStore2_Ref:
                    context.astack[$ - 2].setRef(context.astack[$ - 1]);
                    context.astack.length --;
                    context.pc ++;
                    break;
				case LocalStore2_Object:
					context.ovalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)] = context.ostack[$ - 1];
					context.pc ++;
					break;
				case LocalLoad_Int:
					context.istack ~= context.ivalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)];
					context.pc ++;
					break;
				case LocalLoad_Float:
					context.fstack ~= context.fvalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)];
					context.pc ++;
					break;
				case LocalLoad_String:
					context.sstack ~= context.svalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)];
					context.pc ++;
					break;
                case LocalLoad_Array:
					context.nstack ~= context.nvalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)];
					context.pc ++;
					break;
				case LocalLoad_Any:
					context.astack ~= context.avalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)];
					context.pc ++;
					break;
                case LocalLoad_Ref:
                    GrDynamicValue value;
                    value.setRefArray(&context.nvalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)]);
                    context.astack ~= value;					
					context.pc ++;
					break;
				case LocalLoad_Object:
					context.ostack ~= context.ovalues[context.valuesPos + grBytecode_getUnsignedValue(opcode)];
					context.pc ++;
					break;
				case Const_Int:
					context.istack ~= _iconsts[grBytecode_getUnsignedValue(opcode)];
					context.pc ++;
					break;
				case Const_Float:
					context.fstack ~= _fconsts[grBytecode_getUnsignedValue(opcode)];
					context.pc ++;
					break;
				case Const_Bool:
					context.istack ~= grBytecode_getUnsignedValue(opcode);
					context.pc ++;
					break;
				case Const_String:
					context.sstack ~= _sconsts[grBytecode_getUnsignedValue(opcode)];
					context.pc ++;
					break;
				case GlobalPush_Int:
					uint nbParams = grBytecode_getUnsignedValue(opcode);
					for(uint i = 0u; i < nbParams; i++)
						_iglobalStack ~= context.istack[($ - nbParams) + i];
					context.istack.length -= nbParams;
					context.pc ++;
					break;
				case GlobalPush_Float:
					uint nbParams = grBytecode_getUnsignedValue(opcode);
					for(uint i = 0u; i < nbParams; i++)
						_fglobalStack ~= context.fstack[($ - nbParams) + i];
					context.fstack.length -= nbParams;
					context.pc ++;
					break;
				case GlobalPush_String:
					uint nbParams = grBytecode_getUnsignedValue(opcode);
					for(uint i = 0u; i < nbParams; i++)
						_sglobalStack ~= context.sstack[($ - nbParams) + i];
					context.sstack.length -= nbParams;
					context.pc ++;
					break;
                case GlobalPush_Array:
					uint nbParams = grBytecode_getUnsignedValue(opcode);
					for(uint i = 0u; i < nbParams; i++)
						_nglobalStack ~= context.nstack[($ - nbParams) + i];
					context.nstack.length -= nbParams;
					context.pc ++;
					break;
				case GlobalPush_Any:
					uint nbParams = grBytecode_getUnsignedValue(opcode);
					for(uint i = 0u; i < nbParams; i++)
						_aglobalStack ~= context.astack[($ - nbParams) + i];
					context.astack.length -= nbParams;
					context.pc ++;
					break;
				case GlobalPush_Object:
					uint nbParams = grBytecode_getUnsignedValue(opcode);
					for(uint i = 0u; i < nbParams; i++)
						_oglobalStack ~= context.ostack[($ - nbParams) + i];
					context.ostack.length -= nbParams;
					context.pc ++;
					break;
				case GlobalPop_Int:
					context.istack ~= _iglobalStack[$ - 1];
					_iglobalStack.length --;
					context.pc ++;
					break;
				case GlobalPop_Float:
					context.fstack ~= _fglobalStack[$ - 1];
					_fglobalStack.length --;
					context.pc ++;
					break;
				case GlobalPop_String:
					context.sstack ~= _sglobalStack[$ - 1];
					_sglobalStack.length --;
					context.pc ++;
					break;
                case GlobalPop_Array:
					context.nstack ~= _nglobalStack[$ - 1];
					_nglobalStack.length --;
					context.pc ++;
					break;
				case GlobalPop_Any:
					context.astack ~= _aglobalStack[$ - 1];
					_aglobalStack.length --;
					context.pc ++;
					break;
				case GlobalPop_Object:
					context.ostack ~= _oglobalStack[$ - 1];
					_oglobalStack.length --;
					context.pc ++;
					break;
                case ConvertBoolToAny:
					GrDynamicValue value;
					value.setBool(context.istack[$ - 1]);
					context.istack.length --;
					context.astack ~= value;
					context.pc ++;
					break;
				case ConvertIntToAny:
					GrDynamicValue value;
					value.setInteger(context.istack[$ - 1]);
					context.istack.length --;
					context.astack ~= value;
					context.pc ++;
					break;
				case ConvertFloatToAny:
					GrDynamicValue value;
					value.setFloat(context.fstack[$ - 1]);
					context.fstack.length --;
					context.astack ~= value;
					context.pc ++;
					break;
				case ConvertStringToAny:
					GrDynamicValue value;
					value.setString(context.sstack[$ - 1]);
					context.sstack.length --;
					context.astack ~= value;
					context.pc ++;
					break;
                case ConvertArrayToAny:
					GrDynamicValue value;
					value.setArray(context.nstack[$ - 1]);
					context.nstack.length --;
					context.astack ~= value;
					context.pc ++;
					break;
				case ConvertAnyToBool:
					context.istack ~= context.astack[$ - 1].getBool();
					context.astack.length --;
					context.pc ++;
					break;
                case ConvertAnyToInt:
					context.istack ~= context.astack[$ - 1].getInteger();
					context.astack.length --;
					context.pc ++;
					break;
				case ConvertAnyToFloat:
					context.fstack ~= context.astack[$ - 1].getFloat();
					context.astack.length --;
					context.pc ++;
					break;
				case ConvertAnyToString:
					context.sstack ~= context.astack[$ - 1].getString();
					context.astack.length --;
					context.pc ++;
					break;
                case ConvertAnyToArray:
					context.nstack ~= context.astack[$ - 1].getArray();
					context.astack.length --;
					context.pc ++;
					break;
				case Equal_Int:
					context.istack[$ - 2] = context.istack[$ - 2] == context.istack[$ - 1];
					context.istack.length --;
					context.pc ++;
					break;
				case Equal_Float:
					context.istack ~= context.fstack[$ - 2] == context.fstack[$ - 1];
					context.fstack.length -= 2;
					context.pc ++;
					break;
				case Equal_String:
					context.istack ~= context.sstack[$ - 2] == context.sstack[$ - 1];
					context.sstack.length -= 2;
					context.pc ++;
					break;
				//Equal_Any
				case NotEqual_Int:
					context.istack[$ - 2] = context.istack[$ - 2] != context.istack[$ - 1];
					context.istack.length --;
					context.pc ++;
					break;
				case NotEqual_Float:
					context.istack ~= context.fstack[$ - 2] != context.fstack[$ - 1];
					context.fstack.length -= 2;
					context.pc ++;
					break;
				case NotEqual_String:
					context.istack ~= context.sstack[$ - 2] != context.sstack[$ - 1];
					context.sstack.length -= 2;
					context.pc ++;
					break;
				//NotEqual_Any
				case GreaterOrEqual_Int:
					context.istack[$ - 2] = context.istack[$ - 2] >= context.istack[$ - 1];
					context.istack.length --;
					context.pc ++;
					break;
				case GreaterOrEqual_Float:
					context.istack ~= context.fstack[$ - 2] >= context.fstack[$ - 1];
					context.fstack.length -= 2;
					context.pc ++;
					break;
					//Any
				case LesserOrEqual_Int:
					context.istack[$ - 2] = context.istack[$ - 2] <= context.istack[$ - 1];
					context.istack.length --;
					context.pc ++;
					break;
				case LesserOrEqual_Float:
					context.istack ~= context.fstack[$ - 2] <= context.fstack[$ - 1];
					context.fstack.length -= 2;
					context.pc ++;
					break;
					//any
				case GreaterInt:
					context.istack[$ - 2] = context.istack[$ - 2] > context.istack[$ - 1];
					context.istack.length --;
					context.pc ++;
					break;
				case GreaterFloat:
					context.istack ~= context.fstack[$ - 2] > context.fstack[$ - 1];
					context.fstack.length -= 2;
					context.pc ++;
					break;
					//any
				case LesserInt:
					context.istack[$ - 2] = context.istack[$ - 2] < context.istack[$ - 1];
					context.istack.length --;
					context.pc ++;
					break;
				case LesserFloat:
					context.istack ~= context.fstack[$ - 2] < context.fstack[$ - 1];
					context.fstack.length -= 2;
					context.pc ++;
					break;
					//any
				case AndInt:
					context.istack[$ - 2] = context.istack[$ - 2] && context.istack[$ - 1];
					context.istack.length --;
					context.pc ++;
					break;
				case OrInt:
					context.istack[$ - 2] = context.istack[$ - 2] || context.istack[$ - 1];
					context.istack.length --;
					context.pc ++;
					break;
				case NotInt:
					context.istack[$ - 1] = !context.istack[$ - 1];
					context.pc ++;
					break;
					//any
				case AddInt:
					context.istack[$ - 2] += context.istack[$ - 1];
					context.istack.length --;
					context.pc ++;
					break;
				case AddFloat:
					context.fstack[$ - 2] += context.fstack[$ - 1];
					context.fstack.length --;
					context.pc ++;
					break;
				case AddAny:
					context.astack[$ - 2] += context.astack[$ - 1];
					context.astack.length --;
					context.pc ++;
					break;
				case ConcatenateString:
					context.sstack[$ - 2] ~= context.sstack[$ - 1];
					context.sstack.length --;
					context.pc ++;
					break;
				case ConcatenateAny:
					context.astack[$ - 2] ~= context.astack[$ - 1];
					context.astack.length --;
					context.pc ++;
					break;
				case SubstractInt:
					context.istack[$ - 2] -= context.istack[$ - 1];
					context.istack.length --;
					context.pc ++;
					break;
				case SubstractFloat:
					context.fstack[$ - 2] -= context.fstack[$ - 1];
					context.fstack.length --;
					context.pc ++;
					break;
				case SubstractAny:
					context.astack[$ - 2] -= context.astack[$ - 1];
					context.astack.length --;
					context.pc ++;
					break;
				case MultiplyInt:
					context.istack[$ - 2] *= context.istack[$ - 1];
					context.istack.length --;
					context.pc ++;
					break;
				case MultiplyFloat:
					context.fstack[$ - 2] *= context.fstack[$ - 1];
					context.fstack.length --;
					context.pc ++;
					break;
				case MultiplyAny:
					context.astack[$ - 2] *= context.astack[$ - 1];
					context.astack.length --;
					context.pc ++;
					break;
				case DivideInt:
					context.istack[$ - 2] /= context.istack[$ - 1];
					context.istack.length --;
					context.pc ++;
					break;
				case DivideFloat:
					context.fstack[$ - 2] /= context.fstack[$ - 1];
					context.fstack.length --;
					context.pc ++;
					break;
				case DivideAny:
					context.astack[$ - 2] /= context.astack[$ - 1];
					context.astack.length --;
					context.pc ++;
					break;
				case RemainderInt:
					context.istack[$ - 2] %= context.istack[$ - 1];
					context.istack.length --;
					context.pc ++;
					break;
				case RemainderFloat:
					context.fstack[$ - 2] %= context.fstack[$ - 1];
					context.fstack.length --;
					context.pc ++;
					break;
				case RemainderAny:
					context.astack[$ - 2] %= context.astack[$ - 1];
					context.astack.length --;
					context.pc ++;
					break;
				case NegativeInt:
					context.istack[$ - 1] = -context.istack[$ - 1];
					context.pc ++;
					break;
				case NegativeFloat:
					context.fstack[$ - 1] = -context.fstack[$ - 1];
					context.pc ++;
					break;
				case NegativeAny:
					context.astack[$ - 1] = -context.astack[$ - 1];
					context.pc ++;
					break;
				case IncrementInt:
					context.istack[$ - 1] ++;
					context.pc ++;
					break;
				case IncrementFloat:
					context.fstack[$ - 1] += 1f;
					context.pc ++;
					break;
				case IncrementAny:
					context.astack[$ - 1] ++;
					context.pc ++;
					break;
				case DecrementInt:
					context.istack[$ - 1] --;
					context.pc ++;
					break;
				case DecrementFloat:
					context.fstack[$ - 1] -= 1f;
					context.pc ++;
					break;
				case DecrementAny:
					context.astack[$ - 1] --;
					context.pc ++;
					break;
				case SetupIterator:
					if(context.istack[$ - 1] < 0)
						context.istack[$ - 1] = 0;
					context.istack[$ - 1] ++;
					context.pc ++;
					break;
				case Return:
                    //If another task was killed by an exception,
                    //we might end up there if the task has just been spawned.
                    if(!context.deferStack.length && context.isKilled) {
                        _contexts.markInternalForRemoval(index);
					    continue contextsLabel;
                    }
                    //Check for deferred calls.
                    else if(context.deferStack[$ - 1].length) {
                        //Pop the last defer and run it.
                        context.pc = context.deferStack[$ - 1][$ - 1];
                        context.deferStack[$ - 1].length --;
                    }
                    else {
                        //Pop the defer scope.
                        context.deferStack.length --;

                        //Pop the exception handlers as well.
                        context.exceptionHandlers.length --;

                        //Then returns to the last context.
                        context.stackPos -= 2;
                        context.pc = context.callStack[context.stackPos + 1u];
                        context.valuesPos -= context.callStack[context.stackPos];
                    }
					break;
                case Unwind:
                    //If another task was killed by an exception,
                    //we might end up there if the task has just been spawned.
                    if(!context.deferStack.length) {
                        _contexts.markInternalForRemoval(index);
					    continue contextsLabel;
                    }
                    //Check for deferred calls.
                    else if(context.deferStack[$ - 1].length) {
                        //Pop the next defer and run it.
                        context.pc = context.deferStack[$ - 1][$ - 1];
                        context.deferStack[$ - 1].length --;
                    }
                    else if(context.isKilled) {
                        if(context.stackPos) {
                            //Pop the defer scope.
                            context.deferStack.length --;

                            //Pop the exception handlers as well.
                            context.exceptionHandlers.length --;

                            //Then returns to the last context without modifying the pc.
                            context.stackPos -= 2;
                            context.valuesPos -= context.callStack[context.stackPos];
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
                            context.deferStack.length --;

                            //Pop the exception handlers as well.
                            context.exceptionHandlers.length --;

                            //Then returns to the last context without modifying the pc.
                            context.stackPos -= 2;
                            context.valuesPos -= context.callStack[context.stackPos];

                            //Exception handler found in the current function, just jump.
                            if(context.exceptionHandlers[$ - 1].length) {
                                context.pc = context.exceptionHandlers[$ - 1][$ - 1];
                            }
                        }
                        else {
                            //Kill the others.
                            foreach(coroutine; _contexts) {
                                coroutine.pc = context.pc;
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
                        context.deferStack.length --;

                        //Pop the exception handlers as well.
                        context.exceptionHandlers.length --;

                        //Then returns to the last context.
                        context.stackPos -= 2;
                        context.pc = context.callStack[context.stackPos + 1u];
                        context.valuesPos -= context.callStack[context.stackPos];
                    }
                    break;
                case Defer:
                    context.deferStack[$ - 1] ~= context.pc + grBytecode_getSignedValue(opcode);
					context.pc ++;
                    break;
				case LocalStack:
                    auto stackSize = grBytecode_getUnsignedValue(opcode);
					context.callStack[context.stackPos] = stackSize;
                    stackSize = context.valuesPos + stackSize;
                    context.ivalues.length = stackSize;
                    context.fvalues.length = stackSize;
                    context.svalues.length = stackSize;
                    context.nvalues.length = stackSize;
                    context.avalues.length = stackSize;
                    context.ovalues.length = stackSize;
                    context.deferStack.length ++;
                    context.exceptionHandlers.length ++;
					context.pc ++;
					break;
				case Call:
					context.valuesPos += context.callStack[context.stackPos];
					context.callStack[context.stackPos + 1u] = context.pc + 1u;
					context.stackPos += 2;
					context.pc = grBytecode_getUnsignedValue(opcode);
					break;
				case AnonymousCall:
					context.valuesPos += context.callStack[context.stackPos];
					context.callStack[context.stackPos + 1u] = context.pc + 1u;
					context.stackPos += 2;
					context.pc = context.istack[$ - 1];
					context.istack.length --;
					break;
				case PrimitiveCall:
					primitives[grBytecode_getUnsignedValue(opcode)].callObject.call(context);
					context.pc ++;
					break;
				case Jump:
					context.pc += grBytecode_getSignedValue(opcode);
					break;
				case JumpEqual:
					if(context.istack[$ - 1])
						context.pc ++;
					else
						context.pc += grBytecode_getSignedValue(opcode);
					context.istack.length --;
					break;
				case JumpNotEqual:
					if(context.istack[$ - 1])
						context.pc += grBytecode_getSignedValue(opcode);
					else
						context.pc ++;
					context.istack.length --;
					break;
                case Build_Array:
                    GrDynamicValue[] ary;
                    const auto arySize = grBytecode_getUnsignedValue(opcode);
                    for(int i = arySize; i > 0; i --) {
                        ary ~= context.astack[$ - i];
                    }
                    context.astack.length -= arySize;
                    context.nstack ~= ary;
                    context.pc ++;
                    break;
				case Length_Array:
					context.istack ~= cast(int)context.nstack[$ - 1].length;
                    context.nstack.length --;
					context.pc ++;
					break;
				case Index_Array:
					context.astack ~= context.nstack[$ - 1][context.istack[$ - 1]];
					context.nstack.length --;					
					context.istack.length --;					
					context.pc ++;
					break;
                case IndexRef_Array:
                    context.astack[$ - 1].setArrayIndex(context.istack[$ - 1]);
                    context.istack.length --;
					context.pc ++;
					break;
				default:
					throw new Exception("Invalid instruction");
				}
			}
		}
		_contexts.sweepMarkedData();
    }
}