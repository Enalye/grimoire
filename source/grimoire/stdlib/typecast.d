/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.typecast;

import std.conv;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibTypecast(GrLibrary library, GrLocale locale) {
    //As int
    library.addCast(&typecast_r2i, grFloat, grInt, true);
    library.addCast(&typecast_b2i, grBool, grInt);

    //As GrFloat
    library.addCast(&typecast_i2r, grInt, grFloat);

    //As string
    library.addCast(&typecast_b2s, grBool, grString);
    library.addCast(&typecast_i2s, grInt, grString);
    library.addCast(&typecast_r2s, grFloat, grString);
    library.addCast(&typecast_as2s, grStringList, grString);

    //As String List
    library.addCast(&typecast_s2as, grString, grStringList);
}

//As int
private void typecast_r2i(GrCall call) {
    call.setInt(to!GrInt(call.getFloat(0)));
}

private void typecast_b2i(GrCall call) {
    call.setInt(to!GrInt(call.getBool(0)));
}

//As float
private void typecast_i2r(GrCall call) {
    call.setFloat(to!GrFloat(call.getInt(0)));
}

//As string
private void typecast_b2s(GrCall call) {
    call.setString(call.getBool(0) ? "true" : "false");
}

private void typecast_i2s(GrCall call) {
    call.setString(to!GrString(call.getInt(0)));
}

private void typecast_r2s(GrCall call) {
    call.setString(to!GrString(call.getFloat(0)));
}

private void typecast_as2s(GrCall call) {
    GrString result;
    foreach (const sub; call.getStringList(0).data) {
        result ~= sub;
    }
    call.setString(result);
}

//As string list
private void typecast_s2as(GrCall call) {
    GrStringList result = new GrStringList;
    foreach (const sub; call.getString(0)) {
        result.data ~= to!GrString(sub);
    }
    call.setStringList(result);
}
