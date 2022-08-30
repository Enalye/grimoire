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
    /*library.addForeign("ArrayIterator", ["T"]);

    static foreach (t; ["Int", "Real", "String", "Object"]) {
        mixin("
            GrType " ~ t ~ "ValueType = grAny(\"T\");
            GrType pure" ~ t ~ "ValueType = grAny(\"T\", true);
            GrType " ~ t ~ "ArrayType = grArray(" ~ t ~ "ValueType);
            GrType pure" ~ t ~ "ArrayType = grArray(" ~ t ~ "ValueType, true);
            GrType " ~ t ~ "IteratorType = grGetForeignType(\"ArrayIterator\", [" ~
                t ~ "ValueType]);
            static if(t == \"Object\") {
                GrConstraint " ~ t ~ "Constraint = grConstraint(\"Register\", " ~ t ~ "ValueType,
                    [GrType(GrType.Base.null_)]);
            }
            else {
                GrConstraint " ~ t ~ "Constraint = grConstraint(\"Register\", " ~
                t ~ "ValueType, [gr" ~ t ~ "]);
            }
            library.addFunction(&_copy_!\"" ~ t ~ "\", \"copy\", [pure" ~ t ~
                "ArrayType], [" ~ t ~ "ArrayType], [" ~ t ~ "Constraint]);
            library.addFunction(&_size_!\"" ~ t ~ "\", \"size\", [pure" ~ t ~
                "ArrayType], [grInt], [" ~ t ~ "Constraint]);
            library.addFunction(&_resize_!\"" ~ t ~ "\", \"resize\", [
                " ~ t ~ "ArrayType, grInt
            ], [" ~ t ~ "ArrayType], [" ~ t ~ "Constraint]);
            library.addFunction(&_empty_!\"" ~ t ~ "\", \"empty?\", [
                pure" ~ t ~ "ArrayType
            ], [grBool], [" ~ t ~ "Constraint]);
            library.addFunction(&_fill_!\"" ~ t ~ "\", \"fill\", [
                " ~ t ~ "ArrayType, " ~ t ~ "ValueType
            ], [" ~ t ~ "ArrayType], [" ~ t ~ "Constraint]);
            library.addFunction(&_clear_!\"" ~ t ~ "\", \"clear\", [
                " ~ t ~ "ArrayType
            ], [" ~ t ~ "ArrayType], [" ~ t ~ "Constraint]);
            library.addFunction(&_unshift_!\"" ~ t ~ "\", \"unshift\", [
                    " ~ t ~ "ArrayType, " ~ t ~ "ValueType
                ], [" ~ t ~ "ArrayType], [" ~ t ~ "Constraint]);
            library.addFunction(&_push_!\"" ~ t ~ "\", \"push\", [
                    " ~ t ~ "ArrayType, " ~ t ~ "ValueType
                ], [" ~ t ~ "ValueType], [" ~ t ~ "Constraint]);
            library.addFunction(&_shift_!\"" ~ t ~ "\", \"shift\", [
                    " ~ t ~ "ArrayType
                ], [" ~ t ~ "ValueType], [" ~ t ~ "Constraint]);
            library.addFunction(&_pop_!\"" ~ t ~ "\", \"pop\", [
                    " ~ t ~ "ArrayType
                ], [" ~ t ~ "ValueType], [" ~ t ~ "Constraint]);
            library.addFunction(&_shift1_!\"" ~ t ~ "\", \"shift\", [
                    " ~ t ~ "ArrayType, grInt
                ], [" ~ t ~ "ArrayType], [" ~ t ~ "Constraint]);
            library.addFunction(&_pop1_!\"" ~ t ~ "\", \"pop\", [
                    " ~ t ~ "ArrayType, grInt
                ], [" ~ t ~ "ArrayType], [" ~ t ~ "Constraint]);
            library.addFunction(&_first_!\"" ~ t ~ "\", \"first\", [
                pure" ~ t ~ "ArrayType
            ], [" ~ t ~ "ValueType], [" ~ t ~ "Constraint]);
            library.addFunction(&_last_!\"" ~ t ~ "\", \"last\", [
                    pure" ~ t ~ "ArrayType
                ], [" ~ t ~ "ValueType], [" ~ t ~ "Constraint]);
            library.addFunction(&_remove_!\"" ~ t ~ "\", \"remove\", [
                    " ~ t ~ "ArrayType, grInt
                ], [" ~ t ~ "ArrayType], [" ~ t ~ "Constraint]);
            library.addFunction(&_remove2_!\"" ~ t ~ "\", \"remove\", [
                    " ~ t ~ "ArrayType, grInt, grInt
                ], [" ~ t ~ "ArrayType], [" ~ t ~ "Constraint]);
            library.addFunction(&_slice_!\"" ~ t ~ "\", \"slice\", [
                    " ~ t ~ "ArrayType, grInt, grInt
                ], [" ~ t ~ "ArrayType], [" ~ t ~ "Constraint]);
            library.addFunction(&_slice_copy_!\"" ~ t ~ "\", \"sliced\", [
                    pure" ~ t ~ "ArrayType, grInt, grInt
                ], [" ~ t ~ "ArrayType], [" ~ t ~ "Constraint]);
            library.addFunction(&_reverse_!\"" ~ t ~ "\", \"reverse\", [
                    pure" ~ t ~ "ArrayType
                ], [" ~ t ~ "ArrayType], [" ~ t ~ "Constraint]);
            library.addFunction(&_insert_!\"" ~ t ~ "\", \"insert\", [
                    " ~ t ~ "ArrayType, grInt, " ~ t ~ "ValueType
                ], [" ~ t ~ "ArrayType], [" ~ t ~ "Constraint]);
            library.addFunction(&_each_!\"" ~ t ~ "\", \"each\", [" ~ t ~
                "ArrayType], [" ~ t ~ "IteratorType], [" ~ t ~ "Constraint]);
            library.addFunction(&_next_!\"" ~ t ~ "\", \"next\", [
                    " ~ t ~ "IteratorType
                ], [grBool, " ~ t ~ "ValueType], [" ~ t ~ "Constraint]);
            library.addFunction(&_findFirst_!\"" ~ t ~ "\", \"findFirst\", [
                    pure" ~ t ~ "ArrayType, pure" ~ t ~ "ValueType
                ], [grInt], [" ~ t ~ "Constraint]);
            library.addFunction(&_findLast_!\"" ~ t ~ "\", \"findLast\", [
                    pure" ~ t ~ "ArrayType, pure" ~ t ~ "ValueType
                ], [grInt], [" ~ t ~ "Constraint]);
            library.addFunction(&_findLast_!\"" ~ t ~ "\", \"findLast\", [
                    pure" ~ t ~ "ArrayType, pure" ~ t ~ "ValueType
                ], [grInt], [" ~ t ~ "Constraint]);
            library.addFunction(&_has_!\"" ~ t ~ "\", \"has?\", [
                    pure" ~ t ~ "ArrayType, pure" ~ t ~ "ValueType
                ], [grBool], [" ~ t ~ "Constraint]);
            ");

        static if (t != "Object") {
            mixin("
            library.addFunction(&_sort_!\"" ~ t ~ "\", \"sort\", [
                    " ~ t ~ "ArrayType
                ], [" ~ t ~ "ArrayType], [" ~ t ~ "Constraint]);
                ");
        }
    }*/
}
/+
private void _copy_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array copy = new Gr" ~ t ~ "Array;
        copy.data = call.get" ~ t ~ "Array(0).data.dup;
        call.set" ~ t ~ "Array(copy);");
}

