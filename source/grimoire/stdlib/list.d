/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.list;

import std.range;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibList(GrLibrary library, GrLocale locale) {
    library.addForeign("ListIter", ["T"]);

    static foreach (t; ["Int", "Float", "String", "Object"]) {
        mixin("GrType any" ~ t ~ "List = grAny(\"A\", (type, data) {
                if (type.base != GrType.Base.list_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set(\"T\", subType);
                return grIsKindOf" ~ t ~ "(subType.base);
            });
            library.addPrimitive(&_copy_!\"" ~ t ~ "\", \"copy\", [any"
                ~ t ~ "List], [grAny(\"A\")]);
            library.addPrimitive(&_size_!\"" ~ t ~ "\", \"size\", [any" ~ t ~ "List], [grInt]);
            library.addPrimitive(&_resize_!\"" ~ t ~ "\", \"resize\", [
                any"
                ~ t ~ "List, grInt
            ], [grAny(\"A\")]);
            library.addPrimitive(&_empty_!\"" ~ t ~ "\", \"empty?\", [
                any" ~ t ~ "List
            ], [grBool]);
            library.addPrimitive(&_fill_!\"" ~ t ~ "\", \"fill\", [
                any" ~ t
                ~ "List, grAny(\"T\")
            ], [grAny(\"A\")]);
            library.addPrimitive(&_clear_!\"" ~ t ~ "\", \"clear\", [
                any" ~ t
                ~ "List
            ], [grAny(\"A\")]);
            library.addPrimitive(&_unshift_!\"" ~ t ~ "\", \"unshift\", [
                    any" ~ t ~ "List, grAny(\"T\")
                ], [grAny(\"A\")]);
            library.addPrimitive(&_push_!\"" ~ t
                ~ "\", \"push\", [
                    any" ~ t ~ "List, grAny(\"T\")
                ], [grAny(\"A\")]);
            library.addPrimitive(&_shift_!\"" ~ t ~ "\", \"shift\", [
                    any" ~ t ~ "List
                ], [grAny(\"T\")]);
            library.addPrimitive(&_pop_!\"" ~ t
                ~ "\", \"pop\", [
                    any" ~ t ~ "List
                ], [grAny(\"T\")]);
            library.addPrimitive(&_shift1_!\"" ~ t ~ "\", \"shift\", [
                    any" ~ t ~ "List, grInt
                ], [grAny(\"A\")]);
            library.addPrimitive(&_pop1_!\"" ~ t ~ "\", \"pop\", [
                    any" ~ t
                ~ "List, grInt
                ], [grAny(\"A\")]);
            library.addPrimitive(&_first_!\"" ~ t ~ "\", \"first\", [
                any" ~ t ~ "List
            ], [grAny(\"T\")]);
            library.addPrimitive(&_last_!\"" ~ t ~ "\", \"last\", [
                    any"
                ~ t ~ "List
                ], [grAny(\"T\")]);
            library.addPrimitive(&_remove_!\"" ~ t ~ "\", \"remove\", [
                    any" ~ t ~ "List, grInt
                ], [grAny(\"A\")]);
            library.addPrimitive(&_remove2_!\"" ~ t ~ "\", \"remove\", [
                    any" ~ t ~ "List, grInt, grInt
                ], [grAny(\"A\")]);
            library.addPrimitive(&_slice_!\""
                ~ t ~ "\", \"slice!\", [
                    any" ~ t ~ "List, grInt, grInt
                ], [grAny(\"A\")]);
            library.addPrimitive(&_slice_copy_!\"" ~ t ~ "\", \"slice\", [
                    any" ~ t ~ "List, grInt, grInt
                ], [grAny(\"A\")]);
            library.addPrimitive(&_reverse_!\"" ~ t
                ~ "\", \"reverse\", [
                    any" ~ t ~ "List
                ], [grAny(\"A\")]);
            library.addPrimitive(&_insert_!\"" ~ t ~ "\", \"insert\", [
                    any" ~ t ~ "List, grInt, grAny(\"T\")
                ], [grAny(\"A\")]);
            library.addPrimitive(&_each_!\"" ~ t
                ~ "\", \"each\", [
                    grAny(\"A\", (type, data) {
                if (type.base != GrType.Base.list_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set(\"R\", grGetForeignType(\"ListIter\", [subType]));
                return grIsKindOf" ~ t ~ "(subType.base);
            })
                ], [grAny(\"R\")]);
            library.addPrimitive(&_next_!\""
                ~ t ~ "\", \"next\", [
                    grAny(\"R\", (type, data) {
                if (type.base != GrType.Base.foreign)
                    return false;
                auto result = grUnmangleComposite(type.mangledType);
                if(result.signature.length != 1 || result.name != \"ListIter\")
                    return false;
                data.set(\"T\", result.signature[0]);
                return grIsKindOf" ~ t ~ "(result.signature[0].base);
                    })
                ], [grBool, grAny(\"T\")]);
            ");

        static if (t != "Object") {
            mixin("
            library.addPrimitive(&_sort_!\"" ~ t ~ "\", \"sort\", [
                    any" ~ t ~ "List
                ], [grAny(\"A\")]);
            library.addPrimitive(&_findFirst_!\"" ~ t ~ "\", \"findFirst\", [
                    any" ~ t ~ "List, grAny(\"T\")
                ], [grInt]);
            library.addPrimitive(&_findLast_!\"" ~ t
                    ~ "\", \"findLast\", [
                    any" ~ t ~ "List, grAny(\"T\")
                ], [grInt]);
            library.addPrimitive(&_findLast_!\"" ~ t ~ "\", \"findLast\", [
                    any" ~ t
                    ~ "List, grAny(\"T\")
                ], [grInt]);
            library.addPrimitive(&_has_!\"" ~ t
                    ~ "\", \"has?\", [
                    any" ~ t ~ "List, grAny(\"T\")
                ], [grBool]);
                ");
        }
    }
}

private void _copy_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List copy = new Gr" ~ t ~ "List;
        copy.data = call.get"
            ~ t ~ "List(0).data.dup;
        call.set" ~ t ~ "List(copy);");
}

private void _size_(string t)(GrCall call) {
    mixin("call.setInt(cast(GrInt) call.get" ~ t ~ "List(0).data.length);");
}

private void _resize_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    const GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("ArgumentError");
        return;
    }
    static if (t == "Float") {
        if (size > list.data.length) {
            GrInt index = cast(GrInt) list.data.length;
            list.data.length = size;
            for (; index < list.data.length; ++index)
                list.data[index] = 0f;
        }
        else {
            list.data.length = size;
        }
    }
    else {
        list.data.length = size;
    }
    mixin("call.set" ~ t ~ "List(list);");
}

private void _empty_(string t)(GrCall call) {
    mixin("const Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    call.setBool(list.data.empty);
}

private void _fill_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    static if (t == "Object") {
        GrPtr value = call.getPtr(1);
    }
    else {
        mixin("auto value = call.get" ~ t ~ "(1);");
    }
    for (size_t index; index < list.data.length; ++index)
        list.data[index] = value;
    mixin("call.set" ~ t ~ "List(list);");
}

private void _clear_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    list.data.length = 0;
    mixin("call.set" ~ t ~ "List(list);");
}

private void _unshift_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    static if (t == "Object") {
        list.data = call.getPtr(1) ~ list.data;
    }
    else {
        mixin("list.data = call.get" ~ t ~ "(1) ~ list.data;");
    }
    mixin("call.set" ~ t ~ "List(list);");
}

private void _push_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    static if (t == "Object") {
        list.data ~= call.getPtr(1);
    }
    else {
        mixin("list.data ~= call.get" ~ t ~ "(1);");
    }
    mixin("call.set" ~ t ~ "List(list);");
}

private void _shift_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    if (!list.data.length) {
        call.raise("IndexError");
        return;
    }
    static if (t == "Object") {
        call.setPtr(list.data[0]);
    }
    else {
        mixin("call.set" ~ t ~ "(list.data[0]);");
    }
    list.data = list.data[1 .. $];
}

private void _pop_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    if (!list.data.length) {
        call.raise("IndexError");
        return;
    }
    static if (t == "Object") {
        call.setPtr(list.data[$ - 1]);
    }
    else {
        mixin("call.set" ~ t ~ "(list.data[$ - 1]);");
    }
    list.data.length--;
}

private void _shift1_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    if (list.data.length < size) {
        size = cast(GrInt) list.data.length;
    }
    mixin("Gr" ~ t ~ "List copy = new Gr" ~ t ~ "List;");
    copy.data = list.data[0 .. size];
    list.data = list.data[size .. $];
    mixin("call.set" ~ t ~ "List(copy);");
}

private void _pop1_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    if (list.data.length < size) {
        size = cast(GrInt) list.data.length;
    }
    mixin("Gr" ~ t ~ "List copy = new Gr" ~ t ~ "List;");
    copy.data = list.data[$ - size .. $];
    list.data.length -= size;
    mixin("call.set" ~ t ~ "List(copy);");
}

private void _first_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    if (!list.data.length) {
        call.raise("IndexError");
        return;
    }
    static if (t == "Object") {
        mixin("call.setPtr(list.data[0]);");
    }
    else {
        mixin("call.set" ~ t ~ "(list.data[0]);");
    }
}

private void _last_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    if (!list.data.length) {
        call.raise("IndexError");
        return;
    }
    static if (t == "Object") {
        mixin("call.setPtr(list.data[$ - 1]);");
    }
    else {
        mixin("call.set" ~ t ~ "(list.data[$ - 1]);");
    }
}

private void _remove_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    GrInt index = call.getInt(1);
    if (index < 0)
        index = (cast(GrInt) list.data.length) + index;
    if (!list.data.length || index >= list.data.length || index < 0) {
        mixin("call.set" ~ t ~ "List(list);");
        return;
    }
    if (index + 1 == list.data.length) {
        list.data.length--;
        mixin("call.set" ~ t ~ "List(list);");
        return;
    }
    if (index == 0) {
        list.data = list.data[1 .. $];
        mixin("call.set" ~ t ~ "List(list);");
        return;
    }
    list.data = list.data[0 .. index] ~ list.data[index + 1 .. $];
    mixin("call.set" ~ t ~ "List(list);");
}

private void _remove2_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    GrInt index1 = call.getInt(1);
    GrInt index2 = call.getInt(2);
    if (index1 < 0)
        index1 = (cast(GrInt) list.data.length) + index1;
    if (index2 < 0)
        index2 = (cast(GrInt) list.data.length) + index2;

    if (index2 < index1) {
        const GrInt temp = index1;
        index1 = index2;
        index2 = temp;
    }

    if (!list.data.length || index1 >= list.data.length || index2 < 0) {
        mixin("call.set" ~ t ~ "List(list);");
        return;
    }

    if (index1 < 0)
        index1 = 0;
    if (index2 >= list.data.length)
        index2 = (cast(GrInt) list.data.length) - 1;

    if (index1 == 0 && (index2 + 1) == list.data.length) {
        list.data.length = 0;
        mixin("call.set" ~ t ~ "List(list);");
        return;
    }
    if (index1 == 0) {
        list.data = list.data[(index2 + 1) .. $];
        mixin("call.set" ~ t ~ "List(list);");
        return;
    }
    if ((index2 + 1) == list.data.length) {
        list.data = list.data[0 .. index1];
        mixin("call.set" ~ t ~ "List(list);");
        return;
    }
    list.data = list.data[0 .. index1] ~ list.data[(index2 + 1) .. $];
    mixin("call.set" ~ t ~ "List(list);");
}

private void _slice_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    GrInt index1 = call.getInt(1);
    GrInt index2 = call.getInt(2);
    if (index1 < 0)
        index1 = (cast(GrInt) list.data.length) + index1;
    if (index2 < 0)
        index2 = (cast(GrInt) list.data.length) + index2;

    if (index2 < index1) {
        const GrInt temp = index1;
        index1 = index2;
        index2 = temp;
    }

    if (!list.data.length || index1 >= list.data.length || index2 < 0) {
        list.data.length = 0;
        mixin("call.set" ~ t ~ "List(list);");
        return;
    }

    if (index1 < 0)
        index1 = 0;
    if (index2 >= list.data.length)
        index2 = (cast(GrInt) list.data.length - 1);

    if (index1 == 0 && (index2 + 1) == list.data.length) {
        mixin("call.set" ~ t ~ "List(list);");
        return;
    }
    list.data = list.data[index1 .. index2 + 1];
    mixin("call.set" ~ t ~ "List(list);");
}

private void _slice_copy_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    mixin("Gr" ~ t ~ "List copy = new Gr" ~ t ~ "List;");
    GrInt index1 = call.getInt(1);
    GrInt index2 = call.getInt(2);
    if (index1 < 0)
        index1 = (cast(GrInt) list.data.length) + index1;
    if (index2 < 0)
        index2 = (cast(GrInt) list.data.length) + index2;

    if (index2 < index1) {
        const GrInt temp = index1;
        index1 = index2;
        index2 = temp;
    }

    if (!list.data.length || index1 >= list.data.length || index2 < 0) {
        mixin("call.set" ~ t ~ "List(copy);");
        return;
    }

    if (index1 < 0)
        index1 = 0;
    if (index2 >= list.data.length)
        index2 = (cast(GrInt) list.data.length - 1);

    if (index1 == 0 && (index2 + 1) == list.data.length) {
        copy.data = list.data;
    }
    else {
        copy.data = list.data[index1 .. index2 + 1];
    }
    mixin("call.set" ~ t ~ "List(copy);");
}

private void _reverse_(string t)(GrCall call) {
    import std.algorithm.mutation : reverse;

    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    list.data = list.data.reverse;
    mixin("call.set" ~ t ~ "List(list);");
}

private void _insert_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    GrInt index = call.getInt(1);
    static if (t == "Object") {
        GrPtr value = call.getPtr(2);
    }
    else {
        mixin("auto value = call.get" ~ t ~ "(2);");
    }
    if (index < 0)
        index = (cast(GrInt) list.data.length) + index;
    if (!list.data.length || index >= list.data.length || index < 0) {
        call.raise("IndexError");
        return;
    }
    if (index + 1 == list.data.length) {
        list.data = list.data[0 .. index] ~ value ~ list.data[$ - 1];
        mixin("call.set" ~ t ~ "List(list);");
        return;
    }
    if (index == 0) {
        list.data = value ~ list.data;
        mixin("call.set" ~ t ~ "List(list);");
        return;
    }
    list.data = list.data[0 .. index] ~ value ~ list.data[index .. $];
    mixin("call.set" ~ t ~ "List(list);");
}

private void _sort_(string t)(GrCall call) {
    import std.algorithm.sorting : sort;

    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    list.data.sort();
    mixin("call.set" ~ t ~ "List(list);");
}

private void _findFirst_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    mixin("auto value = call.get" ~ t ~ "(1);");
    for (GrInt index; index < list.data.length; ++index) {
        if (list.data[index] == value) {
            call.setInt(index);
            return;
        }
    }
    call.setInt(-1);
}

private void _findLast_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    mixin("auto value = call.get" ~ t ~ "(1);");
    for (GrInt index = (cast(GrInt) list.data.length) - 1; index > 0; --index) {
        if (list.data[index] == value) {
            call.setInt(index);
            return;
        }
    }
    call.setInt(-1);
}

private void _has_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    mixin("auto value = call.get" ~ t ~ "(1);");
    for (GrInt index; index < list.data.length; ++index) {
        if (list.data[index] == value) {
            call.setBool(true);
            return;
        }
    }
    call.setBool(false);
}

private final class ListIter(T) {
    T[] list;
    size_t index;
}

private void _each_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "List list = call.get" ~ t ~ "List(0);");
    static if (t == "Int") {
        ListIter!(GrInt) iter = new ListIter!(GrInt);
    }
    else static if (t == "Float") {
        ListIter!(GrFloat) iter = new ListIter!(GrFloat);
    }
    else static if (t == "String") {
        ListIter!(GrString) iter = new ListIter!(GrString);
    }
    else static if (t == "Object") {
        ListIter!(GrPtr) iter = new ListIter!(GrPtr);
    }
    iter.list = list.data.dup;
    call.setForeign(iter);
}

private void _next_(string t)(GrCall call) {
    static if (t == "Int") {
        ListIter!(GrInt) iter = call.getForeign!(ListIter!(GrInt))(0);
    }
    else static if (t == "Float") {
        ListIter!(GrFloat) iter = call.getForeign!(ListIter!(GrFloat))(0);
    }
    else static if (t == "String") {
        ListIter!(GrString) iter = call.getForeign!(ListIter!(GrString))(0);
    }
    else static if (t == "Object") {
        ListIter!(GrPtr) iter = call.getForeign!(ListIter!(GrPtr))(0);
    }
    if (!iter) {
        call.raise("NullError");
        return;
    }
    if (iter.index >= iter.list.length) {
        call.setBool(false);
        static if (t == "Int") {
            call.setInt(0);
        }
        else static if (t == "Float") {
            call.setFloat(0f);
        }
        else static if (t == "String") {
            call.setString("");
        }
        else static if (t == "Object") {
            call.setPtr(null);
        }
        return;
    }
    call.setBool(true);
    static if (t == "Int") {
        call.setInt(iter.list[iter.index]);
    }
    else static if (t == "Float") {
        call.setFloat(iter.list[iter.index]);
    }
    else static if (t == "String") {
        call.setString(iter.list[iter.index]);
    }
    else static if (t == "Object") {
        call.setPtr(iter.list[iter.index]);
    }
    iter.index++;
}
