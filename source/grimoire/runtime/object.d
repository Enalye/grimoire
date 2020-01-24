/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.object;

import grimoire.compiler;
import grimoire.runtime.array;

/**
A single field of an object. \
We can't know at runtime the type of a field,
so you need to check with its type definition.
*/
package final class GrField {
    union {
        int ivalue;
        float fvalue;
        dstring svalue;
        void* ovalue;
    }
}

/// Object value in Grimoire runtime.
final class GrObject {
    package {
        GrObjectDefinition _type;
        /// Inner fields, indexes are known at compile time.
        GrField[] _fields;

        /// Ctor
        this(GrObjectDefinition type) {
            _type = type;
            _fields.length = type.fields.length;
            for(size_t index; index < _fields.length; ++ index) {
                _fields[index] = new GrField;
            }
        }
    }

    alias getInt = getField!int;
    alias getBool = getField!bool;
    alias getFloat = getField!float;
    alias getString = getField!dstring;
    alias getObject = getUserData!GrObject;
    alias getIntArray = getUserData!GrIntArray;
    alias getFloatArray = getUserData!GrFloatArray;
    alias getStringArray = getUserData!GrStringArray;
    alias getObjectArray = getUserData!GrObjectArray;

    T getUserData(T)(dstring fieldName) {
        return cast(T)getField!(void*)(fieldName);
    }

    private T getField(T)(dstring fieldName) {
        for(size_t index; index < _fields.length; ++ index) {
            if(_type.fields[index] == fieldName) {
                static if(is(T == int))
                    return _fields[index].ivalue;
                else static if(is(T == bool))
                    return cast(T) _fields[index].ivalue;
                else static if(is(T == float))
                    return _fields[index].fvalue;
                else static if(is(T == dstring))
                    return _fields[index].svalue;
                else static if(is(T == void*))
                    return _fields[index].ovalue;
                else
                    static assert(false, "Invalid field type");
            }
        }
        assert(false, "Invalid field name");
    }

    alias setInt = setField!int;
    alias setBool = setField!bool;
    alias setFloat = setField!float;
    alias setString = setField!dstring;
    alias setObject = setUserData!GrObject;
    alias setIntArray = setUserData!GrIntArray;
    alias setFloatArray = setUserData!GrFloatArray;
    alias setStringArray = setUserData!GrStringArray;
    alias setObjectArray = setUserData!GrObjectArray;
    
    void setUserData(T)(dstring fieldName, T value) {
        setField!(void*)(fieldName, cast(void*)value);
    }

    private T setField(T)(dstring fieldName, T value) {
        for(size_t index; index < _fields.length; ++ index) {
            if(_type.fields[index] == fieldName) {
                static if(is(T == int))
                    return _fields[index].ivalue = cast(int) value;
                else static if(is(T == bool))
                    return _fields[index].ivalue = value;
                else static if(is(T == float))
                    return _fields[index].fvalue = value;
                else static if(is(T == dstring))
                    return _fields[index].svalue = value;
                else static if(is(T == void*))
                    return _fields[index].ovalue = value;
                else
                    static assert(false, "Invalid field type");
            }
        }
        assert(false, "Invalid field name");
    }
}