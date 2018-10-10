/**
Grimoire
Copyright (c) 2017 Enalye

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising
from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product documentation would be appreciated but
	   is not required.

	2. Altered source versions must be plainly marked as such,
	   and must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source distribution.
*/

module grimoire.core.util;

public import std.math;

import grimoire.core.vec2;

enum sqrt2_2 = std.math.sqrt(2.0) / 2.0;
enum pi2 = PI * 2f;

T lerp(T)(T a, T b, float t) {
	return t * b + (1f - t) * a;
}

float rlerp(float a, float b, float v) {
	return (v - a) / (b - a);
}

float angleBetween(float a, float b) {
	float delta = (b - a) % 360f;
	return ((2f * delta) % 360f) - delta;
}

float angleLerp(float a, float b, float t) {
	return a + angleBetween(a, b) * t;
}

Vec2f scaleToFit(Vec2f src, Vec2f dst) {
	float scale;
	if(dst.x / dst.y > src.x / src.y)
		scale = dst.y / src.y;
	else
		scale = dst.x / src.x;
	return src * scale;
}