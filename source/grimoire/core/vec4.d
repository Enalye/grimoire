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

module grimoire.core.vec4;

import grimoire.core.vec2;

struct Vec4(T) {
	static assert(__traits(isArithmetic, T));

	static if(__traits(isUnsigned, T)) {
		enum one = Vec4!T(1u, 1u, 1u, 1u);
		enum zero = Vec4!T(0u, 0u, 0u, 0u);
	}
	else {
		static if(__traits(isFloating, T)) {
			enum one = Vec4!T(1f, 1f, 1f, 1f);
			enum half = Vec4!T(.5f, .5f, .5f, .5f);
			enum zero = Vec4!T(0f, 0f, 0f, 0f);
		}
		else {
			enum one = Vec4!T(1, 1, 1, 1);
			enum zero = Vec4!T(0, 0, 0, 0);
		}
	}

	T x, y, z, w;

	@property {
		Vec2!T xy() const { return Vec2!T(x, y); }
		Vec2!T xy(Vec2!T v) {
			x = v.x;
			y = v.y;
			return v;
		}

		Vec2!T zw() const { return Vec2!T(z, w); }
		Vec2!T zw(Vec2!T v) {
			z = v.x;
			w = v.y;
			return v;
		}
	}

	this(T nx, T ny, T nz, T nw) {
		x = nx;
		y = ny;
		z = nz;
		w = nw;
	}

	this(Vec2!T nxy, Vec2!T nzw) {
		x = nxy.x;
		y = nxy.y;
		z = nzw.x;
		w = nzw.y;
	}

	void set(T nx, T ny, T nz, T nw) {
		x = nx;
		y = ny;
		z = nz;
		w = nw;
	}

	void set(Vec2!T nxy, Vec2!T nzw) {
		x = nxy.x;
		y = nxy.y;
		z = nzw.x;
		w = nzw.y;
	}

	bool opEquals(const Vec4!T v) const {
		return (x == v.x) && (y == v.y) && (z == v.z) && (w == v.w);
	}

	Vec4!T opUnary(string op)() const {
		return mixin("Vec4!T(" ~ op ~ " x, " ~ op ~ " y, " ~ op ~ " z, " ~ op ~ " w)");
	}

	Vec4!T opBinary(string op)(const Vec4!T v) const {
		return mixin("Vec4!T(x " ~ op ~ " v.x, y " ~ op ~ " v.y, z " ~ op ~ " v.z, w " ~ op ~ " v.w)");
	}

	Vec4!T opBinary(string op)(T s) const {
		return mixin("Vec4!T(x " ~ op ~ " s, y " ~ op ~ " s, z " ~ op ~ " s, w " ~ op ~ " s)");
	}

	Vec4!T opBinaryRight(string op)(T s) const {
		return mixin("Vec4!T(s " ~ op ~ " x, s " ~ op ~ " y, s " ~ op ~ " z, s " ~ op ~ "w)");
	}

	Vec4!T opOpAssign(string op)(Vec4!T v) {
		mixin("x = x" ~ op ~ "v.x;y = y" ~ op ~ "v.y;z = z" ~ op ~ "v.z;w = w" ~ op ~ "v.w;");
		return this;
	}

	Vec4!T opOpAssign(string op)(T s) {
		mixin("x = x" ~ op ~ "s;y = y" ~ op ~ "s;z = z" ~ op ~ "s;w = w" ~ op ~ "s;");
		return this;
	}

	Vec4!U opCast(V: Vec4!U, U)() const {
		return V(cast(U)x, cast(U)y, cast(U)z, cast(U)w);
	}
}

alias Vec4f = Vec4!(float);
alias Vec4i = Vec4!(int);
alias Vec4u = Vec4!(uint);