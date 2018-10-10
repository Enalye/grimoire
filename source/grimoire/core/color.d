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

module grimoire.core.color;

import std.math;
import std.typecons;
import std.random;
public import std.algorithm.comparison: clamp;

import grimoire.core.stream;
import grimoire.core.vec4;

struct Color {
	static const Color clear = Color(0f, 0f, 0f, 0f);
	static const Color red = Color(1f, 0f, 0f);
	static const Color lime = Color(0f, 1f, 0f);
	static const Color blue = Color(0f, 0f, 1f);
	static const Color white = Color(1f, 1f, 1f);
	static const Color black = Color(0f, 0f, 0f);
	static const Color yellow = Color(1f, 1f, 0f);
	static const Color cyan = Color(0f, 1f, 1f);
	static const Color magenta = Color(1f, 0f, 1f);
	static const Color silver = Color(.75f, .75f, .75f);
	static const Color gray = Color(.5f, .5f, .5f);
	static const Color maroon = Color(.5f, 0f, 0f);
	static const Color olive = Color(.5f, .5f, 0f);
	static const Color green = Color(0f, 5f, 0f);
	static const Color purple = Color(.5f, 0f, .5f);
	static const Color teal = Color(.5f, 0f, .5f);
	static const Color navy = Color(0f, 0f, .5f);
	static const Color pink = Color(1f, .75f, .8f);

	static @property {
		Color random() {
			return Color(uniform01(), uniform01(), uniform01(), 1f);
		}
	}

	@property {
		float r() const { return _r; }
		float r(float red) {
			return _r = clamp(red, 0f, 1f);
		}

		float g() const { return _g; }
		float g(float green) {
			return _g = clamp(green, 0f, 1f);
		}

		float b() const { return _b; }
		float b(float blue) {
			return _b = clamp(blue, 0f, 1f);
		}

		float a() const { return _a; }
		float a(float alpha) {
			return _a = clamp(alpha, 0f, 1f);
		}

		Vec4f rgba() const { return Vec4f(_r, _g, _b, _a); }
		Vec4f rgba(Vec4f v) {
			set(v.x, v.y, v.z, v.w);
			return v;
		}

		/+ Todo: Need Vec3
		Vec3f rgb() const { return Vec3f(_r, _g, _b); }
		Vec3f rgb(Vec3f v) {
			set(v.x, v.y, v.z);
			return v;
		}+/
	}

	private {
		float _r = 0f, _g = 0f, _b = 0f, _a = 0f;
	}

	this(float red, float green, float blue, float alpha = 1f) {
		_r = clamp(red, 0f, 1f);
		_g = clamp(green, 0f, 1f);
		_b = clamp(blue, 0f, 1f);
		_a = clamp(alpha, 0f, 1f);
	}

	this(Vec4f v) {
		_r = clamp(v.x, 0f, 1f);
		_g = clamp(v.y, 0f, 1f);
		_b = clamp(v.z, 0f, 1f);
		_a = clamp(v.w, 0f, 1f);
	}

	void set(float red, float green, float blue, float alpha = 1f) {
		_r = clamp(red, 0f, 1f);
		_g = clamp(green, 0f, 1f);
		_b = clamp(blue, 0f, 1f);
		_a = clamp(alpha, 0f, 1f);
	}

	Color opBinary(string op)(const Color c) const {
		return mixin("Color(_r " ~ op ~ " c._r, _g " ~ op ~ " c._g, _b " ~ op ~ " c._b, _a " ~ op ~ " c._a)");
	}

	Color opBinary(string op)(float s) const {
		return mixin("Color(_r " ~ op ~ " s, _g " ~ op ~ " s, _b " ~ op ~ " s, _a " ~ op ~ " s)");
	}

	Color opBinaryRight(string op)(float s) const {
		return mixin("Color(s " ~ op ~ " _r, s " ~ op ~ " _g, s " ~ op ~ " _b, s " ~ op ~ " _a)");
	}

	Color opOpAssign(string op)(const Color c) {
		mixin("_r = clamp(_r " ~ op ~ "c._r, 0f, 1f);_g = clamp(_g " ~ op ~ "c._g, 0f, 1f);_b = clamp(_b " ~ op ~ "c._b, 0f, 1f);_a = clamp(_a " ~ op ~ "c._a, 0f, 1f);");
		return this;
	}

	Color opOpAssign(string op)(float s) {
		mixin("s = clamp(s, 0f, 1f);_r = _r" ~ op ~ "s;_g = _g" ~ op ~ "s;_b = _b" ~ op ~ "s;_a = _a" ~ op ~ "s;");
		return this;
	}

	void load(InStream stream) {
		_r = stream.read!float;
		_g = stream.read!float;
		_b = stream.read!float;
		_a = stream.read!float;
	}

	void save(OutStream stream) {
		stream.write!float(_r);
		stream.write!float(_g);
		stream.write!float(_b);
		stream.write!float(_a);
	}
}

Color mix(Color c1, Color c2) {
	return Color((c1._r + c2._r) / 2f, (c1._g + c2._g) / 2f, (c1._b + c2._b) / 2f, (c1._a + c2._a) / 2f);
}