# array

Built-in type.

## Description

An array is a list of values of the same type that can be stored together.

## Functions

|Function|Input|Output|
|-|-|-|
|clear|[array](#array)(T) this|[array](#array)(T)|
|copy|[array](#array)(T) this|[array](#array)(T)|
|each|[array](#array)(T) this|[ArrayIterator](#arrayiterator)\<T\>|
|empty?|[array](#array)(T) this|bool|
|fill|[array](#array)(T) this, T value|[array](#array)(T)|
|first|[array](#array)(T) this|T|
|findLast|[array](#array)(T) this, T value|int|
|findFirst|[array](#array)(T) this, T value|int|
|has?|[array](#array)(T) this, T value|bool|
|insert|[array](#array)(T) this, int index, T value|[array](#array)(T)|
|last|[array](#array)(T) this|T|
|pop|[array](#array)(T) this|T|
|pop|[array](#array)(T) this, int count|[array](#array)(T)|
|push|[array](#array)(T) this, T value|[array](#array)(T)|
|size|[array](#array)(T) this|int|
|sort|[array](#array)(T) this|[array](#array)(T)|
|remove|[array](#array)(T) this, int index|[array](#array)(T)|
|remove|[array](#array)(T) this, int startIndex, int endIndex|[array](#array)(T)|
|resize|[array](#array)(T) this|[array](#array)(T)|
|reverse|[array](#array)(T) this|[array](#array)(T)|
|shift|[array](#array)(T) this|T|
|shift|[array](#array)(T) this, int count|[array](#array)(T)|
|slice|[array](#array)(T) this, int startIndex, int endIndex|[array](#array)(T)|
|sliced|[array](#array)(T) this, int startIndex, int endIndex|[array](#array)(T)|
|unshift|[array](#array)(T) this, T value|[array](#array)(T)|

## Function Descriptions

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
