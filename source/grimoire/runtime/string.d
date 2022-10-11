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
    public GrStringValue data;

    alias data this;

    this() {
    }

    this(GrStringValue value) {
        data = value;
    }

    @property {
        pragma(inline) GrInt size() const {
            return cast(GrInt) data.length;
        }

        pragma(inline) GrBool isEmpty() const {
            return data.length == 0;
        }
    }

    pragma(inline) void opAssign(GrStringValue values) {
        data = values;
    }

    pragma(inline) void clear() {
        data.length = 0;
    }

    pragma(inline) void resize(GrInt size_) {
        data.length = size_;
    }

    pragma(inline) GrStringValue first() {
        return to!GrStringValue(data[0]);
    }

    pragma(inline) GrStringValue last() {
        return to!GrStringValue(data[$ - 1]);
    }

    pragma(inline) void push(GrStringValue value) {
        data ~= value;
    }

    pragma(inline) GrStringValue pop() {
        GrStringValue value = to!GrStringValue(data[$ - 1]);
        data.length--;
        return value;
    }

    pragma(inline) GrStringValue pop(GrInt size_) {
        if (data.length < size_) {
            size_ = cast(GrInt) data.length;
        }
        GrStringValue slice = data[$ - size_ .. $];
        data.length -= size_;
        return slice;
    }

    pragma(inline) void unshift(GrStringValue value) {
        data = value ~ data;
    }

    pragma(inline) GrStringValue shift() {
        GrStringValue value = to!GrStringValue(data[0]);
        data = data[1 .. $];
        return value;
    }

    pragma(inline) GrStringValue shift(GrInt size_) {
        if (data.length < size_) {
            size_ = cast(GrInt) data.length;
        }
        GrStringValue slice = data[0 .. size_];
        data = data[size_ .. $];
        return slice;
    }

    pragma(inline) void remove(GrInt index) {
        if (index < 0)
            index = (cast(GrInt) data.length) + index;
        if (!data.length || index >= data.length || index < 0) {
            return;
        }
        if (index + 1 == data.length) {
            data.length--;
            return;
        }
        if (index == 0) {
            data = data[1 .. $];
            return;
        }
        data = data[0 .. index] ~ data[index + 1 .. $];
    }

    pragma(inline) void remove(GrInt index1, GrInt index2) {
        if (index1 < 0)
            index1 = (cast(GrInt) data.length) + index1;
        if (index2 < 0)
            index2 = (cast(GrInt) data.length) + index2;

        if (index2 < index1) {
            const GrInt temp = index1;
            index1 = index2;
            index2 = temp;
        }

        if (!data.length || index1 >= data.length || index2 < 0) {
            return;
        }

        if (index1 < 0)
            index1 = 0;
        if (index2 >= data.length)
            index2 = (cast(GrInt) data.length) - 1;

        if (index1 == 0 && (index2 + 1) == data.length) {
            data.length = 0;
            return;
        }
        if (index1 == 0) {
            data = data[(index2 + 1) .. $];
            return;
        }
        if ((index2 + 1) == data.length) {
            data = data[0 .. index1];
            return;
        }
        data = data[0 .. index1] ~ data[(index2 + 1) .. $];
    }

    pragma(inline) GrStringValue slice(GrInt index1, GrInt index2) {
        if (index1 < 0)
            index1 = (cast(GrInt) data.length) + index1;
        if (index2 < 0)
            index2 = (cast(GrInt) data.length) + index2;

        if (index2 < index1) {
            const GrInt temp = index1;
            index1 = index2;
            index2 = temp;
        }

        if (!data.length || index1 >= data.length || index2 < 0)
            return [];

        if (index1 < 0)
            index1 = 0;
        if (index2 >= data.length)
            index2 = (cast(GrInt) data.length - 1);

        if (index1 == 0 && (index2 + 1) == data.length)
            return data;

        return data[index1 .. index2 + 1];
    }

    pragma(inline) GrStringValue reverse() {
        import std.algorithm.mutation : reverse;

        return data.dup.reverse();
    }

    pragma(inline) void insert(GrInt index, GrStringValue value) {
        if (index >= data.length) {
            data ~= value;
            return;
        }
        if (index < 0)
            index = (cast(GrInt) data.length) + index;

        if (index <= 0) {
            data = value ~ data;
            return;
        }
        if (index + 1 == data.length) {
            data = data[0 .. index] ~ value ~ data[$ - 1];
            return;
        }
        data = data[0 .. index] ~ value ~ data[index .. $];
    }

    pragma(inline) GrInt indexOf(GrStringValue value) {
        return cast(GrInt) data.indexOf(value);
    }

    pragma(inline) GrInt lastIndexOf(GrStringValue value) {
        return cast(GrInt) data.lastIndexOf(value);
    }

    pragma(inline) GrBool contains(GrStringValue value) {
        return data.indexOf(value) != -1;
    }
}
