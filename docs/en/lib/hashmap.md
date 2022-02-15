<a id="hashmap"></a>
# HashMap\<T\>
## Description

Dictionary that associates values by keys.

## Functions

|Function|Input|Output|
|-|-|-|
|[HashMap](#hashmap_1)|[array](/en/lib/array#array)(string) keys, [array](/en/lib/array#array)(T) values|[HashMap](#hashmap)\<T\>|
|[HashMap](#hashmap_2)|[array](/en/lib/array#array)([Pair](/en/lib/pair#pair)\<[string](/en/lib/string#string), T\>) pairs|[HashMap](#hashmap)\<T\>|
|[copy](#copy)|[HashMap](#hashmap)\<T\> this|[HashMap](#hashmap)\<T\>|
|[size](#size)|[HashMap](#hashmap)\<T\> this|int|
|[empty?](#empty)|[HashMap](#hashmap)\<T\> this|bool|
|[clear](#clear)|[HashMap](#hashmap)\<T\> this|[HashMap](#hashmap)\<T\>|
|[set](#set)|[HashMap](#hashmap)\<T\> this, [string](/en/lib/string#string) key, T value||
|[get](#get)|[HashMap](#hashmap)\<T\> this, [string](/en/lib/string#string) key|T|
|[has?](#has)|[HashMap](#hashmap)\<T\> this, [string](/en/lib/string#string) key|bool|
|[remove](#remove)|[HashMap](#hashmap)\<T\> this, [string](/en/lib/string#string) key||
|[keys](#keys)|[HashMap](#hashmap)\<T\> this|[array](/en/lib/array#array)([string](/en/lib/string#string))|
|[values](#values)|[HashMap](#hashmap)\<T\> this|[array](/en/lib/array#array)(T)|
|[each](#each)|[HashMap](#hashmap)\<T\> this|[HashMapIterator](#hashmapiterator)\<T\>|

## Function Descriptions

<a id="hashmap_1"></a>
- HashMap ( [array](/en/lib/array#array)(string) keys, [array](/en/lib/array#array)(T) values ) ( [HashMap](#hashmap)\<T\> )

Returns a new HashMap by associating each key with its corresponding value.
`keys` and `values` sizes must match.
___

<a id="hashmap_2"></a>
- HashMap ( [array](/en/lib/array#array)([Pair](/en/lib/pair#pair)\<[string](/en/lib/string#string), T\>) pairs ) ( [HashMap](#hashmap)\<T\> )

Returns a new HashMap with `pairs`.
___

<a id="copy"></a>
- copy ( [HashMap](#hashmap)\<T\> this ) ( [HashMap](#hashmap)\<T\> )

Returns a copy of the HashMap.
___

<a id="size"></a>
- size ( [HashMap](#hashmap)\<T\> this ) ( int )

Returns the number of elements in the HashMap.
___

<a id="empty"></a>
- empty? ( [HashMap](#hashmap)\<T\> this ) ( bool )

Returns `true` if the HashMap has no item.
___

<a id="clear"></a>
- clear ( [HashMap](#hashmap)\<T\> this ) ( [HashMap](#hashmap)\<T\> )

Empty the HashMap.
___

<a id="set"></a>
- set ( [HashMap](#hashmap)\<T\> this, [string](/en/lib/string#string) key, T value ) ( [HashMap](#hashmap)\<T\> )

Adds the specified `key` and `value` to the HashMap.
___

<a id="get"></a>
- get ( [HashMap](#hashmap)\<T\> this, [string](/en/lib/string#string) key ) ( T )

Returns the value associated with the specified `key`.
___

<a id="has"></a>
- has? ( [HashMap](#hashmap)\<T\> this, [string](/en/lib/string#string) key ) ( bool )

Returns `true` if the `key` exists inside the HashMap.
___

<a id="remove"></a>
- remove ( [HashMap](#hashmap)\<T\> this, [string](/en/lib/string#string) key ) ( [HashMap](#hashmap)\<T\> )

Delete the entry `key`.
___

<a id="keys"></a>
- keys ( [HashMap](#hashmap)\<T\> this ) ( [array](/en/lib/array#array)([string](/en/lib/string#string)) )

Returns the list of all keys.
___

<a id="values"></a>
- values ( [HashMap](#hashmap)\<T\> this ) ( [array](/en/lib/array#array)(T) )

Returns the list of all values.
___

<a id="each"></a>
- each ( [HashMap](#hashmap)\<T\> this ) ( [HashMapIterator](#hashmapiterator)\<T\> )

Returns an iterator that iterate through each key/value pairs.
___

<a id="hashmapiterator"></a>
# HashMapIterator\<T\>
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