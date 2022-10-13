# list

Built-in type.

## Description

An list is a list of values of the same type that can be stored together.

## Functions

|Function|Input|Output|
|-|-|-|
|[clear](#clear)|[list](#list)(T) this|[list](#list)(T)|
|[copy](#copy)|[list](#list)(T) this|[list](#list)(T)|
|[each](#each)|[list](#list)(T) this|[ListIterator](#listiterator)\<T\>|
|[empty?](#empty)|[list](#list)(T) this|bool|
|[fill](#fill)|[list](#list)(T) this, T value|[list](#list)(T)|
|[indexOf](#indexOf)|[list](#list)(T) this, T value|int|
|[lastIndexOf](#lastIndexOf)|[list](#list)(T) this, T value|int|
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

## Function Descriptions

<a id="clear"></a>
- clear ( [list](#list)(T) this ) ( [list](#list)(T) )

Empty the list.
___

<a id="copy"></a>
- copy ( [list](#list)(T) this ) ( [list](#list)(T) )

Returns a copy of the list.
___

<a id="each"></a>
- each ( [list](#list)(T) this ) ( [ListIterator](#listiterator) )

Returns an iterator that iterate through each element.
___

<a id="empty"></a>
- empty? ( [list](#list)(T) this ) ( bool )

Returns `true` if the list has no element.
___

<a id="fill"></a>
- fill ( [list](#list)(T) this, T value ) ( [list](#list)(T) )

Replace the content of the list with `value`.
___

<a id="indexOf"></a>
- indexOf ( [list](#list)(T) this, T value ) ( int )

If `value` is found inside the list, returns the index of the first element found, otherwise -1 is returned.
___

<a id="lastIndexOf"></a>
- lastIndexOf ( [list](#list)(T) this, T value ) ( int )

If `value` is found inside the list, returns the index of the last element found, otherwise -1 is returned.
___

<a id="first"></a>
- first ( [list](#list)(T) this ) ( T )

Returns the first element of the list.
___

<a id="has"></a>
- has? ( [list](#list)(T) this, T value ) ( bool )

Returns `true` if the `value` is found inside the list.
___

<a id="insert"></a>
- insert ( [list](#list)(T) this, int index, T value ) ( [list](#list)(T) )

Insert the `value` to the list at the specified `index`.
___

<a id="last"></a>
- last ( [list](#list)(T) this ) ( T )

Returns the last element of the list.
___

<a id="pop_1"></a>
- pop ( [list](#list)(T) this ) ( T )

Remove the last element from the list.
___

<a id="pop_2"></a>
- pop ( [list](#list)(T) this, int count ) ( [list](#list)(T) )

Remove the last `count` element from the list.
___

<a id="push"></a>
- push ( [list](#list)(T) this, [list](#list] value ) ( [list](#list)(T) )

Append the `value` at the end of the list.
___

<a id="remove"></a>
- remove ( [list](#list)(T) this, int index ) ( [list](#list)(T) )

Delete the element at `index`.
___

<a id="remove"></a>
- remove ( [list](#list)(T) this, int startIndex, int endIndex ) ( [list](#list)(T) )

Delete the elements between `startIndex` and `endIndex` included.
___

<a id="reverse"></a>
- reverse ( [list](#list)(T) this ) ( [list](#list)(T) )

Invert the list.
___

<a id="shift_1"></a>
- shift ( [list](#list)(T) this ) ( [list](#list)(T) )

Remove the first element from the list.
___

<a id="shift_2"></a>
- shift ( [list](#list)(T) this, int count ) ( [list](#list)(T) )

Remove the first `count` element from the list.
___

<a id="slice"></a>
- slice ( [list](#list)(T) this, int startIndex, int endIndex ) ( [list](#list)(T) )

Returns the list from `startIndex` to `endIndex` included.
___

<a id="split"></a>
- split ( [list](#list)(T) this, T value ) ( [list](#list)(T) )

Remove the first `count` element from the list.
___

<a id="unshift"></a>
- unshift ( [list](#list)(T) this, T value ) ( [list](#list)(T) )

Prepend the `value` at the beginning of the list.
___

# ListIterator

## Description

Provides a way to iterate through an list.

## Functions

|Function|Input|Output|
|-|-|-|
|[next](#next)|[ListIterator](#listiterator)\<T\> this|bool, T|

## Function Descriptions

<a id="next"></a>
- next ( [ListIterator](#listiterator)\<T\> ) ( bool, T )

Advance the iterator to the next element.
Returns `true` while the iterator hasn't reach the end and the current element.
