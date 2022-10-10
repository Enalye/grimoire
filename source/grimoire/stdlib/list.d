/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.list;

import std.range;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

package(grimoire.stdlib) void grLoadStdLibList(GrLibrary library) {
    library.addFunction(&_copy, "copy", [grPure(grList(grAny("T")))], [
            grList(grAny("T"))
        ]);
    library.addFunction(&_size, "size", [grPure(grList(grAny("T")))], [grInt]);
    library.addFunction(&_resize, "resize", [grList(grAny("T")), grInt]);
    library.addFunction(&_isEmpty, "isEmpty", [grPure(grList(grAny("T")))], [
            grBool
        ]);
    library.addFunction(&_fill, "fill", [grList(grAny("T")), grAny("T")]);
    library.addFunction(&_clear, "clear", [grList(grAny("T"))]);
    library.addFunction(&_unshift, "unshift", [grList(grAny("T")), grAny("T")]);
    library.addFunction(&_push, "push", [grList(grAny("T")), grAny("T")], [
            grAny("T")
        ]);
    library.addFunction(&_shift, "shift", [grList(grAny("T"))], [grAny("T")]);
    library.addFunction(&_pop, "pop", [grList(grAny("T"))], [
            grOptional(grAny("T"))
        ]);
    library.addFunction(&_shift1, "shift", [grList(grAny("T")), grInt], [
            grList(grAny("T"))
        ]);
    library.addFunction(&_pop1, "pop", [grList(grAny("T")), grInt], [
            grList(grAny("T"))
        ]);
    library.addFunction(&_first, "first", [grPure(grList(grAny("T")))], [
            grOptional(grAny("T"))
        ]);
    library.addFunction(&_last, "last", [grPure(grList(grAny("T")))], [
            grOptional(grAny("T"))
        ]);
    library.addFunction(&_remove, "remove", [grList(grAny("T")), grInt], [
            grList(grAny("T"))
        ]);
    library.addFunction(&_remove2, "remove", [grList(grAny("T")), grInt,
            grInt], [grList(grAny("T"))]);
    library.addFunction(&_slice, "slice", [
            grPure(grList(grAny("T"))), grInt, grInt
        ], [grList(grAny("T"))]);
    library.addFunction(&_reverse, "reverse", [grPure(grList(grAny("T")))],
        [grList(grAny("T"))]);
    library.addFunction(&_insert, "insert", [
            grList(grAny("T")), grInt, grAny("T")
        ]);

    library.addFunction(&_findFirst, "findFirst",
        [grPure(grList(grAny("T"))), grPure(grAny("T"))], [grInt]);
    library.addFunction(&_findLast, "findLast", [
            grPure(grList(grAny("T"))), grPure(grAny("T"))
        ], [grOptional(grInt)]);
    library.addFunction(&_findLast, "findLast", [
            grPure(grList(grAny("T"))), grPure(grAny("T"))
        ], [grOptional(grInt)]);
    library.addFunction(&_contains, "contains", [
            grPure(grList(grAny("T"))), grPure(grAny("T"))
        ], [grBool]);

    library.addFunction(&_sort_!"int", "sort", [grList(grInt)], [
            grList(grInt)
        ]);
    library.addFunction(&_sort_!"real", "sort", [grList(grReal)], [
            grList(grReal)
        ]);
    library.addFunction(&_sort_!"string", "sort", [grList(grString)], [
            grList(grString)
        ]);

    GrType iteratorType = library.addForeign("ListIterator", ["T"]);
    library.addFunction(&_each, "each", [grList(grAny("T"))], [iteratorType]);
    library.addFunction(&_next, "next", [iteratorType], [grOptional(grAny("T"))]);
}

private void _copy(GrCall call) {
    call.setList(call.getList(0));
}

private void _size(GrCall call) {
    call.setInt(call.getList(0).size());
}

private void _resize(GrCall call) {
    GrList list = call.getList(0);
    const GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("ArgumentError");
        return;
    }
    list.resize(size);
}

