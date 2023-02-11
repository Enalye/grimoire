# Const & Pure

Grimoire possède deux types de modificateurs `const` et `pure`.

`const` permet de définir une variable comme non-assignable.
```grimoire
const a: int = 5;
a = 6; // Erreur
a ++; // Erreur
```
En revanche, il n’empêche pas la modification de son contenu.
```grimoire
class Personnage {
    var nom: string;
}

event main() {
    const perso = @Personnage {
        nom = "Roger";
    };

    perso = @Personnage {
        nom = "Robert";
    }; // Erreur

    perso.nom = "Jean-Eudes"; // Autorisé
}
```

`pure`, quant à lui, rend le contenu d’un type inaltérable.
```grimoire
class Personnage {
    var nom: string;
}

event main() {
    var perso: pure Personnage = @Personnage {
        nom = "Roger";
    };

    perso = @Personnage {
        nom = "Robert";
    }; // Autorisé

    perso.nom = "Jean-Eudes"; // Erreur
}
```

`const` et `pure` peuvent être combiné pour rendre une variable immutable.
```grimoire
class Personnage {
    var nom: string;
}

event main() {
    const perso: pure Personnage = @Personnage {
        nom = "Roger";
    };

    perso = @Personnage {
        nom = "Robert";
    }; // Erreur

    perso.nom = "Jean-Eudes"; // Erreur
}
```