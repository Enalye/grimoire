# Event

Unlike many languages, Grimoire does not have access to a `main` but to special tasks called `event`.

`event` are the entry points of a program written in Grimoire.
```grimoire
event main(arg: string) {
	print(arg);
}
```
An event can only be called from its host program.

```d
GrTask task = vm.callEvent("main", [grString], [GrValue("Hello !")]);
```