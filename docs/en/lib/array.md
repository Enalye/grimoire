# array

Built-in type.

## Description

An array is a list of values of the same type that can be stored together.

## Functions

|Function|Input|Output|
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

## Function Descriptions

<a id="clear"></a>
- clear ( [array](#array)(T) this ) ( [array](#array)(T) )

Empty the array.
___

<a id="copy"></a>
- copy ( [array](#array)(T) this ) ( [array](#array)(T) )

Returns a copy of the array.
___

<a id="each"></a>
- each ( [array](#array)(T) this ) ( [ArrayIterator](#arrayiterator) )

Returns an iterator that iterate through each element.
___

<a id="empty"></a>
- empty? ( [array](#array)(T) this ) ( bool )

Returns `true` if the array has no element.
___

<a id="fill"></a>
- fill ( [array](#array)(T) this, T value ) ( [array](#array)(T) )

Replace the content of the array with `value`.
___

<a id="findFirst"></a>
- findFirst ( [array](#array)(T) this, T value ) ( int )

If `value` is found inside the array, returns the index of the first element found, otherwise -1 is returned.
___

<a id="findLast"></a>
- findLast ( [array](#array)(T) this, T value ) ( int )

If `value` is found inside the array, returns the index of the last element found, otherwise -1 is returned.
___

<a id="first"></a>
- first ( [array](#array)(T) this ) ( T )

Returns the first element of the array.
___

<a id="has"></a>
- has? ( [array](#array)(T) this, T value ) ( bool )

Returns `true` if the `value` is found inside the array.
___

<a id="insert"></a>
- insert ( [array](#array)(T) this, int index, T value ) ( [array](#array)(T) )

Insert the `value` to the array at the specified `index`.
___

<a id="last"></a>
- last ( [array](#array)(T) this ) ( T )

Returns the last element of the array.
___

<a id="pop_1"></a>
- pop ( [array](#array)(T) this ) ( T )

Remove the last element from the array.
___

<a id="pop_2"></a>
- pop ( [array](#array)(T) this, int count ) ( [array](#array)(T) )

Remove the last `count` element from the array.
___

<a id="push"></a>
- push ( [array](#array)(T) this, [array](#array] value ) ( [array](#array)(T) )

Append the `value` at the end of the array.
___

<a id="remove"></a>
- remove ( [array](#array)(T) this, int index ) ( [array](#array)(T) )

Delete the element at `index`.
___

<a id="remove"></a>
- remove ( [array](#array)(T) this, int startIndex, int endIndex ) ( [array](#array)(T) )

Delete the elements between `startIndex` and `endIndex` included.
___

<a id="reverse"></a>
- reverse ( [array](#array)(T) this ) ( [array](#array)(T) )

Invert the array.
___

<a id="shift_1"></a>
- shift ( [array](#array)(T) this ) ( [array](#array)(T) )

Remove the first element from the array.
___

<a id="shift_2"></a>
- shift ( [array](#array)(T) this, int count ) ( [array](#array)(T) )

Remove the first `count` element from the array.
___

<a id="slice"></a>
- slice ( [array](#array)(T) this, int startIndex, int endIndex ) ( [array](#array)(T) )

Returns the array from `startIndex` to `endIndex` included.
___

<a id="split"></a>
- split ( [array](#array)(T) this, T value ) ( [array](#array)(T) )

Remove the first `count` element from the array.
___

<a id="unshift"></a>
- unshift ( [array](#array)(T) this, T value ) ( [array](#array)(T) )

Prepend the `value` at the beginning of the array.
___

# ArrayIterator

## Description

Provides a way to iterate through an array.

## Functions

|Function|Input|Output|
|-|-|-|
|[next](#next)|[ArrayIterator](#arrayiterator)\<T\> this|bool, T|

## Function Descriptions

<a id="next"></a>
- next ( [ArrayIterator](#arrayiterator)\<T\> ) ( bool, T )

Advance the iterator to the next element.
Returns `true` while the iterator hasn't reach the end and the current element.
