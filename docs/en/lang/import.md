# Importing files

You can separate a program between multiple files.

To import them, use the `import` keyword with their relative file paths.
```grimoire
import "foo/myscript.gr"
```
With curly braces `{}` you can add multiple paths.
```grimoire
import {
	"../lib/myotherscript.gr"
	"C:/MyScripts/script.gr"
}
```
The path is relative to the file importing it.

Two import with the same absolute path (i.e. the same file) will be included only once.