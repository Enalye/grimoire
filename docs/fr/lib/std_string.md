# string

Type de base.

## Description

Type pouvant contenir des caractères UTF-8.

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[each](#each)|string|[StringIterator](#stringiterator)|
|[empty?](#empty)|string this|bool|
|[indexOf](#indexOf)|string this, string subString|int|
|[lastIndexOf](#lastIndexOf)|string this, string subString|int|
|[first](#first)|string this|string|
|[has?](#has)|string this, string subString|string|
|[insert](#insert)|string this, int index, string value|string|
|[last](#last)|string this|string|
|[pop](#pop_1)|string this|string|
|[pop](#pop_2)|string this, int count|string|
|[push](#push)|string this, string value|string|
|[remove](#remove)|string this, int index|string|
|[remove](#remove)|string this, int startIndex, int endIndex|string|
|[reverse](#reverse)|string this|string|
|[shift](#shift_1)|string this|string|
|[shift](#shift_2)|string this, int count|string|
|[slice](#slice)|string this, int startIndex, int endIndex|string|
|[split](#split)|string(T) this, T value|list(string))|
|[unshift](#unshift)|string this, string value|string|

## Description des fonctions

<a id="each"></a>
- each ( string this ) ( [StringIterator](#stringiterator) )

Returns an iterator that iterate through each character.
___

<a id="empty"></a>
- empty? ( string this ) ( bool )

Returns `true` if the string has no character.
___

<a id="indexOf"></a>
- indexOf ( string this, string subString ) ( int )

If `subString` is found inside the string, returns the index of the first element found, otherwise -1 is returned.
___

<a id="lastIndexOf"></a>
- lastIndexOf ( string this, string subString ) ( int )

If `subString` is found inside the string, returns the index of the last element found, otherwise -1 is returned.
___

<a id="first"></a>
- first ( string this ) ( string )

Returns the first character of the string.
___

<a id="has"></a>
- has? ( string this, string subString ) ( bool )

Returns `true` if the `subString` is found inside the string.
___

<a id="insert"></a>
- insert ( string this, int index, string value ) ( string )

Insert the `subString` to the string at the specified `index`.
___

<a id="last"></a>
- last ( string this ) ( string )

Returns the last character of the string.
___

<a id="pop_1"></a>
- pop ( string this ) ( string )

Remove the last element from the string.
___

<a id="pop_2"></a>
- pop ( string this, int count ) ( string )

Remove the last `count` element from the string.
___

<a id="push"></a>
- push ( string this, [string](#string] value ) ( string )

Append the `value` at the end of the string.
___

<a id="remove"></a>
- remove ( string this, int index ) ( string )

Delete the element at `index`.
___

<a id="remove"></a>
- remove ( string this, int startIndex, int endIndex ) ( string )

Delete the elements between `startIndex` and `endIndex` included.
___

<a id="reverse"></a>
- reverse ( string this ) ( string )

Invert the string.
___

<a id="shift_1"></a>
- shift ( string this ) ( string )

Remove the first element from the string.
___

<a id="shift_2"></a>
- shift ( string this, int count ) ( string )

Remove the first `count` element from the string.
___

<a id="slice"></a>
- slice ( string this, int startIndex, int endIndex ) ( string )

Returns the string from `startIndex` to `endIndex` included.
___

<a id="split"></a>
- split ( string(T) this, T value ) ( string )

Remove the first `count` element from the string.
___

<a id="unshift"></a>
- unshift ( string this, string value ) ( list(string) )

Prepend the `value` at the beginning of the string.
___

# StringIterator

## Description

Provides a way to iterate through an list.

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[next](#next)|[StringIterator](#stringiterator) this|bool, string|

## Description des fonctions

<a id="next"></a>
- next ( [StringIterator](#stringiterator) ) ( bool, string )

Advance the iterator to the next element.
Returns `true` while the iterator hasn't reach the end and the current element.