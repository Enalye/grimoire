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

    data.addPrimitive(&_size_i, "size", ["array"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfInt(subType.baseType);
            })
            ], [grInt]);
    data.addPrimitive(&_size_f, "size", ["array"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfFloat(subType.baseType);
            })
            ], [grInt]);
    data.addPrimitive(&_size_s, "size", ["array"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfString(subType.baseType);
            })
            ], [grInt]);
    data.addPrimitive(&_size_o, "size", ["array"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfObject(subType.baseType);
            })
            ], [grInt]);

    data.addPrimitive(&_resize_i, "resize", ["array", "size"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfInt(subType.baseType);
            }), grInt
            ], [grAny("A")]);
    data.addPrimitive(&_resize_f, "resize", ["array", "size"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfFloat(subType.baseType);
            }), grInt
            ], [grAny("A")]);
    data.addPrimitive(&_resize_s, "resize", ["array", "size"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfString(subType.baseType);
            }), grInt
            ], [grAny("A")]);
    data.addPrimitive(&_resize_o, "resize", ["array", "size"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfObject(subType.baseType);
            }), grInt
            ], [grAny("A")]);

    data.addPrimitive(&_empty_i, "empty?", ["array"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfInt(subType.baseType);
            })
            ], [grBool]);
    data.addPrimitive(&_empty_f, "empty?", ["array"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfFloat(subType.baseType);
            })
            ], [grBool]);
    data.addPrimitive(&_empty_s, "empty?", ["array"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfString(subType.baseType);
            })
            ], [grBool]);
    data.addPrimitive(&_empty_o, "empty?", ["array"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfObject(subType.baseType);
            })
            ], [grBool]);

    data.addPrimitive(&_pushfront_i, "push_front", ["array", "v"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set("T", subType);
                return grIsKindOfInt(subType.baseType);
            }), grAny("T")
            ]);
    data.addPrimitive(&_pushback_i, "push_back", ["array", "v"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set("T", subType);
                return grIsKindOfInt(subType.baseType);
            }), grAny("T")
            ]);
    data.addPrimitive(&_popfront_i, "pop_front", ["array", "sz"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfInt(subType.baseType);
            }), grInt
            ]);
    data.addPrimitive(&_popback_i, "pop_back", ["array", "sz"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfInt(subType.baseType);
            }), grInt
            ]);

    data.addPrimitive(&_pushfront_f, "push_front", ["array", "v"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set("T", subType);
                return grIsKindOfFloat(subType.baseType);
            }), grAny("T")
            ]);
    data.addPrimitive(&_pushback_f, "push_back", ["array", "v"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set("T", subType);
                return grIsKindOfFloat(subType.baseType);
            }), grAny("T")
            ]);
    data.addPrimitive(&_popfront_f, "pop_front", ["array", "sz"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfFloat(subType.baseType);
            }), grInt
            ]);
    data.addPrimitive(&_popback_f, "pop_back", ["array", "sz"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfFloat(subType.baseType);
            }), grInt
            ]);

    data.addPrimitive(&_pushfront_s, "push_front", ["array", "v"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set("T", subType);
                return grIsKindOfString(subType.baseType);
            }), grAny("T")
            ]);
    data.addPrimitive(&_pushback_s, "push_back", ["array", "v"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set("T", subType);
                return grIsKindOfString(subType.baseType);
            }), grAny("T")
            ]);
    data.addPrimitive(&_popfront_s, "pop_front", ["array", "sz"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfString(subType.baseType);
            }), grInt
            ]);
    data.addPrimitive(&_popback_s, "pop_back", ["array", "sz"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfString(subType.baseType);
            }), grInt
            ]);

    data.addPrimitive(&_pushfront_o, "push_front", ["array", "v"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set("T", subType);
                return grIsKindOfObject(subType.baseType);
            }), grAny("T")
            ]);
    data.addPrimitive(&_pushback_o, "push_back", ["array", "v"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set("T", subType);
                return grIsKindOfObject(subType.baseType);
            }), grAny("T")
            ]);
    data.addPrimitive(&_popfront_o, "pop_front", ["array", "sz"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfObject(subType.baseType);
            }), grInt
            ]);
    data.addPrimitive(&_popback_o, "pop_back", ["array", "sz"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfObject(subType.baseType);
            }), grInt
            ]);

    data.addPrimitive(&_front_i, "front", ["array"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set("T", subType);
                return grIsKindOfInt(subType.baseType);
            })
            ], [grAny("T")]);
    data.addPrimitive(&_back_i, "back", ["array"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set("T", subType);
                return grIsKindOfInt(subType.baseType);
            })
            ], [grAny("T")]);
    data.addPrimitive(&_front_f, "front", ["array"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set("T", subType);
                return grIsKindOfFloat(subType.baseType);
            })
            ], [grAny("T")]);
    data.addPrimitive(&_back_f, "back", ["array"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set("T", subType);
                return grIsKindOfFloat(subType.baseType);
            })
            ], [grAny("T")]);
    data.addPrimitive(&_front_s, "front", ["array"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set("T", subType);
                return grIsKindOfString(subType.baseType);
            })
            ], [grAny("T")]);
    data.addPrimitive(&_back_s, "back", ["array"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set("T", subType);
                return grIsKindOfString(subType.baseType);
            })
            ], [grAny("T")]);
    data.addPrimitive(&_front_o, "front", ["array"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set("T", subType);
                return grIsKindOfObject(subType.baseType);
            })
            ], [grAny("T")]);
    data.addPrimitive(&_back_o, "back", ["array"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set("T", subType);
                return grIsKindOfObject(subType.baseType);
            })
            ], [grAny("T")]);
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

