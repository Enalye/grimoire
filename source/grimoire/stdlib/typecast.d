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
    library.addCast(&typecast_as2s, grPureStringArray, grString);

    //As string array
    library.addCast(&typecast_s2as, grPureString, grStringArray);
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
    call.setString(to!GrString(call.getInt(0)));
}

private void typecast_r2s(GrCall call) {
    call.setString(to!GrString(call.getReal(0)));
}

private void typecast_as2s(GrCall call) {
    GrString result;
    foreach (const ref sub; call.getArray(0).data) {
        result ~= sub.getString();
    }
    call.setString(result);
}

//As string array
private void typecast_s2as(GrCall call) {
    GrArray result = new GrArray;
    foreach (const ref sub; call.getString(0)) {
        result.data ~= GrValue(to!GrString(sub));
    }
    call.setArray(result);
}
