/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
import std.stdio: writeln, write;
import std.string;
import std.algorithm.comparison;
import std.datetime;
import std.conv: to;

import grimoire;

/// Format the error and prints it.
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

/// Format the profiling results and prints them.
void printProfilingResults(GrEngine engine) {
    ulong functionNameLength = 10;
    ulong countLength = 10;
    ulong totalLength = 10;
    ulong averageLength = 10;
    foreach(func; engine.dumpProfiling()) {
        functionNameLength = max(func.name.length, functionNameLength);
        countLength = max(to!string(func.count).length, countLength);
        totalLength = max(to!string(func.total.total!"msecs").length, totalLength);
        Duration average = func.count ? (func.total / func.count) : Duration.zero;
        averageLength = max(to!string(average.total!"msecs").length, averageLength);
    }

    writeln("> Profiling results:");
    string header =
        "| " ~ leftJustify("Function", functionNameLength) ~
        " | " ~ leftJustify("Count", countLength) ~
        " | " ~ leftJustify("Total", totalLength) ~
        " | " ~ leftJustify("Average", averageLength)
        ~ " |";

    string separator = "+" ~
        leftJustify("", functionNameLength + 2, '-')  ~ "+" ~ 
        leftJustify("", countLength + 2, '-')  ~ "+" ~ 
        leftJustify("", totalLength + 2, '-')  ~ "+" ~ 
        leftJustify("", averageLength + 2, '-')  ~ "+";
    writeln(separator);
    writeln(header);
    writeln(separator);
    foreach(func; engine.dumpProfiling()) {
        Duration average = func.count ? (func.total / func.count) : Duration.zero;
        writeln(
            "| ",
            leftJustify(func.name, functionNameLength), " | ",
            leftJustify(to!string(func.count), countLength), " | ",
            leftJustify(to!string(func.total.total!"msecs"), totalLength), " | ",
            leftJustify(to!string(average.total!"msecs"), averageLength), " |");
    }
    writeln(separator);
}

void main() {
	try {
        auto startTime = MonoTime.currTime();
        GrData data = new GrData;
        grLoadStdLibrary(data);

        GrBytecode bytecode;
        GrCompiler compiler = new GrCompiler(data);
        if(!compiler.compileFile(bytecode, "script/test.gr", GrCompiler.Flags.profile)) {
            printError(compiler.getError());
            return;
        }

        auto compilationTime = MonoTime.currTime() - startTime;
        
        writeln(grDump(data, bytecode));

        GrEngine engine = new GrEngine;
        engine.load(data, bytecode);
        engine.spawn();
        
        write("> ");
        startTime = MonoTime.currTime();

        while(engine.hasCoroutines)
            engine.process();
        if(engine.isPanicking)
            writeln("Unhandled Exception: " ~ to!string(engine.panicMessage));
        auto executionTime = MonoTime.currTime() - startTime;
            
        //Benchmark
        writeln("Compilation took: \t", compilationTime);
        writeln("Execution took: \t", executionTime);
        //writeln("Size of engine: ", GrEngine.classinfo.init.length, " Size of context: ", GrContext.classinfo.init.length);

        printProfilingResults(engine);
    }
	catch(Exception e) {
		writeln(e.msg);
	}
}
