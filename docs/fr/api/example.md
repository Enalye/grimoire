# Exemple

```d
// Bibliothèques
GrLibrary stdlib = grLoadStdLibrary();

// Compilation
GrCompiler compiler = new GrCompiler;
compiler.addLibrary(stdlib);
compiler.addSource(`
event main() {
    print("Hello World !");
}`);

GrBytecode bytecode = compiler.compileFile(GrOption.symbols, GrLocale.fr_FR);
if (!bytecode) {
    writeln(compiler.getError().prettify(locale));
    return;
}

// Exécution
GrEngine engine = new GrEngine;
engine.addLibrary(stdlib);
engine.load(bytecode);

engine.callEvent("main");

while (engine.hasTasks)
    engine.process();

// Erreurs
if (engine.isPanicking) {
    writeln("panique: " ~ engine.panicMessage);
    foreach (trace; engine.stackTraces) {
        writeln("[", trace.pc, "] dans ", trace.name, " à ", trace.file,
            "(", trace.line, ",", trace.column, ")");
    }
}
```