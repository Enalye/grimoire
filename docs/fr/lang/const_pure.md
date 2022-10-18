# Const & Pure

Grimoire possède deux types de modificateurs `const` et `pure`.

`const` permet de définir une variable comme non-assignable.
```grimoire
const int a = 5;
a = 6; // Erreur
a ++; // Erreur
```
En revanche, il n’empêche pas la modification de son contenu.
```grimoire
class Personnage {
    string nom;
}

event main() {
    const Personnage perso = new Personnage {
        nom = "Roger";
    };

    perso = new Personnage {
        nom = "Robert";
    }; // Erreur

    perso.nom = "Jean-Eudes"; // Autorisé
}
```

`pure` rend le contenu d’un type inaltérable.
```grimoire
class Personnage {
    string nom;
}

event main() {
    pure Personnage perso = new Personnage {
        nom = "Roger";
    };

    perso = new Personnage {
        nom = "Robert";
    }; // Autorisé

    perso.nom = "Jean-Eudes"; // Erreur
}
```

`const` et `pure` peuvent être combiné pour rendre une variable immutable.
```grimoire
class Personnage {
    string nom;
}

event main() {
    const pure Personnage perso = new Personnage {
        nom = "Roger";
    };

    perso = new Personnage {
        nom = "Robert";
    }; // Erreur

    perso.nom = "Jean-Eudes"; // Erreur
}
```