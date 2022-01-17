/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.range;

import std.range;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

package(grimoire.stdlib) void grLoadStdLibRange(GrLibrary library, GrLocale locale) {
    string rangeIterSymbol, nextSymbol, rangeSymbol;
    final switch (locale) with (GrLocale) {
    case en_US:
        rangeIterSymbol = "IRange";
        nextSymbol = "next";
        rangeSymbol = "range";
        break;
    case fr_FR:
        rangeIterSymbol = "IIntervalle";
        nextSymbol = "suivant";
        rangeSymbol = "intervalle";
        break;
    }

    library.addForeign(rangeIterSymbol, ["T"]);
    GrType rangeIterIntType = grGetForeignType(rangeIterSymbol, [grInt]);
    GrType rangeIterFloatType = grGetForeignType(rangeIterSymbol, [grFloat]);

    library.addPrimitive(&_range_next_i, nextSymbol, [rangeIterIntType], [
            grBool, grInt
        ]);
    library.addOperator(&_range_i, GrLibrary.Operator.interval, [grInt, grInt], rangeIterIntType);
    library.addPrimitive(&_range_i, rangeSymbol, [grInt, grInt], [
            rangeIterIntType
        ]);
    library.addPrimitive(&_range_step_i, rangeSymbol, [grInt, grInt, grInt], [
            rangeIterIntType
        ]);

    library.addPrimitive(&_range_next_f, nextSymbol, [rangeIterFloatType], [
            grBool, grFloat
        ]);
    library.addOperator(&_range_f, GrLibrary.Operator.interval, [
            grFloat, grFloat
        ], rangeIterFloatType);
    library.addPrimitive(&_range_f, rangeSymbol, [grFloat, grFloat], [
            rangeIterFloatType
        ]);
    library.addPrimitive(&_range_step_f, rangeSymbol, [
            grFloat, grFloat, grFloat
        ],
        [rangeIterFloatType]);
}

private final class RangeIter(T) {
    T value, end, step;
}

private void _range_next_i(GrCall call) {
    RangeIter!GrInt iter = call.getForeign!(RangeIter!GrInt)(0);
    if (!iter) {
        call.raise(_paramError);
        return;
    }
    if ((iter.step < 0 && iter.value < iter.end) || (iter.step > 0 && iter.value > iter.end)) {
        call.setBool(false);
        call.setInt(0);
        return;
    }
    call.setBool(true);
    call.setInt(iter.value);
    iter.value += iter.step;
}

private void _range_i(GrCall call) {
    RangeIter!GrInt iter = new RangeIter!GrInt;
    iter.value = call.getInt(0);
    iter.end = call.getInt(1);
    iter.step = iter.value > iter.end ? -1 : 1;
    call.setForeign(iter);
}

private void _range_step_i(GrCall call) {
    RangeIter!GrInt iter = new RangeIter!GrInt;
    iter.value = call.getInt(0);
    iter.end = call.getInt(1);
    iter.step = call.getInt(2);
    if ((iter.value > iter.end && iter.step > 0) || (iter.value < iter.end && iter.step < 0)) {
        iter.step = -iter.step;
    }
    call.setForeign(iter);
}

private void _range_next_f(GrCall call) {
    RangeIter!GrFloat iter = call.getForeign!(RangeIter!GrFloat)(0);
    if (!iter) {
        call.raise(_paramError);
        return;
    }
    if ((iter.step < 0f && iter.value < iter.end) || (iter.step > 0f && iter.value > iter.end)) {
        call.setBool(false);
        call.setFloat(0f);
        return;
    }
    call.setBool(true);
    call.setFloat(iter.value);
    iter.value += iter.step;
}

private void _range_f(GrCall call) {
    RangeIter!GrFloat iter = new RangeIter!GrFloat;
    iter.value = call.getFloat(0);
    iter.end = call.getFloat(1);
    iter.step = iter.value > iter.end ? -1f : 1f;
    call.setForeign(iter);
}

private void _range_step_f(GrCall call) {
    RangeIter!GrFloat iter = new RangeIter!GrFloat;
    iter.value = call.getFloat(0);
    iter.end = call.getFloat(1);
    iter.step = call.getFloat(2);
    if ((iter.value > iter.end && iter.step > 0f) || (iter.value < iter.end && iter.step < 0f)) {
        iter.step = -iter.step;
    }
    call.setForeign(iter);
}
