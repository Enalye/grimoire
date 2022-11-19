# std.list

Built-in type.
## Description
list is a collection of values of the same type.
## Natifs
### ListIterator\<T>
Iterate on a list.
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[clear](#func_0)|**list(T)** *lst*||
|[contains](#func_1)|**pure list(T)** *lst*, **pure T** *value*|**bool**|
|[copy](#func_2)|**pure list(T)** *lst*|**list(T)**|
|[each](#func_3)|**list(T)** *lst*|**ListIterator\<T>**|
|[fill](#func_4)|**list(T)** *lst*, **T** *value*||
|[first](#func_5)|**pure list(T)** *lst*|**T?**|
|[get](#func_6)|**pure list(T)** *lst*, **int** *index*|**T?**|
|[getOr](#func_7)|**pure list(T)** *lst*, **int** *index*, **T** *default*|**T**|
|[indexOf](#func_8)|**pure list(T)** *lst*, **pure T** *value*|**int?**|
|[insert](#func_9)|**list(T)** *lst*, **int** *index*, **T** *value*||
|[isEmpty](#func_10)|**pure list(T)** *lst*|**bool**|
|[last](#func_11)|**pure list(T)** *lst*|**T?**|
|[lastIndexOf](#func_12)|**pure list(T)** *lst*, **pure T** *value*|**int?**|
|[next](#func_13)|**ListIterator\<T>** *iterator*|**T?**|
|[pop](#func_14)|**list(T)** *lst*|**T?**|
|[pop](#func_15)|**list(T)** *lst*, **int** *quantity*|**list(T)**|
|[push](#func_16)|**list(T)** *lst*, **T** *value*||
|[remove](#func_17)|**list(T)** *lst*, **int** *index*||
|[remove](#func_18)|**list(T)** *lst*, **int** *startIndex*, **int** *endIndex*||
|[resize](#func_19)|**list(T)** *lst*, **int** *size*, **T** *default*||
|[reverse](#func_20)|**pure list(T)** *lst*|**list(T)**|
|[shift](#func_21)|**list(T)** *lst*|**T?**|
|[shift](#func_22)|**list(T)** *lst*, **int** *quantity*|**list(T)**|
|[size](#func_23)|**pure list(T)** *lst*|**int**|
|[slice](#func_24)|**pure list(T)** *lst*, **int** *startIndex*, **int** *endIndex*|**list(T)**|
|[sort](#func_25)|**list(int)** *lst*||
|[sort](#func_26)|**list(float)** *lst*||
|[sort](#func_27)|**list(string)** *lst*||
|[unshift](#func_28)|**list(T)** *lst*, **T** *value*||


***
## Description des fonctions

<a id="func_0"></a>
> clear (**list(T)** *lst*)

Cleanup `lst`.

<a id="func_1"></a>
> contains (**pure list(T)** *lst*, **pure T** *value*) (**bool**)

Returns `true` if `value` exists inside `lst`.

<a id="func_2"></a>
> copy (**pure list(T)** *lst*) (**list(T)**)

Returns a copy of `lst`.

<a id="func_3"></a>
> each (**list(T)** *lst*) (**ListIterator\<T>**)

Returns an iterator that iterate through each element of `lst`.

<a id="func_4"></a>
> fill (**list(T)** *lst*, **T** *value*)

Replace the content of `lst` by `value`.

<a id="func_5"></a>
> first (**pure list(T)** *lst*) (**T?**)

Returns the first element of `lst`.
If it doesn't exist, returns `null(T)`.

<a id="func_6"></a>
> get (**pure list(T)** *lst*, **int** *index*) (**T?**)

Returns the element at `index`'s position.
If it doesn't exist, returns `null(T)`.
If `index` is negative, `index` is calculated from the back of `lst`.

<a id="func_7"></a>
> getOr (**pure list(T)** *lst*, **int** *index*, **T** *default*) (**T**)

Returns the element at `index`'s position.
If it doesn't exist, returns the `default` value.
If `index` is negative, `index` is calculated from the back of `lst`.

<a id="func_8"></a>
> indexOf (**pure list(T)** *lst*, **pure T** *value*) (**int?**)

Returns the first occurence of `value` in `lst`, starting from `index`.
If `value` does't exist, `null(int) is returned.
If `index` is negative, `index` is calculated from the back of `lst`.

<a id="func_9"></a>
> insert (**list(T)** *lst*, **int** *index*, **T** *value*)

Insert `value` in `lst` at the specified `index`.
If `index` is greater than the size of `lst`, `value` is appended at the back of `lst`.
If `index` is negative, `index` is calculated from the back of `lst`.

<a id="func_10"></a>
> isEmpty (**pure list(T)** *lst*) (**bool**)

Returns `true` if `lst` contains nothing.

<a id="func_11"></a>
> last (**pure list(T)** *lst*) (**T?**)

Returns the last element of `lst`.
If it doesn't exist, returns `null(T)`.

<a id="func_12"></a>
> lastIndexOf (**pure list(T)** *lst*, **pure T** *value*) (**int?**)

Returns the last occurence of `value` in `lst`, starting from `index`.
If `value` does't exist, `null(int) is returned.
If `index` is negative, `index` is calculated from the back of `lst`.

<a id="func_13"></a>
> next (**ListIterator\<T>** *iterator*) (**T?**)

Advance the iterator to the next element.

<a id="func_14"></a>
> pop (**list(T)** *lst*) (**T?**)

Removes the last element of `lst` and returns it.
If it doesn't exist, returns `null(T)`.

<a id="func_15"></a>
> pop (**list(T)** *lst*, **int** *quantity*) (**list(T)**)

Removes `quantity` elements from `lst` and returns them.

<a id="func_16"></a>
> push (**list(T)** *lst*, **T** *value*)

Appends `value` to the back of `lst`.

<a id="func_17"></a>
> remove (**list(T)** *lst*, **int** *index*)

Removes the element at the specified `index`.

<a id="func_18"></a>
> remove (**list(T)** *lst*, **int** *startIndex*, **int** *endIndex*)

Removes the elements from `startIndex` to `endIndex` included.

<a id="func_19"></a>
> resize (**list(T)** *lst*, **int** *size*, **T** *default*)

Resize `lst`.
If `size` is greater than the size of `lst`, the rest is filled with `default`.

<a id="func_20"></a>
> reverse (**pure list(T)** *lst*) (**list(T)**)

Returns an inverted version of `lst`.

<a id="func_21"></a>
> shift (**list(T)** *lst*) (**T?**)

Removes the first element of `lst` and returns it.
If it doesn't exist, returns `null(T)`.

<a id="func_22"></a>
> shift (**list(T)** *lst*, **int** *quantity*) (**list(T)**)

Removes the first `quantity` elements from `lst` and returns them.

<a id="func_23"></a>
> size (**pure list(T)** *lst*) (**int**)

Returns the size of `lst`.

<a id="func_24"></a>
> slice (**pure list(T)** *lst*, **int** *startIndex*, **int** *endIndex*) (**list(T)**)

Returns a slice of `lst` from `startIndex` to `endIndex` included.

<a id="func_25"></a>
> sort (**list(int)** *lst*)

Sorts `lst`.

<a id="func_26"></a>
> sort (**list(float)** *lst*)

Sorts `lst`.

<a id="func_27"></a>
> sort (**list(string)** *lst*)

Sorts `lst`.

<a id="func_28"></a>
> unshift (**list(T)** *lst*, **T** *value*)

Prepends `value` to the front of `lst`.

