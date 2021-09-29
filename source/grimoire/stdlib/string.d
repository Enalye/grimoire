/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.string;

import std.string;
import std.conv : to;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibString(GrLibrary library) {
    library.addPrimitive(&_empty, "empty?", [grString], [grBool]);
    library.addPrimitive(&_unshift, "unshift", [grString, grString], [grString]);
    library.addPrimitive(&_push, "push", [grString, grString], [grString]);
    library.addPrimitive(&_shift, "shift", [grString], [grString]);
    library.addPrimitive(&_pop, "pop", [grString], [grString]);
    library.addPrimitive(&_shift1, "shift", [grString, grInt], [grString]);
    library.addPrimitive(&_pop1, "pop", [grString, grInt], [grString]);
    library.addPrimitive(&_first, "first", [grString], [grString]);
    library.addPrimitive(&_last, "last", [grString], [grString]);
    library.addPrimitive(&_remove, "remove", [grString, grInt], [grString]);
    library.addPrimitive(&_remove2, "remove", [grString, grInt, grInt], [
            grString
            ]);
    library.addPrimitive(&_slice, "slice", [grString, grInt, grInt], [grString]);
    library.addPrimitive(&_reverse, "reverse", [grString], [grString]);
    library.addPrimitive(&_insert, "insert", [grString, grInt, grString], [
            grString
            ]);
    library.addPrimitive(&_findFirst, "findFirst", [grString, grString], [grInt]);
    library.addPrimitive(&_findLast, "findLast", [grString, grString], [grInt]);
    library.addPrimitive(&_has, "has?", [grString, grString], [grBool]);

    GrType stringIterType = library.addForeign("StringIter");
    library.addPrimitive(&_each, "each", [grString], [stringIterType]);
    library.addPrimitive(&_next, "next", [stringIterType], [grBool, grString]);
}

private void _empty(GrCall call) {
    call.setBool(call.getString(0).length == 0);
}

private void _unshift(GrCall call) {
    string str = call.getString(0);
    str = call.getString(1) ~ str;
    call.setString(str);
}

private void _push(GrCall call) {
    string str = call.getString(0);
    str ~= call.getString(1);
    call.setString(str);
}

private void _shift(GrCall call) {
    string str = call.getString(0);
    if (!str.length) {
        call.setString(str);
        return;
    }
    call.setString(str[1 .. $]);
}

private void _pop(GrCall call) {
    string str = call.getString(0);
    if (!str.length) {
        call.setString(str);
        return;
    }
    str.length--;
    call.setString(str);
}

private void _shift1(GrCall call) {
    string str = call.getString(0);
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
    string str = call.getString(0);
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
    string str = call.getString(0);
    if (!str.length) {
        call.raise("IndexError");
        return;
    }
    call.setString(to!string(str[0]));
}

private void _last(GrCall call) {
    string str = call.getString(0);
    if (!str.length) {
        call.raise("IndexError");
        return;
    }
    call.setString(to!string(str[$ - 1]));
}

private void _remove(GrCall call) {
    string str = call.getString(0);
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
    string str = call.getString(0);
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
    string str = call.getString(0);
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
    string str = call.getString(0);
    GrInt index = call.getInt(1);
    string value = call.getString(2);
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
    string str = call.getString(0);
    string value = call.getString(1);
    call.setInt(cast(GrInt) str.indexOf(value));
}

private void _findLast(GrCall call) {
    string str = call.getString(0);
    string value = call.getString(1);
    call.setInt(cast(GrInt) str.lastIndexOf(value));
}

private void _has(GrCall call) {
    string str = call.getString(0);
    string value = call.getString(1);
    call.setBool(str.indexOf(value) != -1);
}

private final class StringIter {
    string value;
    size_t index;
}

private void _each(GrCall call) {
    StringIter iter = new StringIter;
    iter.value = call.getString(0);
    call.setForeign(iter);
}

private void _next(GrCall call) {
    StringIter iter = call.getForeign!(StringIter)(0);
    if (!iter) {
        call.raise("NullError");
        return;
    }
    if (iter.index >= iter.value.length) {
        call.setBool(false);
        call.setString("");
        return;
    }
    call.setBool(true);
    call.setString(to!string(iter.value[iter.index]));
    iter.index++;
}
