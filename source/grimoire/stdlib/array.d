/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.array;

import std.range;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

package(grimoire.stdlib) void grLoadStdLibArray(GrLibrary library) {
    library.addForeign("ArrayIterator", ["T"]);
    GrType iteratorType = grGetForeignType("ArrayIterator", [grAny("T")]);

    library.addFunction(&_copy, "copy", [grPure(grArray(grAny("T")))], [
            grArray(grAny("T"))
        ]);
    library.addFunction(&_size, "size", [grPure(grArray(grAny("T")))], [grInt]);
    library.addFunction(&_resize, "resize", [grArray(grAny("T")), grInt]);
    library.addFunction(&_isEmpty, "isEmpty", [grPure(grArray(grAny("T")))], [
            grBool
        ]);
    library.addFunction(&_fill, "fill", [grArray(grAny("T")), grAny("T")]);
    library.addFunction(&_clear, "clear", [grArray(grAny("T"))]);
    library.addFunction(&_unshift, "unshift", [grArray(grAny("T")), grAny("T")]);
    library.addFunction(&_push, "push", [grArray(grAny("T")), grAny("T")], [
            grAny("T")
        ]);
    library.addFunction(&_shift, "shift", [grArray(grAny("T"))], [grAny("T")]);
    library.addFunction(&_pop, "pop", [grArray(grAny("T"))], [grOptional(grAny("T"))]);
    library.addFunction(&_shift1, "shift", [grArray(grAny("T")), grInt], [
            grArray(grAny("T"))
        ]);
    library.addFunction(&_pop1, "pop", [grArray(grAny("T")), grInt], [
            grArray(grAny("T"))
        ]);
    library.addFunction(&_first, "first", [grPure(grArray(grAny("T")))], [
            grOptional(grAny("T"))
        ]);
    library.addFunction(&_last, "last", [grPure(grArray(grAny("T")))], [
            grOptional(grAny("T"))
        ]);
    library.addFunction(&_remove, "remove", [grArray(grAny("T")), grInt], [
            grArray(grAny("T"))
        ]);
    library.addFunction(&_remove2, "remove", [grArray(grAny("T")), grInt,
            grInt], [grArray(grAny("T"))]);
    library.addFunction(&_slice, "slice", [
            grPure(grArray(grAny("T"))), grInt, grInt
        ], [grArray(grAny("T"))]);
    library.addFunction(&_reverse, "reverse", [grPure(grArray(grAny("T")))],
        [grArray(grAny("T"))]);
    library.addFunction(&_insert, "insert", [
            grArray(grAny("T")), grInt, grAny("T")
        ], [grArray(grAny("T"))]);
    library.addFunction(&_each, "each", [grArray(grAny("T"))], [iteratorType]);
    library.addFunction(&_next, "next", [iteratorType], [grOptional(grAny("T"))]);
    library.addFunction(&_findFirst, "findFirst",
        [grPure(grArray(grAny("T"))), grPure(grAny("T"))], [grInt]);
    library.addFunction(&_findLast, "findLast", [
            grPure(grArray(grAny("T"))), grPure(grAny("T"))
        ], [grOptional(grInt)]);
    library.addFunction(&_findLast, "findLast", [
            grPure(grArray(grAny("T"))), grPure(grAny("T"))
        ], [grOptional(grInt)]);
    library.addFunction(&_has, "has", [
            grPure(grArray(grAny("T"))), grPure(grAny("T"))
        ], [grBool]);

    library.addFunction(&_sort_!"int", "sort", [grArray(grInt)], [
            grArray(grInt)
        ]);
    library.addFunction(&_sort_!"real", "sort", [grArray(grReal)], [
            grArray(grReal)
        ]);
    library.addFunction(&_sort_!"string", "sort", [grArray(grString)], [
            grArray(grString)
        ]);
}

private void _copy(GrCall call) {
    call.setArray(call.getArray(0));
}

private void _size(GrCall call) {
    call.setInt(call.getArray(0).size());
}

private void _resize(GrCall call) {
    GrArray array = call.getArray(0);
    const GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("ArgumentError");
        return;
    }
    array.resize(size);
}

