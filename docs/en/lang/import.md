# Importing files

You can separate a script between multiple files.
To import them, use the `import` keyword with your file paths.
```cpp
import "foo/myscript.gr"

// With {} you can specify multiple paths.
import {
	"../lib/myotherscript.gr"
	"C:/MyScripts/script.gr"
}
```

The path is relative to the file importing it.
Two import with the same absolute path (i.e. the same file) will be included only once.