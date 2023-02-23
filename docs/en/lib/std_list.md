# std.list

Built-in type.
## Description
list is a collection of values of the same type.
## Natives
### ListIterator\<T>
Iterate on a list.
## Functions
|Function|Input|Output|
|-|-|-|
|[clear](#func_0)|*lst*: **list\<T>**||
|[contains](#func_1)|*lst*: **pure list\<T>**, *value*: **pure T**|**bool**|
|[copy](#func_2)|*lst*: **pure list\<T>**|**list\<T>**|
|[each](#func_3)|*lst*: **list\<T>**|**ListIterator\<T>**|
|[fill](#func_4)|*lst*: **list\<T>**, *value*: **T**||
|[first](#func_5)|*lst*: **pure list\<T>**|**T?**|
|[get](#func_6)|*lst*: **pure list\<T>**, *index*: **int**|**T?**|
|[getOr](#func_7)|*lst*: **pure list\<T>**, *index*: **int**, *default*: **T**|**T**|
|[indexOf](#func_8)|*lst*: **pure list\<T>**, *value*: **pure T**|**int?**|
|[insert](#func_9)|*lst*: **list\<T>**, *index*: **int**, *value*: **T**||
|[isEmpty](#func_10)|*lst*: **pure list\<T>**|**bool**|
|[last](#func_11)|*lst*: **pure list\<T>**|**T?**|
|[lastIndexOf](#func_12)|*lst*: **pure list\<T>**, *value*: **pure T**|**int?**|
|[next](#func_13)|*iterator*: **ListIterator\<T>**|**T?**|
|[pop](#func_14)|*lst*: **list\<T>**|**T?**|
|[pop](#func_15)|*lst*: **list\<T>**, *quantity*: **int**|**list\<T>**|
|[push](#func_16)|*lst*: **list\<T>**, *value*: **T**||
|[remove](#func_17)|*lst*: **list\<T>**, *index*: **int**||
|[remove](#func_18)|*lst*: **list\<T>**, *startIndex*: **int**, *endIndex*: **int**||
|[resize](#func_19)|*lst*: **list\<T>**, *size*: **int**, *default*: **T**||
|[reverse](#func_20)|*lst*: **pure list\<T>**|**list\<T>**|
|[shift](#func_21)|*lst*: **list\<T>**|**T?**|
|[shift](#func_22)|*lst*: **list\<T>**, *quantity*: **int**|**list\<T>**|
|[size](#func_23)|*lst*: **pure list\<T>**|**int**|
|[slice](#func_24)|*lst*: **pure list\<T>**, *startIndex*: **int**, *endIndex*: **int**|**list\<T>**|
|[sort](#func_25)|*lst*: **list\<int>**||
|[sort](#func_26)|*lst*: **list\<float>**||
|[sort](#func_27)|*lst*: **list\<string>**||
|[unshift](#func_28)|*lst*: **list\<T>**, *value*: **T**||


***
## Function descriptions

<a id="func_0"></a>
> clear (*lst*: **list\<T>**)

Cleanup `lst`.

<a id="func_1"></a>
> contains (*lst*: **pure list\<T>**, *value*: **pure T**) (**bool**)

Returns `true` if `value` exists inside `lst`.

<a id="func_2"></a>
> copy (*lst*: **pure list\<T>**) (**list\<T>**)

Returns a copy of `lst`.

<a id="func_3"></a>
> each (*lst*: **list\<T>**) (**ListIterator\<T>**)

Returns an iterator that iterate through each element of `lst`.

<a id="func_4"></a>
> fill (*lst*: **list\<T>**, *value*: **T**)

Replace the content of `lst` by `value`.

<a id="func_5"></a>
> first (*lst*: **pure list\<T>**) (**T?**)

Returns the first element of `lst`.
If it doesn't exist, returns `null<T>`.

<a id="func_6"></a>
> get (*lst*: **pure list\<T>**, *index*: **int**) (**T?**)

Returns the element at `index`'s position.
If it doesn't exist, returns `null<T>`.
If `index` is negative, `index` is calculated from the back of `lst`.

<a id="func_7"></a>
> getOr (*lst*: **pure list\<T>**, *index*: **int**, *default*: **T**) (**T**)

Returns the element at `index`'s position.
If it doesn't exist, returns the `default` value.
If `index` is negative, `index` is calculated from the back of `lst`.

<a id="func_8"></a>
> indexOf (*lst*: **pure list\<T>**, *value*: **pure T**) (**int?**)

Returns the first occurence of `value` in `lst`, starting from `index`.
If `value` does't exist, `null<int> is returned.
If `index` is negative, `index` is calculated from the back of `lst`.

<a id="func_9"></a>
> insert (*lst*: **list\<T>**, *index*: **int**, *value*: **T**)

Insert `value` in `lst` at the specified `index`.
If `index` is greater than the size of `lst`, `value` is appended at the back of `lst`.
If `index` is negative, `index` is calculated from the back of `lst`.

<a id="func_10"></a>
> isEmpty (*lst*: **pure list\<T>**) (**bool**)

Returns `true` if `lst` contains nothing.

<a id="func_11"></a>
> last (*lst*: **pure list\<T>**) (**T?**)

Returns the last element of `lst`.
If it doesn't exist, returns `null<T>`.

<a id="func_12"></a>
> lastIndexOf (*lst*: **pure list\<T>**, *value*: **pure T**) (**int?**)

Returns the last occurence of `value` in `lst`, starting from `index`.
If `value` does't exist, `null<int> is returned.
If `index` is negative, `index` is calculated from the back of `lst`.

<a id="func_13"></a>
> next (*iterator*: **ListIterator\<T>**) (**T?**)

Advance the iterator to the next element.

<a id="func_14"></a>
> pop (*lst*: **list\<T>**) (**T?**)

Removes the last element of `lst` and returns it.
If it doesn't exist, returns `null<T>`.

<a id="func_15"></a>
> pop (*lst*: **list\<T>**, *quantity*: **int**) (**list\<T>**)

Removes `quantity` elements from `lst` and returns them.

<a id="func_16"></a>
> push (*lst*: **list\<T>**, *value*: **T**)

Appends `value` to the back of `lst`.

<a id="func_17"></a>
> remove (*lst*: **list\<T>**, *index*: **int**)

Removes the element at the specified `index`.

<a id="func_18"></a>
> remove (*lst*: **list\<T>**, *startIndex*: **int**, *endIndex*: **int**)

Removes the elements from `startIndex` to `endIndex` included.

<a id="func_19"></a>
> resize (*lst*: **list\<T>**, *size*: **int**, *default*: **T**)

Resize `lst`.
If `size` is greater than the size of `lst`, the rest is filled with `default`.

<a id="func_20"></a>
> reverse (*lst*: **pure list\<T>**) (**list\<T>**)

Returns an inverted version of `lst`.

<a id="func_21"></a>
> shift (*lst*: **list\<T>**) (**T?**)

Removes the first element of `lst` and returns it.
If it doesn't exist, returns `null<T>`.

<a id="func_22"></a>
> shift (*lst*: **list\<T>**, *quantity*: **int**) (**list\<T>**)

Removes the first `quantity` elements from `lst` and returns them.

<a id="func_23"></a>
> size (*lst*: **pure list\<T>**) (**int**)

Returns the size of `lst`.

<a id="func_24"></a>
> slice (*lst*: **pure list\<T>**, *startIndex*: **int**, *endIndex*: **int**) (**list\<T>**)

Returns a slice of `lst` from `startIndex` to `endIndex` included.

<a id="func_25"></a>
> sort (*lst*: **list\<int>**)

Sorts `lst`.

<a id="func_26"></a>
> sort (*lst*: **list\<float>**)

Sorts `lst`.

<a id="func_27"></a>
> sort (*lst*: **list\<string>**)

Sorts `lst`.

<a id="func_28"></a>
> unshift (*lst*: **list\<T>**, *value*: **T**)

Prepends `value` to the front of `lst`.

