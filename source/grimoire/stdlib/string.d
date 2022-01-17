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

package(grimoire.stdlib) void grLoadStdLibString(GrLibrary library, GrLocale locale) {
    string stringIterSymbol, emptySymbol, hasSymbol, removeSymbol;
    string unshiftSymbol, pushSymbol, shiftSymbol, popSymbol, firstSymbol, lastSymbol, sliceSymbol;
    string reverseSymbol, insertSymbol, findFirstSymbol, findLastSymbol, eachSymbol, nextSymbol;
    final switch (locale) with (GrLocale) {
    case en_US:
        stringIterSymbol = "IString";
        emptySymbol = "empty?";
        unshiftSymbol = "unshift";
        pushSymbol = "push";
        shiftSymbol = "shift";
        popSymbol = "pop";
        firstSymbol = "first";
        lastSymbol = "last";
        removeSymbol = "remove";
        sliceSymbol = "slice";
        reverseSymbol = "reverse";
        insertSymbol = "insert";
        eachSymbol = "each";
        nextSymbol = "next";
        findFirstSymbol = "find_first";
        findLastSymbol = "find_last";
        hasSymbol = "has?";
        break;
    case fr_FR:
        stringIterSymbol = "IString";
        emptySymbol = "vide?";
        unshiftSymbol = "enfile";
        pushSymbol = "empile";
        shiftSymbol = "défile";
        popSymbol = "dépile";
        firstSymbol = "premier";
        lastSymbol = "dernier";
        removeSymbol = "retire";
        sliceSymbol = "découpe";
        reverseSymbol = "inverse";
        insertSymbol = "insère";
        eachSymbol = "chaque";
        nextSymbol = "suivant";
        findFirstSymbol = "trouve_premier";
        findLastSymbol = "trouve_dernier";
        hasSymbol = "a?";
        break;
    }

    library.addPrimitive(&_empty, emptySymbol, [grString], [grBool]);
    library.addPrimitive(&_unshift, unshiftSymbol, [grString, grString], [grString]);
    library.addPrimitive(&_push, pushSymbol, [grString, grString], [grString]);
    library.addPrimitive(&_shift, shiftSymbol, [grString], [grString]);
    library.addPrimitive(&_pop, popSymbol, [grString], [grString]);
    library.addPrimitive(&_shift1, shiftSymbol, [grString, grInt], [grString]);
    library.addPrimitive(&_pop1, popSymbol, [grString, grInt], [grString]);
    library.addPrimitive(&_first, firstSymbol, [grString], [grString]);
    library.addPrimitive(&_last, lastSymbol, [grString], [grString]);
    library.addPrimitive(&_remove, removeSymbol, [grString, grInt], [grString]);
    library.addPrimitive(&_remove2, removeSymbol, [grString, grInt, grInt], [
            grString
            ]);
    library.addPrimitive(&_slice, sliceSymbol, [grString, grInt, grInt], [grString]);
    library.addPrimitive(&_reverse, reverseSymbol, [grString], [grString]);
    library.addPrimitive(&_insert, insertSymbol, [grString, grInt, grString], [
            grString
            ]);
    library.addPrimitive(&_findFirst, findFirstSymbol, [grString, grString], [grInt]);
    library.addPrimitive(&_findLast, findLastSymbol, [grString, grString], [grInt]);
    library.addPrimitive(&_has, hasSymbol, [grString, grString], [grBool]);

    GrType stringIterType = library.addForeign(stringIterSymbol);
    library.addPrimitive(&_each, eachSymbol, [grString], [stringIterType]);
    library.addPrimitive(&_next, nextSymbol, [stringIterType], [grBool, grString]);
}

private void _empty(GrCall call) {
    call.setBool(call.getString(0).length == 0);
}

private void _unshift(GrCall call) {
    GrString str = call.getString(0);
    str = call.getString(1) ~ str;
    call.setString(str);
}

private void _push(GrCall call) {
    GrString str = call.getString(0);
    str ~= call.getString(1);
    call.setString(str);
}

private void _shift(GrCall call) {
    GrString str = call.getString(0);
    if (!str.length) {
        call.setString(str);
        return;
    }
    call.setString(str[1 .. $]);
}

private void _pop(GrCall call) {
    GrString str = call.getString(0);
    if (!str.length) {
        call.setString(str);
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
        call.raise("IndexError");
        return;
    }
    call.setString(to!GrString(str[0]));
}

private void _last(GrCall call) {
    GrString str = call.getString(0);
    if (!str.length) {
        call.raise("IndexError");
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
    call.setInt(cast(GrInt) str.indexOf(value));
}

private void _findLast(GrCall call) {
    GrString str = call.getString(0);
    GrString value = call.getString(1);
    call.setInt(cast(GrInt) str.lastIndexOf(value));
}

private void _has(GrCall call) {
    GrString str = call.getString(0);
    GrString value = call.getString(1);
    call.setBool(str.indexOf(value) != -1);
}

private final class StringIter {
    GrString value;
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
        call.raise(_paramError);
        return;
    }
    if (iter.index >= iter.value.length) {
        call.setBool(false);
        call.setString("");
        return;
    }
    call.setBool(true);
    call.setString(to!GrString(iter.value[iter.index]));
    iter.index++;
}
