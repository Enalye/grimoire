/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.print;

import std.stdio : write, writeln;
import std.conv : to;
import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibPrint(GrLibrary library) {
	//print
	library.addPrimitive(&_printi, "print", [grInt]);
	library.addPrimitive(&_printb, "print", [grBool]);
	library.addPrimitive(&_printf, "print", [grFloat]);
	library.addPrimitive(&_prints, "print", [grString]);
	library.addPrimitive(&_printni, "print", [grIntArray]);
	library.addPrimitive(&_printnb, "print", [grBoolArray]);
	library.addPrimitive(&_printnf, "print", [grFloatArray]);
	library.addPrimitive(&_printns, "print", [grStringArray]);

	//printl
	library.addPrimitive(&_printli, "printl", [grInt]);
	library.addPrimitive(&_printlb, "printl", [grBool]);
	library.addPrimitive(&_printlf, "printl", [grFloat]);
	library.addPrimitive(&_printls, "printl", [grString]);
	library.addPrimitive(&_printlni, "printl", [grIntArray]);
	library.addPrimitive(&_printlnb, "printl", [grBoolArray]);
	library.addPrimitive(&_printlnf, "printl", [grFloatArray]);
	library.addPrimitive(&_printlns, "printl", [grStringArray]);
}

// print
private void _prints(GrCall call) {
	write(call.getString(0));
}

private void _printb(GrCall call) {
	write(call.getBool(0) ? "true" : "false");
}

private void _printi(GrCall call) {
	write(call.getInt(0));
}

private void _printf(GrCall call) {
	write(call.getFloat(0));
}

private void _printni(GrCall call) {
	auto ary = call.getIntArray(0);
	write(ary.data);
}

private void _printnb(GrCall call) {
	auto ary = call.getIntArray(0);
	write(to!(bool[])(ary.data));
}

private void _printnf(GrCall call) {
	auto ary = call.getFloatArray(0);
	write(ary.data);
}

private void _printns(GrCall call) {
	auto ary = call.getStringArray(0);
	write(ary.data);
}

// printl
private void _printls(GrCall call) {
	writeln(call.getString(0));
}

private void _printlb(GrCall call) {
	writeln(call.getBool(0) ? "true" : "false");
}

private void _printli(GrCall call) {
	writeln(call.getInt(0));
}

private void _printlf(GrCall call) {
	writeln(call.getFloat(0));
}

private void _printlni(GrCall call) {
	auto ary = call.getIntArray(0);
	writeln(ary.data);
}

private void _printlnb(GrCall call) {
	auto ary = call.getIntArray(0);
	writeln(to!(bool[])(ary.data));
}

private void _printlnf(GrCall call) {
	auto ary = call.getFloatArray(0);
	writeln(ary.data);
}

private void _printlns(GrCall call) {
	auto ary = call.getStringArray(0);
	writeln(ary.data);
}
