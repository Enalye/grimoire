# Variables

Les variables peuvent stocker une valeur pour être réutilisé plus tard.
Une variable est défini par son type et doit être déclaré avant tout usage.

`int a = 0;`
Ici, on déclare une variable **a** de type **int** initialisée avec la valeur **0**.

Si on affiche le contenu de la variable avec 'print(a)', on verra **0** d’affiché.

Toutes les variables sont initialisée, si on ne leur assigne rien, ils auront leur valeur par défaut.

## Types Basiques
Les types de bases en Grimoire peuvent se répartir dans ces différentes catégories:
* Les entiers déclarés avec **int** ex: 2 (Valeur par défaut: 0)
* Les nombres décimaux déclarés avec **real** ex: 2.35f (Valeur par défaut: 0f)
* Les booléens déclarés avec **bool** ex: true, false (Valeur par défaut: false)
* Les chaînes de caractères déclarés avec **string** ex: "Coucou" (Valeur par défaut: "")
* [Les listes](#arrays) (Valeur par défaut: [])
* [Les fonctions](#functions) (Valeur par défaut: fonction vide)
* [Les tâches](#tasks) (Valeur par défaut: tâche vide)
* [Les canaux](#channels) (Valeur par défaut: canal d’une taille de 1)
* [Les classes](#classes) (Valeur par défaut: null)
* [Les types étrangers](#foreign-types) (Valeur par défaut: null)
* [Les énumérations](#enumerations) (Valeur par défaut: la première valeur)

### Type Automatique
`let` est un mot-clé se substituant à un type et permettant au compilateur d’inférer automatiquement le type d’une variable déclarée.
Exemple:
```grimoire
event onLoad() {
    let a = 3.2; //'a' est automatiquement déclaré comme réel.
    print(a);
}
```
`let` peut seulement être utilisé lors d’une déclaration de variable et ne peut faire partie de la signature d’une fonction car ce n’est pas un type !

Les variables déclarées par ce biais **doivent** être initialisées.

## Portée
Une variable peut-être soit locale soit globale.
* Une variable globale est déclarée en dehors de toute fonction/tâche/etc et est accessible globalement.
* Une variable locale n’est accessible que dans le bloc dans lequel il a été défini.

Example:
```grimoire
int globalVar; //Déclaré globalement, accessible partout.

event onLoad() {
    int localVar; //Declaré dans le onLoad, accessible uniquement dans onLoad.
}
```

### Redéclaration
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

### Public et privé
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
Ex: `int a, b = 2, "Coucou"` déclenchera une erreur ca *b* s’attend à un **entier** et on lui passe une **chaîne de caractère**.

Il y a tout de même un moyen de déclarer des variables de types différents grâce à `let`:
> `let a, b, c, d = 1, 2.3, "Coucou!";`

Here:
* *a vaut 1* et est de type **int**,
* *b vaut 2.3* et est de type **real**,
* *c vaut "Hi!"* et est de type **string**,
* *d vaut "Hi!"* et est de type **string**.