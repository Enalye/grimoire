# Native

Native types are types declared in D and opaque in Grimoire.
Their internal representation is only accessible with accessors and modifiers defined in D.

```grimoire
var map = @HashMap<int>();
map.set("strawberry", 12);
```