/**
    Coroutines.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module runtime.coroutine;

import runtime.vm;
import runtime.dynamic;
import runtime.array;

/**
    Coroutines are contexts that hold local data.
*/
class GrCoroutine {
    this(GrVM parentVm) { vm = parentVm; }

    GrVM vm;

    //Local variables
    int[] ivalues;
    float[] fvalues;
    dstring[] svalues;
    GrDynamicValue[][] nvalues;
    GrDynamicValue[] avalues;
    void*[] ovalues;

    //Stack
    uint[64] callStack;
    uint[][] deferStack;
    uint[][] exceptionHandlers;
    int[] istack;
    float[] fstack;
    dstring[] sstack;
    GrDynamicValue[][] nstack;
    GrDynamicValue[] astack;
    void*[] ostack;

    uint pc,
        valuesPos, //Local variables: Access with ivalues[valuesPos + variableIndex]
        stackPos,
        deferPos;

    /// Kill state, unwind the call stack and call all registered deferred statements.
    bool isKilled;

    /// An exception has been raised an is not caught.
    bool isPanicking;
    /// Error object.
    //dstring error;
}