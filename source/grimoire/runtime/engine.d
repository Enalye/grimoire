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

import grimoire.runtime.task;
import grimoire.runtime.array;
import grimoire.runtime.object;
import grimoire.runtime.channel;
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

        /// Task array.
        GrTask[] _tasks, _createdTasks;

        /// Global panic state.
        /// It means that the throwing task didn't handle the exception.
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

    enum Priority {
        immediate,
        normal
    }

    /// External way of stopping the VM.
    shared bool isRunning = true;

    @property {
        /// Check if there is a task currently running.
        bool hasTasks() const {
            return (_tasks.length + _createdTasks.length) > 0uL;
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
        _tasks ~= new GrTask(this);
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
	Checks whether an event exists. \
	The event's name must be mangled with its signature.
	*/
    bool hasEvent(string mangledName) {
        return (mangledName in _bytecode.events) !is null;
    }

    /**
	Spawn a new task registered as an event. \
	The event's name must be mangled with its signature.
	---
	event myEvent() {
		print("myEvent was created !");
	}
	---
	*/
    GrTask callEvent(string mangledName, Priority priority = Priority.normal) {
        const auto event = mangledName in _bytecode.events;
        if (event is null)
            throw new Exception("no event \'" ~ mangledName ~ "\' in script");
        GrTask task = new GrTask(this);
        task.pc = *event;
        final switch (priority) with (Priority) {
        case immediate:
            _tasks ~= task;
            break;
        case normal:
            _createdTasks ~= task;
            break;
        }
        return task;
    }

    /**
	Spawn a new task at an arbitrary address. \
	The address needs to correspond to the start of a task, else the VM will crash. \
	*/
    GrTask callAddress(uint pc) {
        if (pc == 0 || pc >= _bytecode.opcodes.length)
            throw new Exception("address \'" ~ to!string(pc) ~ "\' out of bounds");

        // For now we assume a task is always following a die from the previous task
        // Not a 100% foolproof method but it'll do for now.
        const GrOpcode opcode = cast(GrOpcode)(_bytecode.opcodes[(cast(long) pc) - 1] & 0xFF);
        if (opcode != GrOpcode.die)
            throw new Exception("the address does not correspond with a task");

        GrTask task = new GrTask(this);
        task.pc = pc;
        _createdTasks ~= task;
        return task;
    }

    package(grimoire) void pushTask(GrTask task) {
        _createdTasks ~= task;
    }

    /**
    Captures an unhandled error and kill the VM.
    */
    void panic() {
        _tasks.length = 0;
    }

    /**
    Immediately prints a stacktrace to standard output
    */
    private void generateStackTrace(GrTask task) {
        {
            GrStackTrace trace;
            trace.pc = task.pc;
            auto func = getFunctionInfo(task.pc);
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

        for (int i = task.stackPos - 1; i >= 0; i--) {
            GrStackTrace trace;
            trace.pc = cast(uint)((cast(int) task.callStack[i].retPosition) - 1);
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
	The error is raised inside a task. \
	___
	For each function it unwinds, it'll search for a `try/catch` that captures it. \
	If none is found, it'll execute every `defer` statements inside the function and
	do the same for the next function in the callstack.
	___
	If nothing catches the error inside the task, the VM enters in a panic state. \
	Every tasks will then execute their `defer` statements and be killed.
	*/
    void raise(GrTask task, string message) {
        if (task.isPanicking)
            return;
        //Error message.
        _sglobalStackIn ~= message;

        generateStackTrace(task);

        //We indicate that the task is in a panic state until a catch is found.
        task.isPanicking = true;

        task.pc = cast(uint)(cast(int) _bytecode.opcodes.length - 1);
    }

    /**
	Marks each task as killed and prevents any new task from spawning.
	*/
    private void killTasks() {
        foreach (task; _tasks) {
            task.pc = cast(uint)(cast(int) _bytecode.opcodes.length - 1);
            task.isKilled = true;
        }
        _createdTasks.length = 0;
    }

    alias getBoolVariable = getVariable!bool;
    alias getIntVariable = getVariable!GrInt;
    alias getRealVariable = getVariable!GrReal;
    alias getStringVariable = getVariable!GrString;
    alias getPtrVariable = getVariable!GrPtr;

    GrObject getObjectVariable(string name) {
        return cast(GrObject) getVariable!(GrPtr)(name);
    }

    GrIntArray getIntArrayVariable(string name) {
        return cast(GrIntArray) getVariable!(GrPtr)(name);
    }

    GrRealArray getRealArrayVariable(string name) {
        return cast(GrRealArray) getVariable!(GrPtr)(name);
    }

    GrStringArray getStringArrayVariable(string name) {
        return cast(GrStringArray) getVariable!(GrPtr)(name);
    }

    GrObjectArray getObjectArrayVariable(string name) {
        return cast(GrObjectArray) getVariable!(GrPtr)(name);
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

    void setIntArrayVariable(string name, GrIntArray value) {
        setVariable!(GrPtr)(name, cast(GrPtr) value);
    }

    void setRealArrayVariable(string name, GrRealArray value) {
        setVariable!(GrPtr)(name, cast(GrPtr) value);
    }

    void setStringArrayVariable(string name, GrStringArray value) {
        setVariable!(GrPtr)(name, cast(GrPtr) value);
    }

    void setObjectArrayVariable(string name, GrObjectArray value) {
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
        import std.algorithm.mutation : remove, swap;

        if (_createdTasks.length) {
            foreach_reverse (task; _createdTasks)
                _tasks ~= task;
            _createdTasks.length = 0;

            swap(_iglobalStackIn, _iglobalStackOut);
            swap(_fglobalStackIn, _fglobalStackOut);
            swap(_sglobalStackIn, _sglobalStackOut);
            swap(_oglobalStackIn, _oglobalStackOut);
        }

        tasksLabel: for (uint index = 0u; index < _tasks.length;) {
            GrTask currentTask = _tasks[index];
            if (currentTask.blocker) {
                if (!currentTask.blocker.run())
                    continue;
                currentTask.blocker = null;
            }
            while (isRunning) {
                const uint opcode = _bytecode.opcodes[currentTask.pc];
                final switch (opcode & 0xFF) with (GrOpcode) {
                case nop:
                    currentTask.pc++;
                    break;
                case throw_:
                    if (!currentTask.isPanicking) {
                        //Error message.
                        _sglobalStackIn ~= currentTask.sstack[currentTask.sstackPos];
                        currentTask.sstackPos--;
                        generateStackTrace(currentTask);

                        //We indicate that the task is in a panic state until a catch is found.
                        currentTask.isPanicking = true;
                    }

                    //Exception handler found in the current function, just jump.
                    if (currentTask.callStack[currentTask.stackPos].exceptionHandlers.length) {
                        currentTask.pc = currentTask
                            .callStack[currentTask.stackPos].exceptionHandlers[$ - 1];
                    }
                    //No exception handler in the current function, unwinding the deferred code, then return.

                    //Check for deferred calls as we will exit the current function.
                    else if (currentTask.callStack[currentTask.stackPos].deferStack.length) {
                        //Pop the last defer and run it.
                        currentTask.pc = currentTask
                            .callStack[currentTask.stackPos].deferStack[$ - 1];
                        currentTask.callStack[currentTask.stackPos].deferStack.length--;
                        //The search for an exception handler will be done by Unwind after all defer
                        //has been called for this function.
                    }
                    else if (currentTask.stackPos) {
                        //Then returns to the last currentTask, raise will be run again.
                        currentTask.stackPos--;
                        currentTask.ilocalsPos -= currentTask
                            .callStack[currentTask.stackPos].ilocalStackSize;
                        currentTask.rlocalsPos -= currentTask
                            .callStack[currentTask.stackPos].rlocalStackSize;
                        currentTask.slocalsPos -= currentTask
                            .callStack[currentTask.stackPos].slocalStackSize;
                        currentTask.olocalsPos -= currentTask
                            .callStack[currentTask.stackPos].olocalStackSize;

                        if (_isDebug)
                            _debugProfileEnd();
                    }
                    else {
                        //Kill the others.
                        killTasks();

                        //The VM is now panicking.
                        _isPanicking = true;
                        _panicMessage = _sglobalStackIn[$ - 1];
                        _sglobalStackIn.length--;

                        //Every deferred call has been executed, now die.
                        _tasks = _tasks.remove(index);
                        continue tasksLabel;
                    }
                    break;
                case try_:
                    currentTask.callStack[currentTask.stackPos].exceptionHandlers ~= currentTask.pc + grGetInstructionSignedValue(
                        opcode);
                    currentTask.pc++;
                    break;
                case catch_:
                    currentTask.callStack[currentTask.stackPos].exceptionHandlers.length--;
                    if (currentTask.isPanicking) {
                        currentTask.isPanicking = false;
                        _stackTraces.length = 0;
                        currentTask.pc++;
                    }
                    else {
                        currentTask.pc += grGetInstructionSignedValue(opcode);
                    }
                    break;
                case task:
                    GrTask nTask = new GrTask(this);
                    nTask.pc = grGetInstructionUnsignedValue(opcode);
                    _createdTasks ~= nTask;
                    currentTask.pc++;
                    break;
                case anonymousTask:
                    GrTask nTask = new GrTask(this);
                    nTask.pc = cast(uint) currentTask.istack[currentTask.istackPos];
                    currentTask.istackPos--;
                    _createdTasks ~= nTask;
                    currentTask.pc++;
                    break;
                case die:
                    //Check for deferred calls.
                    if (currentTask.callStack[currentTask.stackPos].deferStack.length) {
                        //Pop the last defer and run it.
                        currentTask.pc = currentTask
                            .callStack[currentTask.stackPos].deferStack[$ - 1];
                        currentTask.callStack[currentTask.stackPos].deferStack.length--;

                        //Flag as killed so the entire stack will be unwinded.
                        currentTask.isKilled = true;
                    }
                    else if (currentTask.stackPos) {
                        //Then returns to the last currentTask.
                        currentTask.stackPos--;
                        currentTask.pc = currentTask.callStack[currentTask.stackPos].retPosition;
                        currentTask.ilocalsPos -= currentTask
                            .callStack[currentTask.stackPos].ilocalStackSize;
                        currentTask.rlocalsPos -= currentTask
                            .callStack[currentTask.stackPos].rlocalStackSize;
                        currentTask.slocalsPos -= currentTask
                            .callStack[currentTask.stackPos].slocalStackSize;
                        currentTask.olocalsPos -= currentTask
                            .callStack[currentTask.stackPos].olocalStackSize;

                        //Flag as killed so the entire stack will be unwinded.
                        currentTask.isKilled = true;
                    }
                    else {
                        //No need to flag if the call stack is empty without any deferred statement.
                        _tasks = _tasks.remove(index);
                        continue tasksLabel;
                    }
                    break;
                case quit:
                    killTasks();
                    index++;
                    continue tasksLabel;
                case yield:
                    currentTask.pc++;
                    index++;
                    continue tasksLabel;
                case new_:
                    currentTask.ostackPos++;
                    if (currentTask.ostackPos == currentTask.ostack.length)
                        currentTask.ostack.length *= 2;
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) new GrObject(
                        _bytecode.classes[grGetInstructionUnsignedValue(opcode)]);
                    currentTask.pc++;
                    break;
                case channel_int:
                    currentTask.ostackPos++;
                    if (currentTask.ostackPos == currentTask.ostack.length)
                        currentTask.ostack.length *= 2;
                    currentTask.ostack[currentTask.ostackPos] = cast(
                        GrPtr) new GrIntChannel(
                        grGetInstructionUnsignedValue(opcode));
                    currentTask.pc++;
                    break;
                case channel_real:
                    currentTask.ostackPos++;
                    if (currentTask.ostackPos == currentTask.ostack.length)
                        currentTask.ostack.length *= 2;
                    currentTask.ostack[currentTask.ostackPos] = cast(
                        GrPtr) new GrRealChannel(
                        grGetInstructionUnsignedValue(opcode));
                    currentTask.pc++;
                    break;
                case channel_string:
                    currentTask.ostackPos++;
                    if (currentTask.ostackPos == currentTask.ostack.length)
                        currentTask.ostack.length *= 2;
                    currentTask.ostack[currentTask.ostackPos] = cast(
                        GrPtr) new GrStringChannel(
                        grGetInstructionUnsignedValue(opcode));
                    currentTask.pc++;
                    break;
                case channel_object:
                    currentTask.ostackPos++;
                    if (currentTask.ostackPos == currentTask.ostack.length)
                        currentTask.ostack.length *= 2;
                    currentTask.ostack[currentTask.ostackPos] = cast(
                        GrPtr) new GrObjectChannel(
                        grGetInstructionUnsignedValue(opcode));
                    currentTask.pc++;
                    break;
                case send_int:
                    GrIntChannel chan = cast(GrIntChannel) currentTask
                        .ostack[currentTask.ostackPos];
                    if (!chan.isOwned) {
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isLocked = true;
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            currentTask.istackPos--;
                            currentTask.ostackPos--;
                            raise(currentTask, "ChannelError");
                        }
                    }
                    else if (chan.canSend) {
                        currentTask.isLocked = false;
                        chan.send(currentTask.istack[currentTask.istackPos]);
                        currentTask.ostackPos--;
                        currentTask.pc++;
                    }
                    else {
                        currentTask.isLocked = true;
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            index++;
                            continue tasksLabel;
                        }
                    }
                    break;
                case send_real:
                    GrRealChannel chan = cast(GrRealChannel) currentTask
                        .ostack[currentTask.ostackPos];
                    if (!chan.isOwned) {
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isLocked = true;
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            currentTask.rstackPos--;
                            currentTask.ostackPos--;
                            raise(currentTask, "ChannelError");
                        }
                    }
                    else if (chan.canSend) {
                        currentTask.isLocked = false;
                        chan.send(currentTask.rstack[currentTask.rstackPos]);
                        currentTask.ostackPos--;
                        currentTask.pc++;
                    }
                    else {
                        currentTask.isLocked = true;
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            index++;
                            continue tasksLabel;
                        }
                    }
                    break;
                case send_string:
                    GrStringChannel chan = cast(GrStringChannel) currentTask
                        .ostack[currentTask.ostackPos];
                    if (!chan.isOwned) {
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isLocked = true;
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            currentTask.sstackPos--;
                            currentTask.ostackPos--;
                            raise(currentTask, "ChannelError");
                        }
                    }
                    else if (chan.canSend) {
                        currentTask.isLocked = false;
                        chan.send(currentTask.sstack[currentTask.sstackPos]);
                        currentTask.ostackPos--;
                        currentTask.pc++;
                    }
                    else {
                        currentTask.isLocked = true;
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            index++;
                            continue tasksLabel;
                        }
                    }
                    break;
                case send_object:
                    GrObjectChannel chan = cast(GrObjectChannel) currentTask
                        .ostack[currentTask.ostackPos - 1];
                    if (!chan.isOwned) {
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isLocked = true;
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            currentTask.ostackPos -= 2;
                            raise(currentTask, "ChannelError");
                        }
                    }
                    else if (chan.canSend) {
                        currentTask.isLocked = false;
                        chan.send(currentTask.ostack[currentTask.ostackPos]);
                        currentTask.ostack[currentTask.ostackPos - 1] = currentTask
                            .ostack[currentTask.ostackPos];
                        currentTask.ostackPos--;
                        currentTask.pc++;
                    }
                    else {
                        currentTask.isLocked = true;
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            index++;
                            continue tasksLabel;
                        }
                    }
                    break;
                case receive_int:
                    GrIntChannel chan = cast(GrIntChannel) currentTask
                        .ostack[currentTask.ostackPos];
                    if (!chan.isOwned) {
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isLocked = true;
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            currentTask.ostackPos--;
                            raise(currentTask, "ChannelError");
                        }
                    }
                    else if (chan.canReceive) {
                        currentTask.isLocked = false;
                        currentTask.istackPos++;
                        if (currentTask.istackPos == currentTask.istack.length)
                            currentTask.istack.length *= 2;
                        currentTask.istack[currentTask.istackPos] = chan.receive();
                        currentTask.ostackPos--;
                        currentTask.pc++;
                    }
                    else {
                        chan.setReceiverReady();
                        currentTask.isLocked = true;
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            index++;
                            continue tasksLabel;
                        }
                    }
                    break;
                case receive_real:
                    GrRealChannel chan = cast(GrRealChannel) currentTask
                        .ostack[currentTask.ostackPos];
                    if (!chan.isOwned) {
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isLocked = true;
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            currentTask.ostackPos--;
                            raise(currentTask, "ChannelError");
                        }
                    }
                    else if (chan.canReceive) {
                        currentTask.isLocked = false;
                        currentTask.rstackPos++;
                        if (currentTask.rstackPos == currentTask.rstack.length)
                            currentTask.rstack.length *= 2;
                        currentTask.rstack[currentTask.rstackPos] = chan.receive();
                        currentTask.ostackPos--;
                        currentTask.pc++;
                    }
                    else {
                        chan.setReceiverReady();
                        currentTask.isLocked = true;
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            index++;
                            continue tasksLabel;
                        }
                    }
                    break;
                case receive_string:
                    GrStringChannel chan = cast(GrStringChannel) currentTask
                        .ostack[currentTask.ostackPos];
                    if (!chan.isOwned) {
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isLocked = true;
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            currentTask.ostackPos--;
                            raise(currentTask, "ChannelError");
                        }
                    }
                    else if (chan.canReceive) {
                        currentTask.isLocked = false;
                        currentTask.sstackPos++;
                        if (currentTask.sstackPos == currentTask.sstack.length)
                            currentTask.sstack.length *= 2;
                        currentTask.sstack[currentTask.sstackPos] = chan.receive();
                        currentTask.ostackPos--;
                        currentTask.pc++;
                    }
                    else {
                        chan.setReceiverReady();
                        currentTask.isLocked = true;
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            index++;
                            continue tasksLabel;
                        }
                    }
                    break;
                case receive_object:
                    GrObjectChannel chan = cast(GrObjectChannel) currentTask
                        .ostack[currentTask.ostackPos];
                    if (!chan.isOwned) {
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isLocked = true;
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            currentTask.ostackPos--;
                            raise(currentTask, "ChannelError");
                        }
                    }
                    else if (chan.canReceive) {
                        currentTask.isLocked = false;
                        currentTask.ostack[currentTask.ostackPos] = chan.receive();
                        currentTask.pc++;
                    }
                    else {
                        chan.setReceiverReady();
                        currentTask.isLocked = true;
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            index++;
                            continue tasksLabel;
                        }
                    }
                    break;
                case startSelectChannel:
                    currentTask.pushState();
                    currentTask.pc++;
                    break;
                case endSelectChannel:
                    currentTask.popState();
                    currentTask.pc++;
                    break;
                case tryChannel:
                    if (currentTask.isEvaluatingChannel)
                        raise(currentTask, "SelectError");
                    currentTask.isEvaluatingChannel = true;
                    currentTask.selectPositionJump = currentTask.pc + grGetInstructionSignedValue(
                        opcode);
                    currentTask.pc++;
                    break;
                case checkChannel:
                    if (!currentTask.isEvaluatingChannel)
                        raise(currentTask, "SelectError");
                    currentTask.isEvaluatingChannel = false;
                    currentTask.restoreState();
                    currentTask.pc++;
                    break;
                case shiftStack_int:
                    currentTask.istackPos += grGetInstructionSignedValue(opcode);
                    currentTask.pc++;
                    break;
                case shiftStack_real:
                    currentTask.rstackPos += grGetInstructionSignedValue(opcode);
                    currentTask.pc++;
                    break;
                case shiftStack_string:
                    currentTask.sstackPos += grGetInstructionSignedValue(opcode);
                    currentTask.pc++;
                    break;
                case shiftStack_object:
                    currentTask.ostackPos += grGetInstructionSignedValue(opcode);
                    currentTask.pc++;
                    break;
                case localStore_int:
                    currentTask.ilocals[currentTask.ilocalsPos + grGetInstructionUnsignedValue(
                            opcode)] = currentTask.istack[currentTask.istackPos];
                    currentTask.istackPos--;
                    currentTask.pc++;
                    break;
                case localStore_real:
                    currentTask.rlocals[currentTask.rlocalsPos + grGetInstructionUnsignedValue(
                            opcode)] = currentTask.rstack[currentTask.rstackPos];
                    currentTask.rstackPos--;
                    currentTask.pc++;
                    break;
                case localStore_string:
                    currentTask.slocals[currentTask.slocalsPos + grGetInstructionUnsignedValue(
                            opcode)] = currentTask.sstack[currentTask.sstackPos];
                    currentTask.sstackPos--;
                    currentTask.pc++;
                    break;
                case localStore_object:
                    currentTask.olocals[currentTask.olocalsPos + grGetInstructionUnsignedValue(
                            opcode)] = currentTask.ostack[currentTask.ostackPos];
                    currentTask.ostackPos--;
                    currentTask.pc++;
                    break;
                case localStore2_int:
                    currentTask.ilocals[currentTask.ilocalsPos + grGetInstructionUnsignedValue(
                            opcode)] = currentTask.istack[currentTask.istackPos];
                    currentTask.pc++;
                    break;
                case localStore2_real:
                    currentTask.rlocals[currentTask.rlocalsPos + grGetInstructionUnsignedValue(
                            opcode)] = currentTask.rstack[currentTask.rstackPos];
                    currentTask.pc++;
                    break;
                case localStore2_string:
                    currentTask.slocals[currentTask.slocalsPos + grGetInstructionUnsignedValue(
                            opcode)] = currentTask.sstack[currentTask.sstackPos];
                    currentTask.pc++;
                    break;
                case localStore2_object:
                    currentTask.olocals[currentTask.olocalsPos + grGetInstructionUnsignedValue(
                            opcode)] = currentTask.ostack[currentTask.ostackPos];
                    currentTask.pc++;
                    break;
                case localLoad_int:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos]
                        = currentTask.ilocals[currentTask.ilocalsPos + grGetInstructionUnsignedValue(
                                opcode)];
                    currentTask.pc++;
                    break;
                case localLoad_real:
                    currentTask.rstackPos++;
                    if (currentTask.rstackPos == currentTask.rstack.length)
                        currentTask.rstack.length *= 2;
                    currentTask.rstack[currentTask.rstackPos]
                        = currentTask.rlocals[currentTask.rlocalsPos + grGetInstructionUnsignedValue(
                                opcode)];
                    currentTask.pc++;
                    break;
                case localLoad_string:
                    currentTask.sstackPos++;
                    if (currentTask.sstackPos == currentTask.sstack.length)
                        currentTask.sstack.length *= 2;
                    currentTask.sstack[currentTask.sstackPos]
                        = currentTask.slocals[currentTask.slocalsPos + grGetInstructionUnsignedValue(
                                opcode)];
                    currentTask.pc++;
                    break;
                case localLoad_object:
                    currentTask.ostackPos++;
                    if (currentTask.ostackPos == currentTask.ostack.length)
                        currentTask.ostack.length *= 2;
                    currentTask.ostack[currentTask.ostackPos]
                        = currentTask.olocals[currentTask.olocalsPos + grGetInstructionUnsignedValue(
                                opcode)];
                    currentTask.pc++;
                    break;
                case globalStore_int:
                    _iglobals[grGetInstructionUnsignedValue(opcode)] = currentTask
                        .istack[currentTask.istackPos];
                    currentTask.istackPos--;
                    currentTask.pc++;
                    break;
                case globalStore_real:
                    _rglobals[grGetInstructionUnsignedValue(opcode)] = currentTask
                        .rstack[currentTask.rstackPos];
                    currentTask.rstackPos--;
                    currentTask.pc++;
                    break;
                case globalStore_string:
                    _sglobals[grGetInstructionUnsignedValue(opcode)] = currentTask
                        .sstack[currentTask.sstackPos];
                    currentTask.sstackPos--;
                    currentTask.pc++;
                    break;
                case globalStore_object:
                    _oglobals[grGetInstructionUnsignedValue(opcode)] = currentTask
                        .ostack[currentTask.ostackPos];
                    currentTask.ostackPos--;
                    currentTask.pc++;
                    break;
                case globalStore2_int:
                    _iglobals[grGetInstructionUnsignedValue(opcode)] = currentTask
                        .istack[currentTask.istackPos];
                    currentTask.pc++;
                    break;
                case globalStore2_real:
                    _rglobals[grGetInstructionUnsignedValue(opcode)] = currentTask
                        .rstack[currentTask.rstackPos];
                    currentTask.pc++;
                    break;
                case globalStore2_string:
                    _sglobals[grGetInstructionUnsignedValue(opcode)] = currentTask
                        .sstack[currentTask.sstackPos];
                    currentTask.pc++;
                    break;
                case globalStore2_object:
                    _oglobals[grGetInstructionUnsignedValue(opcode)] = currentTask
                        .ostack[currentTask.ostackPos];
                    currentTask.pc++;
                    break;
                case globalLoad_int:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = _iglobals[grGetInstructionUnsignedValue(
                            opcode)];
                    currentTask.pc++;
                    break;
                case globalLoad_real:
                    currentTask.rstackPos++;
                    if (currentTask.rstackPos == currentTask.rstack.length)
                        currentTask.rstack.length *= 2;
                    currentTask.rstack[currentTask.rstackPos] = _rglobals[grGetInstructionUnsignedValue(
                            opcode)];
                    currentTask.pc++;
                    break;
                case globalLoad_string:
                    currentTask.sstackPos++;
                    if (currentTask.sstackPos == currentTask.sstack.length)
                        currentTask.sstack.length *= 2;
                    currentTask.sstack[currentTask.sstackPos] = _sglobals[grGetInstructionUnsignedValue(
                            opcode)];
                    currentTask.pc++;
                    break;
                case globalLoad_object:
                    currentTask.ostackPos++;
                    if (currentTask.ostackPos == currentTask.ostack.length)
                        currentTask.ostack.length *= 2;
                    currentTask.ostack[currentTask.ostackPos] = _oglobals[grGetInstructionUnsignedValue(
                            opcode)];
                    currentTask.pc++;
                    break;
                case refStore_int:
                    *(cast(GrInt*) currentTask.ostack[currentTask.ostackPos]) = currentTask
                        .istack[currentTask.istackPos];
                    currentTask.ostackPos--;
                    currentTask.istackPos--;
                    currentTask.pc++;
                    break;
                case refStore_real:
                    *(cast(GrReal*) currentTask.ostack[currentTask.ostackPos]) = currentTask
                        .rstack[currentTask.rstackPos];
                    currentTask.ostackPos--;
                    currentTask.rstackPos--;
                    currentTask.pc++;
                    break;
                case refStore_string:
                    *(cast(GrString*) currentTask.ostack[currentTask.ostackPos]) = currentTask
                        .sstack[currentTask.sstackPos];
                    currentTask.ostackPos--;
                    currentTask.sstackPos--;
                    currentTask.pc++;
                    break;
                case refStore_object:
                    *(cast(GrPtr*) currentTask.ostack[currentTask.ostackPos - 1]) = currentTask
                        .ostack[currentTask.ostackPos];
                    currentTask.ostackPos -= 2;
                    currentTask.pc++;
                    break;
                case refStore2_int:
                    *(cast(GrInt*) currentTask.ostack[currentTask.ostackPos]) = currentTask
                        .istack[currentTask.istackPos];
                    currentTask.ostackPos--;
                    currentTask.pc++;
                    break;
                case refStore2_real:
                    *(cast(GrReal*) currentTask.ostack[currentTask.ostackPos]) = currentTask
                        .rstack[currentTask.rstackPos];
                    currentTask.ostackPos--;
                    currentTask.pc++;
                    break;
                case refStore2_string:
                    *(cast(GrString*) currentTask.ostack[currentTask.ostackPos]) = currentTask
                        .sstack[currentTask.sstackPos];
                    currentTask.ostackPos--;
                    currentTask.pc++;
                    break;
                case refStore2_object:
                    *(cast(GrPtr*) currentTask.ostack[currentTask.ostackPos - 1]) = currentTask
                        .ostack[currentTask.ostackPos];
                    currentTask.ostack[currentTask.ostackPos - 1] = currentTask
                        .ostack[currentTask.ostackPos];
                    currentTask.ostackPos--;
                    currentTask.pc++;
                    break;
                case fieldStore_int:
                    (cast(GrField) currentTask.ostack[currentTask.ostackPos]).ivalue
                        = currentTask.istack[currentTask.istackPos];
                    currentTask.istackPos += grGetInstructionSignedValue(opcode);
                    currentTask.ostackPos--;
                    currentTask.pc++;
                    break;
                case fieldStore_real:
                    (cast(GrField) currentTask.ostack[currentTask.ostackPos]).rvalue
                        = currentTask.rstack[currentTask.rstackPos];
                    currentTask.rstackPos += grGetInstructionSignedValue(opcode);
                    currentTask.ostackPos--;
                    currentTask.pc++;
                    break;
                case fieldStore_string:
                    (cast(GrField) currentTask.ostack[currentTask.ostackPos]).svalue
                        = currentTask.sstack[currentTask.sstackPos];
                    currentTask.sstackPos += grGetInstructionSignedValue(opcode);
                    currentTask.ostackPos--;
                    currentTask.pc++;
                    break;
                case fieldStore_object:
                    currentTask.ostackPos--;
                    (cast(GrField) currentTask.ostack[currentTask.ostackPos]).ovalue
                        = currentTask.ostack[currentTask.ostackPos + 1];
                    currentTask.ostack[currentTask.ostackPos] = currentTask
                        .ostack[currentTask.ostackPos + 1];
                    currentTask.ostackPos += grGetInstructionSignedValue(opcode);
                    currentTask.pc++;
                    break;
                case fieldLoad:
                    if (!currentTask.ostack[currentTask.ostackPos]) {
                        raise(currentTask, "NullError");
                        break;
                    }
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr)(
                        (cast(GrObject) currentTask.ostack[currentTask.ostackPos])
                            ._fields[grGetInstructionUnsignedValue(opcode)]);
                    currentTask.pc++;
                    break;
                case fieldLoad2:
                    currentTask.ostackPos++;
                    if (currentTask.ostackPos == currentTask.ostack.length)
                        currentTask.ostack.length *= 2;
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr)(
                        (cast(GrObject) currentTask.ostack[currentTask.ostackPos - 1])
                            ._fields[grGetInstructionUnsignedValue(opcode)]);
                    currentTask.pc++;
                    break;
                case fieldLoad_int:
                    if (!currentTask.ostack[currentTask.ostackPos]) {
                        raise(currentTask, "NullError");
                        break;
                    }
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = (
                        cast(GrObject) currentTask.ostack[currentTask.ostackPos])
                        ._fields[grGetInstructionUnsignedValue(opcode)].ivalue;
                    currentTask.ostackPos--;
                    currentTask.pc++;
                    break;
                case fieldLoad_real:
                    if (!currentTask.ostack[currentTask.ostackPos]) {
                        raise(currentTask, "NullError");
                        break;
                    }
                    currentTask.rstackPos++;
                    if (currentTask.rstackPos == currentTask.rstack.length)
                        currentTask.rstack.length *= 2;
                    currentTask.rstack[currentTask.rstackPos] = (
                        cast(GrObject) currentTask.ostack[currentTask.ostackPos])
                        ._fields[grGetInstructionUnsignedValue(opcode)].rvalue;
                    currentTask.ostackPos--;
                    currentTask.pc++;
                    break;
                case fieldLoad_string:
                    if (!currentTask.ostack[currentTask.ostackPos]) {
                        raise(currentTask, "NullError");
                        break;
                    }
                    currentTask.sstackPos++;
                    if (currentTask.sstackPos == currentTask.sstack.length)
                        currentTask.sstack.length *= 2;
                    currentTask.sstack[currentTask.sstackPos] = (
                        cast(GrObject) currentTask.ostack[currentTask.ostackPos])
                        ._fields[grGetInstructionUnsignedValue(opcode)].svalue;
                    currentTask.ostackPos--;
                    currentTask.pc++;
                    break;
                case fieldLoad_object:
                    if (!currentTask.ostack[currentTask.ostackPos]) {
                        raise(currentTask, "NullError");
                        break;
                    }
                    currentTask.ostack[currentTask.ostackPos] = (
                        cast(GrObject) currentTask.ostack[currentTask.ostackPos])
                        ._fields[grGetInstructionUnsignedValue(opcode)].ovalue;
                    currentTask.pc++;
                    break;
                case fieldLoad2_int:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    GrField field = (cast(GrObject) currentTask.ostack[currentTask.ostackPos])
                        ._fields[grGetInstructionUnsignedValue(opcode)];
                    currentTask.istack[currentTask.istackPos] = field.ivalue;
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) field;
                    currentTask.pc++;
                    break;
                case fieldLoad2_real:
                    currentTask.rstackPos++;
                    if (currentTask.rstackPos == currentTask.rstack.length)
                        currentTask.rstack.length *= 2;
                    GrField field = (cast(GrObject) currentTask.ostack[currentTask.ostackPos])
                        ._fields[grGetInstructionUnsignedValue(opcode)];
                    currentTask.rstack[currentTask.rstackPos] = field.rvalue;
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) field;
                    currentTask.pc++;
                    break;
                case fieldLoad2_string:
                    currentTask.sstackPos++;
                    if (currentTask.sstackPos == currentTask.sstack.length)
                        currentTask.sstack.length *= 2;
                    GrField field = (cast(GrObject) currentTask.ostack[currentTask.ostackPos])
                        ._fields[grGetInstructionUnsignedValue(opcode)];
                    currentTask.sstack[currentTask.sstackPos] = field.svalue;
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) field;
                    currentTask.pc++;
                    break;
                case fieldLoad2_object:
                    currentTask.ostackPos++;
                    if (currentTask.ostackPos == currentTask.ostack.length)
                        currentTask.ostack.length *= 2;
                    GrField field = (cast(GrObject) currentTask.ostack[currentTask.ostackPos - 1])
                        ._fields[grGetInstructionUnsignedValue(opcode)];
                    currentTask.ostack[currentTask.ostackPos] = field.ovalue;
                    currentTask.ostack[currentTask.ostackPos - 1] = cast(GrPtr) field;
                    currentTask.pc++;
                    break;
                case const_int:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = _bytecode.iconsts[grGetInstructionUnsignedValue(
                            opcode)];
                    currentTask.pc++;
                    break;
                case const_real:
                    currentTask.rstackPos++;
                    if (currentTask.rstackPos == currentTask.rstack.length)
                        currentTask.rstack.length *= 2;
                    currentTask.rstack[currentTask.rstackPos] = _bytecode.rconsts[grGetInstructionUnsignedValue(
                            opcode)];
                    currentTask.pc++;
                    break;
                case const_bool:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = grGetInstructionUnsignedValue(
                        opcode);
                    currentTask.pc++;
                    break;
                case const_string:
                    currentTask.sstackPos++;
                    if (currentTask.sstackPos == currentTask.sstack.length)
                        currentTask.sstack.length *= 2;
                    currentTask.sstack[currentTask.sstackPos] = _bytecode.sconsts[grGetInstructionUnsignedValue(
                            opcode)];
                    currentTask.pc++;
                    break;
                case const_meta:
                    _meta = _bytecode.sconsts[grGetInstructionUnsignedValue(opcode)];
                    currentTask.pc++;
                    break;
                case const_null:
                    currentTask.ostackPos++;
                    if (currentTask.ostackPos == currentTask.ostack.length)
                        currentTask.ostack.length *= 2;
                    currentTask.ostack[currentTask.ostackPos] = null;
                    currentTask.pc++;
                    break;
                case globalPush_int:
                    const uint nbParams = grGetInstructionUnsignedValue(opcode);
                    for (uint i = 1u; i <= nbParams; i++)
                        _iglobalStackOut ~= currentTask.istack[(
                                currentTask.istackPos - nbParams) + i];
                    currentTask.istackPos -= nbParams;
                    currentTask.pc++;
                    break;
                case globalPush_real:
                    const uint nbParams = grGetInstructionUnsignedValue(opcode);
                    for (uint i = 1u; i <= nbParams; i++)
                        _fglobalStackOut ~= currentTask.rstack[(
                                currentTask.rstackPos - nbParams) + i];
                    currentTask.rstackPos -= nbParams;
                    currentTask.pc++;
                    break;
                case globalPush_string:
                    const uint nbParams = grGetInstructionUnsignedValue(opcode);
                    for (uint i = 1u; i <= nbParams; i++)
                        _sglobalStackOut ~= currentTask.sstack[(
                                currentTask.sstackPos - nbParams) + i];
                    currentTask.sstackPos -= nbParams;
                    currentTask.pc++;
                    break;
                case globalPush_object:
                    const uint nbParams = grGetInstructionUnsignedValue(opcode);
                    for (uint i = 1u; i <= nbParams; i++)
                        _oglobalStackOut ~= currentTask.ostack[(
                                currentTask.ostackPos - nbParams) + i];
                    currentTask.ostackPos -= nbParams;
                    currentTask.pc++;
                    break;
                case globalPop_int:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = _iglobalStackIn[$ - 1];
                    _iglobalStackIn.length--;
                    currentTask.pc++;
                    break;
                case globalPop_real:
                    currentTask.rstackPos++;
                    if (currentTask.rstackPos == currentTask.rstack.length)
                        currentTask.rstack.length *= 2;
                    currentTask.rstack[currentTask.rstackPos] = _fglobalStackIn[$ - 1];
                    _fglobalStackIn.length--;
                    currentTask.pc++;
                    break;
                case globalPop_string:
                    currentTask.sstackPos++;
                    if (currentTask.sstackPos == currentTask.sstack.length)
                        currentTask.sstack.length *= 2;
                    currentTask.sstack[currentTask.sstackPos] = _sglobalStackIn[$ - 1];
                    _sglobalStackIn.length--;
                    currentTask.pc++;
                    break;
                case globalPop_object:
                    currentTask.ostackPos++;
                    if (currentTask.ostackPos == currentTask.ostack.length)
                        currentTask.ostack.length *= 2;
                    currentTask.ostack[currentTask.ostackPos] = _oglobalStackIn[$ - 1];
                    _oglobalStackIn.length--;
                    currentTask.pc++;
                    break;
                case equal_int:
                    currentTask.istackPos--;
                    currentTask.istack[currentTask.istackPos] = currentTask.istack[currentTask.istackPos]
                        == currentTask.istack[currentTask.istackPos + 1];
                    currentTask.pc++;
                    break;
                case equal_real:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = currentTask.rstack[currentTask.rstackPos - 1]
                        == currentTask.rstack[currentTask.rstackPos];
                    currentTask.rstackPos -= 2;
                    currentTask.pc++;
                    break;
                case equal_string:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = currentTask.sstack[currentTask.sstackPos - 1]
                        == currentTask.sstack[currentTask.sstackPos];
                    currentTask.sstackPos -= 2;
                    currentTask.pc++;
                    break;
                case notEqual_int:
                    currentTask.istackPos--;
                    currentTask.istack[currentTask.istackPos] = currentTask.istack[currentTask.istackPos]
                        != currentTask.istack[currentTask.istackPos + 1];
                    currentTask.pc++;
                    break;
                case notEqual_real:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = currentTask.rstack[currentTask.rstackPos - 1]
                        != currentTask.rstack[currentTask.rstackPos];
                    currentTask.rstackPos -= 2;
                    currentTask.pc++;
                    break;
                case notEqual_string:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = currentTask.sstack[currentTask.sstackPos - 1]
                        != currentTask.sstack[currentTask.sstackPos];
                    currentTask.sstackPos -= 2;
                    currentTask.pc++;
                    break;
                case greaterOrEqual_int:
                    currentTask.istackPos--;
                    currentTask.istack[currentTask.istackPos] = currentTask.istack[currentTask.istackPos]
                        >= currentTask.istack[currentTask.istackPos + 1];
                    currentTask.pc++;
                    break;
                case greaterOrEqual_real:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = currentTask.rstack[currentTask.rstackPos - 1]
                        >= currentTask.rstack[currentTask.rstackPos];
                    currentTask.rstackPos -= 2;
                    currentTask.pc++;
                    break;
                case lesserOrEqual_int:
                    currentTask.istackPos--;
                    currentTask.istack[currentTask.istackPos] = currentTask.istack[currentTask.istackPos]
                        <= currentTask.istack[currentTask.istackPos + 1];
                    currentTask.pc++;
                    break;
                case lesserOrEqual_real:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = currentTask.rstack[currentTask.rstackPos - 1]
                        <= currentTask.rstack[currentTask.rstackPos];
                    currentTask.rstackPos -= 2;
                    currentTask.pc++;
                    break;
                case greater_int:
                    currentTask.istackPos--;
                    currentTask.istack[currentTask.istackPos] = currentTask.istack[currentTask.istackPos]
                        > currentTask.istack[currentTask.istackPos + 1];
                    currentTask.pc++;
                    break;
                case greater_real:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = currentTask.rstack[currentTask.rstackPos - 1]
                        > currentTask.rstack[currentTask.rstackPos];
                    currentTask.rstackPos -= 2;
                    currentTask.pc++;
                    break;
                case lesser_int:
                    currentTask.istackPos--;
                    currentTask.istack[currentTask.istackPos] = currentTask.istack[currentTask.istackPos]
                        < currentTask.istack[currentTask.istackPos + 1];
                    currentTask.pc++;
                    break;
                case lesser_real:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = currentTask.rstack[currentTask.rstackPos - 1]
                        < currentTask.rstack[currentTask.rstackPos];
                    currentTask.rstackPos -= 2;
                    currentTask.pc++;
                    break;
                case isNonNull_object:
                    currentTask.istackPos++;
                    currentTask.istack[currentTask.istackPos] = (
                        currentTask.ostack[currentTask.ostackPos]!is null);
                    currentTask.ostackPos--;
                    currentTask.pc++;
                    break;
                case and_int:
                    currentTask.istackPos--;
                    currentTask.istack[currentTask.istackPos] = currentTask.istack[currentTask.istackPos]
                        && currentTask.istack[currentTask.istackPos + 1];
                    currentTask.pc++;
                    break;
                case or_int:
                    currentTask.istackPos--;
                    currentTask.istack[currentTask.istackPos] = currentTask.istack[currentTask.istackPos]
                        || currentTask.istack[currentTask.istackPos + 1];
                    currentTask.pc++;
                    break;
                case not_int:
                    currentTask.istack[currentTask.istackPos] = !currentTask
                        .istack[currentTask.istackPos];
                    currentTask.pc++;
                    break;
                case add_int:
                    currentTask.istackPos--;
                    currentTask.istack[currentTask.istackPos] += currentTask
                        .istack[currentTask.istackPos + 1];
                    currentTask.pc++;
                    break;
                case add_real:
                    currentTask.rstackPos--;
                    currentTask.rstack[currentTask.rstackPos] += currentTask
                        .rstack[currentTask.rstackPos + 1];
                    currentTask.pc++;
                    break;
                case concatenate_string:
                    currentTask.sstackPos--;
                    currentTask.sstack[currentTask.sstackPos] ~= currentTask
                        .sstack[currentTask.sstackPos + 1];
                    currentTask.pc++;
                    break;
                case substract_int:
                    currentTask.istackPos--;
                    currentTask.istack[currentTask.istackPos] -= currentTask
                        .istack[currentTask.istackPos + 1];
                    currentTask.pc++;
                    break;
                case substract_real:
                    currentTask.rstackPos--;
                    currentTask.rstack[currentTask.rstackPos] -= currentTask
                        .rstack[currentTask.rstackPos + 1];
                    currentTask.pc++;
                    break;
                case multiply_int:
                    currentTask.istackPos--;
                    currentTask.istack[currentTask.istackPos] *= currentTask
                        .istack[currentTask.istackPos + 1];
                    currentTask.pc++;
                    break;
                case multiply_real:
                    currentTask.rstackPos--;
                    currentTask.rstack[currentTask.rstackPos] *= currentTask
                        .rstack[currentTask.rstackPos + 1];
                    currentTask.pc++;
                    break;
                case divide_int:
                    if (currentTask.istack[currentTask.istackPos] == 0) {
                        raise(currentTask, "ZeroDivisionError");
                        break;
                    }
                    currentTask.istackPos--;
                    currentTask.istack[currentTask.istackPos] /= currentTask
                        .istack[currentTask.istackPos + 1];
                    currentTask.pc++;
                    break;
                case divide_real:
                    if (currentTask.rstack[currentTask.rstackPos] == 0f) {
                        raise(currentTask, "ZeroDivisionError");
                        break;
                    }
                    currentTask.rstackPos--;
                    currentTask.rstack[currentTask.rstackPos] /= currentTask
                        .rstack[currentTask.rstackPos + 1];
                    currentTask.pc++;
                    break;
                case remainder_int:
                    if (currentTask.istack[currentTask.istackPos] == 0) {
                        raise(currentTask, "ZeroDivisionError");
                        break;
                    }
                    currentTask.istackPos--;
                    currentTask.istack[currentTask.istackPos] %= currentTask
                        .istack[currentTask.istackPos + 1];
                    currentTask.pc++;
                    break;
                case remainder_real:
                    if (currentTask.rstack[currentTask.rstackPos] == 0f) {
                        raise(currentTask, "ZeroDivisionError");
                        break;
                    }
                    currentTask.rstackPos--;
                    currentTask.rstack[currentTask.rstackPos] %= currentTask
                        .rstack[currentTask.rstackPos + 1];
                    currentTask.pc++;
                    break;
                case negative_int:
                    currentTask.istack[currentTask.istackPos] = -currentTask
                        .istack[currentTask.istackPos];
                    currentTask.pc++;
                    break;
                case negative_real:
                    currentTask.rstack[currentTask.rstackPos] = -currentTask
                        .rstack[currentTask.rstackPos];
                    currentTask.pc++;
                    break;
                case increment_int:
                    currentTask.istack[currentTask.istackPos]++;
                    currentTask.pc++;
                    break;
                case increment_real:
                    currentTask.rstack[currentTask.rstackPos] += 1f;
                    currentTask.pc++;
                    break;
                case decrement_int:
                    currentTask.istack[currentTask.istackPos]--;
                    currentTask.pc++;
                    break;
                case decrement_real:
                    currentTask.rstack[currentTask.rstackPos] -= 1f;
                    currentTask.pc++;
                    break;
                case copy_int:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = currentTask
                        .istack[currentTask.istackPos - 1];
                    currentTask.pc++;
                    break;
                case copy_real:
                    currentTask.rstackPos++;
                    if (currentTask.rstackPos == currentTask.rstack.length)
                        currentTask.rstack.length *= 2;
                    currentTask.rstack[currentTask.rstackPos] = currentTask
                        .rstack[currentTask.rstackPos - 1];
                    currentTask.pc++;
                    break;
                case copy_string:
                    currentTask.sstackPos++;
                    if (currentTask.sstackPos == currentTask.sstack.length)
                        currentTask.sstack.length *= 2;
                    currentTask.sstack[currentTask.sstackPos] = currentTask
                        .sstack[currentTask.sstackPos - 1];
                    currentTask.pc++;
                    break;
                case copy_object:
                    currentTask.ostackPos++;
                    if (currentTask.ostackPos == currentTask.ostack.length)
                        currentTask.ostack.length *= 2;
                    currentTask.ostack[currentTask.ostackPos] = currentTask
                        .ostack[currentTask.ostackPos - 1];
                    currentTask.pc++;
                    break;
                case swap_int:
                    swapAt(currentTask.istack, currentTask.istackPos - 1, currentTask.istackPos);
                    currentTask.pc++;
                    break;
                case swap_real:
                    swapAt(currentTask.rstack, currentTask.rstackPos - 1, currentTask.rstackPos);
                    currentTask.pc++;
                    break;
                case swap_string:
                    swapAt(currentTask.sstack, currentTask.sstackPos - 1, currentTask.sstackPos);
                    currentTask.pc++;
                    break;
                case swap_object:
                    swapAt(currentTask.ostack, currentTask.ostackPos - 1, currentTask.ostackPos);
                    currentTask.pc++;
                    break;
                case setupIterator:
                    if (currentTask.istack[currentTask.istackPos] < 0)
                        currentTask.istack[currentTask.istackPos] = 0;
                    currentTask.istack[currentTask.istackPos]++;
                    currentTask.pc++;
                    break;
                case return_:
                    //If another task was killed by an exception,
                    //we might killTasks up there if the task has just been spawned.
                    if (currentTask.stackPos < 0 && currentTask.isKilled) {
                        _tasks = _tasks.remove(index);
                        continue tasksLabel;
                    }
                    //Check for deferred calls.
                    else if (currentTask.callStack[currentTask.stackPos].deferStack.length) {
                        //Pop the last defer and run it.
                        currentTask.pc = currentTask
                            .callStack[currentTask.stackPos].deferStack[$ - 1];
                        currentTask.callStack[currentTask.stackPos].deferStack.length--;
                    }
                    else {
                        //Then returns to the last currentTask.
                        currentTask.stackPos--;
                        currentTask.pc = currentTask.callStack[currentTask.stackPos].retPosition;
                        currentTask.ilocalsPos -= currentTask
                            .callStack[currentTask.stackPos].ilocalStackSize;
                        currentTask.rlocalsPos -= currentTask
                            .callStack[currentTask.stackPos].rlocalStackSize;
                        currentTask.slocalsPos -= currentTask
                            .callStack[currentTask.stackPos].slocalStackSize;
                        currentTask.olocalsPos -= currentTask
                            .callStack[currentTask.stackPos].olocalStackSize;
                    }
                    break;
                case unwind:
                    //If another task was killed by an exception,
                    //we might killTasks up there if the task has just been spawned.
                    if (currentTask.stackPos < 0) {
                        _tasks = _tasks.remove(index);
                        continue tasksLabel;
                    }
                    //Check for deferred calls.
                    else if (currentTask.callStack[currentTask.stackPos].deferStack.length) {
                        //Pop the next defer and run it.
                        currentTask.pc = currentTask
                            .callStack[currentTask.stackPos].deferStack[$ - 1];
                        currentTask.callStack[currentTask.stackPos].deferStack.length--;
                    }
                    else if (currentTask.isKilled) {
                        if (currentTask.stackPos) {
                            //Then returns to the last currentTask without modifying the pc.
                            currentTask.stackPos--;
                            currentTask.ilocalsPos
                                -= currentTask.callStack[currentTask.stackPos].ilocalStackSize;
                            currentTask.rlocalsPos
                                -= currentTask.callStack[currentTask.stackPos].rlocalStackSize;
                            currentTask.slocalsPos
                                -= currentTask.callStack[currentTask.stackPos].slocalStackSize;
                            currentTask.olocalsPos
                                -= currentTask.callStack[currentTask.stackPos].olocalStackSize;

                            if (_isDebug)
                                _debugProfileEnd();
                        }
                        else {
                            //Every deferred call has been executed, now die.
                            _tasks = _tasks.remove(index);
                            continue tasksLabel;
                        }
                    }
                    else if (currentTask.isPanicking) {
                        //An exception has been raised without any try/catch inside the function.
                        //So all deferred code is run here before searching in the parent function.
                        if (currentTask.stackPos) {
                            //Then returns to the last currentTask without modifying the pc.
                            currentTask.stackPos--;
                            currentTask.ilocalsPos
                                -= currentTask.callStack[currentTask.stackPos].ilocalStackSize;
                            currentTask.rlocalsPos
                                -= currentTask.callStack[currentTask.stackPos].rlocalStackSize;
                            currentTask.slocalsPos
                                -= currentTask.callStack[currentTask.stackPos].slocalStackSize;
                            currentTask.olocalsPos
                                -= currentTask.callStack[currentTask.stackPos].olocalStackSize;

                            if (_isDebug)
                                _debugProfileEnd();

                            //Exception handler found in the current function, just jump.
                            if (
                                currentTask.callStack[currentTask.stackPos]
                                .exceptionHandlers.length) {
                                currentTask.pc
                                    = currentTask.callStack[currentTask.stackPos].exceptionHandlers[$ - 1];
                            }
                        }
                        else {
                            //Kill the others.
                            foreach (otherTask; _tasks) {
                                otherTask.pc = cast(uint)(cast(int) _bytecode.opcodes.length - 1);
                                otherTask.isKilled = true;
                            }
                            _createdTasks.length = 0;

                            //The VM is now panicking.
                            _isPanicking = true;
                            _panicMessage = _sglobalStackIn[$ - 1];
                            _sglobalStackIn.length--;

                            //Every deferred call has been executed, now die.
                            _tasks = _tasks.remove(index);
                            continue tasksLabel;
                        }
                    }
                    else {
                        //Then returns to the last currentTask.
                        currentTask.stackPos--;
                        currentTask.pc = currentTask.callStack[currentTask.stackPos].retPosition;
                        currentTask.ilocalsPos -= currentTask
                            .callStack[currentTask.stackPos].ilocalStackSize;
                        currentTask.rlocalsPos -= currentTask
                            .callStack[currentTask.stackPos].rlocalStackSize;
                        currentTask.slocalsPos -= currentTask
                            .callStack[currentTask.stackPos].slocalStackSize;
                        currentTask.olocalsPos -= currentTask
                            .callStack[currentTask.stackPos].olocalStackSize;

                        if (_isDebug)
                            _debugProfileEnd();
                    }
                    break;
                case defer:
                    currentTask.callStack[currentTask.stackPos].deferStack ~= currentTask.pc + grGetInstructionSignedValue(
                        opcode);
                    currentTask.pc++;
                    break;
                case localStack_int:
                    const auto istackSize = grGetInstructionUnsignedValue(opcode);
                    currentTask.callStack[currentTask.stackPos].ilocalStackSize = istackSize;
                    if ((currentTask.ilocalsPos + istackSize) >= currentTask.ilocalsLimit)
                        currentTask.doubleIntLocalsStackSize(currentTask.ilocalsPos + istackSize);
                    currentTask.pc++;
                    break;
                case localStack_real:
                    const auto fstackSize = grGetInstructionUnsignedValue(opcode);
                    currentTask.callStack[currentTask.stackPos].rlocalStackSize = fstackSize;
                    if ((currentTask.rlocalsPos + fstackSize) >= currentTask.rlocalsLimit)
                        currentTask.doubleRealLocalsStackSize(currentTask.rlocalsPos + fstackSize);
                    currentTask.pc++;
                    break;
                case localStack_string:
                    const auto sstackSize = grGetInstructionUnsignedValue(opcode);
                    currentTask.callStack[currentTask.stackPos].slocalStackSize = sstackSize;
                    if ((currentTask.slocalsPos + sstackSize) >= currentTask.slocalsLimit)
                        currentTask.doubleStringLocalsStackSize(currentTask.slocalsPos + sstackSize);
                    currentTask.pc++;
                    break;
                case localStack_object:
                    const auto ostackSize = grGetInstructionUnsignedValue(opcode);
                    currentTask.callStack[currentTask.stackPos].olocalStackSize = ostackSize;
                    if ((currentTask.olocalsPos + ostackSize) >= currentTask.olocalsLimit)
                        currentTask.doubleObjectLocalsStackSize(currentTask.olocalsPos + ostackSize);
                    currentTask.pc++;
                    break;
                case call:
                    if ((currentTask.stackPos + 1) >= currentTask.callStackLimit)
                        currentTask.doubleCallStackSize();
                    currentTask.ilocalsPos += currentTask
                        .callStack[currentTask.stackPos].ilocalStackSize;
                    currentTask.rlocalsPos += currentTask
                        .callStack[currentTask.stackPos].rlocalStackSize;
                    currentTask.slocalsPos += currentTask
                        .callStack[currentTask.stackPos].slocalStackSize;
                    currentTask.olocalsPos += currentTask
                        .callStack[currentTask.stackPos].olocalStackSize;
                    currentTask.callStack[currentTask.stackPos].retPosition = currentTask.pc + 1u;
                    currentTask.stackPos++;
                    currentTask.pc = grGetInstructionUnsignedValue(opcode);
                    break;
                case anonymousCall:
                    if ((currentTask.stackPos + 1) >= currentTask.callStackLimit)
                        currentTask.doubleCallStackSize();
                    currentTask.ilocalsPos += currentTask
                        .callStack[currentTask.stackPos].ilocalStackSize;
                    currentTask.rlocalsPos += currentTask
                        .callStack[currentTask.stackPos].rlocalStackSize;
                    currentTask.slocalsPos += currentTask
                        .callStack[currentTask.stackPos].slocalStackSize;
                    currentTask.olocalsPos += currentTask
                        .callStack[currentTask.stackPos].olocalStackSize;
                    currentTask.callStack[currentTask.stackPos].retPosition = currentTask.pc + 1u;
                    currentTask.stackPos++;
                    currentTask.pc = cast(uint) currentTask.istack[currentTask.istackPos];
                    currentTask.istackPos--;
                    break;
                case primitiveCall:
                    _calls[grGetInstructionUnsignedValue(opcode)].call(currentTask);
                    currentTask.pc++;
                    if (currentTask.blocker) {
                        index++;
                        continue tasksLabel;
                    }
                    break;
                case jump:
                    currentTask.pc += grGetInstructionSignedValue(opcode);
                    break;
                case jumpEqual:
                    if (currentTask.istack[currentTask.istackPos])
                        currentTask.pc++;
                    else
                        currentTask.pc += grGetInstructionSignedValue(opcode);
                    currentTask.istackPos--;
                    break;
                case jumpNotEqual:
                    if (currentTask.istack[currentTask.istackPos])
                        currentTask.pc += grGetInstructionSignedValue(opcode);
                    else
                        currentTask.pc++;
                    currentTask.istackPos--;
                    break;
                case array_int:
                    GrIntArray ary = new GrIntArray;
                    const auto arySize = grGetInstructionUnsignedValue(opcode);
                    for (int i = arySize - 1; i >= 0; i--)
                        ary.data ~= currentTask.istack[currentTask.istackPos - i];
                    currentTask.istackPos -= arySize;
                    currentTask.ostackPos++;
                    if (currentTask.ostackPos == currentTask.ostack.length)
                        currentTask.ostack.length *= 2;
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) ary;
                    currentTask.pc++;
                    break;
                case array_real:
                    GrRealArray ary = new GrRealArray;
                    const auto arySize = grGetInstructionUnsignedValue(opcode);
                    for (int i = arySize - 1; i >= 0; i--)
                        ary.data ~= currentTask.rstack[currentTask.rstackPos - i];
                    currentTask.rstackPos -= arySize;
                    currentTask.ostackPos++;
                    if (currentTask.ostackPos == currentTask.ostack.length)
                        currentTask.ostack.length *= 2;
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) ary;
                    currentTask.pc++;
                    break;
                case array_string:
                    GrStringArray ary = new GrStringArray;
                    const auto arySize = grGetInstructionUnsignedValue(opcode);
                    for (int i = arySize - 1; i >= 0; i--)
                        ary.data ~= currentTask.sstack[currentTask.sstackPos - i];
                    currentTask.sstackPos -= arySize;
                    currentTask.ostackPos++;
                    if (currentTask.ostackPos == currentTask.ostack.length)
                        currentTask.ostack.length *= 2;
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) ary;
                    currentTask.pc++;
                    break;
                case array_object:
                    GrObjectArray ary = new GrObjectArray;
                    const auto arySize = grGetInstructionUnsignedValue(opcode);
                    for (int i = arySize - 1; i >= 0; i--)
                        ary.data ~= currentTask.ostack[currentTask.ostackPos - i];
                    currentTask.ostackPos -= arySize;
                    currentTask.ostackPos++;
                    if (currentTask.ostackPos == currentTask.ostack.length)
                        currentTask.ostack.length *= 2;
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) ary;
                    currentTask.pc++;
                    break;
                case index_int:
                    GrIntArray ary = cast(GrIntArray) currentTask.ostack[currentTask.ostackPos];
                    auto idx = currentTask.istack[currentTask.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(currentTask, "IndexError");
                        break;
                    }
                    currentTask.ostack[currentTask.ostackPos] = &ary.data[idx];
                    currentTask.istackPos--;
                    currentTask.pc++;
                    break;
                case index_real:
                    GrRealArray ary = cast(GrRealArray) currentTask.ostack[currentTask.ostackPos];
                    auto idx = currentTask.istack[currentTask.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(currentTask, "IndexError");
                        break;
                    }
                    currentTask.ostack[currentTask.ostackPos] = &ary.data[idx];
                    currentTask.istackPos--;
                    currentTask.pc++;
                    break;
                case index_string:
                    GrStringArray ary = cast(GrStringArray) currentTask
                        .ostack[currentTask.ostackPos];
                    auto idx = currentTask.istack[currentTask.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(currentTask, "IndexError");
                        break;
                    }
                    currentTask.ostack[currentTask.ostackPos] = &ary.data[idx];
                    currentTask.istackPos--;
                    currentTask.pc++;
                    break;
                case index_object:
                    GrObjectArray ary = cast(GrObjectArray) currentTask
                        .ostack[currentTask.ostackPos];
                    auto idx = currentTask.istack[currentTask.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(currentTask, "IndexError");
                        break;
                    }
                    currentTask.ostack[currentTask.ostackPos] = &ary.data[idx];
                    currentTask.istackPos--;
                    currentTask.pc++;
                    break;
                case index2_int:
                    GrIntArray ary = cast(GrIntArray) currentTask.ostack[currentTask.ostackPos];
                    auto idx = currentTask.istack[currentTask.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(currentTask, "IndexError");
                        break;
                    }
                    currentTask.istack[currentTask.istackPos] = ary.data[idx];
                    currentTask.ostackPos--;
                    currentTask.pc++;
                    break;
                case index2_real:
                    GrRealArray ary = cast(GrRealArray) currentTask.ostack[currentTask.ostackPos];
                    auto idx = currentTask.istack[currentTask.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(currentTask, "IndexError");
                        break;
                    }
                    currentTask.rstackPos++;
                    if (currentTask.rstackPos == currentTask.rstack.length)
                        currentTask.rstack.length *= 2;
                    currentTask.istackPos--;
                    currentTask.ostackPos--;
                    currentTask.rstack[currentTask.rstackPos] = ary.data[idx];
                    currentTask.pc++;
                    break;
                case index2_string:
                    GrStringArray ary = cast(GrStringArray) currentTask
                        .ostack[currentTask.ostackPos];
                    auto idx = currentTask.istack[currentTask.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(currentTask, "IndexError");
                        break;
                    }
                    currentTask.sstackPos++;
                    if (currentTask.sstackPos == currentTask.sstack.length)
                        currentTask.sstack.length *= 2;
                    currentTask.istackPos--;
                    currentTask.ostackPos--;
                    currentTask.sstack[currentTask.sstackPos] = ary.data[idx];
                    currentTask.pc++;
                    break;
                case index2_object:
                    GrObjectArray ary = cast(GrObjectArray) currentTask
                        .ostack[currentTask.ostackPos];
                    auto idx = currentTask.istack[currentTask.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(currentTask, "IndexError");
                        break;
                    }
                    currentTask.istackPos--;
                    currentTask.ostack[currentTask.ostackPos] = ary.data[idx];
                    currentTask.pc++;
                    break;
                case index3_int:
                    GrIntArray ary = cast(GrIntArray) currentTask.ostack[currentTask.ostackPos];
                    auto idx = currentTask.istack[currentTask.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(currentTask, "IndexError");
                        break;
                    }
                    currentTask.istack[currentTask.istackPos] = ary.data[idx];
                    currentTask.ostack[currentTask.ostackPos] = &ary.data[idx];
                    currentTask.pc++;
                    break;
                case index3_real:
                    GrRealArray ary = cast(GrRealArray) currentTask.ostack[currentTask.ostackPos];
                    auto idx = currentTask.istack[currentTask.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(currentTask, "IndexError");
                        break;
                    }
                    currentTask.istackPos--;
                    currentTask.rstackPos++;
                    currentTask.rstack[currentTask.rstackPos] = ary.data[idx];
                    currentTask.ostack[currentTask.ostackPos] = &ary.data[idx];
                    currentTask.pc++;
                    break;
                case index3_string:
                    GrStringArray ary = cast(GrStringArray) currentTask
                        .ostack[currentTask.ostackPos];
                    auto idx = currentTask.istack[currentTask.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(currentTask, "IndexError");
                        break;
                    }
                    currentTask.istackPos--;
                    currentTask.sstackPos++;
                    currentTask.sstack[currentTask.sstackPos] = ary.data[idx];
                    currentTask.ostack[currentTask.ostackPos] = &ary.data[idx];
                    currentTask.pc++;
                    break;
                case index3_object:
                    GrObjectArray ary = cast(GrObjectArray) currentTask
                        .ostack[currentTask.ostackPos];
                    auto idx = currentTask.istack[currentTask.istackPos];
                    if (idx < 0) {
                        idx = (cast(int) ary.data.length) + idx;
                    }
                    if (idx >= ary.data.length) {
                        raise(currentTask, "IndexError");
                        break;
                    }
                    currentTask.istackPos--;
                    currentTask.ostack[currentTask.ostackPos] = &ary.data[idx];
                    currentTask.ostackPos++;
                    currentTask.ostack[currentTask.ostackPos] = ary.data[idx];
                    currentTask.pc++;
                    break;
                case length_int:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = cast(int)(
                        (cast(GrIntArray) currentTask.ostack[currentTask.ostackPos]).data.length);
                    currentTask.ostackPos--;
                    currentTask.pc++;
                    break;
                case length_real:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = cast(int)(
                        (cast(GrRealArray) currentTask.ostack[currentTask.ostackPos]).data.length);
                    currentTask.ostackPos--;
                    currentTask.pc++;
                    break;
                case length_string:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = cast(int)(
                        (cast(GrStringArray) currentTask.ostack[currentTask.ostackPos]).data.length);
                    currentTask.ostackPos--;
                    currentTask.pc++;
                    break;
                case length_object:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = cast(int)(
                        (cast(GrObjectArray) currentTask.ostack[currentTask.ostackPos]).data.length);
                    currentTask.ostackPos--;
                    currentTask.pc++;
                    break;
                case concatenate_intArray:
                    GrIntArray nArray = new GrIntArray;
                    currentTask.ostackPos--;
                    nArray.data = (cast(GrIntArray) currentTask.ostack[currentTask.ostackPos])
                        .data ~ (cast(GrIntArray) currentTask.ostack[currentTask.ostackPos + 1])
                        .data;
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) nArray;
                    currentTask.pc++;
                    break;
                case concatenate_realArray:
                    GrRealArray nArray = new GrRealArray;
                    currentTask.ostackPos--;
                    nArray.data = (cast(GrRealArray) currentTask.ostack[currentTask.ostackPos])
                        .data ~ (cast(GrRealArray) currentTask.ostack[currentTask.ostackPos + 1])
                        .data;
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) nArray;
                    currentTask.pc++;
                    break;
                case concatenate_stringArray:
                    GrStringArray nArray = new GrStringArray;
                    currentTask.ostackPos--;
                    nArray.data = (cast(GrStringArray) currentTask.ostack[currentTask.ostackPos])
                        .data ~ (cast(GrStringArray) currentTask.ostack[currentTask.ostackPos + 1])
                        .data;
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) nArray;
                    currentTask.pc++;
                    break;
                case concatenate_objectArray:
                    GrObjectArray nArray = new GrObjectArray;
                    currentTask.ostackPos--;
                    nArray.data = (cast(GrObjectArray) currentTask.ostack[currentTask.ostackPos])
                        .data ~ (cast(GrObjectArray) currentTask.ostack[currentTask.ostackPos + 1])
                        .data;
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) nArray;
                    currentTask.pc++;
                    break;
                case append_int:
                    GrIntArray nArray = new GrIntArray;
                    nArray.data = (cast(GrIntArray) currentTask.ostack[currentTask.ostackPos])
                        .data ~ currentTask.istack[currentTask.istackPos];
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) nArray;
                    currentTask.istackPos--;
                    currentTask.pc++;
                    break;
                case append_real:
                    GrRealArray nArray = new GrRealArray;
                    nArray.data = (cast(GrRealArray) currentTask.ostack[currentTask.ostackPos])
                        .data ~ currentTask.rstack[currentTask.rstackPos];
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) nArray;
                    currentTask.rstackPos--;
                    currentTask.pc++;
                    break;
                case append_string:
                    GrStringArray nArray = new GrStringArray;
                    nArray.data = (cast(GrStringArray) currentTask.ostack[currentTask.ostackPos])
                        .data ~ currentTask.sstack[currentTask.sstackPos];
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) nArray;
                    currentTask.sstackPos--;
                    currentTask.pc++;
                    break;
                case append_object:
                    GrObjectArray nArray = new GrObjectArray;
                    currentTask.ostackPos--;
                    nArray.data = (cast(GrObjectArray) currentTask.ostack[currentTask.ostackPos])
                        .data ~ currentTask.ostack[currentTask.ostackPos + 1];
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) nArray;
                    currentTask.pc++;
                    break;
                case prepend_int:
                    GrIntArray nArray = new GrIntArray;
                    nArray.data = currentTask.istack[currentTask.istackPos] ~ (
                        cast(GrIntArray) currentTask.ostack[currentTask.ostackPos]).data;
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) nArray;
                    currentTask.istackPos--;
                    currentTask.pc++;
                    break;
                case prepend_real:
                    GrRealArray nArray = new GrRealArray;
                    nArray.data = currentTask.rstack[currentTask.rstackPos] ~ (
                        cast(GrRealArray) currentTask.ostack[currentTask.ostackPos]).data;
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) nArray;
                    currentTask.rstackPos--;
                    currentTask.pc++;
                    break;
                case prepend_string:
                    GrStringArray nArray = new GrStringArray;
                    nArray.data = currentTask.sstack[currentTask.sstackPos] ~ (
                        cast(GrStringArray) currentTask.ostack[currentTask.ostackPos]).data;
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) nArray;
                    currentTask.sstackPos--;
                    currentTask.pc++;
                    break;
                case prepend_object:
                    GrObjectArray nArray = new GrObjectArray;
                    currentTask.ostackPos--;
                    nArray.data = currentTask.ostack[currentTask.ostackPos] ~ (
                        cast(
                            GrObjectArray) currentTask.ostack[currentTask.ostackPos + 1]).data;
                    currentTask.ostack[currentTask.ostackPos] = cast(GrPtr) nArray;
                    currentTask.pc++;
                    break;
                case equal_intArray:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = (cast(
                            GrIntArray) currentTask.ostack[currentTask.ostackPos - 1])
                        .data == (cast(GrIntArray) currentTask.ostack[currentTask.ostackPos]).data;
                    currentTask.ostackPos -= 2;
                    currentTask.pc++;
                    break;
                case equal_realArray:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = (cast(
                            GrRealArray) currentTask.ostack[currentTask.ostackPos - 1])
                        .data == (cast(GrRealArray) currentTask.ostack[currentTask.ostackPos]).data;
                    currentTask.ostackPos -= 2;
                    currentTask.pc++;
                    break;
                case equal_stringArray:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = (cast(
                            GrStringArray) currentTask.ostack[currentTask.ostackPos - 1])
                        .data == (cast(GrStringArray) currentTask.ostack[currentTask.ostackPos])
                        .data;
                    currentTask.ostackPos -= 2;
                    currentTask.pc++;
                    break;
                case notEqual_intArray:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = (cast(
                            GrIntArray) currentTask.ostack[currentTask.ostackPos - 1])
                        .data != (cast(GrIntArray) currentTask.ostack[currentTask.ostackPos]).data;
                    currentTask.ostackPos -= 2;
                    currentTask.pc++;
                    break;
                case notEqual_realArray:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = (cast(
                            GrRealArray) currentTask.ostack[currentTask.ostackPos - 1])
                        .data != (cast(GrRealArray) currentTask.ostack[currentTask.ostackPos]).data;
                    currentTask.ostackPos -= 2;
                    currentTask.pc++;
                    break;
                case notEqual_stringArray:
                    currentTask.istackPos++;
                    if (currentTask.istackPos == currentTask.istack.length)
                        currentTask.istack.length *= 2;
                    currentTask.istack[currentTask.istackPos] = (cast(
                            GrStringArray) currentTask.ostack[currentTask.ostackPos - 1])
                        .data != (cast(GrStringArray) currentTask.ostack[currentTask.ostackPos])
                        .data;
                    currentTask.ostackPos -= 2;
                    currentTask.pc++;
                    break;
                case debugProfileBegin:
                    _debugProfileBegin(opcode, currentTask.pc);
                    currentTask.pc++;
                    break;
                case debugProfileEnd:
                    _debugProfileEnd();
                    currentTask.pc++;
                    break;
                }
            }
            index++;
        }
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
