module grimoire.stdlib.array;

import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib)
void grLoadStdLibArray() {
	grAddPrimitive(&_range, "range", ["min", "max"], [grInt, grInt], [grIntArray]);
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