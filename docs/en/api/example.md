# Example

```d
// Libraries
GrModuleDef stdlib = grLoadStdLibrary();

// Compilation
GrCompiler compiler = new GrCompiler;
compiler.addLibrary(stdlib);
compiler.addSource(`
event main() {
    print("Hello World !");
}`);

GrBytecode bytecode = compiler.compile(GrOption.symbols, GrLocale.en_US);
if (!bytecode) {
    writeln(compiler.getError().prettify(locale));
    return;
}

// Execution
GrEngine engine = new GrEngine;
engine.addLibrary(stdlib);
engine.load(bytecode);

engine.callEvent("main");

while (engine.hasTasks)
    engine.process();

// Errors
if (engine.isPanicking) {
    writeln("panic: " ~ engine.panicMessage);
    foreach (trace; engine.stackTraces) {
        writeln("[", trace.pc, "] in ", trace.name, " at ", trace.file,
            "(", trace.line, ",", trace.column, ")");
    }
}
```