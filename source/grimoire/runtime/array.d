module grimoire.runtime.array;

import grimoire.assembly;

import grimoire.runtime.value;

/// Runtime array, can only hold one subtype.
final class GrArray {
    /// Payload
    package {
        GrValue[] _data;
    }

    this() {
    }

    this(GrValue[] value) {
        _data = value;
    }

    this(GrInt initialSize) {
        _data.reserve(initialSize);
    }

    @property {
        pragma(inline) GrInt size() const {
            return cast(GrInt) _data.length;
        }

        pragma(inline) GrBool isEmpty() const {
            return _data.length == 0;
        }

        pragma(inline) GrValue[] data() {
            return _data;
        }
    }

    pragma(inline) GrValue opIndex(GrInt index) {
        return _data[index];
    }

    pragma(inline) GrValue opIndexAssign(GrValue value, GrInt index) {
        return _data[index] = value;
    }

    pragma(inline) void opAssign(GrValue[] values) {
        _data = values;
    }

    pragma(inline) void clear() {
        _data.length = 0;
    }

    pragma(inline) void resize(GrInt size_) {
        _data.length = size_;
    }

    pragma(inline) GrValue first() {
        return _data[0];
    }

    pragma(inline) GrValue last() {
        return _data[$ - 1];
    }

    pragma(inline) void push(GrValue value) {
        _data ~= value;
    }

    pragma(inline) GrValue pop() {
        GrValue value = _data[$ - 1];
        _data.length--;
        return value;
    }

    pragma(inline) GrValue[] pop(GrInt size_) {
        if (_data.length < size_) {
            size_ = cast(GrInt) _data.length;
        }
        GrValue[] slice = _data[$ - size_ .. $];
        _data.length -= size_;
        return slice;
    }

    pragma(inline) void unshift(GrValue value) {
        _data = value ~ _data;
    }

    pragma(inline) GrValue shift() {
        GrValue value = _data[0];
        _data = _data[1 .. $];
        return value;
    }

    pragma(inline) GrValue[] shift(GrInt size_) {
        if (_data.length < size_) {
            size_ = cast(GrInt) _data.length;
        }
        GrValue[] slice = _data[0 .. size_];
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

    pragma(inline) GrValue[] slice(GrInt index1, GrInt index2) {
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

    pragma(inline) GrValue[] reverse() {
        import std.algorithm.mutation : reverse;

        return _data.reverse();
    }

    pragma(inline) void insert(GrInt index, GrValue value) {
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

    pragma(inline) void sortByInt() {
        import std.algorithm.sorting : sort;

        _data.sort!((a, b) => a.getInt() < b.getInt())();
    }

    pragma(inline) void sortByReal() {
        import std.algorithm.sorting : sort;

        _data.sort!((a, b) => a.getReal() < b.getReal())();
    }

    pragma(inline) void sortByString() {
        import std.algorithm.sorting : sort;

        _data.sort!((a, b) => a.getString() < b.getString())();
    }

    pragma(inline) GrInt indexOf(GrValue value) {
        for (GrInt index; index < _data.length; ++index) {
            if (_data[index] == value)
                return index;
        }
        return -1;
    }

    pragma(inline) GrInt lastIndexOf(GrValue value) {
        for (GrInt index = (cast(GrInt) _data.length) - 1; index > 0; --index) {
            if (_data[index] == value)
                return index;
        }
        return -1;
    }

    pragma(inline) GrBool contains(GrValue value) {
        for (GrInt index; index < _data.length; ++index) {
            if (_data[index] == value)
                return true;
        }
        return false;
    }
}
