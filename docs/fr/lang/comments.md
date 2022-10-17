# Commentaires

Grimoire permet l’utilisation de commentaires, ces derniers sont ignorés par le compilateur.


## Commentaire en une ligne
Tout ce qui suit `//` jusqu’au retour à la ligne est ignoré:
```grimoire
// Cette ligne est ignorée
```

## Commentaire sur plusieurs lignes
Tout ce qui suit `/*` jusqu’à `*/` est ignoré:
```grimoire
/* Tout ce qui est écrit
   dans ce bloc est ignoré
*/
```

Les commentaires multilignes peuvent aussi être imbriqués:
```grimoire
/* Tout ce qui est écrit
   /* dans ce bloc aussi */
   est ignoré
*/
```
