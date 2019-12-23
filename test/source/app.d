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

/// Format compilation problems and throw an exception with them.
void printError(GrError error) {
    string report;
    
    report ~= "\033[0;91merror";
    //report ~= "\033[0;93mwarning";

    //Error report
    report ~= "\033[37;1m: " ~ error.message ~ "\033[0m\n";

    //File path
    string lineNumber = to!string(error.line) ~ "| ";
    foreach(x; 1 .. lineNumber.length)
        report ~= " ";

    report ~= "\033[0;36m->\033[0m "
        ~ error.filePath
        ~ "(" ~ to!string(error.line)
        ~ "," ~ to!string(error.column)
        ~ ")\n";
    
    report ~= "\033[0;36m";

    foreach(x; 1 .. lineNumber.length)
        report ~= " ";
    report ~= "\033[0;36m|\n";

    //Script snippet
    report ~= " " ~ lineNumber;
    report ~= "\033[1;34m" ~ error.lineText ~ "\033[0;36m\n";

    //Red underline
    foreach(x; 1 .. lineNumber.length)
        report ~= " ";
    report ~= "\033[0;36m|";
    foreach(x; 0 .. error.column)
        report ~= " ";

    report ~= "\033[1;31m"; //Red color
    //report ~= "\033[1;93m"; //Orange color

    foreach(x; 0 .. error.textLength)
        report ~= "^";
    
    //Error description
    report ~= "\033[0;31m"; //Red color
    //report ~= "\033[0;93m"; //Orange color

    if(error.info.length)
        report ~= "  " ~ error.info;
    report ~= "\n";

    foreach(x; 1 .. lineNumber.length)
        report ~= " ";
    report ~= "\033[0;36m|\033[0m\nCompilation aborted...";
    
    writeln(report);
}

void main() {
	try {
        auto startTime = MonoTime.currTime();
        GrData data = new GrData;
        grLoadStdLibrary(data);

        GrBytecode bytecode;
        GrCompiler compiler = new GrCompiler(data);
        if(!compiler.compileFile(bytecode, "script/test.gr")) {
            printError(compiler.getError());
            return;
        }

        auto compilationTime = MonoTime.currTime() - startTime;
        
        writeln(grDump(data, bytecode));

        GrEngine vm = new GrEngine;
        vm.load(data, bytecode);
        vm.spawn();
        
        write("> ");
        startTime = MonoTime.currTime();

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
