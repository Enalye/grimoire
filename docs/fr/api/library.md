# Bibliothèques

L’ajout de nouvelles définitions se fait au sein d’une bibliothèque `GrModuleDef`.

```d
GrModuleDef library = new GrModuleDef;
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

`addFunction()` permet de définir de nouvelle fonctions.

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

`addCast` permet de définir de nouvelles conversions.

```d
library.addCast(&maConv, grBool, grString);

void maConv(GrCall call) {
    GrBool valeur = call.getBool(0);
    call.setString(valeur ? "vrai" : "faux");
}
```

`addOperator` permet la surcharge d’opérateur.

```d
library.addOperator(&additionner, GrModuleDef.Operator.add, [grFloat, grInt], grFloat);
// Ou
library.addOperator(&additionner, "+", [grFloat, grInt], grFloat);

void additionner(GrCall call) {
    call.setFloat(call.getFloat(0) + cast(GrFloat) call.getInt(1));
}
```
> ***Important:***
Notez cependant que si une opération par défaut existe, elle sera prioritaire.

`addConstructor` permet de définir un constructeur à une classe ou un natif.

```d
library.addConstructor(&monType_ctor, monType);

void monType_ctor(GrCall call) {
    call.setNative(new MonType());
}
```
> ***Important:***
Un constructeur doit toujours retourner le type qu’il définit.

`addStatic` permet de définir une méthode statique à une classe ou un natif.

```d
library.addStatic(&monType_foo, monType, "foo");

void monType_foo(GrCall call) {
}
```

### Généricité

`grAny()` joue le rôle d’un type générique.

```d
library.addFunction(&_push, "push",
    [grList(grAny("T")), grAny("T")],
	[grAny("T")]);
```
Ce code est équivalent à:
```grimoire
func<T> push(a: list<T>, b: T) (T) {}
```
Des contraintes peuvent également restreindre le type.
```d
library.addFunction(&_print_class, "print",
    [grPure(grAny("T"))], [],
    [grConstraint("Class", grAny("T"))]);
```

`addConstraint` permet de définir une constrainte.

```grimoire
library.addConstraint(&equals, "Equals", 1);

bool equals(GrData, GrType type, const GrType[] types) {
    return type == types[0];
}
```

* * *

## Classes

Une classe se déclare en appelant la méthode `addClass()`.
```d
library.addClass("MaClasse", ["foo", "bar"], [grInt, grString]);
```

D’autres paramètres optionnels existent pour l’héritage et la généricité.
```d
library.addClass("MaClasse", [], [], ["T"], "ClasseParente", [grAny("T")]);
```

Instancier une classe se fait à l’aide de `createObject()` sur GrCall ou GrEngine.
```d
GrObject obj = call.createObject("MaClasse");
GrInt valeur = obj.getInt("foo");
obj.setString("bar", "Bonjour");
```

* * *

## Natifs

Les natifs sont des types opaques, ils permettent à Grimoire d’accéder à des types binaires arbitraires.
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

Les natifs peuvent offrir des propriétés avec `addProperty`, similaire aux champs d’une classe.
```d
library.addProperty(&getter, &setter, "maValeur", monTypeNatif, grInt);

void getter(GrCall call) {
    MonType monType = call.getNative!MonType(0);
    call.setInt(monType.maValeur);
}

void setter(GrCall call) {
    MonType monType = call.getNative!MonType(0);
    monType.maValeur = call.getInt(1);
    call.setInt(monType.maValeur);
}
```
La présence d’un `setter` est optionnel, son absence rend la propriété comme constante.

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