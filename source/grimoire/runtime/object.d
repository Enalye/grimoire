/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.object;

import grimoire.compiler, grimoire.assembly;
import grimoire.runtime.channel;
import grimoire.runtime.value;
import grimoire.runtime.array;

/**
A single field of an object. \
We can't know at runtime the type of a field,
so you need to check with its type definition.
*/
package final class GrField {
    string name;
    GrValue value;
}

/// Object value in Grimoire runtime.
final class GrObject {
    package {
        /// Inner fields, indexes are known at compile time.
        GrField[] _fields;

        /// Build from definition
        this(const GrClassBuilder class_) {
            _fields.length = class_.fields.length;
            for (size_t index; index < _fields.length; ++index) {
                _fields[index] = new GrField;
                _fields[index].name = class_.fields[index];
            }
        }
    }

    /// Build from raw fields
    this(const string[] fields_) {
        _fields.length = fields_.length;
        for (size_t index; index < _fields.length; ++index) {
            _fields[index] = new GrField;
            _fields[index].name = fields_[index];
        }
    }

    alias getValue = getField!GrValue;
    alias getBool = getField!GrBool;
    alias getInt = getField!GrInt;
    alias getReal = getField!GrReal;
    alias getPtr = getField!GrPtr;

    pragma(inline) int getInt32(const string fieldName) {
        return cast(int) getField!GrInt(fieldName);
    }

    pragma(inline) long getInt64(const string fieldName) {
        return cast(long) getField!GrInt(fieldName);
    }

    pragma(inline) float getReal32(const string fieldName) {
        return cast(float) getField!GrReal(fieldName);
    }

    pragma(inline) double getReal64(const string fieldName) {
        return cast(double) getField!GrReal(fieldName);
    }

    pragma(inline) GrObject getObject(const string fieldName) {
        return cast(GrObject) getField!GrPtr(fieldName);
    }

    pragma(inline) GrString getString(const string fieldName) {
        return (cast(GrStringWrapper) getField!GrPtr(fieldName)).data;
    }

    pragma(inline) GrArray getArray(const string fieldName) {
        return cast(GrArray) getField!GrPtr(fieldName);
    }

    pragma(inline) GrChannel getChannel(const string fieldName) {
        return cast(GrChannel) getField!GrPtr(fieldName);
    }

    pragma(inline) T getEnum(T)(const string fieldName) {
        return cast(T) getField!GrInt(fieldName);
    }

    pragma(inline) T getForeign(T)(const string fieldName) {
        // We cast to object first to avoid a crash when casting to a parent class
        return cast(T) cast(Object) getField!GrPtr(fieldName);
    }

    pragma(inline) private T getField(T)(const string fieldName) {
        for (size_t index; index < _fields.length; ++index) {
            if (_fields[index].name == fieldName) {
                static if (is(T == GrValue))
                    return _fields[index].value;
                else static if (is(T == GrInt))
                    return _fields[index].value.getInt();
                else static if (is(T == GrBool))
                    return cast(T) _fields[index].value.getInt();
                else static if (is(T == GrReal))
                    return _fields[index].value.getReal();
                else static if (is(T == GrPtr))
                    return _fields[index].value.getPtr();
                else
                    static assert(false, "invalid field type `" ~ T.stringof ~ "`");
            }
        }
        assert(false, "invalid field name `" ~ fieldName ~ "`");
    }

    alias setValue = setField!GrValue;
    alias setBool = setField!GrBool;
    alias setInt = setField!GrInt;
    alias setReal = setField!GrReal;
    alias setPtr = setField!GrPtr;

    pragma(inline) void setInt32(const string fieldName, int value) {
        setField!GrInt(fieldName, cast(GrInt) value);
    }

    pragma(inline) void setInt64(const string fieldName, long value) {
        setField!GrInt(fieldName, cast(GrInt) value);
    }

    pragma(inline) void setReal32(const string fieldName, float value) {
        setField!GrReal(fieldName, cast(GrReal) value);
    }

    pragma(inline) void setReal64(const string fieldName, double value) {
        setField!GrReal(fieldName, cast(GrReal) value);
    }

    pragma(inline) void setObject(const string fieldName, GrObject value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    pragma(inline) void setString(const string fieldName, GrString value) {
        setField!GrPtr(fieldName, cast(GrPtr) new GrStringWrapper(value));
    }

    pragma(inline) void setArray(const string fieldName, GrArray value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    pragma(inline) void setArray(const string fieldName, GrValue[] value) {
        setField!GrPtr(fieldName, cast(GrPtr) new GrArray(value));
    }

    pragma(inline) void setChannel(const string fieldName, GrChannel value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    pragma(inline) void setEnum(T)(const string fieldName, T value) {
        setField!GrInt(fieldName, cast(GrInt) value);
    }

    pragma(inline) void setForeign(T)(const string fieldName, T value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    pragma(inline) private T setField(T)(const string fieldName, T value) {
        for (size_t index; index < _fields.length; ++index) {
            if (_fields[index].name == fieldName) {
                static if (is(T == GrValue))
                    return _fields[index].value = value;
                else static if (is(T == GrInt))
                    return _fields[index].value._ivalue = value;
                else static if (is(T == GrBool))
                    return _fields[index].value._ivalue = cast(GrInt) value;
                else static if (is(T == GrReal))
                    return _fields[index].value._rvalue = value;
                else static if (is(T == GrPtr))
                    return _fields[index].value._ovalue = value;
                else
                    static assert(false, "invalid field type `" ~ T.stringof ~ "`");
            }
        }
        assert(false, "invalid field name `" ~ fieldName ~ "`");
    }
}
