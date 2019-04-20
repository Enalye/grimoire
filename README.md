# Grimoire

Grimoire is an concurrent programming language that can easily be embedded into another D programs.
You can very easily interface your program with Grimoire's scripts.

The language itself is focused on concurrency, and feature both static and dynamic typing.

Hope you have fun with this project !


## Install

Use `dub` to include grimoire in your project (or just dump the files in your project if you're too tired).
Open the "test" folder to see how to add Grimoire to your program or copy/paste it.

Grimoire is in 2 parts:
- The compiler
- The runtime

First you need to compile your file with `grCompileFile()`.
It takes the script's file path, compiles in into a bytecode, and returns it to you.
```d
auto bytecode = grCompileFile("test.gr");
```
The binded D-functions/types must be before compiling the file.
The binded functions/types must be the same (and in the same order) for the compiler and the runtime else it will crash.

Then, create the runtime's virtual machine `GrEngine`, load the bytecode and spawn the main task.
```d
GrEngine vm = new GrEngine;
vm.load(bytecode);
vm.spawn();
```

You're not forced to spawn the main, you can spawn any other named event like this:
```d
auto mangledName = grMangleNamedFunction("hey", []);
if(vm.hasEvent(mangledName))
    GrContext ev = vm.spawnEvent(mangledName);
```
But be aware that every function/task/event are mangled with their signature, so use grMangleNamedFunction to generate the  correct function's name.

To run the virtual machine, just call the process function (check if there's any task(Coroutine) running though):
```d
while(vm.hasCoroutines)
    vm.process();
```
The program will run until all tasks are finished, if you want them to run only for one step, replace the `while` with `if`.

You can then check if there are any unhandled errors that went through the VM (Caught exceptions won't trigger that).
```d
if(vm.isPanicking)
    writeln("Unhandled Exception: " ~ to!string(vm.panicMessage));
```


## Exemple Program

The classic Hello World ! nice to meet you !
```cpp
main {
    print("Hello World!");
}
```
You can find the language documentation [> here ! <](https://enalye.github.io/grimoire)
