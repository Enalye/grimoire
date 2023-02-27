# std.list

Built-in type.
## Description
A list is a collection of values of the same type.
## Natives
### ListIterator\<T>
Iterate on a list.
## Functions
|Function|Input|Output|
|-|-|-|
|[back](#func_0)|*self*: **pure [T]**|**T?**|
|[clear](#func_1)|*self*: **[T]**||
|[contains](#func_2)|*self*: **pure [T]**, *value*: **pure T**|**bool**|
|[copy](#func_3)|*self*: **pure [T]**|**[T]**|
|[each](#func_4)|*self*: **[T]**|**ListIterator\<T>**|
|[fill](#func_5)|*self*: **[T]**, *value*: **T**||
|[find](#func_6)|*self*: **pure [T]**, *value*: **pure T**|**uint?**|
|[front](#func_7)|*self*: **pure [T]**|**T?**|
|[get](#func_8)|*self*: **pure [T]**, *idx*: **int**|**T?**|
|[getOr](#func_9)|*self*: **pure [T]**, *idx*: **int**, *def*: **T**|**T**|
|[insert](#func_10)|*self*: **[T]**, *idx*: **int**, *value*: **T**||
|[isEmpty](#func_11)|*self*: **pure [T]**|**bool**|
|[next](#func_12)|*iterator*: **ListIterator\<T>**|**T?**|
|[popBack](#func_13)|*self*: **[T]**|**T?**|
|[popBack](#func_14)|*self*: **[T]**, *count*: **int**|**[T]**|
|[popFront](#func_15)|*self*: **[T]**|**T?**|
|[popFront](#func_16)|*self*: **[T]**, *count*: **uint**|**[T]**|
|[pushBack](#func_17)|*self*: **[T]**, *value*: **T**||
|[pushFront](#func_18)|*self*: **[T]**, *value*: **T**||
|[remove](#func_19)|*self*: **[T]**, *idx*: **int**||
|[remove](#func_20)|*self*: **[T]**, *start*: **int**, *end*: **int**||
|[resize](#func_21)|*self*: **[T]**, *len*: **int**, *def*: **T**||
|[reverse](#func_22)|*self*: **pure [T]**|**[T]**|
|[rfind](#func_23)|*self*: **pure [T]**, *value*: **pure T**|**uint?**|
|[size](#func_24)|*self*: **pure [T]**|**int**|
|[slice](#func_25)|*self*: **pure [T]**, *start*: **int**, *end*: **int**|**[T]**|
|[sort](#func_26)|*self*: **[int]**||
|[sort](#func_27)|*self*: **[float]**||
|[sort](#func_28)|*self*: **[string]**||


***
## Function descriptions

<a id="func_0"></a>
> back (*self*: **pure [T]**) (**T?**)

Returns the last element of the list.

If it doesn't exist, returns `null<T>`.

<a id="func_1"></a>
> clear (*self*: **[T]**)

Clear the list.

<a id="func_2"></a>
> contains (*self*: **pure [T]**, *value*: **pure T**) (**bool**)

Returns `true` if `value` exists inside the list.

<a id="func_3"></a>
> copy (*self*: **pure [T]**) (**[T]**)

Returns a copy of the list.

<a id="func_4"></a>
> each (*self*: **[T]**) (**ListIterator\<T>**)

Returns an iterator that iterate through each element of the list.

<a id="func_5"></a>
> fill (*self*: **[T]**, *value*: **T**)

Replace the content of the list by `value`.

<a id="func_6"></a>
> find (*self*: **pure [T]**, *value*: **pure T**) (**uint?**)

Returns the first occurence of `value` in the list, starting from the index.

If `value` does't exist, `null<int> is returned.

A negative index is calculated from the back of the list.

<a id="func_7"></a>
> front (*self*: **pure [T]**) (**T?**)

Returns the first element of the list.

If it doesn't exist, returns `null<T>`.

<a id="func_8"></a>
> get (*self*: **pure [T]**, *idx*: **int**) (**T?**)

Returns the element at index position.

If it doesn't exist, returns `null<T>`.

A negative index is calculated from the back of the list.

<a id="func_9"></a>
> getOr (*self*: **pure [T]**, *idx*: **int**, *def*: **T**) (**T**)

Returns the element at index position.

If it doesn't exist, returns the default `def` value.

A negative index is calculated from the back of the list.

<a id="func_10"></a>
> insert (*self*: **[T]**, *idx*: **int**, *value*: **T**)

Insert `value` in the list at the specified `index`.

If `index` is greater than the size of the list, `value` is appended at the back of the list.

A negative index is calculated from the back of the list.

<a id="func_11"></a>
> isEmpty (*self*: **pure [T]**) (**bool**)

Returns `true` if the list is empty.

<a id="func_12"></a>
> next (*iterator*: **ListIterator\<T>**) (**T?**)

Advance the iterator to the next element.

<a id="func_13"></a>
> popBack (*self*: **[T]**) (**T?**)

Removes the last element of the list and returns it.

If it doesn't exist, returns `null<T>`.

<a id="func_14"></a>
> popBack (*self*: **[T]**, *count*: **int**) (**[T]**)

Removes the last N elements from the list and returns them.

<a id="func_15"></a>
> popFront (*self*: **[T]**) (**T?**)

Removes the first element of the list and returns it.

If it doesn't exist, returns `null<T>`.

<a id="func_16"></a>
> popFront (*self*: **[T]**, *count*: **uint**) (**[T]**)

Removes the first N elements from the list and returns them.

<a id="func_17"></a>
> pushBack (*self*: **[T]**, *value*: **T**)

Appends `value` to the back of the list.

<a id="func_18"></a>
> pushFront (*self*: **[T]**, *value*: **T**)

Prepends `value` to the front of the list.

<a id="func_19"></a>
> remove (*self*: **[T]**, *idx*: **int**)

Removes the element at the specified index.

A negative index is calculated from the back of the list.

<a id="func_20"></a>
> remove (*self*: **[T]**, *start*: **int**, *end*: **int**)

Removes the elements from `start` to `end` included.

A negative index is calculated from the back of the list.

<a id="func_21"></a>
> resize (*self*: **[T]**, *len*: **int**, *def*: **T**)

Resize the list.

If `len` is greater than the size of the list, the rest is filled with `def`.

<a id="func_22"></a>
> reverse (*self*: **pure [T]**) (**[T]**)

Returns an inverted version of the list.

<a id="func_23"></a>
> rfind (*self*: **pure [T]**, *value*: **pure T**) (**uint?**)

Returns the last occurence of `value` in the list, starting from the index.

If `value` does't exist, `null<int> is returned.

A negative index is calculated from the back of the list.

<a id="func_24"></a>
> size (*self*: **pure [T]**) (**int**)

Returns the size of the list.

<a id="func_25"></a>
> slice (*self*: **pure [T]**, *start*: **int**, *end*: **int**) (**[T]**)

Returns a slice of the list from `start` to `end` included.

A negative index is calculated from the back of the list.

<a id="func_26"></a>
> sort (*self*: **[int]**)

Sorts the list.

<a id="func_27"></a>
> sort (*self*: **[float]**)

Sorts the list.

<a id="func_28"></a>
> sort (*self*: **[string]**)

Sorts the list.

