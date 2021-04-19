/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.array;

import std.range;
import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibArray(GrData data) {
    data.addPrimitive(&_range_i, "range", ["min", "max"], [grInt, grInt], [
            grIntArray
            ]);
    data.addPrimitive(&_range_f, "range", ["min", "max"], [grFloat, grFloat], [
            grFloatArray
            ]);

    static foreach (t; ["Int", "Float", "String", "Object"]) {
        mixin("GrType any" ~ t ~ "Array = grAny(\"A\", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set(\"T\", subType);
                return grIsKindOf" ~ t ~ "(subType.baseType);
            });
            data.addPrimitive(&_copy_!\"" ~ t
                ~ "\", \"copy\", [\"array\"], [any" ~ t ~ "Array], [grAny(\"A\")]);
            data.addPrimitive(&_size_!\"" ~ t
                ~ "\", \"size\", [\"array\"], [any" ~ t ~ "Array], [grInt]);
            data.addPrimitive(&_resize_!\"" ~ t
                ~ "\", \"resize\", [\"array\", \"size\"], [
                any" ~ t ~ "Array, grInt
            ], [grAny(\"A\")]);
            data.addPrimitive(&_empty_!\""
                ~ t ~ "\", \"empty?\", [\"array\"], [
                any" ~ t ~ "Array
            ], [grBool]);
            data.addPrimitive(&_fill_!\"" ~ t ~ "\", \"fill\", [\"array\", \"value\"], [
                any"
                ~ t ~ "Array, grAny(\"T\")
            ], [grAny(\"A\")]);
            data.addPrimitive(&_clear_!\"" ~ t ~ "\", \"clear\", [\"array\"], [
                any"
                ~ t ~ "Array
            ], [grAny(\"A\")]);
            data.addPrimitive(&_unshift_!\"" ~ t ~ "\", \"unshift\", [\"array\", \"v\"], [
                    any" ~ t
                ~ "Array, grAny(\"T\")
                ], [grAny(\"A\")]);
            data.addPrimitive(&_push_!\"" ~ t ~ "\", \"push\", [\"array\", \"v\"], [
                    any" ~ t
                ~ "Array, grAny(\"T\")
                ], [grAny(\"A\")]);
            data.addPrimitive(&_shift_!\"" ~ t ~ "\", \"shift\", [\"array\"], [
                    any" ~ t ~ "Array
                ], [grAny(\"T\")]);
            data.addPrimitive(&_pop_!\"" ~ t
                ~ "\", \"pop\", [\"array\"], [
                    any" ~ t ~ "Array
                ], [grAny(\"T\")]);
            data.addPrimitive(&_shift1_!\"" ~ t ~ "\", \"shift\", [\"array\", \"size\"], [
                    any" ~ t ~ "Array, grInt
                ], [grAny(\"A\")]);
            data.addPrimitive(&_pop1_!\"" ~ t
                ~ "\", \"pop\", [\"array\", \"size\"], [
                    any" ~ t ~ "Array, grInt
                ], [grAny(\"A\")]);
            data.addPrimitive(&_first_!\""
                ~ t ~ "\", \"first\", [\"array\"], [
                any" ~ t ~ "Array
            ], [grAny(\"T\")]);
            data.addPrimitive(&_last_!\"" ~ t ~ "\", \"last\", [\"array\"], [
                    any" ~ t ~ "Array
                ], [grAny(\"T\")]);
            data.addPrimitive(&_remove_!\"" ~ t
                ~ "\", \"remove\", [\"array\", \"index\"], [
                    any" ~ t ~ "Array, grInt
                ], [grAny(\"A\")]);
            data.addPrimitive(&_remove2_!\""
                ~ t ~ "\", \"remove\", [\"array\", \"index1\", \"index2\"], [
                    any" ~ t ~ "Array, grInt, grInt
                ], [grAny(\"A\")]);
            data.addPrimitive(&_slice_!\"" ~ t
                ~ "\", \"slice!\", [\"array\", \"index1\", \"index2\"], [
                    any" ~ t
                ~ "Array, grInt, grInt
                ], [grAny(\"A\")]);
            data.addPrimitive(&_slice_copy_!\"" ~ t ~ "\", \"slice\", [\"array\", \"index1\", \"index2\"], [
                    any"
                ~ t ~ "Array, grInt, grInt
                ], [grAny(\"A\")]);
            data.addPrimitive(&_reverse_!\"" ~ t ~ "\", \"reverse\", [\"array\"], [
                    any" ~ t ~ "Array
                ], [grAny(\"A\")]);
            data.addPrimitive(&_insert_!\"" ~ t
                ~ "\", \"insert\", [\"array\", \"index\", \"value\"], [
                    any" ~ t ~ "Array, grInt, grAny(\"T\")
                ], [grAny(\"A\")]);
            ");

        static if (t != "Object") {
            mixin("
            data.addPrimitive(&_sort_!\"" ~ t ~ "\", \"sort\", [\"array\"], [
                    any" ~ t ~ "Array
                ], [grAny(\"A\")]);
            data.addPrimitive(&_findFirst_!\"" ~ t ~ "\", \"findFirst\", [\"array\", \"value\"], [
                    any"
                    ~ t ~ "Array, grAny(\"T\")
                ], [grInt]);
            data.addPrimitive(&_findLast_!\"" ~ t ~ "\", \"findLast\", [\"array\", \"value\"], [
                    any"
                    ~ t ~ "Array, grAny(\"T\")
                ], [grInt]);
            data.addPrimitive(&_findLast_!\"" ~ t ~ "\", \"findLast\", [\"array\", \"value\"], [
                    any" ~ t
                    ~ "Array, grAny(\"T\")
                ], [grInt]);
            data.addPrimitive(&_has_!\"" ~ t
                    ~ "\", \"has?\", [\"array\", \"value\"], [
                    any" ~ t ~ "Array, grAny(\"T\")
                ], [grBool]);
                ");
        }
    }
}

private void _range_i(GrCall call) {
    int min = call.getInt("min");
    const int max = call.getInt("max");
    int step = 1;

    if (max < min)
        step = -1;

    GrIntArray array = new GrIntArray;
    while (min != max) {
        array.data ~= min;
        min += step;
    }
    array.data ~= max;
    call.setIntArray(array);
}

private void _range_f(GrCall call) {
    float min = call.getInt("min");
    const float max = call.getInt("max");
    float step = 1f;

    if (max < min)
        step = -1f;

    GrFloatArray array = new GrFloatArray;
    while (min != max) {
        array.data ~= min;
        min += step;
    }
    array.data ~= max;
    call.setFloatArray(array);
}

private void _copy_(string t)(GrCall call) {
    mixin(
            "Gr" ~ t ~ "Array copy = new Gr" ~ t ~ "Array;
        copy.data = call.get" ~ t
            ~ "Array(\"array\").data;
        call.set" ~ t ~ "Array(copy);");
}

private void _size_(string t)(GrCall call) {
    mixin("call.setInt(cast(int) call.get" ~ t ~ "Array(\"array\").data.length);");
}

private void _resize_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    const int size = call.getInt("size");
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
    mixin("const Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    call.setBool(array.data.empty);
}

private void _fill_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    static if (t == "Object") {
        void* value = call.getPtr("value");
    }
    else {
        mixin("auto value = call.get" ~ t ~ "(\"value\");");
    }
    for (int index; index < array.data.length; ++index)
        array.data[index] = value;
    mixin("call.set" ~ t ~ "Array(array);");
}

private void _clear_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    array.data.length = 0;
    mixin("call.set" ~ t ~ "Array(array);");
}

private void _unshift_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    static if (t == "Object") {
        array.data = call.getPtr("v") ~ array.data;
    }
    else {
        mixin("array.data = call.get" ~ t ~ "(\"v\") ~ array.data;");
    }
    mixin("call.set" ~ t ~ "Array(array);");
}

private void _push_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    static if (t == "Object") {
        array.data ~= call.getPtr("v");
    }
    else {
        mixin("array.data ~= call.get" ~ t ~ "(\"v\");");
    }
    mixin("call.set" ~ t ~ "Array(array);");
}

private void _shift_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
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
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
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
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    int size = call.getInt("size");
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
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    int size = call.getInt("size");
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
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
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
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
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
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    int index = call.getInt("index");
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
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    int index1 = call.getInt("index1");
    int index2 = call.getInt("index2");
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
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    int index1 = call.getInt("index1");
    int index2 = call.getInt("index2");
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
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    mixin("Gr" ~ t ~ "Array copy = new Gr" ~ t ~ "Array;");
    int index1 = call.getInt("index1");
    int index2 = call.getInt("index2");
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

    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    array.data = array.data.reverse;
    mixin("call.set" ~ t ~ "Array(array);");
}

private void _insert_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    int index = call.getInt("index");
    static if (t == "Object") {
        void* value = call.getPtr("value");
    }
    else {
        mixin("auto value = call.get" ~ t ~ "(\"value\");");
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

    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    array.data.sort();
    mixin("call.set" ~ t ~ "Array(array);");
}

private void _findFirst_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    mixin("auto value = call.get" ~ t ~ "(\"value\");");
    for (int index; index < array.data.length; ++index) {
        if (array.data[index] == value) {
            call.setInt(index);
            return;
        }
    }
    call.setInt(-1);
}

private void _findLast_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    mixin("auto value = call.get" ~ t ~ "(\"value\");");
    for (int index = (cast(int) array.data.length) - 1; index > 0; --index) {
        if (array.data[index] == value) {
            call.setInt(index);
            return;
        }
    }
    call.setInt(-1);
}

private void _has_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    mixin("auto value = call.get" ~ t ~ "(\"value\");");
    for (int index; index < array.data.length; ++index) {
        if (array.data[index] == value) {
            call.setBool(true);
            return;
        }
    }
    call.setBool(false);
}
