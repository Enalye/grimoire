# std.string

Built-in type.
## Description
Type that contains UTF-8 characters.
## Natifs
### StringIterator
Iterates on characters of a string.
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[clear](#func_0)|*str*: **string**||
|[contains](#func_1)|*str*: **pure string**, *value*: **pure string**|**bool**|
|[copy](#func_2)|*str*: **pure string**|**string**|
|[each](#func_3)|*str*: **string**|**StringIterator**|
|[first](#func_4)|*str*: **pure string**|**string?**|
|[indexOf](#func_5)|*str*: **pure string**, *value*: **pure string**|**int?**|
|[insert](#func_6)|*str*: **string**, *index*: **int**, *value*: **pure string**||
|[isEmpty](#func_7)|*str*: **pure string**|**bool**|
|[last](#func_8)|*str*: **pure string**|**string?**|
|[lastIndexOf](#func_9)|*str*: **pure string**, *value*: **pure string**|**int?**|
|[next](#func_10)|*iterator*: **StringIterator**|**string?**|
|[pop](#func_11)|*str*: **string**|**string?**|
|[pop](#func_12)|*str*: **string**, *quantity*: **int**|**string**|
|[push](#func_13)|*str*: **string**, *value*: **string**||
|[remove](#func_14)|*str*: **string**, *index*: **int**||
|[remove](#func_15)|*str*: **string**, *startIndex*: **int**, *endIndex*: **int**||
|[reverse](#func_16)|*str*: **pure string**|**string**|
|[shift](#func_17)|*str*: **string**|**string?**|
|[shift](#func_18)|*str*: **string**, *quantity*: **int**|**string**|
|[size](#func_19)|*str*: **pure string**|**int**|
|[slice](#func_20)|*str*: **pure string**, *startIndex*: **int**, *endIndex*: **int**|**string**|
|[unshift](#func_21)|*str*: **string**, *value*: **string**||


***
## Description des fonctions

<a id="func_0"></a>
> clear (*str*: **string**)

Cleanup `str`.

<a id="func_1"></a>
> contains (*str*: **pure string**, *value*: **pure string**) (**bool**)

Returns `true` if `value` exists in `str`.

<a id="func_2"></a>
> copy (*str*: **pure string**) (**string**)

Returns a copy of `str`.

<a id="func_3"></a>
> each (*str*: **string**) (**StringIterator**)

Returns an iterator that iterate through each character.

<a id="func_4"></a>
> first (*str*: **pure string**) (**string?**)

Returns the first element of `str`.
If it doesn't exist, returns `null<T>`.

<a id="func_5"></a>
> indexOf (*str*: **pure string**, *value*: **pure string**) (**int?**)

Returns the first occurence of `value` in `str`, starting from `index`.
If `value` does't exist, `null<int>` is returned.
If `index` is negative, `index` is calculated from the back of `str`.

<a id="func_6"></a>
> insert (*str*: **string**, *index*: **int**, *value*: **pure string**)

Insert `value` in `str` at the specified `index`.
If `index` is greater than the size of `str`, `value` is appended at the back of `str`.
If `index` is negative, `index` is calculated from the back of `str`.

<a id="func_7"></a>
> isEmpty (*str*: **pure string**) (**bool**)

Returns `true` if `str` contains nothing.

<a id="func_8"></a>
> last (*str*: **pure string**) (**string?**)

Returns the last element of `str`.
If it doesn't exist, returns `null<T>`.

<a id="func_9"></a>
> lastIndexOf (*str*: **pure string**, *value*: **pure string**) (**int?**)

Returns the last occurence of `value` in `str`, starting from `index`.
If `value` does't exist, `null<int>` is returned.
If `index` is negative, `index` is calculated from the back of `str`.

<a id="func_10"></a>
> next (*iterator*: **StringIterator**) (**string?**)

Advances the iterator until the next character.

<a id="func_11"></a>
> pop (*str*: **string**) (**string?**)

Removes the last element of `str` and returns it.
If it doesn't exist, returns `null<T>`.

<a id="func_12"></a>
> pop (*str*: **string**, *quantity*: **int**) (**string**)

Removes `quantity` elements from `str` and returns them.

<a id="func_13"></a>
> push (*str*: **string**, *value*: **string**)

Appends `value` to the back of `str`.

<a id="func_14"></a>
> remove (*str*: **string**, *index*: **int**)

Removes the element at the specified `index`.

<a id="func_15"></a>
> remove (*str*: **string**, *startIndex*: **int**, *endIndex*: **int**)

Removes the elements from `startIndex` to `endIndex` included.

<a id="func_16"></a>
> reverse (*str*: **pure string**) (**string**)

Returns an inverted version of `str`.

<a id="func_17"></a>
> shift (*str*: **string**) (**string?**)

Removes the first element of `str` and returns it.
If it doesn't exist, returns `null<T>`.

<a id="func_18"></a>
> shift (*str*: **string**, *quantity*: **int**) (**string**)

Removes the first `quantity` elements from `str` and returns them.

<a id="func_19"></a>
> size (*str*: **pure string**) (**int**)

Returns the size of `str`.

<a id="func_20"></a>
> slice (*str*: **pure string**, *startIndex*: **int**, *endIndex*: **int**) (**string**)

Returns a slice of `str` from `startIndex` to `endIndex` included.

<a id="func_21"></a>
> unshift (*str*: **string**, *value*: **string**)

Prepends `value` to the front of `str`.

