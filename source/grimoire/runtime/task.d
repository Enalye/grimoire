/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.task;

import grimoire.assembly;
import grimoire.runtime.engine, grimoire.runtime.array,
grimoire.runtime.channel, grimoire.runtime.object;

/**
Represents a single function task in the callStack.
*/
struct GrStackFrame {
    /// Size of the locals in the calling function.
    uint ilocalStackSize, rlocalStackSize, slocalStackSize, olocalStackSize;
    /// PC to jumps back to.
    uint retPosition;
    /// All current function deferred blocks.
    uint[] deferStack;
    /// All current function exception handling blocks.
    uint[] exceptionHandlers;
}

/**
Snapshot of the task's state. \
Used when we need to restore the task to a previous state.
*/
struct GrTaskState {
    /// Current expression stack top
    int istackPos, /// Ditto
        rstackPos, /// Ditto
        sstackPos, /// Ditto
        ostackPos;

    /// Callstack
    GrStackFrame stackFrame;

    /// Stack frame pointer for the current function.
    /// Each function takes 2 integer: the return pc, and the local variable size.
    uint stackPos;

    /// Local variables: Access with Xlocals[XlocalsPos + variableIndex]
    uint ilocalsPos, rlocalsPos, slocalsPos, olocalsPos;
}

/**
Pause the associated task.
*/
abstract class GrBlocker {
    /// Update the state, returns true if the task is still paused.
    bool run();
}

/**
Coroutines are tasks that hold local data.
*/
final class GrTask {
    /// Default ctor.
    this(GrEngine engine_) {
        engine = engine_;
        setupCallStack(4);
        setupStack(8);
        setupLocals(2, 2, 2, 2);
    }

    /// Parent engine where the task is running.
    GrEngine engine;

    /// Local variables
    GrInt[] ilocals;
    /// Ditto
    GrReal[] rlocals;
    /// Ditto
    GrString[] slocals;
    /// Ditto
    GrPtr[] olocals;

    /// Callstack
    GrStackFrame[] callStack;

    /// Expression stack.
    GrInt[] istack;
    /// Ditto
    GrReal[] rstack;
    /// Ditto
    GrString[] sstack;
    /// Ditto
    GrPtr[] ostack;

    /// Operation pointer.
    uint pc;
    /// Local variables: Access with Xlocals[XlocalsPos + variableIndex]
    uint ilocalsPos, rlocalsPos, slocalsPos, olocalsPos;
    /// Stack frame pointer for the current function.
    /// Each function takes 2 integer: the return pc, and the local variable size.
    uint stackPos;

    /// Current expression stack top
    int istackPos = -1, /// Ditto
        rstackPos = -1, /// Ditto
        sstackPos = -1, /// Ditto
        ostackPos = -1;

    /// Kill state, unwind the call stack and call all registered deferred statements.
    bool isKilled;

    /// An exception has been raised an is not caught.
    bool isPanicking;

    /// Set when the task is in a select/case statement.
    /// Then, the task is not stopped by a blocking channel.
    bool isEvaluatingChannel;

    /// Set when the task is forced to yield by a blocking channel.
    /// Release only when the channel is ready.
    bool isLocked;

    /// When evaluating, a blocking jump to this position will occur instead of blocking.
    uint selectPositionJump;

    /// The task will block until the blocker is cleared.
    GrBlocker blocker;

    /// Backup to restore stack state after select evaluation.
    GrTaskState[] states;

    /// Current callstack max depth.
    uint callStackLimit;
    /// Current max local variable available.
    uint ilocalsLimit, rlocalsLimit, slocalsLimit, olocalsLimit;

    /// Initialize the call stacks.
    void setupCallStack(uint size) {
        callStackLimit = size;
        callStack = new GrStackFrame[callStackLimit];
    }

    /// Initialize the expression stacks.
    void setupStack(uint size) {
        istack = new GrInt[size];
        rstack = new GrReal[size];
        sstack = new GrString[size];
        ostack = new GrPtr[size];
    }

    /// Initialize the local variable stacks.
    void setupLocals(uint isize, uint fsize, uint ssize, uint osize) {
        ilocalsLimit = isize;
        rlocalsLimit = fsize;
        slocalsLimit = ssize;
        olocalsLimit = osize;
        ilocals = new GrInt[ilocalsLimit];
        rlocals = new GrReal[rlocalsLimit];
        slocals = new GrString[slocalsLimit];
        olocals = new GrPtr[olocalsLimit];
    }

    /// Double the current callstack size.
    void doubleCallStackSize() {
        callStackLimit <<= 1;
        callStack.length = callStackLimit;
    }

    /// Double the current integer locals stacks' size.
    void doubleIntLocalsStackSize(uint localsStackSize) {
        while (localsStackSize >= ilocalsLimit)
            ilocalsLimit <<= 1;
        ilocals.length = ilocalsLimit;
    }

    /// Double the current real locals stacks' size.
    void doubleRealLocalsStackSize(uint localsStackSize) {
        while (localsStackSize >= rlocalsLimit)
            rlocalsLimit <<= 1;
        rlocals.length = rlocalsLimit;
    }