private void _isEmpty(GrCall call) {
    const GrList list = call.getList(0);
    call.setBool(list.isEmpty());
}

private void _fill(GrCall call) {
    GrList list = call.getList(0);
    GrValue value = call.getValue(1);
    for (GrInt index; index < list.size(); ++index)
        list[index] = value;
}

private void _clear(GrCall call) {
    GrList list = call.getList(0);
    list.clear();
}

private void _unshift(GrCall call) {
    GrList list = call.getList(0);
    list.unshift(call.getValue(1));
}

private void _push(GrCall call) {
    GrList list = call.getList(0);
    list.push(call.getValue(1));
}

private void _shift(GrCall call) {
    GrList list = call.getList(0);
    if (!list.size()) {
        call.setNull();
        return;
    }
    call.setValue(list.shift());
}

private void _pop(GrCall call) {
    GrList list = call.getList(0);
    if (list.isEmpty()) {
        call.setNull();
        return;
    }
    call.setValue(list.pop());
}

private void _shift1(GrCall call) {
    GrList list = call.getList(0);
    GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    call.setList(list.shift(size));
}

private void _pop1(GrCall call) {
    GrList list = call.getList(0);
    GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    call.setList(list.pop(size));
}

private void _first(GrCall call) {
    GrList list = call.getList(0);
    if (!list.size()) {
        call.setNull();
        return;
    }
    call.setValue(list.first());
}

private void _last(GrCall call) {
    GrList list = call.getList(0);
    if (!list.size()) {
        call.setNull();
        return;
    }
    call.setValue(list.last());
}

private void _remove(GrCall call) {
    GrList list = call.getList(0);
    GrInt index = call.getInt(1);
    list.remove(index);
}

private void _remove2(GrCall call) {
    GrList list = call.getList(0);
    GrInt index1 = call.getInt(1);
    GrInt index2 = call.getInt(2);
    list.remove(index1, index2);
}

private void _slice(GrCall call) {
    GrList list = call.getList(0);
    GrInt index1 = call.getInt(1);
    GrInt index2 = call.getInt(2);
    call.setList(list.slice(index1, index2));
}

private void _reverse(GrCall call) {
    GrList list = call.getList(0);
    call.setList(list.reverse());
}

private void _insert(GrCall call) {
    GrList list = call.getList(0);
    GrInt index = call.getInt(1);
    GrValue value = call.getValue(2);
    list.insert(index, value);
}

private void _sort_(string T)(GrCall call) {
    GrList list = call.getList(0);
    static if (T == "int")
        list.sortByInt();
    else static if (T == "real")
        list.sortByReal();
    else static if (T == "string")
        list.sortByString();
}

private void _findFirst(GrCall call) {
    GrList list = call.getList(0);
    GrValue value = call.getValue(1);
    const GrInt index = list.indexOf(value);
    if (index < 0) {
        call.setNull();
        return;
    }
    call.setInt(index);
}

private void _findLast(GrCall call) {
    GrList list = call.getList(0);
    GrValue value = call.getValue(1);
    const GrInt index = list.lastIndexOf(value);
    if (index < 0) {
        call.setNull();
        return;
    }
    call.setInt(index);
}

private void _contains(GrCall call) {
    GrList list = call.getList(0);
    GrValue value = call.getValue(1);
    call.setBool(list.contains(value));
}

private final class ListIterator {
    GrValue[] list;
    size_t index;
}

private void _each(GrCall call) {
    GrList list = call.getList(0);
    ListIterator iter = new ListIterator;
    foreach (GrValue element; list.getValues()) {
        if (!element.isNull)
            iter.list ~= element;
    }
    call.setForeign(iter);
}

private void _next(GrCall call) {
    ListIterator iter = call.getForeign!(ListIterator)(0);
    if (iter.index >= iter.list.length) {
        call.setNull();
        return;
    }
    call.setValue(iter.list[iter.index]);
    iter.index++;
}
