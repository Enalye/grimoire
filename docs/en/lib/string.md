# string

Built-in type.

## Description

Type that can hold UTF-8 characters.

## Functions

|Function|Input|Output|
|-|-|-|
|each|string|[StringIterator](#stringiterator)|
|empty?|string this|bool|
|findFirst|string this, string subString|string|
|findLast|string this, string subString|string|
|first|string this|string|
|has?|string this, string subString|string|
|insert|string this, int index, string value|string|
|last|string this|string|
|pop|string this|string|
|pop|string this, int count|string|
|push|string this, string value|string|
|remove|string this, int index|string|
|remove|string this, int startIndex, int endIndex|string|
|reverse|string this|string|
|shift|string this|string|
|shift|string this, int count|string|
|slice|string this, int startIndex, int endIndex|string|
|unshift|string this, string value|string|

## Function Descriptions


# StringIterator

## Description

Provides a way to iterate through an array.

## Functions

|Function|Input|Output|
|-|-|-|
|[next](#next)|[StringIterator](#stringiterator) this|bool, string|

## Function Descriptions

<a id="next"></a>
- next ( [StringIterator](#stringiterator) ) ( bool, string )

Advance the iterator to the next element.
Returns `true` while the iterator hasn't reach the end and the current element.