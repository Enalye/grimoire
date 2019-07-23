##### [Next: Deferring](defer.md)
##### [Prev: Channels](chan.md)
##### [Main Page](index.md)

# Error Handling

Error handling in Grimoire is done by raising/catching errors

To raise an error, simply write:
```ruby
raise "Error";
```
If you do nothing about it, the entire VM will panic, because the current task does nothing to catch it.

So we should probably catch it:
```cpp
main {
	try {
		raise "Error";
	}
	catch(e) {
		print("I caught " ~ e);
	}
}
```
And everything is fine.


# Navigation

##### [Next: Deferring](defer.md)
##### [Prev: Channels](chan.md)
##### [Main Page](index.md)