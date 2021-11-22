/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.object;

import grimoire.compiler, grimoire.assembly;
import grimoire.runtime.list, grimoire.runtime.channel;

/**
A single field of an object. \
We can't know at runtime the type of a field,
so you need to check with its type definition.
*/
package final class GrField {
    string name;
    union {
        GrInt ivalue;
        GrFloat fvalue;
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
    alias getFloat = getField!GrFloat;
    alias getString = getField!GrString;
    alias getPtr = getField!GrPtr;

    int getInt32(string fieldName) {
        return cast(int) getField!GrInt(fieldName);
    }

    long getInt64(string fieldName) {
        return cast(long) getField!GrInt(fieldName);
    }

    float getFloat32(string fieldName) {
        return cast(float) getField!GrFloat(fieldName);
    }

    double getFloat64(string fieldName) {
        return cast(double) getField!GrFloat(fieldName);
    }

    GrObject getObject(string fieldName) {
        return cast(GrObject) getField!GrPtr(fieldName);
    }

    GrList!T getList(T)(string fieldName) {
        return cast(GrList!T) getField!GrPtr(fieldName);
    }

    GrIntList getIntList(string fieldName) {
        return cast(GrIntList) getField!GrPtr(fieldName);
    }

    GrFloatList getFloatList(string fieldName) {
        return cast(GrFloatList) getField!GrPtr(fieldName);
    }

    GrStringList getStringList(string fieldName) {
        return cast(GrStringList) getField!GrPtr(fieldName);
    }

    GrObjectList getObjectList(string fieldName) {
        return cast(GrObjectList) getField!GrPtr(fieldName);
    }

    GrIntChannel getIntChannel(string fieldName) {
        return cast(GrIntChannel) getField!GrPtr(fieldName);
    }

    GrFloatChannel getFloatChannel(string fieldName) {
        return cast(GrFloatChannel) getField!GrPtr(fieldName);
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
                else static if (is(T == GrFloat))
                    return _fields[index].fvalue;
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
    alias setFloat = setField!GrFloat;
    alias setString = setField!GrString;
    alias setPtr = setField!GrPtr;

    void setInt32(string fieldName, int value) {
        setField!GrInt(fieldName, cast(GrInt) value);
    }

    void setInt64(string fieldName, long value) {
        setField!GrInt(fieldName, cast(GrInt) value);
    }

    void setFloat32(string fieldName, float value) {
        setField!GrFloat(fieldName, cast(GrFloat) value);
    }

    void setFloat64(string fieldName, double value) {
        setField!GrFloat(fieldName, cast(GrFloat) value);
    }

    void setObject(string fieldName, GrObject value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setList(T)(string fieldName, GrList!T value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setIntList(string fieldName, GrIntList value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setFloatList(string fieldName, GrFloatList value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setStringList(string fieldName, GrStringList value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setObjectList(string fieldName, GrObjectList value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setIntChannel(string fieldName, GrIntChannel value) {
        setField!GrPtr(fieldName, cast(GrPtr) value);
    }

    void setFloatChannel(string fieldName, GrFloatChannel value) {
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
                else static if (is(T == GrFloat))
                    return _fields[index].fvalue = value;
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
