/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.library.range;

import std.range;
import grimoire;

void grLoadStdLibRange(GrModule library) {
    library.setModule("range");

    library.setModuleInfo(GrLocale.fr_FR, "Fonctions pour itérer sur des séries de nombres.");
    library.setModuleInfo(GrLocale.en_US, "Functions to iterate on series of numbers.");

    library.setDescription(GrLocale.fr_FR, "Itère sur une série de nombres.");
    library.setDescription(GrLocale.en_US, "Iterate on a serie of numbers.");
    library.addNative("RangeIterator", ["T"]);
    GrType rangeIteratorIntType = grGetNativeType("RangeIterator", [grInt]);
    GrType rangeIteratorFloatType = grGetNativeType("RangeIterator", [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Avance jusqu’au nombre suivant de la série.");
    library.setDescription(GrLocale.en_US, "Advance until the next number in the serie.");
    library.setParameters(["iterator"]);
    library.addFunction(&_range_next_i, "next", [rangeIteratorIntType], [
            grOptional(grInt),
        ]);
    library.addOperator(&_range_i, GrModule.Operator.interval, [
            grInt, grInt
        ], rangeIteratorIntType);

    library.setDescription(GrLocale.fr_FR,
        "Retourne un itérateur qui part de `start` jusqu’à `end` inclus.");
    library.setDescription(GrLocale.en_US,
        "Returns an iterator that start from `start` and end with `end` included.");
    library.setParameters(["start", "end"]);
    library.addFunction(&_range_i, "range", [grInt, grInt], [
            rangeIteratorIntType
        ]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne un itérateur qui part de `start` jusqu’à `end` inclus par pas de `step`.");
    library.setDescription(GrLocale.en_US,
        "Returns an iterator that start from `start` and end with `end` included by increments of `step`.");
    library.setParameters(["start", "end", "step"]);
    library.addFunction(&_range_step_i, "range", [grInt, grInt, grInt], [
            rangeIteratorIntType
        ]);

    library.setDescription(GrLocale.fr_FR, "Avance jusqu’au nombre suivant de la série.");
    library.setDescription(GrLocale.en_US, "Advance until the next number in the serie.");
    library.setParameters(["iterator"]);
    library.addFunction(&_range_next_r, "next", [rangeIteratorFloatType], [
            grOptional(grFloat)
        ]);
    library.addOperator(&_range_r, GrModule.Operator.interval,
        [grFloat, grFloat], rangeIteratorFloatType);

    library.setDescription(GrLocale.fr_FR,
        "Retourne un itérateur qui part de `start` jusqu’à `end` inclus.");
    library.setDescription(GrLocale.en_US,
        "Returns an iterator that start from `start` and end with `end` included.");
    library.setParameters(["start", "end"]);
    library.addFunction(&_range_r, "range", [grFloat, grFloat], [
            rangeIteratorFloatType
        ]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne un itérateur qui part de `start` jusqu’à `end` inclus par pas de `step`.");
    library.setDescription(GrLocale.en_US,
        "Returns an iterator that start from `start` and end with `end` included by increments of `step`.");
    library.setParameters(["start", "end", "step"]);
    library.addFunction(&_range_step_r, "range", [grFloat, grFloat, grFloat],
        [rangeIteratorFloatType]);
}

private final class RangeIterator(T) {
    T value, end, step;
}

private void _range_next_i(GrCall call) {
    RangeIterator!GrInt iter = call.getNative!(RangeIterator!GrInt)(0);

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

    call.setNative(iter);
}

private void _range_step_i(GrCall call) {
    RangeIterator!GrInt iter = new RangeIterator!GrInt;
    iter.value = call.getInt(0);
    iter.end = call.getInt(1);
    iter.step = call.getInt(2);

    if ((iter.value > iter.end && iter.step > 0) || (iter.value < iter.end && iter.step < 0)) {
        iter.step = -iter.step;
    }

    call.setNative(iter);
}

private void _range_next_r(GrCall call) {
    RangeIterator!GrFloat iter = call.getNative!(RangeIterator!GrFloat)(0);

    if ((iter.step < 0f && iter.value < iter.end) || (iter.step > 0f && iter.value > iter.end)) {
        call.setNull();
        return;
    }

    call.setFloat(iter.value);
    iter.value += iter.step;
}

private void _range_r(GrCall call) {
    RangeIterator!GrFloat iter = new RangeIterator!GrFloat;
    iter.value = call.getFloat(0);
    iter.end = call.getFloat(1);
    iter.step = iter.value > iter.end ? -1f : 1f;

    call.setNative(iter);
}

private void _range_step_r(GrCall call) {
    RangeIterator!GrFloat iter = new RangeIterator!GrFloat;
    iter.value = call.getFloat(0);
    iter.end = call.getFloat(1);
    iter.step = call.getFloat(2);

    if ((iter.value > iter.end && iter.step > 0f) || (iter.value < iter.end && iter.step < 0f)) {
        iter.step = -iter.step;
    }

    call.setNative(iter);
}
