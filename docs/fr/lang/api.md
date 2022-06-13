# Interface de programmation

Tous les types et valeurs peuvent être défini à l’aide d’un GrLibrary.
```d
GrLibrary library = new GrLibrary;
//Puis ajoutez vos types dans library
```

Après la création du GrLibrary et l’ajout de vos types personnalisés, rajoutez-le au compilateur avant la compilation.
```d
compiler.addLibrary(library);
```

Ensuite, ajoutez-le à la machine virtuelle.
```d
engine.addLibrary(library);
```

**Important:** Toutes les bibliothèques doivent être inclus dans le compilateur **et** la machine virtuelle et dans le **même ordre**.

* * *

## Variables

On peut déclarer des variables globales à l’aide de addVariable():
```d
library.addVariable("pi", grReal, 3.141592f, true); 
```

Pour accéder à une variable pendant l’exécution, on peut utiliser getXVariable() de GrCall ou GrEngine:
```d
float value = engine.getRealVariable("PI");
```

Pour les modifier, on utilise setXVariable():
```d
engine.setRealVariable("PI", 3f);
```

* * *

## Primitives

En grimoire, une primitive est une fonction défini en D et accessible depuis un script.
`print` par exemple, est une primitive.
Elles doivent être déclarés avant la compilation et demeurer inchangé dans la machine virtuelle.

* * *

### Déclaration d’une primitive

Pour déclarer une primitive, on utilise `addFunction`.
Cette fonction prend une fonction de rappel, le nom sous lequel la primitive sera connue, ses paramètres d’entrée et de sortie.
Exemple:
```d
//Une fonction print qui prend une chaîne de caractères et ne retourne rien
library.addFunction(&print_a_string, "print", [grString]);
//Fonction mul() qui prend 2 réels et en retourne un.
library.addFunction(&multiply, "mul", [grReal, grReal], [grReal]);
```

* * *

### Implémenter la primitive

La fonction de rappel prend un GrCall et ne retourne rien.
Le GrCall contient tout ce dont on a besoin à propos du contexte.

Ça ressemble à ça:
```d
void myPrimitive(GrCall call) {
	writeln(call.getReal(0));
    call.setInt(99);
}
```
Ici la primitive prend un réel depuis l’index 0 (premier paramètre), et l’affiche, puis retourne un entier qui vaut 99.
Les méthodes getXXX récupèrent les paramètres d’entrée, le type doit correspondre à la déclaration ou sinon un exception est lancé.
Les méthodes setXXX retourne une valeur sur la pile, faite attention à l’ordre dans lequel vous appelez les fonctions setXXX.

* * *

### Ajouter de la généricité à une primitive

Grimoire fourni un moyen pour déclarer une primitive avec des types génériques grâce à `grAny`.
Par exemple ceci:
```d
library.addFunction(&_push, "push",
    [grArray(grAny("T")), grAny("T")],
	[grAny("T")]);
```
Est équivalent à:
```grimoire
function<T> push(array(T) array, T value) (T) {}
```

Pour restreindre quels types génériques sont valides, des contraintes peuvent être ajoutés.

* * *

### Conversion de type

On peut définir une fonction de conversion avec `addCast`:
```d
library.addCast(&myCast, myObjType, grString);
```

Puis l’implémentation:
```d
void myCast(GrCall call) {
    auto myObj = call.getObject(0);
    call.setString("Hello");
}
```

* * *

### Operateurs

Tout comme `addCast`, mais avec `addOperator`:
```d
library.addOperator(&myOperator, GrLibrary.Operator.add, [grReal, grInt], grReal);
// Ou
library.addOperator(&myOperator, "+", [grReal, grInt], grReal);
```

Puis l’implémentation:
```d
void myOperator(GrCall call) {
    call.setReal(call.getReal(0) + cast(int) call.getInt(1));
}
```

Notez cependant que si une opération par défaut existe, elle sera prioritaire.
Donc surcharger un `+` entre deux entiers sera ignoré.

* * *

## Classes

Une classe se déclare en appelant la méthode `addClass`:
```d
library.addClass("MyClass", ["foo", "bar"], [grInt, grString]);
```

D’autres paramètres optionnels existent pour l’héritage et la généricité:
```d
library.addClass("MyClass", [], [], ["T"], "ParentClass", [grAny("T")]);
```
C’est égal à MyClass<T> héritant de ParentClass<T>.
Le `grAny("T")` s’assure que la variable "T" de MyClass est utilisé pour la classe parente.

Instancier une classe se fait à l’aide de `createObject` de GrCall ou GrEngine:
```d
GrObject obj = call.createObject("MyClass");
```

On peut ensuite assigner ou récupérer des champs de GrObject avec leur méthodes set/get respectives:
```d
obj.setInt("foo", 5);
string value = obj.getString("bar");
```

* * *

## Alias de type

Les alias de types se déclarent avec `addTypeAlias` from GrLibrary:
```d
library.addTypeAlias("MyInt", grInt);
```

* * *

## Types étrangers

Les types étrangers (Foreign) sont des pointeurs opaques utilisés en D, grimoire n’a aucun accès à leur contenu.
Il ne peuvent donc être déclaré que depuis D.
```d
library.addForeign("MyType");
```

Tout comme les classes, ils peuvent hériter d’un autre type étranger.
```d
library.addForeign("MyType", [], "ParentType", []);
```

Le deuxième et quatrième paramètre sont des variables génériques du type définie et du type parent, respectivement.
```d
library.addForeign("MyType", ["T"], "ParentType", [grAny("T")]);
```
Veut en gros dire que MyType<T> hérite de ParentType<T>.

* * *

## Énumérations

Les énumérations sont créés avec `addEnum` de GrLibrary:
```d
library.addEnum("Color", ["red", "green", "blue"]);
```