private void _isEmpty(GrCall call) {
    const GrArray array = call.getArray(0);
    call.setBool(array.isEmpty());
}

private void _fill(GrCall call) {
    GrArray array = call.getArray(0);
    GrValue value = call.getValue(1);
    for (GrInt index; index < array.size(); ++index)
        array[index] = value;
}

private void _clear(GrCall call) {
    GrArray array = call.getArray(0);
    array.clear();
}

private void _unshift(GrCall call) {
    GrArray array = call.getArray(0);
    array.unshift(call.getValue(1));
}

private void _push(GrCall call) {
    GrArray array = call.getArray(0);
    array.push(call.getValue(1));
}

private void _shift(GrCall call) {
    GrArray array = call.getArray(0);
    if (!array.size()) {
        call.raise("IndexError");
        return;
    }
    call.setValue(array.shift());
}

private void _pop(GrCall call) {
    GrArray array = call.getArray(0);
    if (array.isEmpty()) {
        call.setNull();
        return;
    }
    call.setValue(array.pop());
}

private void _shift1(GrCall call) {
    GrArray array = call.getArray(0);
    GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    call.setArray(array.shift(size));
}

private void _pop1(GrCall call) {
    GrArray array = call.getArray(0);
    GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    call.setArray(array.pop(size));
}

private void _first(GrCall call) {
    GrArray array = call.getArray(0);
    if (!array.size()) {
        call.setNull();
        return;
    }
    call.setValue(array.first());
}

private void _last(GrCall call) {
    GrArray array = call.getArray(0);
    if (!array.size()) {
        call.setNull();
        return;
    }
    call.setValue(array.last());
}

private void _remove(GrCall call) {
    GrArray array = call.getArray(0);
    GrInt index = call.getInt(1);
    array.remove(index);
}

private void _remove2(GrCall call) {
    GrArray array = call.getArray(0);
    GrInt index1 = call.getInt(1);
    GrInt index2 = call.getInt(2);
    array.remove(index1, index2);
}

private void _slice(GrCall call) {
    GrArray array = call.getArray(0);
    GrInt index1 = call.getInt(1);
    GrInt index2 = call.getInt(2);
    call.setArray(array.slice(index1, index2));
}

private void _reverse(GrCall call) {
    GrArray array = call.getArray(0);
    call.setArray(array.reverse());
}

private void _insert(GrCall call) {
    GrArray array = call.getArray(0);
    GrInt index = call.getInt(1);
    GrValue value = call.getValue(2);
    array.insert(index, value);
}

private void _sort_(string T)(GrCall call) {
    GrArray array = call.getArray(0);
    static if (T == "int")
        array.sortByInt();
    else static if (T == "real")
        array.sortByReal();
    else static if (T == "string")
        array.sortByString();
}

private void _findFirst(GrCall call) {
    GrArray array = call.getArray(0);
    GrValue value = call.getValue(1);
    GrInt index = array.indexOf(value);
    if (index == -1) {
        call.setNull();
        return;
    }
    call.setInt(index);
}

private void _findLast(GrCall call) {
    GrArray array = call.getArray(0);
    GrValue value = call.getValue(1);
    GrInt index = array.lastIndexOf(value);
    if (index == -1) {
        call.setNull();
        return;
    }
    call.setInt(index);
}

private void _has(GrCall call) {
    GrArray array = call.getArray(0);
    GrValue value = call.getValue(1);
    call.setBool(array.contains(value));
}

private final class ArrayIterator {
    GrValue[] array;
    size_t index;
}

private void _each(GrCall call) {
    GrArray array = call.getArray(0);
    ArrayIterator iter = new ArrayIterator;
    iter.array = array.data.dup;
    call.setForeign(iter);
}

private void _next(GrCall call) {
    ArrayIterator iter = call.getForeign!(ArrayIterator)(0);

    if (!iter) {
        call.raise("NullError");
        return;
    }
    if (iter.index >= iter.array.length) {
        call.setNull();
        return;
    }
    call.setValue(iter.array[iter.index]);
    iter.index++;
}
