# Commentaires

You can write comments in Grimoire.
Comments are ignored by the compiler.


## Single line comment
Everything after `//` until the end of the line is ignored:
```grimoire
// This line is ignored
```

## Multiline comment
Everything between `/*` and `*/` is ignored:
```grimoire
/* Everything written inside
   this bloc is ignored
*/
```

Multiline comments can also be inside one another:
```grimoire
/* Everything written inside
   /* this bloc too */
   is ignored
*/
```
