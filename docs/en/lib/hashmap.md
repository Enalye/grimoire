# hashmap

Dictionary that associates values by keys.
## Natives
### HashMap\<T>
Dictionary that associates values by keys.
### HashMapIterator\<T>
Iterate on the elements of a hashmap.
## Constructors
|Function|Input|
|-|-|
|[@**HashMap\<T>**](#ctor_0)||
|[@**HashMap\<T>**](#ctor_1)|**pure [string]** *param0*, **pure [T]** *param1*|
|[@**HashMap\<T>**](#ctor_2)|**pure [Pair\<string, T>]** *param0*|
## Functions
|Function|Input|Output|
|-|-|-|
|[byKeys](#func_0)|*self*: **pure HashMap\<T>**|**[string]**|
|[byValues](#func_1)|*self*: **pure HashMap\<T>**|**[T]**|
|[clear](#func_2)|*self*: **HashMap\<T>**|**HashMap\<T>**|
|[contains](#func_3)|*self*: **pure HashMap\<T>**, *key*: **string**|**bool**|
|[copy](#func_4)|*self*: **pure HashMap\<T>**|**HashMap\<T>**|
|[each](#func_5)|*self*: **pure HashMap\<T>**|**HashMapIterator\<T>**|
|[get](#func_6)|*self*: **pure HashMap\<T>**, *key*: **string**|**T?**|
|[getOr](#func_7)|*self*: **pure HashMap\<T>**, *key*: **string**, *def*: **T**|**T**|
|[isEmpty](#func_8)|*self*: **pure HashMap\<T>**|**bool**|
|[next](#func_9)|*iterator*: **HashMapIterator\<T>**|**Pair\<string, T>?**|
|[print](#func_10)|*self*: **pure HashMap\<bool>**||
|[print](#func_11)|*self*: **pure HashMap\<int>**||
|[print](#func_12)|*self*: **pure HashMap\<float>**||
|[print](#func_13)|*self*: **pure HashMap\<string>**||
|[remove](#func_14)|*self*: **HashMap\<T>**, *key*: **pure string**||
|[set](#func_15)|*self*: **HashMap\<T>**, *key*: **pure string**, *value*: **T**||
|[size](#func_16)|*self*: **pure HashMap\<T>**|**int**|


***
## Function descriptions

<a id="func_0"></a>
> byKeys (*self*: **pure HashMap\<T>**) (**[string]**)

Returns the list of all keys.

<a id="func_1"></a>
> byValues (*self*: **pure HashMap\<T>**) (**[T]**)

Returns the list of all values.

<a id="func_2"></a>
> clear (*self*: **HashMap\<T>**) (**HashMap\<T>**)

Clear the hashmap.

<a id="func_3"></a>
> contains (*self*: **pure HashMap\<T>**, *key*: **string**) (**bool**)

Returns `true` if the key exists inside the hashmap.

<a id="func_4"></a>
> copy (*self*: **pure HashMap\<T>**) (**HashMap\<T>**)

Iterate on the elements of a hashmap.

<a id="func_5"></a>
> each (*self*: **pure HashMap\<T>**) (**HashMapIterator\<T>**)

Returns an iterator that iterate through each key/value pairs.

<a id="func_6"></a>
> get (*self*: **pure HashMap\<T>**, *key*: **string**) (**T?**)

Return the value associated with `key`.

If the value doesn't exist, returns `null<T>`.

<a id="func_7"></a>
> getOr (*self*: **pure HashMap\<T>**, *key*: **string**, *def*: **T**) (**T**)

Return the value associated with `key`.

If the value doesn't exist, returns `def`.

<a id="func_8"></a>
> isEmpty (*self*: **pure HashMap\<T>**) (**bool**)

Returns `true` if the hashmap contains nothing.

<a id="func_9"></a>
> next (*iterator*: **HashMapIterator\<T>**) (**Pair\<string, T>?**)

Advance the iterator to the next element.

<a id="func_10"></a>
> print (*self*: **pure HashMap\<bool>**)

Display the content of hashmap.

<a id="func_11"></a>
> print (*self*: **pure HashMap\<int>**)

Display the content of hashmap.

<a id="func_12"></a>
> print (*self*: **pure HashMap\<float>**)

Display the content of hashmap.

<a id="func_13"></a>
> print (*self*: **pure HashMap\<string>**)

Display the content of hashmap.

<a id="func_14"></a>
> remove (*self*: **HashMap\<T>**, *key*: **pure string**)

Delete the entry `key` from the hashmap.

<a id="func_15"></a>
> set (*self*: **HashMap\<T>**, *key*: **pure string**, *value*: **T**)

Add the new value to the corresponding key in the hashmap.

<a id="func_16"></a>
> size (*self*: **pure HashMap\<T>**) (**int**)

Returns the number of elements in the hashmap.

