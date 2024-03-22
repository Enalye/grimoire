# math

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
|**|**uint**, **uint**|**uint**|
|**|**float**, **float**|**float**|
|**|**double**, **double**|**double**|
## Functions
|Function|Input|Output|
|-|-|-|
|[abs](#func_0)|*x*: **double**|**double**|
|[abs](#func_1)|*x*: **int**|**int**|
|[abs](#func_2)|*x*: **float**|**float**|
|[acos](#func_3)|*radians*: **double**|**double**|
|[acos](#func_4)|*radians*: **float**|**float**|
|[approach](#func_5)|*x*: **double**, *target*: **double**, *step*: **double**|**double**|
|[approach](#func_6)|*x*: **int**, *target*: **int**, *step*: **int**|**int**|
|[approach](#func_7)|*x*: **uint**, *target*: **uint**, *step*: **uint**|**uint**|
|[approach](#func_8)|*x*: **float**, *target*: **float**, *step*: **float**|**float**|
|[asin](#func_9)|*radians*: **double**|**double**|
|[asin](#func_10)|*radians*: **float**|**float**|
|[atan](#func_11)|*radians*: **double**|**double**|
|[atan](#func_12)|*radians*: **float**|**float**|
|[atan2](#func_13)|*a*: **double**, *b*: **double**|**double**|
|[atan2](#func_14)|*a*: **float**, *b*: **float**|**float**|
|[ceil](#func_15)|*x*: **double**|**double**|
|[ceil](#func_16)|*x*: **float**|**float**|
|[clamp](#func_17)|*x*: **int**, *min*: **int**, *max*: **int**|**int**|
|[clamp](#func_18)|*x*: **uint**, *min*: **uint**, *max*: **uint**|**uint**|
|[clamp](#func_19)|*x*: **float**, *min*: **float**, *max*: **float**|**float**|
|[clamp](#func_20)|*x*: **double**, *min*: **double**, *max*: **double**|**double**|
|[cos](#func_21)|*radians*: **double**|**double**|
|[cos](#func_22)|*radians*: **float**|**float**|
|[deg](#func_23)|*radians*: **float**|**float**|
|[deg](#func_24)|*radians*: **double**|**double**|
|[exp](#func_25)|*x*: **double**|**double**|
|[exp](#func_26)|*x*: **float**|**float**|
|[floor](#func_27)|*x*: **double**|**double**|
|[floor](#func_28)|*x*: **float**|**float**|
|[isNaN](#func_29)|*x*: **double**|**bool**|
|[isNaN](#func_30)|*x*: **float**|**bool**|
|[lerp](#func_31)|*src*: **float**, *dest*: **float**, *t*: **float**|**float**|
|[lerp](#func_32)|*src*: **double**, *dest*: **double**, *t*: **double**|**double**|
|[log](#func_33)|*x*: **float**|**float**|
|[log](#func_34)|*x*: **double**|**double**|
|[log10](#func_35)|*x*: **float**|**float**|
|[log10](#func_36)|*x*: **double**|**double**|
|[log2](#func_37)|*x*: **float**|**float**|
|[log2](#func_38)|*x*: **double**|**double**|
|[max](#func_39)|*a*: **double**, *b*: **double**|**double**|
|[max](#func_40)|*a*: **int**, *b*: **int**|**int**|
|[max](#func_41)|*a*: **float**, *b*: **float**|**float**|
|[max](#func_42)|*a*: **uint**, *b*: **uint**|**uint**|
|[min](#func_43)|*a*: **int**, *b*: **int**|**int**|
|[min](#func_44)|*a*: **double**, *b*: **double**|**double**|
|[min](#func_45)|*a*: **float**, *b*: **float**|**float**|
|[min](#func_46)|*a*: **uint**, *b*: **uint**|**uint**|
|[rad](#func_47)|*degrees*: **float**|**float**|
|[rad](#func_48)|*degrees*: **double**|**double**|
|[rand](#func_49)||**double**|
|[rand](#func_50)|*min*: **double**, *max*: **double**|**double**|
|[rand](#func_51)|*min*: **float**, *max*: **float**|**float**|
|[rand](#func_52)|*min*: **uint**, *max*: **uint**|**uint**|
|[rand](#func_53)|*min*: **int**, *max*: **int**|**int**|
|[rlerp](#func_54)|*src*: **float**, *dest*: **float**, *value*: **float**|**float**|
|[rlerp](#func_55)|*src*: **double**, *dest*: **double**, *value*: **double**|**double**|
|[round](#func_56)|*x*: **float**|**float**|
|[round](#func_57)|*x*: **double**|**double**|
|[sin](#func_58)|*radians*: **float**|**float**|
|[sin](#func_59)|*radians*: **double**|**double**|
|[sqrt](#func_60)|*x*: **float**|**float**|
|[sqrt](#func_61)|*x*: **double**|**double**|
|[tan](#func_62)|*radians*: **double**|**double**|
|[tan](#func_63)|*radians*: **float**|**float**|
|[truncate](#func_64)|*x*: **float**|**float**|
|[truncate](#func_65)|*x*: **double**|**double**|
|[ulerp](#func_66)|*src*: **float**, *dest*: **float**, *t*: **float**|**float**|
|[ulerp](#func_67)|*src*: **double**, *dest*: **double**, *t*: **double**|**double**|


***
## Function descriptions

<a id="func_0"></a>
> abs(*x*: **double**) (**double**)

Returns the absolute value of `x`.

<a id="func_1"></a>
> abs(*x*: **int**) (**int**)

Returns the absolute value of `x`.

<a id="func_2"></a>
> abs(*x*: **float**) (**float**)

Returns the absolute value of `x`.

<a id="func_3"></a>
> acos(*radians*: **double**) (**double**)

Returns the arc cosine of `radians`.

<a id="func_4"></a>
> acos(*radians*: **float**) (**float**)

Returns the arc cosine of `radians`.

<a id="func_5"></a>
> approach(*x*: **double**, *target*: **double**, *step*: **double**) (**double**)

Approach `x` up to `target` by increment of `step` without overshooting it.

A negative step distances from `target` by that much.

<a id="func_6"></a>
> approach(*x*: **int**, *target*: **int**, *step*: **int**) (**int**)

Approach `x` up to `target` by increment of `step` without overshooting it.

A negative step distances from `target` by that much.

<a id="func_7"></a>
> approach(*x*: **uint**, *target*: **uint**, *step*: **uint**) (**uint**)

Approach `x` up to `target` by increment of `step` without overshooting it.

A negative step distances from `target` by that much.

<a id="func_8"></a>
> approach(*x*: **float**, *target*: **float**, *step*: **float**) (**float**)

Approach `x` up to `target` by increment of `step` without overshooting it.

A negative step distances from `target` by that much.

<a id="func_9"></a>
> asin(*radians*: **double**) (**double**)

Returns the arc sine of `radians`.

<a id="func_10"></a>
> asin(*radians*: **float**) (**float**)

Returns the arc sine of `radians`.

<a id="func_11"></a>
> atan(*radians*: **double**) (**double**)

Returns the arc tangent of `radians`.

<a id="func_12"></a>
> atan(*radians*: **float**) (**float**)

Returns the arc tangent of `radians`.

<a id="func_13"></a>
> atan2(*a*: **double**, *b*: **double**) (**double**)

Variant of `atan`.

<a id="func_14"></a>
> atan2(*a*: **float**, *b*: **float**) (**float**)

Variant of `atan`.

<a id="func_15"></a>
> ceil(*x*: **double**) (**double**)

Returns the rounded value of `x` not smaller than `x`.

<a id="func_16"></a>
> ceil(*x*: **float**) (**float**)

Returns the rounded value of `x` not smaller than `x`.

<a id="func_17"></a>
> clamp(*x*: **int**, *min*: **int**, *max*: **int**) (**int**)

Restrict `x` between `min` and `max`.

<a id="func_18"></a>
> clamp(*x*: **uint**, *min*: **uint**, *max*: **uint**) (**uint**)

Restrict `x` between `min` and `max`.

<a id="func_19"></a>
> clamp(*x*: **float**, *min*: **float**, *max*: **float**) (**float**)

Restrict `x` between `min` and `max`.

<a id="func_20"></a>
> clamp(*x*: **double**, *min*: **double**, *max*: **double**) (**double**)

Restrict `x` between `min` and `max`.

<a id="func_21"></a>
> cos(*radians*: **double**) (**double**)

Returns the cosine of `radians`.

<a id="func_22"></a>
> cos(*radians*: **float**) (**float**)

Returns the cosine of `radians`.

<a id="func_23"></a>
> deg(*radians*: **float**) (**float**)

Converts `radians` in degrees.

<a id="func_24"></a>
> deg(*radians*: **double**) (**double**)

Converts `radians` in degrees.

<a id="func_25"></a>
> exp(*x*: **double**) (**double**)

Returns the exponential of `x`.

<a id="func_26"></a>
> exp(*x*: **float**) (**float**)

Returns the exponential of `x`.

<a id="func_27"></a>
> floor(*x*: **double**) (**double**)

Returns the rounded value of `x` not greater than `x`.

<a id="func_28"></a>
> floor(*x*: **float**) (**float**)

Returns the rounded value of `x` not greater than `x`.

<a id="func_29"></a>
> isNaN(*x*: **double**) (**bool**)

Checks if `x` is a valid float value or not.

<a id="func_30"></a>
> isNaN(*x*: **float**) (**bool**)

Checks if `x` is a valid float value or not.

<a id="func_31"></a>
> lerp(*src*: **float**, *dest*: **float**, *t*: **float**) (**float**)

Interpolate between `src` and `dest` using `t` clamped between 0 and 1.

<a id="func_32"></a>
> lerp(*src*: **double**, *dest*: **double**, *t*: **double**) (**double**)

Interpolate between `src` and `dest` using `t` clamped between 0 and 1.

<a id="func_33"></a>
> log(*x*: **float**) (**float**)

Returns the natural logarithm of `x`.

<a id="func_34"></a>
> log(*x*: **double**) (**double**)

Returns the natural logarithm of `x`.

<a id="func_35"></a>
> log10(*x*: **float**) (**float**)

Returns the base 10 logarithm of `x`.

<a id="func_36"></a>
> log10(*x*: **double**) (**double**)

Returns the base 10 logarithm of `x`.

<a id="func_37"></a>
> log2(*x*: **float**) (**float**)

Returns the base 2 logarithm of `x`.

<a id="func_38"></a>
> log2(*x*: **double**) (**double**)

Returns the base 2 logarithm of `x`.

<a id="func_39"></a>
> max(*a*: **double**, *b*: **double**) (**double**)

Returns the greatest value between `a` et `b`.

<a id="func_40"></a>
> max(*a*: **int**, *b*: **int**) (**int**)

Returns the greatest value between `a` et `b`.

<a id="func_41"></a>
> max(*a*: **float**, *b*: **float**) (**float**)

Returns the greatest value between `a` et `b`.

<a id="func_42"></a>
> max(*a*: **uint**, *b*: **uint**) (**uint**)

Returns the greatest value between `a` et `b`.

<a id="func_43"></a>
> min(*a*: **int**, *b*: **int**) (**int**)

Returns the smallest value between `a` and `b`.

<a id="func_44"></a>
> min(*a*: **double**, *b*: **double**) (**double**)

Returns the smallest value between `a` and `b`.

<a id="func_45"></a>
> min(*a*: **float**, *b*: **float**) (**float**)

Returns the smallest value between `a` and `b`.

<a id="func_46"></a>
> min(*a*: **uint**, *b*: **uint**) (**uint**)

Returns the smallest value between `a` and `b`.

<a id="func_47"></a>
> rad(*degrees*: **float**) (**float**)

Converts `degrees` in radians.

<a id="func_48"></a>
> rad(*degrees*: **double**) (**double**)

Converts `degrees` in radians.

<a id="func_49"></a>
> rand() (**double**)

Returns a random value between 0 and 1 excluded.

<a id="func_50"></a>
> rand(*min*: **double**, *max*: **double**) (**double**)

Returns a random value between `min` and `max` included.

<a id="func_51"></a>
> rand(*min*: **float**, *max*: **float**) (**float**)

Returns a random value between `min` and `max` included.

<a id="func_52"></a>
> rand(*min*: **uint**, *max*: **uint**) (**uint**)

Returns a random value between `min` and `max` included.

<a id="func_53"></a>
> rand(*min*: **int**, *max*: **int**) (**int**)

Returns a random value between `min` and `max` included.

<a id="func_54"></a>
> rlerp(*src*: **float**, *dest*: **float**, *value*: **float**) (**float**)

Reverse lerp operation.

Returns the ratio between 0 and 1 of `value` from `src` to `dest`.

<a id="func_55"></a>
> rlerp(*src*: **double**, *dest*: **double**, *value*: **double**) (**double**)

Reverse lerp operation.

Returns the ratio between 0 and 1 of `value` from `src` to `dest`.

<a id="func_56"></a>
> round(*x*: **float**) (**float**)

Returns the nearest rounded value of `x`.

<a id="func_57"></a>
> round(*x*: **double**) (**double**)

Returns the nearest rounded value of `x`.

<a id="func_58"></a>
> sin(*radians*: **float**) (**float**)

Returns the sine of `radians`.

<a id="func_59"></a>
> sin(*radians*: **double**) (**double**)

Returns the sine of `radians`.

<a id="func_60"></a>
> sqrt(*x*: **float**) (**float**)

Returns the square root of `x`.

<a id="func_61"></a>
> sqrt(*x*: **double**) (**double**)

Returns the square root of `x`.

<a id="func_62"></a>
> tan(*radians*: **double**) (**double**)

Returns the tangent of `radians`.

<a id="func_63"></a>
> tan(*radians*: **float**) (**float**)

Returns the tangent of `radians`.

<a id="func_64"></a>
> truncate(*x*: **float**) (**float**)

Returns the integer part of `x`.

<a id="func_65"></a>
> truncate(*x*: **double**) (**double**)

Returns the integer part of `x`.

<a id="func_66"></a>
> ulerp(*src*: **float**, *dest*: **float**, *t*: **float**) (**float**)

Interpolate between `src` and `dest` using `t` between 0 and 1 with extrapolation.

<a id="func_67"></a>
> ulerp(*src*: **double**, *dest*: **double**, *t*: **double**) (**double**)

Interpolate between `src` and `dest` using `t` between 0 and 1 with extrapolation.

