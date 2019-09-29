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

    //As float
    grAddCast(&typecast_i2r, "value", grInt, grFloat, true);

    //As string
	grAddCast(&typecast_i2s, "value", grInt, grString);
	grAddCast(&typecast_r2s, "value", grFloat, grString);
	grAddCast(&typecast_as2s, "value", grStringArray, grString);

    //As String Array
	grAddCast(&typecast_s2as, "value", grString, grStringArray);
}

//As int
private void typecast_r2i(GrCall call) {
    call.setInt(to!int(call.getFloat("value")));
}

private void typecast_b2i(GrCall call) {
    call.setInt(to!int(call.getBool("value")));
}

//As float
private void typecast_i2r(GrCall call) {
    call.setFloat(to!float(call.getInt("value")));
}

//As string
private void typecast_i2s(GrCall call) {
	call.setString(to!dstring(call.getInt("value")));
}

private void typecast_r2s(GrCall call) {
	call.setString(to!dstring(call.getFloat("value")));
}

private void typecast_as2s(GrCall call) {
    dstring result;
    foreach(const sub; call.getStringArray("value").data) {
        result ~= sub;
    }
	call.setString(result);
}

//As string array
private void typecast_s2as(GrCall call) {
    GrStringArray result = new GrStringArray;
    foreach(const sub; call.getString("value")) {
        result.data ~= to!dstring(sub);
    }
	call.setStringArray(result);
}