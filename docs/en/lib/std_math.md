# std.math

## Description
Maths related functions.
## Variables
|Variable|Type|Valeur|Description|
|-|-|-|-|
|PI|**const real**|3.14159|Ratio between the diameter of a circle and its circumference.|
## Opérateurs
|Opérateur|Entrée|Sortie|
|-|-|-|
|**|**int**, **int**|**int**|
|**|**real**, **real**|**real**|
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[abs](#func_0)|**real** *x*|**real**|
|[abs](#func_1)|**int** *x*|**int**|
|[acos](#func_2)|**real** *radians*|**real**|
|[approach](#func_3)|**real** *x*, **real** *target*, **real** *step*|**real**|
|[approach](#func_4)|**int** *x*, **int** *target*, **int** *step*|**int**|
|[asin](#func_5)|**real** *radians*|**real**|
|[atan](#func_6)|**real** *radians*|**real**|
|[atan2](#func_7)|**real** *a*, **real** *b*|**real**|
|[ceil](#func_8)|**real** *x*|**real**|
|[clamp](#func_9)|**int** *x*, **int** *min*, **int** *max*|**int**|
|[clamp](#func_10)|**real** *x*, **real** *min*, **real** *max*|**real**|
|[cos](#func_11)|**real** *radians*|**real**|
|[deg](#func_12)|**real** *radians*|**real**|
|[exp](#func_13)|**real** *x*|**real**|
|[floor](#func_14)|**real** *x*|**real**|
|[isNaN](#func_15)|**real** *x*|**bool**|
|[lerp](#func_16)|**real** *source*, **real** *destination*, **real** *t*|**real**|
|[log](#func_17)|**real** *x*|**real**|
|[log10](#func_18)|**real** *x*|**real**|
|[log2](#func_19)|**real** *x*|**real**|
|[max](#func_20)|**int** *a*, **int** *b*|**int**|
|[max](#func_21)|**real** *a*, **real** *b*|**real**|
|[min](#func_22)|**real** *a*, **real** *b*|**real**|
|[min](#func_23)|**int** *a*, **int** *b*|**int**|
|[rad](#func_24)|**real** *degrees*|**real**|
|[rand](#func_25)|**int** *min*, **int** *max*|**int**|
|[rand](#func_26)||**real**|
|[rand](#func_27)|**real** *min*, **real** *max*|**real**|
|[rlerp](#func_28)|**real** *source*, **real** *destination*, **real** *value*|**real**|
|[round](#func_29)|**real** *x*|**real**|
|[sin](#func_30)|**real** *radians*|**real**|
|[sqrt](#func_31)|**real** *x*|**real**|
|[tan](#func_32)|**real** *radians*|**real**|
|[truncate](#func_33)|**real** *x*|**real**|


***
## Description des fonctions

<a id="func_0"></a>
> abs (**real** *x*) (**real**)

Returns the absolute value of `x`.

<a id="func_1"></a>
> abs (**int** *x*) (**int**)

Returns the absolute value of `x`.

<a id="func_2"></a>
> acos (**real** *radians*) (**real**)

Returns the arc cosine of `radians`.

<a id="func_3"></a>
> approach (**real** *x*, **real** *target*, **real** *step*) (**real**)

Approach `x` up to `target` by increment of `step` without overshooting it.
A negative `step` distances from `target` by that much.

<a id="func_4"></a>
> approach (**int** *x*, **int** *target*, **int** *step*) (**int**)

Approach `x` up to `target` by increment of `step` without overshooting it.
A negative `step` distances from `target` by that much.

<a id="func_5"></a>
> asin (**real** *radians*) (**real**)

Returns the arc sine of `radians`.

<a id="func_6"></a>
> atan (**real** *radians*) (**real**)

Returns the arc tangent of `radians`.

<a id="func_7"></a>
> atan2 (**real** *a*, **real** *b*) (**real**)

Variant of `atan`.

<a id="func_8"></a>
> ceil (**real** *x*) (**real**)

Returns the rounded value of `x` not smaller than `x`.

<a id="func_9"></a>
> clamp (**int** *x*, **int** *min*, **int** *max*) (**int**)

Restrict `x` between `min` and `max`.

<a id="func_10"></a>
> clamp (**real** *x*, **real** *min*, **real** *max*) (**real**)

Restrict `x` between `min` and `max`.

<a id="func_11"></a>
> cos (**real** *radians*) (**real**)

Returns the cosine of `radians`.

<a id="func_12"></a>
> deg (**real** *radians*) (**real**)

Converts `radians` in degrees.

<a id="func_13"></a>
> exp (**real** *x*) (**real**)

Returns the exponential of `x`.

<a id="func_14"></a>
> floor (**real** *x*) (**real**)

Returns the rounded value of `x` not greater than `x`.

<a id="func_15"></a>
> isNaN (**real** *x*) (**bool**)

Checks if `x` is a valid real value or not.

<a id="func_16"></a>
> lerp (**real** *source*, **real** *destination*, **real** *t*) (**real**)

Interpolate between `source` and `destination` using `t` between 0 and 1.

<a id="func_17"></a>
> log (**real** *x*) (**real**)

Returns the natural logarithm of `x`.

<a id="func_18"></a>
> log10 (**real** *x*) (**real**)

Returns the base 10 logarithm of `x`.

<a id="func_19"></a>
> log2 (**real** *x*) (**real**)

Returns the base 2 logarithm of `x`.

<a id="func_20"></a>
> max (**int** *a*, **int** *b*) (**int**)

Returns the greatest value between `a` et `b`.

<a id="func_21"></a>
> max (**real** *a*, **real** *b*) (**real**)

Returns the greatest value between `a` et `b`.

<a id="func_22"></a>
> min (**real** *a*, **real** *b*) (**real**)

Returns the smallest value between `a` and `b`.

<a id="func_23"></a>
> min (**int** *a*, **int** *b*) (**int**)

Returns the smallest value between `a` and `b`.

<a id="func_24"></a>
> rad (**real** *degrees*) (**real**)

Converts `degrees` in radians.

<a id="func_25"></a>
> rand (**int** *min*, **int** *max*) (**int**)

Returns a random value between `min` and `max` included.

<a id="func_26"></a>
> rand (**real**)

Returns a random value between 0 and 1 excluded.

<a id="func_27"></a>
> rand (**real** *min*, **real** *max*) (**real**)

Returns a random value between `min` and `max` included.

<a id="func_28"></a>
> rlerp (**real** *source*, **real** *destination*, **real** *value*) (**real**)

Reverse lerp operation.
Returns the ratio between 0 and 1 of `value` from `source` to `destination`.

<a id="func_29"></a>
> round (**real** *x*) (**real**)

Returns the nearest rounded value of `x`.

<a id="func_30"></a>
> sin (**real** *radians*) (**real**)

Returns the sine of `radians`.

<a id="func_31"></a>
> sqrt (**real** *x*) (**real**)

Returns the square root of `x`.

<a id="func_32"></a>
> tan (**real** *radians*) (**real**)

Returns the tangent of `radians`.

<a id="func_33"></a>
> truncate (**real** *x*) (**real**)

Returns the integer part of `x`.

