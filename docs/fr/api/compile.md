# Compilation

Un script doit d’abord être compilé avant de pouvoir être exécuté.
```d
GrCompiler compiler = new GrCompiler;
GrBytecode bytecode = compiler.compileFile(
    "script.gr",
    GrOption.none,
    GrLocale.fr_FR);

if (!bytecode)
    writeln(compiler.getError().prettify());
```
Changer `GrLocale` permet de changer la langue des messages d’erreurs.

L’ajout de bibliothèques doit se faire avant la compilation.
```d
GrLibrary stdlib = grLoadStdLibrary(); 

GrCompiler compiler = new GrCompiler;
compiler.addLibrary(stdlib);

GrBytecode bytecode = compiler.compileFile("script.gr");
```
`GrOption.symbols` permet au bytecode de conserver des informations sur les fonctions en cas d’exception.
```d
GrBytecode bytecode = compiler.compileFile("script.gr", GrOption.symbols);
```
Le bytecode peut être sauvegardé ou être chargé depuis un fichier.
```d
bytecode.save("bytecode.grb");
bytecode.load("bytecode.grb");
```
Le contenu du bytecode peut être lu grâce à `grDump`.
```d
writeln(grDump(bytecode));
```