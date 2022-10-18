# Optionnels

En Grimoire, par défaut un type possède obligatoirement une valeur.
Pour noter l’absence potentielle de valeur, on utilise un type optionnel.
```grimoire
int? monEntier = 5;
```

Un type optionnel a pour valeur par défaut `null`.
```grimoire
string? monString;
monString:print; // -> null
```

De même, on peut assigner `null` à un type optionnel.
```grimoire
real? valeur = 5;
valeur = null;
```

Si le compilateur ne peut inférer le type de `null`, on doit le préciser.
```grimoire
let? valeur = null(int);
null(real):print;
```

# L’opérateur « ? »

L’opérateur `?` permet de récupérer la valeur contenue dans un optionnel.
```grimoire
int? x = 5;
int y = x?;
```

> **Note:** Si la valeur de l’optionnel est `null`, une erreur sera lancé.

# L’opérateur « ?? »

L’opérateur `??` permet de récupérer la valeur contenue dans un optionnel s’il n’est pas `null`, sinon, il récupère la valeur à sa droite.
```grimoire
int? x;
int y = x ?? 3;
```

# L’opérateur « .? »

L’opérateur `.?` est équivalent à l’accès d’un champ grâce à `.` mais appliqué à un optionnel.
Si l’objet est `null`, alors l’expression sera ignorée.
```grimoire
class MaClasse {
    int x;
}

event main() {
    MaClasse? maClasse;
    maClasse.?x = 5;
}
```

# L’opérateur « :? » et « ::? »

L’opérateur `:?` et `::?` sont équivalent à un appel de méthode grâce à respectivement `:` et `::` mais appliqué à un optionnel.
Si l’objet est `null`, alors l’expression sera ignorée.
```grimoire
function ajouter(int a, int b) (int) {
    return a + b;
}

event main() {
    int? a;
    a:?ajouter(10);
}
```