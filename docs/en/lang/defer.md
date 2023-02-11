# Defer

`defer` garanties the execution of a block of code at the end of the current function, event when an exception is thrown.
```grimoire
event main {
	defer { print("Inside defer !"); }
	print("Before defer");
	throw "Error";
}
```