# std.error

Fonctions pour aider la gestion d’erreur.
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[_setMeta](#func_0)|**pure string** *valeur*||
|[assert](#func_1)|**bool** *valeur*, **pure string** *erreur*||
|[assert](#func_2)|**bool** *valeur*||


***
## Description des fonctions

<a id="func_0"></a>
> _setMeta (**pure string** *valeur*)

Fonction interne.

<a id="func_1"></a>
> assert (**bool** *valeur*, **pure string** *erreur*)

Si `valeur` est faux, lance l’exception `erreur`.

<a id="func_2"></a>
> assert (**bool** *valeur*)

Si `valeur` est faux, lance une exception `"AssertError"`.

