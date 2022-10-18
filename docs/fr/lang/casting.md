# Conversions

L’opérateur `as` permet de convertir une valeur d’un type vers un autre.
```grimoire
real a = 5 as real;
```

## Conversion personnalisée

On peut définir notre propre fonction de conversion en la nommant `as`.

Elle ne peut avoir qu’un paramètre d’entrée et de sortie.
```grimoire
class MaClasse {}

event onLoad() {
    let obj = new MaClasse;
    print(obj as string); // Affiche « Salut »
}

function as(MaClasse a) (string) {
    return "Salut";
}
```

Notez que si une conversion par défaut existe pour votre type, elle sera prioritaire.