/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.print;

import std.conv : to;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

package(grimoire.stdlib) void grLoadStdLibPrint(GrLibrary library) {
	//print
	library.addPrimitive(&_printi, "print", [grInt]);
	library.addPrimitive(&_printb, "print", [grBool]);
	library.addPrimitive(&_printf, "print", [grFloat]);
	library.addPrimitive(&_prints, "print", [grString]);
	library.addPrimitive(&_printni, "print", [grIntList]);
	library.addPrimitive(&_printnb, "print", [grBoolList]);
	library.addPrimitive(&_printnf, "print", [grFloatList]);
	library.addPrimitive(&_printns, "print", [grStringList]);

	//printl
	library.addPrimitive(&_printli, "printl", [grInt]);
	library.addPrimitive(&_printlb, "printl", [grBool]);
	library.addPrimitive(&_printlf, "printl", [grFloat]);
	library.addPrimitive(&_printls, "printl", [grString]);
	library.addPrimitive(&_printlni, "printl", [grIntList]);
	library.addPrimitive(&_printlnb, "printl", [grBoolList]);
	library.addPrimitive(&_printlnf, "printl", [grFloatList]);
	library.addPrimitive(&_printlns, "printl", [grStringList]);
}

// print
private void _prints(GrCall call) {
	_stdOut(call.getString(0));
}

private void _printb(GrCall call) {
	_stdOut(call.getBool(0) ? "true" : "false");
}

private void _printi(GrCall call) {
	_stdOut(to!string(call.getInt(0)));
}

private void _printf(GrCall call) {
	_stdOut(to!string(call.getFloat(0)));
}

private void _printni(GrCall call) {
	auto ary = call.getIntList(0);
	_stdOut(to!string(ary.data));
}

private void _printnb(GrCall call) {
	auto ary = call.getIntList(0);
	_stdOut(to!string(to!(GrBool[])(ary.data)));
}

private void _printnf(GrCall call) {
	auto ary = call.getFloatList(0);
	_stdOut(to!string(ary.data));
}

private void _printns(GrCall call) {
	auto ary = call.getStringList(0);
	_stdOut(to!string(ary.data));
}

// printl
private void _printls(GrCall call) {
	_stdOut(call.getString(0) ~ "\n");
}

private void _printlb(GrCall call) {
	_stdOut(call.getBool(0) ? "true\n" : "false\n");
}

private void _printli(GrCall call) {
	_stdOut(to!string(call.getInt(0)) ~ "\n");
}

private void _printlf(GrCall call) {
	_stdOut(to!string(call.getFloat(0)) ~ "\n");
}

private void _printlni(GrCall call) {
	auto ary = call.getIntList(0);
	_stdOut(to!string(ary.data) ~ "\n");
}

private void _printlnb(GrCall call) {
	auto ary = call.getIntList(0);
	_stdOut(to!string(to!(GrBool[])(ary.data)) ~ "\n");
}

private void _printlnf(GrCall call) {
	auto ary = call.getFloatList(0);
	_stdOut(to!string(ary.data) ~ "\n");
}

private void _printlns(GrCall call) {
	auto ary = call.getStringList(0);
	_stdOut(to!string(ary.data) ~ "\n");
}
