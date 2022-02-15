# Event functions

Events are like tasks that can only be spawned from D.

They are declared like tasks and can only be global:
```cpp
event foo(string msg) {
	print(msg);
}
```

To spawn this one from D:
```d
auto mangledName = grMangleComposite("foo", [grString]);
if(vm.hasEvent(mangledName)) {
    GrContext context = vm.spawnEvent(mangledName);
	context.setString("Hello World!");
}
```
Here the process is a little bit special.
First, we need to know the mangled name (name + signature) of the event with "grMangleComposite".
Then, we call it.
If the event has parameters, you absolutely ***must*** push those values to the new context, else the VM will crash.