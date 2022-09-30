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
    library.addFunction(&_unshift, "unshift", [grPure(grString), grString], [
            grString
        ]);
    library.addFunction(&_push, "push", [grPure(grString), grString], [grString]);
    library.addFunction(&_shift, "shift", [grPure(grString)], [grString]);
    library.addFunction(&_pop, "pop", [grPure(grString)], [grString]);
    library.addFunction(&_shift1, "shift", [grPure(grString), grInt], [grString]);
    library.addFunction(&_pop1, "pop", [grPure(grString), grInt], [grString]);
    library.addFunction(&_first, "first", [grPure(grString)], [grOptional(grString)]);
    library.addFunction(&_last, "last", [grPure(grString)], [grOptional(grString)]);
    library.addFunction(&_remove, "remove", [grPure(grString), grInt], [
            grString
        ]);
    library.addFunction(&_remove2, "remove", [grPure(grString), grInt, grInt], [
            grString
        ]);
    library.addFunction(&_slice, "slice", [grPure(grString), grInt, grInt], [
            grString
        ]);
    library.addFunction(&_reverse, "reverse", [grPure(grString)], [grString]);
    library.addFunction(&_insert, "insert", [
            grPure(grString), grInt, grPure(grString)
        ], [grString]);
    library.addFunction(&_findFirst, "findFirst", [
            grPure(grString), grPure(grString)
        ], [grOptional(grInt)]);
    library.addFunction(&_findLast, "findLast", [
            grPure(grString), grPure(grString)
        ], [grOptional(grInt)]);
    library.addFunction(&_has, "has", [grPure(grString), grPure(grString)], [
            grBool
        ]);

    GrType stringIterType = library.addForeign("StringIterator");
    library.addFunction(&_each, "each", [grString], [stringIterType]);
    library.addFunction(&_next, "next", [stringIterType], [grOptional(grString)]);
}

private void _isEmpty(GrCall call) {
    call.setBool(call.getString(0).length == 0);
}

private void _unshift(GrCall call) {
    call.setString(call.getString(1) ~ call.getString(0));
}

private void _push(GrCall call) {
    call.setString(call.getString(0) ~ call.getString(1));
}

private void _shift(GrCall call) {
    string str = call.getString(0);
    if (!str.length) {
        call.setNull();
        return;
    }
    call.setString(str[1 .. $]);
}

private void _pop(GrCall call) {
    string str = call.getString(0);
    if (!str.length) {
        call.setNull();
        return;
    }
    str.length--;
    call.setString(str);
}

private void _shift1(GrCall call) {
    GrString str = call.getString(0);
    GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    if (str.length < size) {
        str.length = 0;
        call.setString(str);
        return;
    }
    if (!str.length) {
        call.setString(str);
        return;
    }
    call.setString(str[size .. $]);
}

private void _pop1(GrCall call) {
    GrString str = call.getString(0);
    GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    if (str.length < size) {
        str.length = 0;
        call.setString(str);
        return;
    }
    if (!str.length) {
        call.setString(str);
        return;
    }
    str.length -= size;
    call.setString(str);
}

private void _first(GrCall call) {
    GrString str = call.getString(0);
    if (!str.length) {
        call.setNull();
        return;
    }
    call.setString(to!GrString(str[0]));
}

private void _last(GrCall call) {
    GrString str = call.getString(0);
    if (!str.length) {
        call.setNull();
        return;
    }
    call.setString(to!GrString(str[$ - 1]));
}

private void _remove(GrCall call) {
    GrString str = call.getString(0);
    GrInt index = call.getInt(1);
    if (index < 0)
        index = (cast(GrInt) str.length) + index;
    if (!str.length || index >= str.length || index < 0) {
        call.setString(str);
        return;
    }
    if (index + 1 == str.length) {
        str.length--;
        call.setString(str);
        return;
    }
    if (index == 0) {
        call.setString(str[1 .. $]);
        return;
    }
    call.setString(str[0 .. index] ~ str[index + 1 .. $]);
}

