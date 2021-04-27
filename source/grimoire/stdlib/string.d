/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.string;

import std.string;
import std.conv : to;
import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibString(GrLibrary library) {
    library.addPrimitive(&_empty, "empty?", ["str"], [grString], [grBool]);
    library.addPrimitive(&_unshift, "unshift", ["str", "value"], [grString, grString], [
            grString
            ]);
    library.addPrimitive(&_push, "push", ["str", "value"], [grString, grString], [
            grString
            ]);
    library.addPrimitive(&_shift, "shift", ["str"], [grString], [grString]);
    library.addPrimitive(&_pop, "pop", ["str"], [grString], [grString]);
    library.addPrimitive(&_shift1, "shift", ["str", "size"], [grString, grInt], [
            grString
            ]);
    library.addPrimitive(&_pop1, "pop", ["str", "size"], [grString, grInt], [
            grString
            ]);
    library.addPrimitive(&_first, "first", ["str"], [grString], [grString]);
    library.addPrimitive(&_last, "last", ["str"], [grString], [grString]);
    library.addPrimitive(&_remove, "remove", ["str", "index"], [grString, grInt], [grString]);
    library.addPrimitive(&_remove2, "remove", ["str", "index1", "index2"], [grString, grInt, grInt], [grString]);
    library.addPrimitive(&_slice, "slice", ["str", "index1", "index2"], [grString, grInt, grInt], [grString]);
    library.addPrimitive(&_reverse, "reverse", ["str"], [grString], [grString]);
    library.addPrimitive(&_insert, "insert", ["str", "index", "value"], [grString, grInt, grString], [grString]);
    library.addPrimitive(&_findFirst, "findFirst", ["str", "value"], [grString, grString], [grInt]);
    library.addPrimitive(&_findLast, "findLast", ["str", "value"], [grString, grString], [grInt]);
    library.addPrimitive(&_has, "has?", ["str", "value"], [grString, grString], [grBool]);
}

private void _empty(GrCall call) {
    call.setBool(call.getString("str").length == 0);
}

private void _unshift(GrCall call) {
    string str = call.getString("str");
    str = call.getString("value") ~ str;
    call.setString(str);
}

private void _push(GrCall call) {
    string str = call.getString("str");
    str ~= call.getString("value");
    call.setString(str);
}

private void _shift(GrCall call) {
    string str = call.getString("str");
    if (!str.length) {
        call.setString(str);
        return;
    }
    call.setString(str[1 .. $]);
}

private void _pop(GrCall call) {
    string str = call.getString("str");
    if (!str.length) {
        call.setString(str);
        return;
    }
    str.length--;
    call.setString(str);
}

private void _shift1(GrCall call) {
    string str = call.getString("str");
    int size = call.getInt("size");
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
    string str = call.getString("str");
    int size = call.getInt("size");
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
    string str = call.getString("str");
    if (!str.length) {
        call.raise("IndexError");
        return;
    }
    call.setString(to!string(str[0]));
}

private void _last(GrCall call) {
    string str = call.getString("str");
    if (!str.length) {
        call.raise("IndexError");
        return;
    }
    call.setString(to!string(str[$ - 1]));
}

private void _remove(GrCall call) {
    string str = call.getString("str");
    int index = call.getInt("index");
    if (index < 0)
        index = (cast(int) str.length) + index;
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
    string str = call.getString("str");
    int index1 = call.getInt("index1");
    int index2 = call.getInt("index2");
    if (index1 < 0)
        index1 = (cast(int) str.length) + index1;
    if (index2 < 0)
        index2 = (cast(int) str.length) + index2;

    if (index2 < index1) {
        const int temp = index1;
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
        index2 = (cast(int) str.length) - 1;

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
    string str = call.getString("str");
    int index1 = call.getInt("index1");
    int index2 = call.getInt("index2");
    if (index1 < 0)
        index1 = (cast(int) str.length) + index1;
    if (index2 < 0)
        index2 = (cast(int) str.length) + index2;

    if (index2 < index1) {
        const int temp = index1;
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
        index2 = (cast(int) str.length - 1);

    if (index1 == 0 && (index2 + 1) == str.length) {
        call.setString(str);
        return;
    }
    call.setString(str[index1 .. index2 + 1]);
}

private void _reverse(GrCall call) {
    import std.algorithm.mutation : reverse;
    call.setString(call.getString("str").dup.reverse);
}

private void _insert(GrCall call) {
    string str = call.getString("str");
    int index = call.getInt("index");
    string value = call.getString("value");
    if (index < 0)
        index = (cast(int) str.length) + index;
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
    string str = call.getString("str");
    string value = call.getString("value");
    call.setInt(cast(int) str.indexOf(value));
}

private void _findLast(GrCall call) {
    string str = call.getString("str");
    string value = call.getString("value");
    call.setInt(cast(int) str.lastIndexOf(value));
}

private void _has(GrCall call) {
    string str = call.getString("str");
    string value = call.getString("value");
    call.setBool(str.indexOf(value) != -1);
}