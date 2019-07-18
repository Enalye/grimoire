module grimoire.lib.math.misc;

import grimoire.lib.api;

static this() {
	grAddPrimitive(&_range, "range", ["min", "max"], [grInt, grInt], [grArray]);
}

private void _range(GrCall call) {
    int min = call.getInt("min");
    int max = call.getInt("max");
    int step = 1;

    if(max < min)
        step = -1;

    GrArrayValue array = new GrArrayValue;
    while(min != max) {
        array.push(min);
        min += step;
    }
    array.push(max);
    call.setArray(array);
}