private void _remove2(GrCall call) {
    GrString str = call.getString(0);
    GrInt index1 = call.getInt(1);
    GrInt index2 = call.getInt(2);
    if (index1 < 0)
        index1 = (cast(GrInt) str.length) + index1;
    if (index2 < 0)
        index2 = (cast(GrInt) str.length) + index2;

    if (index2 < index1) {
        const GrInt temp = index1;
        index1 = index2;
        index2 = temp;
    }

    if (!str.length || index1 >= str.length || index2 < 0) {
        call.setString(str);
        return;
    }

    if (index1 < 0)
        index1 = 0;
    if (index2 >= str.length)
        index2 = (cast(GrInt) str.length) - 1;

    if (index1 == 0 && (index2 + 1) == str.length) {
        call.setString("");
        return;
    }
    if (index1 == 0) {
        call.setString(str[(index2 + 1) .. $]);
        return;
    }
    if ((index2 + 1) == str.length) {
        call.setString(str[0 .. index1]);
        return;
    }
    call.setString(str[0 .. index1] ~ str[(index2 + 1) .. $]);
}

private void _slice(GrCall call) {
    GrString str = call.getString(0);
    GrInt index1 = call.getInt(1);
    GrInt index2 = call.getInt(2);
    if (index1 < 0)
        index1 = (cast(GrInt) str.length) + index1;
    if (index2 < 0)
        index2 = (cast(GrInt) str.length) + index2;

    if (index2 < index1) {
        const GrInt temp = index1;
        index1 = index2;
        index2 = temp;
    }

    if (!str.length || index1 >= str.length || index2 < 0) {
        call.setString("");
        return;
    }

    if (index1 < 0)
        index1 = 0;
    if (index2 >= str.length)
        index2 = (cast(GrInt) str.length - 1);

    if (index1 == 0 && (index2 + 1) == str.length) {
        call.setString(str);
        return;
    }
    call.setString(str[index1 .. index2 + 1]);
}

private void _reverse(GrCall call) {
    import std.algorithm.mutation : reverse;

    call.setString(call.getString(0).dup.reverse);
}

private void _insert(GrCall call) {
    GrString str = call.getString(0);
    GrInt index = call.getInt(1);
    GrString value = call.getString(2);
    if (index < 0)
        index = (cast(GrInt) str.length) + index;
    if (!str.length || index >= str.length || index < 0) {
        call.raise("IndexError");
        return;
    }
    if (index + 1 == str.length) {
        call.setString(str[0 .. index] ~ value ~ str[$ - 1]);
        return;
    }
    if (index == 0) {
        call.setString(value ~ str);
        return;
    }
    call.setString(str[0 .. index] ~ value ~ str[index .. $]);
}

private void _findFirst(GrCall call) {
    GrString str = call.getString(0);
    GrString value = call.getString(1);
    const GrInt result = cast(GrInt) str.indexOf(value);
    if (result < 0) {
        call.setNull();
        return;
    }
    call.setInt(result);
}

private void _findLast(GrCall call) {
    GrString str = call.getString(0);
    GrString value = call.getString(1);
    const GrInt result = cast(GrInt) str.lastIndexOf(value);
    if (result < 0) {
        call.setNull();
        return;
    }
    call.setInt(result);
}

private void _has(GrCall call) {
    GrString str = call.getString(0);
    GrString value = call.getString(1);
    call.setBool(str.indexOf(value) != -1);
}

private final class StringIterator {
    GrString value;
    size_t index;
}

private void _each(GrCall call) {
    StringIterator iter = new StringIterator;
    iter.value = call.getString(0);
    call.setForeign(iter);
}

private void _next(GrCall call) {
    StringIterator iter = call.getForeign!(StringIterator)(0);
    if (iter.index >= iter.value.length) {
        call.setNull();
        return;
    }
    call.setString(to!GrString(iter.value[iter.index]));
    iter.index++;
}
