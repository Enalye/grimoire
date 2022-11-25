# std.hashmap

Dictionary that associates values by keys.
## Natifs
### HashMap\<T>
Dictionary that associates values by keys.
### HashMapIterator\<T>
Iterate on a hashmap.
## Constructeurs
|Fonction|Entrée|
|-|-|
|[@**HashMap\<T>**](#ctor_0)||
|[@**HashMap\<T>**](#ctor_1)|**pure list\<string>** *param0*, **pure list\<T>** *param1*|
|[@**HashMap\<T>**](#ctor_2)|**pure list\<Pair\<string, T>>** *param0*|
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[byKeys](#func_0)|*hashmap*: **pure HashMap\<T>**|**list\<string>**|
|[byValues](#func_1)|*hashmap*: **pure HashMap\<T>**|**list\<T>**|
|[clear](#func_2)|*hashmap*: **HashMap\<T>**|**HashMap\<T>**|
|[contains](#func_3)|*hashmap*: **pure HashMap\<T>**, *key*: **string**|**bool**|
|[copy](#func_4)|*hashmap*: **pure HashMap\<T>**|**HashMap\<T>**|
|[each](#func_5)|*hashmap*: **pure HashMap\<T>**|**HashMapIterator\<T>**|
|[get](#func_6)|*hashmap*: **pure HashMap\<T>**, *key*: **string**|**T?**|
|[getOr](#func_7)|*hashmap*: **pure HashMap\<T>**, *key*: **string**, *default*: **T**|**T**|
|[isEmpty](#func_8)|*hashmap*: **pure HashMap\<T>**|**bool**|
|[next](#func_9)|*iterator*: **HashMapIterator\<T>**|**Pair\<string, T>?**|
|[print](#func_10)|*hashmap*: **pure HashMap\<bool>**||
|[print](#func_11)|*hashmap*: **pure HashMap\<int>**||
|[print](#func_12)|*hashmap*: **pure HashMap\<float>**||
|[print](#func_13)|*hashmap*: **pure HashMap\<string>**||
|[remove](#func_14)|*hashmap*: **HashMap\<T>**, *key*: **pure string**||
|[set](#func_15)|*hashmap*: **HashMap\<T>**, *key*: **pure string**, *value*: **T**||
|[size](#func_16)|*hashmap*: **pure HashMap\<T>**|**int**|


***
## Description des fonctions

<a id="func_0"></a>
> byKeys (*hashmap*: **pure HashMap\<T>**) (**list\<string>**)

Returns the list of all keys.

<a id="func_1"></a>
> byValues (*hashmap*: **pure HashMap\<T>**) (**list\<T>**)

Returns the list of all values.

<a id="func_2"></a>
> clear (*hashmap*: **HashMap\<T>**) (**HashMap\<T>**)

Clear the `hashmap`.

<a id="func_3"></a>
> contains (*hashmap*: **pure HashMap\<T>**, *key*: **string**) (**bool**)

Returns `true` if `key` exists inside the `hashmap`.

<a id="func_4"></a>
> copy (*hashmap*: **pure HashMap\<T>**) (**HashMap\<T>**)

Iterate on a hashmap.

<a id="func_5"></a>
> each (*hashmap*: **pure HashMap\<T>**) (**HashMapIterator\<T>**)

Returns an iterator that iterate through each key/value pairs.

<a id="func_6"></a>
> get (*hashmap*: **pure HashMap\<T>**, *key*: **string**) (**T?**)

Return the value associated with `key`.
If the value doesn't exist, returns `null(T)`.

<a id="func_7"></a>
> getOr (*hashmap*: **pure HashMap\<T>**, *key*: **string**, *default*: **T**) (**T**)

Return the value associated with `key`.
If the value doesn't exist, returns `default`.

<a id="func_8"></a>
> isEmpty (*hashmap*: **pure HashMap\<T>**) (**bool**)

Returns `true` if the `hashmap` contains nothing.

<a id="func_9"></a>
> next (*iterator*: **HashMapIterator\<T>**) (**Pair\<string, T>?**)

Advance the iterator to the next element.

<a id="func_10"></a>
> print (*hashmap*: **pure HashMap\<bool>**)

Display the content of `hashmap`.

<a id="func_11"></a>
> print (*hashmap*: **pure HashMap\<int>**)

Display the content of `hashmap`.

<a id="func_12"></a>
> print (*hashmap*: **pure HashMap\<float>**)

Display the content of `hashmap`.

<a id="func_13"></a>
> print (*hashmap*: **pure HashMap\<string>**)

Display the content of `hashmap`.

<a id="func_14"></a>
> remove (*hashmap*: **HashMap\<T>**, *key*: **pure string**)

Delete the entry `key` from the `hashmap`.

<a id="func_15"></a>
> set (*hashmap*: **HashMap\<T>**, *key*: **pure string**, *value*: **T**)

Add the new `value` to the corresponding `key` in the `hashmap`.

<a id="func_16"></a>
> size (*hashmap*: **pure HashMap\<T>**) (**int**)

Returns the number of elements in the `hashmap`.

