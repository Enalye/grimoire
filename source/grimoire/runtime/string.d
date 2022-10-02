/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.string;

import std.string;
import std.conv : to;

import grimoire.assembly;
import grimoire.runtime.value;

/// Runtime string
final class GrString {
    /// Payload
    package {
        GrStr _data;
    }

    this() {
    }

    this(GrStr value) {
        _data = value;
    }

    @property {
        pragma(inline) GrInt size() const {
            return cast(GrInt) _data.length;
        }

        pragma(inline) GrBool isEmpty() const {
            return _data.length == 0;
        }

        pragma(inline) GrStr data() {
            return _data;
        }
    }

    /*pragma(inline) GrStr opIndex(GrInt index) {
        return _data[index];
    }

    pragma(inline) GrStr opIndexAssign(GrStr value, GrInt index) {
        return _data[index] = value;
    }*/

    pragma(inline) void opAssign(GrStr values) {
        _data = values;
    }

    pragma(inline) void clear() {
        _data.length = 0;
    }

    pragma(inline) void resize(GrInt size_) {
        _data.length = size_;
    }

    pragma(inline) GrStr first() {
        return to!GrStr(_data[0]);
    }

    pragma(inline) GrStr last() {
        return to!GrStr(_data[$ - 1]);
    }

    pragma(inline) void push(GrStr value) {
        _data ~= value;
    }

    pragma(inline) GrStr pop() {
        GrStr value = to!GrStr(_data[$ - 1]);
        _data.length--;
        return value;
    }

    pragma(inline) GrStr pop(GrInt size_) {
        if (_data.length < size_) {
            size_ = cast(GrInt) _data.length;
        }
        GrStr slice = _data[$ - size_ .. $];
        _data.length -= size_;
        return slice;
    }

    pragma(inline) void unshift(GrStr value) {
        _data = value ~ _data;
    }

    pragma(inline) GrStr shift() {
        GrStr value = to!GrStr(_data[0]);
        _data = _data[1 .. $];
        return value;
    }

    pragma(inline) GrStr shift(GrInt size_) {
        if (_data.length < size_) {
            size_ = cast(GrInt) _data.length;
        }
        GrStr slice = _data[0 .. size_];
        _data = _data[size_ .. $];
        return slice;
    }

    pragma(inline) void remove(GrInt index) {
        if (index < 0)
            index = (cast(GrInt) _data.length) + index;
        if (!_data.length || index >= _data.length || index < 0) {
            return;
        }
        if (index + 1 == _data.length) {
            _data.length--;
            return;
        }
        if (index == 0) {
            _data = _data[1 .. $];
            return;
        }
        _data = _data[0 .. index] ~ _data[index + 1 .. $];
    }

    pragma(inline) void remove(GrInt index1, GrInt index2) {
        if (index1 < 0)
            index1 = (cast(GrInt) _data.length) + index1;
        if (index2 < 0)
            index2 = (cast(GrInt) _data.length) + index2;

        if (index2 < index1) {
            const GrInt temp = index1;
            index1 = index2;
            index2 = temp;
        }

        if (!_data.length || index1 >= _data.length || index2 < 0) {
            return;
        }

        if (index1 < 0)
            index1 = 0;
        if (index2 >= _data.length)
            index2 = (cast(GrInt) _data.length) - 1;

        if (index1 == 0 && (index2 + 1) == _data.length) {
            _data.length = 0;
            return;
        }
        if (index1 == 0) {
            _data = _data[(index2 + 1) .. $];
            return;
        }
        if ((index2 + 1) == _data.length) {
            _data = _data[0 .. index1];
            return;
        }
        _data = _data[0 .. index1] ~ _data[(index2 + 1) .. $];
    }

    pragma(inline) GrStr slice(GrInt index1, GrInt index2) {
        if (index1 < 0)
            index1 = (cast(GrInt) _data.length) + index1;
        if (index2 < 0)
            index2 = (cast(GrInt) _data.length) + index2;

        if (index2 < index1) {
            const GrInt temp = index1;
            index1 = index2;
            index2 = temp;
        }

        if (!_data.length || index1 >= _data.length || index2 < 0)
            return [];

        if (index1 < 0)
            index1 = 0;
        if (index2 >= _data.length)
            index2 = (cast(GrInt) _data.length - 1);

        if (index1 == 0 && (index2 + 1) == _data.length)
            return _data;

        return _data[index1 .. index2 + 1];
    }

    pragma(inline) GrStr reverse() {
        import std.algorithm.mutation : reverse;

        return _data.dup.reverse();
    }

    pragma(inline) void insert(GrInt index, GrStr value) {
        if (index >= _data.length) {
            _data ~= value;
            return;
        }
        if (index < 0)
            index = (cast(GrInt) _data.length) + index;

        if (index <= 0) {
            _data = value ~ _data;
            return;
        }
        if (index + 1 == _data.length) {
            _data = _data[0 .. index] ~ value ~ _data[$ - 1];
            return;
        }
        _data = _data[0 .. index] ~ value ~ _data[index .. $];
    }

    pragma(inline) GrInt indexOf(GrStr value) {
        return cast(GrInt) _data.indexOf(value);
    }

    pragma(inline) GrInt lastIndexOf(GrStr value) {
        return cast(GrInt) _data.lastIndexOf(value);
    }

    pragma(inline) GrBool contains(GrStr value) {
        return _data.indexOf(value) != -1;
    }
}
