# Classes

Les classes sont des types qui peuvent contenir plusieurs champs de types différents.
Contrairement à la plupart des langages de programmation, les classes en Grimoire ne contiennent pas de méthode.

```grimoire
class Animal {
    var nom: string;
    var nombreDePattes: int;
    var vitesse: float;
}
```

Un classe s’instancie avec l’opérateur `@`.
```grimoire
var toutou = @Animal {};
```
Une classe n’a pas de valeur par défaut, elle doit donc obligatoirement être initialisée.
```grimoire
var toutou: Animal; // Erreur de compilation
```

L’initialisation des champs se fait entre les accolades `{}`.
```grimoire
Animal toutou = @Animal {
	nom = "Médor";
	nombreDePattes = 4;
    vitesse = 30f;
};
```
Un champ non-initialisé prendra sa valeur par défaut s’il en a une.
Si un champ n’a pas de valeur par défaut, une erreur de compilation surviendra.

## Constructeur

La création d’un objet peut se faire au moyen d’un constructeur.
```grimoire
event main() {
    var toutou = @Animal("Médor");
}

func @Animal(nom: string) (Animal) {
    return @Animal {
        nom = nom;
        nombreDePattes = 4;
        vitesse = 30f;
    };
}
```

> ***Important:***
Un constructeur sans paramètre devient automatiquement la valeur par défaut d’une classe.

## Méthode statique

Les méthodes statiques sont des fonctions qui appartiennent à un type.
```grimoire
func @Animal.aboyer() (string) {
    return "ouaf !";
}

var x = @Animal.aboyer();
```

## Spécialisation

Une classe peut hériter d’une autre classe.
```grimoire
class Chien : Animal {
    var typeDeChien: string;
}
```
Elle obtiendra les mêmes champs que le type parent et pourra être utilisé à la place du type parent (polymorphisme).
```grimoire
Animal animal = @Chien {};
```

## Généricité

Les classes peuvent utiliser des types non-connus à l’avance.
```grimoire
class MaClasse<T, A> : ClasseParente<T, int> {
	var maValeur: T;
	var monAutreValeur: A;
}

var x: MaClasse<int, string> = @MaClasse<int, string> {};
```

## Accéder à un champ

L’opérateur `.` permet d’accéder à un champ d’une classe.
```grimoire
toutou.vitesse = 12.7;
toutou.nom = "Rex";
print(toutou.nom);
```

Par défaut, les champs sont seulement visibles à l’intérieur du fichier qui l’a déclaré.
Pour les rendre visibles globalement, on doit les exporter avec le mot-clé `export`:
```grimoire
class A {
	export var a: int; // Visible globalement
	var b: int; // Visible seulement dans le fichier actuel
}
```