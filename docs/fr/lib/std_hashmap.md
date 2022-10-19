<a id="hashmap"></a>
# HashMap\<T\>
## Description

Dictionnaire associant des valeurs par clés.

## Constructeurs

|Fonction|Entrée|Sortie|
|-|-|-|
|[new](#new)||**[HashMap](#hashmap)\<T\>**|
|[new](#new_lists)|**pure list(string)** *clés*, **pure list(T)** *valeurs*|**[HashMap](#hashmap)\<T\>**|
|[new](#new_pairs)|**pure list([Pair](/fr/lib/std_pair#pair)\<string, T\>)** *pairs*|**[HashMap](#hashmap)\<T\>**|

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[clear](#clear)|**[HashMap](#hashmap)\<T\>** *hashmap*|**[HashMap](#hashmap)\<T\>**|
|[copy](#copy)|**pure [HashMap](#hashmap)\<T\>** *hashmap*|**[HashMap](#hashmap)\<T\>**|
|[each](#each)|**[HashMap](#hashmap)\<T\>** *hashmap*|**[HashMapIterator](#hashmapiterator)\<T\>**|
|[isEmpty](#isEmpty)|**pure [HashMap](#hashmap)\<T\>** *hashmap*|**bool**|
|[get](#get)|**pure [HashMap](#hashmap)\<T\>** *hashmap*, **pure string** *clé*|**T?**|
|[getOr](#get)|**pure [HashMap](#hashmap)\<T\>** *hashmap*, **pure string** *clé*, **T** *défaut*|**T**|
|[contains](#contains)|**pure [HashMap](#hashmap)\<T\>** *hashmap*, **string** *clé*|**bool**|
|[byKeys](#byKeys)|**pure [HashMap](#hashmap)\<T\>** *hashmap*|**list(string)**|
|[remove](#remove)|**[HashMap](#hashmap)\<T\>** *hashmap*, **pure string** clé||
|[set](#set)|**[HashMap](#hashmap)\<T\>** *hashmap*, **pure string** *clé*, **T** *valeur*||
|[size](#size)|**pure [HashMap](#hashmap)\<T\>** *hashmap*|**int**|
|[byValues](#byValues)|**pure [HashMap](#hashmap)\<T\>** *hashmap*|**list(T)**|

---

## Description des fonctions

<a id="clear"></a>
- clear (**[HashMap](#hashmap)\<T\>** *hashmap*) (**[HashMap](#hashmap)\<T\>**)

Vide l’HashMap.
___

<a id="copy"></a>
- copy (**pure [HashMap](#hashmap)\<T\>** *hashmap*) (**[HashMap](#hashmap)\<T\>**)

Returne une copie de l’HashMap.
___

<a id="each"></a>
- each (**pure [HashMap](#hashmap)\<T\>** hashmap) (**[HashMapIterator](#hashmapiterator)\<T\>**)

Returne un itérateur permettant d’itérer sur chaque paire de clés/valeurs.
___

<a id="isEmpty"></a>
- isEmpty (**pure [HashMap](#hashmap)\<T\>** *hashmap*) (**bool**)

Returne `true` si l’HashMap ne contient rien.
___

<a id="get"></a>
- get (**pure [HashMap](#hashmap)\<T\>** *hashmap*, **pure string** *clé*) (**T?**)

Returne la valeur associée avec `clé`.
Si cette valeur n’existe pas, retourne `null(T)`.
___

<a id="getOr"></a>
- getOr (**pure [HashMap](#hashmap)\<T\>** *hashmap*, **pure string** *clé*, **T** *défaut*) (**T**)

Returne la valeur associée avec `clé`.
Si cette valeur n’existe pas, retourne `défaut`.
___

<a id="contains"></a>
- contains (**pure [HashMap](#hashmap)\<T\>** *hashmap*, **pure string** *clé*) (**bool**)

Renvoie `true` si `clé` existe dans l’HashMap.
___

<a id="byKeys"></a>
- byKeys (**pure [HashMap](#hashmap)\<T\>** *hashmap*) (**list(string)**)

Returne la liste de toutes les clés.
___

<a id="remove"></a>
- remove (**[HashMap](#hashmap)\<T\>** *hashmap*, **pure string** *clé*) (**[HashMap](#hashmap)\<T\>**)

Retire l’entrée `clé` de l’HashMap.
___

<a id="set"></a>
- set (**[HashMap](#hashmap)\<T\>** *hashmap*, **pure string** clé, **T** *valeur*) (**[HashMap](#hashmap)\<T\>**)

Ajoute la nouvelle `valeur` à la `clé` correspondante dans l’HashMap.
___

<a id="size"></a>
- size (**[HashMap](#hashmap)\<T\>** *hashmap*) (**int**)

Returne le nombre d’élements dans l’HashMap.
___

<a id="byValues"></a>
- byValues (**[HashMap](#hashmap)\<T\>** *hashmap*) (**list(T)**)

Returnse la liste de toutes les valeurs.
___

<a id="hashmapiterator"></a>
# HashMapIterator\<T\>
## Description

Fournit un moyen d’itérer sur une HashMap.

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[next](#next)|[HashMapIterator](#hashmapiterator)\<T\> iterateur|bool, T|

## Description des fonctions

<a id="next"></a>
- next (**[HashMapIterator](#hashmapiterator)\<T\>** *iterateur*) (**T?**)

Avance l’itérateur à l’élément suivant.
