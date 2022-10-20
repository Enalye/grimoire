/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.typecast;

import std.conv;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

void grLoadStdLibTypecast(GrLibDefinition library) {
    library.setModule(["std", "typecast"]);

    //As int
    library.addCast(&typecast_r2i, grReal, grInt, true);
    library.addCast(&typecast_b2i, grBool, grInt);

    //As real
    library.addCast(&typecast_i2r, grInt, grReal);

    //As string
    library.addCast(&typecast_b2s, grBool, grString);
    library.addCast(&typecast_i2s, grInt, grString);
    library.addCast(&typecast_r2s, grReal, grString);
    library.addCast(&typecast_as2s, grPure(grList(grString)), grString);

    //As string list
    library.addCast(&typecast_s2as, grPure(grString), grList(grString));
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
    call.setString(to!GrStringValue(call.getInt(0)));
}

private void typecast_r2s(GrCall call) {
    call.setString(to!GrStringValue(call.getReal(0)));
}

private void typecast_as2s(GrCall call) {
    GrStringValue result;
    foreach (const ref sub; call.getList(0).getStrings()) {
        result ~= sub;
    }
    call.setString(result);
}

//As string list
private void typecast_s2as(GrCall call) {
    GrValue[] result;
    foreach (const ref sub; call.getString(0)) {
        result ~= GrValue(sub);
    }
    call.setList(result);
}
