/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.typecast;

import std.conv;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibTypecast(GrLibrary library) {
    //As int
    library.addCast(&typecast_r2i, grReal, grInt, true);
    library.addCast(&typecast_b2i, grBool, grInt);

    //As real
    library.addCast(&typecast_i2r, grInt, grReal);

    //As string
    library.addCast(&typecast_b2s, grBool, grString);
    library.addCast(&typecast_i2s, grInt, grString);
    library.addCast(&typecast_r2s, grReal, grString);
    library.addCast(&typecast_as2s, grPure(grArray(grString)), grString);

    //As string array
    library.addCast(&typecast_s2as, grPure(grString), grArray(grString));
}

//As int
private void typecast_r2i(GrCall call) {
    call.setInt(to!GrInt(call.getReal(0)));
}

private void typecast_b2i(GrCall call) {
    call.setInt(to!GrInt(call.getBool(0)));
}

//As real
private void typecast_i2r(GrCall call) {
    call.setReal(to!GrReal(call.getInt(0)));
}

//As string
private void typecast_b2s(GrCall call) {
    call.setString(call.getBool(0) ? "true" : "false");
}

private void typecast_i2s(GrCall call) {
    call.setString(to!GrStr(call.getInt(0)));
}

private void typecast_r2s(GrCall call) {
    call.setString(to!GrStr(call.getReal(0)));
}

private void typecast_as2s(GrCall call) {
    GrStr result;
    foreach (const ref sub; call.getArray(0).data) {
        result ~= sub.getStringData();
    }
    call.setString(result);
}

//As string array
private void typecast_s2as(GrCall call) {
    GrValue[] result;
    foreach (const ref sub; call.getStringData(0)) {
        result ~= GrValue(to!GrStr(sub));
    }
    call.setArray(result);
}
