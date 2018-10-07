/**
    Log functions.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module lib.io.print;

import std.stdio: write, writeln;
import std.conv: to;
import lib.api;

void grLib_std_io_print_load() {
	grLib_addPrimitive(&prints, "print", ["value"], [grString]);
	grLib_addPrimitive(&printb, "print", ["value"], [grBool]);
	grLib_addPrimitive(&printi, "print", ["value"], [grInt]);
	grLib_addPrimitive(&printf, "print", ["value"], [grFloat]);
	grLib_addPrimitive(&printa, "print", ["value"], [grDynamic]);
	grLib_addPrimitive(&printn, "print", ["value"], [grArray]);
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