# Natif

Les types natifs sont des types définis en D et opaque pour Grimoire.
Leur représentation interne n’est accessible que via des accesseurs et des modifieurs définis en D.

Les détails de leur implémentation sont accessible [ici](/fr/api/library).

```grimoire
var map = @HashMap<int>();
map.set("cerise", 12);
```

En terme d’usage, un natif suit les mêmes régles d’héritage, de généricité, de constructeurs, de méthode statiques et de champs qu’une classe.

> ***Important:***
Un type natif ne peut pas hériter d’une classe et inversement.