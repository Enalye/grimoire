<a id="hashmap"></a>
# HashMap\<T\>
## Description

Dictionnaire associant des valeurs par clés.

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[new](#new)||[HashMap](#hashmap)\<T\>|
|[new](#new_lists)|[list](/fr/lib/list#list)(string) clés, [list](/fr/lib/list#list)(T) valeurs|[HashMap](#hashmap)\<T\>|
|[new](#new_pairs)|[list](/fr/lib/list#list)([Pair](/fr/lib/pair#pair)\<[string](/fr/lib/string#string), T\>) pairs|[HashMap](#hashmap)\<T\>|
|[clear](#clear)|[HashMap](#hashmap)\<T\> hashmap|[HashMap](#hashmap)\<T\>|
|[copy](#copy)|[HashMap](#hashmap)\<T\> hashmap|[HashMap](#hashmap)\<T\>|
|[each](#each)|[HashMap](#hashmap)\<T\> hashmap|[HashMapIterator](#hashmapiterator)\<T\>|
|[empty?](#empty)|[HashMap](#hashmap)\<T\> hashmap|bool|
|[get](#get)|[HashMap](#hashmap)\<T\> hashmap, [string](/fr/lib/string#string) clé|T|
|[has?](#has)|[HashMap](#hashmap)\<T\> hashmap, [string](/fr/lib/string#string) clé|bool|
|[keys](#keys)|[HashMap](#hashmap)\<T\> hashmap|[list](/fr/lib/list#list)([string](/fr/lib/string#string))|
|[remove](#remove)|[HashMap](#hashmap)\<T\> hashmap, [string](/fr/lib/string#string) clé||
|[set](#set)|[HashMap](#hashmap)\<T\> hashmap, [string](/fr/lib/string#string) clé, T valeur||
|[size](#size)|[HashMap](#hashmap)\<T\> hashmap|int|
|[values](#values)|[HashMap](#hashmap)\<T\> hashmap|[list](/fr/lib/list#list)(T)|

## Description des fonctions

<a id="new"></a>
- new ( ) ( [HashMap](#hashmap)\<T\> )

Crée une HashMap vide.
___

<a id="new_lists"></a>
- new ( [list](/fr/lib/list#list)(string) clés, [list](/fr/lib/list#list)(T) valeurs ) ( [HashMap](#hashmap)\<T\> )

Crée une nouvelle HashMap en associant chaque clé avec sa valeur correspondante.
La taille de `clés` et de `valeurs` doivent correspondre.
___

<a id="new_pairs"></a>
- new ( [list](/fr/lib/list#list)([Pair](/fr/lib/pair#pair)\<[string](/fr/lib/string#string), T\>) paires ) ( [HashMap](#hashmap)\<T\> )

Crée une nouvelle HashMap à partir des `paires`.
___

<a id="clear"></a>
- clear ( [HashMap](#hashmap)\<T\> hashmap ) ( [HashMap](#hashmap)\<T\> )

Vide l’HashMap.
___

<a id="copy"></a>
- copy ( [HashMap](#hashmap)\<T\> hashmap ) ( [HashMap](#hashmap)\<T\> )

Returne une copie de l’HashMap.
___

<a id="each"></a>
- each ( [HashMap](#hashmap)\<T\> hashmap ) ( [HashMapIterator](#hashmapiterator)\<T\> )

Returne un itérateur permettant d’itérer sur chaque paire de clés/valeurs.
___

<a id="empty"></a>
- empty? ( [HashMap](#hashmap)\<T\> hashmap ) ( bool )

Returne `true` si l’HashMap ne contient rien.
___

<a id="get"></a>
- get ( [HashMap](#hashmap)\<T\> hashmap, [string](/fr/lib/string#string) clé ) ( T )

Returns the valeur associated with the specified `clé`.
___

<a id="has"></a>
- has? ( [HashMap](#hashmap)\<T\> hashmap, [string](/fr/lib/string#string) clé ) ( bool )

Returns `true` if the `clé` exists inside the HashMap.
___

<a id="keys"></a>
- keys ( [HashMap](#hashmap)\<T\> hashmap ) ( [list](/fr/lib/list#list)([string](/fr/lib/string#string)) )

Returns the list of all clés.
___

<a id="remove"></a>
- remove ( [HashMap](#hashmap)\<T\> hashmap, [string](/fr/lib/string#string) clé ) ( [HashMap](#hashmap)\<T\> )

Delete the entry `clé`.
___

<a id="set"></a>
- set ( [HashMap](#hashmap)\<T\> hashmap, [string](/fr/lib/string#string) clé, T valeur ) ( [HashMap](#hashmap)\<T\> )

Adds the specified `clé` and `valeur` to the HashMap.
___

<a id="size"></a>
- size ( [HashMap](#hashmap)\<T\> hashmap ) ( int )

Returns the number of elements in the HashMap.
___

<a id="values"></a>
- values ( [HashMap](#hashmap)\<T\> hashmap ) ( [list](/fr/lib/list#list)(T) )

Returns the list of all valeurs.
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
- next ( [HashMapIterator](#hashmapiterator)\<T\> iterateur ) ( bool, T )

Advance l’itérateur à l’élément suivant.
Retourne `true` tant que l’itérateur n’a pas atteint la fin de la liste et retourne l’élément actuel.