/**
    Log functions.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.stdlib.print;

import std.stdio: write, writeln;
import std.conv: to;
import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib)
void grLoadStdLibPrint() {
    //print
	grAddPrimitive(&prints, "print", ["value"], [grString]);
	grAddPrimitive(&printb, "print", ["value"], [grBool]);
	grAddPrimitive(&printi, "print", ["value"], [grInt]);
	grAddPrimitive(&printf, "print", ["value"], [grFloat]);
	grAddPrimitive(&printni, "print", ["value"], [grIntArray]);

    //printl
    grAddPrimitive(&printls, "printl", ["value"], [grString]);
	grAddPrimitive(&printlb, "printl", ["value"], [grBool]);
	grAddPrimitive(&printli, "printl", ["value"], [grInt]);
	grAddPrimitive(&printlf, "printl", ["value"], [grFloat]);
	grAddPrimitive(&printlni, "printl", ["value"], [grIntArray]);
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

private void printni(GrCall call) {
    auto ary = call.getIntArray("value");
    write(ary.data);
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

private void printlni(GrCall call) {
    auto ary = call.getIntArray("value");
    writeln(ary.data);
}