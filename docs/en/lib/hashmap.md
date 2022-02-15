# HashMap

## Description

Dictionary that associates values by keys.

## Functions

|Function|Input|Output|
|-|-|-|
|[HashMap](#hashmap)|[array](/en/lib/array#array)(string) keys, [array](/en/lib/array#array)(T) values|[HashMap](#hashmap)\<T\>|
|[HashMap](#hashmap)|[array](/en/lib/array#array)([Pair](/en/lib/pair#pair)\<[string](/en/lib/string#string), T\>) pairs|[HashMap](#hashmap)\<T\>|
|copy|[HashMap](#hashmap)\<T\> this|[HashMap](#hashmap)\<T\>|
|size|[HashMap](#hashmap)\<T\> this|int|
|empty?|[HashMap](#hashmap)\<T\> this|bool|
|clear|[HashMap](#hashmap)\<T\> this|[HashMap](#hashmap)\<T\>|
|set|[HashMap](#hashmap)\<T\> this, [string](/en/lib/string#string) key, T value||
|get|[HashMap](#hashmap)\<T\> this, [string](/en/lib/string#string) key|T|
|has?|[HashMap](#hashmap)\<T\> this, [string](/en/lib/string#string) key|bool|
|remove|[HashMap](#hashmap)\<T\> this, [string](/en/lib/string#string) key||
|keys|[HashMap](#hashmap)\<T\> this|[array](/en/lib/array#array)([string](/en/lib/string#string))|
|values|[HashMap](#hashmap)\<T\> this|[array](/en/lib/array#array)(T)|
|each|[HashMap](#hashmap)\<T\> this|[HashMapIterator](#hashmapiterator)\<T\>|

## Function Descriptions


# HashMapIterator

## Description

Provides a way to iterate through a hashmap.

## Functions

|Function|Input|Output|
|-|-|-|
|[next](#next)|[HashMapIterator](#hashmapiterator)\<T\> this|bool, T|

## Function Descriptions

<a id="next"></a>
- next ( [HashMapIterator](#hashmapiterator)\<T\> ) ( bool, T )

Advance the iterator to the next element.
Returns `true` while the iterator hasn't reach the end and the current element.