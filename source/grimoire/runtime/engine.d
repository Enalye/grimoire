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
import std.algorithm.mutation : swapAt;
import std.typecons : Nullable;

import grimoire.compiler, grimoire.assembly;

import grimoire.runtime.context;
import grimoire.runtime.list;
import grimoire.runtime.object;
import grimoire.runtime.channel;
import grimoire.runtime.indexedarray;
import grimoire.runtime.call;

/**
Grimoire's virtual machine.
*/
class GrEngine {
    private {
        /// Bytecode.
        GrBytecode _bytecode;

        /// Global integral variables.
        GrInt[] _iglobals;
        /// Global real variables.
        GrReal[] _rglobals;
        /// Global string variables.
        GrString[] _sglobals;
        /// Global object variables.
        GrPtr[] _oglobals;

        /// Global integral stack.
        GrInt[] _iglobalStackIn, _iglobalStackOut;
        /// Global real stack.
        GrReal[] _fglobalStackIn, _fglobalStackOut;
        /// Global string stack.
        GrString[] _sglobalStackIn, _sglobalStackOut;
        /// Global object stack.
        GrPtr[] _oglobalStackIn, _oglobalStackOut;

        /// Context array.
        DynamicIndexedArray!GrContext _contexts, _contextsToSpawn;

        /// Global panic state.
        /// It means that the throwing context didn't handle the exception.
        bool _isPanicking;
        /// Unhandled panic message.
        string _panicMessage;
        /// Stack traces are generated each time an error is raised.
        GrStackTrace[] _stackTraces;

        /// Extra type compiler information.
        string _meta;

        /// Primitives.
        GrCallback[] _callbacks;
        /// Ditto
        GrCall[] _calls;

        /// Classes
        GrClassBuilder[string] _classBuilders;
    }

    /// External way of stopping the VM.
    shared bool isRunning = true;

    @property {
        /// Check if there is a coroutine currently running.
        bool hasCoroutines() const {
            return (_contexts.length + _contextsToSpawn.length) > 0uL;
        }

        /// Whether the whole VM has panicked, true if an unhandled error occurred.
        bool isPanicking() const {
            return _isPanicking;
        }

        /// If the VM has raised an error, stack traces are generated.
        const(GrStackTrace[]) stackTraces() const {
            return _stackTraces;
        }

        /// The unhandled error message.
        string panicMessage() const {
            return _panicMessage;
        }

        /// Extra type compiler information.
        string meta() const {
            return _meta;
        }
        /// Ditto
        string meta(string newMeta) {
            return _meta = newMeta;
        }
    }

    /// Default.
    this() {
    }

    private void initialize() {
        _contexts = new DynamicIndexedArray!GrContext;
        _contextsToSpawn = new DynamicIndexedArray!GrContext;
        _contexts.push(new GrContext(this));
    }

    /// Add a new library to the runtime.
    /// ___
    /// It must be called before loading the bytecode.
    /// It should be loading the same library as the compiler
    /// and in the same order.
    final void addLibrary(GrLibrary library) {
        _callbacks ~= library._callbacks;
    }

    /// Load the bytecode.
    final void load(GrBytecode bytecode) {
        initialize();
        _bytecode = bytecode;
        _iglobals = new GrInt[_bytecode.iglobalsCount];
        _rglobals = new GrReal[_bytecode.rglobalsCount];
        _sglobals = new GrString[_bytecode.sglobalsCount];
        _oglobals = new GrPtr[_bytecode.oglobalsCount];

        // Setup the primitives
        for (uint i; i < _bytecode.primitives.length; ++i) {
            if (_bytecode.primitives[i].index > _callbacks.length)
                throw new Exception("callback index out of bounds");
            _calls ~= new GrCall(_callbacks[_bytecode.primitives[i].index], _bytecode.primitives[i]);
        }

        foreach (ref globalRef; _bytecode.variables) {
            const uint typeMask = globalRef.typeMask;
            const uint index = globalRef.index;
            if (typeMask & 0x1)
                _iglobals[index] = globalRef.ivalue;
            else if (typeMask & 0x2)
                _rglobals[index] = globalRef.rvalue;
            else if (typeMask & 0x4)
                _sglobals[index] = globalRef.svalue;
            else if (typeMask & 0x8)
                _oglobals[index] = null;
        }

        // Index the classes
        for (size_t index; index < _bytecode.classes.length; index++) {
            GrClassBuilder classBuilder = _bytecode.classes[index];
            _classBuilders[classBuilder.name] = classBuilder;
        }
    }

    /**
	Checks whether an action exists. \
	The action's name must be mangled with its signature.
	*/
    bool hasAction(string mangledName) {
        return (mangledName in _bytecode.actions) !is null;
    }

    /**
	Spawn a new coroutine registered as an action. \
	The action's name must be mangled with its signature.
	---
	action myAction() {
		trace("myAction was created !");
	}
	---
	*/
    GrContext callAction(string mangledName) {
        const auto action = mangledName in _bytecode.actions;
        if (action is null)
            throw new Exception("no action \'" ~ mangledName ~ "\' in script");
        GrContext context = new GrContext(this);
        context.pc = *action;
        _contextsToSpawn.push(context);
        return context;
    }

