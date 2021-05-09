/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.object;

import grimoire.compiler, grimoire.assembly;
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
            for(size_t index; index < _fields.length; ++ index) {
                _fields[index] = new GrField;
            }
        }
    }

    alias getInt = getField!int;
    alias getBool = getField!bool;
    alias getFloat = getField!float;
    alias getString = getField!string;
    alias getObject = getUserData!GrObject;
    alias getIntArray = getUserData!GrIntArray;
    alias getFloatArray = getUserData!GrFloatArray;
    alias getStringArray = getUserData!GrStringArray;
    alias getObjectArray = getUserData!GrObjectArray;

    T getUserData(T)(string fieldName) {
        return cast(T)getField!(void*)(fieldName);
    }

    private T getField(T)(string fieldName) {
        for(size_t index; index < _fields.length; ++ index) {
            if(_class.fields[index] == fieldName) {
                static if(is(T == int))
                    return _fields[index].ivalue;
                else static if(is(T == bool))
                    return cast(T) _fields[index].ivalue;
                else static if(is(T == float))
                    return _fields[index].fvalue;
                else static if(is(T == string))
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
    alias setString = setField!string;
    alias setObject = setUserData!GrObject;
    alias setIntArray = setUserData!GrIntArray;
    alias setFloatArray = setUserData!GrFloatArray;
    alias setStringArray = setUserData!GrStringArray;
    alias setObjectArray = setUserData!GrObjectArray;
    
    void setUserData(T)(string fieldName, T value) {
        setField!(void*)(fieldName, cast(void*)value);
    }

    private T setField(T)(string fieldName, T value) {
        for(size_t index; index < _fields.length; ++ index) {
            if(_class.fields[index] == fieldName) {
                static if(is(T == int))
                    return _fields[index].ivalue = cast(int) value;
                else static if(is(T == bool))
                    return _fields[index].ivalue = value;
                else static if(is(T == float))
                    return _fields[index].fvalue = value;
                else static if(is(T == string))
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