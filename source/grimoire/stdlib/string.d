/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.string;

import std.string;
import std.conv : to;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

package(grimoire.stdlib) void grLoadStdLibString(GrLibrary library) {
    library.addFunction(&_isEmpty, "isEmpty", [grPure(grString)], [grBool]);
    library.addFunction(&_unshift, "unshift", [grString, grString]);
    library.addFunction(&_push, "push", [grString, grString]);
    library.addFunction(&_shift, "shift", [grString], [grOptional(grString)]);
    library.addFunction(&_pop, "pop", [grString], [grOptional(grString)]);
    library.addFunction(&_shift1, "shift", [grString, grInt], [grString]);
    library.addFunction(&_pop1, "pop", [grString, grInt], [grString]);
    library.addFunction(&_first, "first", [grPure(grString)], [
            grOptional(grString)
        ]);
    library.addFunction(&_last, "last", [grPure(grString)], [
            grOptional(grString)
        ]);
    library.addFunction(&_remove, "remove", [grString, grInt]);
    library.addFunction(&_remove2, "remove", [grString, grInt, grInt]);
    library.addFunction(&_slice, "slice", [grPure(grString), grInt, grInt], [
            grString
        ]);
    library.addFunction(&_reverse, "reverse", [grPure(grString)], [grString]);
    library.addFunction(&_insert, "insert", [grString, grInt, grPure(grString)]);
    library.addFunction(&_findFirst, "findFirst", [
            grPure(grString), grPure(grString)
        ], [grOptional(grInt)]);
    library.addFunction(&_findLast, "findLast", [
            grPure(grString), grPure(grString)
        ], [grOptional(grInt)]);
    library.addFunction(&_contains, "contains", [
            grPure(grString), grPure(grString)
        ], [grBool]);

    GrType stringIterType = library.addForeign("StringIterator");
    library.addFunction(&_each, "each", [grString], [stringIterType]);
    library.addFunction(&_next, "next", [stringIterType], [grOptional(grString)]);
}

private void _isEmpty(GrCall call) {
    call.setBool(call.getString(0).isEmpty());
}

private void _unshift(GrCall call) {
    GrString str = call.getString(0);
    str.unshift(call.getStringData(1));
}

private void _push(GrCall call) {
    GrString str = call.getString(0);
    str.push(call.getStringData(1));
}

private void _shift(GrCall call) {
    GrString str = call.getString(0);
    if (!str.size()) {
        call.setNull();
        return;
    }
    call.setString(str.shift());
}

private void _pop(GrCall call) {
    GrString str = call.getString(0);
    if (!str.size()) {
        call.setNull();
        return;
    }
    call.setString(str.pop());
}

private void _shift1(GrCall call) {
    GrString str = call.getString(0);
    GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    call.setString(str.shift(size));
}

private void _pop1(GrCall call) {
    GrString str = call.getString(0);
    GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    call.setString(str.pop(size));
}

private void _first(GrCall call) {
    GrString str = call.getString(0);
    if (!str.size()) {
        call.setNull();
        return;
    }
    call.setString(str.first());
}

private void _last(GrCall call) {
    GrString str = call.getString(0);
    if (!str.size()) {
        call.setNull();
        return;
    }
    call.setString(str.last());
}

private void _remove(GrCall call) {
    GrString str = call.getString(0);
    GrInt index = call.getInt(1);
    str.remove(index);
}

private void _remove2(GrCall call) {
    GrString str = call.getString(0);
    GrInt index1 = call.getInt(1);
    GrInt index2 = call.getInt(2);
    str.remove(index1, index2);
}

private void _slice(GrCall call) {
    GrString str = call.getString(0);
    GrInt index1 = call.getInt(1);
    GrInt index2 = call.getInt(2);
    call.setString(str.slice(index1, index2));
}

private void _reverse(GrCall call) {
    call.setString(call.getString(0).reverse());
}

private void _insert(GrCall call) {
    GrString str = call.getString(0);
    GrInt index = call.getInt(1);
    GrStr value = call.getStringData(2);
    str.insert(index, value);
}

private void _findFirst(GrCall call) {
    GrString str = call.getString(0);
    GrStr value = call.getStringData(1);
    const GrInt result = cast(GrInt) str.indexOf(value);
    if (result < 0) {
        call.setNull();
        return;
    }
    call.setInt(result);
}

private void _findLast(GrCall call) {
    GrString str = call.getString(0);
    GrStr value = call.getStringData(1);
    const GrInt result = cast(GrInt) str.lastIndexOf(value);
    if (result < 0) {
        call.setNull();
        return;
    }
    call.setInt(result);
}

private void _contains(GrCall call) {
    GrString str = call.getString(0);
    GrStr value = call.getStringData(1);
    call.setBool(str.contains(value));
}

private final class StringIterator {
    GrStr value;
    size_t index;
}

private void _each(GrCall call) {
    StringIterator iter = new StringIterator;
    iter.value = call.getStringData(0);
    call.setForeign(iter);
}

private void _next(GrCall call) {
    StringIterator iter = call.getForeign!(StringIterator)(0);
    if (iter.index >= iter.value.length) {
        call.setNull();
        return;
    }
    call.setString(to!GrStr(iter.value[iter.index]));
    iter.index++;
}
