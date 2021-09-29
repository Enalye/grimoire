/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.context;

import grimoire.assembly;
import grimoire.runtime.engine;
import grimoire.runtime.array;
import grimoire.runtime.object;

/**
Represents a single function context in the callStack.
*/
struct GrStackFrame {
    /// Size of the locals in the calling function.
    uint ilocalStackSize, flocalStackSize, slocalStackSize, olocalStackSize;
    /// PC to jumps back to.
    uint retPosition;
    /// All current function deferred blocks.
    uint[] deferStack;
    /// All current function exception handling blocks.
    uint[] exceptionHandlers;
}

/**
Snapshot of the context's state. \
Used when we need to restore the context to a previous state.
*/
struct GrContextState {
    /// Current expression stack top
    int istackPos, /// Ditto
        fstackPos, /// Ditto
        sstackPos, /// Ditto
        ostackPos;

    /// Callstack
    GrStackFrame stackFrame;

    /// Stack frame pointer for the current function.
    /// Each function takes 2 integer: the return pc, and the local variable size.
    uint stackPos;

    /// Local variables: Access with Xlocals[XlocalsPos + variableIndex]
    uint ilocalsPos, flocalsPos, slocalsPos, olocalsPos;
}

/**
Pause the associated context.
*/
abstract class GrBlocker {
    /// Update the state, returns true if the context is still paused.
    bool run();
}

/**
Coroutines are contexts that hold local data.
*/
final class GrContext {
    /// Default ctor.
    this(GrEngine engine_) {
        engine = engine_;
        setupCallStack(4);
        setupStack(8);
        setupLocals(2, 2, 2, 2);
    }

    /// Parent engine where the context is running.
    GrEngine engine;

    /// Local variables
    GrInt[] ilocals;
    /// Ditto
    GrFloat[] flocals;
    /// Ditto
    string[] slocals;
    /// Ditto
    void*[] olocals;

    /// Callstack
    GrStackFrame[] callStack;

    /// Expression stack.
    GrInt[] istack;
    /// Ditto
    GrFloat[] fstack;
    /// Ditto
    string[] sstack;
    /// Ditto
    void*[] ostack;

    /// Operation pointer.
    uint pc;
    /// Local variables: Access with Xlocals[XlocalsPos + variableIndex]
    uint ilocalsPos, flocalsPos, slocalsPos, olocalsPos;
    /// Stack frame pointer for the current function.
    /// Each function takes 2 integer: the return pc, and the local variable size.
    uint stackPos;

    /// Current expression stack top
    int istackPos = -1, /// Ditto
        fstackPos = -1, /// Ditto
        sstackPos = -1, /// Ditto
        ostackPos = -1;

    /// Kill state, unwind the call stack and call all registered deferred statements.
    bool isKilled;

    /// An exception has been raised an is not caught.
    bool isPanicking;

    /// Set when the context is in a select/case statement.
    /// Then, the context is not stopped by a blocking channel.
    bool isEvaluatingChannel;

    /// Set when the context is forced to yield by a blocking channel.
    /// Release only when the channel is ready.
    bool isLocked;

    /// When evaluating, a blocking jump to this position will occur instead of blocking.
    uint selectPositionJump;

    /// The context will block until the blocker is cleared.
    GrBlocker blocker;

    /// Backup to restore stack state after select evaluation.
    GrContextState[] states;

    /// Current callstack max depth.
    uint callStackLimit;
    /// Current max local variable available.
    uint ilocalsLimit, flocalsLimit, slocalsLimit, olocalsLimit;

    /// Initialize the call stacks.
    void setupCallStack(uint size) {
        callStackLimit = size;
        callStack = new GrStackFrame[callStackLimit];
    }

    /// Initialize the expression stacks.
    void setupStack(uint size) {
        istack = new GrInt[size];
        fstack = new GrFloat[size];
        sstack = new string[size];
        ostack = new void*[size];
    }

    /// Initialize the local variable stacks.
    void setupLocals(uint isize, uint fsize, uint ssize, uint osize) {
        ilocalsLimit = isize;
        flocalsLimit = fsize;
        slocalsLimit = ssize;
        olocalsLimit = osize;
        ilocals = new GrInt[ilocalsLimit];
        flocals = new GrFloat[flocalsLimit];
        slocals = new string[slocalsLimit];
        olocals = new void*[olocalsLimit];
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

    /// Double the current float locals stacks' size.
    void doubleFloatLocalsStackSize(uint localsStackSize) {
        while (localsStackSize >= flocalsLimit)
            flocalsLimit <<= 1;
        flocals.length = flocalsLimit;
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

    alias setBool = setValue!bool;
    alias setInt = setValue!GrInt;
    alias setFloat = setValue!GrFloat;
    alias setString = setValue!string;
    alias setObject = setUserData!GrObject;
    alias setIntArray = setUserData!GrIntArray;
    alias setFloatArray = setUserData!GrFloatArray;
    alias setStringArray = setUserData!GrStringArray;
    alias setObjectArray = setUserData!GrObjectArray;

    void setUserData(T)(T value) {
        setValue!(void*)(cast(void*) value);
    }

    private void setValue(T)(T value) {
        static if (is(T == GrInt)) {
            istackPos++;
            istack[istackPos] = value;
        }
        else static if (is(T == bool)) {
            istackPos++;
            istack[istackPos] = value;
        }
        else static if (is(T == GrFloat)) {
            fstackPos++;
            fstack[fstackPos] = value;
        }
        else static if (is(T == string)) {
            sstackPos++;
            sstack[sstackPos] = value;
        }
        else static if (is(T == void*)) {
            ostackPos++;
            ostack[ostackPos] = value;
        }
    }

    /// Register the current state of the context
    void pushState() {
        GrContextState state;
        state.istackPos = istackPos;
        state.fstackPos = fstackPos;
        state.sstackPos = sstackPos;
        state.ostackPos = ostackPos;
        state.stackPos = stackPos;
        state.stackFrame = callStack[stackPos];
        state.ilocalsPos = ilocalsPos;
        state.flocalsPos = flocalsPos;
        state.slocalsPos = slocalsPos;
        state.olocalsPos = olocalsPos;
        states ~= state;
    }

    /// Restore the last state of the context
    void restoreState() {
        if (!states.length)
            throw new Exception("Fatal error: pop context state");
        GrContextState state = states[$ - 1];
        istackPos = state.istackPos;
        fstackPos = state.fstackPos;
        sstackPos = state.sstackPos;
        ostackPos = state.ostackPos;
        stackPos = state.stackPos;
        ilocalsPos = state.ilocalsPos;
        flocalsPos = state.flocalsPos;
        slocalsPos = state.slocalsPos;
        olocalsPos = state.olocalsPos;
        callStack[stackPos] = state.stackFrame;
    }

    /// Remove last state of the context
    void popState() {
        states.length--;
    }

    /// Lock the context until the blocker is cleared
    void block(GrBlocker blocker_) {
        blocker = blocker_;
    }

    /// Unlock the context from the blocker
    void unblock() {
        blocker = null;
    }

    /// Dump stacks info
    string dump() {
        import std.conv : to;

        string result = "Context Dump:";
        result ~= "\nfstack: " ~ to!string(fstack[0 .. (fstackPos + 1)]);
        result ~= "\nistack: " ~ to!string(istack[0 .. (istackPos + 1)]);
        result ~= "\nsstack: " ~ to!string(sstack[0 .. (sstackPos + 1)]);
        result ~= "\nostack: " ~ to!string(ostack[0 .. (ostackPos + 1)]);
        return result;
    }
}
