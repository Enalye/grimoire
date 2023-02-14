# Variables

Les variables peuvent stocker une valeur pour être réutilisée plus tard.
Une variable est définie par son type et doit être déclarée avant tout usage.

On déclare une variable avec `var`.
```grimoire
var a = 0;
```

La variable inférera automatiquement le type de la variable en fonction de la valeur qui lui est assignée.

On peut spécifier explicitement le type d’une variable après son nom.
```grimoire
var a: int = 0;
```

Sans initialisation, l’annotation du type est obligatoire.
```grimoire
var a; // Erreur, le type de « a » est inconnu
```

Sans initialisation, une variable est initialisé par sa valeur par défaut.
Si aucune valeur par défaut n’existe, le programme ne compilera pas.
> **Note:** La valeur par défaut d’une classe ou d’un natif est son constructeur par défaut.
```grimoire
class A1 {}
class A2 {}

func @A2() (A2) {
    return @A2 {};
}

event main {
    var a: float;   // 0.0 par défaut
    var b: A1;      // Erreur
    var c: A2;      // Appelle le constructeur @A2()
}
```

## Valeur par défaut

On peut récupérer la valeur par défaut d’un type grâce à `default<T>` où `T` est le type souhaité.
```grimoire
var x = default<int>; // -> 0
```

## Portée
Une variable peut-être soit locale soit globale.
* Une variable déclarée en **dehors** de toute fonction/tâche/etc est **globale**.
* Une variable **locale** n’est accessible que dans le **bloc** dans lequel il a été défini.
> Un bloc est défini par une paire d’accolades `{}`

```grimoire
var globalVar: int; // Déclaré globalement, accessible partout.

event main() {
    var localVar: int; // Declaré dans le main, accessible uniquement dans le bloc actuel.
}
```

## Redéclaration
On peut redéclarer une variable, celle-ci remplacera la précédente dans la portée actuelle.
```grimoire
event main() {
    var x = 5;
    x.print; // -> 5

    var x = "Bonjour";
    x.print; // -> « Bonjour »
}
```

Le shadowing de variable est autorisé.
```grimoire
event main() {
    var x: int = 5;

    {
        var x: int = 12;
        x.print; // -> 12
    }

    x.print; // -> 5
}
```

## Visibilité
Une variable globale n’est par défaut visible que depuis son propre fichier.
Pour y accéder depuis un autre fichier, on doit le déclarer en public avec le mot-clé `public`:
```grimoire
public var variableGlobale: int; // Utilisable depuis un autre fichier
```

Ce principe s’applique également pour les types déclarés et les champs des classes.
```grimoire
public class A {        //La classe est visible globalement
    public var a: int;  //a est visible globalement
    var b: int;         //b n’est visible que depuis ce fichier
}
```

## Liste de déclaration

On peut déclarer plusieurs variables en les séparant d’une virgule.
```grimoire
event main() {
    var a, b: int;

    a.print; // -> 0
    b.print; // -> 0
}
```

L’initialisation des variables se fait dans l’ordre de déclaration.
```grimoire
event main() {
    var a, b = 2, 3;

    a.print; // -> 2
    b.print; // -> 3
}
```

S’il n’y a pas assez de valeurs à assigner, les autres variables auront la dernière valeur.
```grimoire
event main() {
    var a, b, c = 2, 3;

    a.print; // -> 2
    b.print; // -> 3
    c.print; // -> 3
}
```

On peut passer outre une ou plusieurs valeurs en laissant des virgules vides, ça copiera la dernière valeur.
```grimoire
event main() {
    var a, b, c = 12,, 5;

    a.print; // -> 12
    b.print; // -> 12
    c.print; // -> 5
}
```

En revanche, la première valeur ne peut être manquante.
```grimoire
event main() {
    var a, b, c = , 5, 2; // Erreur
}
```

En l’absence d’annotation de type, les variables déclarées par une liste d’initialisation sont du type de la valeur qui leur est assignée.
```grimoire
event main() {
    var a, b, c, d = true, 2.3, "Coucou !";

    a.print; // -> true
    b.print; // -> 2.3
    c.print; // -> "Coucou !"
    d.print; // -> "Coucou !"
}
```