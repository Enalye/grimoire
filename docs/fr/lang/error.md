# Error Handling

Error handling in Grimoire is done by throwing and catching errors

To raise an error, simply write:
```grimoire
throw "Error";
```
If you do nothing about it, the entire VM will panic, because the current task does nothing to catch it.

So we should probably catch it:
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
And everything is fine.