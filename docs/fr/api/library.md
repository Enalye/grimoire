# Bibliothèques

L’ajout de nouvelles définitions se fait au sein d’une bibliothèque `GrLibrary`.

```d
GrLibrary library = new GrLibrary;
```

* * *

## Variables

`addVariable()` permet de déclarer des variables globales.

```d
library.addVariable("PI", grConst(grFloat), 3.141592); 
```

Ces variables deviennent accessible pendant l’exécution de la machine virtuelle.

```d
GrFloat pi = engine.getFloatVariable("PI");
engine.setFloatVariable("PI", 3.0);
```

* * *

## Fonctions

La méthode `addFunction()` permet de définir de nouvelle fonctions.

```d
library.addFunction(&multiplier, "multiplier", [grFloat, grFloat], [grFloat]);
```

Le premier paramètre est un callback vers une fonction de type `void function(GrCall)`.

```d
void multiplier(GrCall call) {
	GrFloat valeur1 = call.getFloat(0);
	GrFloat valeur2 = call.getFloat(1);
    call.setFloat(valeur1 * valeur2);
}
```

La méthode `addCast` permet de définir de nouvelles conversions.

```d
library.addCast(&maConv, grBool, grString);

void maConv(GrCall call) {
    GrBool valeur = call.getBool(0);
    call.setString(valeur ? "vrai" : "faux");
}
```

La méthode `addOperator` permet la surcharge d’opérateur.

```d
library.addOperator(&additionner, GrLibrary.Operator.add, [grFloat, grInt], grFloat);
// Ou
library.addOperator(&additionner, "+", [grFloat, grInt], grFloat);

void additionner(GrCall call) {
    call.setFloat(call.getFloat(0) + cast(GrFloat) call.getInt(1));
}
```
> ***Important:***
Notez cependant que si une opération par défaut existe, elle sera prioritaire.


### Généricité

`grAny()` joue le rôle d’un type générique.

```d
library.addFunction(&_push, "push",
    [grList(grAny("T")), grAny("T")],
	[grAny("T")]);
```
Ce code est équivalent à:
```grimoire
function<T> push(list(T) liste, T valeur) (T) {}
```
Des contraintes peuvent également restreindre le type.
```d
library.addFunction(&_print_class, "print",
    [grPure(grAny("T"))], [],
    [grConstraint("Class", grAny("T"))]);
```

* * *

## Classes

Une classe se déclare en appelant la méthode `addClass()`.
```d
library.addClass("MaClasse", ["foo", "bar"], [grInt, grString]);
```

D’autres paramètres optionnels existent pour l’héritage et la généricité:
```d
library.addClass("MaClasse", [], [], ["T"], "ClasseParente", [grAny("T")]);
```

Instancier une classe se fait à l’aide de `createObject()` sur GrCall ou GrEngine:
```d
GrObject obj = call.createObject("MaClasse");
GrInt valeur = obj.getInt("foo");
obj.setString("bar", "Bonjour");
```

* * *

## Natifs

```d
library.addNative("MonType");
```

Tout comme les classes, ils peuvent hériter d’un autre type étranger.
```d
library.addNative("MonType", [], "TypeParent", []);
```

Tout comme les classes, on peut définir des types génériques.
```d
library.addNative("MonType", ["T"], "TypeParent", [grAny("T")]);
```

* * *

## Énumérations

Les énumérations sont créés avec `addEnum()`.
```d
library.addEnum("Couleur", ["rouge", "vert", "bleu"]);
```

* * *

## Alias

Les alias de types se déclarent avec `addAlias`.
```d
library.addAlias("MonEntier", grInt);
```