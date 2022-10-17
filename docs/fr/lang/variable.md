# Variables

Les variables peuvent stocker une valeur pour être réutilisé plus tard.
Une variable est défini par son type et doit être déclaré avant tout usage.

```grimoire
int a = 0;
```

Sans initialisation, une variable est initialisé par sa valeur par défaut.
Si aucune valeur par défaut n’existe, le script ne compilera pas.
```grimoire
real a;         //Vaut 0.0 par défaut
HashMap<int> a; //Ne compile pas
```

> **Note:** Les classes et natifs n’ont pas de valeurs assignée par défaut, elles doivent donc **obligatoirement** être initialisées.

* * *

## Let
`let` permet d’inférer automatiquement le type d’une variable déclarée.
```grimoire
let a = 3; //a est un entier
```
> `let` peut seulement être utilisé lors d’une déclaration de variable et ne peut faire partie de la signature d’une fonction car ce n’est pas un type !

> **Note:** Les variables déclarées par ce biais **doivent** être initialisées.

* * *

## Portée
Une variable peut-être soit locale soit globale.
* Une variable déclarée en dehors de toute fonction/tâche/etc est **globale**.
* Une variable **locale** n’est accessible que dans le bloc dans lequel il a été défini.

Example:
```grimoire
int globalVar; //Déclaré globalement, accessible partout.

event main() {
    int localVar; //Declaré dans le main, accessible uniquement dans le bloc actuel.
}
```

* * *

## Redéclaration
Une même variable locale peut être redéclarée autant de fois que nécessaire avec n’importe quel type, les règles de portée de cette nouvelle déclaration s’applique toujours comme indiqué ci-dessus.

```grimoire
event onLoad() {
    int x = 5;
    x:print; //Affiche 5
    string x = "Bonjour";
    x:print; // Affiche « Bonjour »

    {
        real x = 1.2;
        x:print; // Affiche 1.2
    }
    x:print; // Affiche « Bonjour »
}
```

* * *

## Visibilité
Une variable globale n’est par défaut visible que depuis son propre fichier.
Pour y accéder depuis un autre fichier, on doit le déclarer en public avec le mot-clé `public`:
```grimoire
public int variableGlobale; //Utilisable depuis un autre fichier
```

Ce principe s’applique également pour les types déclarés et les champs des classes.
```grimoire
public class A { //La classe est visible globalement
    public int a; //a est visible globalement
    int b; //b n’est visible que depuis ce fichier
}
```

* * *

## Liste de Déclaration

On peut déclarer plusieurs variable d’un même type en séparant chaque identifieur d’une virgule:
> `int a, b;`

L’initialisation des variables se fait dans l’ordre de déclaration:
> `int a, b = 2, 3;`
Ici *a vaut 2* et *b vaut 3*.

S’il n’y a pas assez de valeurs à assigner, les autres variables seront affublées de la dernière valeur:
> `int a, b, c = 2, 3;`
Ici *a vaut 2*, *b vaut 3* et *c vaut 3*.

On peut passer outre une ou plusieurs valeurs en laissant des virgules vides, ça copiera la dernière valeur:
> `int a, b, c = 12,, 5;`
*a* et *b* valent tout deux *12* alors que *c* vaut 5.

> `int a, b, c, d = 12,,, 5;`
*a*, *b* et *c* valent tous *12* pendant que *c* vaut 5.

En revanche, la première valeur ne peut être manquante, ceci est illégal:
> `int a, b, c = , 5, 2;`

Chaque variable d’une liste d’initialisation sont du même type.
Ex: `int a, b = 2, "Coucou"` déclenchera une erreur ca *b* s’attend à un `int` et on lui passe un `string`.

Il y a tout de même un moyen de déclarer des variables de types différents grâce à `let`:
> `let a, b, c, d = 1, 2.3, "Coucou!";`

Ce qui donne:
* *a vaut 1* et est de type **int**,
* *b vaut 2.3* et est de type **real**,
* *c vaut "Hi!"* et est de type **string**,
* *d vaut "Hi!"* et est de type **string**.