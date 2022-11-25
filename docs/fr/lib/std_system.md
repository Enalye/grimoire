# std.system

Fonctions basiques.
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[cond](#func_0)|**bool** *condition*, **T** *a*, **T** *b*|**T**|
|[swap](#func_1)|**T1** *a*, **T2** *b*|**T2**, **T1**|
|[testa](#func_2)|**event(string)** *valeur*||
|[typeOf](#func_3)|**T** *valeur*|**string**|


***
## Description des fonctions

<a id="func_0"></a>
> cond (**bool** *condition*, **T** *a*, **T** *b*) (**T**)

Renvoie `a` si `condition` est vrai, sinon renvoie `b`.

<a id="func_1"></a>
> swap (**T1** *a*, **T2** *b*) (**T2**, **T1**)

Renvoie `a` et `b` dans l’ordre inverse.

<a id="func_2"></a>
> testa (**event(string)** *valeur*)

Retourne le type de `valeur`.

<a id="func_3"></a>
> typeOf (**T** *valeur*) (**string**)

Retourne le type de `valeur`.

