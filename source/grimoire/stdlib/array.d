module grimoire.stdlib.array;

import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib)
void grLoadStdLibArray(GrData data) {
	data.addPrimitive(&_range, "range", ["min", "max"], [grInt, grInt], [grIntArray]);
	data.addPrimitive(&_size_s, "size", ["array"], [grStringArray], [grInt]);
}

private void _range(GrCall call) {
    int min = call.getInt("min");
    int max = call.getInt("max");
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

private void _size_s(GrCall call) {
    call.setInt(cast(int)call.getStringArray("array").data.length);
}