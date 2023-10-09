# std.math

## Description
Maths related functions.
## Variables
|Variable|Type|Value|Description|
|-|-|-|-|
|PI|**double**|3.14159|Ratio between the diameter of a circle and its circumference.|
## Opérators
|Opérator|Input|Output|
|-|-|-|
|**|**int**, **int**|**int**|
|**|**double**, **double**|**double**|
## Functions
|Function|Input|Output|
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
|[rad](#func_24)|*degrees*: **double**|**double**|
|[rand](#func_25)|*min*: **int**, *max*: **int**|**int**|
|[rand](#func_26)||**double**|
|[rand](#func_27)|*min*: **double**, *max*: **double**|**double**|
|[rlerp](#func_28)|*source*: **double**, *destination*: **double**, *value*: **double**|**double**|
|[round](#func_29)|*x*: **double**|**double**|
|[sin](#func_30)|*radians*: **double**|**double**|
|[sqrt](#func_31)|*x*: **double**|**double**|
|[tan](#func_32)|*radians*: **double**|**double**|
|[truncate](#func_33)|*x*: **double**|**double**|


***
## Function descriptions

<a id="func_0"></a>
> abs (*x*: **double**) (**double**)

Returns the absolute value of `x`.

<a id="func_1"></a>
> abs (*x*: **int**) (**int**)

Returns the absolute value of `x`.

<a id="func_2"></a>
> acos (*radians*: **double**) (**double**)

Returns the arc cosine of `radians`.

<a id="func_3"></a>
> approach (*x*: **double**, *target*: **double**, *step*: **double**) (**double**)

Approach `x` up to `target` by increment of `step` without overshooting it.

A negative step distances from `target` by that much.

<a id="func_4"></a>
> approach (*x*: **int**, *target*: **int**, *step*: **int**) (**int**)

Approach `x` up to `target` by increment of `step` without overshooting it.

A negative step distances from `target` by that much.

<a id="func_5"></a>
> asin (*radians*: **double**) (**double**)

Returns the arc sine of `radians`.

<a id="func_6"></a>
> atan (*radians*: **double**) (**double**)

Returns the arc tangent of `radians`.

<a id="func_7"></a>
> atan2 (*a*: **double**, *b*: **double**) (**double**)

Variant of `atan`.

<a id="func_8"></a>
> ceil (*x*: **double**) (**double**)

Returns the rounded value of `x` not smaller than `x`.

<a id="func_9"></a>
> clamp (*x*: **int**, *min*: **int**, *max*: **int**) (**int**)

Restrict `x` between `min` and `max`.

<a id="func_10"></a>
> clamp (*x*: **double**, *min*: **double**, *max*: **double**) (**double**)

Restrict `x` between `min` and `max`.

<a id="func_11"></a>
> cos (*radians*: **double**) (**double**)

Returns the cosine of `radians`.

<a id="func_12"></a>
> deg (*radians*: **double**) (**double**)

Converts `radians` in degrees.

<a id="func_13"></a>
> exp (*x*: **double**) (**double**)

Returns the exponential of `x`.

<a id="func_14"></a>
> floor (*x*: **double**) (**double**)

Returns the rounded value of `x` not greater than `x`.

<a id="func_15"></a>
> isNaN (*x*: **double**) (**bool**)

Checks if `x` is a valid float value or not.

<a id="func_16"></a>
> lerp (*source*: **double**, *destination*: **double**, *t*: **double**) (**double**)

Interpolate between `source` and `destination` using `t` between 0 and 1.

<a id="func_17"></a>
> log (*x*: **double**) (**double**)

Returns the natural logarithm of `x`.

<a id="func_18"></a>
> log10 (*x*: **double**) (**double**)

Returns the base 10 logarithm of `x`.

<a id="func_19"></a>
> log2 (*x*: **double**) (**double**)

Returns the base 2 logarithm of `x`.

<a id="func_20"></a>
> max (*a*: **int**, *b*: **int**) (**int**)

Returns the greatest value between `a` et `b`.

<a id="func_21"></a>
> max (*a*: **double**, *b*: **double**) (**double**)

Returns the greatest value between `a` et `b`.

<a id="func_22"></a>
> min (*a*: **double**, *b*: **double**) (**double**)

Returns the smallest value between `a` and `b`.

<a id="func_23"></a>
> min (*a*: **int**, *b*: **int**) (**int**)

Returns the smallest value between `a` and `b`.

<a id="func_24"></a>
> rad (*degrees*: **double**) (**double**)

Converts `degrees` in radians.

<a id="func_25"></a>
> rand (*min*: **int**, *max*: **int**) (**int**)

Returns a random value between `min` and `max` included.

<a id="func_26"></a>
> rand (**double**)

Returns a random value between 0 and 1 excluded.

<a id="func_27"></a>
> rand (*min*: **double**, *max*: **double**) (**double**)

Returns a random value between `min` and `max` included.

<a id="func_28"></a>
> rlerp (*source*: **double**, *destination*: **double**, *value*: **double**) (**double**)

Reverse lerp operation.

Returns the ratio between 0 and 1 of `value` from `source` to `destination`.

<a id="func_29"></a>
> round (*x*: **double**) (**double**)

Returns the nearest rounded value of `x`.

<a id="func_30"></a>
> sin (*radians*: **double**) (**double**)

Returns the sine of `radians`.

<a id="func_31"></a>
> sqrt (*x*: **double**) (**double**)

Returns the square root of `x`.

<a id="func_32"></a>
> tan (*radians*: **double**) (**double**)

Returns the tangent of `radians`.

<a id="func_33"></a>
> truncate (*x*: **double**) (**double**)

Returns the integer part of `x`.

