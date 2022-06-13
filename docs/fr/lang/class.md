# Classes

Les classes sont des types qui peuvent contenir plusieurs champs de types différents.

## Définition

La déclaration se fait à l’aide du mot-clé `class`.
```grimoire
class MyClass {
    int foo;
    string bar;
}
```

## Création

Pour créer une instance de la classe (càd un objet), on utilise le mot-clé `new` suivi du nom de la classe.
```grimoire
MyClass obj = new MyClass;
```

Par défaut, tous les champs sont initialisés avec leur valeur par défaut.
Pour changer ça, on doit utiliser le constructeur:
```grimoire
MyClass obj = new MyClass {
	foo = 5;
	bar = "Salut";
};
```
Les champs non-spécifiés dans le constructeur sera quand même initialisés par défaut.

## Accéder à un champ

Pour accéder à un champ, on utilise la notation `.`.
```grimoire
obj.foo = 5;
obj.bar = "Coucou";
print(obj.bar);
```

Par défaut, les champs sont seulement visibles à l’intérieur du fichier qui l’a déclaré.
Pour les rendre visibles globalement, on doit les spécifier en public avec le mot-clé `public`:
```grimoire
class A {
	public int a; // Visible globalement
	int b; // Visible seulement dans le fichier actuel
}
```

## Nul

Une variable d’une classe non-initialisée sera initialisée à null.

Tout comme les types étrangers, on peut assigner `null` à ces variables.

```grimoire
MyClass obj = null;
if(!obj)
	"Obj is null":print;
```

Tenter d’accéder à un champ d’un objet nul résultera en une erreur.

## Héritage

On peut hériter des champs d’une autre classe:
```grimoire
class MyClass : ParentClass {
}
```

## Généricité

On peut définir des types génériques pour les classes comme ceci:
```grimoire
class MyClass<T, A> : ParentClass<T, int> {
	T myValue;
	A myOtherValue;
}
```