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
import grimoire.runtime.variant;
import grimoire.runtime.array;
import grimoire.runtime.object;
import grimoire.runtime.channel;

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
        GrVariantValue[]* _nglobals;
        GrVariantValue* _vglobals;
        void** _oglobals;

        /// Global integral stack.
        int[] _iglobalStack;
        /// Global floating point stack.
        float[] _fglobalStack;
        /// Global string stack.
        dstring[] _sglobalStack;
        /// Global dynamic value stack.
        GrVariantValue[] _vglobalStack;
        /// Global object stack.
        void*[] _oglobalStack;

        /// Context array.
	    DynamicIndexedArray!GrContext _contexts, _contextsToSpawn;
    
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
        bool hasCoroutines() const { return (_contexts.length + _contextsToSpawn.length) > 0uL; }

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
		_contextsToSpawn = new DynamicIndexedArray!GrContext;
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
        _nglobals = (new GrVariantValue[][_globalsLimit]).ptr;
        _vglobals = (new GrVariantValue[_globalsLimit]).ptr;
        _oglobals = (new void*[_globalsLimit]).ptr;
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
        _contextsToSpawn.push(context);
        return context;
    }

    package(grimoire) void pushContext(GrContext context) {
        _contextsToSpawn.push(context);
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
        if(context.callStack[context.stackPos].exceptionHandlers.length) {
            context.pc = context.callStack[context.stackPos].exceptionHandlers[$ - 1];
        }
        //No exception handler in the current function, unwinding the deferred code, then return.
        
        //Check for deferred calls as we will exit the current function.
        else if(context.callStack[context.stackPos].deferStack.length) {
            //Pop the last defer and run it.
            context.pc = context.callStack[context.stackPos].deferStack[$ - 1];
            context.callStack[context.stackPos].deferStack.length --;
            //The search for an exception handler will be done by Unwind after all defer
            //has been called for this function.
        }
        else if(context.stackPos) {
            //Then returns to the last context, raise will be run again.
            context.stackPos --;
            context.localsPos -= context.callStack[context.stackPos].localStackSize;
        }
        else {
            //Kill the others.
            foreach(coroutine; _contexts) {
                coroutine.pc = cast(uint)(_opcodes.length - 1);
                coroutine.isKilled = true;
            }
			_contextsToSpawn.reset();

            //The VM is now panicking.
            _isPanicking = true;
            _panicMessage = _sglobalStack[$ - 1];
            _sglobalStack.length --;
        }
    }

    /// Run the vm until all the contexts are finished or in yield.
	void process() {
		if(_contextsToSpawn.length) {
			for(int index = _contextsToSpawn.length - 1; index >= 0; index --)
				_contexts.push(_contextsToSpawn[index]);
			_contextsToSpawn.reset();
		}
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
                    if(context.callStack[context.stackPos].exceptionHandlers.length) {
                        context.pc = context.callStack[context.stackPos].exceptionHandlers[$ - 1];
                    }
                    //No exception handler in the current function, unwinding the deferred code, then return.
                    
                    //Check for deferred calls as we will exit the current function.
                    else if(context.callStack[context.stackPos].deferStack.length) {
                        //Pop the last defer and run it.
                        context.pc = context.callStack[context.stackPos].deferStack[$ - 1];
                        context.callStack[context.stackPos].deferStack.length --;
                        //The search for an exception handler will be done by Unwind after all defer
                        //has been called for this function.
                    }
                    else if(context.stackPos) {
                        //Then returns to the last context, raise will be run again.
                        context.stackPos --;
                        context.localsPos -= context.callStack[context.stackPos].localStackSize;
                    }
                    else {
                        //Kill the others.
                        foreach(coroutine; _contexts) {
                            coroutine.pc = cast(uint)(_opcodes.length - 1);
                            coroutine.isKilled = true;
                        }
						_contextsToSpawn.reset();

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
                    context.callStack[context.stackPos].exceptionHandlers ~= context.pc + grGetInstructionSignedValue(opcode);
                    context.pc ++;
                    break;
                case Catch:
                    context.callStack[context.stackPos].exceptionHandlers.length --;
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
					_contextsToSpawn.push(newCoro);
					context.pc ++;
					break;
				case AnonymousTask:
					GrContext newCoro = new GrContext(this);
					newCoro.pc = context.istack[context.istackPos];
					context.istackPos --;
					_contextsToSpawn.push(newCoro);
					context.pc ++;
					break;
				case Kill:
                    //Check for deferred calls.
                    if(context.callStack[context.stackPos].deferStack.length) {
                        //Pop the last defer and run it.
                        context.pc = context.callStack[context.stackPos].deferStack[$ - 1];
                        context.callStack[context.stackPos].deferStack.length --;

                        //Flag as killed so the entire stack will be unwinded.
                        context.isKilled = true;
                    }
                    else if(context.stackPos) {
                        //Then returns to the last context.
                        context.stackPos --;
                        context.pc = context.callStack[context.stackPos].retPosition;
                        context.localsPos -= context.callStack[context.stackPos].localStackSize;

                        //Flag as killed so the entire stack will be unwinded.
                        context.isKilled = true;
                    }
                    else {
                        //No need to flag if the call stac is empty without any deferred statement.
                        _contexts.markInternalForRemoval(index);
					    continue contextsLabel;
                    }
					break;
				case KillAll:
					//Kill the others.
					foreach(coroutine; _contexts) {
						coroutine.pc = cast(uint)(_opcodes.length - 1);
						coroutine.isKilled = true;
					}
					_contextsToSpawn.reset();
					continue contextsLabel;
				case Yield:
					context.pc ++;
					continue contextsLabel;
                case New:
                    context.ostackPos ++;
					context.ostack[context.ostackPos] = cast(void*)new GrObjectValue(grGetInstructionUnsignedValue(opcode));
					context.pc ++;
                    break;
				case Channel_Int:
					context.ostackPos ++;
					context.ostack[context.ostackPos] = cast(void*)new GrIntChannel(grGetInstructionUnsignedValue(opcode));
					context.pc ++;
					break;
				case Channel_Float:
					context.ostackPos ++;
					context.ostack[context.ostackPos] = cast(void*)new GrFloatChannel(grGetInstructionUnsignedValue(opcode));
					context.pc ++;
					break;
				case Channel_String:
					context.ostackPos ++;
					context.ostack[context.ostackPos] = cast(void*)new GrStringChannel(grGetInstructionUnsignedValue(opcode));
					context.pc ++;
					break;
				case Channel_Variant:
					context.ostackPos ++;
					context.ostack[context.ostackPos] = cast(void*)new GrVariantChannel(grGetInstructionUnsignedValue(opcode));
					context.pc ++;
					break;
				case Channel_Object:
					context.ostackPos ++;
					context.ostack[context.ostackPos] = cast(void*)new GrObjectChannel(grGetInstructionUnsignedValue(opcode));
					context.pc ++;
					break;
				case Send_Int:
					GrIntChannel chan = cast(GrIntChannel)context.ostack[context.ostackPos];
					if(!chan.isOwned) {
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isLocked = true;
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else {
							context.istackPos --;
							context.ostackPos --;
							raise(context, "Channel not owned");
						}
					}
					else if(chan.canSend) {
						context.isLocked = false;
						chan.send(context.istack[context.istackPos]);
						context.ostackPos --;
						context.pc ++;
					}
					else {
						context.isLocked = true;
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else
							continue contextsLabel;
					}
					break;
				case Send_Float:
					GrFloatChannel chan = cast(GrFloatChannel)context.ostack[context.ostackPos];
					if(!chan.isOwned) {
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isLocked = true;
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else {
							context.fstackPos --;
							context.ostackPos --;
							raise(context, "Channel not owned");
						}
					}
					else if(chan.canSend) {
						context.isLocked = false;
						chan.send(context.fstack[context.fstackPos]);
						context.ostackPos --;
						context.pc ++;
					}
					else {
						context.isLocked = true;
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else
							continue contextsLabel;
					}
					break;
				case Send_String:
					GrStringChannel chan = cast(GrStringChannel)context.ostack[context.ostackPos];
					if(!chan.isOwned) {
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isLocked = true;
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else {
							context.sstackPos --;
							context.ostackPos --;
							raise(context, "Channel not owned");
						}
					}
					else if(chan.canSend) {
						context.isLocked = false;
						chan.send(context.sstack[context.sstackPos]);
						context.ostackPos --;
						context.pc ++;
					}
					else {
						context.isLocked = true;
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else
							continue contextsLabel;
					}
					break;
				case Send_Variant:
					GrVariantChannel chan = cast(GrVariantChannel)context.ostack[context.ostackPos];
					if(!chan.isOwned) {
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isLocked = true;
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else {
							context.vstackPos --;
							context.ostackPos --;
							raise(context, "Channel not owned");
						}
					}
					else if(chan.canSend) {
						context.isLocked = false;
						chan.send(context.vstack[context.vstackPos]);
						context.ostackPos --;
						context.pc ++;
					}
					else {
						context.isLocked = true;
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else
							continue contextsLabel;
					}
					break;
				case Send_Object:
					GrObjectChannel chan = cast(GrObjectChannel)context.ostack[context.ostackPos - 1];
					if(!chan.isOwned) {
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isLocked = true;
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else {
							context.ostackPos -= 2;
							raise(context, "Channel not owned");
						}
					}
					else if(chan.canSend) {
						context.isLocked = false;
						chan.send(context.ostack[context.ostackPos]);
						context.ostack[context.ostackPos - 1] = context.ostack[context.ostackPos];
						context.ostackPos --;
						context.pc ++;
					}
					else {
						context.isLocked = true;
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else
							continue contextsLabel;
					}
					break;
				case Receive_Int:
					GrIntChannel chan = cast(GrIntChannel)context.ostack[context.ostackPos];
					if(!chan.isOwned) {
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isLocked = true;
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else {
							context.ostackPos --;
							raise(context, "Channel not owned");
						}
					}
					else if(chan.canReceive) {
						context.isLocked = false;
						context.istackPos ++;
						context.istack[context.istackPos] = chan.receive();
						context.ostackPos --;
						context.pc ++;
					}
					else {
						chan.setReceiverReady();
						context.isLocked = true;
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else
							continue contextsLabel;
					}
					break;
				case Receive_Float:
					GrFloatChannel chan = cast(GrFloatChannel)context.ostack[context.ostackPos];
					if(!chan.isOwned) {
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isLocked = true;
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else {
							context.ostackPos --;
							raise(context, "Channel not owned");
						}
					}
					else if(chan.canReceive) {
						context.isLocked = false;
						context.fstackPos ++;
						context.fstack[context.fstackPos] = chan.receive();
						context.ostackPos --;
						context.pc ++;
					}
					else {
						chan.setReceiverReady();
						context.isLocked = true;
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else
							continue contextsLabel;
					}
					break;
				case Receive_String:
					GrStringChannel chan = cast(GrStringChannel)context.ostack[context.ostackPos];
					if(!chan.isOwned) {
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isLocked = true;
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else {
							context.ostackPos --;
							raise(context, "Channel not owned");
						}
					}
					else if(chan.canReceive) {
						context.isLocked = false;
						context.sstackPos ++;
						context.sstack[context.sstackPos] = chan.receive();
						context.ostackPos --;
						context.pc ++;
					}
					else {
						chan.setReceiverReady();
						context.isLocked = true;
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else
							continue contextsLabel;
					}
					break;
				case Receive_Variant:
					GrVariantChannel chan = cast(GrVariantChannel)context.ostack[context.ostackPos];
					if(!chan.isOwned) {
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isLocked = true;
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else {
							context.ostackPos --;
							raise(context, "Channel not owned");
						}
					}
					else if(chan.canReceive) {
						context.isLocked = false;
						context.vstackPos ++;
						context.vstack[context.vstackPos] = chan.receive();
						context.ostackPos --;
						context.pc ++;
					}
					else {
						chan.setReceiverReady();
						context.isLocked = true;
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else
							continue contextsLabel;
					}
					break;
				case Receive_Object:
					GrObjectChannel chan = cast(GrObjectChannel)context.ostack[context.ostackPos];
					if(!chan.isOwned) {
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isLocked = true;
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else {
							context.ostackPos --;
							raise(context, "Channel not owned");
						}
					}
					else if(chan.canReceive) {
						context.isLocked = false;
						context.ostack[context.ostackPos] = chan.receive();
						context.pc ++;
					}
					else {
						chan.setReceiverReady();
						context.isLocked = true;
						if(context.isEvaluatingChannel) {
							context.restoreState();
							context.isEvaluatingChannel = false;
							context.pc = context.selectPositionJump;
						}
						else
							continue contextsLabel;
					}
					break;
				case StartSelectChannel:
					context.pushState();
					context.pc ++;
					break;
				case EndSelectChannel:
					context.popState();
					context.pc ++;
					break;
				case TryChannel:
					if(context.isEvaluatingChannel)
						raise(context, "Already inside a select");
					context.isEvaluatingChannel = true;
					context.selectPositionJump = context.pc + grGetInstructionSignedValue(opcode);
					context.pc ++;
					break;
				case CheckChannel:
					if(!context.isEvaluatingChannel)
						raise(context, "Not inside a select");
					context.isEvaluatingChannel = false;
					context.restoreState();
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
				case ShiftStack_Variant:
					context.vstackPos += grGetInstructionSignedValue(opcode);
					context.pc ++;
					break;
                case ShiftStack_Object:
					context.ostackPos += grGetInstructionSignedValue(opcode);
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
				case LocalStore_Variant:
					context.vlocals[context.localsPos + grGetInstructionUnsignedValue(opcode)] = context.vstack[context.vstackPos];
                    context.vstackPos --;	
					context.pc ++;
					break;
                case LocalStore_Ref:
                    context.vstack[context.vstackPos - 1].storeRef(context, context.vstack[context.vstackPos]);
                    context.vstackPos -= 2;
                    context.pc ++;
                    break;
                case LocalStore_Object:
					context.olocals[context.localsPos + grGetInstructionUnsignedValue(opcode)] = context.ostack[context.ostackPos];
                    context.ostackPos --;	
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
				case LocalStore2_Variant:
					context.vlocals[context.localsPos + grGetInstructionUnsignedValue(opcode)] = context.vstack[context.vstackPos];
					context.pc ++;
					break;
                case LocalStore2_Ref:
                    context.vstackPos --;
                    context.vstack[context.vstackPos].storeRef(context, context.vstack[context.vstackPos + 1]);
                    context.pc ++;
                    break;
                case LocalStore2_Object:
					context.olocals[context.localsPos + grGetInstructionUnsignedValue(opcode)] = context.ostack[context.ostackPos];
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
				case LocalLoad_Variant:
                    context.vstackPos ++;
					context.vstack[context.vstackPos] = context.vlocals[context.localsPos + grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
                case LocalLoad_Object:
                    context.ostackPos ++;
					context.ostack[context.ostackPos] = context.olocals[context.localsPos + grGetInstructionUnsignedValue(opcode)];
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
				case GlobalStore_Variant:
					_vglobals[grGetInstructionUnsignedValue(opcode)] = context.vstack[context.vstackPos];
                    context.vstackPos --;	
					context.pc ++;
					break;
                case GlobalStore_Object:
					_oglobals[grGetInstructionUnsignedValue(opcode)] = context.ostack[context.ostackPos];
                    context.ostackPos --;	
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
				case GlobalStore2_Variant:
					_vglobals[grGetInstructionUnsignedValue(opcode)] = context.vstack[context.vstackPos];
					context.pc ++;
					break;
                case GlobalStore2_Object:
					_oglobals[grGetInstructionUnsignedValue(opcode)] = context.ostack[context.ostackPos];
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
				case GlobalLoad_Variant:
                    context.vstackPos ++;
					context.vstack[context.vstackPos] = _vglobals[grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
                case GlobalLoad_Object:
                    context.ostackPos ++;
					context.ostack[context.ostackPos] = _oglobals[grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
                case GetField:
					context.ostack[context.ostackPos] = cast(void*)((cast(GrObjectValue)context.ostack[context.ostackPos]).fields[grGetInstructionUnsignedValue(opcode)]);
					context.pc ++;
                    break;
                case FieldStore_Int:
                    (cast(GrFieldValue)context.ostack[context.ostackPos]).ivalue = context.istack[context.istackPos];
                    context.istackPos += grGetInstructionSignedValue(opcode);
                    context.ostackPos --;
					context.pc ++;
                    break;
                case FieldLoad_Int:
                    context.istackPos ++;
					context.istack[context.istackPos] = (cast(GrFieldValue)context.ostack[context.ostackPos]).ivalue;
                    context.ostackPos += grGetInstructionSignedValue(opcode);
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
				case GlobalPush_Variant:
					uint nbParams = grGetInstructionUnsignedValue(opcode);
					for(uint i = 1u; i <= nbParams; i++)
						_vglobalStack ~= context.vstack[(context.vstackPos - nbParams) + i];
					context.vstackPos -= nbParams;
					context.pc ++;
					break;
                case GlobalPush_Object:
					uint nbParams = grGetInstructionUnsignedValue(opcode);
					for(uint i = 1u; i <= nbParams; i++)
						_oglobalStack ~= context.ostack[(context.ostackPos - nbParams) + i];
					context.ostackPos -= nbParams;
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
				case GlobalPop_Variant:
                    context.vstackPos ++;
					context.vstack[context.vstackPos] = _vglobalStack[$ - 1];
					_vglobalStack.length --;
					context.pc ++;
					break;
                case GlobalPop_Object:
                    context.ostackPos ++;
					context.ostack[context.ostackPos] = _oglobalStack[$ - 1];
					_oglobalStack.length --;
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
				case Equal_Variant:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.vstack[context.vstackPos - 1] == context.vstack[context.vstackPos];
					context.vstackPos -= 2;
					context.pc ++;
					break;
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
				case NotEqual_Variant:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.vstack[context.vstackPos - 1] != context.vstack[context.vstackPos];
					context.vstackPos -= 2;
					context.pc ++;
					break;
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
				case GreaterOrEqual_Variant:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.vstack[context.vstackPos - 1].operationComparison!">="(context, context.vstack[context.vstackPos]);
					context.vstackPos -= 2;
					context.pc ++;
					break;
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
				case LesserOrEqual_Variant:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.vstack[context.vstackPos - 1].operationComparison!"<="(context, context.vstack[context.vstackPos]);
					context.vstackPos -= 2;
					context.pc ++;
					break;
				case Greater_Int:
					context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] > context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case Greater_Float:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.fstack[context.fstackPos - 1] > context.fstack[context.fstackPos];
					context.fstackPos -= 2;
					context.pc ++;
					break;
				case Greater_Variant:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.vstack[context.vstackPos - 1].operationComparison!">"(context, context.vstack[context.vstackPos]);
					context.vstackPos -= 2;
					context.pc ++;
					break;
				case Lesser_Int:
					context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] < context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case Lesser_Float:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.fstack[context.fstackPos - 1] < context.fstack[context.fstackPos];
					context.fstackPos -= 2;
					context.pc ++;
					break;
				case Lesser_Variant:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.vstack[context.vstackPos - 1].operationComparison!"<"(context, context.vstack[context.vstackPos]);
					context.vstackPos -= 2;
					context.pc ++;
					break;
				case And_Int:
					context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] && context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case And_Variant:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.vstack[context.vstackPos - 1].operationAnd(context, context.vstack[context.vstackPos]);
					context.vstackPos -= 2;
					context.pc ++;
					break;
				case Or_Int:
					context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] || context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case Or_Variant:
                    context.istackPos ++;
					context.istack[context.istackPos] = context.vstack[context.vstackPos - 1].operationOr(context, context.vstack[context.vstackPos]);
					context.vstackPos -= 2;
					context.pc ++;
					break;
				case Not_Int:
					context.istack[context.istackPos] = !context.istack[context.istackPos];
					context.pc ++;
					break;
				case Not_Variant:
					context.vstack[context.vstackPos].operationNot(context);
					context.pc ++;
					break;
				case Add_Int:
					context.istackPos --;
					context.istack[context.istackPos] += context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case Add_Float:
					context.fstackPos --;
					context.fstack[context.fstackPos] += context.fstack[context.fstackPos + 1];
					context.pc ++;
					break;
				case Add_Variant:
					context.vstackPos --;
					context.vstack[context.vstackPos] += context.vstack[context.vstackPos + 1];
					context.pc ++;
					break;
				case Concatenate_String:
					context.sstackPos --;
					context.sstack[context.sstackPos] ~= context.sstack[context.sstackPos + 1];
					context.pc ++;
					break;
				case Concatenate_Variant:
					context.vstackPos --;
					context.vstack[context.vstackPos] ~= context.vstack[context.vstackPos + 1];
					context.pc ++;
					break;
				case Substract_Int:
					context.istackPos --;
					context.istack[context.istackPos] -= context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case Substract_Float:
					context.fstackPos --;
					context.fstack[context.fstackPos] -= context.fstack[context.fstackPos + 1];
					context.pc ++;
					break;
				case Substract_Variant:
					context.vstackPos --;
					context.vstack[context.vstackPos] -= context.vstack[context.vstackPos + 1];
					context.pc ++;
					break;
				case Multiply_Int:
					context.istackPos --;
					context.istack[context.istackPos] *= context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case Multiply_Float:
					context.fstackPos --;
					context.fstack[context.fstackPos] *= context.fstack[context.fstackPos + 1];
					context.pc ++;
					break;
				case Multiply_Variant:
					context.vstackPos --;
					context.vstack[context.vstackPos] *= context.vstack[context.vstackPos + 1];
					context.pc ++;
					break;
				case Divide_Int:
					context.istackPos --;
					context.istack[context.istackPos] /= context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case Divide_Float:
					context.fstackPos --;
					context.fstack[context.fstackPos] /= context.fstack[context.fstackPos + 1];
					context.pc ++;
					break;
				case Divide_Variant:
					context.vstackPos --;
					context.vstack[context.vstackPos] /= context.vstack[context.vstackPos + 1];
					context.pc ++;
					break;
				case Remainder_Int:
					context.istackPos --;
					context.istack[context.istackPos] %= context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case Remainder_Float:
					context.fstackPos --;
					context.fstack[context.fstackPos] %= context.fstack[context.fstackPos + 1];
					context.pc ++;
					break;
				case Remainder_Variant:
					context.vstackPos --;
					context.vstack[context.vstackPos] %= context.vstack[context.vstackPos + 1];
					context.pc ++;
					break;
				case Negative_Int:
					context.istack[context.istackPos] = -context.istack[context.istackPos];
					context.pc ++;
					break;
				case Negative_Float:
					context.fstack[context.fstackPos] = -context.fstack[context.fstackPos];
					context.pc ++;
					break;
				case Negative_Variant:
					context.vstack[context.vstackPos] = -context.vstack[context.vstackPos];
					context.pc ++;
					break;
				case Increment_Int:
					context.istack[context.istackPos] ++;
					context.pc ++;
					break;
				case Increment_Float:
					context.fstack[context.fstackPos] += 1f;
					context.pc ++;
					break;
				case Increment_Variant:
					context.vstack[context.vstackPos] ++;
					context.pc ++;
					break;
				case Decrement_Int:
					context.istack[context.istackPos] --;
					context.pc ++;
					break;
				case Decrement_Float:
					context.fstack[context.fstackPos] -= 1f;
					context.pc ++;
					break;
				case Decrement_Variant:
					context.vstack[context.vstackPos] --;
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
                    if(!context.stackPos && context.isKilled) {
                        _contexts.markInternalForRemoval(index);
					    continue contextsLabel;
                    }
                    //Check for deferred calls.
                    else if(context.callStack[context.stackPos].deferStack.length) {
                        //Pop the last defer and run it.
                        context.pc = context.callStack[context.stackPos].deferStack[$ - 1];
                        context.callStack[context.stackPos].deferStack.length --;
                    }
                    else {
                        //Then returns to the last context.
                        context.stackPos --;
                        context.pc = context.callStack[context.stackPos].retPosition;
                        context.localsPos -= context.callStack[context.stackPos].localStackSize;
                    }
					break;
                case Unwind:
                    //If another task was killed by an exception,
                    //we might end up there if the task has just been spawned.
                    if(!context.stackPos) {
                        _contexts.markInternalForRemoval(index);
					    continue contextsLabel;
                    }
                    //Check for deferred calls.
                    else if(context.callStack[context.stackPos].deferStack.length) {
                        //Pop the next defer and run it.
                        context.pc = context.callStack[context.stackPos].deferStack[$ - 1];
                        context.callStack[context.stackPos].deferStack.length --;
                    }
                    else if(context.isKilled) {
                        if(context.stackPos) {
                            //Then returns to the last context without modifying the pc.
                            context.stackPos --;
                            context.localsPos -= context.callStack[context.stackPos].localStackSize;
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
                            //Then returns to the last context without modifying the pc.
                            context.stackPos --;
                            context.localsPos -= context.callStack[context.stackPos].localStackSize;

                            //Exception handler found in the current function, just jump.
                            if(context.callStack[context.stackPos].exceptionHandlers.length) {
                                context.pc = context.callStack[context.stackPos].exceptionHandlers[$ - 1];
                            }
                        }
                        else {
                            //Kill the others.
                            foreach(coroutine; _contexts) {
                                coroutine.pc = cast(uint)(_opcodes.length - 1);
                                coroutine.isKilled = true;
                            }
							_contextsToSpawn.reset();

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
                        //Then returns to the last context.
                        context.stackPos --;
                        context.pc = context.callStack[context.stackPos].retPosition;
                        context.localsPos -= context.callStack[context.stackPos].localStackSize;
                    }
                    break;
                case Defer:
                    context.callStack[context.stackPos].deferStack ~= context.pc + grGetInstructionSignedValue(opcode);
					context.pc ++;
                    break;
				case LocalStack:
                    const auto stackSize = grGetInstructionUnsignedValue(opcode);
					context.callStack[context.stackPos].localStackSize = stackSize;
					context.pc ++;
					break;
				case Call:
                    if(((context.stackPos >> 1) + 1) >= context.callStackLimit)
                        context.doubleCallStackSize();
					context.localsPos += context.callStack[context.stackPos].localStackSize;
					context.callStack[context.stackPos].retPosition = context.pc + 1u;
					context.stackPos ++;
					context.pc = grGetInstructionUnsignedValue(opcode);
					break;
				case AnonymousCall:
                    if((context.stackPos >> 1) >= context.callStackLimit)
                        context.doubleCallStackSize();
					context.localsPos += context.callStack[context.stackPos].localStackSize;
					context.callStack[context.stackPos].retPosition = context.pc + 1u;
					context.stackPos ++;
					context.pc = context.istack[context.istackPos];
					context.istackPos --;
					break;
                case VariantCall:
                    _meta = _sconsts[grGetInstructionUnsignedValue(opcode)];
                    context.vstack[context.vstackPos].call(context);
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
                    GrArrayValue ary = new GrArrayValue;
                    const auto arySize = grGetInstructionUnsignedValue(opcode);
                    for(int i = arySize - 1; i >= 0; i --) {
                        ary.data ~= context.vstack[context.vstackPos - i];
                    }
                    context.vstackPos -= arySize;
                    context.ostackPos ++;
                    context.ostack[context.ostackPos] = cast(void*)ary;
                    context.pc ++;
                    break;
				case Length_Array:
                    context.istackPos ++;
					context.istack[context.istackPos] = cast(int)((cast(GrArrayValue)context.ostack[context.ostackPos]).data.length);
                    context.ostackPos --;
					context.pc ++;
					break;
				case Index_Array:
					GrArrayValue ary = cast(GrArrayValue)context.ostack[context.ostackPos];
                    const auto idx = context.istack[context.istackPos];
                    if(idx >= ary.data.length) {
                        raise(context, "Array overflow");
                        break;
                    }
                    context.vstackPos ++;
                    context.vstack[context.vstackPos].setRef(context, &ary.data[idx]);
					context.ostackPos --;					
					context.istackPos --;					
					context.pc ++;
					break;
                case Index_Variant:
                    context.vstack[context.vstackPos].setArrayIndex(context, context.istack[context.istackPos]);
                    context.istackPos --;
					context.pc ++;
					break;
				case Copy_Array:
                    context.ostack[context.ostackPos] = cast(void*)(
						new GrArrayValue(cast(GrArrayValue)context.ostack[context.ostackPos])
						);
					context.pc ++;
					break;
				case Copy_Variant:
					context.vstack[context.vstackPos] = context.vstack[context.vstackPos].copy();
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