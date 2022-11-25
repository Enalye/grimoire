/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
import std.stdio : writeln, write;
import std.string;
import std.datetime;
import std.conv : to;

import grimoire;

void main() {
    version (Windows) {
        import core.sys.windows.windows : SetConsoleOutputCP;

        SetConsoleOutputCP(65_001);
    }
    try {
        bool testBytecode = false;
        const GrLocale locale = GrLocale.fr_FR;
        auto startTime = MonoTime.currTime();
        GrLibrary stdlib = grLoadStdLibrary();

        GrCompiler compiler = new GrCompiler;
        compiler.addLibrary(stdlib);
        GrBytecode bytecode = compiler.compileFile("script/test.gr", GrOption.symbols, locale);
        if (!bytecode) {
            writeln(compiler.getError().prettify(locale));
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

        if (!engine.load(bytecode)) {
            writeln("bytecode incompatible");
            return;
        }

        engine.callEvent("main");

        write("> ");
        startTime = MonoTime.currTime();

        while (engine.hasTasks)
            engine.process();

        if (engine.isPanicking) {
            writeln("panique: " ~ engine.panicMessage);
            foreach (trace; engine.stackTraces) {
                writeln("[", trace.pc, "] in ", trace.name, " at ", trace.file,
                    "(", trace.line, ",", trace.column, ")");
            }
        }
        auto executionTime = MonoTime.currTime() - startTime;

        //Benchmark
        writeln("compilation took: \t", compilationTime);
        writeln("execution took: \t", executionTime);

        //writeln(engine.prettifyProfiling());
    }
    catch (Exception e) {
        writeln(e.msg);
        foreach (trace; e.info)
            writeln("at: ", trace);
    }
}
