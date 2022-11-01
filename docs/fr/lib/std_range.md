# std.range

Fonctions pour itérer sur des séries de nombres.
## Natifs
### RangeIterator\<T>
Itère sur une série de nombres.
## Opérateurs
|Opérateur|Entrée|Sortie|
|-|-|-|
|->|**int**, **int**|**RangeIterator\<int>**|
|->|**real**, **real**|**RangeIterator\<real>**|
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[next](#func_0)|**RangeIterator\<int>** *itérateur*|**int?**|
|[next](#func_1)|**RangeIterator\<real>** *itérateur*|**real?**|
|[range](#func_2)|**int** *début*, **int** *fin*|**RangeIterator\<int>**|
|[range](#func_3)|**int** *début*, **int** *fin*, **int** *pas*|**RangeIterator\<int>**|
|[range](#func_4)|**real** *début*, **real** *fin*|**RangeIterator\<real>**|
|[range](#func_5)|**real** *début*, **real** *fin*, **real** *pas*|**RangeIterator\<real>**|


***
## Description des fonctions

<a id="func_0"></a>
> next (**RangeIterator\<int>** *itérateur*) (**int?**)

Avance jusqu’au nombre suivant de la série.

<a id="func_1"></a>
> next (**RangeIterator\<real>** *itérateur*) (**real?**)

Avance jusqu’au nombre suivant de la série.

<a id="func_2"></a>
> range (**int** *début*, **int** *fin*) (**RangeIterator\<int>**)

Retourne un itérateur qui part de `début` jusqu’à `fin` inclus.

<a id="func_3"></a>
> range (**int** *début*, **int** *fin*, **int** *pas*) (**RangeIterator\<int>**)

Retourne un itérateur qui part de `début` jusqu’à `fin` inclus par incréments de `pas`.

<a id="func_4"></a>
> range (**real** *début*, **real** *fin*) (**RangeIterator\<real>**)

Retourne un itérateur qui part de `début` jusqu’à `fin` inclus.

<a id="func_5"></a>
> range (**real** *début*, **real** *fin*, **real** *pas*) (**RangeIterator\<real>**)

Retourne un itérateur qui part de `début` jusqu’à `fin` inclus par incréments de `pas`.

