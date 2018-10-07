/**
    Explicit typecast library.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module lib.type.typecast;

import std.conv;
import lib.api;

void grLib_std_type_typecast_load() {
    //As int
    grLib_addCast(&typecast_f2i, "value", grFloat, grInt, true);
    grLib_addCast(&typecast_b2i, "value", grBool, grInt);

    //As float
    grLib_addCast(&typecast_i2f, "value", grInt, grFloat, true);

    //As bool

    //As Array
	grLib_addCast(&typecast_s2n, "value", grString, grArray);


    //As string
	grLib_addCast(&typecast_i2s, "value", grInt, grString);
	grLib_addCast(&typecast_f2s, "value", grFloat, grString);
}

//As int
private void typecast_f2i(GrCall call) {
    //call._context.istack ~= to!int(call._context.fstack[$ - 1]);
    //call._context.fstack.length --;
    //call.setInt(to!int(call.getParameterDbg!float));
    call.setInt(to!int(call.getFloat("value")));

    //call._context.istack ~= to!int(call.getFloat("value"));

    //call.setInt(to!int(call._context.fstack[$ - 1]));
    //call._context.fstack.length -= 1;
}

private void typecast_b2i(GrCall call) {
    call.setInt(to!int(call.getBool("value")));
}

//As float
private void typecast_i2f(GrCall call) {
    call.setFloat(to!float(call.getInt("value")));
}

//As bool


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

//As string
private void typecast_i2s(GrCall call) {
	call.setString(to!dstring(call.getInt("value")));
}

private void typecast_f2s(GrCall call) {
	call.setString(to!dstring(call.getFloat("value")));
}