# std.circularbuffer

## Natifs
### CircularBuffer\<T>
### CircularBufferIterator\<T>
Iterate on a circular buffer.
## Constructeurs
|Fonction|Entrée|
|-|-|
|[@**CircularBuffer\<T>**](#ctor_0)|**int** *param0*|
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[back](#func_0)|*buffer*: **pure CircularBuffer\<T>**|**T?**|
|[capacity](#func_1)|*buffer*: **pure CircularBuffer\<T>**|**int**|
|[front](#func_2)|*buffer*: **pure CircularBuffer\<T>**|**T?**|
|[isEmpty](#func_3)|*buffer*: **pure CircularBuffer\<T>**|**bool**|
|[isFull](#func_4)|*buffer*: **pure CircularBuffer\<T>**|**bool**|
|[pop](#func_5)|*buffer*: **CircularBuffer\<T>**|**T?**|
|[push](#func_6)|*buffer*: **CircularBuffer\<T>**, *value*: **T**||
|[size](#func_7)|*buffer*: **pure CircularBuffer\<T>**|**int**|


***
## Description des fonctions

<a id="func_0"></a>
> back (*buffer*: **pure CircularBuffer\<T>**) (**T?**)

Returns the last element of `buffer`.
If it doesn't exist, returns `null(T)`.

<a id="func_1"></a>
> capacity (*buffer*: **pure CircularBuffer\<T>**) (**int**)

Returns the `buffer`'s capacity.

<a id="func_2"></a>
> front (*buffer*: **pure CircularBuffer\<T>**) (**T?**)

Returns the first element of `buffer`.
If it doesn't exist, returns `null(T)`.

<a id="func_3"></a>
> isEmpty (*buffer*: **pure CircularBuffer\<T>**) (**bool**)

Returns `true` if `buffer` contains nothing.

<a id="func_4"></a>
> isFull (*buffer*: **pure CircularBuffer\<T>**) (**bool**)

Returns `true` if `buffer` is full.

<a id="func_5"></a>
> pop (*buffer*: **CircularBuffer\<T>**) (**T?**)

Removes an element of the `buffer` and returns it.
If there aren't any, returns `null(T)`.

<a id="func_6"></a>
> push (*buffer*: **CircularBuffer\<T>**, *value*: **T**)

Appends `value` to the `buffer`.

<a id="func_7"></a>
> size (*buffer*: **pure CircularBuffer\<T>**) (**int**)

Returns the `buffer`'s size.

