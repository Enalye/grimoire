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

    GrType valueType = grAny("T");
    GrType pureValueType = grAny("T", true);
    GrType arrayType = grArray(valueType);
    GrType pureArrayType = grArray(valueType, true);
    GrType iteratorType = grGetForeignType("ArrayIterator", [valueType]);

    library.addFunction(&_copy, "copy", [pureArrayType], [arrayType]);
    library.addFunction(&_size, "size", [pureArrayType], [grInt]);
    library.addFunction(&_resize, "resize", [arrayType, grInt], [arrayType]);
    library.addFunction(&_empty, "empty?", [pureArrayType], [grBool]);
    library.addFunction(&_fill, "fill", [arrayType, valueType], [arrayType]);
    library.addFunction(&_clear, "clear", [arrayType], [arrayType]);
    library.addFunction(&_unshift, "unshift", [arrayType, valueType], [
            arrayType
        ]);
    library.addFunction(&_push, "push", [arrayType, valueType], [valueType]);
    library.addFunction(&_shift, "shift", [arrayType], [valueType]);
    library.addFunction(&_pop, "pop", [arrayType], [valueType]);
    library.addFunction(&_shift1, "shift", [arrayType, grInt], [arrayType]);
    library.addFunction(&_pop1, "pop", [arrayType, grInt], [arrayType]);
    library.addFunction(&_first, "first", [pureArrayType], [valueType]);
    library.addFunction(&_last, "last", [pureArrayType], [valueType]);
    library.addFunction(&_remove, "remove", [arrayType, grInt], [arrayType]);
    library.addFunction(&_remove2, "remove", [arrayType, grInt, grInt], [
            arrayType
        ]);
    library.addFunction(&_slice, "slice", [arrayType, grInt, grInt], [arrayType]);
    library.addFunction(&_slice_copy, "sliced", [pureArrayType, grInt, grInt], [
            arrayType
        ]);
    library.addFunction(&_reverse, "reverse", [pureArrayType], [arrayType]);
    library.addFunction(&_insert, "insert", [arrayType, grInt, valueType], [
            arrayType
        ]);
    library.addFunction(&_each, "each", [arrayType], [iteratorType]);
    library.addFunction(&_next, "next", [iteratorType], [grBool, valueType]);
    library.addFunction(&_findFirst, "findFirst", [pureArrayType, pureValueType], [
            grInt
        ]);
    library.addFunction(&_findLast, "findLast", [pureArrayType, pureValueType], [
            grInt
        ]);
    library.addFunction(&_findLast, "findLast", [pureArrayType, pureValueType], [
            grInt
        ]);
    library.addFunction(&_has, "has?", [pureArrayType, pureValueType], [grBool]);

    library.addFunction(&_sort_!"int", "sort", [grIntArray], [grIntArray]);
    library.addFunction(&_sort_!"real", "sort", [grRealArray], [grRealArray]);
    library.addFunction(&_sort_!"string", "sort", [grStringArray], [
            grStringArray
        ]);
}

private void _copy(GrCall call) {
    GrArray copy = new GrArray;
    copy.data = call.getArray(0).data.dup;
    call.setArray(copy);
}

private void _size(GrCall call) {
    call.setInt(cast(GrInt) call.getArray(0).data.length);
}

private void _resize(GrCall call) {
    GrArray array = call.getArray(0);
    const GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("ArgumentError");
        return;
    }
    array.data.length = size;
    call.setArray(array);
}

private void _empty(GrCall call) {
    const GrArray array = call.getArray(0);
    call.setBool(array.data.empty);
}

private void _fill(GrCall call) {
    GrArray array = call.getArray(0);
    GrValue value = call.getValue(1);
    for (size_t index; index < array.data.length; ++index)
        array.data[index] = value;
    call.setArray(array);
}

private void _clear(GrCall call) {
    GrArray array = call.getArray(0);
    array.data.length = 0;
    call.setArray(array);
}

private void _unshift(GrCall call) {
    GrArray array = call.getArray(0);
    array.data = call.getValue(1) ~ array.data;
    call.setArray(array);
}