private void _size_(string t)(GrCall call) {
    mixin("call.setInt(cast(GrInt) call.get" ~ t ~ "Array(0).data.length);");
}

private void _resize_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    const GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("ArgumentError");
        return;
    }
    static if (t == "Real") {
        if (size > array.data.length) {
            GrInt index = cast(GrInt) array.data.length;
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
        GrPtr value = call.getPtr(1);
    }
    else {
        mixin("auto value = call.get" ~ t ~ "(1);");
    }
    for (size_t index; index < array.data.length; ++index)
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
    GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    if (array.data.length < size) {
        size = cast(GrInt) array.data.length;
    }
    mixin("Gr" ~ t ~ "Array copy = new Gr" ~ t ~ "Array;");
    copy.data = array.data[0 .. size];
    array.data = array.data[size .. $];
    mixin("call.set" ~ t ~ "Array(copy);");
}

private void _pop1_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    if (array.data.length < size) {
        size = cast(GrInt) array.data.length;
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
    GrInt index = call.getInt(1);
    if (index < 0)
        index = (cast(GrInt) array.data.length) + index;
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
        mixin("call.set" ~ t ~ "Array(array);");
        return;
    }

    if (index1 < 0)
        index1 = 0;
    if (index2 >= array.data.length)
        index2 = (cast(GrInt) array.data.length) - 1;

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
        mixin("call.set" ~ t ~ "Array(array);");
        return;
    }

    if (index1 < 0)
        index1 = 0;
    if (index2 >= array.data.length)
        index2 = (cast(GrInt) array.data.length - 1);

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
        mixin("call.set" ~ t ~ "Array(copy);");
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
    GrInt index = call.getInt(1);
    static if (t == "Object") {
        GrPtr value = call.getPtr(2);
    }
    else {
        mixin("auto value = call.get" ~ t ~ "(2);");
    }
    if (index < 0)
        index = (cast(GrInt) array.data.length) + index;
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
    static if (t == "Object") {
        auto value = call.getPtr(1);
    }
    else {
        mixin("auto value = call.get" ~ t ~ "(1);");
    }
    for (GrInt index; index < array.data.length; ++index) {
        if (array.data[index] == value) {
            call.setInt(index);
            return;
        }
    }
    call.setInt(-1);
}

