# range

## Description


## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[range](#range_i2)|int from, int to|[RangeIterator](#rangeiterator)\<int\>|
|[range](#range_r2)|real from, real to|[RangeIterator](#rangeiterator)\<real\>|
|[range](#range_i3)|int from, int to, int step|[RangeIterator](#rangeiterator)\<int\>|
|[range](#range_r3)|real from, real to, real step|[RangeIterator](#rangeiterator)\<real\>|

## Description des fonctions

<a id="range_i2"></a>
- range ( int from, int to ) ( [RangeIterator](#rangeiterator)\<int\> )

Returns a new iterator that yields values between `from` and `to` included with an increment of `1`.
___

<a id="range_r2"></a>
- range ( real from, real to ) ( [RangeIterator](#rangeiterator)\<real\> )

Returns a new iterator that yields values between `from` and `to` included with an increment of `1.0`.
___

<a id="range_i3"></a>
- range ( int from, int to, int step ) ( [RangeIterator](#rangeiterator)\<int\> )

Returns a new iterator that yields values between `from` and `to` included with an increment of `step`.
___

<a id="range_r3"></a>
- range ( real from, real to, real step ) ( [RangeIterator](#rangeiterator)\<real\> )

Returns a new iterator that yields values between `from` and `to` included with an increment of `step`.
___

# RangeIterator

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[next](#next_i)|[RangeIterator](#rangeiterator)\<int\> this|bool, int|
|[next](#next_r)|[RangeIterator](#rangeiterator)\<real\> this|bool, real|

## Description des fonctions

<a id="next_i"></a>
- next ( [RangeIterator](#rangeiterator)\<int\> ) ( bool, T )

Advance the iterator to the next element.
Returns `true` while the iterator hasn't reach the end and the current element.
___

<a id="next_r"></a>
- next ( [RangeIterator](#rangeiterator)\<real\> ) ( bool, T )

Advance the iterator to the next element.
Returns `true` while the iterator hasn't reach the end and the current element.