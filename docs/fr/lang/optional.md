# Optionnels

En Grimoire, par défaut un type possède obligatoirement une valeur.
Pour noter l’absence potentielle de valeur, on utilise un type optionnel.
Un type optionnel se note avec un `?`.
```grimoire
var x: int? = 5;
```

Un type optionnel a pour valeur par défaut `null`.
```grimoire
var x: string?;
x.print; // -> null
```

De même, on peut assigner `null` à un type optionnel.
```grimoire
var x: float? = 5f;
x = null;
```

Si le compilateur ne peut inférer le type de `null`, on doit le préciser.
```grimoire
var x = null<int>;
null<float>.print;
```

# L’opérateur « ? »

L’opérateur `?` permet de récupérer la valeur contenue dans un optionnel.
```grimoire
var x: int? = 5;
var y: int = x?;
```

> **Note:** Si la valeur de l’optionnel est `null`, une erreur sera lancé.

# L’opérateur « ?? »

L’opérateur `??` permet de récupérer la valeur contenue dans un optionnel s’il n’est pas `null`, sinon, il récupère la valeur à sa droite.
```grimoire
var x: int?;
var y: int = x ?? 3;
```

# Accès optionnel à un champ avec « .? »

L’opérateur `.?` est équivalent à l’accès d’un champ grâce à `.` mais appliqué à un optionnel.
Si l’objet est `null`, alors l’expression sera ignorée.
```grimoire
class MaClasse {
    var x: int;
}

event main() {
    var maClasse: MaClasse?;
    maClasse.?x = 5;
}
```

# L’appel optionnel de fonction avec « .? » et « :? »

Les opérateurs `.?` et `:?` sont équivalent à un appel de méthode fait par respectivement `.` et `:` mais appliqué à un optionnel.
Si l’objet est `null`, alors l’expression sera ignorée.
```grimoire
func ajouter(a: int, b: int) (int) {
    return a + b;
}

event main() {
    var a: int?;
    a.?ajouter(10).print;
}
```