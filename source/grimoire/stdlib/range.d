/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.range;

import std.range;
import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibRange(GrLibrary library) {
    library.addForeign("RangeIter", ["T"]);
    GrType rangeIterIntType = grGetForeignType("RangeIter", [grInt]);
    GrType rangeIterFloatType = grGetForeignType("RangeIter", [grFloat]);

    library.addPrimitive(&_range_next_i, "next", [rangeIterIntType], [
            grBool, grInt
            ]);
    library.addPrimitive(&_range_i, "range", [grInt, grInt], [rangeIterIntType]);
    library.addPrimitive(&_range_step_i, "range", [grInt, grInt, grInt], [
            rangeIterIntType
            ]);

    library.addPrimitive(&_range_next_f, "next", [rangeIterFloatType], [
            grBool, grFloat
            ]);
    library.addPrimitive(&_range_f, "range", [grFloat, grFloat], [
            rangeIterFloatType
            ]);
    library.addPrimitive(&_range_step_f, "range", [grFloat, grFloat, grFloat],
            [rangeIterFloatType]);
}

private final class RangeIter(T) {
    T value, end, step;
}

private void _range_next_i(GrCall call) {
    RangeIter!int iter = call.getForeign!(RangeIter!int)(0);
    if (!iter) {
        call.raise("NullError");
        return;
    }
    if ((iter.step < 0 && iter.value < iter.end) || (iter.step > 0 && iter.value > iter.end)) {
        call.setBool(false);
        call.setInt(iter.value);
        return;
    }
    call.setBool(true);
    call.setInt(iter.value);
    iter.value += iter.step;
}

private void _range_i(GrCall call) {
    RangeIter!int iter = new RangeIter!int;
    iter.value = call.getInt(0);
    iter.end = call.getInt(1);
    iter.step = iter.value > iter.end ? -1 : 1;
    call.setForeign(iter);
}

private void _range_step_i(GrCall call) {
    RangeIter!int iter = new RangeIter!int;
    iter.value = call.getInt(0);
    iter.end = call.getInt(1);
    iter.step = call.getInt(2);
    if ((iter.value > iter.end && iter.step > 0) || (iter.value < iter.end && iter.step < 0)) {
        iter.step = -iter.step;
    }
    call.setForeign(iter);
}

private void _range_next_f(GrCall call) {
    RangeIter!float iter = call.getForeign!(RangeIter!float)(0);
    if (!iter) {
        call.raise("NullError");
        return;
    }
    if ((iter.step < 0f && iter.value < iter.end) || (iter.step > 0f && iter.value > iter.end)) {
        call.setBool(false);
        call.setFloat(iter.value);
        return;
    }
    call.setBool(true);
    call.setFloat(iter.value);
    iter.value += iter.step;
}

private void _range_f(GrCall call) {
    RangeIter!float iter = new RangeIter!float;
    iter.value = call.getFloat(0);
    iter.end = call.getFloat(1);
    iter.step = iter.value > iter.end ? -1f : 1f;
    call.setForeign(iter);
}

private void _range_step_f(GrCall call) {
    RangeIter!float iter = new RangeIter!float;
    iter.value = call.getFloat(0);
    iter.end = call.getFloat(1);
    iter.step = call.getInt(2);
    if ((iter.value > iter.end && iter.step > 0f) || (iter.value < iter.end && iter.step < 0f)) {
        iter.step = -iter.step;
    }
    call.setForeign(iter);
}
