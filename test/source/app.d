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
        GrData data = new GrData;
        grLoadStdLibrary(data);

        auto bytecode = grCompileFile(data, "script/test.gr");
        auto compilationTime = MonoTime.currTime() - startTime;
        
        writeln(grDump(data, bytecode));

        GrEngine vm = new GrEngine;
        vm.load(data, bytecode);
        vm.spawn();
        
        write("> ");
        startTime = MonoTime.currTime();
        /*auto mangledName = grMangleNamedFunction("hey", [grString]);
        if(vm.hasEvent(mangledName)) {
            GrContext ev = vm.spawnEvent(mangledName);
            ev.setString("you !");
        }*/

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
