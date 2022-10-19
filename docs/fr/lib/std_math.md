# math

Fonctions liées aux maths.

## Constantes

|Constante|Type|
|-|-|
|PI|**const real**|

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[abs](#abs_i)|**int** *valeur*|**real**|
|[abs](#abs_r)|**real** *valeur*|**real**|
|[acos](#acos)|**real** *valeur*|**real**|
|[approach](#approach_i)|**int** *valeur*, **int** *destination*, **int** *pas*|**int**|
|[approach](#approach_r)|**real** *valeur*, **real** *destination*, **real** *pas*|**real**|
|[asin](#asin)|**real** *valeur*|**real**|
|[atan](#atan)|**real** *valeur*|**real**|
|[atan2](#atan2)|**real** *a*, **real** *b*|**real**|
|[ceil](#ceil)|**real** *valeur*|**real**|
|[clamp](#clamp_i)|**int** *valeur*, **int** *min*, **int** *max*|**int**|
|[clamp](#clamp_r)|**real** *valeur*, **real** *min*, **real** *max*|**real**|
|[cos](#cos)|**real** *valeur*|**real**|
|[deg](#deg)|**real** *radians*|**real**|
|[exp](#exp)|**real** *valeur*|**real**|
|[floor](#floor)|**real** *valeur*|**real**|
|[isNaN](#isNaN)|**real** *valeur*|**bool**|
|[lerp](#lerp)|**real** *source*, **real** *destination*, **real** *t*|**real**|
|[log](#log)|**real** *valeur*|**real**|
|[log2](#log2)|**real** *valeur*|**real**|
|[log10](#log10)|**real** *valeur*|**real**|
|[max](#max_i)|**int** *a*, **int** *b*|**int**|
|[max](#max_r)|**real** *a*, **real** *b*|**real**|
|[min](#min_i)|**int** *a*, **int** *b*|**int**|
|[min](#min_r)|**real** *a*, **real** *b*|**real**|
|[rad](#rad)|**real** *degrés*|**real**|
|[rlerp](#rlerp)|**real** *min*, **real** *max*, **real** *valeur*|**real**|
|[round](#round)|**real** *valeur*|**real**|
|[rand](#rand_01)||**real**|
|[rand](#rand_i)|**int** *min*, **int** *max*|**int**|
|[rand](#rand_r)|**real** *min*, **real** *max*|**real**|
|[sin](#sin)|**real** *valeur*|**real**|
|[sqrt](#sqrt)|**real** *valeur*|**real**|
|[tan](#tan)|**real** *valeur*|**real**|
|[truncate](#truncate)|**real** *valeur*|**real**|

## Opérateurs

|Operateur|Entrée|Sortie|
|-|-|-|
|\*\*|**int** *valeur*, **int** *exposant*|**int**|
|\*\*|**real** *valeur*, **real** *exposant*|**real**|

---

## Description des fonctions

<a id="abs_i"></a>
- abs(**int** *valeur*) (**int**)

Retourne la valeur positive de `valeur`.
___

<a id="abs_r"></a>
- abs(**real** *valeur*) (**real**)

Retourne la valeur positive de `valeur`.
___

<a id="acos"></a>
- acos(**real** *valeur*) (**real**)

Retourne l’arc cosinus de `valeur` exprimé en radians.
___

<a id="approach_i"></a>
- approach(**int** *valeur*, **int** *destination*, **int** *pas*) (**real**)

Approche `valeur` de `destination` par incrément de `pas` sans le dépasser. Un `pas` négatif l’éloigne de `destination` d’autant.
___

<a id="approach_r"></a>
- approach(**real** *valeur*, **real** *destination*, **real** *pas*) (**real**)

Approche `valeur` de `destination` par incrément de `pas` sans le dépasser. Un `pas` négatif l’éloigne de `destination` d’autant.
___

<a id="asin"></a>
- asin(**real** *valeur*) (**real**)

Retourne l’arc sinus de `valeur` exprimé en radians.
___

<a id="atan"></a>
- atan(**real** *valeur*) (**real**)

Retourne l’arc tangente de `valeur` exprimé en radians.
___

<a id="atan2"></a>
- atan2(**real** *y*, **real** *x*) (**real**)

La suite de atan, mais l’original est mieux.
___

<a id="ceil"></a>
- ceil(**real** *valeur*) (**real**)

Retourne l’arrondi de `valeur` à l’entier le plus éloigné de 0.
___

<a id="clamp_i"></a>
- clamp(**int** *valeur*, **int** *min*, **int** *max*) (**int**)

Restreint `valeur` entre `min` et `max`.
___

<a id="clamp_r"></a>
- clamp(**real** *valeur*, **real** *min*, **real** *max*) (**real**)

Restreint `valeur` entre `min` et `max`.
___

<a id="cos"></a>
- cos(**real** *valeur*) (**real**)

Retourne le cosinus de `valeur` exprimé en radians.
___

<a id="deg"></a>
- deg(**real** *radians*) (**real**)

Convertit en degrés `radians` exprimé en radians.
___

<a id="floor"></a>
- floor(**real** *valeur*) (**real**)

Retourne l’arrondi de `valeur` à l’entier le plus proche de 0.
___

<a id="isNaN"></a>
- isNaN(**real** *valeur*) (**bool**)

Vérifie si le `valeur` est un réel valide ou non.
___

<a id="lerp"></a>
- lerp(**real** *source*,**real** *destination*, **real** *t*) (**real**)

Interpole entre `source` et `destination` en fonction de `t` compris entre 0 et 1.
___

<a id="log"></a>
- log(**real** *valeur*) (**real**)

Renvoie le logarithme naturel de `valeur`.
___

<a id="log2"></a>
- log2(**real** *valeur*) (**real**)

Renvoie le logarithme en base 2 de `valeur`.
___

<a id="log10"></a>
- log10(**real** *valeur*) (**real**)

Renvoie le logarithme en base 10 de `valeur`.
___

<a id="max_i"></a>
- max(**int** *a*, **int** b) (**int**)

Renvoie la plus grande valeur entre `a` et `b`.
___

<a id="max_r"></a>
- max(**real** *a*, **real** b) (**real**)

Renvoie la plus grande valeur entre `a` et `b`.
___

<a id="min_i"></a>
- min(**int** *a*, **int** b) (**int**)

Renvoie la plus petite valeur entre `a` et `b`.
___

<a id="min_r"></a>
- min(**real** *a*, **real** b) (**real**)

Renvoie la plus petite valeur entre `a` et `b`.
___

<a id="rad"></a>
- rad(**real** *degrés*) (**real**)

Convertit en radians `degrés` exprimé en degrés.
___

<a id="rlerp"></a>
- rlerp(**real** *min*,**real** *max*, **real** *valeur*) (**real**)

Opération inverse de [lerp](#lerp).
Retourne le ratio entre 0 et 1 de `valeur` par rapport à `min` et `max`.
___

<a id="round"></a>
- round(**real** *valeur*) (**real**)

Retourne l’arrondi de `valeur`.
___

<a id="rand_01"></a>
- rand() (**real**)

Retourne une valeur aléatoire comprise entre 0 et 1 exclus.
___

<a id="rand_i"></a>
- rand(**int** *min*, **int** *max*) (**int**)

Retourne une valeur aléatoire comprise entre `min` et `max` inclus.
___

<a id="rand_r"></a>
- rand(**real** *min*, **real** *max*) (**real**)

Retourne une valeur aléatoire comprise entre `min` et `max` inclus.
___

<a id="sin"></a>
- sin(**real** *valeur*) (**real**)

Retourne le sinus de `valeur` exprimé en radians.
___

<a id="sqrt"></a>
- sqrt(**real** *valeur*) (**real**)

Retourne la racine carré de `valeur`.
___

<a id="tan"></a>
- tan(**real** *valeur*) (**real**)

Retourne la tangente de `valeur` exprimé en radians.
___

<a id="truncate"></a>
- truncate(**real** *valeur*) (**real**)

Retourne la partie entière de `valeur`.
___