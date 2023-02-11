# Natif

Les types natifs sont des types définis en D et opaque pour Grimoire.
Leur représentation interne n’est accessible que via des accesseurs et des modifieurs définis en D.

```grimoire
var map = @HashMap<int>();
map.set("cerise", 12);
```