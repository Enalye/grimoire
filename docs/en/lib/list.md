# list

Built-in type.
## Description
A list is a collection of values of the same type.

## Natives
### ListIterator\<T>
Iterate on a list.
## Functions
|Function|Input|Output|
|-|-|-|
|[back](#func_0)|*array*: **pure [T]**|**T?**|
|[clear](#func_1)|*array*: **[T]**||
|[contains](#func_2)|*array*: **pure [T]**, *value*: **pure T**|**bool**|
|[copy](#func_3)|*array*: **pure [T]**|**[T]**|
|[each](#func_4)|*array*: **[T]**|**ListIterator\<T>**|
|[fill](#func_5)|*array*: **[T]**, *value*: **T**||
|[find](#func_6)|*array*: **pure [T]**, *value*: **pure T**|**uint?**|
|[front](#func_7)|*array*: **pure [T]**|**T?**|
|[get](#func_8)|*array*: **pure [T]**, *idx*: **int**|**T?**|
|[getOr](#func_9)|*array*: **pure [T]**, *idx*: **int**, *default*: **T**|**T**|
|[insert](#func_10)|*array*: **[T]**, *idx*: **int**, *value*: **T**||
|[isEmpty](#func_11)|*array*: **pure [T]**|**bool**|
|[next](#func_12)|*iterator*: **ListIterator\<T>**|**T?**|
|[popBack](#func_13)|*array*: **[T]**|**T?**|
|[popBack](#func_14)|*array*: **[T]**, *count*: **int**|**[T]**|
|[popFront](#func_15)|*array*: **[T]**|**T?**|
|[popFront](#func_16)|*array*: **[T]**, *count*: **uint**|**[T]**|
|[pushBack](#func_17)|*array*: **[T]**, *value*: **T**||
|[pushFront](#func_18)|*array*: **[T]**, *value*: **T**||
|[remove](#func_19)|*array*: **[T]**, *idx*: **int**||
|[remove](#func_20)|*array*: **[T]**, *start*: **int**, *end*: **int**||
|[resize](#func_21)|*array*: **[T]**, *length*: **int**, *default*: **T**||
|[reverse](#func_22)|*array*: **pure [T]**|**[T]**|
|[rfind](#func_23)|*array*: **pure [T]**, *value*: **pure T**|**uint?**|
|[size](#func_24)|*array*: **pure [T]**|**int**|
|[slice](#func_25)|*array*: **pure [T]**, *start*: **int**, *end*: **int**|**[T]**|
|[sort](#func_26)|*array*: **[int]**||
|[sort](#func_27)|*array*: **[float]**||
|[sort](#func_28)|*array*: **[string]**||


***
## Function descriptions

<a id="func_0"></a>
> back(*array*: **pure [T]**) (**T?**)

Returns the last element of the list.

If it doesn't exist, returns `null<T>`.

<a id="func_1"></a>
> clear(*array*: **[T]**)

Clear the list.

<a id="func_2"></a>
> contains(*array*: **pure [T]**, *value*: **pure T**) (**bool**)

Returns `true` if `value` exists inside the list.

<a id="func_3"></a>
> copy(*array*: **pure [T]**) (**[T]**)

Returns a copy of the list.

<a id="func_4"></a>
> each(*array*: **[T]**) (**ListIterator\<T>**)

Returns an iterator that iterate through each element of the list.

<a id="func_5"></a>
> fill(*array*: **[T]**, *value*: **T**)

Replace the content of the list by `value`.

<a id="func_6"></a>
> find(*array*: **pure [T]**, *value*: **pure T**) (**uint?**)

Returns the first occurence of `value` in the list, starting from the index.

If `value` does't exist, `null<int> is returned.

A negative index is calculated from the back of the list.

<a id="func_7"></a>
> front(*array*: **pure [T]**) (**T?**)

Returns the first element of the list.

If it doesn't exist, returns `null<T>`.

<a id="func_8"></a>
> get(*array*: **pure [T]**, *idx*: **int**) (**T?**)

Returns the element at index position.

If it doesn't exist, returns `null<T>`.

A negative index is calculated from the back of the list.

<a id="func_9"></a>
> getOr(*array*: **pure [T]**, *idx*: **int**, *default*: **T**) (**T**)

Returns the element at index position.

If it doesn't exist, returns the default `default` value.

A negative index is calculated from the back of the list.

<a id="func_10"></a>
> insert(*array*: **[T]**, *idx*: **int**, *value*: **T**)

Insert `value` in the list at the specified `index`.

If `index` is greater than the size of the list, `value` is appended at the back of the list.

A negative index is calculated from the back of the list.

<a id="func_11"></a>
> isEmpty(*array*: **pure [T]**) (**bool**)

Returns `true` if the list is empty.

<a id="func_12"></a>
> next(*iterator*: **ListIterator\<T>**) (**T?**)

Advance the iterator to the next element.

<a id="func_13"></a>
> popBack(*array*: **[T]**) (**T?**)

Removes the last element of the list and returns it.

If it doesn't exist, returns `null<T>`.

<a id="func_14"></a>
> popBack(*array*: **[T]**, *count*: **int**) (**[T]**)

Removes the last N elements from the list and returns them.

<a id="func_15"></a>
> popFront(*array*: **[T]**) (**T?**)

Removes the first element of the list and returns it.

If it doesn't exist, returns `null<T>`.

<a id="func_16"></a>
> popFront(*array*: **[T]**, *count*: **uint**) (**[T]**)

Removes the first N elements from the list and returns them.

<a id="func_17"></a>
> pushBack(*array*: **[T]**, *value*: **T**)

Appends `value` to the back of the list.

<a id="func_18"></a>
> pushFront(*array*: **[T]**, *value*: **T**)

Prepends `value` to the front of the list.

<a id="func_19"></a>
> remove(*array*: **[T]**, *idx*: **int**)

Removes the element at the specified index.

A negative index is calculated from the back of the list.

<a id="func_20"></a>
> remove(*array*: **[T]**, *start*: **int**, *end*: **int**)

Removes the elements from `start` to `end` included.

A negative index is calculated from the back of the list.

<a id="func_21"></a>
> resize(*array*: **[T]**, *length*: **int**, *default*: **T**)

Resize the list.

If `len` is greater than the size of the list, the rest is filled with `default`.

<a id="func_22"></a>
> reverse(*array*: **pure [T]**) (**[T]**)

Returns an inverted version of the list.

<a id="func_23"></a>
> rfind(*array*: **pure [T]**, *value*: **pure T**) (**uint?**)

Returns the last occurence of `value` in the list, starting from the index.

If `value` does't exist, `null<int> is returned.

A negative index is calculated from the back of the list.

<a id="func_24"></a>
> size(*array*: **pure [T]**) (**int**)

Returns the size of the list.

<a id="func_25"></a>
> slice(*array*: **pure [T]**, *start*: **int**, *end*: **int**) (**[T]**)

Returns a slice of the list from `start` to `end` included.

A negative index is calculated from the back of the list.

<a id="func_26"></a>
> sort(*array*: **[int]**)

Sorts the list.

<a id="func_27"></a>
> sort(*array*: **[float]**)

Sorts the list.

<a id="func_28"></a>
> sort(*array*: **[string]**)

Sorts the list.

