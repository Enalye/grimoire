# hashmap

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
|[@**HashMap\<T>**](#ctor_1)| *param0*: **pure [string]**,  *param1*: **pure [T]**|
|[@**HashMap\<T>**](#ctor_2)| *param0*: **pure [Pair\<string, T>]**|
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[byKeys](#func_0)|*hashmap*: **pure HashMap\<T>**|**[string]**|
|[byValues](#func_1)|*hashmap*: **pure HashMap\<T>**|**[T]**|
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
> byKeys(*hashmap*: **pure HashMap\<T>**) (**[string]**)

Returne la liste de toutes les clés.

<a id="func_1"></a>
> byValues(*hashmap*: **pure HashMap\<T>**) (**[T]**)

Returne la liste de toutes les valeurs.

<a id="func_2"></a>
> clear(*hashmap*: **HashMap\<T>**) (**HashMap\<T>**)

Vide la hashmap.

<a id="func_3"></a>
> contains(*hashmap*: **pure HashMap\<T>**, *key*: **string**) (**bool**)

Renvoie `true` si la clé existe dans la hashmap.

<a id="func_4"></a>
> copy(*hashmap*: **pure HashMap\<T>**) (**HashMap\<T>**)

Returns a copy of the hashmap.

<a id="func_5"></a>
> each(*hashmap*: **pure HashMap\<T>**) (**HashMapIterator\<T>**)

Returne un itérateur permettant d’itérer sur chaque paire de clés/valeurs.

<a id="func_6"></a>
> get(*hashmap*: **pure HashMap\<T>**, *key*: **string**) (**T?**)

Returne la valeur associée avec `key`.

Si cette valeur n’existe pas, retourne `null<T>`.

<a id="func_7"></a>
> getOr(*hashmap*: **pure HashMap\<T>**, *key*: **string**, *default*: **T**) (**T**)

Returne la valeur associée avec `key`.

Si cette valeur n’existe pas, retourne `def`.

<a id="func_8"></a>
> isEmpty(*hashmap*: **pure HashMap\<T>**) (**bool**)

Renvoie `true` si la hashmap ne contient rien.

<a id="func_9"></a>
> next(*iterator*: **HashMapIterator\<T>**) (**Pair\<string, T>?**)

Avance l’itérateur à l’élément suivant.

<a id="func_10"></a>
> print(*hashmap*: **pure HashMap\<bool>**)

Affiche le contenu d’hashmap.

<a id="func_11"></a>
> print(*hashmap*: **pure HashMap\<int>**)

Affiche le contenu d’hashmap.

<a id="func_12"></a>
> print(*hashmap*: **pure HashMap\<float>**)

Affiche le contenu d’hashmap.

<a id="func_13"></a>
> print(*hashmap*: **pure HashMap\<string>**)

Affiche le contenu d’hashmap.

<a id="func_14"></a>
> remove(*hashmap*: **HashMap\<T>**, *key*: **pure string**)

Retire l’entrée `key` de la hashmap.

<a id="func_15"></a>
> set(*hashmap*: **HashMap\<T>**, *key*: **pure string**, *value*: **T**)

Ajoute la nouvelle valeur à la clé correspondante dans la hashmap.

<a id="func_16"></a>
> size(*hashmap*: **pure HashMap\<T>**) (**int**)

Returne le nombre d’élements dans la hashmap.