private void _findLast_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    static if (t == "Object") {
        auto value = call.getPtr(1);
    }
    else {
        mixin("auto value = call.get" ~ t ~ "(1);");
    }
    for (GrInt index = (cast(GrInt) array.data.length) - 1; index > 0; --index) {
        if (array.data[index] == value) {
            call.setInt(index);
            return;
        }
    }
    call.setInt(-1);
}

private void _has_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    static if (t == "Object") {
        auto value = call.getPtr(1);
    }
    else {
        mixin("auto value = call.get" ~ t ~ "(1);");
    }
    for (GrInt index; index < array.data.length; ++index) {
        if (array.data[index] == value) {
            call.setBool(true);
            return;
        }
    }
    call.setBool(false);
}

private final class ArrayIterator(T) {
    T[] array;
    size_t index;
}

private void _each_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(0);");
    static if (t == "Int") {
        ArrayIterator!(GrInt) iter = new ArrayIterator!(GrInt);
    }
    else static if (t == "Real") {
        ArrayIterator!(GrReal) iter = new ArrayIterator!(GrReal);
    }
    else static if (t == "String") {
        ArrayIterator!(GrString) iter = new ArrayIterator!(GrString);
    }
    else static if (t == "Object") {
        ArrayIterator!(GrPtr) iter = new ArrayIterator!(GrPtr);
    }
    iter.array = array.data.dup;
    call.setForeign(iter);
}

private void _next_(string t)(GrCall call) {
    static if (t == "Int") {
        ArrayIterator!(GrInt) iter = call.getForeign!(ArrayIterator!(GrInt))(0);
    }
    else static if (t == "Real") {
        ArrayIterator!(GrReal) iter = call.getForeign!(ArrayIterator!(GrReal))(0);
    }
    else static if (t == "String") {
        ArrayIterator!(GrString) iter = call.getForeign!(ArrayIterator!(GrString))(0);
    }
    else static if (t == "Object") {
        ArrayIterator!(GrPtr) iter = call.getForeign!(ArrayIterator!(GrPtr))(0);
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
        else static if (t == "Real") {
            call.setReal(0f);
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
    else static if (t == "Real") {
        call.setReal(iter.array[iter.index]);
    }
    else static if (t == "String") {
        call.setString(iter.array[iter.index]);
    }
    else static if (t == "Object") {
        call.setPtr(iter.array[iter.index]);
    }
    iter.index++;
}
+/