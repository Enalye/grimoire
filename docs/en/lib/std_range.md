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
|[next](#func_0)|*iterator*: **RangeIterator\<int>**|**int?**|
|[next](#func_1)|*iterator*: **RangeIterator\<float>**|**float?**|
|[range](#func_2)|*start*: **int**, *end*: **int**|**RangeIterator\<int>**|
|[range](#func_3)|*start*: **int**, *end*: **int**, *step*: **int**|**RangeIterator\<int>**|
|[range](#func_4)|*start*: **float**, *end*: **float**|**RangeIterator\<float>**|
|[range](#func_5)|*start*: **float**, *end*: **float**, *step*: **float**|**RangeIterator\<float>**|


***
## Description des fonctions

<a id="func_0"></a>
> next (*iterator*: **RangeIterator\<int>**) (**int?**)

Advance until the next number in the serie.

<a id="func_1"></a>
> next (*iterator*: **RangeIterator\<float>**) (**float?**)

Advance until the next number in the serie.

<a id="func_2"></a>
> range (*start*: **int**, *end*: **int**) (**RangeIterator\<int>**)

Returns an iterator that start from `start` and end with `end` included.

<a id="func_3"></a>
> range (*start*: **int**, *end*: **int**, *step*: **int**) (**RangeIterator\<int>**)

Returns an iterator that start from `start` and end with `end` included by increments of `step`.

<a id="func_4"></a>
> range (*start*: **float**, *end*: **float**) (**RangeIterator\<float>**)

Returns an iterator that start from `start` and end with `end` included.

<a id="func_5"></a>
> range (*start*: **float**, *end*: **float**, *step*: **float**) (**RangeIterator\<float>**)

Returns an iterator that start from `start` and end with `end` included by increments of `step`.

