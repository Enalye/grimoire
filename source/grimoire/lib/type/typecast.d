/**
    Explicit typecast library.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.lib.type.typecast;

import std.conv;
import grimoire.lib.api;

static this() {
    //As int
    grAddCast(&typecast_r2i, "value", grFloat, grInt, true);
    grAddCast(&typecast_b2i, "value", grBool, grInt);
	grAddCast(&typecast_d2i, "value", grDynamic, grInt);

    //As float
    grAddCast(&typecast_i2r, "value", grInt, grFloat, true);
	grAddCast(&typecast_d2r, "value", grDynamic, grFloat);

    //As bool
	grAddCast(&typecast_b2i, "value", grDynamic, grBool);

    //As Array
	grAddCast(&typecast_s2n, "value", grString, grArray);
	grAddCast(&typecast_d2n, "value", grDynamic, grArray);


    //As string
	grAddCast(&typecast_i2s, "value", grInt, grString);
	grAddCast(&typecast_r2s, "value", grFloat, grString);
	grAddCast(&typecast_d2s, "value", grDynamic, grString);

    //As dynamic value
	grAddCast(&typecast_b2d, "value", grBool, grDynamic);
	grAddCast(&typecast_i2d, "value", grInt, grDynamic);
	grAddCast(&typecast_r2d, "value", grFloat, grDynamic);
	grAddCast(&typecast_s2d, "value", grString, grDynamic);
	grAddCast(&typecast_n2d, "value", grArray, grDynamic);

    GrType anonFunc = GrBaseType.FunctionType;
    anonFunc.mangledType = grMangleNamedFunction("", []);
	grAddCast(&typecast_f2d, "value", anonFunc, grDynamic);
	grAddCast(&typecast_d2f, "value", grDynamic, anonFunc);

    GrType anonTask = GrBaseType.TaskType;
    anonTask.mangledType = grMangleNamedFunction("", []);
	grAddCast(&typecast_t2d, "value", anonTask, grDynamic);
	grAddCast(&typecast_d2t, "value", grDynamic, anonTask);
}

//As int
private void typecast_r2i(GrCall call) {
    call.setInt(to!int(call.getFloat("value")));
}

private void typecast_b2i(GrCall call) {
    call.setInt(to!int(call.getBool("value")));
}

private void typecast_d2i(GrCall call) {
    call.setInt(call.getDynamic("value").getInt(call));
}

//As float
private void typecast_i2r(GrCall call) {
    call.setFloat(to!float(call.getInt("value")));
}

private void typecast_d2r(GrCall call) {
    call.setFloat(call.getDynamic("value").getFloat(call));
}

//As bool
private void typecast_d2b(GrCall call) {
    call.setBool(call.getDynamic("value").getBool(call) > 0);
}

//As array
private void typecast_s2n(GrCall call) {
    GrDynamicValue[] array;
    foreach(c; call.getString("value")) {
        GrDynamicValue dynamic;
        dynamic.setString(to!dstring(c));
        array ~= dynamic;
    }
	call.setArray(array);
}

private void typecast_d2n(GrCall call) {
    call.setArray(call.getDynamic("value").getArray(call));
}

//As string
private void typecast_i2s(GrCall call) {
	call.setString(to!dstring(call.getInt("value")));
}

private void typecast_r2s(GrCall call) {
	call.setString(to!dstring(call.getFloat("value")));
}

private void typecast_d2s(GrCall call) {
    call.setString(call.getDynamic("value").getString(call));
}

//As dynamic value
private void typecast_b2d(GrCall call) {
    GrDynamicValue dyn;
    dyn.setBool(call.getBool("value"));
	call.setDynamic(dyn);
}

private void typecast_i2d(GrCall call) {
    GrDynamicValue dyn;
    dyn.setInt(call.getInt("value"));
	call.setDynamic(dyn);
}

private void typecast_r2d(GrCall call) {
    GrDynamicValue dyn;
    dyn.setFloat(call.getFloat("value"));
	call.setDynamic(dyn);
}

private void typecast_s2d(GrCall call) {
    GrDynamicValue dyn;
    dyn.setString(call.getString("value"));
	call.setDynamic(dyn);
}

private void typecast_n2d(GrCall call) {
    GrDynamicValue dyn;
    dyn.setArray(call.getArray("value"));
	call.setDynamic(dyn);
}

private void typecast_n2d(GrCall call) {
    GrDynamicValue dyn;
    dyn.setArray(call.getArray("value"));
	call.setDynamic(dyn);
}

private void typecast_f2d(GrCall call) {
    GrDynamicValue dyn;
    dyn.setFunction(call.getInt("value"), call.meta);
	call.setDynamic(dyn);
}

private void typecast_d2f(GrCall call) {
    GrDynamicValue dyn = call.getDynamic("value");
	call.setInt(dyn.getFunction(call));
}

private void typecast_t2d(GrCall call) {
    GrDynamicValue dyn;
    dyn.setString(call.meta);
	call.setDynamic(dyn);
}

private void typecast_d2t(GrCall call) {
    GrDynamicValue dyn = call.getDynamic("value");
	call.setInt(dyn.getTask(call));
}