# array

Type de base.

## Description

Une array est une liste de valeur d’un même type pouvant être stockées ensemble.

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[clear](#clear)|[array](#array)(T) this|[array](#array)(T)|
|[copy](#copy)|[array](#array)(T) this|[array](#array)(T)|
|[each](#each)|[array](#array)(T) this|[ArrayIterator](#arrayiterator)\<T\>|
|[empty?](#empty)|[array](#array)(T) this|bool|
|[fill](#fill)|[array](#array)(T) this, T value|[array](#array)(T)|
|[findFirst](#findFirst)|[array](#array)(T) this, T value|int|
|[findLast](#findLast)|[array](#array)(T) this, T value|int|
|[first](#first)|[array](#array)(T) this|T|
|[has?](#has)|[array](#array)(T) this, T value|bool|
|[insert](#insert)|[array](#array)(T) this, int index, T value|[array](#array)(T)|
|[last](#last)|[array](#array)(T) this|T|
|[pop](#pop_1)|[array](#array)(T) this|T|
|[pop](#pop_2)|[array](#array)(T) this, int count|[array](#array)(T)|
|[push](#push)|[array](#array)(T) this, T value|[array](#array)(T)|
|[size](#size)|[array](#array)(T) this|int|
|[sort](#sort)|[array](#array)(T) this|[array](#array)(T)|
|[split](#split)|[array](#array)(T) this, T value|[array](#array)([array](#array)(T))|
|[remove](#remove)|[array](#array)(T) this, int index|[array](#array)(T)|
|[remove](#remove)|[array](#array)(T) this, int startIndex, int endIndex|[array](#array)(T)|
|[resize](#resize)|[array](#array)(T) this|[array](#array)(T)|
|[reverse](#reverse)|[array](#array)(T) this|[array](#array)(T)|
|[shift](#shift_1)|[array](#array)(T) this|T|
|[shift](#shift_2)|[array](#array)(T) this, int count|[array](#array)(T)|
|[slice](#slice)|[array](#array)(T) this, int startIndex, int endIndex|[array](#array)(T)|
|[sliced](#sliced)|[array](#array)(T) this, int startIndex, int endIndex|[array](#array)(T)|
|[unshift](#unshift)|[array](#array)(T) this, T value|[array](#array)(T)|

## Description des fonctions

<a id="clear"></a>
- clear ( [array](#array)(T) this ) ( [array](#array)(T) )

Vide la liste.
___

<a id="copy"></a>
- copy ( [array](#array)(T) this ) ( [array](#array)(T) )

Retourne une copie de la liste.
___

<a id="each"></a>
- each ( [array](#array)(T) this ) ( [ArrayIterator](#arrayiterator) )

Retourne un itérateur itérant à travers chaque élément.
___

<a id="empty"></a>
- empty? ( [array](#array)(T) this ) ( bool )

Returne `true` si la liste ne contient rien.
___

<a id="fill"></a>
- fill ( [array](#array)(T) this, T value ) ( [array](#array)(T) )

Remplace le contenu de la liste par `value`.
___

<a id="findFirst"></a>
- findFirst ( [array](#array)(T) this, T value ) ( int )

Si `value` est trouvé dans la liste, returne l’index du premier élement trouvé, sinon -1 est retourné.
___

<a id="findLast"></a>
- findLast ( [array](#array)(T) this, T value ) ( int )

Si `value` est trouvé dans la liste, returne l’index du dernier élement trouvé, sinon -1 est retourné.
___

<a id="first"></a>
- first ( [array](#array)(T) this ) ( T )

Retourne le premier élément de la liste.
___

<a id="has"></a>
- has? ( [array](#array)(T) this, T value ) ( bool )

Returne `true` si `value` est trouvé dans la liste.
___

<a id="insert"></a>
- insert ( [array](#array)(T) this, int index, T value ) ( [array](#array)(T) )

Insère `value` dans la liste à l’`index` spécifié.
___

<a id="last"></a>
- last ( [array](#array)(T) this ) ( T )

Returne le dernier élément de la liste.
___

<a id="pop_1"></a>
- pop ( [array](#array)(T) this ) ( T )

Retire le dernier élément de la liste et les retourne.
___

<a id="pop_2"></a>
- pop ( [array](#array)(T) this, int count ) ( [array](#array)(T) )

Retire `count` éléments de la liste et les retourne.
___

<a id="push"></a>
- push ( [array](#array)(T) this, [array](#array] value ) ( [array](#array)(T) )

Ajoute `value` en fin de liste.
___

<a id="remove"></a>
- remove ( [array](#array)(T) this, int index ) ( [array](#array)(T) )

Retire l’élément à l’`index` spécifié.
___

<a id="remove"></a>
- remove ( [array](#array)(T) this, int startIndex, int endIndex ) ( [array](#array)(T) )

Retire les éléments de `startIndex` à `endIndex` inclus.
___

<a id="reverse"></a>
- reverse ( [array](#array)(T) this ) ( [array](#array)(T) )

Inverse la liste.
___

<a id="shift_1"></a>
- shift ( [array](#array)(T) this ) ( [array](#array)(T) )

Retire le premier élément de la liste.
___

<a id="shift_2"></a>
- shift ( [array](#array)(T) this, int count ) ( [array](#array)(T) )

Retire les premiers `count` éléments de la liste.
___

<a id="slice"></a>
- slice ( [array](#array)(T) this, int startIndex, int endIndex ) ( [array](#array)(T) )

Retourne une portion de la liste de `startIndex` jusqu’à `endIndex` inclus.
___

<a id="split"></a>
- split ( [array](#array)(T) this, T index ) ( [array](#array)(T) )

Coupe la liste en deux à l’`index` indiqué.
___

<a id="unshift"></a>
- unshift ( [array](#array)(T) this, T value ) ( [array](#array)(T) )

Ajoute `value` en début de liste.
___

# ArrayIterator

## Description

Fournit un moyen d’itérer sur les éléments d’une liste.

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[next](#next)|[ArrayIterator](#arrayiterator)\<T\> this|bool, T|

## Description des fonctions

<a id="next"></a>
- next ( [ArrayIterator](#arrayiterator)\<T\> ) ( bool, T )

Avance l’itérateur à l’élément suivant.
Retourne `true` tant que l’itérateur n’a pas atteint la fin de la liste et retourne l’élément actuel.
