/**
    Coroutines.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.runtime.context;

import grimoire.runtime.engine;
import grimoire.runtime.array;
import grimoire.runtime.object;

/**
Represents a single function context in the callStack.
*/
struct GrStackFrame {
    /// Size of the locals in the calling function.
    uint localStackSize;
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
    int istackPos,
    /// Ditto
        fstackPos,
    /// Ditto
        sstackPos,
    /// Ditto
        ostackPos;
    
    /// Callstack
    GrStackFrame stackFrame;

    /// Stack frame pointer for the current function.
    /// Each function takes 2 integer: the return pc, and the local variable size.
    uint stackPos;

    /// Local variables: Access with Xlocals[localsPos + variableIndex]
    uint localsPos;
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
        setupLocals(8);
    }

    /// Parent engine where the context is running.
    GrEngine engine;

    /// Local variables
    int[] ilocals;
    /// Ditto
    float[] flocals;
    /// Ditto
    dstring[] slocals;
    /// Ditto
    void*[] olocals;

    /// Callstack
    GrStackFrame[] callStack;

    /// Expression stack.
    int[] istack;
    /// Ditto
    float[] fstack;
    /// Ditto
    dstring[] sstack;
    /// Ditto
    void*[] ostack;

    /// Operation pointer.
    uint pc,
    /// Local variables: Access with Xlocals[localsPos + variableIndex]
        localsPos,
    /// Stack frame pointer for the current function.
    /// Each function takes 2 integer: the return pc, and the local variable size.
        stackPos;
    
    /// Current expression stack top
    int istackPos = -1,
    /// Ditto
        fstackPos = -1,
    /// Ditto
        sstackPos = -1,
    /// Ditto
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

    /// Backup to restore stack state after select evaluation.
    GrContextState[] states;

    /// Current callstack max depth.
    uint callStackLimit,
    /// Current max local variable available.
        localsLimit;

    /// Initialize the call stacks.
    void setupCallStack(uint size) {
        callStackLimit = size;
        callStack = new GrStackFrame[callStackLimit];   
    }

    /// Initialize the expression stacks.
    void setupStack(uint size) {
        istack = new int[size];
        fstack = new float[size];
        sstack = new dstring[size];
        ostack = new void*[size];
    }

    /// Initialize the local variable stacks.
    void setupLocals(uint size) {
        localsLimit = size;
        ilocals = new int[localsLimit];
        flocals = new float[localsLimit];
        slocals = new dstring[localsLimit];
        olocals = new void*[localsLimit];
    }

    /// Double the current callstack size.
    void doubleCallStackSize() {
        callStackLimit <<= 1;
        callStack.length = callStackLimit;
    }

    /// Double the current locals stacks' size.
    void doubleLocalsStackSize() {
        localsLimit <<= 1;
        ilocals.length = localsLimit;
        flocals.length = localsLimit;
        slocals.length = localsLimit;
        olocals.length = localsLimit;
    }

    alias setString = setValue!dstring;
    alias setBool = setValue!bool;
    alias setInt = setValue!int;
    alias setFloat = setValue!float;

    void setUserData(T)(T value) {
        setValue!(void*)(cast(void*)value);
    }

    private void setValue(T)(T value) {
        static if(is(T == int)) {
            istackPos ++;
			istack[istackPos] = value;
        }
        else static if(is(T == bool)) {
            istackPos ++;
            istack[istackPos] = value;
        }
        else static if(is(T == float)) {
            fstackPos ++;
            fstack[fstackPos] = value;
        }
        else static if(is(T == dstring)) {
            sstackPos ++;
            sstack[sstackPos] = value;
        }
        else static if(is(T == void*)) {
            ostackPos ++;
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
        state.localsPos = localsPos;
        states ~= state;
    }

    /// Restore the last state of the context
    void restoreState() {
        if(!states.length)
            throw new Exception("Fatal error: pop context state");
        GrContextState state = states[$ - 1];
        istackPos = state.istackPos;
        fstackPos = state.fstackPos;
        sstackPos = state.sstackPos;
        ostackPos = state.ostackPos;
        stackPos = state.stackPos;
        localsPos = state.localsPos;
        callStack[stackPos] = state.stackFrame;
    }

    /// Remove last state of the context
    void popState() {
        states.length --;
    }
}