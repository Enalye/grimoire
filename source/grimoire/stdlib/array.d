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
            data.addPrimitive(&_size_!\""
                ~ t ~ "\", \"size\", [\"array\"], [any" ~ t ~ "Array], [grInt]);
            data.addPrimitive(&_resize_!\"" ~ t
                ~ "\", \"resize\", [\"array\", \"size\"], [
                any" ~ t ~ "Array, grInt
            ], [grAny(\" A\")]);
            data.addPrimitive(&_empty_!\"" ~ t ~ "\", \"empty?\", [\"array\"], [
                any" ~ t
                ~ "Array
            ], [grBool]);
            data.addPrimitive(&_pushfront_!\"" ~ t ~ "\", \"push_front\", [\"array\", \"v\"], [
                    any" ~ t
                ~ "Array, grAny(\"T\")
                ]);
            data.addPrimitive(&_pushback_!\"" ~ t ~ "\", \"push_back\", [\"array\", \"v\"], [
                    any"
                ~ t ~ "Array, grAny(\"T\")
                ]);
            data.addPrimitive(&_popfront_!\"" ~ t ~ "\", \"pop_front\", [\"array\", \"size\"], [
                    any" ~ t ~ "Array, grInt
                ]);
            data.addPrimitive(&_popback_!\"" ~ t
                ~ "\", \"pop_back\", [\"array\", \"size\"], [
                    any" ~ t ~ "Array, grInt
                ]);
            data.addPrimitive(&_front_!\""
                ~ t ~ "\", \"front\", [\"array\"], [
                any" ~ t ~ "Array
            ], [grAny(\"T\")]);
            data.addPrimitive(&_back_!\"" ~ t
                ~ "\", \"back\", [\"array\"], [
                    any" ~ t ~ "Array
                ], [grAny(\"T\")]);");
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

private void _size_(string t)(GrCall call) {
    mixin("call.setInt(cast(int) call.get" ~ t ~ "Array(\"array\").data.length);");
}

private void _resize_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");
    array.data.length = call.getInt(\"size\");
    call.set" ~ t ~ "Array(array);");
}

private void _empty_(string t)(GrCall call) {
    mixin("const Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");
    call.setBool(array.data.empty);");
}

private void _pushfront_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    static if (t == "Object") {
        mixin("array.data = call.getPtr(\"v\") ~ array.data;");
    }
    else {
        mixin("array.data = call.get" ~ t ~ "(\"v\") ~ array.data;");
    }
}

private void _pushback_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");");
    static if (t == "Object") {
        mixin("array.data ~= call.getPtr(\"v\");");
    }
    else {
        mixin("array.data ~= call.get" ~ t ~ "(\"v\");");
    }
}

private void _popfront_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");
    int sz = call.getInt(\"size\");
    if (array.data.length < sz) {
        sz = cast(int) array.data.length;
    }
    else if (sz < 0) {
        sz = 0;
    }
    array.data = array.data[sz .. $];");
}

private void _popback_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");
    int sz = call.getInt(\"size\");
    if (array.data.length < sz) {
        sz = cast(int) array.data.length;
    }
    else if (sz < 0) {
        sz = 0;
    }
    array.data.length -= sz;");
}

private void _front_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");
    if (!array.data.length) {
        call.raise(\"IndexError\");
        return;
    }");
    static if (t == "Object") {
        mixin("call.setPtr(array.data[0]);");
    }
    else {
        mixin("call.set" ~ t ~ "(array.data[0]);");
    }
}

private void _back_(string t)(GrCall call) {
    mixin("Gr" ~ t ~ "Array array = call.get" ~ t ~ "Array(\"array\");
    if (!array.data.length) {
        call.raise(\"IndexError\");
        return;
    }");
    static if (t == "Object") {
        mixin("call.setPtr(array.data[$ - 1]);");
    }
    else {
        mixin("call.set" ~ t ~ "(array.data[$ - 1]);");
    }
}
