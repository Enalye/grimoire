# std.math

## Description
Maths related functions.
## Variables
|Variable|Type|Valeur|Description|
|-|-|-|-|
|PI|**float**|3.14159|Ratio between the diameter of a circle and its circumference.|
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
|[approach](#func_3)|**float** *x*, **float** *target*, **float** *step*|**float**|
|[approach](#func_4)|**int** *x*, **int** *target*, **int** *step*|**int**|
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
|[rad](#func_24)|**float** *degrees*|**float**|
|[rand](#func_25)|**int** *min*, **int** *max*|**int**|
|[rand](#func_26)||**float**|
|[rand](#func_27)|**float** *min*, **float** *max*|**float**|
|[rlerp](#func_28)|**float** *source*, **float** *destination*, **float** *value*|**float**|
|[round](#func_29)|**float** *x*|**float**|
|[sin](#func_30)|**float** *radians*|**float**|
|[sqrt](#func_31)|**float** *x*|**float**|
|[tan](#func_32)|**float** *radians*|**float**|
|[truncate](#func_33)|**float** *x*|**float**|


***
## Description des fonctions

<a id="func_0"></a>
> abs (**float** *x*) (**float**)

Returns the absolute value of `x`.

<a id="func_1"></a>
> abs (**int** *x*) (**int**)

Returns the absolute value of `x`.

<a id="func_2"></a>
> acos (**float** *radians*) (**float**)

Returns the arc cosine of `radians`.

<a id="func_3"></a>
> approach (**float** *x*, **float** *target*, **float** *step*) (**float**)

Approach `x` up to `target` by increment of `step` without overshooting it.
A negative `step` distances from `target` by that much.

<a id="func_4"></a>
> approach (**int** *x*, **int** *target*, **int** *step*) (**int**)

Approach `x` up to `target` by increment of `step` without overshooting it.
A negative `step` distances from `target` by that much.

<a id="func_5"></a>
> asin (**float** *radians*) (**float**)

Returns the arc sine of `radians`.

<a id="func_6"></a>
> atan (**float** *radians*) (**float**)

Returns the arc tangent of `radians`.

<a id="func_7"></a>
> atan2 (**float** *a*, **float** *b*) (**float**)

Variant of `atan`.

<a id="func_8"></a>
> ceil (**float** *x*) (**float**)

Returns the rounded value of `x` not smaller than `x`.

<a id="func_9"></a>
> clamp (**int** *x*, **int** *min*, **int** *max*) (**int**)

Restrict `x` between `min` and `max`.

<a id="func_10"></a>
> clamp (**float** *x*, **float** *min*, **float** *max*) (**float**)

Restrict `x` between `min` and `max`.

<a id="func_11"></a>
> cos (**float** *radians*) (**float**)

Returns the cosine of `radians`.

<a id="func_12"></a>
> deg (**float** *radians*) (**float**)

Converts `radians` in degrees.

<a id="func_13"></a>
> exp (**float** *x*) (**float**)

Returns the exponential of `x`.

<a id="func_14"></a>
> floor (**float** *x*) (**float**)

Returns the rounded value of `x` not greater than `x`.

<a id="func_15"></a>
> isNaN (**float** *x*) (**bool**)

Checks if `x` is a valid float value or not.

<a id="func_16"></a>
> lerp (**float** *source*, **float** *destination*, **float** *t*) (**float**)

Interpolate between `source` and `destination` using `t` between 0 and 1.

<a id="func_17"></a>
> log (**float** *x*) (**float**)

Returns the natural logarithm of `x`.

<a id="func_18"></a>
> log10 (**float** *x*) (**float**)

Returns the base 10 logarithm of `x`.

<a id="func_19"></a>
> log2 (**float** *x*) (**float**)

Returns the base 2 logarithm of `x`.

<a id="func_20"></a>
> max (**int** *a*, **int** *b*) (**int**)

Returns the greatest value between `a` et `b`.

<a id="func_21"></a>
> max (**float** *a*, **float** *b*) (**float**)

Returns the greatest value between `a` et `b`.

<a id="func_22"></a>
> min (**float** *a*, **float** *b*) (**float**)

Returns the smallest value between `a` and `b`.

<a id="func_23"></a>
> min (**int** *a*, **int** *b*) (**int**)

Returns the smallest value between `a` and `b`.

<a id="func_24"></a>
> rad (**float** *degrees*) (**float**)

Converts `degrees` in radians.

<a id="func_25"></a>
> rand (**int** *min*, **int** *max*) (**int**)

Returns a random value between `min` and `max` included.

<a id="func_26"></a>
> rand (**float**)

Returns a random value between 0 and 1 excluded.

<a id="func_27"></a>
> rand (**float** *min*, **float** *max*) (**float**)

Returns a random value between `min` and `max` included.

<a id="func_28"></a>
> rlerp (**float** *source*, **float** *destination*, **float** *value*) (**float**)

Reverse lerp operation.
Returns the ratio between 0 and 1 of `value` from `source` to `destination`.

<a id="func_29"></a>
> round (**float** *x*) (**float**)

Returns the nearest rounded value of `x`.

<a id="func_30"></a>
> sin (**float** *radians*) (**float**)

Returns the sine of `radians`.

<a id="func_31"></a>
> sqrt (**float** *x*) (**float**)

Returns the square root of `x`.

<a id="func_32"></a>
> tan (**float** *radians*) (**float**)

Returns the tangent of `radians`.

<a id="func_33"></a>
> truncate (**float** *x*) (**float**)

Returns the integer part of `x`.

