# std.optional

Fonctions pour la manipulation d’optionnels.
## Description
Un optionnel est un type pouvant contenir son propre type ou être nul.
Son type nul correspondant vaut `null(T)` où `T` est le type concerné.
## Opérateurs
|Opérateur|Entrée|Sortie|
|-|-|-|
|!|**bool?**|**bool?**|
|!=|**int?**, **int?**|**bool**|
|!=|**bool?**, **bool?**|**bool**|
|!=|**real?**, **real?**|**bool**|
|!=|**int?**, **real?**|**bool**|
|!=|**real?**, **int?**|**bool**|
|%|**real?**, **int?**|**real?**|
|%|**real?**, **real?**|**real?**|
|%|**int?**, **int?**|**int?**|
|%|**int?**, **real?**|**real?**|
|&|**int?**, **int?**|**int?**|
|&&|**bool?**, **bool?**|**bool?**|
|*|**int?**, **int?**|**int?**|
|*|**real?**, **real?**|**real?**|
|*|**real?**, **int?**|**real?**|
|*|**int?**, **real?**|**real?**|
|+|**int?**, **int?**|**int?**|
|+|**real?**, **real?**|**real?**|
|+|**real?**, **int?**|**real?**|
|+|**int?**, **real?**|**real?**|
|+|**real?**|**real?**|
|+|**int?**|**int?**|
|-|**int?**, **int?**|**int?**|
|-|**real?**, **real?**|**real?**|
|-|**real?**, **int?**|**real?**|
|-|**int?**, **real?**|**real?**|
|-|**int?**|**int?**|
|-|**real?**|**real?**|
|/|**int?**, **int?**|**int?**|
|/|**real?**, **real?**|**real?**|
|/|**real?**, **int?**|**real?**|
|/|**int?**, **real?**|**real?**|
|<|**real?**, **int?**|**bool**|
|<|**int?**, **real?**|**bool**|
|<|**real?**, **real?**|**bool**|
|<|**int?**, **int?**|**bool**|
|<<|**int?**, **int?**|**int?**|
|<=|**int?**, **int?**|**bool**|
|<=|**real?**, **real?**|**bool**|
|<=|**int?**, **real?**|**bool**|
|<=|**real?**, **int?**|**bool**|
|==|**int?**, **real?**|**bool**|
|==|**real?**, **real?**|**bool**|
|==|**int?**, **int?**|**bool**|
|==|**bool?**, **bool?**|**bool**|
|==|**real?**, **int?**|**bool**|
|>|**int?**, **int?**|**bool**|
|>|**real?**, **real?**|**bool**|
|>|**int?**, **real?**|**bool**|
|>|**real?**, **int?**|**bool**|
|>=|**int?**, **int?**|**bool**|
|>=|**real?**, **real?**|**bool**|
|>=|**int?**, **real?**|**bool**|
|>=|**real?**, **int?**|**bool**|
|>>|**int?**, **int?**|**int?**|
|^|**int?**, **int?**|**int?**|
|\||**int?**, **int?**|**int?**|
|\|\||**bool?**, **bool?**|**bool?**|
|~|**int?**|**int?**|
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[expect](#func_0)|**T?** *x*, **pure string** *erreur*|**T**|
|[some](#func_1)|**T** *x*|**T?**|
|[unwrap](#func_2)|**T?** *x*|**T**|
|[unwrapOr](#func_3)|**T?** *x*, **T** *défaut*|**T**|


***
## Description des fonctions

<a id="func_0"></a>
> expect (**T?** *x*, **pure string** *erreur*) (**T**)

Vérifie si un optionnel est nul.
S’il est nul, l’exception `erreur` est lancé.
Sinon, la version non-optionnel de `x` est renvoyé.

<a id="func_1"></a>
> some (**T** *x*) (**T?**)

Retourne une version optionnelle du type.

<a id="func_2"></a>
> unwrap (**T?** *x*) (**T**)

Vérifie si un optionnel est nul.
S’il est nul, l’exception `"UnwrapError"` est lancé.
Sinon, la version non-optionnel de `x` est renvoyé.

<a id="func_3"></a>
> unwrapOr (**T?** *x*, **T** *défaut*) (**T**)

Vérifie si un optionnel est nul.
S’il est nul, la valeur par `défaut` est retourné.
Sinon, la version non-optionnel de `x` est renvoyé.

