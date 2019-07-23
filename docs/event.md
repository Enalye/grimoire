* [Next: Array](array.md)
* [Prev: Anonymous function/task](anon.md)
* [Main Page](index.md)

* * *

# Event functions

Events are like tasks that can only be spawned from D.

They are declared like tasks and can only be global:
```cpp
event foo(string msg) {
	printl(msg);
}
```

To spawn this one from D:
```d
auto mangledName = grMangleNamedFunction("foo", [grString]);
if(vm.hasEvent(mangledName))
    GrContext ev = vm.spawnEvent(mangledName);
```
Here the process is a little bit special.
First, we need to know the mangled name (name + signature) of the event with "grMangleNamedFunction".
Then, we call it.

* * *

* [Next: Array](array.md)
* [Prev: Anonymous function/task](anon.md)
* [Main Page](index.md)