# Énumérations

Les énumérations listent différentes alternatives qu’un même type peut avoir.

```grimoire
enum Couleur {
	rouge;
	vert;
	bleu;
}
```

Par défaut, les champs d’une énumération ont la valeur du champ précédent + 1.
```grimoire
var maCouleur = Couleur.rouge;

switch(maCouleur)
case(Couleur.rouge) "On est sur du rouge !".print;
case(Couleur.vert) "On est sur du vert !".print;
case(Couleur.bleu) "On est sur du bleu !".print;
```

On peut changer la valeur d’un champ.
```grimoire
enum Couleur {
    blanc = -1;   //-1
	rouge;        //0
	vert;         //1
	bleu = 5;     //5
	orange;       //6
}
```
> ***Note:***
La valeur doit être un entier littéral.