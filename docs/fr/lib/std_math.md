# std.math

## Description
Fonctions liées aux maths.
## Variables
|Variable|Type|Valeur|Description|
|-|-|-|-|
|PI|**float**|3.14159|Rapport entre le diamètre du cercle et sa circonférence.|
## Opérateurs
|Opérateur|Entrée|Sortie|
|-|-|-|
|**|**int**, **int**|**int**|
|**|**float**, **float**|**float**|
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[abs](#func_0)|*x*: **float**|**float**|
|[abs](#func_1)|*x*: **int**|**int**|
|[acos](#func_2)|*radians*: **float**|**float**|
|[approach](#func_3)|*x*: **float**, *cible*: **float**, *pas*: **float**|**float**|
|[approach](#func_4)|*x*: **int**, *cible*: **int**, *pas*: **int**|**int**|
|[asin](#func_5)|*radians*: **float**|**float**|
|[atan](#func_6)|*radians*: **float**|**float**|
|[atan2](#func_7)|*a*: **float**, *b*: **float**|**float**|
|[ceil](#func_8)|*x*: **float**|**float**|
|[clamp](#func_9)|*x*: **int**, *min*: **int**, *max*: **int**|**int**|
|[clamp](#func_10)|*x*: **float**, *min*: **float**, *max*: **float**|**float**|
|[cos](#func_11)|*radians*: **float**|**float**|
|[deg](#func_12)|*radians*: **float**|**float**|
|[exp](#func_13)|*x*: **float**|**float**|
|[floor](#func_14)|*x*: **float**|**float**|
|[isNaN](#func_15)|*x*: **float**|**bool**|
|[lerp](#func_16)|*source*: **float**, *destination*: **float**, *t*: **float**|**float**|
|[log](#func_17)|*x*: **float**|**float**|
|[log10](#func_18)|*x*: **float**|**float**|
|[log2](#func_19)|*x*: **float**|**float**|
|[max](#func_20)|*a*: **int**, *b*: **int**|**int**|
|[max](#func_21)|*a*: **float**, *b*: **float**|**float**|
|[min](#func_22)|*a*: **float**, *b*: **float**|**float**|
|[min](#func_23)|*a*: **int**, *b*: **int**|**int**|
|[rad](#func_24)|*degrés*: **float**|**float**|
|[rand](#func_25)|*min*: **int**, *max*: **int**|**int**|
|[rand](#func_26)||**float**|
|[rand](#func_27)|*min*: **float**, *max*: **float**|**float**|
|[rlerp](#func_28)|*source*: **float**, *destination*: **float**, *valeur*: **float**|**float**|
|[round](#func_29)|*x*: **float**|**float**|
|[sin](#func_30)|*radians*: **float**|**float**|
|[sqrt](#func_31)|*x*: **float**|**float**|
|[tan](#func_32)|*radians*: **float**|**float**|
|[truncate](#func_33)|*x*: **float**|**float**|


***
## Description des fonctions

<a id="func_0"></a>
> abs (*x*: **float**) (**float**)

Retourne la valeur absolue de `x`.

<a id="func_1"></a>
> abs (*x*: **int**) (**int**)

Retourne la valeur absolue de `x`.

<a id="func_2"></a>
> acos (*radians*: **float**) (**float**)

Retourne l’arc cosinus de `radians`.

<a id="func_3"></a>
> approach (*x*: **float**, *cible*: **float**, *pas*: **float**) (**float**)

Approche `x` de `cible` par incrément de `pas` sans le dépasser.
Un `pas` négatif l’éloigne de `destination` d’autant.

<a id="func_4"></a>
> approach (*x*: **int**, *cible*: **int**, *pas*: **int**) (**int**)

Approche `x` de `cible` par incrément de `pas` sans le dépasser.
Un `pas` négatif l’éloigne de `destination` d’autant.

<a id="func_5"></a>
> asin (*radians*: **float**) (**float**)

Retourne l’arc sinus de `radians`.

<a id="func_6"></a>
> atan (*radians*: **float**) (**float**)

Retourne l’arc tangeante de `radians`.

<a id="func_7"></a>
> atan2 (*a*: **float**, *b*: **float**) (**float**)

Variation d’`atan`.

<a id="func_8"></a>
> ceil (*x*: **float**) (**float**)

Retourne l’arrondi de `x` à l’entier supérieur.

<a id="func_9"></a>
> clamp (*x*: **int**, *min*: **int**, *max*: **int**) (**int**)

Restreint `x` entre `min` et `max`.

<a id="func_10"></a>
> clamp (*x*: **float**, *min*: **float**, *max*: **float**) (**float**)

Restreint `x` entre `min` et `max`.

<a id="func_11"></a>
> cos (*radians*: **float**) (**float**)

Retourne le cosinus de `radians`.

<a id="func_12"></a>
> deg (*radians*: **float**) (**float**)

Convertit `radians` en degrés .

<a id="func_13"></a>
> exp (*x*: **float**) (**float**)

Retourne l’exponentielle de `x`.

<a id="func_14"></a>
> floor (*x*: **float**) (**float**)

Retourne l’arrondi de `x` à l’entier inférieur.

<a id="func_15"></a>
> isNaN (*x*: **float**) (**bool**)

Vérifie si le `x` est un réel valide ou non.

<a id="func_16"></a>
> lerp (*source*: **float**, *destination*: **float**, *t*: **float**) (**float**)

Interpole entre `source` et `destination` en fonction de `t` compris entre 0 et 1.

<a id="func_17"></a>
> log (*x*: **float**) (**float**)

Renvoie le logarithme naturel de `x`.

<a id="func_18"></a>
> log10 (*x*: **float**) (**float**)

Renvoie le logarithme en base 10 de `x`.

<a id="func_19"></a>
> log2 (*x*: **float**) (**float**)

Renvoie le logarithme en base 2 de `x`.

<a id="func_20"></a>
> max (*a*: **int**, *b*: **int**) (**int**)

Renvoie la plus grande valeur entre `a` et `b`.

<a id="func_21"></a>
> max (*a*: **float**, *b*: **float**) (**float**)

Renvoie la plus grande valeur entre `a` et `b`.

<a id="func_22"></a>
> min (*a*: **float**, *b*: **float**) (**float**)

Renvoie la plus petite valeur entre `a` et `b`.

<a id="func_23"></a>
> min (*a*: **int**, *b*: **int**) (**int**)

Renvoie la plus petite valeur entre `a` et `b`.

<a id="func_24"></a>
> rad (*degrés*: **float**) (**float**)

Convertit `degrés`  en radians.

<a id="func_25"></a>
> rand (*min*: **int**, *max*: **int**) (**int**)

Retourne une valeur aléatoire comprise entre `min` et `max` inclus.

<a id="func_26"></a>
> rand (**float**)

Retourne une valeur aléatoire comprise entre 0 et 1 exclus.

<a id="func_27"></a>
> rand (*min*: **float**, *max*: **float**) (**float**)

Retourne une valeur aléatoire comprise entre `min` et `max` inclus.

<a id="func_28"></a>
> rlerp (*source*: **float**, *destination*: **float**, *valeur*: **float**) (**float**)

Opération inverse de lerp.
Retourne le ratio entre 0 et 1 de `valeur` par rapport à `source` et `destination`

<a id="func_29"></a>
> round (*x*: **float**) (**float**)

Retourne l’arrondi de `x` à l’entier le plus proche.

<a id="func_30"></a>
> sin (*radians*: **float**) (**float**)

Retourne le sinus de `radians`.

<a id="func_31"></a>
> sqrt (*x*: **float**) (**float**)

Renvoie la racine carré de `x`.

<a id="func_32"></a>
> tan (*radians*: **float**) (**float**)

Retourne la tangeante de `radians`.

<a id="func_33"></a>
> truncate (*x*: **float**) (**float**)

Retourne la partie entière de `x`.

