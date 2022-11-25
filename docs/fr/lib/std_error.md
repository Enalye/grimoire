# std.error

Fonctions pour aider la gestion d’erreur.
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[_setMeta](#func_0)|*valeur*: **pure string**||
|[assert](#func_1)|*valeur*: **bool**, *erreur*: **pure string**||
|[assert](#func_2)|*valeur*: **bool**||


***
## Description des fonctions

<a id="func_0"></a>
> _setMeta (*valeur*: **pure string**)

Fonction interne.

<a id="func_1"></a>
> assert (*valeur*: **bool**, *erreur*: **pure string**)

Si `valeur` est faux, lance l’exception `erreur`.

<a id="func_2"></a>
> assert (*valeur*: **bool**)

Si `valeur` est faux, lance une exception `"AssertError"`.

