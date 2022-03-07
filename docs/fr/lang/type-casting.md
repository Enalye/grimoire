# Conversion de type

You can explicitly cast a value to any type with the keyword `as`, it must be followed by the desired type like this: `real a = 5 as real;`.
On peut convertir une valeur explicitement vers un autre type avec le mot-clé `as`. Celui-ci doit être suivi du type voulu comme ceci:
```grimoire
real a = 5 as real;
```

## Conversion personnalisée

On peut définir notre propre fonction de conversion en la nommant `as`.
Elle ne doit avoir qu’un paramètre d’entrée et de sortie.

```grimoire
class MyClass {}

event onLoad() {
    let obj = new MyClass;
    print(obj as string); // Affiche « Salut »
}

function as(MyClass a) (string) {
    return "Salut";
}
```

Notez que si une conversion par défaut existe pour votre type, elle sera prioritaire.