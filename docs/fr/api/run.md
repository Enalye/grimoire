# Exécution

L’exécution d’un programme Grimoire se fait à partir d’événements `event`.
```d
GrEngine engine = new GrEngine;
engine.load(bytecode);

engine.callEvent("main");
```

L’ajout de bibliothèques doit se faire avant le chargement du bytecode.
```d
GrLibrary stdlib = grLoadStdLibrary();

GrEngine engine = new GrEngine;
engine.addLibrary(stdlib);
engine.load(bytecode);

engine.callEvent("main");
```
**Important:** Toutes les bibliothèques doivent être inclus dans le compilateur **et** la machine virtuelle dans le **même ordre**.

La méthode `process()` permet l’exécution de toute les tâches du programme jusqu’à leur fin ou leur suspension.
```d
engine.process();
```

Pour exécuter l’ensemble du programme, on boucle le processus.
```d
while (engine.hasTasks)
    engine.process();
```

Entre temps, la machine virtuelle peut avoir paniqué.
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

La quantité d’informations disponible dans le stacktrace dépend des informations de compilation fournis (`GrOption.symbols` en compilation).