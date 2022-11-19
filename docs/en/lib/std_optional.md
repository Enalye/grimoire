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
|!=|**float?**, **float?**|**bool**|
|!=|**int?**, **float?**|**bool**|
|!=|**float?**, **int?**|**bool**|
|%|**float?**, **int?**|**float?**|
|%|**float?**, **float?**|**float?**|
|%|**int?**, **int?**|**int?**|
|%|**int?**, **float?**|**float?**|
|&|**int?**, **int?**|**int?**|
|&&|**bool?**, **bool?**|**bool?**|
|*|**int?**, **int?**|**int?**|
|*|**float?**, **float?**|**float?**|
|*|**float?**, **int?**|**float?**|
|*|**int?**, **float?**|**float?**|
|+|**int?**, **int?**|**int?**|
|+|**float?**, **float?**|**float?**|
|+|**float?**, **int?**|**float?**|
|+|**int?**, **float?**|**float?**|
|+|**float?**|**float?**|
|+|**int?**|**int?**|
|-|**int?**, **int?**|**int?**|
|-|**float?**, **float?**|**float?**|
|-|**float?**, **int?**|**float?**|
|-|**int?**, **float?**|**float?**|
|-|**int?**|**int?**|
|-|**float?**|**float?**|
|/|**int?**, **int?**|**int?**|
|/|**float?**, **float?**|**float?**|
|/|**float?**, **int?**|**float?**|
|/|**int?**, **float?**|**float?**|
|<|**float?**, **int?**|**bool**|
|<|**int?**, **float?**|**bool**|
|<|**float?**, **float?**|**bool**|
|<|**int?**, **int?**|**bool**|
|<<|**int?**, **int?**|**int?**|
|<=|**int?**, **int?**|**bool**|
|<=|**float?**, **float?**|**bool**|
|<=|**int?**, **float?**|**bool**|
|<=|**float?**, **int?**|**bool**|
|==|**int?**, **float?**|**bool**|
|==|**float?**, **float?**|**bool**|
|==|**int?**, **int?**|**bool**|
|==|**bool?**, **bool?**|**bool**|
|==|**float?**, **int?**|**bool**|
|>|**int?**, **int?**|**bool**|
|>|**float?**, **float?**|**bool**|
|>|**int?**, **float?**|**bool**|
|>|**float?**, **int?**|**bool**|
|>=|**int?**, **int?**|**bool**|
|>=|**float?**, **float?**|**bool**|
|>=|**int?**, **float?**|**bool**|
|>=|**float?**, **int?**|**bool**|
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

