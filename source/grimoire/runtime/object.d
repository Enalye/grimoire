/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.object;

import grimoire.compiler, grimoire.assembly;
import grimoire.runtime.array, grimoire.runtime.channel;

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

    alias getBool = getField!bool;
    alias getInt = getField!GrInt;
    alias getReal = getField!GrReal;
    alias getString = getField!GrString;
    alias getPtr = getField!GrPtr;

    int getInt32(const string fieldName) {
        return cast(int) getField!GrInt(fieldName);
    }

    long getInt64(const string fieldName) {
        return cast(long) getField!GrInt(fieldName);
    }

    real getReal32(const string fieldName) {
        return cast(real) getField!GrReal(fieldName);
    }

    double getReal64(const string fieldName) {
        return cast(double) getField!GrReal(fieldName);
    }

    GrObject getObject(const string fieldName) {
        return cast(GrObject) getField!GrPtr(fieldName);
    }

    GrArray getArray(const string fieldName) {
        return cast(GrArray) getField!GrPtr(fieldName);
    }

    GrChannel getChannel(const string fieldName) {
        return cast(GrChannel) getField!GrPtr(fieldName);
    }

    T getEnum(T)(const string fieldName) {
        return cast(T) getField!GrInt(fieldName);
    }

    T getForeign(T)(const string fieldName) {
        // We cast to object first to avoid a crash when casting to a parent class
        return cast(T) cast(Object) getField!GrPtr(fieldName);
    }

    private T getField(T)(const string fieldName) {
        for (size_t index; index < _fields.length; ++index) {
            if (_fields[index].name == fieldName) {
                static if (is(T == GrInt))
                    return _fields[index].value.ivalue;
                else static if (is(T == GrBool))
                    return cast(T) _fields[index].value.ivalue;
                else static if (is(T == GrReal))
                    return _fields[index].value.rvalue;
                else static if (is(T == GrString))
                    return _fields[index].value.svalue;
                else static if (is(T == GrPtr))
                    return _fields[index].value.ovalue;
                else
                    static assert(false, "Invalid field type");
            }
        }
        assert(false, "Invalid field name");
    }

    alias setBool = setField!bool;
    alias setInt = setField!GrInt;
    alias setReal = setField!GrReal;
    alias setString = setField!GrString;
    alias setPtr = setField!GrPtr;

    void setInt32(const string fieldName, int value) {
        setField!GrInt(fieldName, cast(GrInt) value);
    }

    void setInt64(const string fieldName, long value) {
        setField!GrInt(fieldName, cast(GrInt) value);
    }

    void setReal32(const string fieldName, real value) {
        setField!GrReal(fieldName, cast(GrReal) value);
    }

    void setReal64(const string fieldName, double value) {
        setField!GrReal(fieldName, cast(GrReal) value);
    }

    void setObject(const string fieldName, GrObject value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setArray(const string fieldName, GrArray value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setChannel(const string fieldName, GrChannel value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setEnum(T)(const string fieldName, T value) {
        setField!GrInt(fieldName, cast(GrInt) value);
    }

    void setForeign(T)(const string fieldName, T value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    private T setField(T)(const string fieldName, T value) {
        for (size_t index; index < _fields.length; ++index) {
            if (_fields[index].name == fieldName) {
                static if (is(T == GrInt))
                    return _fields[index].value.ivalue = cast(int) value;
                else static if (is(T == GrBool))
                    return _fields[index].value.ivalue = value;
                else static if (is(T == GrReal))
                    return _fields[index].value.rvalue = value;
                else static if (is(T == GrString))
                    return _fields[index].value.svalue = value;
                else static if (is(T == GrPtr))
                    return _fields[index].value.ovalue = value;
                else
                    static assert(false, "Invalid field type");
            }
        }
        assert(false, "Invalid field name");
    }
}
