# Grimoire

What it looks like:
```cpp
//Invert a string
main {
    assert("Hello World !":invert == "! dlroW olleH");
}

func invert(string str) string {
    let result = str as array(string);
    loop(i, result:size / 2)
        result[i], result[-(i + 1)] = result[-(i + 1)], result[i];
    return result as string;
}
```

```cpp
//Fibonacci
main {
    assert(
        func(int n) int {
            if(n < 2) return n;
            return self(n - 1) + self(n - 2);
        }(10) == 55);
}
```

Grimoire is an concurrent programming language that can easily be embedded into another D programs.
You can very easily interface your program with Grimoire's scripts.

Hope you have fun with this project !

[Documentation here !](https://enalye.github.io/grimoire)


## Install

Use `dub` to include grimoire in your project (or just dump the files in your project if you're too tired).
Open the "test" folder to see how to add Grimoire to your program or copy/paste it.

Grimoire is in 2 parts:
- The compiler
- The runtime

### Compilation

First you need to set up `GrData`
The GrData object contains all binded D-functions (called primitives here) and types definitions shared with the scripts.
If you want to bind D-functions or create types with it, you must do so before compiling your script.
The GrData object will be used by the runtime as well, so it must remains the same between compilation and runtime.

```d
GrData data = new GrData;
// Define you types and primitives in data here..
grLoadStdLibrary(data); //Like the provided default library for example.
```

Then, you need a compiler `GrCompiler` which will turn your scripts into bytecode with `compileFile`.
If the compilation fails, you can fetch the error with `getError()`.
```d
GrBytecode bytecode;
GrCompiler compiler = new GrCompiler(data);
if(compiler.compileFile(bytecode, "test.gr")) {
    // Compilation successful
}
else {
    // Error while compiling
    import std.stdio: writeln;
    writeln(compiler.getError().prettify());
}
```

### Processing

Then, create the runtime's virtual machine `GrEngine`, load the data and bytecode then spawn the main task.
```d
GrEngine engine = new GrEngine;
engine.load(data, bytecode);
engine.spawn();
```

You're not forced to spawn the main, you can spawn any other named event like this:
```d
auto mangledName = grMangleNamedFunction("myEvent", [grString]);
if(engine.hasEvent(mangledName)) {
    GrContext context = engine.spawnEvent(mangledName);
    context.setString("Hello World!");
}
```
But be aware that every function/task/event are mangled with their signature, so use grMangleNamedFunction to generate the  correct function's name.

If the event has parameters, you must push them into the context with the `setXX` functions.

To run the virtual machine, just call the process function (check if there's any task(Coroutine) running though):
```d
while(engine.hasCoroutines)
    engine.process();
```
The program will run until all tasks are finished, if you want them to run only for one step, replace the `while` with `if`.

You can then check if there are any unhandled errors that went through the VM (Caught exceptions won't trigger that).
```d
if(engine.isPanicking)
    writeln("Unhandled Exception: " ~ to!string(engine.panicMessage));
```


## Exemple Program

The classic Hello World ! nice to meet you !
```cpp
main {
    printl("Hello World!");
}
```
You can find the language documentation [> here ! <](https://enalye.github.io/grimoire)
