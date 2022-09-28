/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.range;

import std.range;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

package(grimoire.stdlib) void grLoadStdLibRange(GrLibrary library) {
    library.addForeign("RangeIterator", ["T"]);
    GrType rangeIteratorIntType = grGetForeignType("RangeIterator", [grInt]);
    GrType rangeIteratorRealType = grGetForeignType("RangeIterator", [grReal]);

    library.addFunction(&_range_next_i, "next", [rangeIteratorIntType], [
            grOptional(grInt),
        ]);
    library.addOperator(&_range_i, GrLibrary.Operator.interval, [grInt,
            grInt], rangeIteratorIntType);
    library.addFunction(&_range_i, "range", [grInt, grInt], [
            rangeIteratorIntType
        ]);
    library.addFunction(&_range_step_i, "range", [grInt, grInt, grInt], [
            rangeIteratorIntType
        ]);

    library.addFunction(&_range_next_r, "next", [rangeIteratorRealType], [
            grOptional(grReal)
        ]);
    library.addOperator(&_range_r, GrLibrary.Operator.interval, [grReal,
            grReal], rangeIteratorRealType);
    library.addFunction(&_range_r, "range", [grReal, grReal], [
            rangeIteratorRealType
        ]);
    library.addFunction(&_range_step_r, "range", [grReal, grReal, grReal],
        [rangeIteratorRealType]);
}

private final class RangeIterator(T) {
    T value, end, step;
}

private void _range_next_i(GrCall call) {
    RangeIterator!GrInt iter = call.getForeign!(RangeIterator!GrInt)(0);
    if (!iter) {
        call.raise("NullError");
        return;
    }
    if ((iter.step < 0 && iter.value < iter.end) || (iter.step > 0 && iter.value > iter.end)) {
        call.setNull();
        return;
    }
    call.setInt(iter.value);
    iter.value += iter.step;
}

private void _range_i(GrCall call) {
    RangeIterator!GrInt iter = new RangeIterator!GrInt;
    iter.value = call.getInt(0);
    iter.end = call.getInt(1);
    iter.step = iter.value > iter.end ? -1 : 1;
    call.setForeign(iter);
}

private void _range_step_i(GrCall call) {
    RangeIterator!GrInt iter = new RangeIterator!GrInt;
    iter.value = call.getInt(0);
    iter.end = call.getInt(1);
    iter.step = call.getInt(2);
    if ((iter.value > iter.end && iter.step > 0) || (iter.value < iter.end && iter.step < 0)) {
        iter.step = -iter.step;
    }
    call.setForeign(iter);
}

private void _range_next_r(GrCall call) {
    RangeIterator!GrReal iter = call.getForeign!(RangeIterator!GrReal)(0);
    if (!iter) {
        call.raise("NullError");
        return;
    }
    if ((iter.step < 0f && iter.value < iter.end) || (iter.step > 0f && iter.value > iter.end)) {
        call.setNull();
        return;
    }
    call.setReal(iter.value);
    iter.value += iter.step;
}

private void _range_r(GrCall call) {
    RangeIterator!GrReal iter = new RangeIterator!GrReal;
    iter.value = call.getReal(0);
    iter.end = call.getReal(1);
    iter.step = iter.value > iter.end ? -1f : 1f;
    call.setForeign(iter);
}

private void _range_step_r(GrCall call) {
    RangeIterator!GrReal iter = new RangeIterator!GrReal;
    iter.value = call.getReal(0);
    iter.end = call.getReal(1);
    iter.step = call.getReal(2);
    if ((iter.value > iter.end && iter.step > 0f) || (iter.value < iter.end && iter.step < 0f)) {
        iter.step = -iter.step;
    }
    call.setForeign(iter);
}