private void _push(GrCall call) {
    GrArray array = call.getArray(0);
    array.data ~= call.getValue(1);
    call.setArray(array);
}

private void _shift(GrCall call) {
    GrArray array = call.getArray(0);
    if (!array.data.length) {
        call.raise("IndexError");
        return;
    }
    call.setValue(array.data[0]);
    array.data = array.data[1 .. $];
}

private void _pop(GrCall call) {
    GrArray array = call.getArray(0);
    if (!array.data.length) {
        call.raise("IndexError");
        return;
    }
    call.setValue(array.data[$ - 1]);
    array.data.length--;
}

private void _shift1(GrCall call) {
    GrArray array = call.getArray(0);
    GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    if (array.data.length < size) {
        size = cast(GrInt) array.data.length;
    }
    GrArray copy = new GrArray;
    copy.data = array.data[0 .. size];
    array.data = array.data[size .. $];
    call.setArray(copy);
}

private void _pop1(GrCall call) {
    GrArray array = call.getArray(0);
    GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    if (array.data.length < size) {
        size = cast(GrInt) array.data.length;
    }
    GrArray copy = new GrArray;
    copy.data = array.data[$ - size .. $];
    array.data.length -= size;
    call.setArray(copy);
}

private void _first(GrCall call) {
    GrArray array = call.getArray(0);
    if (!array.data.length) {
        call.raise("IndexError");
        return;
    }
    call.setValue(array.data[0]);
}

private void _last(GrCall call) {
    GrArray array = call.getArray(0);
    if (!array.data.length) {
        call.raise("IndexError");
        return;
    }
    call.setValue(array.data[$ - 1]);
}

private void _remove(GrCall call) {
    GrArray array = call.getArray(0);
    GrInt index = call.getInt(1);
    if (index < 0)
        index = (cast(GrInt) array.data.length) + index;
    if (!array.data.length || index >= array.data.length || index < 0) {
        call.setArray(array);
        return;
    }
    if (index + 1 == array.data.length) {
        array.data.length--;
        call.setArray(array);
        return;
    }
    if (index == 0) {
        array.data = array.data[1 .. $];
        call.setArray(array);
        return;
    }
    array.data = array.data[0 .. index] ~ array.data[index + 1 .. $];
    call.setArray(array);
}

private void _remove2(GrCall call) {
    GrArray array = call.getArray(0);
    GrInt index1 = call.getInt(1);
    GrInt index2 = call.getInt(2);
    if (index1 < 0)
        index1 = (cast(GrInt) array.data.length) + index1;
    if (index2 < 0)
        index2 = (cast(GrInt) array.data.length) + index2;

    if (index2 < index1) {
        const GrInt temp = index1;
        index1 = index2;
        index2 = temp;
    }

    if (!array.data.length || index1 >= array.data.length || index2 < 0) {
        call.setArray(array);
        return;
    }

    if (index1 < 0)
        index1 = 0;
    if (index2 >= array.data.length)
        index2 = (cast(GrInt) array.data.length) - 1;

    if (index1 == 0 && (index2 + 1) == array.data.length) {
        array.data.length = 0;
        call.setArray(array);
        return;
    }
    if (index1 == 0) {
        array.data = array.data[(index2 + 1) .. $];
        call.setArray(array);
        return;
    }
    if ((index2 + 1) == array.data.length) {
        array.data = array.data[0 .. index1];
        call.setArray(array);
        return;
    }
    array.data = array.data[0 .. index1] ~ array.data[(index2 + 1) .. $];
    call.setArray(array);
}

