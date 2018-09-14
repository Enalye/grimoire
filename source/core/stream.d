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

module core.stream;

import std.array;
import std.conv;
import std.string;
import std.bitmanip;

class OutStream {
	private Appender!(const ubyte[]) _buffer;

	this() {
		_buffer = appender!(const ubyte[])();
	}

	@property {
		const(ubyte)[] data() const { return _buffer.data; }
		size_t length() const { return _buffer.data.length; }
	}

	void write(string values) {
		write!(char[])(cast(char[])values);
	}

	void write(wstring values) {
		write!(wchar[])(cast(wchar[])values);
	}

	void write(dstring values) {
		write!(dchar[])(cast(dchar[])values);
	}

	void write(T : T[])(T[] values) {
		//Values size.
		ubyte[ushort.sizeof] sizeValues = nativeToBigEndian!ushort(cast(ushort)values.length);
		foreach(ubyte b; sizeValues)
			_buffer.append!ubyte(b);
		//Values array.
		foreach(T v; values)
			foreach(ubyte b; nativeToBigEndian(v))
				_buffer.append!ubyte(b);
	}

	void write(T)(T value) {
		//Value size.
		ubyte[ushort.sizeof] sizeValues = nativeToBigEndian!ushort(1u);
		foreach(ubyte b; sizeValues)
			_buffer.append!ubyte(b);
		//Value array.
		foreach(ubyte b; nativeToBigEndian(value))
			_buffer.append!ubyte(b);
	}
}

class InStream {
	private ubyte[] _buffer;

	@property {
		void data(ubyte[] buffer) { _buffer = buffer; }
		ref ubyte[] data() { return _buffer; }

		ushort length(ushort newLength) { return _buffer.length = newLength; }
		size_t length() const { return _buffer.length; }
	}

	void set(const ubyte[] buffer) {
		_buffer = buffer.dup;
	}

	string read(T : string)() {
		return read!(char[])();
	}

	wstring read(T : wstring)() {
		return read!(wchar[])();
	}

	dstring read(T : dstring)() {
		return read!(dchar[])();
	}

	T[] read(T : T[])() {
		T[] values;
		ushort size = _buffer.read!ushort();
		if(size == 0)
			return values;
		foreach(_; 0..size)
			values ~= _buffer.read!T();
		return values;
	}

	T read(T)() {
		ushort size = _buffer.read!ushort();
		if(size != 1uL)
			throw new Exception("Stream data does not match.");
		return _buffer.read!T();
	}
}

unittest {
	auto o = new OutStream;
	auto i = new InStream;

	o.write!int(179);
	o.write!(int[])([1,2,3,0,4,5]);
	o.write!string("hello");
	o.write!bool(true);
	i.set(o.data);

	assert(i.read!int() == 179, "Stream module failure");
	assert(i.read!(int[])() == [1,2,3,0,4,5], "Stream module failure");
	assert(i.read!string() == "hello", "Stream module failure");
	assert(i.read!bool() == true, "Stream module failure");
}