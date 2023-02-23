# std.error

Functions to help error handling.
## Functions
|Function|Input|Output|
|-|-|-|
|[_setMeta](#func_0)|*value*: **pure string**||
|[assert](#func_1)|*value*: **bool**, *error*: **pure string**||
|[assert](#func_2)|*value*: **bool**||


***
## Function descriptions

<a id="func_0"></a>
> _setMeta (*value*: **pure string**)

Internal function.

<a id="func_1"></a>
> assert (*value*: **bool**, *error*: **pure string**)

If `value` is false, throw the exception `errror`.

<a id="func_2"></a>
> assert (*value*: **bool**)

If `value` is false, throw an exception `"AssertError"`.