private void _slice(GrCall call) {
    GrArray array = call.getArray(0);
    GrInt index1 = call.getInt(1);
    GrInt index2 = call.getInt(2);
    if (index1 < 0)
        index1 = (cast(GrInt) array.data.length) + index1;
    if (index2 < 0)
        index2 = (cast(GrInt) array.data.length) + index2;

    if (index2 < index1) {
        const GrInt temp = index1;
        index1 = index2;
        index2 = temp;
    }

    if (!array.data.length || index1 >= array.data.length || index2 < 0) {
        array.data.length = 0;
        call.setArray(array);
        return;
    }

    if (index1 < 0)
        index1 = 0;
    if (index2 >= array.data.length)
        index2 = (cast(GrInt) array.data.length - 1);

    if (index1 == 0 && (index2 + 1) == array.data.length) {
        call.setArray(array);
        return;
    }
    array.data = array.data[index1 .. index2 + 1];
    call.setArray(array);
}

private void _slice_copy(GrCall call) {
    GrArray array = call.getArray(0);
    GrArray copy = new GrArray;
    GrInt index1 = call.getInt(1);
    GrInt index2 = call.getInt(2);
    if (index1 < 0)
        index1 = (cast(GrInt) array.data.length) + index1;
    if (index2 < 0)
        index2 = (cast(GrInt) array.data.length) + index2;

    if (index2 < index1) {
        const GrInt temp = index1;
        index1 = index2;
        index2 = temp;
    }

    if (!array.data.length || index1 >= array.data.length || index2 < 0) {
        call.setArray(copy);
        return;
    }

    if (index1 < 0)
        index1 = 0;
    if (index2 >= array.data.length)
        index2 = (cast(GrInt) array.data.length - 1);

    if (index1 == 0 && (index2 + 1) == array.data.length) {
        copy.data = array.data;
    }
    else {
        copy.data = array.data[index1 .. index2 + 1];
    }
    call.setArray(copy);
}

private void _reverse(GrCall call) {
    import std.algorithm.mutation : reverse;

    GrArray array = call.getArray(0);
    array.data = array.data.reverse;
    call.setArray(array);
}

private void _insert(GrCall call) {
    GrArray array = call.getArray(0);
    GrInt index = call.getInt(1);
    auto value = call.getValue(2);

    if (index < 0)
        index = (cast(GrInt) array.data.length) + index;
    if (!array.data.length || index >= array.data.length || index < 0) {
        call.raise("IndexError");
        return;
    }
    if (index + 1 == array.data.length) {
        array.data = array.data[0 .. index] ~ value ~ array.data[$ - 1];
        call.setArray(array);
        return;
    }
    if (index == 0) {
        array.data = value ~ array.data;
        call.setArray(array);
        return;
    }
    array.data = array.data[0 .. index] ~ value ~ array.data[index .. $];
    call.setArray(array);
}

private void _sort_(string T)(GrCall call) {
    import std.algorithm.sorting : sort;

    GrArray array = call.getArray(0);
    static if (T == "int")
        array.data.sort!((a, b) => a.ivalue < b.ivalue)();
    else static if (T == "real")
        array.data.sort!((a, b) => a.rvalue < b.rvalue)();
    else static if (T == "string")
        array.data.sort!((a, b) => (cast(GrStringWrapper) a.ovalue).data < (cast(GrStringWrapper) b.ovalue).data)();
    call.setArray(array);
}

private void _findFirst(GrCall call) {
    GrArray array = call.getArray(0);
    auto value = call.getValue(1);

    for (GrInt index; index < array.data.length; ++index) {
        if (array.data[index] == value) {
            call.setInt(index);
            return;
        }
    }
    call.setInt(-1);
}

private void _findLast(GrCall call) {
    GrArray array = call.getArray(0);
    auto value = call.getValue(1);

    for (GrInt index = (cast(GrInt) array.data.length) - 1; index > 0; --index) {
        if (array.data[index] == value) {
            call.setInt(index);
            return;
        }
    }
    call.setInt(-1);
}

private void _has(GrCall call) {
    GrArray array = call.getArray(0);
    auto value = call.getValue(1);

    for (GrInt index; index < array.data.length; ++index) {
        if (array.data[index] == value) {
            call.setBool(true);
            return;
        }
    }
    call.setBool(false);
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
        call.setBool(false);
        call.setValue(GrValue());
        return;
    }
    call.setBool(true);
    call.setValue(iter.array[iter.index]);
    iter.index++;
}
