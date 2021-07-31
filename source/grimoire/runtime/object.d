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
    union {
        int ivalue;
        float fvalue;
        string svalue;
        void* ovalue;
    }
}

/// Object value in Grimoire runtime.
final class GrObject {
    package {
        GrClassBuilder _class;
        /// Inner fields, indexes are known at compile time.
        GrField[] _fields;

        /// Ctor
        this(GrClassBuilder class_) {
            _class = class_;
            _fields.length = _class.fields.length;
            for (size_t index; index < _fields.length; ++index) {
                _fields[index] = new GrField;
            }
        }
    }

    alias getBool = getField!bool;
    alias getInt = getField!int;
    alias getFloat = getField!float;
    alias getString = getField!string;
    alias getPtr = getField!(void*);

    GrObject getObject(string fieldName) {
        return cast(GrObject) getField!(void*)(fieldName);
    }

    GrIntArray getIntArray(string fieldName) {
        return cast(GrIntArray) getField!(void*)(fieldName);
    }

    GrFloatArray getFloatArray(string fieldName) {
        return cast(GrFloatArray) getField!(void*)(fieldName);
    }

    GrStringArray getStringArray(string fieldName) {
        return cast(GrStringArray) getField!(void*)(fieldName);
    }

    GrObjectArray getObjectArray(string fieldName) {
        return cast(GrObjectArray) getField!(void*)(fieldName);
    }

    GrIntChannel getIntChannel(string fieldName) {
        return cast(GrIntChannel) getField!(void*)(fieldName);
    }

    GrFloatChannel getFloatChannel(string fieldName) {
        return cast(GrFloatChannel) getField!(void*)(fieldName);
    }

    GrStringChannel getStringChannel(string fieldName) {
        return cast(GrStringChannel) getField!(void*)(fieldName);
    }

    GrObjectChannel getObjectChannel(string fieldName) {
        return cast(GrObjectChannel) getField!(void*)(fieldName);
    }

    T getEnum(T)(string fieldName) {
        return cast(T) getField!int(fieldName);
    }

    T getForeign(T)(string fieldName) {
        // We cast to object first to avoid a crash when casting to a parent class
        return cast(T) cast(Object) getField!(void*)(fieldName);
    }

    private T getField(T)(string fieldName) {
        for (size_t index; index < _fields.length; ++index) {
            if (_class.fields[index] == fieldName) {
                static if (is(T == int))
                    return _fields[index].ivalue;
                else static if (is(T == bool))
                    return cast(T) _fields[index].ivalue;
                else static if (is(T == float))
                    return _fields[index].fvalue;
                else static if (is(T == string))
                    return _fields[index].svalue;
                else static if (is(T == void*))
                    return _fields[index].ovalue;
                else
                    static assert(false, "Invalid field type");
            }
        }
        assert(false, "Invalid field name");
    }

    alias setBool = setField!bool;
    alias setInt = setField!int;
    alias setFloat = setField!float;
    alias setString = setField!string;
    alias setPtr = setField!(void*);

    void setObject(string fieldName, GrObject value) {
        setField!(void*)(fieldName, cast(void*) value);
    }

    void setIntArray(string fieldName, GrIntArray value) {
        setField!(void*)(fieldName, cast(void*) value);
    }

    void setFloatArray(string fieldName, GrFloatArray value) {
        setField!(void*)(fieldName, cast(void*) value);
    }

    void setStringArray(string fieldName, GrStringArray value) {
        setField!(void*)(fieldName, cast(void*) value);
    }

    void setObjectArray(string fieldName, GrObjectArray value) {
        setField!(void*)(fieldName, cast(void*) value);
    }

    void setIntChannel(string fieldName, GrIntChannel value) {
        setField!(void*)(fieldName, cast(void*) value);
    }

    void setFloatChannel(string fieldName, GrFloatChannel value) {
        setField!(void*)(fieldName, cast(void*) value);
    }

    void setStringChannel(string fieldName, GrStringChannel value) {
        setField!(void*)(fieldName, cast(void*) value);
    }

    void setObjectChannel(string fieldName, GrObjectChannel value) {
        setField!(void*)(fieldName, cast(void*) value);
    }

    void setEnum(T)(string fieldName, T value) {
        setField!int(fieldName, cast(int) value);
    }

    void setForeign(T)(string fieldName, T value) {
        setField!(void*)(fieldName, cast(void*) value);
    }

    private T setField(T)(string fieldName, T value) {
        for (size_t index; index < _fields.length; ++index) {
            if (_class.fields[index] == fieldName) {
                static if (is(T == int))
                    return _fields[index].ivalue = cast(int) value;
                else static if (is(T == bool))
                    return _fields[index].ivalue = value;
                else static if (is(T == float))
                    return _fields[index].fvalue = value;
                else static if (is(T == string))
                    return _fields[index].svalue = value;
                else static if (is(T == void*))
                    return _fields[index].ovalue = value;
                else
                    static assert(false, "Invalid field type");
            }
        }
        assert(false, "Invalid field name");
    }
}
