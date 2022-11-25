# std.hashmap

Dictionnaire associant des valeurs par clés.
## Natifs
### HashMap\<T>
Dictionnaire associant des valeurs par clés.
### HashMapIterator\<T>
Itère sur une hashmap.
## Constructeurs
|Fonction|Entrée|
|-|-|
|[@**HashMap\<T>**](#ctor_0)||
|[@**HashMap\<T>**](#ctor_1)|**pure list\<string>** *param0*, **pure list\<T>** *param1*|
|[@**HashMap\<T>**](#ctor_2)|**pure list\<Pair\<string, T>>** *param0*|
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[byKeys](#func_0)|**pure HashMap\<T>** *hashmap*|**list\<string>**|
|[byValues](#func_1)|**pure HashMap\<T>** *hashmap*|**list\<T>**|
|[clear](#func_2)|**HashMap\<T>** *hashmap*|**HashMap\<T>**|
|[contains](#func_3)|**pure HashMap\<T>** *hashmap*, **string** *clé*|**bool**|
|[copy](#func_4)|**pure HashMap\<T>** *hashmap*|**HashMap\<T>**|
|[each](#func_5)|**pure HashMap\<T>** *hashmap*|**HashMapIterator\<T>**|
|[get](#func_6)|**pure HashMap\<T>** *hashmap*, **string** *clé*|**T?**|
|[getOr](#func_7)|**pure HashMap\<T>** *hashmap*, **string** *clé*, **T** *défaut*|**T**|
|[isEmpty](#func_8)|**pure HashMap\<T>** *hashmap*|**bool**|
|[next](#func_9)|**HashMapIterator\<T>** *itérateur*|**Pair\<string, T>?**|
|[print](#func_10)|**pure HashMap\<bool>** *hashmap*||
|[print](#func_11)|**pure HashMap\<int>** *hashmap*||
|[print](#func_12)|**pure HashMap\<float>** *hashmap*||
|[print](#func_13)|**pure HashMap\<string>** *hashmap*||
|[remove](#func_14)|**HashMap\<T>** *hashmap*, **pure string** *clé*||
|[set](#func_15)|**HashMap\<T>** *hashmap*, **pure string** *clé*, **T** *valeur*||
|[size](#func_16)|**pure HashMap\<T>** *hashmap*|**int**|


***
## Description des fonctions

<a id="func_0"></a>
> byKeys (**pure HashMap\<T>** *hashmap*) (**list\<string>**)

Returne la liste de toutes les clés.

<a id="func_1"></a>
> byValues (**pure HashMap\<T>** *hashmap*) (**list\<T>**)

Returne la liste de toutes les valeurs.

<a id="func_2"></a>
> clear (**HashMap\<T>** *hashmap*) (**HashMap\<T>**)

Vide la `hashmap`.

<a id="func_3"></a>
> contains (**pure HashMap\<T>** *hashmap*, **string** *clé*) (**bool**)

Renvoie `true` si `clé` existe dans la `hashmap`.

<a id="func_4"></a>
> copy (**pure HashMap\<T>** *hashmap*) (**HashMap\<T>**)

Returns a copy of the `hashmap`.

<a id="func_5"></a>
> each (**pure HashMap\<T>** *hashmap*) (**HashMapIterator\<T>**)

Returne un itérateur permettant d’itérer sur chaque paire de clés/valeurs.

<a id="func_6"></a>
> get (**pure HashMap\<T>** *hashmap*, **string** *clé*) (**T?**)

Returne la valeur associée avec `clé`.
Si cette valeur n’existe pas, retourne `null(T)`.

<a id="func_7"></a>
> getOr (**pure HashMap\<T>** *hashmap*, **string** *clé*, **T** *défaut*) (**T**)

Returne la valeur associée avec `clé`.
Si cette valeur n’existe pas, retourne `défaut`.

<a id="func_8"></a>
> isEmpty (**pure HashMap\<T>** *hashmap*) (**bool**)

Renvoie `true` si la `hashmap` ne contient rien.

<a id="func_9"></a>
> next (**HashMapIterator\<T>** *itérateur*) (**Pair\<string, T>?**)

Avance l’itérateur à l’élément suivant.

<a id="func_10"></a>
> print (**pure HashMap\<bool>** *hashmap*)

Affiche le contenu d’`hashmap`.

<a id="func_11"></a>
> print (**pure HashMap\<int>** *hashmap*)

Affiche le contenu d’`hashmap`.

<a id="func_12"></a>
> print (**pure HashMap\<float>** *hashmap*)

Affiche le contenu d’`hashmap`.

<a id="func_13"></a>
> print (**pure HashMap\<string>** *hashmap*)

Affiche le contenu d’`hashmap`.

<a id="func_14"></a>
> remove (**HashMap\<T>** *hashmap*, **pure string** *clé*)

Retire l’entrée `clé` de la `hashmap`.

<a id="func_15"></a>
> set (**HashMap\<T>** *hashmap*, **pure string** *clé*, **T** *valeur*)

Ajoute la nouvelle `valeur` à la `clé` correspondante dans la `hashmap`.

<a id="func_16"></a>
> size (**pure HashMap\<T>** *hashmap*) (**int**)

Returne le nombre d’élements dans la `hashmap`.

