# Énumérations

Les énumérations sont des jeux de constantes définis au sein d’un seul type.
Elles peuvent seulement être comparés entre-elles et ne peuvent effectuer d’opérations arithmétiques.

## Définition

Elles sont déclarés avec le mot-clé `enum`:
```grimoire
enum Couleur {
	rouge;
	vert;
	bleu;
}
```

## Accéder à un champ

Pour accéder à une valeur, on suit le nom du type d’un point suivi du nom du champ souhaité:
```grimoire
event onLoad() {
	Couleur myColor = Couleur.rouge;

	switch(myColor)
	case(Couleur.rouge) "On est sur du rouge !":print;
	case(Couleur.vert) "On est sur du vert !":print;
	case(Couleur.bleu) "On est sur du bleu !":print;
}
```