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
    GrVariantValue[][] nlocals;
    GrVariantValue[] vlocals;
    void*[] olocals;

    /// Callstack
    uint[] callStack;
    uint[][] deferStack;
    uint[][] exceptionHandlers;

    /// Expression stack.
    int[] istack;
    float[] fstack;
    dstring[] sstack;
    GrVariantValue[][] nstack;
    GrVariantValue[] vstack;
    void*[] ostack;

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
        vstackPos = -1,
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
        callStack = new uint[callStackLimit << 1];
        deferStack = new uint[][callStackLimit];
        exceptionHandlers = new uint[][callStackLimit];
    }

    /// Current expression stack limit.
    uint stackLimit;

    /// Initialize the expression stacks.
    void setupStack(uint size) {
        stackLimit = size;
        istack = new int[stackLimit];
        fstack = new float[stackLimit];
        sstack = new dstring[stackLimit];
        nstack = new GrVariantValue[][stackLimit];
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
        nlocals = new GrVariantValue[][localsLimit];
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
        else static if(is(T == GrVariantValue[])) {
            nstackPos ++;            
            nstack[nstackPos] = value;
        }
        else static if(is(T == void*)) {
            ostackPos ++;
            ostack[ostackPos] = value;
        }
    }
}