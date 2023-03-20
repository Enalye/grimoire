# Compilation

A program must first be compiled before being run.
```d
GrCompiler compiler = new GrCompiler;
compiler.addFile("script.gr");
GrBytecode bytecode = compiler.compileFile(GrOption.none, GrLocale.en_US);
```
* `GrLocale` changes the language of error messages.
* `GrOption` adds compilation data:
    * `GrOption.none`: no data (default)
    * `GrOption.symbols`: Keeps track of debug information in the bytecode in case of exception.
    * `GrOption.profile`: Adds profiling commands in the bytecode.
    * `GrOption.safe`: Changes some instruction by more secure ones.

```d
GrBytecode bytecode = compiler.compile(
    GrOption.symbols | GrOption.profile | GrOption.safe,
    GrLocale.en_US);
```

In case of a compilation error, `getError()` fetches the error.
```d
if (!bytecode)
    writeln(compiler.getError().prettify());
```

Required libraries and scripts must be added before compiling.
```d
GrLibrary stdlib = grLoadStdLibrary(); 

GrCompiler compiler = new GrCompiler;
compiler.addLibrary(stdlib);

compiler.addSource(`export func hello() { "Hello World !".print; }`});
compiler.addFile("script.gr");

GrBytecode bytecode = compiler.compile();
```

The bytecode can be saved or loaded into a file.
```d
bytecode.save("bytecode.grb");
bytecode.load("bytecode.grb");
```

The content of the bytecode can be read in a prettified format.
```d
writeln(bytecode.prettify());
```

A specific version number can be added to the bytecode.
```d
enum PROGRAM_VERSION = 11;
GrCompiler compiler = new GrCompiler(PROGRAM_VERSION);

[…]

if(!bytecode.checkVersion(PROGRAM_VERSION))
    writeln("Mauvaise version");
```