    /**
	Spawn a new coroutine at an arbitrary address. \
	The address needs to correspond to the start of a task, else the VM will crash. \
	*/
    GrContext callAddress(uint pc) {
        if (pc == 0 || pc >= _bytecode.opcodes.length)
            throw new Exception("address \'" ~ to!string(pc) ~ "\' out of bounds");

        // For now we assume a task is always following a die from the previous task
        // Not a 100% foolproof method but it'll do for now.
        const GrOpcode opcode = cast(GrOpcode)(_bytecode.opcodes[(cast(long) pc) - 1] & 0xFF);
        if (opcode != GrOpcode.die)
            throw new Exception("the address does not correspond with a task");

        GrContext context = new GrContext(this);
        context.pc = pc;
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
    Immediately prints a stacktrace to standard output
    */
    private void generateStackTrace(GrContext context) {
        {
            GrStackTrace trace;
            trace.pc = context.pc;
            auto func = getFunctionInfo(context.pc);
            if (func.isNull) {
                trace.name = "?";
            }
            else {
                trace.name = func.get.name;
                trace.file = func.get.file;
                uint index = cast(uint)(cast(int) trace.pc - cast(int) func.get.start);
                if (index < 0 || index >= func.get.positions.length) {
                    trace.line = 0;
                    trace.column = 0;
                }
                else {
                    auto position = func.get.positions[index];
                    trace.line = position.line;
                    trace.column = position.column;
                }
            }
            _stackTraces ~= trace;
        }

        for (int i = context.stackPos - 1; i >= 0; i--) {
            GrStackTrace trace;
            trace.pc = cast(uint)((cast(int) context.callStack[i].retPosition) - 1);
            auto func = getFunctionInfo(trace.pc);
            if (func.isNull) {
                trace.name = "?";
            }
            else {
                trace.name = func.get.name;
                trace.file = func.get.file;
                uint index = cast(uint)(cast(int) trace.pc - cast(int) func.get.start);
                if (index < 0 || index >= func.get.positions.length) {
                    trace.line = 1;
                    trace.column = 0;
                }
                else {
                    auto position = func.get.positions[index];
                    trace.line = position.line;
                    trace.column = position.column;
                }
            }
            _stackTraces ~= trace;
        }
    }

    /**
    Tries to resolve a function from a position in the bytecode
    */
    private Nullable!(GrFunctionSymbol) getFunctionInfo(uint position) {
        Nullable!(GrFunctionSymbol) bestInfo;
        foreach (const GrSymbol symbol; _bytecode.symbols) {
            if (symbol.type == GrSymbol.Type.function_) {
                auto info = cast(GrFunctionSymbol) symbol;
                if (info.start <= position && info.start + info.length > position) {
                    if (bestInfo.isNull) {
                        bestInfo = info;
                    }
                    else {
                        if (bestInfo.get.length > info.length) {
                            bestInfo = info;
                        }
                    }
                }
            }
        }
        return bestInfo;
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
    void raise(GrContext context, string message) {
        if (context.isPanicking)
            return;
        //Error message.
        _sglobalStackIn ~= message;

        generateStackTrace(context);

        //We indicate that the coroutine is in a panic state until a catch is found.
        context.isPanicking = true;

        context.pc = cast(uint)(cast(int) _bytecode.opcodes.length - 1);
    }

    /**
	Marks each coroutine as killed and prevents any new coroutine from spawning.
	*/
    private void end() {
        foreach (coroutine; _contexts) {
            coroutine.pc = cast(uint)(cast(int) _bytecode.opcodes.length - 1);
            coroutine.isKilled = true;
        }
        _contextsToSpawn.reset();
    }

    alias getBoolVariable = getVariable!bool;
    alias getIntVariable = getVariable!GrInt;
    alias getRealVariable = getVariable!GrReal;
    alias getStringVariable = getVariable!GrString;
    alias getPtrVariable = getVariable!GrPtr;

    GrObject getObjectVariable(string name) {
        return cast(GrObject) getVariable!(GrPtr)(name);
    }

    GrIntList getIntListVariable(string name) {
        return cast(GrIntList) getVariable!(GrPtr)(name);
    }

    GrRealList getRealListVariable(string name) {
        return cast(GrRealList) getVariable!(GrPtr)(name);
    }

    GrStringList getStringListVariable(string name) {
        return cast(GrStringList) getVariable!(GrPtr)(name);
    }

    GrObjectList getObjectListVariable(string name) {
        return cast(GrObjectList) getVariable!(GrPtr)(name);
    }

    GrIntChannel getIntChannelVariable(string name) {
        return cast(GrIntChannel) getVariable!(GrPtr)(name);
    }

    GrRealChannel getRealChannelVariable(string name) {
        return cast(GrRealChannel) getVariable!(GrPtr)(name);
    }

    GrStringChannel getStringChannelVariable(string name) {
        return cast(GrStringChannel) getVariable!(GrPtr)(name);
    }

    GrObjectChannel getObjectChannelVariable(string name) {
        return cast(GrObjectChannel) getVariable!(GrPtr)(name);
    }

    T getEnumVariable(T)(string name) {
        return cast(T) getVariable!int(name);
    }

    T getForeignVariable(T)(string name) {
        // We cast to object first to avoid a crash when casting to a parent class
        return cast(T) cast(Object) getVariable!(GrPtr)(name);
    }

    private T getVariable(T)(string name) {
        const auto variable = name in _bytecode.variables;
        if (variable is null)
            throw new Exception("no global variable `" ~ name ~ "` defined");
        static if (is(T == GrInt)) {
            if ((variable.typeMask & 0x1) == 0)
                throw new Exception("variable `" ~ name ~ "` is not an int");
            return _iglobals[variable.index];
        }
        else static if (is(T == GrBool)) {
            if ((variable.typeMask & 0x1) == 0)
                throw new Exception("variable `" ~ name ~ "` is not an int");
            return _iglobals[variable.index] > 0;
        }
        else static if (is(T == GrReal)) {
            if ((variable.typeMask & 0x2) == 0)
                throw new Exception("variable `" ~ name ~ "` is not a real");
            return _rglobals[variable.index];
        }
        else static if (is(T == GrString)) {
            if ((variable.typeMask & 0x4) == 0)
                throw new Exception("variable `" ~ name ~ "` is not a string");
            return _sglobals[variable.index];
        }
        else static if (is(T == GrPtr)) {
            if ((variable.typeMask & 0x8) == 0)
                throw new Exception("variable `" ~ name ~ "` is not an object");
            return _oglobals[variable.index];
        }
    }

    alias setBoolVariable = setVariable!GrBool;
    alias setIntVariable = setVariable!GrInt;
    alias setRealVariable = setVariable!GrReal;
    alias setStringVariable = setVariable!GrString;
    alias setPtrVariable = setVariable!GrPtr;

    void setObjectVariable(string name, GrObject value) {
        setVariable!(GrPtr)(name, cast(GrPtr) value);
    }

    void setIntListVariable(string name, GrIntList value) {
        setVariable!(GrPtr)(name, cast(GrPtr) value);
    }

    void setRealListVariable(string name, GrRealList value) {
        setVariable!(GrPtr)(name, cast(GrPtr) value);
    }

    void setStringListVariable(string name, GrStringList value) {
        setVariable!(GrPtr)(name, cast(GrPtr) value);
    }

    void setObjectListVariable(string name, GrObjectList value) {
        setVariable!(GrPtr)(name, cast(GrPtr) value);
    }

    void setIntChannelVariable(string name, GrIntChannel value) {
        setVariable!(GrPtr)(name, cast(GrPtr) value);
    }

    void setRealChannelVariable(string name, GrRealChannel value) {
        setVariable!(GrPtr)(name, cast(GrPtr) value);
    }

    void setStringChannelVariable(string name, GrStringChannel value) {
        setVariable!(GrPtr)(name, cast(GrPtr) value);
    }

    void setObjectChannelVariable(string name, GrObjectChannel value) {
        setVariable!(GrPtr)(name, cast(GrPtr) value);
    }

    void setEnumVariable(T)(string name, T value) {
        setVariable!int(name, cast(int) value);
    }

    void setForeignVariable(T)(string name, T value) {
        setVariable!(GrPtr)(name, cast(GrPtr) value);
    }

    private void setVariable(T)(string name, T value) {
        const auto variable = name in _bytecode.variables;
        if (variable is null)
            throw new Exception("no global variable `" ~ name ~ "` defined");
        static if (is(T == GrInt)) {
            if ((variable.typeMask & 0x1) == 0)
                throw new Exception("variable `" ~ name ~ "` is not an int");
            _iglobals[variable.index] = value;
        }
        else static if (is(T == GrBool)) {
            if ((variable.typeMask & 0x1) == 0)
                throw new Exception("variable `" ~ name ~ "` is not an int");
            _iglobals[variable.index] = value;
        }
        else static if (is(T == GrReal)) {
            if ((variable.typeMask & 0x2) == 0)
                throw new Exception("variable `" ~ name ~ "` is not a real");
            _rglobals[variable.index] = value;
        }
        else static if (is(T == GrString)) {
            if ((variable.typeMask & 0x4) == 0)
                throw new Exception("variable `" ~ name ~ "` is not a string");
            _sglobals[variable.index] = value;
        }
        else static if (is(T == GrPtr)) {
            if ((variable.typeMask & 0x8) == 0)
                throw new Exception("variable `" ~ name ~ "` is not an object");
            _oglobals[variable.index] = value;
        }
    }

    /// Run the vm until all the contexts are finished or suspended.
    void process() {
        if (_contextsToSpawn.length) {
            for (int index = cast(int) _contextsToSpawn.length - 1; index >= 0; index--)
                _contexts.push(_contextsToSpawn[index]);
            _contextsToSpawn.reset();
            import std.algorithm.mutation : swap;

            swap(_iglobalStackIn, _iglobalStackOut);
            swap(_fglobalStackIn, _fglobalStackOut);
            swap(_sglobalStackIn, _sglobalStackOut);
            swap(_oglobalStackIn, _oglobalStackOut);
        }
        contextsLabel: for (uint index = 0u; index < _contexts.length; index++) {
            GrContext context = _contexts.data[index];
            if (context.blocker) {
                if (!context.blocker.run())
                    continue;
                context.blocker = null;
            }
            while (isRunning) {
                const uint opcode = _bytecode.opcodes[context.pc];
                final switch (opcode & 0xFF) with (GrOpcode) {
                case nop:
                    context.pc++;
                    break;
                case error:
                    if (!context.isPanicking) {
                        //Error message.
                        _sglobalStackIn ~= context.sstack[context.sstackPos];
                        context.sstackPos--;
                        generateStackTrace(context);

                        //We indicate that the coroutine is in a panic state until a catch is found.
                        context.isPanicking = true;
                    }

                    //Exception handler found in the current function, just jump.
                    if (context.callStack[context.stackPos].exceptionHandlers.length) {
                        context.pc = context.callStack[context.stackPos].exceptionHandlers[$ - 1];
                    }
                    //No exception handler in the current function, unwinding the deferred code, then return.

                    //Check for deferred calls as we will exit the current function.
                    else if (context.callStack[context.stackPos].deferStack.length) {
                        //Pop the last defer and run it.
                        context.pc = context.callStack[context.stackPos].deferStack[$ - 1];
                        context.callStack[context.stackPos].deferStack.length--;
                        //The search for an exception handler will be done by Unwind after all defer
                        //has been called for this function.
                    }
                    else if (context.stackPos) {
                        //Then returns to the last context, raise will be run again.
                        context.stackPos--;
                        context.ilocalsPos -= context.callStack[context.stackPos].ilocalStackSize;
                        context.rlocalsPos -= context.callStack[context.stackPos].rlocalStackSize;
                        context.slocalsPos -= context.callStack[context.stackPos].slocalStackSize;
                        context.olocalsPos -= context.callStack[context.stackPos].olocalStackSize;

                        if (_isDebug)
                            _debugProfileEnd();
                    }
                    else {
                        //Kill the others.
                        end();

                        //The VM is now panicking.
                        _isPanicking = true;
                        _panicMessage = _sglobalStackIn[$ - 1];
                        _sglobalStackIn.length--;

                        //Every deferred call has been executed, now die.
                        _contexts.markInternalForRemoval(index);
                        continue contextsLabel;
                    }
                    break;
                case isolate:
                    context.callStack[context.stackPos].exceptionHandlers ~= context.pc + grGetInstructionSignedValue(
                        opcode);
                    context.pc++;
                    break;
                case capture:
                    context.callStack[context.stackPos].exceptionHandlers.length--;
                    if (context.isPanicking) {
                        context.isPanicking = false;
                        _stackTraces.length = 0;
                        context.pc++;
                    }
                    else {
                        context.pc += grGetInstructionSignedValue(opcode);
                    }
                    break;
                case task:
                    GrContext newCoro = new GrContext(this);
                    newCoro.pc = grGetInstructionUnsignedValue(opcode);
                    _contextsToSpawn.push(newCoro);
                    context.pc++;
                    break;
                case anonymousTask:
                    GrContext newCoro = new GrContext(this);
                    newCoro.pc = cast(uint) context.istack[context.istackPos];
                    context.istackPos--;
                    _contextsToSpawn.push(newCoro);
                    context.pc++;
                    break;
                case die:
                    //Check for deferred calls.
                    if (context.callStack[context.stackPos].deferStack.length) {
                        //Pop the last defer and run it.
                        context.pc = context.callStack[context.stackPos].deferStack[$ - 1];
                        context.callStack[context.stackPos].deferStack.length--;

                        //Flag as killed so the entire stack will be unwinded.
                        context.isKilled = true;
                    }
                    else if (context.stackPos) {
                        //Then returns to the last context.
                        context.stackPos--;
                        context.pc = context.callStack[context.stackPos].retPosition;
                        context.ilocalsPos -= context.callStack[context.stackPos].ilocalStackSize;
                        context.rlocalsPos -= context.callStack[context.stackPos].rlocalStackSize;
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
                case quit:
                    end();
                    continue contextsLabel;
                case suspend:
                    context.pc++;
                    continue contextsLabel;
                case new_:
                    context.ostackPos++;
                    if (context.ostackPos == context.ostack.length)
                        context.ostack.length *= 2;
                    context.ostack[context.ostackPos] = cast(GrPtr) new GrObject(
                        _bytecode.classes[grGetInstructionUnsignedValue(opcode)]);
                    context.pc++;
                    break;
                case channel_int:
                    context.ostackPos++;
                    if (context.ostackPos == context.ostack.length)
                        context.ostack.length *= 2;
                    context.ostack[context.ostackPos] = cast(GrPtr) new GrIntChannel(
                        grGetInstructionUnsignedValue(opcode));
                    context.pc++;
                    break;
                case channel_real:
                    context.ostackPos++;
                    if (context.ostackPos == context.ostack.length)
                        context.ostack.length *= 2;
                    context.ostack[context.ostackPos] = cast(GrPtr) new GrRealChannel(
                        grGetInstructionUnsignedValue(opcode));
                    context.pc++;
                    break;
                case channel_string:
                    context.ostackPos++;
                    if (context.ostackPos == context.ostack.length)
                        context.ostack.length *= 2;
                    context.ostack[context.ostackPos] = cast(GrPtr) new GrStringChannel(
                        grGetInstructionUnsignedValue(opcode));
                    context.pc++;
                    break;
                case channel_object:
                    context.ostackPos++;
                    if (context.ostackPos == context.ostack.length)
                        context.ostack.length *= 2;
                    context.ostack[context.ostackPos] = cast(GrPtr) new GrObjectChannel(
                        grGetInstructionUnsignedValue(opcode));
                    context.pc++;
                    break;
                case send_int:
                    GrIntChannel chan = cast(GrIntChannel) context.ostack[context.ostackPos];
                    if (!chan.isOwned) {
                        if (context.isEvaluatingChannel) {
                            context.restoreState();
                            context.isLocked = true;
                            context.isEvaluatingChannel = false;
                            context.pc = context.selectPositionJump;
                        }
                        else {
                            context.istackPos--;
                            context.ostackPos--;
                            raise(context, "ChannelError");
                        }
                    }
                    else if (chan.canSend) {
                        context.isLocked = false;
                        chan.send(context.istack[context.istackPos]);
                        context.ostackPos--;
                        context.pc++;
                    }
                    else {
                        context.isLocked = true;
                        if (context.isEvaluatingChannel) {
                            context.restoreState();
                            context.isEvaluatingChannel = false;
                            context.pc = context.selectPositionJump;
                        }
                        else
                            continue contextsLabel;
                    }
                    break;
                case send_real:
                    GrRealChannel chan = cast(GrRealChannel) context.ostack[context.ostackPos];
                    if (!chan.isOwned) {
                        if (context.isEvaluatingChannel) {
                            context.restoreState();
                            context.isLocked = true;
                            context.isEvaluatingChannel = false;
                            context.pc = context.selectPositionJump;
                        }
                        else {
                            context.rstackPos--;
                            context.ostackPos--;
                            raise(context, "ChannelError");
                        }
                    }
                    else if (chan.canSend) {
                        context.isLocked = false;
                        chan.send(context.rstack[context.rstackPos]);
                        context.ostackPos--;
                        context.pc++;
                    }
                    else {
                        context.isLocked = true;
                        if (context.isEvaluatingChannel) {
                            context.restoreState();
                            context.isEvaluatingChannel = false;
                            context.pc = context.selectPositionJump;
                        }
                        else
                            continue contextsLabel;
                    }
                    break;
                case send_string:
                    GrStringChannel chan = cast(GrStringChannel) context.ostack[context.ostackPos];
                    if (!chan.isOwned) {
                        if (context.isEvaluatingChannel) {
                            context.restoreState();
                            context.isLocked = true;
                            context.isEvaluatingChannel = false;
                            context.pc = context.selectPositionJump;
                        }
                        else {
                            context.sstackPos--;
                            context.ostackPos--;
                            raise(context, "ChannelError");
                        }
                    }
                    else if (chan.canSend) {
                        context.isLocked = false;
                        chan.send(context.sstack[context.sstackPos]);
                        context.ostackPos--;
                        context.pc++;
                    }
                    else {
                        context.isLocked = true;
                        if (context.isEvaluatingChannel) {
                            context.restoreState();
                            context.isEvaluatingChannel = false;
                            context.pc = context.selectPositionJump;
                        }
                        else
                            continue contextsLabel;
                    }
                    break;
                case send_object:
                    GrObjectChannel chan = cast(GrObjectChannel) context
                        .ostack[context.ostackPos - 1];
                    if (!chan.isOwned) {
                        if (context.isEvaluatingChannel) {
                            context.restoreState();
                            context.isLocked = true;
                            context.isEvaluatingChannel = false;
                            context.pc = context.selectPositionJump;
                        }
                        else {
                            context.ostackPos -= 2;
                            raise(context, "ChannelError");
                        }
                    }
                    else if (chan.canSend) {
                        context.isLocked = false;
                        chan.send(context.ostack[context.ostackPos]);
                        context.ostack[context.ostackPos - 1] = context.ostack[context.ostackPos];
                        context.ostackPos--;
                        context.pc++;
                    }
                    else {
                        context.isLocked = true;
                        if (context.isEvaluatingChannel) {
                            context.restoreState();
                            context.isEvaluatingChannel = false;
                            context.pc = context.selectPositionJump;
                        }
                        else
                            continue contextsLabel;
                    }
                    break;
                case receive_int:
                    GrIntChannel chan = cast(GrIntChannel) context.ostack[context.ostackPos];
                    if (!chan.isOwned) {
                        if (context.isEvaluatingChannel) {
                            context.restoreState();
                            context.isLocked = true;
                            context.isEvaluatingChannel = false;
                            context.pc = context.selectPositionJump;
                        }
                        else {
                            context.ostackPos--;
                            raise(context, "ChannelError");
                        }
                    }
                    else if (chan.canReceive) {
                        context.isLocked = false;
                        context.istackPos++;
                        if (context.istackPos == context.istack.length)
                            context.istack.length *= 2;
                        context.istack[context.istackPos] = chan.receive();
                        context.ostackPos--;
                        context.pc++;
                    }
                    else {
                        chan.setReceiverReady();
                        context.isLocked = true;
                        if (context.isEvaluatingChannel) {
                            context.restoreState();
                            context.isEvaluatingChannel = false;
                            context.pc = context.selectPositionJump;
                        }
                        else
                            continue contextsLabel;
                    }
                    break;
                case receive_real:
                    GrRealChannel chan = cast(GrRealChannel) context.ostack[context.ostackPos];
                    if (!chan.isOwned) {
                        if (context.isEvaluatingChannel) {
                            context.restoreState();
                            context.isLocked = true;
                            context.isEvaluatingChannel = false;
                            context.pc = context.selectPositionJump;
                        }
                        else {
                            context.ostackPos--;
                            raise(context, "ChannelError");
                        }
                    }
                    else if (chan.canReceive) {
                        context.isLocked = false;
                        context.rstackPos++;
                        if (context.rstackPos == context.rstack.length)
                            context.rstack.length *= 2;
                        context.rstack[context.rstackPos] = chan.receive();
                        context.ostackPos--;
                        context.pc++;
                    }
                    else {
                        chan.setReceiverReady();
                        context.isLocked = true;
                        if (context.isEvaluatingChannel) {
                            context.restoreState();
                            context.isEvaluatingChannel = false;
                            context.pc = context.selectPositionJump;
                        }
                        else
                            continue contextsLabel;
                    }
                    break;
                case receive_string:
                    GrStringChannel chan = cast(GrStringChannel) context.ostack[context.ostackPos];
                    if (!chan.isOwned) {
                        if (context.isEvaluatingChannel) {
                            context.restoreState();
                            context.isLocked = true;
                            context.isEvaluatingChannel = false;
                            context.pc = context.selectPositionJump;
                        }
                        else {
                            context.ostackPos--;
                            raise(context, "ChannelError");
                        }
                    }
                    else if (chan.canReceive) {
                        context.isLocked = false;
                        context.sstackPos++;
                        if (context.sstackPos == context.sstack.length)
                            context.sstack.length *= 2;
                        context.sstack[context.sstackPos] = chan.receive();
                        context.ostackPos--;
                        context.pc++;
                    }
                    else {
                        chan.setReceiverReady();
                        context.isLocked = true;
                        if (context.isEvaluatingChannel) {
                            context.restoreState();
                            context.isEvaluatingChannel = false;
                            context.pc = context.selectPositionJump;
                        }
                        else
                            continue contextsLabel;
                    }
                    break;
                case receive_object:
                    GrObjectChannel chan = cast(GrObjectChannel) context.ostack[context.ostackPos];
                    if (!chan.isOwned) {
                        if (context.isEvaluatingChannel) {
                            context.restoreState();
                            context.isLocked = true;
                            context.isEvaluatingChannel = false;
                            context.pc = context.selectPositionJump;
                        }
                        else {
                            context.ostackPos--;
                            raise(context, "ChannelError");
                        }
                    }
                    else if (chan.canReceive) {
                        context.isLocked = false;
                        context.ostack[context.ostackPos] = chan.receive();
                        context.pc++;
                    }
                    else {
                        chan.setReceiverReady();
                        context.isLocked = true;
                        if (context.isEvaluatingChannel) {
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
                    context.pc++;
                    break;
                case endSelectChannel:
                    context.popState();
                    context.pc++;
                    break;
                case tryChannel:
                    if (context.isEvaluatingChannel)
                        raise(context, "SelectError");
                    context.isEvaluatingChannel = true;
                    context.selectPositionJump = context.pc + grGetInstructionSignedValue(opcode);
                    context.pc++;
                    break;
                case checkChannel:
                    if (!context.isEvaluatingChannel)
                        raise(context, "SelectError");
                    context.isEvaluatingChannel = false;
                    context.restoreState();
                    context.pc++;
                    break;
                case shiftStack_int:
                    context.istackPos += grGetInstructionSignedValue(opcode);
                    context.pc++;
                    break;
                case shiftStack_real:
                    context.rstackPos += grGetInstructionSignedValue(opcode);
                    context.pc++;
                    break;
                case shiftStack_string:
                    context.sstackPos += grGetInstructionSignedValue(opcode);
                    context.pc++;
                    break;
                case shiftStack_object:
                    context.ostackPos += grGetInstructionSignedValue(opcode);
                    context.pc++;
                    break;
                case localStore_int:
                    context.ilocals[context.ilocalsPos + grGetInstructionUnsignedValue(
                            opcode)] = context.istack[context.istackPos];
                    context.istackPos--;
                    context.pc++;
                    break;
                case localStore_real:
                    context.rlocals[context.rlocalsPos + grGetInstructionUnsignedValue(
                            opcode)] = context.rstack[context.rstackPos];
                    context.rstackPos--;
                    context.pc++;
                    break;
                case localStore_string:
                    context.slocals[context.slocalsPos + grGetInstructionUnsignedValue(
                            opcode)] = context.sstack[context.sstackPos];
                    context.sstackPos--;
                    context.pc++;
                    break;
                case localStore_object:
                    context.olocals[context.olocalsPos + grGetInstructionUnsignedValue(
                            opcode)] = context.ostack[context.ostackPos];
                    context.ostackPos--;
                    context.pc++;
                    break;
                case localStore2_int:
                    context.ilocals[context.ilocalsPos + grGetInstructionUnsignedValue(
                            opcode)] = context.istack[context.istackPos];
                    context.pc++;
                    break;
                case localStore2_real:
                    context.rlocals[context.rlocalsPos + grGetInstructionUnsignedValue(
                            opcode)] = context.rstack[context.rstackPos];
                    context.pc++;
                    break;
                case localStore2_string:
                    context.slocals[context.slocalsPos + grGetInstructionUnsignedValue(
                            opcode)] = context.sstack[context.sstackPos];
                    context.pc++;
                    break;
                case localStore2_object:
                    context.olocals[context.olocalsPos + grGetInstructionUnsignedValue(
                            opcode)] = context.ostack[context.ostackPos];
                    context.pc++;
                    break;
                case localLoad_int:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos]
                        = context.ilocals[context.ilocalsPos + grGetInstructionUnsignedValue(
                                opcode)];
                    context.pc++;
                    break;
                case localLoad_real:
                    context.rstackPos++;
                    if (context.rstackPos == context.rstack.length)
                        context.rstack.length *= 2;
                    context.rstack[context.rstackPos]
                        = context.rlocals[context.rlocalsPos + grGetInstructionUnsignedValue(
                                opcode)];
                    context.pc++;
                    break;
                case localLoad_string:
                    context.sstackPos++;
                    if (context.sstackPos == context.sstack.length)
                        context.sstack.length *= 2;
                    context.sstack[context.sstackPos]
                        = context.slocals[context.slocalsPos + grGetInstructionUnsignedValue(
                                opcode)];
                    context.pc++;
                    break;
                case localLoad_object:
                    context.ostackPos++;
                    if (context.ostackPos == context.ostack.length)
                        context.ostack.length *= 2;
                    context.ostack[context.ostackPos]
                        = context.olocals[context.olocalsPos + grGetInstructionUnsignedValue(
                                opcode)];
                    context.pc++;
                    break;
                case globalStore_int:
                    _iglobals[grGetInstructionUnsignedValue(opcode)] = context
                        .istack[context.istackPos];
                    context.istackPos--;
                    context.pc++;
                    break;
                case globalStore_real:
                    _rglobals[grGetInstructionUnsignedValue(opcode)] = context
                        .rstack[context.rstackPos];
                    context.rstackPos--;
                    context.pc++;
                    break;
                case globalStore_string:
                    _sglobals[grGetInstructionUnsignedValue(opcode)] = context
                        .sstack[context.sstackPos];
                    context.sstackPos--;
                    context.pc++;
                    break;
                case globalStore_object:
                    _oglobals[grGetInstructionUnsignedValue(opcode)] = context
                        .ostack[context.ostackPos];
                    context.ostackPos--;
                    context.pc++;
                    break;
                case globalStore2_int:
                    _iglobals[grGetInstructionUnsignedValue(opcode)] = context
                        .istack[context.istackPos];
                    context.pc++;
                    break;
                case globalStore2_real:
                    _rglobals[grGetInstructionUnsignedValue(opcode)] = context
                        .rstack[context.rstackPos];
                    context.pc++;
                    break;
                case globalStore2_string:
                    _sglobals[grGetInstructionUnsignedValue(opcode)] = context
                        .sstack[context.sstackPos];
                    context.pc++;
                    break;
                case globalStore2_object:
                    _oglobals[grGetInstructionUnsignedValue(opcode)] = context
                        .ostack[context.ostackPos];
                    context.pc++;
                    break;
                case globalLoad_int:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = _iglobals[grGetInstructionUnsignedValue(
                            opcode)];
                    context.pc++;
                    break;
                case globalLoad_real:
                    context.rstackPos++;
                    if (context.rstackPos == context.rstack.length)
                        context.rstack.length *= 2;
                    context.rstack[context.rstackPos] = _rglobals[grGetInstructionUnsignedValue(
                            opcode)];
                    context.pc++;
                    break;
                case globalLoad_string:
                    context.sstackPos++;
                    if (context.sstackPos == context.sstack.length)
                        context.sstack.length *= 2;
                    context.sstack[context.sstackPos] = _sglobals[grGetInstructionUnsignedValue(
                            opcode)];
                    context.pc++;
                    break;
                case globalLoad_object:
                    context.ostackPos++;
                    if (context.ostackPos == context.ostack.length)
                        context.ostack.length *= 2;
                    context.ostack[context.ostackPos] = _oglobals[grGetInstructionUnsignedValue(
                            opcode)];
                    context.pc++;
                    break;
                case refStore_int:
                    *(cast(GrInt*) context.ostack[context.ostackPos]) = context
                        .istack[context.istackPos];
                    context.ostackPos--;
                    context.istackPos--;
                    context.pc++;
                    break;
                case refStore_real:
                    *(cast(GrReal*) context.ostack[context.ostackPos]) = context
                        .rstack[context.rstackPos];
                    context.ostackPos--;
                    context.rstackPos--;
                    context.pc++;
                    break;
                case refStore_string:
                    *(cast(GrString*) context.ostack[context.ostackPos]) = context
                        .sstack[context.sstackPos];
                    context.ostackPos--;
                    context.sstackPos--;
                    context.pc++;
                    break;
                case refStore_object:
                    *(cast(GrPtr*) context.ostack[context.ostackPos - 1]) = context
                        .ostack[context.ostackPos];
                    context.ostackPos -= 2;
                    context.pc++;
                    break;
                case refStore2_int:
                    *(cast(GrInt*) context.ostack[context.ostackPos]) = context
                        .istack[context.istackPos];
                    context.ostackPos--;
                    context.pc++;
                    break;
                case refStore2_real:
                    *(cast(GrReal*) context.ostack[context.ostackPos]) = context
                        .rstack[context.rstackPos];
                    context.ostackPos--;
                    context.pc++;
                    break;
                case refStore2_string:
                    *(cast(GrString*) context.ostack[context.ostackPos]) = context
                        .sstack[context.sstackPos];
                    context.ostackPos--;
                    context.pc++;
                    break;
                case refStore2_object:
                    *(cast(GrPtr*) context.ostack[context.ostackPos - 1]) = context
                        .ostack[context.ostackPos];
                    context.ostack[context.ostackPos - 1] = context.ostack[context.ostackPos];
                    context.ostackPos--;
                    context.pc++;
                    break;
                case fieldStore_int:
                    (cast(GrField) context.ostack[context.ostackPos]).ivalue
                        = context.istack[context.istackPos];
                    context.istackPos += grGetInstructionSignedValue(opcode);
                    context.ostackPos--;
                    context.pc++;
                    break;
                case fieldStore_real:
                    (cast(GrField) context.ostack[context.ostackPos]).rvalue
                        = context.rstack[context.rstackPos];
                    context.rstackPos += grGetInstructionSignedValue(opcode);
                    context.ostackPos--;
                    context.pc++;
                    break;
                case fieldStore_string:
                    (cast(GrField) context.ostack[context.ostackPos]).svalue
                        = context.sstack[context.sstackPos];
                    context.sstackPos += grGetInstructionSignedValue(opcode);
                    context.ostackPos--;
                    context.pc++;
                    break;
                case fieldStore_object:
                    context.ostackPos--;
                    (cast(GrField) context.ostack[context.ostackPos]).ovalue
                        = context.ostack[context.ostackPos + 1];
                    context.ostack[context.ostackPos] = context.ostack[context.ostackPos + 1];
                    context.ostackPos += grGetInstructionSignedValue(opcode);
                    context.pc++;
                    break;
                case fieldLoad:
                    if (!context.ostack[context.ostackPos]) {
                        raise(context, "NullError");
                        break;
                    }
                    context.ostack[context.ostackPos] = cast(GrPtr)((cast(GrObject) context.ostack[context.ostackPos])
                            ._fields[grGetInstructionUnsignedValue(opcode)]);
                    context.pc++;
                    break;
                case fieldLoad2:
                    context.ostackPos++;
                    if (context.ostackPos == context.ostack.length)
                        context.ostack.length *= 2;
                    context.ostack[context.ostackPos] = cast(GrPtr)(
                        (cast(GrObject) context.ostack[context.ostackPos - 1])
                            ._fields[grGetInstructionUnsignedValue(opcode)]);
                    context.pc++;
                    break;
                case fieldLoad_int:
                    if (!context.ostack[context.ostackPos]) {
                        raise(context, "NullError");
                        break;
                    }
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = (cast(GrObject) context.ostack[context.ostackPos])
                        ._fields[grGetInstructionUnsignedValue(opcode)].ivalue;
                    context.ostackPos--;
                    context.pc++;
                    break;
                case fieldLoad_real:
                    if (!context.ostack[context.ostackPos]) {
                        raise(context, "NullError");
                        break;
                    }
                    context.rstackPos++;
                    if (context.rstackPos == context.rstack.length)
                        context.rstack.length *= 2;
                    context.rstack[context.rstackPos] = (cast(GrObject) context.ostack[context.ostackPos])
                        ._fields[grGetInstructionUnsignedValue(opcode)].rvalue;
                    context.ostackPos--;
                    context.pc++;
                    break;
                case fieldLoad_string:
                    if (!context.ostack[context.ostackPos]) {
                        raise(context, "NullError");
                        break;
                    }
                    context.sstackPos++;
                    if (context.sstackPos == context.sstack.length)
                        context.sstack.length *= 2;
                    context.sstack[context.sstackPos] = (cast(GrObject) context.ostack[context.ostackPos])
                        ._fields[grGetInstructionUnsignedValue(opcode)].svalue;
                    context.ostackPos--;
                    context.pc++;
                    break;
                case fieldLoad_object:
                    if (!context.ostack[context.ostackPos]) {
                        raise(context, "NullError");
                        break;
                    }
                    context.ostack[context.ostackPos] = (cast(GrObject) context.ostack[context.ostackPos])
                        ._fields[grGetInstructionUnsignedValue(opcode)].ovalue;
                    context.pc++;
                    break;
                case fieldLoad2_int:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    GrField field = (cast(GrObject) context.ostack[context.ostackPos])
                        ._fields[grGetInstructionUnsignedValue(opcode)];
                    context.istack[context.istackPos] = field.ivalue;
                    context.ostack[context.ostackPos] = cast(GrPtr) field;
                    context.pc++;
                    break;
                case fieldLoad2_real:
                    context.rstackPos++;
                    if (context.rstackPos == context.rstack.length)
                        context.rstack.length *= 2;
                    GrField field = (cast(GrObject) context.ostack[context.ostackPos])
                        ._fields[grGetInstructionUnsignedValue(opcode)];
                    context.rstack[context.rstackPos] = field.rvalue;
                    context.ostack[context.ostackPos] = cast(GrPtr) field;
                    context.pc++;
                    break;
                case fieldLoad2_string:
                    context.sstackPos++;
                    if (context.sstackPos == context.sstack.length)
                        context.sstack.length *= 2;
                    GrField field = (cast(GrObject) context.ostack[context.ostackPos])
                        ._fields[grGetInstructionUnsignedValue(opcode)];
                    context.sstack[context.sstackPos] = field.svalue;
                    context.ostack[context.ostackPos] = cast(GrPtr) field;
                    context.pc++;
                    break;
                case fieldLoad2_object:
                    context.ostackPos++;
                    if (context.ostackPos == context.ostack.length)
                        context.ostack.length *= 2;
                    GrField field = (cast(GrObject) context.ostack[context.ostackPos - 1])
                        ._fields[grGetInstructionUnsignedValue(opcode)];
                    context.ostack[context.ostackPos] = field.ovalue;
                    context.ostack[context.ostackPos - 1] = cast(GrPtr) field;
                    context.pc++;
                    break;
                case const_int:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = _bytecode.iconsts[grGetInstructionUnsignedValue(
                            opcode)];
                    context.pc++;
                    break;
                case const_real:
                    context.rstackPos++;
                    if (context.rstackPos == context.rstack.length)
                        context.rstack.length *= 2;
                    context.rstack[context.rstackPos] = _bytecode.rconsts[grGetInstructionUnsignedValue(
                            opcode)];
                    context.pc++;
                    break;
                case const_bool:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = grGetInstructionUnsignedValue(opcode);
                    context.pc++;
                    break;
                case const_string:
                    context.sstackPos++;
                    if (context.sstackPos == context.sstack.length)
                        context.sstack.length *= 2;
                    context.sstack[context.sstackPos] = _bytecode.sconsts[grGetInstructionUnsignedValue(
                            opcode)];
                    context.pc++;
                    break;
                case const_meta:
                    _meta = _bytecode.sconsts[grGetInstructionUnsignedValue(opcode)];
                    context.pc++;
                    break;
                case const_null:
                    context.ostackPos++;
                    if (context.ostackPos == context.ostack.length)
                        context.ostack.length *= 2;
                    context.ostack[context.ostackPos] = null;
                    context.pc++;
                    break;
                case globalPush_int:
                    const uint nbParams = grGetInstructionUnsignedValue(opcode);
                    for (uint i = 1u; i <= nbParams; i++)
                        _iglobalStackOut ~= context.istack[(context.istackPos - nbParams) + i];
                    context.istackPos -= nbParams;
                    context.pc++;
                    break;
                case globalPush_real:
                    const uint nbParams = grGetInstructionUnsignedValue(opcode);
                    for (uint i = 1u; i <= nbParams; i++)
                        _fglobalStackOut ~= context.rstack[(context.rstackPos - nbParams) + i];
                    context.rstackPos -= nbParams;
                    context.pc++;
                    break;
                case globalPush_string:
                    const uint nbParams = grGetInstructionUnsignedValue(opcode);
                    for (uint i = 1u; i <= nbParams; i++)
                        _sglobalStackOut ~= context.sstack[(context.sstackPos - nbParams) + i];
                    context.sstackPos -= nbParams;
                    context.pc++;
                    break;
                case globalPush_object:
                    const uint nbParams = grGetInstructionUnsignedValue(opcode);
                    for (uint i = 1u; i <= nbParams; i++)
                        _oglobalStackOut ~= context.ostack[(context.ostackPos - nbParams) + i];
                    context.ostackPos -= nbParams;
                    context.pc++;
                    break;
                case globalPop_int:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = _iglobalStackIn[$ - 1];
                    _iglobalStackIn.length--;
                    context.pc++;
                    break;
                case globalPop_real:
                    context.rstackPos++;
                    if (context.rstackPos == context.rstack.length)
                        context.rstack.length *= 2;
                    context.rstack[context.rstackPos] = _fglobalStackIn[$ - 1];
                    _fglobalStackIn.length--;
                    context.pc++;
                    break;
                case globalPop_string:
                    context.sstackPos++;
                    if (context.sstackPos == context.sstack.length)
                        context.sstack.length *= 2;
                    context.sstack[context.sstackPos] = _sglobalStackIn[$ - 1];
                    _sglobalStackIn.length--;
                    context.pc++;
                    break;
                case globalPop_object:
                    context.ostackPos++;
                    if (context.ostackPos == context.ostack.length)
                        context.ostack.length *= 2;
                    context.ostack[context.ostackPos] = _oglobalStackIn[$ - 1];
                    _oglobalStackIn.length--;
                    context.pc++;
                    break;
                case equal_int:
                    context.istackPos--;
                    context.istack[context.istackPos] = context.istack[context.istackPos]
                        == context.istack[context.istackPos + 1];
                    context.pc++;
                    break;
                case equal_real:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = context.rstack[context.rstackPos - 1]
                        == context.rstack[context.rstackPos];
                    context.rstackPos -= 2;
                    context.pc++;
                    break;
                case equal_string:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = context.sstack[context.sstackPos - 1]
                        == context.sstack[context.sstackPos];
                    context.sstackPos -= 2;
                    context.pc++;
                    break;
                case notEqual_int:
                    context.istackPos--;
                    context.istack[context.istackPos] = context.istack[context.istackPos]
                        != context.istack[context.istackPos + 1];
                    context.pc++;
                    break;
                case notEqual_real:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = context.rstack[context.rstackPos - 1]
                        != context.rstack[context.rstackPos];
                    context.rstackPos -= 2;
                    context.pc++;
                    break;
                case notEqual_string:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = context.sstack[context.sstackPos - 1]
                        != context.sstack[context.sstackPos];
                    context.sstackPos -= 2;
                    context.pc++;
                    break;
                case greaterOrEqual_int:
                    context.istackPos--;
                    context.istack[context.istackPos] = context.istack[context.istackPos]
                        >= context.istack[context.istackPos + 1];
                    context.pc++;
                    break;
                case greaterOrEqual_real:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = context.rstack[context.rstackPos - 1]
                        >= context.rstack[context.rstackPos];
                    context.rstackPos -= 2;
                    context.pc++;
                    break;
                case lesserOrEqual_int:
                    context.istackPos--;
                    context.istack[context.istackPos] = context.istack[context.istackPos]
                        <= context.istack[context.istackPos + 1];
                    context.pc++;
                    break;
                case lesserOrEqual_real:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = context.rstack[context.rstackPos - 1]
                        <= context.rstack[context.rstackPos];
                    context.rstackPos -= 2;
                    context.pc++;
                    break;
                case greater_int:
                    context.istackPos--;
                    context.istack[context.istackPos] = context.istack[context.istackPos]
                        > context.istack[context.istackPos + 1];
                    context.pc++;
                    break;
                case greater_real:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = context.rstack[context.rstackPos - 1]
                        > context.rstack[context.rstackPos];
                    context.rstackPos -= 2;
                    context.pc++;
                    break;
                case lesser_int:
                    context.istackPos--;
                    context.istack[context.istackPos] = context.istack[context.istackPos]
                        < context.istack[context.istackPos + 1];
                    context.pc++;
                    break;
                case lesser_real:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = context.rstack[context.rstackPos - 1]
                        < context.rstack[context.rstackPos];
                    context.rstackPos -= 2;
                    context.pc++;
                    break;
                case isNonNull_object:
                    context.istackPos++;
                    context.istack[context.istackPos] = (context.ostack[context.ostackPos]!is null);
                    context.ostackPos--;
                    context.pc++;
                    break;
                case and_int:
                    context.istackPos--;
                    context.istack[context.istackPos] = context.istack[context.istackPos]
                        && context.istack[context.istackPos + 1];
                    context.pc++;
                    break;
                case or_int:
                    context.istackPos--;
                    context.istack[context.istackPos] = context.istack[context.istackPos]
                        || context.istack[context.istackPos + 1];
                    context.pc++;
                    break;
                case not_int:
                    context.istack[context.istackPos] = !context.istack[context.istackPos];
                    context.pc++;
                    break;
                case add_int:
                    context.istackPos--;
                    context.istack[context.istackPos] += context.istack[context.istackPos + 1];
                    context.pc++;
                    break;
                case add_real:
                    context.rstackPos--;
                    context.rstack[context.rstackPos] += context.rstack[context.rstackPos + 1];
                    context.pc++;
                    break;
                case concatenate_string:
                    context.sstackPos--;
                    context.sstack[context.sstackPos] ~= context.sstack[context.sstackPos + 1];
                    context.pc++;
                    break;
                case substract_int:
                    context.istackPos--;
                    context.istack[context.istackPos] -= context.istack[context.istackPos + 1];
                    context.pc++;
                    break;
                case substract_real:
                    context.rstackPos--;
                    context.rstack[context.rstackPos] -= context.rstack[context.rstackPos + 1];
                    context.pc++;
                    break;
                case multiply_int:
                    context.istackPos--;
                    context.istack[context.istackPos] *= context.istack[context.istackPos + 1];
                    context.pc++;
                    break;
                case multiply_real:
                    context.rstackPos--;
                    context.rstack[context.rstackPos] *= context.rstack[context.rstackPos + 1];
                    context.pc++;
                    break;
                case divide_int:
                    if (context.istack[context.istackPos] == 0) {
                        raise(context, "ZeroDivisionError");
                        break;
                    }
                    context.istackPos--;
                    context.istack[context.istackPos] /= context.istack[context.istackPos + 1];
                    context.pc++;
                    break;
                case divide_real:
                    if (context.rstack[context.rstackPos] == 0f) {
                        raise(context, "ZeroDivisionError");
                        break;
                    }
                    context.rstackPos--;
                    context.rstack[context.rstackPos] /= context.rstack[context.rstackPos + 1];
                    context.pc++;
                    break;
                case remainder_int:
                    if (context.istack[context.istackPos] == 0) {
                        raise(context, "ZeroDivisionError");
                        break;
                    }
                    context.istackPos--;
                    context.istack[context.istackPos] %= context.istack[context.istackPos + 1];
                    context.pc++;
                    break;
                case remainder_real:
                    if (context.rstack[context.rstackPos] == 0f) {
                        raise(context, "ZeroDivisionError");
                        break;
                    }
                    context.rstackPos--;
                    context.rstack[context.rstackPos] %= context.rstack[context.rstackPos + 1];
                    context.pc++;
                    break;
                case negative_int:
                    context.istack[context.istackPos] = -context.istack[context.istackPos];
                    context.pc++;
                    break;
                case negative_real:
                    context.rstack[context.rstackPos] = -context.rstack[context.rstackPos];
                    context.pc++;
                    break;
                case increment_int:
                    context.istack[context.istackPos]++;
                    context.pc++;
                    break;
                case increment_real:
                    context.rstack[context.rstackPos] += 1f;
                    context.pc++;
                    break;
                case decrement_int:
                    context.istack[context.istackPos]--;
                    context.pc++;
                    break;
                case decrement_real:
                    context.rstack[context.rstackPos] -= 1f;
                    context.pc++;
                    break;
                case copy_int:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = context.istack[context.istackPos - 1];
                    context.pc++;
                    break;
                case copy_real:
                    context.rstackPos++;
                    if (context.rstackPos == context.rstack.length)
                        context.rstack.length *= 2;
                    context.rstack[context.rstackPos] = context.rstack[context.rstackPos - 1];
                    context.pc++;
                    break;
                case copy_string:
                    context.sstackPos++;
                    if (context.sstackPos == context.sstack.length)
                        context.sstack.length *= 2;
                    context.sstack[context.sstackPos] = context.sstack[context.sstackPos - 1];
                    context.pc++;
                    break;
                case copy_object:
                    context.ostackPos++;
                    if (context.ostackPos == context.ostack.length)
                        context.ostack.length *= 2;
                    context.ostack[context.ostackPos] = context.ostack[context.ostackPos - 1];
                    context.pc++;
                    break;
                case swap_int:
                    swapAt(context.istack, context.istackPos - 1, context.istackPos);
                    context.pc++;
                    break;
                case swap_real:
                    swapAt(context.rstack, context.rstackPos - 1, context.rstackPos);
                    context.pc++;
                    break;
                case swap_string:
                    swapAt(context.sstack, context.sstackPos - 1, context.sstackPos);
                    context.pc++;
                    break;
                case swap_object:
                    swapAt(context.ostack, context.ostackPos - 1, context.ostackPos);
                    context.pc++;
                    break;
                case setupIterator:
                    if (context.istack[context.istackPos] < 0)
                        context.istack[context.istackPos] = 0;
                    context.istack[context.istackPos]++;
                    context.pc++;
                    break;
                case return_:
                    //If another task was killed by an exception,
                    //we might end up there if the task has just been spawned.
                    if (context.stackPos < 0 && context.isKilled) {
                        _contexts.markInternalForRemoval(index);
                        continue contextsLabel;
                    }
                    //Check for deferred calls.
                    else if (context.callStack[context.stackPos].deferStack.length) {
                        //Pop the last defer and run it.
                        context.pc = context.callStack[context.stackPos].deferStack[$ - 1];
                        context.callStack[context.stackPos].deferStack.length--;
                    }
                    else {
                        //Then returns to the last context.
                        context.stackPos--;
                        context.pc = context.callStack[context.stackPos].retPosition;
                        context.ilocalsPos -= context.callStack[context.stackPos].ilocalStackSize;
                        context.rlocalsPos -= context.callStack[context.stackPos].rlocalStackSize;
                        context.slocalsPos -= context.callStack[context.stackPos].slocalStackSize;
                        context.olocalsPos -= context.callStack[context.stackPos].olocalStackSize;
                    }
                    break;
                case unwind:
                    //If another task was killed by an exception,
                    //we might end up there if the task has just been spawned.
                    if (context.stackPos < 0) {
                        _contexts.markInternalForRemoval(index);
                        continue contextsLabel;
                    }
                    //Check for deferred calls.
                    else if (context.callStack[context.stackPos].deferStack.length) {
                        //Pop the next defer and run it.
                        context.pc = context.callStack[context.stackPos].deferStack[$ - 1];
                        context.callStack[context.stackPos].deferStack.length--;
                    }
                    else if (context.isKilled) {
                        if (context.stackPos) {
                            //Then returns to the last context without modifying the pc.
                            context.stackPos--;
                            context.ilocalsPos
                                -= context.callStack[context.stackPos].ilocalStackSize;
                            context.rlocalsPos
                                -= context.callStack[context.stackPos].rlocalStackSize;
                            context.slocalsPos
                                -= context.callStack[context.stackPos].slocalStackSize;
                            context.olocalsPos
                                -= context.callStack[context.stackPos].olocalStackSize;

                            if (_isDebug)
                                _debugProfileEnd();
                        }
                        else {
                            //Every deferred call has been executed, now die.
                            _contexts.markInternalForRemoval(index);
                            continue contextsLabel;
                        }
                    }
                    else if (context.isPanicking) {
                        //An exception has been raised without any try/catch inside the function.
                        //So all deferred code is run here before searching in the parent function.
                        if (context.stackPos) {
                            //Then returns to the last context without modifying the pc.
                            context.stackPos--;
                            context.ilocalsPos
                                -= context.callStack[context.stackPos].ilocalStackSize;
                            context.rlocalsPos
                                -= context.callStack[context.stackPos].rlocalStackSize;
                            context.slocalsPos
                                -= context.callStack[context.stackPos].slocalStackSize;
                            context.olocalsPos
                                -= context.callStack[context.stackPos].olocalStackSize;

                            if (_isDebug)
                                _debugProfileEnd();

                            //Exception handler found in the current function, just jump.
                            if (context.callStack[context.stackPos].exceptionHandlers.length) {
                                context.pc
                                    = context.callStack[context.stackPos].exceptionHandlers[$ - 1];
                            }
                        }
                        else {
                            //Kill the others.
                            foreach (coroutine; _contexts) {
                                coroutine.pc = cast(uint)(cast(int) _bytecode.opcodes.length - 1);
                                coroutine.isKilled = true;
                            }
                            _contextsToSpawn.reset();

                            //The VM is now panicking.
                            _isPanicking = true;
                            _panicMessage = _sglobalStackIn[$ - 1];
                            _sglobalStackIn.length--;

                            //Every deferred call has been executed, now die.
                            _contexts.markInternalForRemoval(index);
                            continue contextsLabel;
                        }
                    }
                    else {
                        //Then returns to the last context.
                        context.stackPos--;
                        context.pc = context.callStack[context.stackPos].retPosition;
                        context.ilocalsPos -= context.callStack[context.stackPos].ilocalStackSize;
                        context.rlocalsPos -= context.callStack[context.stackPos].rlocalStackSize;
                        context.slocalsPos -= context.callStack[context.stackPos].slocalStackSize;
                        context.olocalsPos -= context.callStack[context.stackPos].olocalStackSize;

                        if (_isDebug)
                            _debugProfileEnd();
                    }
                    break;
                case defer:
                    context.callStack[context.stackPos].deferStack ~= context.pc + grGetInstructionSignedValue(
                        opcode);
                    context.pc++;
                    break;
                case localStack_int:
                    const auto istackSize = grGetInstructionUnsignedValue(opcode);
                    context.callStack[context.stackPos].ilocalStackSize = istackSize;
                    if ((context.ilocalsPos + istackSize) >= context.ilocalsLimit)
                        context.doubleIntLocalsStackSize(context.ilocalsPos + istackSize);
                    context.pc++;
                    break;
                case localStack_real:
                    const auto fstackSize = grGetInstructionUnsignedValue(opcode);
                    context.callStack[context.stackPos].rlocalStackSize = fstackSize;
                    if ((context.rlocalsPos + fstackSize) >= context.rlocalsLimit)
                        context.doubleRealLocalsStackSize(context.rlocalsPos + fstackSize);
                    context.pc++;
                    break;
                case localStack_string:
                    const auto sstackSize = grGetInstructionUnsignedValue(opcode);
                    context.callStack[context.stackPos].slocalStackSize = sstackSize;
                    if ((context.slocalsPos + sstackSize) >= context.slocalsLimit)
                        context.doubleStringLocalsStackSize(context.slocalsPos + sstackSize);
                    context.pc++;
                    break;
                case localStack_object:
                    const auto ostackSize = grGetInstructionUnsignedValue(opcode);
                    context.callStack[context.stackPos].olocalStackSize = ostackSize;
                    if ((context.olocalsPos + ostackSize) >= context.olocalsLimit)
                        context.doubleObjectLocalsStackSize(context.olocalsPos + ostackSize);
                    context.pc++;
                    break;
                case call:
                    if ((context.stackPos + 1) >= context.callStackLimit)
                        context.doubleCallStackSize();
                    context.ilocalsPos += context.callStack[context.stackPos].ilocalStackSize;
                    context.rlocalsPos += context.callStack[context.stackPos].rlocalStackSize;
                    context.slocalsPos += context.callStack[context.stackPos].slocalStackSize;
                    context.olocalsPos += context.callStack[context.stackPos].olocalStackSize;
                    context.callStack[context.stackPos].retPosition = context.pc + 1u;
                    context.stackPos++;
                    context.pc = grGetInstructionUnsignedValue(opcode);
                    break;
                case anonymousCall:
                    if ((context.stackPos + 1) >= context.callStackLimit)
                        context.doubleCallStackSize();
                    context.ilocalsPos += context.callStack[context.stackPos].ilocalStackSize;
                    context.rlocalsPos += context.callStack[context.stackPos].rlocalStackSize;
                    context.slocalsPos += context.callStack[context.stackPos].slocalStackSize;
                    context.olocalsPos += context.callStack[context.stackPos].olocalStackSize;
                    context.callStack[context.stackPos].retPosition = context.pc + 1u;
                    context.stackPos++;
                    context.pc = cast(uint) context.istack[context.istackPos];
                    context.istackPos--;
                    break;
                case primitiveCall:
                    _calls[grGetInstructionUnsignedValue(opcode)].call(context);
                    context.pc++;
                    if (context.blocker)
                        continue contextsLabel;
                    break;
                case jump:
                    context.pc += grGetInstructionSignedValue(opcode);
                    break;
                case jumpEqual:
                    if (context.istack[context.istackPos])
                        context.pc++;
                    else
                        context.pc += grGetInstructionSignedValue(opcode);
                    context.istackPos--;
                    break;
                case jumpNotEqual:
                    if (context.istack[context.istackPos])
                        context.pc += grGetInstructionSignedValue(opcode);
                    else
                        context.pc++;
                    context.istackPos--;
                    break;
                case list_int:
                    GrIntList ary = new GrIntList;
                    const auto arySize = grGetInstructionUnsignedValue(opcode);
                    for (int i = arySize - 1; i >= 0; i--)
                        ary.data ~= context.istack[context.istackPos - i];
                    context.istackPos -= arySize;
                    context.ostackPos++;
                    if (context.ostackPos == context.ostack.length)
                        context.ostack.length *= 2;
                    context.ostack[context.ostackPos] = cast(GrPtr) ary;
                    context.pc++;
                    break;
                case list_real:
                    GrRealList ary = new GrRealList;
                    const auto arySize = grGetInstructionUnsignedValue(opcode);
                    for (int i = arySize - 1; i >= 0; i--)
                        ary.data ~= context.rstack[context.rstackPos - i];
                    context.rstackPos -= arySize;
                    context.ostackPos++;
                    if (context.ostackPos == context.ostack.length)
                        context.ostack.length *= 2;
                    context.ostack[context.ostackPos] = cast(GrPtr) ary;
                    context.pc++;
                    break;
                case list_string:
                    GrStringList ary = new GrStringList;
                    const auto arySize = grGetInstructionUnsignedValue(opcode);
                    for (int i = arySize - 1; i >= 0; i--)
                        ary.data ~= context.sstack[context.sstackPos - i];
                    context.sstackPos -= arySize;
                    context.ostackPos++;
                    if (context.ostackPos == context.ostack.length)
                        context.ostack.length *= 2;
                    context.ostack[context.ostackPos] = cast(GrPtr) ary;
                    context.pc++;
                    break;
                case list_object:
                    GrObjectList ary = new GrObjectList;
                    const auto arySize = grGetInstructionUnsignedValue(opcode);
                    for (int i = arySize - 1; i >= 0; i--)
                        ary.data ~= context.ostack[context.ostackPos - i];
                    context.ostackPos -= arySize;
                    context.ostackPos++;
                    if (context.ostackPos == context.ostack.length)
                        context.ostack.length *= 2;
                    context.ostack[context.ostackPos] = cast(GrPtr) ary;
                    context.pc++;
                    break;
                case index_int:
                    GrIntList ary = cast(GrIntList) context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(context, "IndexError");
                        break;
                    }
                    context.ostack[context.ostackPos] = &ary.data[idx];
                    context.istackPos--;
                    context.pc++;
                    break;
                case index_real:
                    GrRealList ary = cast(GrRealList) context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(context, "IndexError");
                        break;
                    }
                    context.ostack[context.ostackPos] = &ary.data[idx];
                    context.istackPos--;
                    context.pc++;
                    break;
                case index_string:
                    GrStringList ary = cast(GrStringList) context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(context, "IndexError");
                        break;
                    }
                    context.ostack[context.ostackPos] = &ary.data[idx];
                    context.istackPos--;
                    context.pc++;
                    break;
                case index_object:
                    GrObjectList ary = cast(GrObjectList) context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(context, "IndexError");
                        break;
                    }
                    context.ostack[context.ostackPos] = &ary.data[idx];
                    context.istackPos--;
                    context.pc++;
                    break;
                case index2_int:
                    GrIntList ary = cast(GrIntList) context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(context, "IndexError");
                        break;
                    }
                    context.istack[context.istackPos] = ary.data[idx];
                    context.ostackPos--;
                    context.pc++;
                    break;
                case index2_real:
                    GrRealList ary = cast(GrRealList) context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(context, "IndexError");
                        break;
                    }
                    context.rstackPos++;
                    if (context.rstackPos == context.rstack.length)
                        context.rstack.length *= 2;
                    context.istackPos--;
                    context.ostackPos--;
                    context.rstack[context.rstackPos] = ary.data[idx];
                    context.pc++;
                    break;
                case index2_string:
                    GrStringList ary = cast(GrStringList) context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(context, "IndexError");
                        break;
                    }
                    context.sstackPos++;
                    if (context.sstackPos == context.sstack.length)
                        context.sstack.length *= 2;
                    context.istackPos--;
                    context.ostackPos--;
                    context.sstack[context.sstackPos] = ary.data[idx];
                    context.pc++;
                    break;
                case index2_object:
                    GrObjectList ary = cast(GrObjectList) context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(context, "IndexError");
                        break;
                    }
                    context.istackPos--;
                    context.ostack[context.ostackPos] = ary.data[idx];
                    context.pc++;
                    break;
                case index3_int:
                    GrIntList ary = cast(GrIntList) context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(context, "IndexError");
                        break;
                    }
                    context.istack[context.istackPos] = ary.data[idx];
                    context.ostack[context.ostackPos] = &ary.data[idx];
                    context.pc++;
                    break;
                case index3_real:
                    GrRealList ary = cast(GrRealList) context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(context, "IndexError");
                        break;
                    }
                    context.istackPos--;
                    context.rstackPos++;
                    context.rstack[context.rstackPos] = ary.data[idx];
                    context.ostack[context.ostackPos] = &ary.data[idx];
                    context.pc++;
                    break;
                case index3_string:
                    GrStringList ary = cast(GrStringList) context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(context, "IndexError");
                        break;
                    }
                    context.istackPos--;
                    context.sstackPos++;
                    context.sstack[context.sstackPos] = ary.data[idx];
                    context.ostack[context.ostackPos] = &ary.data[idx];
                    context.pc++;
                    break;
                case index3_object:
                    GrObjectList ary = cast(GrObjectList) context.ostack[context.ostackPos];
                    auto idx = context.istack[context.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(context, "IndexError");
                        break;
                    }
                    context.istackPos--;
                    context.ostack[context.ostackPos] = &ary.data[idx];
                    context.ostackPos++;
                    context.ostack[context.ostackPos] = ary.data[idx];
                    context.pc++;
                    break;
                case length_int:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = cast(int)(
                        (cast(GrIntList) context.ostack[context.ostackPos]).data.length);
                    context.ostackPos--;
                    context.pc++;
                    break;
                case length_real:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = cast(int)(
                        (cast(GrRealList) context.ostack[context.ostackPos]).data.length);
                    context.ostackPos--;
                    context.pc++;
                    break;
                case length_string:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = cast(int)(
                        (cast(GrStringList) context.ostack[context.ostackPos]).data.length);
                    context.ostackPos--;
                    context.pc++;
                    break;
                case length_object:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = cast(int)(
                        (cast(GrObjectList) context.ostack[context.ostackPos]).data.length);
                    context.ostackPos--;
                    context.pc++;
                    break;
                case concatenate_intList:
                    GrIntList nList = new GrIntList;
                    context.ostackPos--;
                    nList.data = (cast(GrIntList) context.ostack[context.ostackPos])
                        .data ~ (cast(GrIntList) context.ostack[context.ostackPos + 1]).data;
                    context.ostack[context.ostackPos] = cast(GrPtr) nList;
                    context.pc++;
                    break;
                case concatenate_realList:
                    GrRealList nList = new GrRealList;
                    context.ostackPos--;
                    nList.data = (cast(GrRealList) context.ostack[context.ostackPos])
                        .data ~ (cast(GrRealList) context.ostack[context.ostackPos + 1]).data;
                    context.ostack[context.ostackPos] = cast(GrPtr) nList;
                    context.pc++;
                    break;
                case concatenate_stringList:
                    GrStringList nList = new GrStringList;
                    context.ostackPos--;
                    nList.data = (cast(GrStringList) context.ostack[context.ostackPos])
                        .data ~ (cast(GrStringList) context.ostack[context.ostackPos + 1]).data;
                    context.ostack[context.ostackPos] = cast(GrPtr) nList;
                    context.pc++;
                    break;
                case concatenate_objectList:
                    GrObjectList nList = new GrObjectList;
                    context.ostackPos--;
                    nList.data = (cast(GrObjectList) context.ostack[context.ostackPos])
                        .data ~ (cast(GrObjectList) context.ostack[context.ostackPos + 1]).data;
                    context.ostack[context.ostackPos] = cast(GrPtr) nList;
                    context.pc++;
                    break;
                case append_int:
                    GrIntList nList = new GrIntList;
                    nList.data = (cast(GrIntList) context.ostack[context.ostackPos])
                        .data ~ context.istack[context.istackPos];
                    context.ostack[context.ostackPos] = cast(GrPtr) nList;
                    context.istackPos--;
                    context.pc++;
                    break;
                case append_real:
                    GrRealList nList = new GrRealList;
                    nList.data = (cast(GrRealList) context.ostack[context.ostackPos])
                        .data ~ context.rstack[context.rstackPos];
                    context.ostack[context.ostackPos] = cast(GrPtr) nList;
                    context.rstackPos--;
                    context.pc++;
                    break;
                case append_string:
                    GrStringList nList = new GrStringList;
                    nList.data = (cast(GrStringList) context.ostack[context.ostackPos])
                        .data ~ context.sstack[context.sstackPos];
                    context.ostack[context.ostackPos] = cast(GrPtr) nList;
                    context.sstackPos--;
                    context.pc++;
                    break;
                case append_object:
                    GrObjectList nList = new GrObjectList;
                    context.ostackPos--;
                    nList.data = (cast(GrObjectList) context.ostack[context.ostackPos])
                        .data ~ context.ostack[context.ostackPos + 1];
                    context.ostack[context.ostackPos] = cast(GrPtr) nList;
                    context.pc++;
                    break;
                case prepend_int:
                    GrIntList nList = new GrIntList;
                    nList.data = context.istack[context.istackPos] ~ (
                        cast(GrIntList) context.ostack[context.ostackPos]).data;
                    context.ostack[context.ostackPos] = cast(GrPtr) nList;
                    context.istackPos--;
                    context.pc++;
                    break;
                case prepend_real:
                    GrRealList nList = new GrRealList;
                    nList.data = context.rstack[context.rstackPos] ~ (
                        cast(GrRealList) context.ostack[context.ostackPos]).data;
                    context.ostack[context.ostackPos] = cast(GrPtr) nList;
                    context.rstackPos--;
                    context.pc++;
                    break;
                case prepend_string:
                    GrStringList nList = new GrStringList;
                    nList.data = context.sstack[context.sstackPos] ~ (
                        cast(GrStringList) context.ostack[context.ostackPos]).data;
                    context.ostack[context.ostackPos] = cast(GrPtr) nList;
                    context.sstackPos--;
                    context.pc++;
                    break;
                case prepend_object:
                    GrObjectList nList = new GrObjectList;
                    context.ostackPos--;
                    nList.data = context.ostack[context.ostackPos] ~ (
                        cast(
                            GrObjectList) context.ostack[context.ostackPos + 1]).data;
                    context.ostack[context.ostackPos] = cast(GrPtr) nList;
                    context.pc++;
                    break;
                case equal_intList:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = (cast(GrIntList) context.ostack[context.ostackPos - 1])
                        .data == (cast(GrIntList) context.ostack[context.ostackPos]).data;
                    context.ostackPos -= 2;
                    context.pc++;
                    break;
                case equal_realList:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = (cast(GrRealList) context.ostack[context.ostackPos - 1])
                        .data == (cast(GrRealList) context.ostack[context.ostackPos]).data;
                    context.ostackPos -= 2;
                    context.pc++;
                    break;
                case equal_stringList:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = (cast(GrStringList) context.ostack[context.ostackPos - 1])
                        .data == (cast(GrStringList) context.ostack[context.ostackPos]).data;
                    context.ostackPos -= 2;
                    context.pc++;
                    break;
                case notEqual_intList:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = (cast(GrIntList) context.ostack[context.ostackPos - 1])
                        .data != (cast(GrIntList) context.ostack[context.ostackPos]).data;
                    context.ostackPos -= 2;
                    context.pc++;
                    break;
                case notEqual_realList:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = (cast(GrRealList) context.ostack[context.ostackPos - 1])
                        .data != (cast(GrRealList) context.ostack[context.ostackPos]).data;
                    context.ostackPos -= 2;
                    context.pc++;
                    break;
                case notEqual_stringList:
                    context.istackPos++;
                    if (context.istackPos == context.istack.length)
                        context.istack.length *= 2;
                    context.istack[context.istackPos] = (cast(GrStringList) context.ostack[context.ostackPos - 1])
                        .data != (cast(GrStringList) context.ostack[context.ostackPos]).data;
                    context.ostackPos -= 2;
                    context.pc++;
                    break;
                case debugProfileBegin:
                    _debugProfileBegin(opcode, context.pc);
                    context.pc++;
                    break;
                case debugProfileEnd:
                    _debugProfileEnd();
                    context.pc++;
                    break;
                }
            }
        }
        _contexts.sweepMarkedData();
    }

    /// Create a new object.
    GrObject createObject(string name) {
        GrClassBuilder* builder = (name in _classBuilders);
        if (builder)
            return new GrObject(*builder);
        return null;
    }

    import core.time : MonoTime, Duration;

    private {
        bool _isDebug;
        DebugFunction[int] _debugFunctions;
        DebugFunction[] _debugFunctionsStack;
    }

    /// Runtime information about every called functions
    DebugFunction[int] dumpProfiling() {
        return _debugFunctions;
    }

    /// Prettify the result from `dumpProfiling`
    string prettifyProfiling() {
        import std.algorithm.comparison : max;
        import std.conv : to;

        string report;
        ulong functionNameLength = 10;
        ulong countLength = 10;
        ulong totalLength = 10;
        ulong averageLength = 10;
        foreach (func; dumpProfiling()) {
            functionNameLength = max(func.name.length, functionNameLength);
            countLength = max(to!string(func.count).length, countLength);
            totalLength = max(to!string(func.total.total!"msecs").length, totalLength);
            Duration average = func.count ? (func.total / func.count) : Duration.zero;
            averageLength = max(to!string(average.total!"msecs").length, averageLength);
        }
        string header = "| " ~ leftJustify("Function", functionNameLength) ~ " | " ~ leftJustify("Count",
            countLength) ~ " | " ~ leftJustify("Total",
            totalLength) ~ " | " ~ leftJustify("Average", averageLength) ~ " |";

        string separator = "+" ~ leftJustify("", functionNameLength + 2,
            '-') ~ "+" ~ leftJustify("", countLength + 2, '-') ~ "+" ~ leftJustify("",
            totalLength + 2, '-') ~ "+" ~ leftJustify("", averageLength + 2, '-') ~ "+";
        report ~= separator ~ "\n" ~ header ~ "\n" ~ separator ~ "\n";
        foreach (func; dumpProfiling()) {
            Duration average = func.count ? (func.total / func.count) : Duration.zero;
            report ~= "| " ~ leftJustify(func.name, functionNameLength) ~ " | " ~ leftJustify(
                to!string(func.count), countLength) ~ " | " ~ leftJustify(to!string(func.total.total!"msecs"),
                totalLength) ~ " | " ~ leftJustify(to!string(average.total!"msecs"),
                averageLength) ~ " |\n";
        }
        report ~= separator ~ "\n";
        return report;
    }

    /// Runtime information of a called function
    final class DebugFunction {
        private {
            MonoTime _start;
            Duration _total;
            ulong _count;
            int _pc;
            string _name;
        }

        @property {
            /// Total execution time passed inside the function
            Duration total() const {
                return _total;
            }
            /// Total times the function was called
            ulong count() const {
                return _count;
            }
            /// Prettified name of the function
            string name() const {
                return _name;
            }
        }
    }

    private void _debugProfileEnd() {
        if (!_debugFunctionsStack.length)
            return;
        auto p = _debugFunctionsStack[$ - 1];
        _debugFunctionsStack.length--;
        p._total += MonoTime.currTime() - p._start;
        p._count++;
    }

    private void _debugProfileBegin(uint opcode, int pc) {
        _isDebug = true;
        auto p = (pc in _debugFunctions);
        if (p) {
            p._start = MonoTime.currTime();
            _debugFunctionsStack ~= *p;
        }
        else {
            auto debugFunc = new DebugFunction;
            debugFunc._pc = pc;
            debugFunc._name = _bytecode.sconsts[grGetInstructionUnsignedValue(opcode)];
            debugFunc._start = MonoTime.currTime();
            _debugFunctions[pc] = debugFunc;
            _debugFunctionsStack ~= debugFunc;
        }
    }
}
