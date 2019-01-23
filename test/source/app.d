/**
    Test application.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

import std.stdio: writeln, write;
import std.datetime;
import std.conv: to;

import grimoire;

void main() {
	try {
        auto startTime = MonoTime.currTime();
        auto bytecode = grCompileFile("test.gr");
        auto compilationTime = MonoTime.currTime() - startTime;
        
        writeln(grDump(bytecode));

        GrEngine vm = new GrEngine;
        vm.load(bytecode);
        vm.spawn();
        
        write("> ");
        startTime = MonoTime.currTime();
        auto mangledName = grMangleNamedFunction("hey", []);
        if(vm.hasEvent(mangledName)) {
            GrContext ev = vm.spawnEvent(mangledName);
        }

        while(vm.hasCoroutines)
            vm.process();
        if(vm.isPanicking)
            writeln("Unhandled Exception: " ~ to!string(vm.panicMessage));
        auto executionTime = MonoTime.currTime() - startTime;
            
        //Benchmark
        writeln("Compilation took: \t", compilationTime);
        writeln("Execution took: \t", executionTime);
        //writeln("Size of engine: ", GrEngine.classinfo.init.length, " Size of context: ", GrContext.classinfo.init.length);
    }
	catch(Exception e) {
		writeln(e.msg);
	}
}
