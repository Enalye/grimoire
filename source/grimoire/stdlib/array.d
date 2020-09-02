/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.array;

import std.range;
import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib)
void grLoadStdLibArray(GrData data) {
	data.addPrimitive(&_range_i, "range", ["min", "max"], [grInt, grInt], [grIntArray]);
	data.addPrimitive(&_range_f, "range", ["min", "max"], [grFloat, grFloat], [grFloatArray]);

	data.addPrimitive(&_size_i, "size", ["array"], [grIntArray], [grInt]);
	data.addPrimitive(&_size_f, "size", ["array"], [grFloatArray], [grInt]);
	data.addPrimitive(&_size_s, "size", ["array"], [grStringArray], [grInt]);

	data.addPrimitive(&_resize_i, "resize", ["array", "size"], [grIntArray, grInt], [grIntArray]);
	data.addPrimitive(&_resize_f, "resize", ["array", "size"], [grFloatArray, grInt], [grFloatArray]);
	data.addPrimitive(&_resize_s, "resize", ["array", "size"], [grStringArray, grInt], [grStringArray]);

	data.addPrimitive(&_empty_i, "empty?", ["array"], [grIntArray], [grBool]);
	data.addPrimitive(&_empty_f, "empty?", ["array"], [grFloatArray], [grBool]);
	data.addPrimitive(&_empty_s, "empty?", ["array"], [grStringArray], [grBool]);

	data.addPrimitive(&_pushfront_i, "push_front", ["array", "v"], [grIntArray, grInt]);
	data.addPrimitive(&_pushback_i, "push_back", ["array", "v"], [grIntArray, grInt]);
	data.addPrimitive(&_popfront_i, "pop_front", ["array", "sz"], [grIntArray, grInt]);
	data.addPrimitive(&_popback_i, "pop_back", ["array", "sz"], [grIntArray, grInt]);

	data.addPrimitive(&_pushfront_f, "push_front", ["array", "v"], [grFloatArray, grInt]);
	data.addPrimitive(&_pushback_f, "push_back", ["array", "v"], [grFloatArray, grInt]);
	data.addPrimitive(&_popfront_f, "pop_front", ["array", "sz"], [grFloatArray, grInt]);
	data.addPrimitive(&_popback_f, "pop_back", ["array", "sz"], [grFloatArray, grInt]);

	data.addPrimitive(&_pushfront_s, "push_front", ["array", "v"], [grStringArray, grInt]);
	data.addPrimitive(&_pushback_s, "push_back", ["array", "v"], [grStringArray, grInt]);
	data.addPrimitive(&_popfront_s, "pop_front", ["array", "sz"], [grStringArray, grInt]);
	data.addPrimitive(&_popback_s, "pop_back", ["array", "sz"], [grStringArray, grInt]);

}

private void _range_i(GrCall call) {
    int min = call.getInt("min");
    const int max = call.getInt("max");
    int step = 1;

    if(max < min)
        step = -1;

    GrIntArray array = new GrIntArray;
    while(min != max) {
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

    if(max < min)
        step = -1f;

    GrFloatArray array = new GrFloatArray;
    while(min != max) {
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
    if(array.data.length < sz) {
        sz = cast(int) array.data.length;
    }
    else if(sz < 0) {
        sz = 0;
    }
    array.data = array.data[sz..$];
}

private void _popback_i(GrCall call) {
    GrIntArray array = call.getIntArray("array");
    int sz = call.getInt("sz");
    if(array.data.length < sz) {
        sz = cast(int) array.data.length;
    }
    else if(sz < 0) {
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
    if(array.data.length < sz) {
        sz = cast(int) array.data.length;
    }
    else if(sz < 0) {
        sz = 0;
    }
    array.data = array.data[sz..$];
}

private void _popback_f(GrCall call) {
    GrFloatArray array = call.getFloatArray("array");
    int sz = call.getInt("sz");
    if(array.data.length < sz) {
        sz = cast(int) array.data.length;
    }
    else if(sz < 0) {
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
    if(array.data.length < sz) {
        sz = cast(int) array.data.length;
    }
    else if(sz < 0) {
        sz = 0;
    }
    array.data = array.data[sz..$];
}

private void _popback_s(GrCall call) {
    GrStringArray array = call.getStringArray("array");
    int sz = call.getInt("sz");
    if(array.data.length < sz) {
        sz = cast(int) array.data.length;
    }
    else if(sz < 0) {
        sz = 0;
    }
    array.data.length -= sz;
}