    /// Double the current string locals stacks' size.
    void doubleStringLocalsStackSize(uint localsStackSize) {
        while (localsStackSize >= slocalsLimit)
            slocalsLimit <<= 1;
        slocals.length = slocalsLimit;
    }

    /// Double the current object locals stacks' size.
    void doubleObjectLocalsStackSize(uint localsStackSize) {
        while (localsStackSize >= olocalsLimit)
            olocalsLimit <<= 1;
        olocals.length = olocalsLimit;
    }

    alias setBool = setValue!GrBool;
    alias setInt = setValue!GrInt;
    alias setReal = setValue!GrReal;
    alias setString = setValue!GrString;
    alias setPtr = setValue!GrPtr;

    void setInt32(int value) {
        setValue!GrInt(cast(GrInt) value);
    }

    void setInt64(long value) {
        setValue!GrInt(cast(GrInt) value);
    }

    void setReal32(real value) {
        setValue!GrReal(cast(GrReal) value);
    }

    void setReal64(double value) {
        setValue!GrReal(cast(GrReal) value);
    }

    void setObject(GrObject value) {
        setValue!GrPtr(cast(GrPtr) value);
    }

    void setArray(T)(GrArray!T value) {
        setValue!GrPtr(cast(GrPtr) value);
    }

    void setIntArray(GrIntArray value) {
        setValue!GrPtr(cast(GrPtr) value);
    }

    void setRealArray(GrRealArray value) {
        setValue!GrPtr(cast(GrPtr) value);
    }

    void setStringArray(GrStringArray value) {
        setValue!GrPtr(cast(GrPtr) value);
    }

    void setObjectArray(GrObjectArray value) {
        setValue!GrPtr(cast(GrPtr) value);
    }

    void setIntChannel(GrIntChannel value) {
        setValue!GrPtr(cast(GrPtr) value);
    }

    void setRealChannel(GrRealChannel value) {
        setValue!GrPtr(cast(GrPtr) value);
    }

    void setStringChannel(GrStringChannel value) {
        setValue!GrPtr(cast(GrPtr) value);
    }

    void setObjectChannel(GrObjectChannel value) {
        setValue!GrPtr(cast(GrPtr) value);
    }

    void setEnum(T)(T value) {
        setValue!GrInt(cast(GrInt) value);
    }

    void setForeign(T)(T value) {
        setValue!GrPtr(cast(GrPtr) value);
    }

    private void setValue(T)(T value) {
        static if (is(T == GrInt)) {
            istackPos++;
            istack[istackPos] = value;
        }
        else static if (is(T == GrBool)) {
            istackPos++;
            istack[istackPos] = value;
        }
        else static if (is(T == GrReal)) {
            rstackPos++;
            rstack[rstackPos] = value;
        }
        else static if (is(T == GrString)) {
            sstackPos++;
            sstack[sstackPos] = value;
        }
        else static if (is(T == GrPtr)) {
            ostackPos++;
            ostack[ostackPos] = value;
        }
    }

    /// Register the current state of the task
    void pushState() {
        GrTaskState state;
        state.istackPos = istackPos;
        state.rstackPos = rstackPos;
        state.sstackPos = sstackPos;
        state.ostackPos = ostackPos;
        state.stackPos = stackPos;
        state.stackFrame = callStack[stackPos];
        state.ilocalsPos = ilocalsPos;
        state.rlocalsPos = rlocalsPos;
        state.slocalsPos = slocalsPos;
        state.olocalsPos = olocalsPos;
        states ~= state;
    }

    /// Restore the last state of the task
    void restoreState() {
        if (!states.length)
            throw new Exception("Fatal error: pop task state");
        GrTaskState state = states[$ - 1];
        istackPos = state.istackPos;
        rstackPos = state.rstackPos;
        sstackPos = state.sstackPos;
        ostackPos = state.ostackPos;
        stackPos = state.stackPos;
        ilocalsPos = state.ilocalsPos;
        rlocalsPos = state.rlocalsPos;
        slocalsPos = state.slocalsPos;
        olocalsPos = state.olocalsPos;
        callStack[stackPos] = state.stackFrame;
    }

    /// Remove last state of the task
    void popState() {
        states.length--;
    }

    /// Lock the task until the blocker is cleared
    void block(GrBlocker blocker_) {
        blocker = blocker_;
    }

    /// Unlock the task from the blocker
    void unblock() {
        blocker = null;
    }

    /// Dump stacks info
    string dump() {
        import std.conv : to;

        string result = "Task Dump:";
        result ~= "\nfstack: " ~ to!string(rstack[0 .. (rstackPos + 1)]);
        result ~= "\nistack: " ~ to!string(istack[0 .. (istackPos + 1)]);
        result ~= "\nsstack: " ~ to!string(sstack[0 .. (sstackPos + 1)]);
        result ~= "\nostack: " ~ to!string(ostack[0 .. (ostackPos + 1)]);
        return result;
    }
}
