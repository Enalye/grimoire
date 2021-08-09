/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.array;

import std.range;
import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibArray(GrLibrary library) {
    library.addForeign("ArrayIter", ["T"]);

    static foreach (t; ["Int", "Float", "String", "Object"]) {
        mixin("GrType any" ~ t ~ "Array = grAny(\"A\", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set(\"T\", subType);
                return grIsKindOf" ~ t
                ~ "(subType.baseType);
            });
            library.addPrimitive(&_copy_!\"" ~ t ~ "\", \"copy\", [any" ~ t ~ "Array], [grAny(\"A\")]);
            library.addPrimitive(&_size_!\""
                ~ t ~ "\", \"size\", [any" ~ t ~ "Array], [grInt]);
            library.addPrimitive(&_resize_!\"" ~ t ~ "\", \"resize\", [
                any" ~ t ~ "Array, grInt
            ], [grAny(\"A\")]);
            library.addPrimitive(&_empty_!\"" ~ t
                ~ "\", \"empty?\", [
                any" ~ t ~ "Array
            ], [grBool]);
            library.addPrimitive(&_fill_!\"" ~ t ~ "\", \"fill\", [
                any" ~ t
                ~ "Array, grAny(\"T\")
            ], [grAny(\"A\")]);
            library.addPrimitive(&_clear_!\"" ~ t ~ "\", \"clear\", [
                any" ~ t ~ "Array
            ], [grAny(\"A\")]);
            library.addPrimitive(&_unshift_!\"" ~ t
                ~ "\", \"unshift\", [
                    any" ~ t ~ "Array, grAny(\"T\")
                ], [grAny(\"A\")]);
            library.addPrimitive(&_push_!\"" ~ t ~ "\", \"push\", [
                    any" ~ t ~ "Array, grAny(\"T\")
                ], [grAny(\"A\")]);
            library.addPrimitive(&_shift_!\""
                ~ t ~ "\", \"shift\", [
                    any" ~ t ~ "Array
                ], [grAny(\"T\")]);
            library.addPrimitive(&_pop_!\"" ~ t ~ "\", \"pop\", [
                    any" ~ t ~ "Array
                ], [grAny(\"T\")]);
            library.addPrimitive(&_shift1_!\"" ~ t ~ "\", \"shift\", [
                    any"
                ~ t ~ "Array, grInt
                ], [grAny(\"A\")]);
            library.addPrimitive(&_pop1_!\"" ~ t ~ "\", \"pop\", [
                    any" ~ t ~ "Array, grInt
                ], [grAny(\"A\")]);
            library.addPrimitive(&_first_!\"" ~ t ~ "\", \"first\", [
                any" ~ t
                ~ "Array
            ], [grAny(\"T\")]);
            library.addPrimitive(&_last_!\"" ~ t ~ "\", \"last\", [
                    any" ~ t ~ "Array
                ], [grAny(\"T\")]);
            library.addPrimitive(&_remove_!\"" ~ t
                ~ "\", \"remove\", [
                    any" ~ t ~ "Array, grInt
                ], [grAny(\"A\")]);
            library.addPrimitive(&_remove2_!\"" ~ t ~ "\", \"remove\", [
                    any"
                ~ t ~ "Array, grInt, grInt
                ], [grAny(\"A\")]);
            library.addPrimitive(&_slice_!\"" ~ t ~ "\", \"slice!\", [
                    any" ~ t ~ "Array, grInt, grInt
                ], [grAny(\"A\")]);
            library.addPrimitive(&_slice_copy_!\"" ~ t ~ "\", \"slice\", [
                    any" ~ t
                ~ "Array, grInt, grInt
                ], [grAny(\"A\")]);
            library.addPrimitive(&_reverse_!\"" ~ t ~ "\", \"reverse\", [
                    any" ~ t ~ "Array
                ], [grAny(\"A\")]);
            library.addPrimitive(&_insert_!\"" ~ t
                ~ "\", \"insert\", [
                    any" ~ t ~ "Array, grInt, grAny(\"T\")
                ], [grAny(\"A\")]);
            library.addPrimitive(&_each_!\"" ~ t ~ "\", \"each\", [
                    grAny(\"A\", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set(\"R\", grGetForeignType(\"ArrayIter\", [subType]));
                return grIsKindOf"
                ~ t ~ "(subType.baseType);
            })
                ], [grAny(\"R\")]);
            library.addPrimitive(&_next_!\"" ~ t ~ "\", \"next\", [
                    grAny(\"R\", (type, data) {
                if (type.baseType != GrBaseType.foreign)
                    return false;
                auto result = grUnmangleComposite(type.mangledType);
                if(result.signature.length != 1 || result.name != \"ArrayIter\")
                    return false;
                data.set(\"T\", result.signature[0]);
                return grIsKindOf" ~ t
                ~ "(result.signature[0].baseType);
                    })
                ], [grBool, grAny(\"T\")]);
            ");

        static if (t != "Object") {
            mixin("
            library.addPrimitive(&_sort_!\"" ~ t ~ "\", \"sort\", [
                    any" ~ t ~ "Array
                ], [grAny(\"A\")]);
            library.addPrimitive(&_findFirst_!\"" ~ t ~ "\", \"findFirst\", [
                    any" ~ t ~ "Array, grAny(\"T\")
                ], [grInt]);
            library.addPrimitive(&_findLast_!\"" ~ t
                    ~ "\", \"findLast\", [
                    any" ~ t ~ "Array, grAny(\"T\")
                ], [grInt]);
            library.addPrimitive(&_findLast_!\"" ~ t ~ "\", \"findLast\", [
                    any" ~ t
                    ~ "Array, grAny(\"T\")
                ], [grInt]);
            library.addPrimitive(&_has_!\"" ~ t
                    ~ "\", \"has?\", [
                    any" ~ t ~ "Array, grAny(\"T\")
                ], [grBool]);
                ");
        }
    }
}

private void _copy_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array copy = new Gr" ~ t ~ "Array;
        copy.data = call.get"
            ~ t ~ "Array(0).data.dup;
        call.set" ~ t ~ "Array(copy);");
}

private void _size_(string t)(GrCall call) {
    mixin("call.setInt(cast(int) call.get" ~ t ~ "Array(0).data.length);");
}

private void _resize_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    const int size = call.getInt(1);
    if (size < 0) {
        call.raise("ArgumentError");
        return;
    }
    static if (t == "Float") {
        if (size > array.data.length) {
            int index = cast(int) array.data.length;
            array.data.length = size;
            for (; index < array.data.length; ++index)
                array.data[index] = 0f;
        }
        else {
            array.data.length = size;
        }
    }
    else {
        array.data.length = size;
    }
    mixin("call.set" ~ t ~ "Array(array);");
}

private void _empty_(string t)(GrCall call) {
    mixin("const Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    call.setBool(array.data.empty);
}

private void _fill_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    static if (t == "Object") {
        void* value = call.getPtr(1);
    }
    else {
        mixin("auto value = call.get" ~ t ~ "(1);");
    }
    for (int index; index < array.data.length; ++index)
        array.data[index] = value;
    mixin("call.set" ~ t ~ "Array(array);");
}

private void _clear_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    array.data.length = 0;
    mixin("call.set" ~ t ~ "Array(array);");
}

private void _unshift_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    static if (t == "Object") {
        array.data = call.getPtr(1) ~ array.data;
    }
    else {
        mixin("array.data = call.get" ~ t ~ "(1) ~ array.data;");
    }
    mixin("call.set" ~ t ~ "Array(array);");
}

private void _push_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    static if (t == "Object") {
        array.data ~= call.getPtr(1);
    }
    else {
        mixin("array.data ~= call.get" ~ t ~ "(1);");
    }
    mixin("call.set" ~ t ~ "Array(array);");
}

private void _shift_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    if (!array.data.length) {
        call.raise("IndexError");
        return;
    }
    static if (t == "Object") {
        call.setPtr(array.data[0]);
    }
    else {
        mixin("call.set" ~ t ~ "(array.data[0]);");
    }
    array.data = array.data[1 .. $];
}

private void _pop_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    if (!array.data.length) {
        call.raise("IndexError");
        return;
    }
    static if (t == "Object") {
        call.setPtr(array.data[$ - 1]);
    }
    else {
        mixin("call.set" ~ t ~ "(array.data[$ - 1]);");
    }
    array.data.length--;
}

private void _shift1_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    int size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    if (array.data.length < size) {
        size = cast(int) array.data.length;
    }
    mixin("Gr" ~ t ~ "Array copy = new Gr" ~ t ~ "Array;");
    copy.data = array.data[0 .. size];
    array.data = array.data[size .. $];
    mixin("call.set" ~ t ~ "Array(copy);");
}

private void _pop1_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    int size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    if (array.data.length < size) {
        size = cast(int) array.data.length;
    }
    mixin("Gr" ~ t ~ "Array copy = new Gr" ~ t ~ "Array;");
    copy.data = array.data[$ - size .. $];
    array.data.length -= size;
    mixin("call.set" ~ t ~ "Array(copy);");
}

private void _first_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    if (!array.data.length) {
        call.raise("IndexError");
        return;
    }
    static if (t == "Object") {
        mixin("call.setPtr(array.data[0]);");
    }
    else {
        mixin("call.set" ~ t ~ "(array.data[0]);");
    }
}

private void _last_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    if (!array.data.length) {
        call.raise("IndexError");
        return;
    }
    static if (t == "Object") {
        mixin("call.setPtr(array.data[$ - 1]);");
    }
    else {
        mixin("call.set" ~ t ~ "(array.data[$ - 1]);");
    }
}

private void _remove_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    int index = call.getInt(1);
    if (index < 0)
        index = (cast(int) array.data.length) + index;
    if (!array.data.length || index >= array.data.length || index < 0) {
        mixin("call.set" ~ t ~ "Array(array);");
        return;
    }
    if (index + 1 == array.data.length) {
        array.data.length--;
        mixin("call.set" ~ t ~ "Array(array);");
        return;
    }
    if (index == 0) {
        array.data = array.data[1 .. $];
        mixin("call.set" ~ t ~ "Array(array);");
        return;
    }
    array.data = array.data[0 .. index] ~ array.data[index + 1 .. $];
    mixin("call.set" ~ t ~ "Array(array);");
}

private void _remove2_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    int index1 = call.getInt(1);
    int index2 = call.getInt(2);
    if (index1 < 0)
        index1 = (cast(int) array.data.length) + index1;
    if (index2 < 0)
        index2 = (cast(int) array.data.length) + index2;

    if (index2 < index1) {
        const int temp = index1;
        index1 = index2;
        index2 = temp;
    }

    if (!array.data.length || index1 >= array.data.length || index2 < 0) {
        mixin("call.set" ~ t ~ "Array(array);");
        return;
    }

    if (index1 < 0)
        index1 = 0;
    if (index2 >= array.data.length)
        index2 = (cast(int) array.data.length) - 1;

    if (index1 == 0 && (index2 + 1) == array.data.length) {
        array.data.length = 0;
        mixin("call.set" ~ t ~ "Array(array);");
        return;
    }
    if (index1 == 0) {
        array.data = array.data[(index2 + 1) .. $];
        mixin("call.set" ~ t ~ "Array(array);");
        return;
    }
    if ((index2 + 1) == array.data.length) {
        array.data = array.data[0 .. index1];
        mixin("call.set" ~ t ~ "Array(array);");
        return;
    }
    array.data = array.data[0 .. index1] ~ array.data[(index2 + 1) .. $];
    mixin("call.set" ~ t ~ "Array(array);");
}

private void _slice_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    int index1 = call.getInt(1);
    int index2 = call.getInt(2);
    if (index1 < 0)
        index1 = (cast(int) array.data.length) + index1;
    if (index2 < 0)
        index2 = (cast(int) array.data.length) + index2;

    if (index2 < index1) {
        const int temp = index1;
        index1 = index2;
        index2 = temp;
    }

    if (!array.data.length || index1 >= array.data.length || index2 < 0) {
        array.data.length = 0;
        mixin("call.set" ~ t ~ "Array(array);");
        return;
    }

    if (index1 < 0)
        index1 = 0;
    if (index2 >= array.data.length)
        index2 = (cast(int) array.data.length - 1);

    if (index1 == 0 && (index2 + 1) == array.data.length) {
        mixin("call.set" ~ t ~ "Array(array);");
        return;
    }
    array.data = array.data[index1 .. index2 + 1];
    mixin("call.set" ~ t ~ "Array(array);");
}

private void _slice_copy_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    mixin("Gr" ~ t ~ "Array copy = new Gr" ~ t ~ "Array;");
    int index1 = call.getInt(1);
    int index2 = call.getInt(2);
    if (index1 < 0)
        index1 = (cast(int) array.data.length) + index1;
    if (index2 < 0)
        index2 = (cast(int) array.data.length) + index2;

    if (index2 < index1) {
        const int temp = index1;
        index1 = index2;
        index2 = temp;
    }

    if (!array.data.length || index1 >= array.data.length || index2 < 0) {
        mixin("call.set" ~ t ~ "Array(copy);");
        return;
    }

    if (index1 < 0)
        index1 = 0;
    if (index2 >= array.data.length)
        index2 = (cast(int) array.data.length - 1);

    if (index1 == 0 && (index2 + 1) == array.data.length) {
        copy.data = array.data;
    }
    else {
        copy.data = array.data[index1 .. index2 + 1];
    }
    mixin("call.set" ~ t ~ "Array(copy);");
}

private void _reverse_(string t)(GrCall call) {
    import std.algorithm.mutation : reverse;

    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    array.data = array.data.reverse;
    mixin("call.set" ~ t ~ "Array(array);");
}

private void _insert_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    int index = call.getInt(1);
    static if (t == "Object") {
        void* value = call.getPtr(2);
    }
    else {
        mixin("auto value = call.get" ~ t ~ "(2);");
    }
    if (index < 0)
        index = (cast(int) array.data.length) + index;
    if (!array.data.length || index >= array.data.length || index < 0) {
        call.raise("IndexError");
        return;
    }
    if (index + 1 == array.data.length) {
        array.data = array.data[0 .. index] ~ value ~ array.data[$ - 1];
        mixin("call.set" ~ t ~ "Array(array);");
        return;
    }
    if (index == 0) {
        array.data = value ~ array.data;
        mixin("call.set" ~ t ~ "Array(array);");
        return;
    }
    array.data = array.data[0 .. index] ~ value ~ array.data[index .. $];
    mixin("call.set" ~ t ~ "Array(array);");
}

private void _sort_(string t)(GrCall call) {
    import std.algorithm.sorting : sort;

    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    array.data.sort();
    mixin("call.set" ~ t ~ "Array(array);");
}

private void _findFirst_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    mixin("auto value = call.get" ~ t ~ "(1);");
    for (int index; index < array.data.length; ++index) {
        if (array.data[index] == value) {
            call.setInt(index);
            return;
        }
    }
    call.setInt(-1);
}

private void _findLast_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    mixin("auto value = call.get" ~ t ~ "(1);");
    for (int index = (cast(int) array.data.length) - 1; index > 0; --index) {
        if (array.data[index] == value) {
            call.setInt(index);
            return;
        }
    }
    call.setInt(-1);
}

private void _has_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    mixin("auto value = call.get" ~ t ~ "(1);");
    for (int index; index < array.data.length; ++index) {
        if (array.data[index] == value) {
            call.setBool(true);
            return;
        }
    }
    call.setBool(false);
}

private class ArrayIter(T) {
    T array;
    size_t index;
}

private void _each_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    static if (t == "Int") {
        ArrayIter!(int[]) iter = new ArrayIter!(int[]);
    }
    else static if (t == "Float") {
        ArrayIter!(float[]) iter = new ArrayIter!(float[]);
    }
    else static if (t == "String") {
        ArrayIter!(string[]) iter = new ArrayIter!(string[]);
    }
    else static if (t == "Object") {
        ArrayIter!(void*[]) iter = new ArrayIter!(void*[]);
    }
    iter.array = array.data.dup;
    call.setForeign(iter);
}

private void _next_(string t)(GrCall call) {
    static if (t == "Int") {
        ArrayIter!(int[]) iter = call.getForeign!(ArrayIter!(int[]))(0);
    }
    else static if (t == "Float") {
        ArrayIter!(float[]) iter = call.getForeign!(ArrayIter!(float[]))(0);
    }
    else static if (t == "String") {
        ArrayIter!(string[]) iter = call.getForeign!(ArrayIter!(string[]))(0);
    }
    else static if (t == "Object") {
        ArrayIter!(void*[]) iter = call.getForeign!(ArrayIter!(void*[]))(0);
    }
    if (!iter) {
        call.raise("NullError");
        return;
    }
    if (iter.index >= iter.array.length) {
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
        call.setInt(iter.array[iter.index]);
    }
    else static if (t == "Float") {
        call.setFloat(iter.array[iter.index]);
    }
    else static if (t == "String") {
        call.setString(iter.array[iter.index]);
    }
    else static if (t == "Object") {
        call.setPtr(iter.array[iter.index]);
    }
    iter.index++;
}
