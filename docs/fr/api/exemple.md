# Exemple

```d
// Bibliothèques
GrLibrary stdlib = grLoadStdLibrary();

// Compilation
GrCompiler compiler = new GrCompiler;
compiler.addLibrary(stdlib);
GrBytecode bytecode = compiler.compileFile("script.gr", GrOption.symbols, GrLocale.fr_FR);
if (!bytecode) {
    writeln(compiler.getError().prettify(locale));
    return;
}

// Exécution
GrEngine engine = new GrEngine;
engine.addLibrary(stdlib);
engine.load(bytecode);

if (engine.hasEvent("main"))
    engine.callEvent("main");

while (engine.hasTasks)
    engine.process();

// Erreurs
if (engine.isPanicking) {
    writeln("panic: " ~ engine.panicMessage);
    foreach (trace; engine.stackTraces) {
        writeln("[", trace.pc, "] in ", trace.name, " at ", trace.file,
            "(", trace.line, ",", trace.column, ")");
    }
}
```