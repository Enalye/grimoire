# std.hashmap

Dictionnaire associant des valeurs par clés.
## Natifs
### HashMap\<T>
Dictionnaire associant des valeurs par clés.
### HashMapIterator\<T>
Itère sur les éléments d’une hashmap.
## Constructeurs
|Fonction|Entrée|
|-|-|
|[@**HashMap\<T>**](#ctor_0)||
|[@**HashMap\<T>**](#ctor_1)|**pure [string]** *param0*, **pure [T]** *param1*|
|[@**HashMap\<T>**](#ctor_2)|**pure [Pair\<string, T>]** *param0*|
## Fonctions
|Fonction|Entrée|Sortie|
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
|[next](#func_9)|*itérateur*: **HashMapIterator\<T>**|**Pair\<string, T>?**|
|[print](#func_10)|*self*: **pure HashMap\<bool>**||
|[print](#func_11)|*self*: **pure HashMap\<int>**||
|[print](#func_12)|*self*: **pure HashMap\<float>**||
|[print](#func_13)|*self*: **pure HashMap\<string>**||
|[remove](#func_14)|*self*: **HashMap\<T>**, *key*: **pure string**||
|[set](#func_15)|*self*: **HashMap\<T>**, *key*: **pure string**, *value*: **T**||
|[size](#func_16)|*self*: **pure HashMap\<T>**|**int**|


***
## Description des fonctions

<a id="func_0"></a>
> byKeys (*self*: **pure HashMap\<T>**) (**[string]**)

Returne la liste de toutes les clés.

<a id="func_1"></a>
> byValues (*self*: **pure HashMap\<T>**) (**[T]**)

Returne la liste de toutes les valeurs.

<a id="func_2"></a>
> clear (*self*: **HashMap\<T>**) (**HashMap\<T>**)

Vide la hashmap.

<a id="func_3"></a>
> contains (*self*: **pure HashMap\<T>**, *key*: **string**) (**bool**)

Renvoie `true` si la clé existe dans la hashmap.

<a id="func_4"></a>
> copy (*self*: **pure HashMap\<T>**) (**HashMap\<T>**)

Returns a copy of the hashmap.

<a id="func_5"></a>
> each (*self*: **pure HashMap\<T>**) (**HashMapIterator\<T>**)

Returne un itérateur permettant d’itérer sur chaque paire de clés/valeurs.

<a id="func_6"></a>
> get (*self*: **pure HashMap\<T>**, *key*: **string**) (**T?**)

Returne la valeur associée avec `key`.

Si cette valeur n’existe pas, retourne `null<T>`.

<a id="func_7"></a>
> getOr (*self*: **pure HashMap\<T>**, *key*: **string**, *def*: **T**) (**T**)

Returne la valeur associée avec `key`.

Si cette valeur n’existe pas, retourne `def`.

<a id="func_8"></a>
> isEmpty (*self*: **pure HashMap\<T>**) (**bool**)

Renvoie `true` si la hashmap ne contient rien.

<a id="func_9"></a>
> next (*itérateur*: **HashMapIterator\<T>**) (**Pair\<string, T>?**)

Avance l’itérateur à l’élément suivant.

<a id="func_10"></a>
> print (*self*: **pure HashMap\<bool>**)

Affiche le contenu d’hashmap.

<a id="func_11"></a>
> print (*self*: **pure HashMap\<int>**)

Affiche le contenu d’hashmap.

<a id="func_12"></a>
> print (*self*: **pure HashMap\<float>**)

Affiche le contenu d’hashmap.

<a id="func_13"></a>
> print (*self*: **pure HashMap\<string>**)

Affiche le contenu d’hashmap.

<a id="func_14"></a>
> remove (*self*: **HashMap\<T>**, *key*: **pure string**)

Retire l’entrée `key` de la hashmap.

<a id="func_15"></a>
> set (*self*: **HashMap\<T>**, *key*: **pure string**, *value*: **T**)

Ajoute la nouvelle valeur à la clé correspondante dans la hashmap.

<a id="func_16"></a>
> size (*self*: **pure HashMap\<T>**) (**int**)

Returne le nombre d’élements dans la hashmap.

