# std.hashmap

Dictionary that associates values by keys.
## Natifs
### HashMap\<T>
Dictionary that associates values by keys.
### HashMapIterator\<T>
Iterate on a hashmap.
## Constructeurs
|Constructeur|Entrée|
|-|-|
|**HashMap\<T>**||
|**HashMap\<T>**|**pure list(string)**, **pure list(T)**|
|**HashMap\<T>**|**pure list(Pair\<string, T>)**|
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[byKeys](#func_0)|**pure HashMap\<T>** *hashmap*|**list(string)**|
|[byValues](#func_1)|**pure HashMap\<T>** *hashmap*|**list(T)**|
|[clear](#func_2)|**HashMap\<T>** *hashmap*|**HashMap\<T>**|
|[contains](#func_3)|**pure HashMap\<T>** *hashmap*, **string** *key*|**bool**|
|[copy](#func_4)|**pure HashMap\<T>** *hashmap*|**HashMap\<T>**|
|[each](#func_5)|**pure HashMap\<T>** *hashmap*|**HashMapIterator\<T>**|
|[get](#func_6)|**pure HashMap\<T>** *hashmap*, **string** *key*|**T?**|
|[getOr](#func_7)|**pure HashMap\<T>** *hashmap*, **string** *key*, **T** *default*|**T**|
|[isEmpty](#func_8)|**pure HashMap\<T>** *hashmap*|**bool**|
|[next](#func_9)|**HashMapIterator\<T>** *iterator*|**Pair\<string, T>?**|
|[print](#func_10)|**pure HashMap\<bool>** *hashmap*||
|[print](#func_11)|**pure HashMap\<int>** *hashmap*||
|[print](#func_12)|**pure HashMap\<float>** *hashmap*||
|[print](#func_13)|**pure HashMap\<string>** *hashmap*||
|[remove](#func_14)|**HashMap\<T>** *hashmap*, **pure string** *key*||
|[set](#func_15)|**HashMap\<T>** *hashmap*, **pure string** *key*, **T** *value*||
|[size](#func_16)|**pure HashMap\<T>** *hashmap*|**int**|


***
## Description des fonctions

<a id="func_0"></a>
> byKeys (**pure HashMap\<T>** *hashmap*) (**list(string)**)

Returns the list of all keys.

<a id="func_1"></a>
> byValues (**pure HashMap\<T>** *hashmap*) (**list(T)**)

Returns the list of all values.

<a id="func_2"></a>
> clear (**HashMap\<T>** *hashmap*) (**HashMap\<T>**)

Clear the `hashmap`.

<a id="func_3"></a>
> contains (**pure HashMap\<T>** *hashmap*, **string** *key*) (**bool**)

Returns `true` if `key` exists inside the `hashmap`.

<a id="func_4"></a>
> copy (**pure HashMap\<T>** *hashmap*) (**HashMap\<T>**)

Iterate on a hashmap.

<a id="func_5"></a>
> each (**pure HashMap\<T>** *hashmap*) (**HashMapIterator\<T>**)

Returns an iterator that iterate through each key/value pairs.

<a id="func_6"></a>
> get (**pure HashMap\<T>** *hashmap*, **string** *key*) (**T?**)

Return the value associated with `key`.
If the value doesn't exist, returns `null(T)`.

<a id="func_7"></a>
> getOr (**pure HashMap\<T>** *hashmap*, **string** *key*, **T** *default*) (**T**)

Return the value associated with `key`.
If the value doesn't exist, returns `default`.

<a id="func_8"></a>
> isEmpty (**pure HashMap\<T>** *hashmap*) (**bool**)

Returns `true` if the `hashmap` contains nothing.

<a id="func_9"></a>
> next (**HashMapIterator\<T>** *iterator*) (**Pair\<string, T>?**)

Advance the iterator to the next element.

<a id="func_10"></a>
> print (**pure HashMap\<bool>** *hashmap*)

Display the content of `hashmap`.

<a id="func_11"></a>
> print (**pure HashMap\<int>** *hashmap*)

Display the content of `hashmap`.

<a id="func_12"></a>
> print (**pure HashMap\<float>** *hashmap*)

Display the content of `hashmap`.

<a id="func_13"></a>
> print (**pure HashMap\<string>** *hashmap*)

Display the content of `hashmap`.

<a id="func_14"></a>
> remove (**HashMap\<T>** *hashmap*, **pure string** *key*)

Delete the entry `key` from the `hashmap`.

<a id="func_15"></a>
> set (**HashMap\<T>** *hashmap*, **pure string** *key*, **T** *value*)

Add the new `value` to the corresponding `key` in the `hashmap`.

<a id="func_16"></a>
> size (**pure HashMap\<T>** *hashmap*) (**int**)

Returns the number of elements in the `hashmap`.

