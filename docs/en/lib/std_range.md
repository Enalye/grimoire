# std.range

Functions to iterate on series of numbers.
## Natifs
### RangeIterator\<T>
Iterate on a serie of numbers.
## Opérateurs
|Opérateur|Entrée|Sortie|
|-|-|-|
|->|**int**, **int**|**RangeIterator\<int>**|
|->|**float**, **float**|**RangeIterator\<float>**|
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[next](#func_0)|**RangeIterator\<int>** *iterator*|**int?**|
|[next](#func_1)|**RangeIterator\<float>** *iterator*|**float?**|
|[range](#func_2)|**int** *start*, **int** *end*|**RangeIterator\<int>**|
|[range](#func_3)|**int** *start*, **int** *end*, **int** *step*|**RangeIterator\<int>**|
|[range](#func_4)|**float** *start*, **float** *end*|**RangeIterator\<float>**|
|[range](#func_5)|**float** *start*, **float** *end*, **float** *step*|**RangeIterator\<float>**|


***
## Description des fonctions

<a id="func_0"></a>
> next (**RangeIterator\<int>** *iterator*) (**int?**)

Advance until the next number in the serie.

<a id="func_1"></a>
> next (**RangeIterator\<float>** *iterator*) (**float?**)

Advance until the next number in the serie.

<a id="func_2"></a>
> range (**int** *start*, **int** *end*) (**RangeIterator\<int>**)

Returns an iterator that start from `start` and end with `end` included.

<a id="func_3"></a>
> range (**int** *start*, **int** *end*, **int** *step*) (**RangeIterator\<int>**)

Returns an iterator that start from `start` and end with `end` included by increments of `step`.

<a id="func_4"></a>
> range (**float** *start*, **float** *end*) (**RangeIterator\<float>**)

Returns an iterator that start from `start` and end with `end` included.

<a id="func_5"></a>
> range (**float** *start*, **float** *end*, **float** *step*) (**RangeIterator\<float>**)

Returns an iterator that start from `start` and end with `end` included by increments of `step`.

