/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.runtime.value;

import grimoire.assembly;
import grimoire.runtime.string;
import grimoire.runtime.list;
import grimoire.runtime.object;
import grimoire.runtime.channel;

package(grimoire) enum GR_NULL = 0xffffUL << 48;

struct GrValue {
    package(grimoire) union {
        GrInt _ivalue;
        GrUInt _uvalue;
        GrFloat _fvalue;
        GrPointer _ovalue;
        ulong _bytes;
    }

    this(GrInt value) {
        _ivalue = value;
    }

    this(GrFloat value) {
        _fvalue = value;
    }

    this(GrBool value) {
        _ivalue = cast(GrInt) value;
    }

    this(GrChar value) {
        _uvalue = cast(GrUInt) value;
    }

    this(GrList value) {
        _ovalue = cast(GrPointer) value;
    }

    this(GrValue[] value) {
        _ovalue = cast(GrPointer) new GrList(value);
    }

    this(string value) {
        _ovalue = cast(GrPointer) new GrString(value);
    }

    this(GrObject value) {
        _ovalue = cast(GrPointer) value;
    }

    this(T)(T value) if (is(T == class)) {
        _ovalue = cast(GrPointer) value;
    }

    this(T)(T[] values) {
        GrList list = new GrList;
        foreach (value; values) {
            list.push(GrValue(value));
        }
        _ovalue = cast(GrPointer) list;
    }

    this(GrPointer value) {
        _ovalue = value;
    }

    @property {
        pragma(inline) GrBool isNull() const {
            return _bytes == GR_NULL;
        }
    }

    pragma(inline) void setNull() {
        _bytes = GR_NULL;
    }

    pragma(inline) GrBool getBool() const {
        return cast(GrBool) _ivalue;
    }

    pragma(inline) GrInt getInt() const {
        return _ivalue;
    }

    pragma(inline) GrUInt getUInt() const {
        return _uvalue;
    }

    pragma(inline) GrChar getChar() const {
        return cast(GrChar) _uvalue;
    }

    pragma(inline) T getEnum(T)() const {
        return cast(T) _ivalue;
    }

    pragma(inline) GrFloat getFloat() const {
        return _fvalue;
    }

    pragma(inline) GrPointer getPointer() const {
        return cast(GrPointer) _ovalue;
    }

    pragma(inline) GrString getString() const {
        return cast(GrString) _ovalue;
    }

    pragma(inline) GrList getList() const {
        return cast(GrList) _ovalue;
    }

    pragma(inline) GrChannel getChannel() const {
        return cast(GrChannel) _ovalue;
    }

    pragma(inline) GrObject getObject() const {
        return cast(GrObject) _ovalue;
    }

    pragma(inline) T getNative(T)() const {
        return cast(T) _ovalue;
    }

    pragma(inline) void setBool(GrBool value) {
        _ivalue = cast(GrInt) value;
    }

    pragma(inline) void setInt(GrInt value) {
        _ivalue = value;
    }

    pragma(inline) void setUInt(GrUInt value) {
        _uvalue = value;
    }

    pragma(inline) void setChar(GrChar value) {
        _uvalue = cast(GrUInt) value;
    }

    pragma(inline) void setEnum(T)(T value) {
        _ivalue = cast(GrInt) value;
    }

    pragma(inline) void setFloat(GrFloat value) {
        _fvalue = value;
    }

    pragma(inline) void setPointer(GrPointer value) {
        _ovalue = value;
    }

    pragma(inline) void setString(GrString value) {
        _ovalue = cast(GrPointer) value;
    }

    pragma(inline) void setString(string value) {
        (cast(GrString) _ovalue) = value;
    }

    pragma(inline) void setList(GrList value) {
        _ovalue = cast(GrPointer) value;
    }

    pragma(inline) void setList(GrValue[] value) {
        _ovalue = cast(GrPointer) new GrList(value);
    }

    pragma(inline) void setChannel(GrChannel value) {
        _ovalue = cast(GrPointer) value;
    }

    pragma(inline) void setObject(GrObject value) {
        _ovalue = cast(GrPointer) value;
    }

    pragma(inline) void setNative(T)(T value) {
        _ovalue = cast(GrPointer) value;
    }
}