private void _size_i(GrCall call) {
    call.setInt(cast(int) call.getIntArray("array").data.length);
}

private void _size_f(GrCall call) {
    call.setInt(cast(int) call.getFloatArray("array").data.length);
}

private void _size_s(GrCall call) {
    call.setInt(cast(int) call.getStringArray("array").data.length);
}

private void _size_o(GrCall call) {
    call.setInt(cast(int) call.getObjectArray("array").data.length);
}

private void _resize_i(GrCall call) {
    GrIntArray array = call.getIntArray("array");
    array.data.length = call.getInt("size");
    call.setIntArray(array);
}

private void _resize_f(GrCall call) {
    GrFloatArray array = call.getFloatArray("array");
    array.data.length = call.getInt("size");
    call.setFloatArray(array);
}

private void _resize_s(GrCall call) {
    GrStringArray array = call.getStringArray("array");
    array.data.length = call.getInt("size");
    call.setStringArray(array);
}

private void _resize_o(GrCall call) {
    GrObjectArray array = call.getObjectArray("array");
    array.data.length = call.getInt("size");
    call.setObjectArray(array);
}

private void _empty_i(GrCall call) {
    const GrIntArray array = call.getIntArray("array");
    call.setBool(array.data.empty);
}

private void _empty_f(GrCall call) {
    const GrFloatArray array = call.getFloatArray("array");
    call.setBool(array.data.empty);
}

private void _empty_s(GrCall call) {
    const GrStringArray array = call.getStringArray("array");
    call.setBool(array.data.empty);
}

private void _empty_o(GrCall call) {
    const GrObjectArray array = call.getObjectArray("array");
    call.setBool(array.data.empty);
}

private void _pushfront_i(GrCall call) {
    GrIntArray array = call.getIntArray("array");
    array.data = call.getInt("v") ~ array.data;
}

private void _pushback_i(GrCall call) {
    GrIntArray array = call.getIntArray("array");
    array.data ~= call.getInt("v");
}

private void _popfront_i(GrCall call) {
    GrIntArray array = call.getIntArray("array");
    int sz = call.getInt("sz");
    if (array.data.length < sz) {
        sz = cast(int) array.data.length;
    }
    else if (sz < 0) {
        sz = 0;
    }
    array.data = array.data[sz .. $];
}

private void _popback_i(GrCall call) {
    GrIntArray array = call.getIntArray("array");
    int sz = call.getInt("sz");
    if (array.data.length < sz) {
        sz = cast(int) array.data.length;
    }
    else if (sz < 0) {
        sz = 0;
    }
    array.data.length -= sz;
}

private void _pushfront_f(GrCall call) {
    GrFloatArray array = call.getFloatArray("array");
    array.data = call.getFloat("v") ~ array.data;
}

private void _pushback_f(GrCall call) {
    GrFloatArray array = call.getFloatArray("array");
    array.data ~= call.getFloat("v");
}

