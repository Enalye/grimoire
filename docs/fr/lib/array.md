# list

Type de base.

## Description

Une list est une liste de valeur d’un même type pouvant être stockées ensemble.

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[clear](#clear)|[list](#list)(T) this|[list](#list)(T)|
|[copy](#copy)|[list](#list)(T) this|[list](#list)(T)|
|[each](#each)|[list](#list)(T) this|[ListIterator](#listiterator)\<T\>|
|[empty?](#empty)|[list](#list)(T) this|bool|
|[fill](#fill)|[list](#list)(T) this, T value|[list](#list)(T)|
|[findFirst](#findFirst)|[list](#list)(T) this, T value|int|
|[findLast](#findLast)|[list](#list)(T) this, T value|int|
|[first](#first)|[list](#list)(T) this|T|
|[has?](#has)|[list](#list)(T) this, T value|bool|
|[insert](#insert)|[list](#list)(T) this, int index, T value|[list](#list)(T)|
|[last](#last)|[list](#list)(T) this|T|
|[pop](#pop_1)|[list](#list)(T) this|T|
|[pop](#pop_2)|[list](#list)(T) this, int count|[list](#list)(T)|
|[push](#push)|[list](#list)(T) this, T value|[list](#list)(T)|
|[size](#size)|[list](#list)(T) this|int|
|[sort](#sort)|[list](#list)(T) this|[list](#list)(T)|
|[split](#split)|[list](#list)(T) this, T value|[list](#list)([list](#list)(T))|
|[remove](#remove)|[list](#list)(T) this, int index|[list](#list)(T)|
|[remove](#remove)|[list](#list)(T) this, int startIndex, int endIndex|[list](#list)(T)|
|[resize](#resize)|[list](#list)(T) this|[list](#list)(T)|
|[reverse](#reverse)|[list](#list)(T) this|[list](#list)(T)|
|[shift](#shift_1)|[list](#list)(T) this|T|
|[shift](#shift_2)|[list](#list)(T) this, int count|[list](#list)(T)|
|[slice](#slice)|[list](#list)(T) this, int startIndex, int endIndex|[list](#list)(T)|
|[sliced](#sliced)|[list](#list)(T) this, int startIndex, int endIndex|[list](#list)(T)|
|[unshift](#unshift)|[list](#list)(T) this, T value|[list](#list)(T)|

## Description des fonctions

<a id="clear"></a>
- clear ( [list](#list)(T) this ) ( [list](#list)(T) )

Vide la liste.
___

<a id="copy"></a>
- copy ( [list](#list)(T) this ) ( [list](#list)(T) )

Retourne une copie de la liste.
___

<a id="each"></a>
- each ( [list](#list)(T) this ) ( [ListIterator](#listiterator) )

Retourne un itérateur itérant à travers chaque élément.
___

<a id="empty"></a>
- empty? ( [list](#list)(T) this ) ( bool )

Returne `true` si la liste ne contient rien.
___

<a id="fill"></a>
- fill ( [list](#list)(T) this, T value ) ( [list](#list)(T) )

Remplace le contenu de la liste par `value`.
___

<a id="findFirst"></a>
- findFirst ( [list](#list)(T) this, T value ) ( int )

Si `value` est trouvé dans la liste, returne l’index du premier élement trouvé, sinon -1 est retourné.
___

<a id="findLast"></a>
- findLast ( [list](#list)(T) this, T value ) ( int )

Si `value` est trouvé dans la liste, returne l’index du dernier élement trouvé, sinon -1 est retourné.
___

<a id="first"></a>
- first ( [list](#list)(T) this ) ( T )

Retourne le premier élément de la liste.
___

<a id="has"></a>
- has? ( [list](#list)(T) this, T value ) ( bool )

Returne `true` si `value` est trouvé dans la liste.
___

<a id="insert"></a>
- insert ( [list](#list)(T) this, int index, T value ) ( [list](#list)(T) )

Insère `value` dans la liste à l’`index` spécifié.
___

<a id="last"></a>
- last ( [list](#list)(T) this ) ( T )

Returne le dernier élément de la liste.
___

<a id="pop_1"></a>
- pop ( [list](#list)(T) this ) ( T )

Retire le dernier élément de la liste et les retourne.
___

<a id="pop_2"></a>
- pop ( [list](#list)(T) this, int count ) ( [list](#list)(T) )

Retire `count` éléments de la liste et les retourne.
___

<a id="push"></a>
- push ( [list](#list)(T) this, [list](#list] value ) ( [list](#list)(T) )

Ajoute `value` en fin de liste.
___

<a id="remove"></a>
- remove ( [list](#list)(T) this, int index ) ( [list](#list)(T) )

Retire l’élément à l’`index` spécifié.
___

<a id="remove"></a>
- remove ( [list](#list)(T) this, int startIndex, int endIndex ) ( [list](#list)(T) )

Retire les éléments de `startIndex` à `endIndex` inclus.
___

<a id="reverse"></a>
- reverse ( [list](#list)(T) this ) ( [list](#list)(T) )

Inverse la liste.
___

<a id="shift_1"></a>
- shift ( [list](#list)(T) this ) ( [list](#list)(T) )

Retire le premier élément de la liste.
___

<a id="shift_2"></a>
- shift ( [list](#list)(T) this, int count ) ( [list](#list)(T) )

Retire les premiers `count` éléments de la liste.
___

<a id="slice"></a>
- slice ( [list](#list)(T) this, int startIndex, int endIndex ) ( [list](#list)(T) )

Retourne une portion de la liste de `startIndex` jusqu’à `endIndex` inclus.
___

<a id="split"></a>
- split ( [list](#list)(T) this, T index ) ( [list](#list)(T) )

Coupe la liste en deux à l’`index` indiqué.
___

<a id="unshift"></a>
- unshift ( [list](#list)(T) this, T value ) ( [list](#list)(T) )

Ajoute `value` en début de liste.
___

# ListIterator

## Description

Fournit un moyen d’itérer sur les éléments d’une liste.

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[next](#next)|[ListIterator](#listiterator)\<T\> this|bool, T|

## Description des fonctions

<a id="next"></a>
- next ( [ListIterator](#listiterator)\<T\> ) ( bool, T )

Avance l’itérateur à l’élément suivant.
Retourne `true` tant que l’itérateur n’a pas atteint la fin de la liste et retourne l’élément actuel.
