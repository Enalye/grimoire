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

        GrCompiler compiler = new GrCompiler;
        compiler.addLibrary(stdlib);
        GrBytecode bytecode = compiler.compileFile("script/test.gr", GrCompiler.Flags.none);
        if (!bytecode) {
            writeln(compiler.getError().prettify());
            return;
        }
        bytecode.save("test.grb");
        bytecode = null;

        auto compilationTime = MonoTime.currTime() - startTime;

        bytecode = new GrBytecode;
        bytecode.load("test.grb");
        writeln(grDump(bytecode));

        GrEngine engine = new GrEngine;
        engine.addLibrary(stdlib);
        engine.load(bytecode);
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