private void _popfront_f(GrCall call) {
    GrFloatArray array = call.getFloatArray("array");
    int sz = call.getInt("sz");
    if (array.data.length < sz) {
        sz = cast(int) array.data.length;
    }
    else if (sz < 0) {
        sz = 0;
    }
    array.data = array.data[sz .. $];
}

private void _popback_f(GrCall call) {
    GrFloatArray array = call.getFloatArray("array");
    int sz = call.getInt("sz");
    if (array.data.length < sz) {
        sz = cast(int) array.data.length;
    }
    else if (sz < 0) {
        sz = 0;
    }
    array.data.length -= sz;
}

private void _pushfront_s(GrCall call) {
    GrStringArray array = call.getStringArray("array");
    array.data = call.getString("v") ~ array.data;
}

private void _pushback_s(GrCall call) {
    GrStringArray array = call.getStringArray("array");
    array.data ~= call.getString("v");
}

private void _popfront_s(GrCall call) {
    GrStringArray array = call.getStringArray("array");
    int sz = call.getInt("sz");
    if (array.data.length < sz) {
        sz = cast(int) array.data.length;
    }
    else if (sz < 0) {
        sz = 0;
    }
    array.data = array.data[sz .. $];
}

private void _popback_s(GrCall call) {
    GrStringArray array = call.getStringArray("array");
    int sz = call.getInt("sz");
    if (array.data.length < sz) {
        sz = cast(int) array.data.length;
    }
    else if (sz < 0) {
        sz = 0;
    }
    array.data.length -= sz;
}

private void _pushfront_o(GrCall call) {
    GrObjectArray array = call.getObjectArray("array");
    array.data = call.getPtr("v") ~ array.data;
}

private void _pushback_o(GrCall call) {
    GrObjectArray array = call.getObjectArray("array");
    array.data ~= call.getPtr("v");
}

private void _popfront_o(GrCall call) {
    GrObjectArray array = call.getObjectArray("array");
    int sz = call.getInt("sz");
    if (array.data.length < sz) {
        sz = cast(int) array.data.length;
    }
    else if (sz < 0) {
        sz = 0;
    }
    array.data = array.data[sz .. $];
}

private void _popback_o(GrCall call) {
    GrObjectArray array = call.getObjectArray("array");
    int sz = call.getInt("sz");
    if (array.data.length < sz) {
        sz = cast(int) array.data.length;
    }
    else if (sz < 0) {
        sz = 0;
    }
    array.data.length -= sz;
}

private void _front_i(GrCall call) {
    GrIntArray array = call.getIntArray("array");
    if (!array.data.length) {
        call.raise("EmptyArray");
        return;
    }
    call.setInt(array.data[0]);
}

private void _back_i(GrCall call) {
    GrIntArray array = call.getIntArray("array");
    if (!array.data.length) {
        call.raise("EmptyArray");
        return;
    }
    call.setInt(array.data[$ - 1]);
}

private void _front_f(GrCall call) {
    GrFloatArray array = call.getFloatArray("array");
    if (!array.data.length) {
        call.raise("EmptyArray");
        return;
    }
    call.setFloat(array.data[0]);
}

private void _back_f(GrCall call) {
    GrFloatArray array = call.getFloatArray("array");
    if (!array.data.length) {
        call.raise("EmptyArray");
        return;
    }
    call.setFloat(array.data[$ - 1]);
}

private void _front_s(GrCall call) {
    GrStringArray array = call.getStringArray("array");
    if (!array.data.length) {
        call.raise("EmptyArray");
        return;
    }
    call.setString(array.data[0]);
}

private void _back_s(GrCall call) {
    GrStringArray array = call.getStringArray("array");
    if (!array.data.length) {
        call.raise("EmptyArray");
        return;
    }
    call.setString(array.data[$ - 1]);
}

private void _front_o(GrCall call) {
    GrObjectArray array = call.getObjectArray("array");
    if (!array.data.length) {
        call.raise("EmptyArray");
        return;
    }
    call.setPtr(array.data[0]);
}

private void _back_o(GrCall call) {
    GrObjectArray array = call.getObjectArray("array");
    if (!array.data.length) {
        call.raise("EmptyArray");
        return;
    }
    call.setPtr(array.data[$ - 1]);
}
