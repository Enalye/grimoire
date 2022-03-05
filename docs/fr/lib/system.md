# system
___
## Description

Basic functions.

## Functions

|Function|Input|Output|
|-|-|-|
|[swap](#swap)|T a, T b|T, T|
|[cond](#cond)|bool check, T a, T b|T|


## Function Descriptions

<a id="swap"></a>
- swap ( T a, T b ) ( T, T )

Swaps around `a` and `b`.
For instance `swap(5, 9)` will return `9` and `5`.
___

<a id="cond"></a>
- cond ( bool check, T a, T b ) ( T )

Returns `a` if `check` is `true` or `b` otherwise.
___