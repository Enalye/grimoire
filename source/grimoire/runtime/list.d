/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.runtime.list;

import grimoire.assembly;

import grimoire.runtime.value;
import grimoire.runtime.string;
import grimoire.runtime.object;
import grimoire.runtime.channel;

/// Collection contenant plusieurs valeurs
final class GrList {
    package {
        /// Liste des valeurs
        GrValue[] _data;
    }

    this() {
    }

    this(GrValue[] value) {
        _data = value;
    }

    this(GrUInt initialSize) {
        _data.reserve(initialSize);
    }

    @property {
        pragma(inline) GrUInt size() const {
            return cast(GrUInt) _data.length;
        }

        pragma(inline) GrBool isEmpty() const {
            return _data.length == 0;
        }
    }

    pragma(inline) GrValue opIndex(GrUInt index) {
        return _data[index];
    }

    pragma(inline) GrValue opIndexAssign(GrValue value, GrUInt index) {
        return _data[index] = value;
    }

    pragma(inline) void opAssign(GrValue[] values) {
        _data = values;
    }

    pragma(inline) GrValue[] getValues() {
        return _data;
    }

    pragma(inline) GrBool[] getBools() {
        GrBool[] values;
        foreach (GrValue value; _data)
            values ~= value.getBool();
        return values;
    }

    pragma(inline) GrInt[] getInts() {
        GrInt[] values;
        foreach (GrValue value; _data)
            values ~= value.getInt();
        return values;
    }

    pragma(inline) GrUInt[] getUInts() {
        GrUInt[] values;
        foreach (GrValue value; _data)
            values ~= value.getUInt();
        return values;
    }

    pragma(inline) GrChar[] getChars() {
        GrChar[] values;
        foreach (GrValue value; _data)
            values ~= value.getChar();
        return values;
    }

    pragma(inline) T[] getEnums(T)() {
        T[] values;
        foreach (GrValue value; _data)
            values ~= value.getEnum!T();
        return values;
    }

    pragma(inline) GrFloat[] getFloats() {
        return cast(GrFloat[]) _data;
    }

    pragma(inline) GrString[] getStrings() {
        return cast(GrString[]) cast(GrPointer[]) _data;
    }

    pragma(inline) GrList[] getLists() {
        return cast(GrList[]) cast(GrPointer[]) _data;
    }

    pragma(inline) GrChannel[] getChannels() {
        return cast(GrChannel[]) cast(GrPointer[]) _data;
    }

    pragma(inline) GrObject[] getObjects() {
        return cast(GrObject[]) cast(GrPointer[]) _data;
    }

    pragma(inline) T[] getNatives(T)() {
        return cast(T[]) cast(GrPointer[]) _data;
    }

    pragma(inline) void setValues(GrValue[] values) {
        _data = values;
    }

    pragma(inline) void setBools(GrBool[] values) {
        _data.length = values.length;
        for (size_t i; i < _data.length; ++i)
            _data[i].setBool(values[i]);
    }

    pragma(inline) void setInts(GrInt[] values) {
        _data.length = values.length;
        for (size_t i; i < _data.length; ++i)
            _data[i].setInt(values[i]);
    }

    pragma(inline) void setUInts(GrUInt[] values) {
        _data.length = values.length;
        for (size_t i; i < _data.length; ++i)
            _data[i].setUInt(values[i]);
    }

    pragma(inline) void setChars(GrChar[] values) {
        _data.length = values.length;
        for (size_t i; i < _data.length; ++i)
            _data[i].setChar(values[i]);
    }

    pragma(inline) void setEnums(T)(T[] values) {
        _data.length = values.length;
        for (size_t i; i < _data.length; ++i)
            _data[i].setEnum!T(values[i]);
    }

    pragma(inline) void setFloats(GrFloat[] values) {
        _data = cast(GrValue[]) values;
    }

    pragma(inline) void setStrings(GrString[] values) {
        _data = cast(GrValue[]) values;
    }

    pragma(inline) void setLists(GrList[] values) {
        _data = cast(GrValue[]) values;
    }

    pragma(inline) void setChannels(GrChannel[] values) {
        _data = cast(GrValue[]) values;
    }

    pragma(inline) void setObjects(GrObject[] values) {
        _data = cast(GrValue[]) values;
    }

    pragma(inline) void setNatives(T)(T[] values) {
        _data = cast(GrValue[]) values;
    }

    pragma(inline) void clear() {
        _data.length = 0;
    }

    pragma(inline) void resize(GrUInt size_, GrValue defaultValue) {
        GrUInt oldSize = cast(GrUInt) _data.length;
        _data.length = size_;

        while (oldSize < size_) {
            _data[oldSize] = defaultValue;
            oldSize++;
        }
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

    pragma(inline) GrValue[] pop(GrUInt size_) {
        if (_data.length < size_) {
            size_ = cast(GrUInt) _data.length;
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

    pragma(inline) GrValue[] shift(GrUInt size_) {
        if (_data.length < size_) {
            size_ = cast(GrUInt) _data.length;
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

    pragma(inline) void sortByFloat() {
        import std.algorithm.sorting : sort;

        _data.sort!((a, b) => a.getFloat() < b.getFloat())();
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
        for (GrUInt index; index < _data.length; ++index) {
            if (_data[index] == value)
                return true;
        }
        return false;
    }
}
