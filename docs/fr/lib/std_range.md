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
|[next](#func_0)|*itérateur*: **RangeIterator\<int>**|**int?**|
|[next](#func_1)|*itérateur*: **RangeIterator\<float>**|**float?**|
|[range](#func_2)|*début*: **int**, *fin*: **int**|**RangeIterator\<int>**|
|[range](#func_3)|*début*: **int**, *fin*: **int**, *pas*: **int**|**RangeIterator\<int>**|
|[range](#func_4)|*début*: **float**, *fin*: **float**|**RangeIterator\<float>**|
|[range](#func_5)|*début*: **float**, *fin*: **float**, *pas*: **float**|**RangeIterator\<float>**|


***
## Description des fonctions

<a id="func_0"></a>
> next (*itérateur*: **RangeIterator\<int>**) (**int?**)

Avance jusqu’au nombre suivant de la série.

<a id="func_1"></a>
> next (*itérateur*: **RangeIterator\<float>**) (**float?**)

Avance jusqu’au nombre suivant de la série.

<a id="func_2"></a>
> range (*début*: **int**, *fin*: **int**) (**RangeIterator\<int>**)

Retourne un itérateur qui part de `début` jusqu’à `fin` inclus.

<a id="func_3"></a>
> range (*début*: **int**, *fin*: **int**, *pas*: **int**) (**RangeIterator\<int>**)

Retourne un itérateur qui part de `début` jusqu’à `fin` inclus par incréments de `pas`.

<a id="func_4"></a>
> range (*début*: **float**, *fin*: **float**) (**RangeIterator\<float>**)

Retourne un itérateur qui part de `début` jusqu’à `fin` inclus.

<a id="func_5"></a>
> range (*début*: **float**, *fin*: **float**, *pas*: **float**) (**RangeIterator\<float>**)

Retourne un itérateur qui part de `début` jusqu’à `fin` inclus par incréments de `pas`.

