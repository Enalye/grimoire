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
    library.addFunction(&_get, "get", [grPure(grList(grAny("T"))), grInt], [
            grOptional(grAny("T"))
        ]);
    library.addFunction(&_getOr, "getOr", [
            grPure(grList(grAny("T"))), grInt, grAny("T")
        ], [grAny("T")]);
    library.addFunction(&_unshift, "unshift", [grList(grAny("T")), grAny("T")]);
    library.addFunction(&_push, "push", [grList(grAny("T")), grAny("T")]);
    library.addFunction(&_shift, "shift", [grList(grAny("T"))], [
            grOptional(grAny("T"))
        ]);
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
    library.addFunction(&_remove, "remove", [grList(grAny("T")), grInt]);
    library.addFunction(&_remove2, "remove", [grList(grAny("T")), grInt, grInt]);
    library.addFunction(&_slice, "slice", [
            grPure(grList(grAny("T"))), grInt, grInt
        ], [grList(grAny("T"))]);
    library.addFunction(&_reverse, "reverse", [grPure(grList(grAny("T")))], [
            grList(grAny("T"))
        ]);
    library.addFunction(&_insert, "insert", [
            grList(grAny("T")), grInt, grAny("T")
        ]);

    library.addFunction(&_indexOf, "indexOf", [
            grPure(grList(grAny("T"))), grPure(grAny("T"))
        ], [grOptional(grInt)]);
    library.addFunction(&_lastIndexOf, "lastIndexOf",
        [grPure(grList(grAny("T"))), grPure(grAny("T"))], [grOptional(grInt)]);
    library.addFunction(&_contains, "contains", [
            grPure(grList(grAny("T"))), grPure(grAny("T"))
        ], [grBool]);

    library.addFunction(&_sort_!"int", "sort", [grList(grInt)]);
    library.addFunction(&_sort_!"real", "sort", [grList(grReal)]);
    library.addFunction(&_sort_!"string", "sort", [grList(grString)]);

    GrType iteratorType = library.addNative("ListIterator", ["T"]);
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

private void _get(GrCall call) {
    GrList list = call.getList(0);
    const GrInt idx = call.getInt(1);
    if(idx >= list.size) {
        call.setNull();
        return;
    }
    call.setValue(list[idx]);
}

private void _getOr(GrCall call) {
    GrList list = call.getList(0);
    const GrInt idx = call.getInt(1);
    if(idx >= list.size) {
        call.setValue(call.getValue(2));
        return;
    }
    call.setValue(list[idx]);
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

private void _indexOf(GrCall call) {
    GrList list = call.getList(0);
    GrValue value = call.getValue(1);
    const GrInt index = list.indexOf(value);
    if (index < 0) {
        call.setNull();
        return;
    }
    call.setInt(index);
}

private void _lastIndexOf(GrCall call) {
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
    call.setNative(iter);
}

private void _next(GrCall call) {
    ListIterator iter = call.getNative!(ListIterator)(0);
    if (iter.index >= iter.list.length) {
        call.setNull();
        return;
    }
    call.setValue(iter.list[iter.index]);
    iter.index++;
}
