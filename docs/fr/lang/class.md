# Classes

Les classes sont des types qui peuvent contenir plusieurs champs de types différents.
Contrairement à la plupart des langages de programmation, les classes en Grimoire ne contiennent pas de méthode.

```grimoire
class Animal {
    string nom;
    int nombreDePattes;
    float vitesse;
}
```

Un classe s’instancie avec l’opérateur `new`.
```grimoire
Animal toutou = new Animal {};
```
Une classe n’a pas de valeur par défaut, elle doit donc obligatoirement être initialisée.
```grimoire
Animal toutou; // Erreur de compilation
```

L’initialisation des champs se fait entre les accolades `{}`.
```grimoire
Animal toutou = new Animal {
	nom = "Médor";
	nombreDePattes = 4;
    vitesse = 30.;
};
```
Un champ non-initialisé prendra sa valeur par défaut s’il en a une.
Si un champ n’a pas de valeur par défaut, une erreur de compilation surviendra.

## Constructeur

La création d’un objet peut se faire au moyen d’un constructeur.
```grimoire
event main() {
    let toutou = new Animal("Médor");
}

function new(string nom) (Animal) {
    return new Animal {
        nom = nom;
        nombreDePattes = 4;
        vitesse = 30.;
    };
}
```

## Spécialisation

Une classe peut hériter d’une autre classe.
```grimoire
class Chien : Animal {
    string typeDeChien;
}
```
Elle obtiendra les mêmes champs que le type parent et pourra être utilisé à la place du type parent (polymorphisme).
```grimoire
Animal animal = new Chien {};
```

## Généricité

Les classes peuvent utiliser des types non-connus à l’avance.
```grimoire
class MaClasse<T, A> : ClasseParente<T, int> {
	T maValeur;
	A monAutreValeur;
}
```

## Accéder à un champ

L’opérateur `.` permet d’accéder à un champ d’une classe.
```grimoire
toutou.vitesse = 12.7;
toutou.nom = "Rex";
print(toutou.nom);
```

Par défaut, les champs sont seulement visibles à l’intérieur du fichier qui l’a déclaré.
Pour les rendre visibles globalement, on doit les spécifier en public avec le mot-clé `public`:
```grimoire
class A {
	public int a; // Visible globalement
	int b; // Visible seulement dans le fichier actuel
}
```