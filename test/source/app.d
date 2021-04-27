/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
import std.stdio : writeln, write;
import std.string;
import std.datetime;
import std.conv : to;

import grimoire;

void main() {
    try {
        auto startTime = MonoTime.currTime();
        GrLibrary stdlib = grLoadStdLibrary();

        GrData data = new GrData;
        data.addLibrary(stdlib);
        GrBytecode bytecode;
        GrCompiler compiler = new GrCompiler(data);
        if (!compiler.compileFile(bytecode, "script/test.gr", GrCompiler.Flags.none)) {
            writeln(compiler.getError().prettify());
            return;
        }

        auto compilationTime = MonoTime.currTime() - startTime;

        writeln(grDump(data, bytecode));

        GrEngine engine = new GrEngine;
        engine.load(data, bytecode);
        engine.spawn();

        write("> ");
        startTime = MonoTime.currTime();

        while (engine.hasCoroutines)
            engine.process();
        if (engine.isPanicking)
            writeln("unhandled error: " ~ to!string(engine.panicMessage));
        auto executionTime = MonoTime.currTime() - startTime;

        //Benchmark
        writeln("Compilation took: \t", compilationTime);
        writeln("Execution took: \t", executionTime);
        //writeln("Size of engine: ", GrEngine.classinfo.init.length, " Size of context: ", GrContext.classinfo.init.length);

        writeln(engine.prettifyProfiling());
    }
    catch (Exception e) {
        writeln(e.msg);
        foreach (trace; e.info)
            writeln("at: ", trace);
    }
}
