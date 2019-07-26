/**
    Explicit typecast library.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.stdlib.typecast;

import std.conv;
import grimoire.compiler, grimoire.runtime;


package(grimoire.stdlib)
void grLoadStdLibTypecast() {
    //As int
    grAddCast(&typecast_r2i, "value", grFloat, grInt, true);
    grAddCast(&typecast_b2i, "value", grBool, grInt);
	grAddCast(&typecast_v2i, "value", grVariant, grInt);

    //As float
    grAddCast(&typecast_i2r, "value", grInt, grFloat, true);
	grAddCast(&typecast_v2r, "value", grVariant, grFloat);

    //As bool
	grAddCast(&typecast_v2b, "value", grVariant, grBool);

    //As Array
	grAddCast(&typecast_s2n, "value", grString, grArray);
	grAddCast(&typecast_v2n, "value", grVariant, grArray);


    //As string
	grAddCast(&typecast_i2s, "value", grInt, grString);
	grAddCast(&typecast_r2s, "value", grFloat, grString);
	grAddCast(&typecast_v2s, "value", grVariant, grString);

    //As dynamic value
	grAddCast(&typecast_b2v, "value", grBool, grVariant);
	grAddCast(&typecast_i2v, "value", grInt, grVariant);
	grAddCast(&typecast_r2v, "value", grFloat, grVariant);
	grAddCast(&typecast_s2v, "value", grString, grVariant);
	grAddCast(&typecast_n2v, "value", grArray, grVariant);

    GrType anonFunc = GrBaseType.FunctionType;
    anonFunc.mangledType = grMangleNamedFunction("", []);
	grAddCast(&typecast_f2v, "value", anonFunc, grVariant);
	grAddCast(&typecast_v2f, "value", grVariant, anonFunc);

    GrType anonTask = GrBaseType.TaskType;
    anonTask.mangledType = grMangleNamedFunction("", []);
	grAddCast(&typecast_t2v, "value", anonTask, grVariant);
	grAddCast(&typecast_v2t, "value", grVariant, anonTask);

    GrType structType = GrBaseType.StructType;
	grAddCast(&typecast_p2v, "value", structType, grVariant);
	grAddCast(&typecast_v2p, "value", grVariant, structType);

    GrType userType = GrBaseType.UserType;
	grAddCast(&typecast_u2v, "value", userType, grVariant);
	grAddCast(&typecast_v2u, "value", grVariant, userType);

    GrType chanType = GrBaseType.ChanType;
	grAddCast(&typecast_c2v, "value", chanType, grVariant);
	grAddCast(&typecast_v2c, "value", grVariant, chanType);
}

//As int
private void typecast_r2i(GrCall call) {
    call.setInt(to!int(call.getFloat("value")));
}

private void typecast_b2i(GrCall call) {
    call.setInt(to!int(call.getBool("value")));
}

private void typecast_v2i(GrCall call) {
    call.setInt(call.getVariant("value").getInt(call));
}

//As float
private void typecast_i2r(GrCall call) {
    call.setFloat(to!float(call.getInt("value")));
}

private void typecast_v2r(GrCall call) {
    call.setFloat(call.getVariant("value").getFloat(call));
}

//As bool
private void typecast_v2b(GrCall call) {
    call.setBool(call.getVariant("value").getBool(call) > 0);
}

//As array
private void typecast_s2n(GrCall call) {
    GrArray array = new GrArray;
    foreach(c; call.getString("value")) {
        GrVariant variant;
        variant.setString(to!dstring(c));
        array.data ~= variant;
    }
	call.setArray(array);
}

private void typecast_v2n(GrCall call) {
    call.setArray(call.getVariant("value").getArray(call));
}

//As string
private void typecast_i2s(GrCall call) {
	call.setString(to!dstring(call.getInt("value")));
}

private void typecast_r2s(GrCall call) {
	call.setString(to!dstring(call.getFloat("value")));
}

private void typecast_v2s(GrCall call) {
    call.setString(call.getVariant("value").getString(call));
}

//As dynamic value
private void typecast_b2v(GrCall call) {
    GrVariant dyn;
    dyn.setBool(call.getBool("value"));
	call.setVariant(dyn);
}

private void typecast_i2v(GrCall call) {
    GrVariant dyn;
    dyn.setInt(call.getInt("value"));
	call.setVariant(dyn);
}

private void typecast_r2v(GrCall call) {
    GrVariant dyn;
    dyn.setFloat(call.getFloat("value"));
	call.setVariant(dyn);
}

private void typecast_s2v(GrCall call) {
    GrVariant dyn;
    dyn.setString(call.getString("value"));
	call.setVariant(dyn);
}

private void typecast_n2v(GrCall call) {
    GrVariant dyn;
    dyn.setArray(call.getArray("value"));
	call.setVariant(dyn);
}

private void typecast_f2v(GrCall call) {
    GrVariant dyn;
    dyn.setFunction(call.getInt("value"), call.meta);
	call.setVariant(dyn);
}

private void typecast_v2f(GrCall call) {
    GrVariant dyn = call.getVariant("value");
	call.setInt(dyn.getFunction(call));
}

private void typecast_t2v(GrCall call) {
    GrVariant dyn;
    dyn.setTask(call.getInt("value"), call.meta);
	call.setVariant(dyn);
}

private void typecast_v2t(GrCall call) {
    GrVariant dyn = call.getVariant("value");
	call.setInt(dyn.getTask(call));
}

private void typecast_p2v(GrCall call) {
    GrVariant dyn;
    dyn.setStruct(call.getUserData!(void*)("value"), call.meta);
	call.setVariant(dyn);
}

private void typecast_v2p(GrCall call) {
    GrVariant dyn = call.getVariant("value");
	call.setUserData(dyn.getStruct(call));
}

private void typecast_u2v(GrCall call) {
    GrVariant dyn;
    dyn.setUserData(call.getUserData!(void*)("value"), call.meta);
	call.setVariant(dyn);
}

private void typecast_v2u(GrCall call) {
    GrVariant dyn = call.getVariant("value");
	call.setUserData(dyn.getUserData(call));
}

private void typecast_c2v(GrCall call) {
    GrVariant dyn;
    dyn.setChannel(call.getUserData!(void*)("value"), call.meta);
	call.setVariant(dyn);
}

private void typecast_v2c(GrCall call) {
    GrVariant dyn = call.getVariant("value");
	call.setUserData(dyn.getChannel(call));
}

