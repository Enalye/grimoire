# Compilation

Un programme doit d’abord être compilé avant de pouvoir être exécuté.
```d
GrCompiler compiler = new GrCompiler;
compiler.addFile("script.gr");
GrBytecode bytecode = compiler.compileFile(GrOption.none, GrLocale.fr_FR);
```
* `GrLocale` permet de changer la langue des messages d’erreurs.
* `GrOption` permet de rajouter des informations de compilations:
    * `GrOption.none`: aucune information (défaut)
    * `GrOption.symbols`: Conserve des informations de débogage dans le bytecode en cas d’exception.
    * `GrOption.profile`: Ajoute des commandes de profilage dans le bytecode.
    * `GrOption.safe`: Change certaines instructions par des versions plus sécurisés.

```d
GrBytecode bytecode = compiler.compile(
    GrOption.symbols | GrOption.profile | GrOption.safe,
    GrLocale.fr_FR);
```

En cas d’erreur de compilation, `getError()` permet de récupérer l’erreur.
```d
if (!bytecode)
    writeln(compiler.getError().prettify());
```

L’ajout des bibliothèques ainsi que des scripts doit se faire avant la compilation.
```d
GrModuleDef stdlib = grLoadStdLibrary(); 

GrCompiler compiler = new GrCompiler;
compiler.addLibrary(stdlib);

compiler.addSource(`export func hello() { "Bonjour à tous !".print; }`});
compiler.addFile("script.gr");

GrBytecode bytecode = compiler.compile();
```

Le bytecode peut être sauvegardé ou être chargé depuis un fichier.
```d
bytecode.save("bytecode.grb");
bytecode.load("bytecode.grb");
```

Le contenu du bytecode peut être lu de façon formatté.
```d
writeln(bytecode.prettify());
```

Un numéro de version spécifique peut être rajouté dans le bytecode.
```d
enum PROGRAM_VERSION = 11;
GrCompiler compiler = new GrCompiler(PROGRAM_VERSION);

[…]

if(!bytecode.checkVersion(PROGRAM_VERSION))
    writeln("Mauvaise version");
```