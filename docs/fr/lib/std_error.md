# std.error

Fonctions pour aider la gestion d’erreur.
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[_setMeta](#func_0)|*value*: **pure string**||
|[assert](#func_1)|*value*: **bool**, *erreur*: **pure string**||
|[assert](#func_2)|*value*: **bool**||


***
## Description des fonctions

<a id="func_0"></a>
> _setMeta (*value*: **pure string**)

Fonction interne.

<a id="func_1"></a>
> assert (*value*: **bool**, *erreur*: **pure string**)

Si `value` est faux, lance l’exception.

<a id="func_2"></a>
> assert (*value*: **bool**)

Si `value` est faux, lance une exception `"AssertError"`.

