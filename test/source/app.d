/**
    Test application.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

import std.stdio: writeln;
import std.datetime;
import std.conv: to;

import grimoire;

void main() {
	try {
        auto startTime = MonoTime.currTime();
        auto bytecode = grCompiler_compileFile("test.grimoire");
        auto compilationTime = MonoTime.currTime() - startTime;

        writeln(grBytecode_dump(bytecode));
        GrVM vm = new GrVM;
        vm.load(bytecode);
        vm.spawn();
        
        startTime = MonoTime.currTime();
        while(vm.hasCoroutines)
            vm.process();
        if(vm.isPanicking)
            writeln("Unhandled Exception: " ~ to!string(vm.panicMessage));
        auto executionTime = MonoTime.currTime() - startTime;

        writeln("Compilation took: \t", compilationTime.total!"usecs", " us");
        writeln("Execution took: \t", executionTime.total!"usecs", " us");
	}
	catch(Exception e) {
		writeln(e.msg);
	}
}
