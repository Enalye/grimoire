/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.engine;

import std.string;
import std.array;
import std.conv;
import std.math;
import std.algorithm.mutation: swapAt;

import grimoire.compiler;
import grimoire.assembly;
import grimoire.runtime.context;
import grimoire.runtime.array;
import grimoire.runtime.object;
import grimoire.runtime.channel;
import grimoire.runtime.indexedarray;

/**
Grimoire's virtual machine.
*/
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
        int[] _iglobals;
        /// Global floating point variables.
        float[] _fglobals;
        /// Global string variables.
        dstring[] _sglobals;
        void*[] _oglobals;

        /// Global integral stack.
        int[] _iglobalStackIn, _iglobalStackOut;
        /// Global floating point stack.
        float[] _fglobalStackIn, _fglobalStackOut;
        /// Global string stack.
        dstring[] _sglobalStackIn, _sglobalStackOut;
        /// Global object stack.
        void*[] _oglobalStackIn, _oglobalStackOut;

        /// Context array.
		DynamicIndexedArray!GrContext _contexts, _contextsToSpawn;
    
        /// Global panic state.
        /// It means that the throwing context didn't handle the exception.
        bool _isPanicking;
        /// Unhandled panic message.
        dstring _panicMessage;

        /// Extra type compiler information.
        dstring _meta;

        /// Primitives and types database.
        GrData _data;
    }

	/// External way of stopping the VM.
    shared bool isRunning = true;

    @property {
        /// Check if there is a coroutine currently running.
        bool hasCoroutines() const { return (_contexts.length + _contextsToSpawn.length) > 0uL; }

        /// Whether the whole VM has panicked, true if an unhandled error occurred.
        bool isPanicking() const { return _isPanicking; }

        /// The unhandled error message.
        dstring panicMessage() const { return _panicMessage; }

        /// Extra type compiler information.
        dstring meta() const { return _meta; }
		/// Ditto
        dstring meta(dstring newMeta) { return _meta = newMeta; }
    }

    /// Default.
	this() {}

    /// Load the bytecode.
	this(GrData data, GrBytecode bytecode) {
		load(data, bytecode);
	}

    private void initialize() {
        _contexts = new DynamicIndexedArray!GrContext;
		_contextsToSpawn = new DynamicIndexedArray!GrContext;
    }

    /// Load the bytecode.
	final void load(GrData data, GrBytecode bytecode) {
        initialize();
        _data = data;
		_iconsts = bytecode.iconsts.idup;
		_fconsts = bytecode.fconsts.idup;
		_sconsts = bytecode.sconsts.idup;
		_opcodes = bytecode.opcodes.idup;
		_iglobals = new int[bytecode.iglobalsCount];
        _fglobals = new float[bytecode.fglobalsCount];
        _sglobals = new dstring[bytecode.sglobalsCount];
        _oglobals = new void*[bytecode.oglobalsCount];
        _events = bytecode.events;
	}

    /**
	Create the main context.
	You must call this function before running the vm.
	---
	main {
		printl("Hello World !");
	}
	---
    */
    void spawn() {
		_contexts.push(new GrContext(this));
	}

	/**
	Checks whether an event exists. \
	`eventName` must be the mangled name of the event.
	*/
    bool hasEvent(dstring eventName) {
        return (eventName in _events) !is null;
    }

	/**
	Spawn a new coroutine registered as an event. \
	`eventName` must be the mangled name of the event.
	---
	event mycoroutine() {
		printl("mycoroutine was created !");
	}
	---
	*/
    GrContext spawnEvent(dstring eventName) {
        const auto event = eventName in _events;
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

	/**
	Raise an error message and attempt to recover from it. \
	The error is raised inside a coroutine. \
	___
	For each function it unwinds, it'll search for a `try/catch` that captures it. \
	If none is found, it'll execute every `defer` statements inside the function and
	do the same for the next function in the callstack.
	___
	If nothing catches the error inside the coroutine, the VM enters in a panic state. \
	Every coroutines will then execute their `defer` statements and be killed.
	*/
    void raise(GrContext context, dstring message) {
        if(context.isPanicking)
            return;
        //Error message.
        _sglobalStackIn ~= message;
        
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
            context.ilocalsPos -= context.callStack[context.stackPos].ilocalStackSize;
            context.flocalsPos -= context.callStack[context.stackPos].flocalStackSize;
            context.slocalsPos -= context.callStack[context.stackPos].slocalStackSize;
            context.olocalsPos -= context.callStack[context.stackPos].olocalStackSize;

			if(_isDebug)
				debugProfileEnd();
        }
        else {
            //Kill the others.
            foreach(coroutine; _contexts) {
                coroutine.pc = cast(uint)(cast(int) _opcodes.length - 1);
                coroutine.isKilled = true;
            }
			_contextsToSpawn.reset();

            //The VM is now panicking.
            _isPanicking = true;
            _panicMessage = _sglobalStackIn[$ - 1];
            _sglobalStackIn.length --;
        }
    }

	/**
	Marks each coroutine as killed and prevents any new coroutine from spawning.
	*/
    private void killAll() {
        foreach(coroutine; _contexts) {
            coroutine.pc = cast(uint)(cast(int) _opcodes.length - 1);
            coroutine.isKilled = true;
        }
        _contextsToSpawn.reset();
    }

    /// Run the vm until all the contexts are finished or in yield.
	void process() {
		if(_contextsToSpawn.length) {
			for(int index = cast(int) _contextsToSpawn.length - 1; index >= 0; index --)
				_contexts.push(_contextsToSpawn[index]);
			_contextsToSpawn.reset();
			import std.algorithm.mutation: swap;
			swap(_iglobalStackIn, _iglobalStackOut);
			swap(_fglobalStackIn, _fglobalStackOut);
			swap(_sglobalStackIn, _sglobalStackOut);
			swap(_oglobalStackIn, _oglobalStackOut);
		}
		contextsLabel: for(uint index = 0u; index < _contexts.length; index ++) {
			GrContext context = _contexts.data[index];
			while(isRunning) {
				uint opcode = _opcodes[context.pc];
				switch (grGetInstructionOpcode(opcode)) with(GrOpcode) {
                case nop:
                    context.pc ++;
                    break;
                case raise_:
                    if(!context.isPanicking) {
                        //Error message.
                        _sglobalStackIn ~= context.sstack[context.sstackPos];
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
                        context.ilocalsPos -= context.callStack[context.stackPos].ilocalStackSize;
                        context.flocalsPos -= context.callStack[context.stackPos].flocalStackSize;
                        context.slocalsPos -= context.callStack[context.stackPos].slocalStackSize;
                        context.olocalsPos -= context.callStack[context.stackPos].olocalStackSize;

						if(_isDebug)
							debugProfileEnd();
                    }
                    else {
                        //Kill the others.
                        killAll();

                        //The VM is now panicking.
                        _isPanicking = true;
                        _panicMessage = _sglobalStackIn[$ - 1];
                        _sglobalStackIn.length --;

                        //Every deferred call has been executed, now die.
                        _contexts.markInternalForRemoval(index);
                        continue contextsLabel;
                    }
                    break;
                case try_:
                    context.callStack[context.stackPos].exceptionHandlers ~= context.pc + grGetInstructionSignedValue(opcode);
                    context.pc ++;
                    break;
                case catch_:
                    context.callStack[context.stackPos].exceptionHandlers.length --;
                    if(context.isPanicking) {
                        context.isPanicking = false;
                        context.pc ++;
                    }
                    else {
                        context.pc += grGetInstructionSignedValue(opcode);
                    }
                    break;
				case task:
					GrContext newCoro = new GrContext(this);
					newCoro.pc = grGetInstructionUnsignedValue(opcode);
					_contextsToSpawn.push(newCoro);
					context.pc ++;
					break;
				case anonymousTask:
					GrContext newCoro = new GrContext(this);
					newCoro.pc = context.istack[context.istackPos];
					context.istackPos --;
					_contextsToSpawn.push(newCoro);
					context.pc ++;
					break;
				case kill_:
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
                        context.ilocalsPos -= context.callStack[context.stackPos].ilocalStackSize;
                        context.flocalsPos -= context.callStack[context.stackPos].flocalStackSize;
                        context.slocalsPos -= context.callStack[context.stackPos].slocalStackSize;
                        context.olocalsPos -= context.callStack[context.stackPos].olocalStackSize;

                        //Flag as killed so the entire stack will be unwinded.
                        context.isKilled = true;
                    }
                    else {
                        //No need to flag if the call stack is empty without any deferred statement.
                        _contexts.markInternalForRemoval(index);
						continue contextsLabel;
                    }
					break;
				case killAll_:
					killAll();
					continue contextsLabel;
				case yield:
					context.pc ++;
					continue contextsLabel;
                case new_:
                    context.ostackPos ++;
					if(context.ostackPos == context.ostack.length)
						context.ostack.length *= 2;
					context.ostack[context.ostackPos] = cast(void*)new GrObject(
						_data._classTypes[grGetInstructionUnsignedValue(opcode)]
						);
					context.pc ++;
                    break;
				case channel_Int:
					context.ostackPos ++;
					if(context.ostackPos == context.ostack.length)
						context.ostack.length *= 2;
					context.ostack[context.ostackPos] = cast(void*)new GrIntChannel(grGetInstructionUnsignedValue(opcode));
					context.pc ++;
					break;
				case channel_Float:
					context.ostackPos ++;
					if(context.ostackPos == context.ostack.length)
						context.ostack.length *= 2;
					context.ostack[context.ostackPos] = cast(void*)new GrFloatChannel(grGetInstructionUnsignedValue(opcode));
					context.pc ++;
					break;
				case channel_String:
					context.ostackPos ++;
					if(context.ostackPos == context.ostack.length)
						context.ostack.length *= 2;
					context.ostack[context.ostackPos] = cast(void*)new GrStringChannel(grGetInstructionUnsignedValue(opcode));
					context.pc ++;
					break;
				case channel_Object:
					context.ostackPos ++;
					if(context.ostackPos == context.ostack.length)
						context.ostack.length *= 2;
					context.ostack[context.ostackPos] = cast(void*)new GrObjectChannel(grGetInstructionUnsignedValue(opcode));
					context.pc ++;
					break;
				case send_Int:
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
				case send_Float:
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
				case send_String:
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
				case send_Object:
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
				case receive_Int:
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
						if(context.istackPos == context.istack.length)
							context.istack.length *= 2;
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
				case receive_Float:
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
						if(context.fstackPos == context.fstack.length)
							context.fstack.length *= 2;
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
				case receive_String:
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
						if(context.sstackPos == context.sstack.length)
							context.sstack.length *= 2;
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
				case receive_Object:
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
				case startSelectChannel:
					context.pushState();
					context.pc ++;
					break;
				case endSelectChannel:
					context.popState();
					context.pc ++;
					break;
				case tryChannel:
					if(context.isEvaluatingChannel)
						raise(context, "Already inside a select");
					context.isEvaluatingChannel = true;
					context.selectPositionJump = context.pc + grGetInstructionSignedValue(opcode);
					context.pc ++;
					break;
				case checkChannel:
					if(!context.isEvaluatingChannel)
						raise(context, "Not inside a select");
					context.isEvaluatingChannel = false;
					context.restoreState();
					context.pc ++;
					break;
				case shiftStack_Int:
					context.istackPos += grGetInstructionSignedValue(opcode);
					context.pc ++;
					break;
				case shiftStack_Float:
					context.fstackPos += grGetInstructionSignedValue(opcode);
					context.pc ++;
					break;
				case shiftStack_String:
					context.sstackPos += grGetInstructionSignedValue(opcode);
					context.pc ++;
					break;
                case shiftStack_Object:
					context.ostackPos += grGetInstructionSignedValue(opcode);
					context.pc ++;
					break;
				case localStore_Int:
					context.ilocals[context.ilocalsPos + grGetInstructionUnsignedValue(opcode)] = context.istack[context.istackPos];
                    context.istackPos --;
					context.pc ++;
					break;
				case localStore_Float:
					context.flocals[context.flocalsPos + grGetInstructionUnsignedValue(opcode)] = context.fstack[context.fstackPos];
                    context.fstackPos --;
					context.pc ++;
					break;
				case localStore_String:
					context.slocals[context.slocalsPos + grGetInstructionUnsignedValue(opcode)] = context.sstack[context.sstackPos];		
                    context.sstackPos --;
					context.pc ++;
					break;
                case localStore_Object:
					context.olocals[context.olocalsPos + grGetInstructionUnsignedValue(opcode)] = context.ostack[context.ostackPos];
                    context.ostackPos --;
					context.pc ++;
					break;
                case localStore2_Int:
					context.ilocals[context.ilocalsPos + grGetInstructionUnsignedValue(opcode)] = context.istack[context.istackPos];
					context.pc ++;
					break;
				case localStore2_Float:
					context.flocals[context.flocalsPos + grGetInstructionUnsignedValue(opcode)] = context.fstack[context.fstackPos];
					context.pc ++;
					break;
				case localStore2_String:
					context.slocals[context.slocalsPos + grGetInstructionUnsignedValue(opcode)] = context.sstack[context.sstackPos];		
					context.pc ++;
					break;
                case localStore2_Object:
					context.olocals[context.olocalsPos + grGetInstructionUnsignedValue(opcode)] = context.ostack[context.ostackPos];
					context.pc ++;
					break;
				case localLoad_Int:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] = context.ilocals[context.ilocalsPos + grGetInstructionUnsignedValue(opcode)];
                    context.pc ++;
					break;
				case localLoad_Float:
                    context.fstackPos ++;
					if(context.fstackPos == context.fstack.length)
						context.fstack.length *= 2;
					context.fstack[context.fstackPos] = context.flocals[context.flocalsPos + grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
				case localLoad_String:
                    context.sstackPos ++;
					if(context.sstackPos == context.sstack.length)
						context.sstack.length *= 2;
					context.sstack[context.sstackPos] = context.slocals[context.slocalsPos + grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
                case localLoad_Object:
                    context.ostackPos ++;
					if(context.ostackPos == context.ostack.length)
						context.ostack.length *= 2;
					context.ostack[context.ostackPos] = context.olocals[context.olocalsPos + grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
                case globalStore_Int:
					_iglobals[grGetInstructionUnsignedValue(opcode)] = context.istack[context.istackPos];
                    context.istackPos --;	
					context.pc ++;
					break;
				case globalStore_Float:
					_fglobals[grGetInstructionUnsignedValue(opcode)] = context.fstack[context.fstackPos];
                    context.fstackPos --;	
					context.pc ++;
					break;
				case globalStore_String:
					_sglobals[grGetInstructionUnsignedValue(opcode)] = context.sstack[context.sstackPos];		
                    context.sstackPos --;	
					context.pc ++;
					break;
                case globalStore_Object:
					_oglobals[grGetInstructionUnsignedValue(opcode)] = context.ostack[context.ostackPos];
                    context.ostackPos --;	
					context.pc ++;
					break;
                case globalStore2_Int:
					_iglobals[grGetInstructionUnsignedValue(opcode)] = context.istack[context.istackPos];
					context.pc ++;
					break;
				case globalStore2_Float:
					_fglobals[grGetInstructionUnsignedValue(opcode)] = context.fstack[context.fstackPos];
					context.pc ++;
					break;
				case globalStore2_String:
					_sglobals[grGetInstructionUnsignedValue(opcode)] = context.sstack[context.sstackPos];		
					context.pc ++;
					break;
                case globalStore2_Object:
					_oglobals[grGetInstructionUnsignedValue(opcode)] = context.ostack[context.ostackPos];
					context.pc ++;
					break;
				case globalLoad_Int:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] = _iglobals[grGetInstructionUnsignedValue(opcode)];
                    context.pc ++;
					break;
				case globalLoad_Float:
                    context.fstackPos ++;
					if(context.fstackPos == context.fstack.length)
						context.fstack.length *= 2;
					context.fstack[context.fstackPos] = _fglobals[grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
				case globalLoad_String:
                    context.sstackPos ++;
					if(context.sstackPos == context.sstack.length)
						context.sstack.length *= 2;
					context.sstack[context.sstackPos] = _sglobals[grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
                case globalLoad_Object:
                    context.ostackPos ++;
					if(context.ostackPos == context.ostack.length)
						context.ostack.length *= 2;
					context.ostack[context.ostackPos] = _oglobals[grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
				case refStore_Int:
                    *(cast(int*)context.ostack[context.ostackPos]) = context.istack[context.istackPos];
                    context.ostackPos --;
                    context.istackPos --;
                    context.pc ++;
                    break;
                case refStore_Float:
                    *(cast(float*)context.ostack[context.ostackPos]) = context.fstack[context.fstackPos];
                    context.ostackPos --;
                    context.fstackPos --;
                    context.pc ++;
                    break;
                case refStore_String:
                    *(cast(dstring*)context.ostack[context.ostackPos]) = context.sstack[context.sstackPos];
                    context.ostackPos --;
                    context.sstackPos --;
                    context.pc ++;
                    break;
                case refStore_Object:
                    *(cast(void**)context.ostack[context.ostackPos - 1]) = context.ostack[context.ostackPos];
                    context.ostackPos -= 2;
                    context.pc ++;
                    break;
                case refStore2_Int:
                    *(cast(int*)context.ostack[context.ostackPos]) = context.istack[context.istackPos];
                    context.ostackPos --;
                    context.pc ++;
                    break;
                case refStore2_Float:
                    *(cast(float*)context.ostack[context.ostackPos]) = context.fstack[context.fstackPos];
                    context.ostackPos --;
                    context.pc ++;
                    break;
                case refStore2_String:
                    *(cast(dstring*)context.ostack[context.ostackPos]) = context.sstack[context.sstackPos];
                    context.ostackPos --;
                    context.pc ++;
                    break;
                case refStore2_Object:
                    *(cast(void**)context.ostack[context.ostackPos - 1]) = context.ostack[context.ostackPos];
                    context.ostack[context.ostackPos - 1] = context.ostack[context.ostackPos];
                    context.ostackPos --;
                    context.pc ++;
                    break;
                case fieldStore_Int:
                    (cast(GrField)context.ostack[context.ostackPos]).ivalue = context.istack[context.istackPos];
                    context.istackPos += grGetInstructionSignedValue(opcode);
                    context.ostackPos --;
					context.pc ++;
                    break;
				case fieldStore_Float:
                    (cast(GrField)context.ostack[context.ostackPos]).fvalue = context.fstack[context.fstackPos];
                    context.fstackPos += grGetInstructionSignedValue(opcode);
                    context.ostackPos --;
					context.pc ++;
                    break;
				case fieldStore_String:
                    (cast(GrField)context.ostack[context.ostackPos]).svalue = context.sstack[context.sstackPos];
                    context.sstackPos += grGetInstructionSignedValue(opcode);
                    context.ostackPos --;
					context.pc ++;
                    break;
				case fieldStore_Object:
					context.ostackPos --;
                    (cast(GrField)context.ostack[context.ostackPos]).ovalue = context.ostack[context.ostackPos + 1];
					context.ostack[context.ostackPos] = context.ostack[context.ostackPos + 1];
                    context.ostackPos += grGetInstructionSignedValue(opcode);
					context.pc ++;
                    break;
				case fieldLoad:
					context.ostack[context.ostackPos] = cast(void*)((cast(GrObject)context.ostack[context.ostackPos])._fields[grGetInstructionUnsignedValue(opcode)]);
					context.pc ++;
                    break;
                case fieldLoad_Int:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] = (cast(GrObject)context.ostack[context.ostackPos])._fields[grGetInstructionUnsignedValue(opcode)].ivalue;
                    context.ostackPos --;
					context.pc ++;
                    break;
				case fieldLoad_Float:
                    context.fstackPos ++;
					if(context.fstackPos == context.fstack.length)
						context.fstack.length *= 2;
					context.fstack[context.fstackPos] = (cast(GrObject)context.ostack[context.ostackPos])._fields[grGetInstructionUnsignedValue(opcode)].fvalue;
                    context.ostackPos --;
					context.pc ++;
                    break;
				case fieldLoad_String:
                    context.sstackPos ++;
					if(context.sstackPos == context.sstack.length)
						context.sstack.length *= 2;
					context.sstack[context.sstackPos] = (cast(GrObject)context.ostack[context.ostackPos])._fields[grGetInstructionUnsignedValue(opcode)].svalue;
                    context.ostackPos --;
					context.pc ++;
                    break;
				case fieldLoad_Object:
					context.ostack[context.ostackPos] = (cast(GrObject)context.ostack[context.ostackPos])._fields[grGetInstructionUnsignedValue(opcode)].ovalue;
					context.pc ++;
                    break;
				case fieldLoad2_Int:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					GrField field = (cast(GrObject)context.ostack[context.ostackPos])._fields[grGetInstructionUnsignedValue(opcode)];
					context.istack[context.istackPos] = field.ivalue;
					context.ostack[context.ostackPos] = cast(void*)field;
					context.pc ++;
                    break;
				case fieldLoad2_Float:
                    context.fstackPos ++;
					if(context.fstackPos == context.fstack.length)
						context.fstack.length *= 2;
					GrField field = (cast(GrObject)context.ostack[context.ostackPos])._fields[grGetInstructionUnsignedValue(opcode)];
					context.fstack[context.fstackPos] = field.fvalue;
					context.ostack[context.ostackPos] = cast(void*)field;
					context.pc ++;
                    break;
				case fieldLoad2_String:
                    context.sstackPos ++;
					if(context.sstackPos == context.sstack.length)
						context.sstack.length *= 2;
					GrField field = (cast(GrObject)context.ostack[context.ostackPos])._fields[grGetInstructionUnsignedValue(opcode)];
					context.sstack[context.sstackPos] = field.svalue;
					context.ostack[context.ostackPos] = cast(void*)field;
					context.pc ++;
                    break;
				case fieldLoad2_Object:
					context.ostackPos ++;
					if(context.ostackPos == context.ostack.length)
						context.ostack.length *= 2;
					GrField field = (cast(GrObject)context.ostack[context.ostackPos - 1])._fields[grGetInstructionUnsignedValue(opcode)];
					context.ostack[context.ostackPos] = field.ovalue;
					context.ostack[context.ostackPos - 1] = cast(void*)field;
					context.pc ++;
                    break;
				case const_Int:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] = _iconsts[grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
				case const_Float:
                    context.fstackPos ++;
					if(context.fstackPos == context.fstack.length)
						context.fstack.length *= 2;
					context.fstack[context.fstackPos] = _fconsts[grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
				case const_Bool:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] = grGetInstructionUnsignedValue(opcode);
					context.pc ++;
					break;
				case const_String:
                    context.sstackPos ++;
					if(context.sstackPos == context.sstack.length)
						context.sstack.length *= 2;
					context.sstack[context.sstackPos] = _sconsts[grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
					break;
                case const_Meta:
					_meta = _sconsts[grGetInstructionUnsignedValue(opcode)];
					context.pc ++;
                    break;
				case globalPush_Int:
					const uint nbParams = grGetInstructionUnsignedValue(opcode);
					for(uint i = 1u; i <= nbParams; i++)
						_iglobalStackOut ~= context.istack[(context.istackPos - nbParams) + i];
					context.istackPos -= nbParams;
					context.pc ++;
					break;
				case globalPush_Float:
					const uint nbParams = grGetInstructionUnsignedValue(opcode);
					for(uint i = 1u; i <= nbParams; i++)
						_fglobalStackOut ~= context.fstack[(context.fstackPos - nbParams) + i];
					context.fstackPos -= nbParams;
					context.pc ++;
					break;
				case globalPush_String:
					const uint nbParams = grGetInstructionUnsignedValue(opcode);
					for(uint i = 1u; i <= nbParams; i++)
						_sglobalStackOut ~= context.sstack[(context.sstackPos - nbParams) + i];
					context.sstackPos -= nbParams;
					context.pc ++;
					break;
                case globalPush_Object:
					const uint nbParams = grGetInstructionUnsignedValue(opcode);
					for(uint i = 1u; i <= nbParams; i++)
						_oglobalStackOut ~= context.ostack[(context.ostackPos - nbParams) + i];
					context.ostackPos -= nbParams;
					context.pc ++;
					break;
				case globalPop_Int:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] = _iglobalStackIn[$ - 1];
					_iglobalStackIn.length --;
					context.pc ++;
					break;
				case globalPop_Float:
                    context.fstackPos ++;
					if(context.fstackPos == context.fstack.length)
						context.fstack.length *= 2;
					context.fstack[context.fstackPos] = _fglobalStackIn[$ - 1];
					_fglobalStackIn.length --;
					context.pc ++;
					break;
				case globalPop_String:
                    context.sstackPos ++;
					if(context.sstackPos == context.sstack.length)
						context.sstack.length *= 2;
					context.sstack[context.sstackPos] = _sglobalStackIn[$ - 1];
					_sglobalStackIn.length --;
					context.pc ++;
					break;
                case globalPop_Object:
                    context.ostackPos ++;
					if(context.ostackPos == context.ostack.length)
						context.ostack.length *= 2;
					context.ostack[context.ostackPos] = _oglobalStackIn[$ - 1];
					_oglobalStackIn.length --;
					context.pc ++;
					break;
				case equal_Int:
                    context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] == context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case equal_Float:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] = context.fstack[context.fstackPos - 1] == context.fstack[context.fstackPos];
					context.fstackPos -= 2;
					context.pc ++;
					break;
				case equal_String:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] = context.sstack[context.sstackPos - 1] == context.sstack[context.sstackPos];
					context.sstackPos -= 2;
					context.pc ++;
					break;
				case notEqual_Int:
					context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] != context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case notEqual_Float:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] = context.fstack[context.fstackPos - 1] != context.fstack[context.fstackPos];
					context.fstackPos -= 2;
					context.pc ++;
					break;
				case notEqual_String:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] = context.sstack[context.sstackPos - 1] != context.sstack[context.sstackPos];
					context.sstackPos -= 2;
					context.pc ++;
					break;
				case greaterOrEqual_Int:
					context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] >= context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case greaterOrEqual_Float:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] = context.fstack[context.fstackPos - 1] >= context.fstack[context.fstackPos];
					context.fstackPos -= 2;
					context.pc ++;
					break;
				case lesserOrEqual_Int:
					context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] <= context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case lesserOrEqual_Float:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] = context.fstack[context.fstackPos - 1] <= context.fstack[context.fstackPos];
					context.fstackPos -= 2;
					context.pc ++;
					break;
				case greater_Int:
					context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] > context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case greater_Float:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] = context.fstack[context.fstackPos - 1] > context.fstack[context.fstackPos];
					context.fstackPos -= 2;
					context.pc ++;
					break;
				case lesser_Int:
					context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] < context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case lesser_Float:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] = context.fstack[context.fstackPos - 1] < context.fstack[context.fstackPos];
					context.fstackPos -= 2;
					context.pc ++;
					break;
				case isNonNull_Object:
                    context.istackPos ++;
					context.istack[context.istackPos] = (context.ostack[context.ostackPos] !is null);
                    context.ostackPos --;
					context.pc ++;
					break;
				case and_Int:
					context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] && context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case or_Int:
					context.istackPos --;
					context.istack[context.istackPos] = context.istack[context.istackPos] || context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case not_Int:
					context.istack[context.istackPos] = !context.istack[context.istackPos];
					context.pc ++;
					break;
				case add_Int:
					context.istackPos --;
					context.istack[context.istackPos] += context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case add_Float:
					context.fstackPos --;
					context.fstack[context.fstackPos] += context.fstack[context.fstackPos + 1];
					context.pc ++;
					break;
				case concatenate_String:
					context.sstackPos --;
					context.sstack[context.sstackPos] ~= context.sstack[context.sstackPos + 1];
					context.pc ++;
					break;
				case substract_Int:
					context.istackPos --;
					context.istack[context.istackPos] -= context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case substract_Float:
					context.fstackPos --;
					context.fstack[context.fstackPos] -= context.fstack[context.fstackPos + 1];
					context.pc ++;
					break;
				case multiply_Int:
					context.istackPos --;
					context.istack[context.istackPos] *= context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case multiply_Float:
					context.fstackPos --;
					context.fstack[context.fstackPos] *= context.fstack[context.fstackPos + 1];
					context.pc ++;
					break;
				case divide_Int:
					context.istackPos --;
					context.istack[context.istackPos] /= context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case divide_Float:
					context.fstackPos --;
					context.fstack[context.fstackPos] /= context.fstack[context.fstackPos + 1];
					context.pc ++;
					break;
				case remainder_Int:
					context.istackPos --;
					context.istack[context.istackPos] %= context.istack[context.istackPos + 1];
					context.pc ++;
					break;
				case remainder_Float:
					context.fstackPos --;
					context.fstack[context.fstackPos] %= context.fstack[context.fstackPos + 1];
					context.pc ++;
					break;
				case negative_Int:
					context.istack[context.istackPos] = -context.istack[context.istackPos];
					context.pc ++;
					break;
				case negative_Float:
					context.fstack[context.fstackPos] = -context.fstack[context.fstackPos];
					context.pc ++;
					break;
				case increment_Int:
					context.istack[context.istackPos] ++;
					context.pc ++;
					break;
				case increment_Float:
					context.fstack[context.fstackPos] += 1f;
					context.pc ++;
					break;
				case decrement_Int:
					context.istack[context.istackPos] --;
					context.pc ++;
					break;
				case decrement_Float:
					context.fstack[context.fstackPos] -= 1f;
					context.pc ++;
					break;
				case swap_Int:
					swapAt(context.istack, context.istackPos - 1, context.istackPos);
					context.pc ++;
					break;
				case swap_Float:
					swapAt(context.fstack, context.fstackPos - 1, context.fstackPos);
					context.pc ++;
					break;
				case swap_String:
					swapAt(context.sstack, context.sstackPos - 1, context.sstackPos);
					context.pc ++;
					break;
				case swap_Object:
					swapAt(context.ostack, context.ostackPos - 1, context.ostackPos);
					context.pc ++;
					break;
				case setupIterator:
					if(context.istack[context.istackPos] < 0)
						context.istack[context.istackPos] = 0;
					context.istack[context.istackPos] ++;
					context.pc ++;
					break;
				case return_:
                    //If another task was killed by an exception,
                    //we might end up there if the task has just been spawned.
                    if(context.stackPos < 0 && context.isKilled) {
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
                        context.ilocalsPos -= context.callStack[context.stackPos].ilocalStackSize;
                        context.flocalsPos -= context.callStack[context.stackPos].flocalStackSize;
                        context.slocalsPos -= context.callStack[context.stackPos].slocalStackSize;
                        context.olocalsPos -= context.callStack[context.stackPos].olocalStackSize;
                    }
					break;
                case unwind:
                    //If another task was killed by an exception,
                    //we might end up there if the task has just been spawned.
                    if(context.stackPos < 0) {
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
                            context.ilocalsPos -= context.callStack[context.stackPos].ilocalStackSize;
                            context.flocalsPos -= context.callStack[context.stackPos].flocalStackSize;
                            context.slocalsPos -= context.callStack[context.stackPos].slocalStackSize;
                            context.olocalsPos -= context.callStack[context.stackPos].olocalStackSize;

							if(_isDebug)
								debugProfileEnd();
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
                            context.ilocalsPos -= context.callStack[context.stackPos].ilocalStackSize;
                            context.flocalsPos -= context.callStack[context.stackPos].flocalStackSize;
                            context.slocalsPos -= context.callStack[context.stackPos].slocalStackSize;
                            context.olocalsPos -= context.callStack[context.stackPos].olocalStackSize;

							if(_isDebug)
								debugProfileEnd();

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
                            _panicMessage = _sglobalStackIn[$ - 1];
                            _sglobalStackIn.length --;

                            //Every deferred call has been executed, now die.
                            _contexts.markInternalForRemoval(index);
							continue contextsLabel;
                        }
                    }
                    else {
                        //Then returns to the last context.
                        context.stackPos --;
                        context.pc = context.callStack[context.stackPos].retPosition;
                        context.ilocalsPos -= context.callStack[context.stackPos].ilocalStackSize;
                        context.flocalsPos -= context.callStack[context.stackPos].flocalStackSize;
                        context.slocalsPos -= context.callStack[context.stackPos].slocalStackSize;
                        context.olocalsPos -= context.callStack[context.stackPos].olocalStackSize;

						if(_isDebug)
							debugProfileEnd();
                    }
                    break;
                case defer:
                    context.callStack[context.stackPos].deferStack ~= context.pc + grGetInstructionSignedValue(opcode);
					context.pc ++;
                    break;
				case localStack_Int:
                    const auto istackSize = grGetInstructionUnsignedValue(opcode);
					context.callStack[context.stackPos].ilocalStackSize = istackSize;
					if((context.ilocalsPos + istackSize) >= context.ilocalsLimit)
                        context.doubleIntLocalsStackSize(context.ilocalsPos + istackSize);
					context.pc ++;
					break;
				case localStack_Float:
                    const auto fstackSize = grGetInstructionUnsignedValue(opcode);
					context.callStack[context.stackPos].flocalStackSize = fstackSize;
					if((context.flocalsPos + fstackSize) >= context.flocalsLimit)
                        context.doubleFloatLocalsStackSize(context.flocalsPos + fstackSize);
					context.pc ++;
					break;
				case localStack_String:
                    const auto sstackSize = grGetInstructionUnsignedValue(opcode);
					context.callStack[context.stackPos].slocalStackSize = sstackSize;
					if((context.slocalsPos + sstackSize) >= context.slocalsLimit)
                        context.doubleStringLocalsStackSize(context.slocalsPos + sstackSize);
					context.pc ++;
					break;
				case localStack_Object:
                    const auto ostackSize = grGetInstructionUnsignedValue(opcode);
					context.callStack[context.stackPos].olocalStackSize = ostackSize;
					if((context.olocalsPos + ostackSize) >= context.olocalsLimit)
                        context.doubleObjectLocalsStackSize(context.olocalsPos + ostackSize);
					context.pc ++;
					break;
				case call:
                    if((context.stackPos + 1) >= context.callStackLimit)
                        context.doubleCallStackSize();
					context.ilocalsPos += context.callStack[context.stackPos].ilocalStackSize;
					context.flocalsPos += context.callStack[context.stackPos].flocalStackSize;
					context.slocalsPos += context.callStack[context.stackPos].slocalStackSize;
					context.olocalsPos += context.callStack[context.stackPos].olocalStackSize;
					context.callStack[context.stackPos].retPosition = context.pc + 1u;
					context.stackPos ++;
					context.pc = grGetInstructionUnsignedValue(opcode);
					break;
				case anonymousCall:
                    if((context.stackPos + 1) >= context.callStackLimit)
                        context.doubleCallStackSize();
					context.ilocalsPos += context.callStack[context.stackPos].ilocalStackSize;
					context.flocalsPos += context.callStack[context.stackPos].flocalStackSize;
					context.slocalsPos += context.callStack[context.stackPos].slocalStackSize;
					context.olocalsPos += context.callStack[context.stackPos].olocalStackSize;
					context.callStack[context.stackPos].retPosition = context.pc + 1u;
					context.stackPos ++;
					context.pc = context.istack[context.istackPos];
					context.istackPos --;
					break;
				case primitiveCall:
					_data._primitives[grGetInstructionUnsignedValue(opcode)].callObject.call(context);
					context.pc ++;
					break;
				case jump:
					context.pc += grGetInstructionSignedValue(opcode);
					break;
				case jumpEqual:
					if(context.istack[context.istackPos])
						context.pc ++;
					else
						context.pc += grGetInstructionSignedValue(opcode);
					context.istackPos --;
					break;
				case jumpNotEqual:
					if(context.istack[context.istackPos])
						context.pc += grGetInstructionSignedValue(opcode);
					else
						context.pc ++;
					context.istackPos --;
					break;
                case array_Int:
                    GrIntArray ary = new GrIntArray;
                    const auto arySize = grGetInstructionUnsignedValue(opcode);
                    for(int i = arySize - 1; i >= 0; i --)
                        ary.data ~= context.istack[context.istackPos - i];
                    context.istackPos -= arySize;
                    context.ostackPos ++;
					if(context.ostackPos == context.ostack.length)
						context.ostack.length *= 2;
                    context.ostack[context.ostackPos] = cast(void*)ary;
                    context.pc ++;
                    break;
                case array_Float:
                    GrFloatArray ary = new GrFloatArray;
                    const auto arySize = grGetInstructionUnsignedValue(opcode);
                    for(int i = arySize - 1; i >= 0; i --)
                        ary.data ~= context.fstack[context.fstackPos - i];
                    context.fstackPos -= arySize;
                    context.ostackPos ++;
					if(context.ostackPos == context.ostack.length)
						context.ostack.length *= 2;
                    context.ostack[context.ostackPos] = cast(void*)ary;
                    context.pc ++;
                    break;
                case array_String:
                    GrStringArray ary = new GrStringArray;
                    const auto arySize = grGetInstructionUnsignedValue(opcode);
                    for(int i = arySize - 1; i >= 0; i --)
                        ary.data ~= context.sstack[context.sstackPos - i];
                    context.sstackPos -= arySize;
                    context.ostackPos ++;
					if(context.ostackPos == context.ostack.length)
						context.ostack.length *= 2;
                    context.ostack[context.ostackPos] = cast(void*)ary;
                    context.pc ++;
                    break;
                case array_Object:
                    GrObjectArray ary = new GrObjectArray;
                    const auto arySize = grGetInstructionUnsignedValue(opcode);
                    for(int i = arySize - 1; i >= 0; i --)
                        ary.data ~= context.ostack[context.ostackPos - i];
                    context.ostackPos -= arySize;
                    context.ostackPos ++;
					if(context.ostackPos == context.ostack.length)
						context.ostack.length *= 2;
                    context.ostack[context.ostackPos] = cast(void*)ary;
                    context.pc ++;
                    break;
                case index_Int:
                    GrIntArray ary = cast(GrIntArray)context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
					if(idx < 0) {
						idx = (cast(int)ary.data.length) + idx;
					}
                    if(idx >= ary.data.length) {
                        raise(context, "Array overflow");
                        break;
                    }
                    context.ostack[context.ostackPos] = &ary.data[idx];
					context.istackPos --;
					context.pc ++;
                    break;
                case index_Float:
                    GrFloatArray ary = cast(GrFloatArray)context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
					if(idx < 0) {
						idx = (cast(int)ary.data.length) + idx;
					}
                    if(idx >= ary.data.length) {
                        raise(context, "Array overflow");
                        break;
                    }
                    context.ostack[context.ostackPos] = &ary.data[idx];
					context.istackPos --;
					context.pc ++;
                    break;
                case index_String:
                    GrStringArray ary = cast(GrStringArray)context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
					if(idx < 0) {
						idx = (cast(int)ary.data.length) + idx;
					}
                    if(idx >= ary.data.length) {
                        raise(context, "Array overflow");
                        break;
                    }
                    context.ostack[context.ostackPos] = &ary.data[idx];
					context.istackPos --;
					context.pc ++;
                    break;
                case index_Object:
                    GrObjectArray ary = cast(GrObjectArray)context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
					if(idx < 0) {
						idx = (cast(int)ary.data.length) + idx;
					}
                    if(idx >= ary.data.length) {
                        raise(context, "Array overflow");
                        break;
                    }
                    context.ostack[context.ostackPos] = &ary.data[idx];
					context.istackPos --;
					context.pc ++;
                    break;
                case index2_Int:
                    GrIntArray ary = cast(GrIntArray)context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
					if(idx < 0) {
						idx = (cast(int)ary.data.length) + idx;
					}
                    if(idx >= ary.data.length) {
                        raise(context, "Array overflow");
                        break;
                    }
                    context.istack[context.istackPos] = ary.data[idx];
					context.ostackPos --;
					context.pc ++;
                    break;
                case index2_Float:
                    GrFloatArray ary = cast(GrFloatArray)context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
					if(idx < 0) {
						idx = (cast(int)ary.data.length) + idx;
					}
                    if(idx >= ary.data.length) {
                        raise(context, "Array overflow");
                        break;
                    }
					context.fstackPos ++;
					if(context.fstackPos == context.fstack.length)
						context.fstack.length *= 2;
					context.istackPos --;
					context.ostackPos --;
                    context.fstack[context.fstackPos] = ary.data[idx];
					context.pc ++;
                    break;
                case index2_String:
                    GrStringArray ary = cast(GrStringArray)context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
					if(idx < 0) {
						idx = (cast(int)ary.data.length) + idx;
					}
                    if(idx >= ary.data.length) {
                        raise(context, "Array overflow");
                        break;
                    }
                    context.sstackPos ++;
					if(context.sstackPos == context.sstack.length)
						context.sstack.length *= 2;
					context.istackPos --;
					context.ostackPos --;
                    context.sstack[context.sstackPos] = ary.data[idx];
					context.pc ++;
                    break;
                case index2_Object:
                    GrObjectArray ary = cast(GrObjectArray)context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
					if(idx < 0) {
						idx = (cast(int)ary.data.length) + idx;
					}
                    if(idx >= ary.data.length) {
                        raise(context, "Array overflow");
                        break;
                    }
					context.istackPos --;
                    context.ostack[context.ostackPos] = ary.data[idx];
					context.pc ++;
                    break;
				case index3_Int:
                    GrIntArray ary = cast(GrIntArray)context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
					if(idx < 0) {
						idx = (cast(int)ary.data.length) + idx;
					}
                    if(idx >= ary.data.length) {
                        raise(context, "Array overflow");
                        break;
                    }
                    context.istack[context.istackPos] = ary.data[idx];
                    context.ostack[context.ostackPos] = &ary.data[idx];
					context.pc ++;
                    break;
				case index3_Float:
                    GrFloatArray ary = cast(GrFloatArray)context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
					if(idx < 0) {
						idx = (cast(int)ary.data.length) + idx;
					}
                    if(idx >= ary.data.length) {
                        raise(context, "Array overflow");
                        break;
                    }
					context.istackPos --;
					context.fstackPos ++;
                    context.fstack[context.fstackPos] = ary.data[idx];
                    context.ostack[context.ostackPos] = &ary.data[idx];
					context.pc ++;
                    break;
				case index3_String:
                    GrStringArray ary = cast(GrStringArray)context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
					if(idx < 0) {
						idx = (cast(int)ary.data.length) + idx;
					}
                    if(idx >= ary.data.length) {
                        raise(context, "Array overflow");
                        break;
                    }
					context.istackPos --;
					context.sstackPos ++;
                    context.sstack[context.sstackPos] = ary.data[idx];
                    context.ostack[context.ostackPos] = &ary.data[idx];
					context.pc ++;
                    break;
				case index3_Object:
                    GrObjectArray ary = cast(GrObjectArray)context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
					if(idx < 0) {
						idx = (cast(int)ary.data.length) + idx;
					}
                    if(idx >= ary.data.length) {
                        raise(context, "Array overflow");
                        break;
                    }
					context.istackPos --;
                    context.ostack[context.ostackPos] = &ary.data[idx];
					context.ostackPos ++;
                    context.ostack[context.ostackPos] = ary.data[idx];
					context.pc ++;
                    break;
				case length_Int:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] = cast(int)((cast(GrIntArray)context.ostack[context.ostackPos]).data.length);
                    context.ostackPos --;
					context.pc ++;
					break;
                case length_Float:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] = cast(int)((cast(GrFloatArray)context.ostack[context.ostackPos]).data.length);
                    context.ostackPos --;
					context.pc ++;
					break;
                case length_String:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] = cast(int)((cast(GrStringArray)context.ostack[context.ostackPos]).data.length);
                    context.ostackPos --;
					context.pc ++;
					break;
                case length_Object:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] = cast(int)((cast(GrObjectArray)context.ostack[context.ostackPos]).data.length);
                    context.ostackPos --;
					context.pc ++;
					break;
                case concatenate_IntArray:
                    GrIntArray nArray = new GrIntArray;
                    context.ostackPos --;
					nArray.data = (cast(GrIntArray)context.ostack[context.ostackPos]).data
                        ~ (cast(GrIntArray)context.ostack[context.ostackPos + 1]).data;
                    context.ostack[context.ostackPos] = cast(void*)nArray;
					context.pc ++;
					break;
                case concatenate_FloatArray:
                    GrFloatArray nArray = new GrFloatArray;
                    context.ostackPos --;
					nArray.data = (cast(GrFloatArray)context.ostack[context.ostackPos]).data
                        ~ (cast(GrFloatArray)context.ostack[context.ostackPos + 1]).data;
                    context.ostack[context.ostackPos] = cast(void*)nArray;
					context.pc ++;
					break;
                case concatenate_StringArray:
                    GrStringArray nArray = new GrStringArray;
                    context.ostackPos --;
					nArray.data = (cast(GrStringArray)context.ostack[context.ostackPos]).data
                        ~ (cast(GrStringArray)context.ostack[context.ostackPos + 1]).data;
                    context.ostack[context.ostackPos] = cast(void*)nArray;
					context.pc ++;
					break;
                case concatenate_ObjectArray:
                    GrObjectArray nArray = new GrObjectArray;
                    context.ostackPos --;
					nArray.data = (cast(GrObjectArray)context.ostack[context.ostackPos]).data
                        ~ (cast(GrObjectArray)context.ostack[context.ostackPos + 1]).data;
                    context.ostack[context.ostackPos] = cast(void*)nArray;
					context.pc ++;
					break;
                case append_Int:
                    GrIntArray nArray = new GrIntArray;
					nArray.data = (cast(GrIntArray)context.ostack[context.ostackPos]).data
                        ~ context.istack[context.istackPos];
                    context.ostack[context.ostackPos] = cast(void*)nArray;
                    context.istackPos --;
					context.pc ++;
                    break;
                case append_Float:
                    GrFloatArray nArray = new GrFloatArray;
					nArray.data = (cast(GrFloatArray)context.ostack[context.ostackPos]).data
                        ~ context.fstack[context.fstackPos];
                    context.ostack[context.ostackPos] = cast(void*)nArray;
                    context.fstackPos --;
					context.pc ++;
                    break;
                case append_String:
                    GrStringArray nArray = new GrStringArray;
					nArray.data = (cast(GrStringArray)context.ostack[context.ostackPos]).data
                        ~ context.sstack[context.sstackPos];
                    context.ostack[context.ostackPos] = cast(void*)nArray;
                    context.sstackPos --;
					context.pc ++;
                    break;
                case append_Object:
                    GrObjectArray nArray = new GrObjectArray;
                    context.ostackPos --;
					nArray.data = (cast(GrObjectArray)context.ostack[context.ostackPos]).data
                        ~ context.ostack[context.ostackPos + 1];
                    context.ostack[context.ostackPos] = cast(void*)nArray;
					context.pc ++;
                    break;
                case prepend_Int:
                    GrIntArray nArray = new GrIntArray;
					nArray.data = context.istack[context.istackPos]
                        ~ (cast(GrIntArray)context.ostack[context.ostackPos]).data;
                    context.ostack[context.ostackPos] = cast(void*)nArray;
                    context.istackPos --;
					context.pc ++;
                    break;
                case prepend_Float:
                    GrFloatArray nArray = new GrFloatArray;
					nArray.data = context.fstack[context.fstackPos]
                        ~ (cast(GrFloatArray)context.ostack[context.ostackPos]).data;
                    context.ostack[context.ostackPos] = cast(void*)nArray;
                    context.fstackPos --;
					context.pc ++;
                    break;
                case prepend_String:
                    GrStringArray nArray = new GrStringArray;
					nArray.data = context.sstack[context.sstackPos]
                        ~ (cast(GrStringArray)context.ostack[context.ostackPos]).data;
                    context.ostack[context.ostackPos] = cast(void*)nArray;
                    context.sstackPos --;
					context.pc ++;
                    break;
                case prepend_Object:
                    GrObjectArray nArray = new GrObjectArray;
                    context.ostackPos --;
					nArray.data = context.ostack[context.ostackPos]
                        ~ (cast(GrObjectArray)context.ostack[context.ostackPos + 1]).data;
                    context.ostack[context.ostackPos] = cast(void*)nArray;
					context.pc ++;
                    break;
                case equal_IntArray:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] =
                        (cast(GrIntArray)context.ostack[context.ostackPos - 1]).data
                        == (cast(GrIntArray)context.ostack[context.ostackPos]).data;
                    context.ostackPos -= 2;
					context.pc ++;
					break;
                case equal_FloatArray:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] =
                        (cast(GrFloatArray)context.ostack[context.ostackPos - 1]).data
                        == (cast(GrFloatArray)context.ostack[context.ostackPos]).data;
                    context.ostackPos -= 2;
					context.pc ++;
					break;
                case equal_StringArray:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] =
                        (cast(GrStringArray)context.ostack[context.ostackPos - 1]).data
                        == (cast(GrStringArray)context.ostack[context.ostackPos]).data;
                    context.ostackPos -= 2;
					context.pc ++;
					break;
                case notEqual_IntArray:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] =
                        (cast(GrIntArray)context.ostack[context.ostackPos - 1]).data
                        != (cast(GrIntArray)context.ostack[context.ostackPos]).data;
                    context.ostackPos -= 2;
					context.pc ++;
					break;
                case notEqual_FloatArray:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] =
                        (cast(GrFloatArray)context.ostack[context.ostackPos - 1]).data
                        != (cast(GrFloatArray)context.ostack[context.ostackPos]).data;
                    context.ostackPos -= 2;
					context.pc ++;
					break;
                case notEqual_StringArray:
                    context.istackPos ++;
					if(context.istackPos == context.istack.length)
						context.istack.length *= 2;
					context.istack[context.istackPos] =
                        (cast(GrStringArray)context.ostack[context.ostackPos - 1]).data
                        != (cast(GrStringArray)context.ostack[context.ostackPos]).data;
                    context.ostackPos -= 2;
					context.pc ++;
					break;
				case debug_ProfileBegin:
					debugProfileBegin(opcode, context.pc);
					context.pc ++;
					break;
				case debug_ProfileEnd:
					debugProfileEnd();
					context.pc ++;
					break;
				default:
					throw new Exception("Invalid instruction at (" ~ to!string(context.pc) ~ "): " ~ to!string(grGetInstructionOpcode(opcode)));
                }
			}
		}
		_contexts.sweepMarkedData();
    }

import core.time: MonoTime, Duration;
	private {
		bool _isDebug;
		DebugFunction[int] _debugFunctions;
		DebugFunction[] _debugFunctionsStack;
	}

	DebugFunction[int] dumpProfiling() {
		return _debugFunctions;
	}

	final class DebugFunction {
		private MonoTime _start;
		Duration total;
		ulong count;
		int pc;
		dstring name;
	}

	private void debugProfileEnd() {
		if(!_debugFunctionsStack.length)
			return;
		auto p = _debugFunctionsStack[$ - 1];
		_debugFunctionsStack.length --;
		p.total += MonoTime.currTime() - p._start;
		p.count ++;
	}

	private void debugProfileBegin(uint opcode, int pc) {
		_isDebug = true;
		auto p = (pc in _debugFunctions);
		if(p) {
			p._start = MonoTime.currTime();
			_debugFunctionsStack ~= *p;
		}
		else {
			auto debugFunc = new DebugFunction;
			debugFunc.pc = pc;
			debugFunc.name = _sconsts[grGetInstructionUnsignedValue(opcode)];
			debugFunc._start = MonoTime.currTime();
			_debugFunctions[pc] = debugFunc;
			_debugFunctionsStack ~= debugFunc;
		}
	}
}