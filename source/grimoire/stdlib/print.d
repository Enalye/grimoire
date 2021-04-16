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
	data.addPrimitive(&_printi, "print", ["value"], [grInt]);
	data.addPrimitive(&_printb, "print", ["value"], [grBool]);
	data.addPrimitive(&_printf, "print", ["value"], [grFloat]);
	data.addPrimitive(&_prints, "print", ["value"], [grString]);
	data.addPrimitive(&_printni, "print", ["value"], [grIntArray]);
	data.addPrimitive(&_printnb, "print", ["value"], [grBoolArray]);
	data.addPrimitive(&_printnf, "print", ["value"], [grFloatArray]);
	data.addPrimitive(&_printns, "print", ["value"], [grStringArray]);

    //printl
	data.addPrimitive(&_printli, "printl", ["value"], [grInt]);
	data.addPrimitive(&_printlb, "printl", ["value"], [grBool]);
	data.addPrimitive(&_printlf, "printl", ["value"], [grFloat]);
    data.addPrimitive(&_printls, "printl", ["value"], [grString]);
	data.addPrimitive(&_printlni, "printl", ["value"], [grIntArray]);
	data.addPrimitive(&_printlnb, "printl", ["value"], [grBoolArray]);
	data.addPrimitive(&_printlnf, "printl", ["value"], [grFloatArray]);
	data.addPrimitive(&_printlns, "printl", ["value"], [grStringArray]);
}

// print
private void _prints(GrCall call) {
	write(call.getString("value"));
}

private void _printb(GrCall call) {
	write(call.getBool("value") ? "true" : "false");
}

private void _printi(GrCall call) {
	write(call.getInt("value"));
}

private void _printf(GrCall call) {
	write(call.getFloat("value"));
}

private void _printni(GrCall call) {
    auto ary = call.getIntArray("value");
    write(ary.data);
}

private void _printnb(GrCall call) {
    auto ary = call.getIntArray("value");
    write(to!(bool[])(ary.data));
}

private void _printnf(GrCall call) {
    auto ary = call.getFloatArray("value");
    write(ary.data);
}

private void _printns(GrCall call) {
    auto ary = call.getStringArray("value");
    write(ary.data);
}

// printl
private void _printls(GrCall call) {
	writeln(call.getString("value"));
}

private void _printlb(GrCall call) {
	writeln(call.getBool("value") ? "true" : "false");
}

private void _printli(GrCall call) {
	writeln(call.getInt("value"));
}

private void _printlf(GrCall call) {
	writeln(call.getFloat("value"));
}

private void _printlni(GrCall call) {
    auto ary = call.getIntArray("value");
    writeln(ary.data);
}

private void _printlnb(GrCall call) {
    auto ary = call.getIntArray("value");
    writeln(to!(bool[])(ary.data));
}

private void _printlnf(GrCall call) {
    auto ary = call.getFloatArray("value");
    writeln(ary.data);
}

private void _printlns(GrCall call) {
    auto ary = call.getStringArray("value");
    writeln(ary.data);
}