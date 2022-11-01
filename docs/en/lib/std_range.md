# std.range

Functions to iterate on series of numbers.
## Natifs
### RangeIterator\<T>
Iterate on a serie of numbers.
## Opérateurs
|Opérateur|Entrée|Sortie|
|-|-|-|
|->|**int**, **int**|**RangeIterator\<int>**|
|->|**real**, **real**|**RangeIterator\<real>**|
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[next](#func_0)|**RangeIterator\<int>** *iterator*|**int?**|
|[next](#func_1)|**RangeIterator\<real>** *iterator*|**real?**|
|[range](#func_2)|**int** *start*, **int** *end*|**RangeIterator\<int>**|
|[range](#func_3)|**int** *start*, **int** *end*, **int** *step*|**RangeIterator\<int>**|
|[range](#func_4)|**real** *start*, **real** *end*|**RangeIterator\<real>**|
|[range](#func_5)|**real** *start*, **real** *end*, **real** *step*|**RangeIterator\<real>**|


***
## Description des fonctions

<a id="func_0"></a>
> next (**RangeIterator\<int>** *iterator*) (**int?**)

Advance until the next number in the serie.

<a id="func_1"></a>
> next (**RangeIterator\<real>** *iterator*) (**real?**)

Advance until the next number in the serie.

<a id="func_2"></a>
> range (**int** *start*, **int** *end*) (**RangeIterator\<int>**)

Returns an iterator that start from `start` and end with `end` included.

<a id="func_3"></a>
> range (**int** *start*, **int** *end*, **int** *step*) (**RangeIterator\<int>**)

Returns an iterator that start from `start` and end with `end` included by increments of `step`.

<a id="func_4"></a>
> range (**real** *start*, **real** *end*) (**RangeIterator\<real>**)

Returns an iterator that start from `start` and end with `end` included.

<a id="func_5"></a>
> range (**real** *start*, **real** *end*, **real** *step*) (**RangeIterator\<real>**)

Returns an iterator that start from `start` and end with `end` included by increments of `step`.

