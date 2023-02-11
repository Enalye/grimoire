# Conditions

`if` et `unless` permettent l’exécution d’une partie du code sous certaines conditions. 
```grimoire
var a = 5;

if(a < 2)
    print("a vaut moins que 2 !");

unless(a < 2)
    print("a vaut au moins 2 !");
```
Les conditions peuvent s’imbriquer à l’aide de `else`.
```grimoire
var a = 5;

if(a > 10)
    print("a vaut plus que 10");
else if(a >= 5)
    print("a vaut 5 ou plus mais pas plus que 10");
else unless(i < 2)
    print("a vaut 2 ou plus, mais moins que 5");
else
    print("a vaut moins que 2");
```

## Switch

`switch` compare une valeur avec chaque cas possible.
```grimoire
var i = "Salut";

switch(i)
default
	print("Il a pas dit bonjour");
case("Wesh")
	print("Il a dit wesh mais c’est pas pareil");
case("Salut")
	print("Il a dit bonjour");
```

Contrairement à `if` et `unless`, l’ordre des cas n’a pas d’importance.

## Select

`select` exécute le premier cas non-bloquant disponible.
```grimoire
select
case(valeur = <- monCanal) {
	print("Reçu " ~ valeur);
}
case(monAutreCanal <- "Salut") {
	print("Envoyé Salut");
}
```

Le bloc `default` est exécuté si tout les cas sont bloquants. S’il n’est pas présent, l’opération `select` devient bloquante.
```grimoire
select
case(valeur = <- monCanal) {
	print("Reçu " ~ valeur);
}
case(monAutreCanal <- "Salut") {
	print("Envoyé Salut");
}
default {
	print("Il se passe rien");
}
```