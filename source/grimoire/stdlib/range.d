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
    GrType rangeIterRealType = grGetForeignType(rangeIterSymbol, [grReal]);

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

    library.addPrimitive(&_range_next_f, nextSymbol, [rangeIterRealType], [
            grBool, grReal
        ]);
    library.addOperator(&_range_f, GrLibrary.Operator.interval, [
            grReal, grReal
        ], rangeIterRealType);
    library.addPrimitive(&_range_f, rangeSymbol, [grReal, grReal], [
            rangeIterRealType
        ]);
    library.addPrimitive(&_range_step_f, rangeSymbol, [
            grReal, grReal, grReal
        ],
        [rangeIterRealType]);
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
    RangeIter!GrReal iter = call.getForeign!(RangeIter!GrReal)(0);
    if (!iter) {
        call.raise(_paramError);
        return;
    }
    if ((iter.step < 0f && iter.value < iter.end) || (iter.step > 0f && iter.value > iter.end)) {
        call.setBool(false);
        call.setReal(0f);
        return;
    }
    call.setBool(true);
    call.setReal(iter.value);
    iter.value += iter.step;
}

private void _range_f(GrCall call) {
    RangeIter!GrReal iter = new RangeIter!GrReal;
    iter.value = call.getReal(0);
    iter.end = call.getReal(1);
    iter.step = iter.value > iter.end ? -1f : 1f;
    call.setForeign(iter);
}

private void _range_step_f(GrCall call) {
    RangeIter!GrReal iter = new RangeIter!GrReal;
    iter.value = call.getReal(0);
    iter.end = call.getReal(1);
    iter.step = call.getReal(2);
    if ((iter.value > iter.end && iter.step > 0f) || (iter.value < iter.end && iter.step < 0f)) {
        iter.step = -iter.step;
    }
    call.setForeign(iter);
}
