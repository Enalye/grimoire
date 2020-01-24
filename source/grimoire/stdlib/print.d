/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.print;

import std.stdio: write, writeln;
import std.conv: to;
import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib)
void grLoadStdLibPrint(GrData data) {
    //print
	data.addPrimitive(&prints, "print", ["value"], [grString]);
	data.addPrimitive(&printb, "print", ["value"], [grBool]);
	data.addPrimitive(&printi, "print", ["value"], [grInt]);
	data.addPrimitive(&printf, "print", ["value"], [grFloat]);
	data.addPrimitive(&printni, "print", ["value"], [grIntArray]);
	data.addPrimitive(&printnf, "print", ["value"], [grFloatArray]);
	data.addPrimitive(&printns, "print", ["value"], [grStringArray]);

    //printl
    data.addPrimitive(&printls, "printl", ["value"], [grString]);
	data.addPrimitive(&printlb, "printl", ["value"], [grBool]);
	data.addPrimitive(&printli, "printl", ["value"], [grInt]);
	data.addPrimitive(&printlf, "printl", ["value"], [grFloat]);
	data.addPrimitive(&printlni, "printl", ["value"], [grIntArray]);
	data.addPrimitive(&printlnf, "printl", ["value"], [grFloatArray]);
	data.addPrimitive(&printlns, "printl", ["value"], [grStringArray]);
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

private void printnf(GrCall call) {
    auto ary = call.getFloatArray("value");
    write(ary.data);
}

private void printns(GrCall call) {
    auto ary = call.getStringArray("value");
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

private void printlnf(GrCall call) {
    auto ary = call.getFloatArray("value");
    writeln(ary.data);
}

private void printlns(GrCall call) {
    auto ary = call.getStringArray("value");
    writeln(ary.data);
}