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