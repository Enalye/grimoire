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

module core.vec2;

import std.math;

import core.vec3;
import core.vec4;

enum double degToRad = std.math.PI / 180.0;
enum double radToDeg = 180.0 / std.math.PI;

struct Vec2(T) {
	static assert(__traits(isArithmetic, T));

	static if(__traits(isUnsigned, T)) {
		enum one = Vec2!T(1u, 1u);
		enum zero = Vec2!T(0u, 0u);
	}
	else {
		static if(__traits(isFloating, T)) {
			enum one = Vec2!T(1f, 1f);
			enum half = Vec2!T(.5f, .5f);
			enum zero = Vec2!T(0f, 0f);
		}
		else {
			enum one = Vec2!T(1, 1);
			enum zero = Vec2!T(0, 0);
		}
	}

	T x, y;

	void set(T nx, T ny) {
		x = nx;
		y = ny;
	}

	T distance(Vec2!T v) {
		static if(__traits(isUnsigned, T))
			alias V = int;
		else
			alias V = T;

		V px = x - v.x,
		  py = y - v.y;

		static if(__traits(isFloating, T))
			return std.math.sqrt(px * px + py * py);
		else
			return cast(T)std.math.sqrt(cast(float)(px * px + py * py));
	}

	T distanceSquared(Vec2!T v) const {
		static if(__traits(isUnsigned, T))
			alias V = int;
		else
			alias V = T;

		V px = x - v.x,
		  py = y - v.y;

		return px * px + py * py;
	}

	T dot(const Vec2!T v) const {
		return x * v.x + y * v.y;
	}

	T cross(const Vec2!T v) const {
		static if(__traits(isUnsigned, T))
			return cast(int)(x * v.y) - cast(int)(y * v.x);
		else
			return (x * v.y) - (y * v.x);
	}

	Vec2!T normal() const {
		return Vec2!T(-y, x);
	}

	Vec2!T reflect(const Vec2!T v) const {
		static if(__traits(isFloating, T)) {
			T dotNI2 = 2.0 * x * v.x + y * v.y;
			return Vec2!T(cast(T)(x - dotNI2 * v.x), cast(T)(y - dotNI2 * v.y));
		}
		else {
			T dotNI2 = 2 * x * v.x + y * v.y;
			static if(__traits(isUnsigned, T))
				return Vec2!T(cast(int)(x) - cast(int)(dotNI2 * v.x), cast(int)(y) - cast(int)(dotNI2 * v.y));
			else
				return Vec2!T(x - dotNI2 * v.x, y - dotNI2 * v.y);
		}
	}

	Vec2!T refract(const Vec2!T v, float eta) const {
		static if(__traits(isFloating, T)) {
			T dotNI = (x * v.x + y * v.y);
			T k = 1.0 - eta * eta * (1.0 - dotNI * dotNI);
			if (k < .0)
				return Vec2!T(T.init, T.init);
			else {
				double s = (eta * dotNI + sqrt(k));
				return Vec2!T(eta * x - s * v.x, eta * y - s * v.y);
			}
		}
		else {
			float dotNI = cast(float)(x * v.x + y * v.y);
			float k = 1.0f - eta * eta * (1.0f - dotNI * dotNI);
			if (k < 0f)
				return Vec2!T(T.init, T.init);
			else {
				float s = (eta * dotNI + sqrt(k));
				return Vec2!T(cast(T)(eta * x - s * v.x), cast(T)(eta * y - s * v.y));
			}
		}
	}

	Vec2!T abs() const {
		static if(__traits(isFloating, T))
			return Vec2!T(x < .0 ? -x : x, y < .0 ? -y : y);
		else static if(__traits(isUnsigned, T))
			return Vec2!T(x < 0U ? -x : x, y < 0U ? -y : y);
		else
			return Vec2!T(x, y);
	}

	Vec2!T floor() const {
		static if(__traits(isFloating, T))
			return Vec2!T(std.math.floor(x), std.math.floor(y));
		else
			return this;
	}

	Vec2!T ceil() const {
		static if(__traits(isFloating, T))
			return Vec2!T(std.math.ceil(x), std.math.ceil(y));
		else
			return this;
	}

	Vec2!T round() const {
		static if(__traits(isFloating, T))
			return Vec2!T(std.math.round(x), std.math.round(y));
		else
			return this;
	}

