<p align="center" >
<img src="https://raw.githubusercontent.com/enalye/grimoire/master/docs/_media/logo.png" alt="Grimoire" title="Grimoire">
</p>

Grimoire is a simple and fast concurrent programming language that can easily be embedded into another D programs.
You can very easily interface your program with Grimoire's scripts.

Hope you have fun with this project !

[Documentation here !](https://enalye.github.io/grimoire)

There is a VSCode extension for Grimoire available here: [grimoire-lang](https://marketplace.visualstudio.com/items?itemName=enalye.grimoire-lang)

What it looks like:

```cpp
//Hello World
event app {
    "Hello World!".print;
}
```

```go
//Invert a string
event app {
    assert("Hello World !".invert == "! dlroW olleH");
}

func invert(str: string) (string) {
    let result = str as<list<string>>;
    loop(i, result.size / 2)
        result[i], result[-(i + 1)] = result[-(i + 1)], result[i];
    return result as<string>;
}
```

```go
//Fibonacci
event fib {
    assert(
        function(n: int) (int) {
            if(n < 2) return n;
            return self(n - 1) + self(n - 2);
        }(10) == 55);
}
```

## Install

Use `dub` to include grimoire in your project (or just dump the files in your project if you want).
Open the "test" folder to see how to add Grimoire to your program or copy/paste it.

Grimoire is in 2 parts:

- The compiler
- The runtime

### Compilation

To bind functions defined in D and add other types, you can create a `GrLibrary` which will store primitives and type information. The `GrLibrary` object can be shared between multiple compilations.

To compile, you need a compiler `GrCompiler` which will turn your scripts into bytecode with `compile`.

You must add the `GrLibrary` objects to the compiler before calling `compile` with `addLibrary`.
You must also add at least one file or source to compile with `addFile` or `addSource` before compiling (further files can be added with `import` directives).
If the compilation fails, you can fetch the error with `getError()`.

If it's successful, the `compile` function will returns a `GrBytecode` that stores the bytecode generated by the compiler, which can be saved into a file or run by the VM.

```d
// Some basic functions are provided by the default library.
GrLibrary stdlib = grLoadStdLibrary(); 

GrCompiler compiler = new GrCompiler;

// We add the default library.
compiler.addLibrary(stdlib);

// We provide an entry script
compiler.addFile("script.gr");

// We compile the file.
GrBytecode bytecode = compiler.compile();

if(bytecode) {
    // Compilation successful
}
else {
    // Error while compiling
    import std.stdio: writeln;
    writeln(compiler.getError().prettify());
}
```

### Debug & Profiling

You can see the generated bytecode with

```d
bytecode.prettify();
```

Which formats the bytecode in a printable way.

Grimoire also provide a basic profiling tool, to use it, to need to specify a flag during compilation to activate debug informations.

```d
compiler.compileFile("test.gr", GrOption.Option.profile | GrOption.Option.symbols | GrOption.Option.safe);
```

* `profile` adds profiling commands to the bytecode
* `symbols` generate debug information into the bytecode
* `safe` adds additional checks that can help detect some crashes

The profiling information are accessible on the GrEngine with:

```d
engine.dumpProfiling();
```

An already formatted version is accessible with:

```d
engine.prettifyProfiling();
```

### Processing

Then, create the runtime's virtual machine `GrEngine`, you'll first need to add the same libraries as the compiler and in the same order.
Then, load the bytecode.

```d
GrEngine engine = new GrEngine;
engine.addLibrary(stdlib);
engine.load(bytecode);
```

You can then spawn any event like this:

```d
GrTask task = engine.callEvent("myEvent", [grString], [GrValue("Hello World!")]);
```

To run the virtual machine, just call the process function (and check if there's any task(Coroutine) currently running):

```d
while(engine.hasTasks)
    engine.process();
```

The program will run until all tasks are finished, if you want them to run only for one step, replace the `while` with `if`.

You can then check if there are any unhandled errors that went through the VM (Caught exceptions won't trigger that).

```d
if(engine.isPanicking) {
    writeln("unhandled exception: " ~ engine.panicMessage);
   
    foreach (trace; engine.stackTraces) {
        writeln("[", trace.pc, "] in ", trace.name, " at ", trace.file,
            "(", trace.line, ",", trace.column, ")");
    }
}
```

## Documentation

You can find the language documentation [&gt; here ! &lt;](https://enalye.github.io/grimoire)

## Extension

There is a VSCode extension for Grimoire available here: [grimoire-lang](https://marketplace.visualstudio.com/items?itemName=enalye.grimoire-lang)
