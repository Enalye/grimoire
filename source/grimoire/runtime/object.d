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
    union {
        GrInt ivalue;
        GrReal rvalue;
        GrString svalue;
        GrPtr ovalue;
    }
}

/// Object value in Grimoire runtime.
final class GrObject {
    package {
        /// Inner fields, indexes are known at compile time.
        GrField[] _fields;

        /// Build from definition
        this(GrClassBuilder class_) {
            _fields.length = class_.fields.length;
            for (size_t index; index < _fields.length; ++index) {
                _fields[index] = new GrField;
                _fields[index].name = class_.fields[index];
            }
        }
    }

    /// Build from raw fields
    this(string[] fields_) {
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

    int getInt32(string fieldName) {
        return cast(int) getField!GrInt(fieldName);
    }

    long getInt64(string fieldName) {
        return cast(long) getField!GrInt(fieldName);
    }

    real getReal32(string fieldName) {
        return cast(real) getField!GrReal(fieldName);
    }

    double getReal64(string fieldName) {
        return cast(double) getField!GrReal(fieldName);
    }

    GrObject getObject(string fieldName) {
        return cast(GrObject) getField!GrPtr(fieldName);
    }

    GrArray!T getArray(T)(string fieldName) {
        return cast(GrArray!T) getField!GrPtr(fieldName);
    }

    GrIntArray getIntArray(string fieldName) {
        return cast(GrIntArray) getField!GrPtr(fieldName);
    }

    GrRealArray getRealArray(string fieldName) {
        return cast(GrRealArray) getField!GrPtr(fieldName);
    }

    GrStringArray getStringArray(string fieldName) {
        return cast(GrStringArray) getField!GrPtr(fieldName);
    }

    GrObjectArray getObjectArray(string fieldName) {
        return cast(GrObjectArray) getField!GrPtr(fieldName);
    }

    GrIntChannel getIntChannel(string fieldName) {
        return cast(GrIntChannel) getField!GrPtr(fieldName);
    }

    GrRealChannel getRealChannel(string fieldName) {
        return cast(GrRealChannel) getField!GrPtr(fieldName);
    }

    GrStringChannel getStringChannel(string fieldName) {
        return cast(GrStringChannel) getField!GrPtr(fieldName);
    }

    GrObjectChannel getObjectChannel(string fieldName) {
        return cast(GrObjectChannel) getField!GrPtr(fieldName);
    }

    T getEnum(T)(string fieldName) {
        return cast(T) getField!GrInt(fieldName);
    }

    T getForeign(T)(string fieldName) {
        // We cast to object first to avoid a crash when casting to a parent class
        return cast(T) cast(Object) getField!GrPtr(fieldName);
    }

    private T getField(T)(string fieldName) {
        for (size_t index; index < _fields.length; ++index) {
            if (_fields[index].name == fieldName) {
                static if (is(T == GrInt))
                    return _fields[index].ivalue;
                else static if (is(T == GrBool))
                    return cast(T) _fields[index].ivalue;
                else static if (is(T == GrReal))
                    return _fields[index].rvalue;
                else static if (is(T == GrString))
                    return _fields[index].svalue;
                else static if (is(T == GrPtr))
                    return _fields[index].ovalue;
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

    void setInt32(string fieldName, int value) {
        setField!GrInt(fieldName, cast(GrInt) value);
    }

    void setInt64(string fieldName, long value) {
        setField!GrInt(fieldName, cast(GrInt) value);
    }

    void setReal32(string fieldName, real value) {
        setField!GrReal(fieldName, cast(GrReal) value);
    }

    void setReal64(string fieldName, double value) {
        setField!GrReal(fieldName, cast(GrReal) value);
    }

    void setObject(string fieldName, GrObject value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setArray(T)(string fieldName, GrArray!T value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setIntArray(string fieldName, GrIntArray value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setRealArray(string fieldName, GrRealArray value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setStringArray(string fieldName, GrStringArray value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setObjectArray(string fieldName, GrObjectArray value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setIntChannel(string fieldName, GrIntChannel value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setRealChannel(string fieldName, GrRealChannel value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setStringChannel(string fieldName, GrStringChannel value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setObjectChannel(string fieldName, GrObjectChannel value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setEnum(T)(string fieldName, T value) {
        setField!GrInt(fieldName, cast(GrInt) value);
    }

    void setForeign(T)(string fieldName, T value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    private T setField(T)(string fieldName, T value) {
        for (size_t index; index < _fields.length; ++index) {
            if (_fields[index].name == fieldName) {
                static if (is(T == GrInt))
                    return _fields[index].ivalue = cast(int) value;
                else static if (is(T == GrBool))
                    return _fields[index].ivalue = value;
                else static if (is(T == GrReal))
                    return _fields[index].rvalue = value;
                else static if (is(T == GrString))
                    return _fields[index].svalue = value;
                else static if (is(T == GrPtr))
                    return _fields[index].ovalue = value;
                else
                    static assert(false, "Invalid field type");
            }
        }
        assert(false, "Invalid field name");
    }
}
