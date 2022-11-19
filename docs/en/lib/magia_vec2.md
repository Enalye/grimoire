# vec2

Vector used for 2D math.

## Description

A pair of float values that can represents a single point of a direction in a 2 dimensional space.

## Fields

|Field|Type|
|-|-|
|x|float|
|y|float|

## Functions

|Function|Input|Output|
|-|-|-|
|[vec2](#vec2_0)||[vec2](#vec2)|
|[vec2](#vec2_1)|float x|[vec2](#vec2)|
|[vec2](#vec2_2)|float x, float y|[vec2](#vec2)|
|[vec2_zero](#vec2_zero)||[vec2](#vec2)|
|[vec2_half](#vec2_half)||[vec2](#vec2)|
|[vec2_one](#vec2_one)||[vec2](#vec2)|
|[vec2_up](#vec2_up)||[vec2](#vec2)|
|[vec2_down](#vec2_down)||[vec2](#vec2)|
|[vec2_right](#vec2_right)||[vec2](#vec2)|
|[vec2_left](#vec2_left)||[vec2](#vec2)|
|[vec2_angled](#vec2_angled)|float angle|[vec2](#vec2)|
|[abs](#abs)|[vec2](#vec2) this|[vec2](#vec2)|
|[angle](#angle)|[vec2](#vec2) this|float|
|[approach](#approach)|[vec2](#vec2) from, [vec2](#vec2) to, float step|[vec2](#vec2)|
|[ceil](#ceil)|[vec2](#vec2) this|[vec2](#vec2)|
|[cross](#cross)|[vec2](#vec2) v1, [vec2](#vec2) v2|float|
|[distance](#distance)|[vec2](#vec2) from, [vec2](#vec2) to|float|
|[distance2](#distance2)|[vec2](#vec2) from, [vec2](#vec2) to|float|
|[dot](#dot)|[vec2](#vec2) v1, [vec2](#vec2) v2|float|
|[floor](#floor)|[vec2](#vec2) this|[vec2](#vec2)|
|[lerp](#lerp)|[vec2](#vec2) from, [vec2](#vec2) to, float t|[vec2](#vec2)|
|[magnitude](#magnitude)|[vec2](#vec2) this|float|
|[magnitude2](#magnitude2)|[vec2](#vec2) this|float|
|[normal](#normal)|[vec2](#vec2) this|[vec2](#vec2)|
|[normalize](#normalize)|[vec2](#vec2) this|[vec2](#vec2)|
|[normalized](#normalized)|[vec2](#vec2) this|[vec2](#vec2)|
|[print](#print)|[vec2](#vec2) this||
|[reflect](#reflect)|[vec2](#vec2) this, [vec2](#vec2) normal|[vec2](#vec2)|
|[refract](#refract)|[vec2](#vec2) this, [vec2](#vec2) normal, float theta|[vec2](#vec2)|
|[rotate](#rotate)|[vec2](#vec2) this, float angle|[vec2](#vec2)|
|[rotated](#rotated)|[vec2](#vec2) this, float angle|[vec2](#vec2)|
|[round](#round)|[vec2](#vec2) this|[vec2](#vec2)|
|[sign](#sign)|[vec2](#vec2) this|[vec2](#vec2)|
|[sum](#sum)|[vec2](#vec2) this|float|
|[unpack](#unpack)|[vec2](#vec2) this|float, float|
|[zero?](#zero)|[vec2](#vec2) this|bool|

---

## Function Descriptions

<a id="vec2_0"></a>
- vec2 ( ) ( [vec2](#vec2) )

Returns a new vec2 which equals `vec2(0., 0.)`.
___

<a id="vec2_1"></a>
- vec2 ( float x ) ( [vec2](#vec2) )

Returns a new vec2 with both `x` and `y` being equals to the given `x`.
___

<a id="vec2_2"></a>
- vec2 ( float x, float y ) ( [vec2](#vec2) )

Returns a new vec2 from the given `x` and `y`.
___

<a id="vec2_zero"></a>
- vec2_zero ( ) ( [vec2](#vec2) )

Returns a new vec2 which equals `vec2(0., 0.)`.
___

<a id="vec2_half"></a>
- vec2_half ( ) ( [vec2](#vec2) )

Returns a new vec2 which equals `vec2(.5, .5)`.
___

<a id="vec2_one"></a>
- vec2_one ( ) ( [vec2](#vec2) )

Returns a new vec2 which equals `vec2(1., 1.)`.
___

<a id="vec2_up"></a>
- vec2_up ( ) ( [vec2](#vec2) )

Returns a new vec2 which equals `vec2(0., 1.)`.
___

<a id="vec2_down"></a>
- vec2_down ( ) ( [vec2](#vec2) )

Returns a new vec2 which equals `vec2(0., -1.)`.
___

<a id="vec2_right"></a>
- vec2_right ( ) ( [vec2](#vec2) )

Returns a new vec2 which equals `vec2(1., 0.)`.
___

<a id="vec2_left"></a>
- vec2_left ( ) ( [vec2](#vec2) )

Returns a new vec2 which equals `vec2(-1., 0.)`.
___

<a id="vec2_angled"></a>
- vec2_angled ( float angle ) ( [vec2](#vec2) )

Returns a new vec2 rotated by `angle` radians.
___

<a id="abs"></a>
- abs ( [vec2](#vec2) this ) ( [vec2](#vec2) )

Returns a new vec2 with its components positive.
___

<a id="angle"></a>
- angle ( [vec2](#vec2) this ) ( float )

Returns the angle in radians that the vector is forming.
___

<a id="approach"></a>
- approach ( [vec2](#vec2) from, [vec2](#vec2) to, float step ) ( [vec2](#vec2) )

Returns a vec2 that adds `step` to `from` up to `to`.
___

<a id="ceil"></a>
- ceil ( [vec2](#vec2) this ) ( [vec2](#vec2) )

Returns a new vec2 with all its components rounded up.
___

<a id="cross"></a>
- cross ( [vec2](#vec2) v1, [vec2](#vec2) v2 ) ( float )

Returns the cross product of two vectors.
___

<a id="distance"></a>
- distance ( [vec2](#vec2) from, [vec2](#vec2) to ) ( float )

Returns the distance between two vectors.
___

<a id="distance2"></a>
- distance2 ( [vec2](#vec2) from, [vec2](#vec2) to ) ( float )

Returns the squared distance between two vectors.
___

<a id="dot"></a>
- dot ( [vec2](#vec2) v1, [vec2](#vec2) v2 ) ( float )

Returns the dot product of two vectors.
___

<a id="floor"></a>
- floor ( [vec2](#vec2) this ) ( [vec2](#vec2) )

Returns a new vec2 with all its components rounded down.
___

<a id="lerp"></a>
- lerp ( [vec2](#vec2) from, [vec2](#vec2) to, float t ) ( [vec2](#vec2) )

Returns an interpolated vec2 between `from` and `to` with a factor `t` between 0 and 1.
___

<a id="magnitude"></a>
- magnitude ( [vec2](#vec2) this ) ( float )

Returns the vector's length.
___

<a id="magnitude2"></a>
- magnitude2 ( [vec2](#vec2) this ) ( float )

Returns the vector's squared length.
___

<a id="normal"></a>
- normal ( [vec2](#vec2) this ) ( [vec2](#vec2) )

Returns the normal of the vector.
___

<a id="normalize"></a>
- normalize ( [vec2](#vec2) this ) ( [vec2](#vec2) )

Returns the vector with a magnitude of 1.
___

<a id="normalized"></a>
- normalized ( [vec2](#vec2) this ) ( [vec2](#vec2) )

Returns a new vec2 of the vector with a magnitude of 1.
___

<a id="print"></a>
- print ( [vec2](#vec2) this ) ( )

Display the vector.
___

<a id="reflect"></a>
- reflect ( [vec2](#vec2) this, [vec2](#vec2) normal ) ( [vec2](#vec2) )

Returns a new vec2 of the vector bouncing off a surface represented by its `normal`.
___

<a id="refract"></a>
- refract ( [vec2](#vec2) this, [vec2](#vec2) normal, float theta ) ( [vec2](#vec2) )

Returns a new vec2 of the vector deviated by a surface represented by its `normal` with a factor `theta`.
___

<a id="rotate"></a>
- rotate ( [vec2](#vec2) this, float angle ) ( [vec2](#vec2) )

Returns the vector rotated by `angle` radians.
___

<a id="rotated"></a>
- rotated ( [vec2](#vec2) this, float angle ) ( [vec2](#vec2) )

Returns a new vec2 of the vector rotated by `angle` radians.
___

<a id="round"></a>
- round ( [vec2](#vec2) this ) ( [vec2](#vec2) )

Returns a new vec2 with all its components rounded to the nearest integer.
___

<a id="sign"></a>
- sign ( [vec2](#vec2) this ) ( [vec2](#vec2) )

Returns a new vec2 in which each components equals `1.` if the value is positive or `-1.` if the value is negative.
___

<a id="sum"></a>
- sum ( [vec2](#vec2) this ) ( float )

Adds the components of the vector together.
___

<a id="unpack"></a>
- unpack ( [vec2](#vec2) this ) ( float, float )

Returns the components of the vector.
___

<a id="zero"></a>
- zero? ( [vec2](#vec2) this ) ( bool )

Returns `true` if the vector is eaquals to `vec2(0., 0.)`.
___