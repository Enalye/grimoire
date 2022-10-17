# Énumérations

Les énumérations listent différentes alternatives qu’un même type peut avoir.

```grimoire
enum Couleur {
	rouge;
	vert;
	bleu;
}
```

Les champs d’une énumération ont une valeur unique.
```grimoire
Couleur maCouleur = Couleur.rouge;

switch(maCouleur)
case(Couleur.rouge) "On est sur du rouge !":print;
case(Couleur.vert) "On est sur du vert !":print;
case(Couleur.bleu) "On est sur du bleu !":print;
```