	static if(__traits(isFloating, T)) {
		T angle() const {
			return std.math.atan2(y, x) * radToDeg;
		}
	
		Vec2!T rotate(T angle) {
			T radians = angle * degToRad;
			T px = x, py = y;
			T c = std.math.cos(radians);
			T s = std.math.sin(radians);
			x = px * c - py * s;
			y = px * s + py * c;
			return this;
		}

		Vec2!T rotated(T angle) const {
			T radians = angle * degToRad;
			T c = std.math.cos(radians);
			T s = std.math.sin(radians);
			return Vec2f(x * c - y * s, x * s + y * c);
		}

		static Vec2!T angled(T angle) {
			T radians = angle * degToRad;
			return Vec2f(std.math.cos(radians), std.math.sin(radians));
		}
	}

	T sum() const {
		return x + y;
	}

	T length() const {
		static if(__traits(isFloating, T))
			return std.math.sqrt(x * x + y * y);
		else
			return cast(T)std.math.sqrt(cast(float)(x * x + y * y));
	}

	T lengthSquared() const  {
		return x * x + y * y;
	}

	void normalize() {
		static if(__traits(isFloating, T))
			T len = std.math.sqrt(x * x + y * y);
		else
			T len = cast(T)std.math.sqrt(cast(float)(x * x + y * y));

		x /= len;
		y /= len;
	}

	Vec2!T normalized() const  {
		static if(__traits(isFloating, T))
			T len = std.math.sqrt(x * x + y * y);
		else
			T len = cast(T)std.math.sqrt(cast(float)(x * x + y * y));

		return Vec2!T(x / len, y / len);
	}

	Vec2!T clamp(const Vec2!T min, const Vec2!T max) const {
		Vec2!T v = {x, y};
		if (v.x < min.x) v.x = min.x;
		else if(v.x > max.x) v.x = max.x;
		if (v.y < min.y) v.y = min.y;
		else if (v.y > max.y) v.y = max.y;
		return v;
	}

	Vec2!T clamp(const Vec4!T clip) const {
		Vec2!T v = {x, y};
		if (v.x < clip.x) v.x = clip.x;
		else if(v.x > clip.z) v.x = clip.z;
		if (v.y < clip.y) v.y = clip.y;
		else if (v.y > clip.w) v.y = clip.w;
		return v;
	}

	bool isBetween(const Vec2!T min, const Vec2!T max) const {
		if (x < min.x) return false;
		else if (x > max.x) return false;
		if (y < min.y) return false;
		else if (y > max.y) return false;
		return true;
	}

	static if(__traits(isFloating, T)) {
		Vec2!T lerp(Vec2!T end, float t) const {
			return (this * (1.0 - t)) + (end * t);
		}

		Vec2!T fit(const Vec2!T v) const {
			Vec2!T u = {v.x / x, v.y / y};
			if(u.x < u.y)
				return Vec2!T(v.x, v.x);
			else
				return Vec2!T(v.y, v.y);
		}
	}

	bool opEquals(const Vec2!T v) const {
		return (x == v.x) && (y == v.y);
	}

	Vec2!T opUnary(string op)() const {
		return mixin("Vec2!T(" ~ op ~ " x, " ~ op ~ " y)");
	}

	Vec2!T opBinary(string op)(const Vec2!T v) const {
		return mixin("Vec2!T(x " ~ op ~ " v.x, y " ~ op ~ " v.y)");
	}

	Vec2!T opBinary(string op)(T s) const {
		return mixin("Vec2!T(x " ~ op ~ " s, y " ~ op ~ " s)");
	}

	Vec2!T opBinaryRight(string op)(T s) const {
		return mixin("Vec2!T(s " ~ op ~ " x, s " ~ op ~ " y)");
	}

	Vec2!T opOpAssign(string op)(Vec2!T v) {
		mixin("x = x" ~ op ~ "v.x;y = y" ~ op ~ "v.y;");
		return this;
	}

	Vec2!T opOpAssign(string op)(T s) {
		mixin("x = x" ~ op ~ "s;y = y" ~ op ~ "s;");
		return this;
	}

	Vec2!U opCast(V: Vec2!U, U)() const {
		return V(cast(U)x, cast(U)y);
	}
}

alias Vec2f = Vec2!(float);
alias Vec2i = Vec2!(int);
alias Vec2u = Vec2!(uint);