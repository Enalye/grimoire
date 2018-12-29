/**
    Log functions.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.lib.io.print;

import std.stdio: write, writeln;
import std.conv: to;
import grimoire.lib.api;

static this() {
	grAddPrimitive(&prints, "print", ["value"], [grString]);
	grAddPrimitive(&printb, "print", ["value"], [grBool]);
	grAddPrimitive(&printi, "print", ["value"], [grInt]);
	grAddPrimitive(&printf, "print", ["value"], [grFloat]);
	grAddPrimitive(&printa, "print", ["value"], [grDynamic]);
	grAddPrimitive(&printn, "print", ["value"], [grArray]);
}

private void prints(GrCall call) {
	writeln(call.getString("value"));
}

private void printb(GrCall call) {
	writeln(call.getBool("value") ? "true" : "false");
}

private void printi(GrCall call) {
	writeln(call.getInt("value"));
}

private void printf(GrCall call) {
	writeln(call.getFloat("value"));
}

private void printa(GrCall call) {
	writeln(call.getDynamic("value").getString());
}

private void printn(GrCall call) {
    const auto ary = call.getArray("value");
    string result = "[";
    int i;
    foreach(value; ary) {
        result ~= to!string(value.getString());
        if((i + 2) <= ary.length)
            result ~= ", ";
        i ++;
    }
    result ~= "]";
    writeln(result);
}