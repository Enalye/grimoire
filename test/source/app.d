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
        // Options
        bool testBytecode = false;
        bool showBytecode = true;

        const GrLocale locale = GrLocale.fr_FR;
        auto startTime = MonoTime.currTime();
        GrLibrary stdlib = grLoadStdLibrary();

        GrCompiler compiler = new GrCompiler;
        compiler.addLibrary(stdlib);

        compiler.addFile("script/test.gr");

        GrBytecode bytecode = compiler.compile(GrOption.symbols | GrOption.safe, locale);
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
        if (showBytecode) {
            writeln(bytecode.prettify());
        }

        GrEngine engine = new GrEngine;
        engine.addLibrary(stdlib);

        if (!engine.load(bytecode)) {
            writeln("bytecode incompatible");
            return;
        }

        engine.callEvent("app");

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
