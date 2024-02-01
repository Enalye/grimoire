# range

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
|[range](#func_2)|*start*: **int**, *end*: **int**|**RangeIterator\<int>**|
|[range](#func_3)|*start*: **int**, *end*: **int**, *step*: **int**|**RangeIterator\<int>**|
|[range](#func_4)|*start*: **float**, *end*: **float**|**RangeIterator\<float>**|
|[range](#func_5)|*start*: **float**, *end*: **float**, *step*: **float**|**RangeIterator\<float>**|


***
## Description des fonctions

<a id="func_0"></a>
> next (*itérateur*: **RangeIterator\<int>**) (**int?**)

Avance jusqu’au nombre suivant de la série.

<a id="func_1"></a>
> next (*itérateur*: **RangeIterator\<float>**) (**float?**)

Avance jusqu’au nombre suivant de la série.

<a id="func_2"></a>
> range (*start*: **int**, *end*: **int**) (**RangeIterator\<int>**)

Retourne un itérateur qui part de `start` jusqu’à `end` inclus.

<a id="func_3"></a>
> range (*start*: **int**, *end*: **int**, *step*: **int**) (**RangeIterator\<int>**)

Retourne un itérateur qui part de `start` jusqu’à `end` inclus par pas de `step`.

<a id="func_4"></a>
> range (*start*: **float**, *end*: **float**) (**RangeIterator\<float>**)

Retourne un itérateur qui part de `start` jusqu’à `end` inclus.

<a id="func_5"></a>
> range (*start*: **float**, *end*: **float**, *step*: **float**) (**RangeIterator\<float>**)

Retourne un itérateur qui part de `start` jusqu’à `end` inclus par pas de `step`.

