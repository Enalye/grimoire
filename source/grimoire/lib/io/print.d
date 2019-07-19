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
    //print
	grAddPrimitive(&prints, "print", ["value"], [grString]);
	grAddPrimitive(&printb, "print", ["value"], [grBool]);
	grAddPrimitive(&printi, "print", ["value"], [grInt]);
	grAddPrimitive(&printf, "print", ["value"], [grFloat]);
	grAddPrimitive(&printv, "print", ["value"], [grVariant]);
	grAddPrimitive(&printn, "print", ["value"], [grArray]);

    //printl
    grAddPrimitive(&printls, "printl", ["value"], [grString]);
	grAddPrimitive(&printlb, "printl", ["value"], [grBool]);
	grAddPrimitive(&printli, "printl", ["value"], [grInt]);
	grAddPrimitive(&printlf, "printl", ["value"], [grFloat]);
	grAddPrimitive(&printlv, "printl", ["value"], [grVariant]);
	grAddPrimitive(&println, "printl", ["value"], [grArray]);
}

// print
private void prints(GrCall call) {
	write(call.getString("value"));
}

private void printb(GrCall call) {
	write(call.getBool("value") ? "true" : "false");
}

private void printi(GrCall call) {
	write(call.getInt("value"));
}

private void printf(GrCall call) {
	write(call.getFloat("value"));
}

private void printv(GrCall call) {
	write(call.getVariant("value").getString(call));
}

private void printn(GrCall call) {
    auto ary = call.getArray("value");
    write(ary.getString(call));
}

// printl

private void printls(GrCall call) {
	writeln(call.getString("value"));
}

private void printlb(GrCall call) {
	writeln(call.getBool("value") ? "true" : "false");
}

private void printli(GrCall call) {
	writeln(call.getInt("value"));
}

private void printlf(GrCall call) {
	writeln(call.getFloat("value"));
}

private void printlv(GrCall call) {
	writeln(call.getVariant("value").getString(call));
}

private void println(GrCall call) {
    auto ary = call.getArray("value");
    writeln(ary.getString(call));
}