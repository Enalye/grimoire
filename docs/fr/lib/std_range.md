# range

## Description


## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[range](#range_i2)|**int** *début*, **int** *fin*|**[RangeIterator](#rangeiterator)\<int\>**|
|[range](#range_r2)|**real** *début*, **real** *fin*|**[RangeIterator](#rangeiterator)\<real\>**|
|[range](#range_i3)|**int** *début*, **int** *fin*, **int** *pas*|**[RangeIterator](#rangeiterator)\<int\>**|
|[range](#range_r3)|**real** *début*, **real** *fin*, **real** *pas*|**[RangeIterator](#rangeiterator)\<real\>**|

## Description des fonctions

<a id="range_i2"></a>
- range (**int** *début*, **int** *fin*) (**[RangeIterator](#rangeiterator)\<int\>**)

Returne un itérateur qui renvoie des valeurs comprises entre `début` et `fin` inclus par incréments de `1`.
___

<a id="range_r2"></a>
- range (**real** *début*, **real** *fin*) (**[RangeIterator](#rangeiterator)\<real\>**)

Returne un itérateur qui renvoie des valeurs comprises entre `début` et `fin` inclus par incréments de `1.0`.
___

<a id="range_i3"></a>
- range (**int** *début*, **int** *fin*, **int** *pas*) (**[RangeIterator](#rangeiterator)\<int\>**)

Returne un itérateur qui renvoie des valeurs comprises entre `début` et `fin` inclus par incréments de `pas`.
___

<a id="range_r3"></a>
- range (**real** *début*, **real** *fin*, **real** *pas*) (**[RangeIterator](#rangeiterator)\<real\>**)

Returne un itérateur qui renvoie des valeurs comprises entre `début` et `fin` inclus par incréments de `pas`.
___

# RangeIterator

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[next](#next_i)|**[RangeIterator](#rangeiterator)\<int\>** *itérateur*|**int?**|
|[next](#next_r)|**[RangeIterator](#rangeiterator)\<real\>** *itérateur*|**real?**|

## Description des fonctions

<a id="next_i"></a>
- next (**[RangeIterator](#rangeiterator)\<int\>**) (**T?**)

Avance l’itérateur jusqu’au prochain élément.
___

<a id="next_r"></a>
- next (**[RangeIterator](#rangeiterator)\<real\>**) (**T?**)

Avance l’itérateur jusqu’au prochain élément.