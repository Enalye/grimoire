# std.math

## Description
Fonctions liées aux maths.
## Variables
|Variable|Type|Valeur|Description|
|-|-|-|-|
|PI|**double**|3.14159|Rapport entre le diamètre du cercle et sa circonférence.|
## Opérateurs
|Opérateur|Entrée|Sortie|
|-|-|-|
|**|**int**, **int**|**int**|
|**|**double**, **double**|**double**|
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[abs](#func_0)|*x*: **double**|**double**|
|[abs](#func_1)|*x*: **int**|**int**|
|[acos](#func_2)|*radians*: **double**|**double**|
|[approach](#func_3)|*x*: **double**, *target*: **double**, *step*: **double**|**double**|
|[approach](#func_4)|*x*: **int**, *target*: **int**, *step*: **int**|**int**|
|[asin](#func_5)|*radians*: **double**|**double**|
|[atan](#func_6)|*radians*: **double**|**double**|
|[atan2](#func_7)|*a*: **double**, *b*: **double**|**double**|
|[ceil](#func_8)|*x*: **double**|**double**|
|[clamp](#func_9)|*x*: **int**, *min*: **int**, *max*: **int**|**int**|
|[clamp](#func_10)|*x*: **double**, *min*: **double**, *max*: **double**|**double**|
|[cos](#func_11)|*radians*: **double**|**double**|
|[deg](#func_12)|*radians*: **double**|**double**|
|[exp](#func_13)|*x*: **double**|**double**|
|[floor](#func_14)|*x*: **double**|**double**|
|[isNaN](#func_15)|*x*: **double**|**bool**|
|[lerp](#func_16)|*source*: **double**, *destination*: **double**, *t*: **double**|**double**|
|[log](#func_17)|*x*: **double**|**double**|
|[log10](#func_18)|*x*: **double**|**double**|
|[log2](#func_19)|*x*: **double**|**double**|
|[max](#func_20)|*a*: **int**, *b*: **int**|**int**|
|[max](#func_21)|*a*: **double**, *b*: **double**|**double**|
|[min](#func_22)|*a*: **double**, *b*: **double**|**double**|
|[min](#func_23)|*a*: **int**, *b*: **int**|**int**|
|[rad](#func_24)|*degrés*: **double**|**double**|
|[rand](#func_25)|*min*: **int**, *max*: **int**|**int**|
|[rand](#func_26)||**double**|
|[rand](#func_27)|*min*: **double**, *max*: **double**|**double**|
|[rlerp](#func_28)|*source*: **double**, *destination*: **double**, *valeur*: **double**|**double**|
|[round](#func_29)|*x*: **double**|**double**|
|[sin](#func_30)|*radians*: **double**|**double**|
|[sqrt](#func_31)|*x*: **double**|**double**|
|[tan](#func_32)|*radians*: **double**|**double**|
|[truncate](#func_33)|*x*: **double**|**double**|


***
## Description des fonctions

<a id="func_0"></a>
> abs (*x*: **double**) (**double**)

Retourne la valeur absolue de `x`.

<a id="func_1"></a>
> abs (*x*: **int**) (**int**)

Retourne la valeur absolue de `x`.

<a id="func_2"></a>
> acos (*radians*: **double**) (**double**)

Retourne l’arc cosinus de `radians`.

<a id="func_3"></a>
> approach (*x*: **double**, *target*: **double**, *step*: **double**) (**double**)

Approche `x` de `target` par pas de `step` sans le dépasser.

Un pas négatif l’éloigne de `target` d’autant.

<a id="func_4"></a>
> approach (*x*: **int**, *target*: **int**, *step*: **int**) (**int**)

Approche `x` de `target` par pas de `step` sans le dépasser.

Un pas négatif l’éloigne de `target` d’autant.

<a id="func_5"></a>
> asin (*radians*: **double**) (**double**)

Retourne l’arc sinus de `radians`.

<a id="func_6"></a>
> atan (*radians*: **double**) (**double**)

Retourne l’arc tangeante de `radians`.

<a id="func_7"></a>
> atan2 (*a*: **double**, *b*: **double**) (**double**)

Variation d’`atan`.

<a id="func_8"></a>
> ceil (*x*: **double**) (**double**)

Retourne l’arrondi de `x` à l’entier supérieur.

<a id="func_9"></a>
> clamp (*x*: **int**, *min*: **int**, *max*: **int**) (**int**)

Restreint `x` entre `min` et `max`.

<a id="func_10"></a>
> clamp (*x*: **double**, *min*: **double**, *max*: **double**) (**double**)

Restreint `x` entre `min` et `max`.

<a id="func_11"></a>
> cos (*radians*: **double**) (**double**)

Retourne le cosinus de `radians`.

<a id="func_12"></a>
> deg (*radians*: **double**) (**double**)

Convertit `radians` en degrés .

<a id="func_13"></a>
> exp (*x*: **double**) (**double**)

Retourne l’exponentielle de `x`.

<a id="func_14"></a>
> floor (*x*: **double**) (**double**)

Retourne l’arrondi de `x` à l’entier inférieur.

<a id="func_15"></a>
> isNaN (*x*: **double**) (**bool**)

Vérifie si le `x` est un réel valide ou non.

<a id="func_16"></a>
> lerp (*source*: **double**, *destination*: **double**, *t*: **double**) (**double**)

Interpole entre `source` et `destination` en fonction de `t` compris entre 0 et 1.

<a id="func_17"></a>
> log (*x*: **double**) (**double**)

Renvoie le logarithme naturel de `x`.

<a id="func_18"></a>
> log10 (*x*: **double**) (**double**)

Renvoie le logarithme en base 10 de `x`.

<a id="func_19"></a>
> log2 (*x*: **double**) (**double**)

Renvoie le logarithme en base 2 de `x`.

<a id="func_20"></a>
> max (*a*: **int**, *b*: **int**) (**int**)

Renvoie la plus grande valeur entre `a` et `b`.

<a id="func_21"></a>
> max (*a*: **double**, *b*: **double**) (**double**)

Renvoie la plus grande valeur entre `a` et `b`.

<a id="func_22"></a>
> min (*a*: **double**, *b*: **double**) (**double**)

Renvoie la plus petite valeur entre `a` et `b`.

<a id="func_23"></a>
> min (*a*: **int**, *b*: **int**) (**int**)

Renvoie la plus petite valeur entre `a` et `b`.

<a id="func_24"></a>
> rad (*degrés*: **double**) (**double**)

Convertit `degrés`  en radians.

<a id="func_25"></a>
> rand (*min*: **int**, *max*: **int**) (**int**)

Retourne une valeur aléatoire comprise entre `min` et `max` inclus.

<a id="func_26"></a>
> rand (**double**)

Retourne une valeur aléatoire comprise entre 0 et 1 exclus.

<a id="func_27"></a>
> rand (*min*: **double**, *max*: **double**) (**double**)

Retourne une valeur aléatoire comprise entre `min` et `max` inclus.

<a id="func_28"></a>
> rlerp (*source*: **double**, *destination*: **double**, *valeur*: **double**) (**double**)

Opération inverse de lerp.

Retourne le ratio entre 0 et 1 de `valeur` par rapport à `source` et `destination`

<a id="func_29"></a>
> round (*x*: **double**) (**double**)

Retourne l’arrondi de `x` à l’entier le plus proche.

<a id="func_30"></a>
> sin (*radians*: **double**) (**double**)

Retourne le sinus de `radians`.

<a id="func_31"></a>
> sqrt (*x*: **double**) (**double**)

Renvoie la racine carré de `x`.

<a id="func_32"></a>
> tan (*radians*: **double**) (**double**)

Retourne la tangeante de `radians`.

<a id="func_33"></a>
> truncate (*x*: **double**) (**double**)

Retourne la partie entière de `x`.

