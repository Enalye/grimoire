/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.runtime.object;

import grimoire.compiler, grimoire.assembly;
import grimoire.runtime.channel;
import grimoire.runtime.value;
import grimoire.runtime.string;
import grimoire.runtime.list;

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
    alias getFloat = getField!GrFloat;
    alias getPointer = getField!GrPointer;

    pragma(inline) T getEnum(T)(const string fieldName) const {
        return cast(T) getField!GrInt(fieldName);
    }

    pragma(inline) GrString getString(const string fieldName) const {
        return cast(GrString) getField!GrPointer(fieldName);
    }

    pragma(inline) GrList getList(const string fieldName) const {
        return cast(GrList) getField!GrPointer(fieldName);
    }

    pragma(inline) GrChannel getChannel(const string fieldName) const {
        return cast(GrChannel) getField!GrPointer(fieldName);
    }

    pragma(inline) GrObject getObject(const string fieldName) const {
        return cast(GrObject) getField!GrPointer(fieldName);
    }

    pragma(inline) T getNative(T)(const string fieldName) const {
        // On change en objet d’abord pour éviter un plantage en changeant pour une classe mère
        return cast(T) cast(Object) getField!GrPointer(fieldName);
    }

    pragma(inline) private T getField(T)(const string fieldName) const {
        for (size_t index; index < _fields.length; ++index) {
            if (_fields[index].name == fieldName) {
                static if (is(T == GrValue))
                    return _fields[index].value;
                else static if (is(T == GrInt))
                    return _fields[index].value.getInt();
                else static if (is(T == GrBool))
                    return cast(T) _fields[index].value.getInt();
                else static if (is(T == GrFloat))
                    return _fields[index].value.getFloat();
                else static if (is(T == GrPointer))
                    return _fields[index].value.getPointer();
                else
                    static assert(false, "invalid field type `" ~ T.stringof ~ "`");
            }
        }
        assert(false, "invalid field name `" ~ fieldName ~ "`");
    }

    alias setValue = setField!GrValue;
    alias setBool = setField!GrBool;
    alias setInt = setField!GrInt;
    alias setFloat = setField!GrFloat;
    alias setPointer = setField!GrPointer;

    pragma(inline) void setEnum(T)(const string fieldName, T value) {
        setField!GrInt(fieldName, cast(GrInt) value);
    }

    pragma(inline) void setString(const string fieldName, GrStringValue value) {
        setField!GrPointer(fieldName, cast(GrPointer) new GrString(value));
    }

    pragma(inline) void setList(const string fieldName, GrList value) {
        setField!GrPointer(fieldName, cast(GrPointer) value);
    }

    pragma(inline) void setList(const string fieldName, GrValue[] value) {
        setField!GrPointer(fieldName, cast(GrPointer) new GrList(value));
    }

    pragma(inline) void setChannel(const string fieldName, GrChannel value) {
        setField!GrPointer(fieldName, cast(GrPointer) value);
    }

    pragma(inline) void setObject(const string fieldName, GrObject value) {
        setField!GrPointer(fieldName, cast(GrPointer) value);
    }

    pragma(inline) void setNative(T)(const string fieldName, T value) {
        setField!GrPointer(fieldName, cast(GrPointer) value);
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
                else static if (is(T == GrFloat))
                    return _fields[index].value._rvalue = value;
                else static if (is(T == GrPointer))
                    return _fields[index].value._ovalue = value;
                else
                    static assert(false, "invalid field type `" ~ T.stringof ~ "`");
            }
        }
        assert(false, "invalid field name `" ~ fieldName ~ "`");
    }
}
