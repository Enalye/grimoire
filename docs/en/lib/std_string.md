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
|[clear](#func_0)|**string** *str*||
|[contains](#func_1)|**pure string** *str*, **pure string** *value*|**bool**|
|[copy](#func_2)|**pure string** *str*|**string**|
|[each](#func_3)|**string** *str*|**StringIterator**|
|[first](#func_4)|**pure string** *str*|**string?**|
|[indexOf](#func_5)|**pure string** *str*, **pure string** *value*|**int?**|
|[insert](#func_6)|**string** *str*, **int** *index*, **pure string** *value*||
|[isEmpty](#func_7)|**pure string** *str*|**bool**|
|[last](#func_8)|**pure string** *str*|**string?**|
|[lastIndexOf](#func_9)|**pure string** *str*, **pure string** *value*|**int?**|
|[next](#func_10)|**StringIterator** *iterator*|**string?**|
|[pop](#func_11)|**string** *str*|**string?**|
|[pop](#func_12)|**string** *str*, **int** *quantity*|**string**|
|[push](#func_13)|**string** *str*, **string** *value*||
|[remove](#func_14)|**string** *str*, **int** *index*||
|[remove](#func_15)|**string** *str*, **int** *startIndex*, **int** *endIndex*||
|[reverse](#func_16)|**pure string** *str*|**string**|
|[shift](#func_17)|**string** *str*|**string?**|
|[shift](#func_18)|**string** *str*, **int** *quantity*|**string**|
|[size](#func_19)|**pure string** *str*|**int**|
|[slice](#func_20)|**pure string** *str*, **int** *startIndex*, **int** *endIndex*|**string**|
|[unshift](#func_21)|**string** *str*, **string** *value*||


***
## Description des fonctions

<a id="func_0"></a>
> clear (**string** *str*)

Cleanup `str`.

<a id="func_1"></a>
> contains (**pure string** *str*, **pure string** *value*) (**bool**)

Returns `true` if `value` exists in `str`.

<a id="func_2"></a>
> copy (**pure string** *str*) (**string**)

Returns a copy of `str`.

<a id="func_3"></a>
> each (**string** *str*) (**StringIterator**)

Returns an iterator that iterate through each character.

<a id="func_4"></a>
> first (**pure string** *str*) (**string?**)

Returns the first element of `str`.
If it doesn't exist, returns `null(T)`.

<a id="func_5"></a>
> indexOf (**pure string** *str*, **pure string** *value*) (**int?**)

Returns the first occurence of `value` in `str`, starting from `index`.
If `value` does't exist, `null(int) is returned.
If `index` is negative, `index` is calculated from the back of `str`.

<a id="func_6"></a>
> insert (**string** *str*, **int** *index*, **pure string** *value*)

Insert `value` in `str` at the specified `index`.
If `index` is greater than the size of `str`, `value` is appended at the back of `str`.
If `index` is negative, `index` is calculated from the back of `str`.

<a id="func_7"></a>
> isEmpty (**pure string** *str*) (**bool**)

Returns `true` if `str` contains nothing.

<a id="func_8"></a>
> last (**pure string** *str*) (**string?**)

Returns the last element of `str`.
If it doesn't exist, returns `null(T)`.

<a id="func_9"></a>
> lastIndexOf (**pure string** *str*, **pure string** *value*) (**int?**)

Returns the last occurence of `value` in `str`, starting from `index`.
If `value` does't exist, `null(int) is returned.
If `index` is negative, `index` is calculated from the back of `str`.

<a id="func_10"></a>
> next (**StringIterator** *iterator*) (**string?**)

Advances the iterator until the next character.

<a id="func_11"></a>
> pop (**string** *str*) (**string?**)

Removes the last element of `str` and returns it.
If it doesn't exist, returns `null(T)`.

<a id="func_12"></a>
> pop (**string** *str*, **int** *quantity*) (**string**)

Removes `quantity` elements from `str` and returns them.

<a id="func_13"></a>
> push (**string** *str*, **string** *value*)

Appends `value` to the back of `str`.

<a id="func_14"></a>
> remove (**string** *str*, **int** *index*)

Removes the element at the specified `index`.

<a id="func_15"></a>
> remove (**string** *str*, **int** *startIndex*, **int** *endIndex*)

Removes the elements from `startIndex` to `endIndex` included.

<a id="func_16"></a>
> reverse (**pure string** *str*) (**string**)

Returns an inverted version of `str`.

<a id="func_17"></a>
> shift (**string** *str*) (**string?**)

Removes the first element of `str` and returns it.
If it doesn't exist, returns `null(T)`.

<a id="func_18"></a>
> shift (**string** *str*, **int** *quantity*) (**string**)

Removes the first `quantity` elements from `str` and returns them.

<a id="func_19"></a>
> size (**pure string** *str*) (**int**)

Returns the size of `str`.

<a id="func_20"></a>
> slice (**pure string** *str*, **int** *startIndex*, **int** *endIndex*) (**string**)

Returns a slice of `str` from `startIndex` to `endIndex` included.

<a id="func_21"></a>
> unshift (**string** *str*, **string** *value*)

Prepends `value` to the front of `str`.

