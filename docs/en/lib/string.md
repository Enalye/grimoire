# string

Built-in type.

## Description

Type that can hold UTF-8 characters.

## Functions

|Function|Input|Output|
|-|-|-|
|[each](#each)|[string](#string)|[StringIterator](#stringiterator)|
|[empty?](#empty)|[string](#string) this|bool|
|[indexOf](#indexOf)|[string](#string) this, [string](#string) subString|int|
|[lastIndexOf](#lastIndexOf)|[string](#string) this, [string](#string) subString|int|
|[first](#first)|[string](#string) this|[string](#string)|
|[has?](#has)|[string](#string) this, [string](#string) subString|[string](#string)|
|[insert](#insert)|[string](#string) this, int index, [string](#string) value|[string](#string)|
|[last](#last)|[string](#string) this|[string](#string)|
|[pop](#pop_1)|[string](#string) this|[string](#string)|
|[pop](#pop_2)|[string](#string) this, int count|[string](#string)|
|[push](#push)|[string](#string) this, [string](#string) value|[string](#string)|
|[remove](#remove)|[string](#string) this, int index|[string](#string)|
|[remove](#remove)|[string](#string) this, int startIndex, int endIndex|[string](#string)|
|[reverse](#reverse)|[string](#string) this|[string](#string)|
|[shift](#shift_1)|[string](#string) this|[string](#string)|
|[shift](#shift_2)|[string](#string) this, int count|[string](#string)|
|[slice](#slice)|[string](#string) this, int startIndex, int endIndex|[string](#string)|
|[split](#split)|[string](#string)(T) this, T value|[list](/en/lib/list#list)([string](#string)))|
|[unshift](#unshift)|[string](#string) this, [string](#string) value|[string](#string)|

## Function Descriptions

<a id="each"></a>
- each ( [string](#string) this ) ( [StringIterator](#stringiterator) )

Returns an iterator that iterate through each character.
___

<a id="empty"></a>
- empty? ( [string](#string) this ) ( bool )

Returns `true` if the string has no character.
___

<a id="indexOf"></a>
- indexOf ( [string](#string) this, [string](#string) subString ) ( int )

If `subString` is found inside the string, returns the index of the first element found, otherwise -1 is returned.
___

<a id="lastIndexOf"></a>
- lastIndexOf ( [string](#string) this, [string](#string) subString ) ( int )

If `subString` is found inside the string, returns the index of the last element found, otherwise -1 is returned.
___

<a id="first"></a>
- first ( [string](#string) this ) ( [string](#string) )

Returns the first character of the string.
___

<a id="has"></a>
- has? ( [string](#string) this, [string](#string) subString ) ( bool )

Returns `true` if the `subString` is found inside the string.
___

<a id="insert"></a>
- insert ( [string](#string) this, int index, [string](#string) value ) ( [string](#string) )

Insert the `subString` to the string at the specified `index`.
___

<a id="last"></a>
- last ( [string](#string) this ) ( [string](#string) )

Returns the last character of the string.
___

<a id="pop_1"></a>
- pop ( [string](#string) this ) ( [string](#string) )

Remove the last element from the string.
___

<a id="pop_2"></a>
- pop ( [string](#string) this, int count ) ( [string](#string) )

Remove the last `count` element from the string.
___

<a id="push"></a>
- push ( [string](#string) this, [string](#string] value ) ( [string](#string) )

Append the `value` at the end of the string.
___

<a id="remove"></a>
- remove ( [string](#string) this, int index ) ( [string](#string) )

Delete the element at `index`.
___

<a id="remove"></a>
- remove ( [string](#string) this, int startIndex, int endIndex ) ( [string](#string) )

Delete the elements between `startIndex` and `endIndex` included.
___

<a id="reverse"></a>
- reverse ( [string](#string) this ) ( [string](#string) )

Invert the string.
___

<a id="shift_1"></a>
- shift ( [string](#string) this ) ( [string](#string) )

Remove the first element from the string.
___

<a id="shift_2"></a>
- shift ( [string](#string) this, int count ) ( [string](#string) )

Remove the first `count` element from the string.
___

<a id="slice"></a>
- slice ( [string](#string) this, int startIndex, int endIndex ) ( [string](#string) )

Returns the string from `startIndex` to `endIndex` included.
___

<a id="split"></a>
- split ( [string](#string)(T) this, T value ) ( [string](#string) )

Remove the first `count` element from the string.
___

<a id="unshift"></a>
- unshift ( [string](#string) this, [string](#string) value ) ( [list](/en/lib/list#list)([string](#string)) )

Prepend the `value` at the beginning of the string.
___

# StringIterator

## Description

Provides a way to iterate through an list.

## Functions

|Function|Input|Output|
|-|-|-|
|[next](#next)|[StringIterator](#stringiterator) this|bool, [string](#string)|

## Function Descriptions

<a id="next"></a>
- next ( [StringIterator](#stringiterator) ) ( bool, [string](#string) )

Advance the iterator to the next element.
Returns `true` while the iterator hasn't reach the end and the current element.