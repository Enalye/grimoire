# std.math

## Description
Maths related functions.
## Variables
|Variable|Type|Value|Description|
|-|-|-|-|
|PI|**float**|3.14159|Ratio between the diameter of a circle and its circumference.|
## Opérators
|Opérator|Input|Output|
|-|-|-|
|**|**int**, **int**|**int**|
|**|**float**, **float**|**float**|
## Functions
|Function|Input|Output|
|-|-|-|
|[abs](#func_0)|*x*: **float**|**float**|
|[abs](#func_1)|*x*: **int**|**int**|
|[acos](#func_2)|*radians*: **float**|**float**|
|[approach](#func_3)|*x*: **float**, *target*: **float**, *step*: **float**|**float**|
|[approach](#func_4)|*x*: **int**, *target*: **int**, *step*: **int**|**int**|
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
|[rad](#func_24)|*degrees*: **float**|**float**|
|[rand](#func_25)|*min*: **int**, *max*: **int**|**int**|
|[rand](#func_26)||**float**|
|[rand](#func_27)|*min*: **float**, *max*: **float**|**float**|
|[rlerp](#func_28)|*source*: **float**, *destination*: **float**, *value*: **float**|**float**|
|[round](#func_29)|*x*: **float**|**float**|
|[sin](#func_30)|*radians*: **float**|**float**|
|[sqrt](#func_31)|*x*: **float**|**float**|
|[tan](#func_32)|*radians*: **float**|**float**|
|[truncate](#func_33)|*x*: **float**|**float**|


***
## Function descriptions

<a id="func_0"></a>
> abs (*x*: **float**) (**float**)

Returns the absolute value of `x`.

<a id="func_1"></a>
> abs (*x*: **int**) (**int**)

Returns the absolute value of `x`.

<a id="func_2"></a>
> acos (*radians*: **float**) (**float**)

Returns the arc cosine of `radians`.

<a id="func_3"></a>
> approach (*x*: **float**, *target*: **float**, *step*: **float**) (**float**)

Approach `x` up to `target` by increment of `step` without overshooting it.

A negative step distances from `target` by that much.

<a id="func_4"></a>
> approach (*x*: **int**, *target*: **int**, *step*: **int**) (**int**)

Approach `x` up to `target` by increment of `step` without overshooting it.

A negative step distances from `target` by that much.

<a id="func_5"></a>
> asin (*radians*: **float**) (**float**)

Returns the arc sine of `radians`.

<a id="func_6"></a>
> atan (*radians*: **float**) (**float**)

Returns the arc tangent of `radians`.

<a id="func_7"></a>
> atan2 (*a*: **float**, *b*: **float**) (**float**)

Variant of `atan`.

<a id="func_8"></a>
> ceil (*x*: **float**) (**float**)

Returns the rounded value of `x` not smaller than `x`.

<a id="func_9"></a>
> clamp (*x*: **int**, *min*: **int**, *max*: **int**) (**int**)

Restrict `x` between `min` and `max`.

<a id="func_10"></a>
> clamp (*x*: **float**, *min*: **float**, *max*: **float**) (**float**)

Restrict `x` between `min` and `max`.

<a id="func_11"></a>
> cos (*radians*: **float**) (**float**)

Returns the cosine of `radians`.

<a id="func_12"></a>
> deg (*radians*: **float**) (**float**)

Converts `radians` in degrees.

<a id="func_13"></a>
> exp (*x*: **float**) (**float**)

Returns the exponential of `x`.

<a id="func_14"></a>
> floor (*x*: **float**) (**float**)

Returns the rounded value of `x` not greater than `x`.

<a id="func_15"></a>
> isNaN (*x*: **float**) (**bool**)

Checks if `x` is a valid float value or not.

<a id="func_16"></a>
> lerp (*source*: **float**, *destination*: **float**, *t*: **float**) (**float**)

Interpolate between `source` and `destination` using `t` between 0 and 1.

<a id="func_17"></a>
> log (*x*: **float**) (**float**)

Returns the natural logarithm of `x`.

<a id="func_18"></a>
> log10 (*x*: **float**) (**float**)

Returns the base 10 logarithm of `x`.

<a id="func_19"></a>
> log2 (*x*: **float**) (**float**)

Returns the base 2 logarithm of `x`.

<a id="func_20"></a>
> max (*a*: **int**, *b*: **int**) (**int**)

Returns the greatest value between `a` et `b`.

<a id="func_21"></a>
> max (*a*: **float**, *b*: **float**) (**float**)

Returns the greatest value between `a` et `b`.

<a id="func_22"></a>
> min (*a*: **float**, *b*: **float**) (**float**)

Returns the smallest value between `a` and `b`.

<a id="func_23"></a>
> min (*a*: **int**, *b*: **int**) (**int**)

Returns the smallest value between `a` and `b`.

<a id="func_24"></a>
> rad (*degrees*: **float**) (**float**)

Converts `degrees` in radians.

<a id="func_25"></a>
> rand (*min*: **int**, *max*: **int**) (**int**)

Returns a random value between `min` and `max` included.

<a id="func_26"></a>
> rand (**float**)

Returns a random value between 0 and 1 excluded.

<a id="func_27"></a>
> rand (*min*: **float**, *max*: **float**) (**float**)

Returns a random value between `min` and `max` included.

<a id="func_28"></a>
> rlerp (*source*: **float**, *destination*: **float**, *value*: **float**) (**float**)

Reverse lerp operation.

Returns the ratio between 0 and 1 of `value` from `source` to `destination`.

<a id="func_29"></a>
> round (*x*: **float**) (**float**)

Returns the nearest rounded value of `x`.

<a id="func_30"></a>
> sin (*radians*: **float**) (**float**)

Returns the sine of `radians`.

<a id="func_31"></a>
> sqrt (*x*: **float**) (**float**)

Returns the square root of `x`.

<a id="func_32"></a>
> tan (*radians*: **float**) (**float**)

Returns the tangent of `radians`.

<a id="func_33"></a>
> truncate (*x*: **float**) (**float**)

Returns the integer part of `x`.

