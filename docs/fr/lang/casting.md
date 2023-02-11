# Conversions

L’opérateur `as` permet de convertir une valeur d’un type vers un autre.
```grimoire
var a: float = 5 as<float>;
```

## Conversion personnalisée

On peut définir notre propre fonction de conversion en la nommant `as`.

Elle ne peut avoir qu’un paramètre d’entrée et de sortie.
```grimoire
class MaClasse {}

event onLoad() {
    var obj = @MaClasse;
    print(obj as<string>); // Affiche « Salut »
}

func as(MaClasse a) (string) {
    return "Salut";
}
```

Notez que si une conversion par défaut existe pour votre type, elle sera prioritaire.