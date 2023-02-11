# Error

Grimoire has a way to handle errors.
```grimoire
throw "Error";
```

`try`/`catch` blocks allow these errors to be captured.
```grimoire
event onLoad() {
	try {
		throw "Error";
	}
	catch(e) {
		print("I caught " ~ e);
	}
}
```
An uncaught error will put the virtual machine in a state of panic and will interrupt all the remaining tasks.