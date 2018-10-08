/**
    Coroutines.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module runtime.context;

import runtime.engine;
import runtime.dynamic;
import runtime.array;

/**
    Coroutines are contexts that hold local data.
*/
class GrContext {
    /// Default ctor.
    this(GrEngine e) {
        engine = e;
        istack = (new int[128]).ptr;
        setupCallStack(16);
        setupStack(32);
        setupLocals(256);
    }

    /// Parent engine where the context is running.
    GrEngine engine;

    /// Local variables
    int* ilocals;
    float* flocals;
    dstring* slocals;
    GrDynamicValue[]* nlocals;
    GrDynamicValue* alocals;
    void** olocals;

    /// Callstack
    uint* callStack;
    uint[]* deferStack;
    uint[]* exceptionHandlers;

    /// Expression stack.
    int* istack;
    float* fstack;
    dstring* sstack;
    GrDynamicValue[]* nstack;
    GrDynamicValue* astack;
    void** ostack;

    /// Operation pointer.
    uint pc,
    /// Local variables: Access with Xlocals[localsPos + variableIndex]
        localsPos,
    /// Stack frame pointer for the current function.
    /// Each function takes 2 integer: the return pc, and the local variable size.
        stackPos,
    /// Current deferrable block.
        deferPos,
    /// Current block wich can contain exception handlers.
        exceptionHandlersPos;
    
    int istackPos = -1,
        fstackPos = -1,
        sstackPos = -1,
        nstackPos = -1,
        astackPos = -1,
        ostackPos = -1;

    /// Kill state, unwind the call stack and call all registered deferred statements.
    bool isKilled;

    /// An exception has been raised an is not caught.
    bool isPanicking;

    /// Current callstack max depth.
    uint callStackLimit;

    /// Initialize the call stacks.
    void setupCallStack(uint size) {
        callStackLimit = size;
        callStack = (new uint[callStackLimit << 1]).ptr;
        deferStack = (new uint[][callStackLimit]).ptr;
        exceptionHandlers = (new uint[][callStackLimit]).ptr;
    }

    /// Current expression stack limit.
    uint stackLimit;

    /// Initialize the expression stacks.
    void setupStack(uint size) {
        stackLimit = size;
        istack = (new int[stackLimit]).ptr;
        fstack = (new float[stackLimit]).ptr;
        sstack = (new dstring[stackLimit]).ptr;
        nstack = (new GrDynamicValue[][stackLimit]).ptr;
        astack = (new GrDynamicValue[stackLimit]).ptr;
        ostack = (new void*[stackLimit]).ptr;
    }

    /// Current max local variable available.
    uint localsLimit;

    /// Initialize the local variable stacks.
    void setupLocals(uint size) {
        localsLimit = size;
        ilocals = (new int[localsLimit]).ptr;
        flocals = (new float[localsLimit]).ptr;
        slocals = (new dstring[localsLimit]).ptr;
        nlocals = (new GrDynamicValue[][localsLimit]).ptr;
        alocals = (new GrDynamicValue[localsLimit]).ptr;
        olocals = (new void*[localsLimit]).ptr;
    }

    /// Double the current call stacks' size.
    void doubleCallStackSize() {
        const auto oldLimit = callStackLimit;
        callStackLimit <<= 1;
        auto newCallStack = (new uint[callStackLimit << 1]).ptr;
        auto newDeferStack = (new uint[][callStackLimit]).ptr;
        auto newExceptionHandlers = (new uint[][callStackLimit]).ptr;

        newCallStack[0.. callStackLimit << 1] = callStack[0.. callStackLimit << 1];
        newDeferStack[0.. callStackLimit] = deferStack[0.. callStackLimit];
        newExceptionHandlers[0.. callStackLimit] = exceptionHandlers[0.. callStackLimit];
        
        callStack = newCallStack;
        deferStack = newDeferStack;
        exceptionHandlers = newExceptionHandlers;
    }
}