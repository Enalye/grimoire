# std.error

Functions to help error handling.
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[_setMeta](#func_0)|**pure string** *value*||
|[assert](#func_1)|**bool** *value*, **pure string** *error*||
|[assert](#func_2)|**bool** *value*||


***
## Description des fonctions

<a id="func_0"></a>
> _setMeta (**pure string** *value*)

Internal function.

<a id="func_1"></a>
> assert (**bool** *value*, **pure string** *error*)

If `value` is false, throw the exception `errror`.

<a id="func_2"></a>
> assert (**bool** *value*)

If `value` is false, throw an exception `"AssertError"`.

