# std.range

Fonctions pour itérer sur des séries de nombres.
## Natifs
### RangeIterator\<T>
Itère sur une série de nombres.
## Opérateurs
|Opérateur|Entrée|Sortie|
|-|-|-|
|->|**int**, **int**|**RangeIterator\<int>**|
|->|**float**, **float**|**RangeIterator\<float>**|
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[next](#func_0)|**RangeIterator\<int>** *itérateur*|**int?**|
|[next](#func_1)|**RangeIterator\<float>** *itérateur*|**float?**|
|[range](#func_2)|**int** *début*, **int** *fin*|**RangeIterator\<int>**|
|[range](#func_3)|**int** *début*, **int** *fin*, **int** *pas*|**RangeIterator\<int>**|
|[range](#func_4)|**float** *début*, **float** *fin*|**RangeIterator\<float>**|
|[range](#func_5)|**float** *début*, **float** *fin*, **float** *pas*|**RangeIterator\<float>**|


***
## Description des fonctions

<a id="func_0"></a>
> next (**RangeIterator\<int>** *itérateur*) (**int?**)

Avance jusqu’au nombre suivant de la série.

<a id="func_1"></a>
> next (**RangeIterator\<float>** *itérateur*) (**float?**)

Avance jusqu’au nombre suivant de la série.

<a id="func_2"></a>
> range (**int** *début*, **int** *fin*) (**RangeIterator\<int>**)

Retourne un itérateur qui part de `début` jusqu’à `fin` inclus.

<a id="func_3"></a>
> range (**int** *début*, **int** *fin*, **int** *pas*) (**RangeIterator\<int>**)

Retourne un itérateur qui part de `début` jusqu’à `fin` inclus par incréments de `pas`.

<a id="func_4"></a>
> range (**float** *début*, **float** *fin*) (**RangeIterator\<float>**)

Retourne un itérateur qui part de `début` jusqu’à `fin` inclus.

<a id="func_5"></a>
> range (**float** *début*, **float** *fin*, **float** *pas*) (**RangeIterator\<float>**)

Retourne un itérateur qui part de `début` jusqu’à `fin` inclus par incréments de `pas`.

