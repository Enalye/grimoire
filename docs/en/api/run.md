# Exécution

The execution of a Grimoire program is done through events `event`.
```d
GrEngine engine = new GrEngine;
engine.load(bytecode);

engine.callEvent("main");
```

Required libraries must be added before loading the bytecode.
```d
GrModuleDef stdlib = grLoadStdLibrary();

GrEngine engine = new GrEngine;
engine.addLibrary(stdlib);
engine.load(bytecode);

engine.callEvent("main");
```
**Important:** All the libraries must be included both in the compiler **and** in the virtual machine in the **same order**.

The method `process()` allow the program's tasks to be run until they exit or until they are suspended.
```d
engine.process();
```

To execute the program whole, you can loop over the process.
```d
while (engine.hasTasks)
    engine.process();
```

Meanwhile, the virtual machine can panic.
```d
while (engine.hasTasks)
    engine.process();

if (engine.isPanicking) {
    writeln("panic: " ~ engine.panicMessage);
    foreach (trace; engine.stackTraces) {
        writeln("[", trace.pc, "] in ", trace.name, " at ", trace.file,
            "(", trace.line, ",", trace.column, ")");
    }
}
```

The information available inside the stack trace depends on the compilation information that was included (`GrOption.symbols` in the compiler).