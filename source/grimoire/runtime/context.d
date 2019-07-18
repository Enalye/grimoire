/**
    Coroutines.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.runtime.context;

import grimoire.runtime.engine;
import grimoire.runtime.variant;
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

struct GrContextState {
    int istackPos,
        fstackPos,
        sstackPos,
        vstackPos,
        ostackPos;
    GrStackFrame stackFrame;
    uint stackPos;
    uint localsPos;    
}

/**
    Coroutines are contexts that hold local data.
*/
final class GrContext {
    /// Default ctor.
    this(GrEngine e) {
        engine = e;
        setupCallStack(16);
        setupStack(32);
        setupLocals(256);
    }

    /// Parent engine where the context is running.
    GrEngine engine;

    /// Local variables
    int[] ilocals;
    float[] flocals;
    dstring[] slocals;
    GrVariantValue[] vlocals;
    void*[] olocals;

    /// Callstack
    GrStackFrame[] callStack;
    uint[][] deferStack;
    uint[][] exceptionHandlers;

    /// Expression stack.
    int[] istack;
    float[] fstack;
    dstring[] sstack;
    GrVariantValue[] vstack;
    void*[] ostack;

    /// Operation pointer.
    uint pc,
    /// Local variables: Access with Xlocals[localsPos + variableIndex]
        localsPos,
    /// Stack frame pointer for the current function.
    /// Each function takes 2 integer: the return pc, and the local variable size.
        stackPos;
    
    int istackPos = -1,
        fstackPos = -1,
        sstackPos = -1,
        vstackPos = -1,
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
    uint callStackLimit;

    /// Initialize the call stacks.
    void setupCallStack(uint size) {
        callStackLimit = size;
        callStack = new GrStackFrame[callStackLimit];   
    }

    /// Current expression stack limit.
    uint stackLimit;

    /// Initialize the expression stacks.
    void setupStack(uint size) {
        stackLimit = size;
        istack = new int[stackLimit];
        fstack = new float[stackLimit];
        sstack = new dstring[stackLimit];
        vstack = new GrVariantValue[stackLimit];
        ostack = new void*[stackLimit];
    }

    /// Current max local variable available.
    uint localsLimit;

    /// Initialize the local variable stacks.
    void setupLocals(uint size) {
        localsLimit = size;
        ilocals = new int[localsLimit];
        flocals = new float[localsLimit];
        slocals = new dstring[localsLimit];
        vlocals = new GrVariantValue[localsLimit];
        olocals = new void*[localsLimit];
    }

    /// Double the current call stacks' size.
    void doubleCallStackSize() {
        callStackLimit <<= 1;
        callStack.length = callStackLimit << 1;
        deferStack.length = callStackLimit;
        exceptionHandlers.length = callStackLimit;
    }

    alias setString = setValue!dstring;
    alias setBool = setValue!bool;
    alias setInt = setValue!int;
    alias setFloat = setValue!float;
    alias setVariant = setValue!GrVariantValue;
    alias setArray = setValue!(GrVariantValue[]);

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
        else static if(is(T == GrVariantValue)) {
            vstackPos ++;
            vstack[vstackPos] = value;
        }
        else static if(is(T == void*)) {
            ostackPos ++;
            ostack[ostackPos] = value;
        }
    }

    void pushState() {
        GrContextState state;
        state.istackPos = istackPos;
        state.fstackPos = fstackPos;
        state.sstackPos = sstackPos;
        state.vstackPos = vstackPos;
        state.ostackPos = ostackPos;
        state.stackPos = stackPos;
        state.stackFrame = callStack[stackPos];
        state.localsPos = localsPos;
        states ~= state;
    }

    void restoreState() {
        if(!states.length)
            throw new Exception("Fatal error: pop context state");
        GrContextState state = states[$ - 1];
        istackPos = state.istackPos;
        fstackPos = state.fstackPos;
        sstackPos = state.sstackPos;
        vstackPos = state.vstackPos;
        ostackPos = state.ostackPos;
        stackPos = state.stackPos;
        localsPos = state.localsPos;
        callStack[stackPos] = state.stackFrame;
    }

    void popState() {
        states.length --;
    }
}