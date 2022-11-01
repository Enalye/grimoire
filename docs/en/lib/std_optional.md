# std.optional

Optionals handling functions.
## Description
An optiona is a type that can contains its own type or be null.
Its null type is equal to `null(T)` where `T` is the referenced type.
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
|[expect](#func_0)|**T?** *x*, **pure string** *error*|**T**|
|[some](#func_1)|**T** *x*|**T?**|
|[unwrap](#func_2)|**T?** *x*|**T**|
|[unwrapOr](#func_3)|**T?** *x*, **T** *default*|**T**|


***
## Description des fonctions

<a id="func_0"></a>
> expect (**T?** *x*, **pure string** *error*) (**T**)

Checks if an optionnal is null.
If it is, the exception `error` is thrown.
Otherwise, the non-optional version of `x` is returned.

<a id="func_1"></a>
> some (**T** *x*) (**T?**)

Returns an optional version of the type.

<a id="func_2"></a>
> unwrap (**T?** *x*) (**T**)

Checks if an optionnal is null.
If it is, the exception `"UnwrapError"` is thrown.
Otherwise, the non-optional version of `x` is returned.

<a id="func_3"></a>
> unwrapOr (**T?** *x*, **T** *default*) (**T**)

Checks if an optionnal is null.
If it is, the `default` value is returned.
Otherwise, the non-optional version of `x` is returned.

