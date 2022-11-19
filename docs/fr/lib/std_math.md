# std.math

## Description
Fonctions liées aux maths.
## Variables
|Variable|Type|Valeur|Description|
|-|-|-|-|
|PI|**const float**|3.14159|Rapport entre le diamètre du cercle et sa circonférence.|
## Opérateurs
|Opérateur|Entrée|Sortie|
|-|-|-|
|**|**int**, **int**|**int**|
|**|**float**, **float**|**float**|
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[abs](#func_0)|**float** *x*|**float**|
|[abs](#func_1)|**int** *x*|**int**|
|[acos](#func_2)|**float** *radians*|**float**|
|[approach](#func_3)|**float** *x*, **float** *cible*, **float** *pas*|**float**|
|[approach](#func_4)|**int** *x*, **int** *cible*, **int** *pas*|**int**|
|[asin](#func_5)|**float** *radians*|**float**|
|[atan](#func_6)|**float** *radians*|**float**|
|[atan2](#func_7)|**float** *a*, **float** *b*|**float**|
|[ceil](#func_8)|**float** *x*|**float**|
|[clamp](#func_9)|**int** *x*, **int** *min*, **int** *max*|**int**|
|[clamp](#func_10)|**float** *x*, **float** *min*, **float** *max*|**float**|
|[cos](#func_11)|**float** *radians*|**float**|
|[deg](#func_12)|**float** *radians*|**float**|
|[exp](#func_13)|**float** *x*|**float**|
|[floor](#func_14)|**float** *x*|**float**|
|[isNaN](#func_15)|**float** *x*|**bool**|
|[lerp](#func_16)|**float** *source*, **float** *destination*, **float** *t*|**float**|
|[log](#func_17)|**float** *x*|**float**|
|[log10](#func_18)|**float** *x*|**float**|
|[log2](#func_19)|**float** *x*|**float**|
|[max](#func_20)|**int** *a*, **int** *b*|**int**|
|[max](#func_21)|**float** *a*, **float** *b*|**float**|
|[min](#func_22)|**float** *a*, **float** *b*|**float**|
|[min](#func_23)|**int** *a*, **int** *b*|**int**|
|[rad](#func_24)|**float** *degrés*|**float**|
|[rand](#func_25)|**int** *min*, **int** *max*|**int**|
|[rand](#func_26)||**float**|
|[rand](#func_27)|**float** *min*, **float** *max*|**float**|
|[rlerp](#func_28)|**float** *source*, **float** *destination*, **float** *valeur*|**float**|
|[round](#func_29)|**float** *x*|**float**|
|[sin](#func_30)|**float** *radians*|**float**|
|[sqrt](#func_31)|**float** *x*|**float**|
|[tan](#func_32)|**float** *radians*|**float**|
|[truncate](#func_33)|**float** *x*|**float**|


***
## Description des fonctions

<a id="func_0"></a>
> abs (**float** *x*) (**float**)

Retourne la valeur absolue de `x`.

<a id="func_1"></a>
> abs (**int** *x*) (**int**)

Retourne la valeur absolue de `x`.

<a id="func_2"></a>
> acos (**float** *radians*) (**float**)

Retourne l’arc cosinus de `radians`.

<a id="func_3"></a>
> approach (**float** *x*, **float** *cible*, **float** *pas*) (**float**)

Approche `x` de `cible` par incrément de `pas` sans le dépasser.
Un `pas` négatif l’éloigne de `destination` d’autant.

<a id="func_4"></a>
> approach (**int** *x*, **int** *cible*, **int** *pas*) (**int**)

Approche `x` de `cible` par incrément de `pas` sans le dépasser.
Un `pas` négatif l’éloigne de `destination` d’autant.

<a id="func_5"></a>
> asin (**float** *radians*) (**float**)

Retourne l’arc sinus de `radians`.

<a id="func_6"></a>
> atan (**float** *radians*) (**float**)

Retourne l’arc tangeante de `radians`.

<a id="func_7"></a>
> atan2 (**float** *a*, **float** *b*) (**float**)

Variation d’`atan`.

<a id="func_8"></a>
> ceil (**float** *x*) (**float**)

Retourne l’arrondi de `x` à l’entier supérieur.

<a id="func_9"></a>
> clamp (**int** *x*, **int** *min*, **int** *max*) (**int**)

Restreint `x` entre `min` et `max`.

<a id="func_10"></a>
> clamp (**float** *x*, **float** *min*, **float** *max*) (**float**)

Restreint `x` entre `min` et `max`.

<a id="func_11"></a>
> cos (**float** *radians*) (**float**)

Retourne le cosinus de `radians`.

<a id="func_12"></a>
> deg (**float** *radians*) (**float**)

Convertit `radians` en degrés .

<a id="func_13"></a>
> exp (**float** *x*) (**float**)

Retourne l’exponentielle de `x`.

<a id="func_14"></a>
> floor (**float** *x*) (**float**)

Retourne l’arrondi de `x` à l’entier inférieur.

<a id="func_15"></a>
> isNaN (**float** *x*) (**bool**)

Vérifie si le `x` est un réel valide ou non.

<a id="func_16"></a>
> lerp (**float** *source*, **float** *destination*, **float** *t*) (**float**)

Interpole entre `source` et `destination` en fonction de `t` compris entre 0 et 1.

<a id="func_17"></a>
> log (**float** *x*) (**float**)

Renvoie le logarithme naturel de `x`.

<a id="func_18"></a>
> log10 (**float** *x*) (**float**)

Renvoie le logarithme en base 10 de `x`.

<a id="func_19"></a>
> log2 (**float** *x*) (**float**)

Renvoie le logarithme en base 2 de `x`.

<a id="func_20"></a>
> max (**int** *a*, **int** *b*) (**int**)

Renvoie la plus grande valeur entre `a` et `b`.

<a id="func_21"></a>
> max (**float** *a*, **float** *b*) (**float**)

Renvoie la plus grande valeur entre `a` et `b`.

<a id="func_22"></a>
> min (**float** *a*, **float** *b*) (**float**)

Renvoie la plus petite valeur entre `a` et `b`.

<a id="func_23"></a>
> min (**int** *a*, **int** *b*) (**int**)

Renvoie la plus petite valeur entre `a` et `b`.

<a id="func_24"></a>
> rad (**float** *degrés*) (**float**)

Convertit `degrés`  en radians.

<a id="func_25"></a>
> rand (**int** *min*, **int** *max*) (**int**)

Retourne une valeur aléatoire comprise entre `min` et `max` inclus.

<a id="func_26"></a>
> rand (**float**)

Retourne une valeur aléatoire comprise entre 0 et 1 exclus.

<a id="func_27"></a>
> rand (**float** *min*, **float** *max*) (**float**)

Retourne une valeur aléatoire comprise entre `min` et `max` inclus.

<a id="func_28"></a>
> rlerp (**float** *source*, **float** *destination*, **float** *valeur*) (**float**)

Opération inverse de lerp.
Retourne le ratio entre 0 et 1 de `valeur` par rapport à `source` et `destination`

<a id="func_29"></a>
> round (**float** *x*) (**float**)

Retourne l’arrondi de `x` à l’entier le plus proche.

<a id="func_30"></a>
> sin (**float** *radians*) (**float**)

Retourne le sinus de `radians`.

<a id="func_31"></a>
> sqrt (**float** *x*) (**float**)

Renvoie la racine carré de `x`.

<a id="func_32"></a>
> tan (**float** *radians*) (**float**)

Retourne la tangeante de `radians`.

<a id="func_33"></a>
> truncate (**float** *x*) (**float**)

Retourne la partie entière de `x`.

