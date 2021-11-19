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
        bool testBytecode = true;
        auto startTime = MonoTime.currTime();
        GrLibrary stdlib = grLoadStdLibrary();

        GrCompiler compiler = new GrCompiler;
        compiler.addLibrary(stdlib);
        GrBytecode bytecode = compiler.compileFile("script/test.gr", GrOption.symbols);
        if (!bytecode) {
            writeln(compiler.getError().prettify());
            return;
        }
        if (testBytecode) {
            bytecode.save("test.grb");
            bytecode = null;
        }

        auto compilationTime = MonoTime.currTime() - startTime;

        if (testBytecode) {
            bytecode = new GrBytecode;
            bytecode.load("test.grb");
        }
        writeln(grDump(bytecode));

        GrEngine engine = new GrEngine;
        engine.addLibrary(stdlib);
        engine.load(bytecode);

        if(engine.hasAction("test"))
            engine.callAction("test");

        write("> ");
        startTime = MonoTime.currTime();

        while (engine.hasCoroutines)
            engine.process();
        if (engine.isPanicking) {
            writeln("panic: " ~ to!string(engine.panicMessage));
            foreach (trace; engine.stackTraces) {
                writeln("[", trace.pc, "] in ", trace.name, " at ", trace.file,
                        "(", trace.line, ",", trace.column, ")");
            }
        }
        auto executionTime = MonoTime.currTime() - startTime;

        //Benchmark
        writeln("compilation took: \t", compilationTime);
        writeln("execution took: \t", executionTime);
        //writeln("Size of engine: ", GrEngine.classinfo.init.length, " Size of context: ", GrContext.classinfo.init.length);

        //writeln(engine.prettifyProfiling());
    }
    catch (Exception e) {
        writeln(e.msg);
        foreach (trace; e.info)
            writeln("at: ", trace);
    }
}
