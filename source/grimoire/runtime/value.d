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
        GrInt _intValue;
        GrUInt _uintValue;
        GrByte _byteValue;
        GrFloat _floatValue;
        GrDouble _doubleValue;
        GrPointer _ptrValue;
        ulong _bytes;
    }

    this(GrInt value) {
        _intValue = value;
    }

    this(GrUInt value) {
        _uintValue = value;
    }

    this(GrFloat value) {
        _floatValue = value;
    }

    this(GrDouble value) {
        _doubleValue = value;
    }

    this(GrBool value) {
        _intValue = cast(GrInt) value;
    }

    this(GrChar value) {
        _uintValue = cast(GrUInt) value;
    }

    this(GrByte value) {
        _byteValue = value;
    }

    this(GrList value) {
        _ptrValue = cast(GrPointer) value;
    }

    this(GrValue[] value) {
        _ptrValue = cast(GrPointer) new GrList(value);
    }

    this(string value) {
        _ptrValue = cast(GrPointer) new GrString(value);
    }

    this(GrObject value) {
        _ptrValue = cast(GrPointer) value;
    }

    this(T)(T value) if (is(T == class)) {
        _ptrValue = cast(GrPointer) value;
    }

    this(T)(T[] values) {
        GrList list = new GrList;
        foreach (value; values) {
            list.pushBack(GrValue(value));
        }
        _ptrValue = cast(GrPointer) list;
    }

    this(GrPointer value) {
        _ptrValue = value;
    }

    static {
        GrValue asNull() {
            GrValue value;
            value._bytes = GR_NULL;
            return value;
        }
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
        return cast(GrBool) _intValue;
    }

    pragma(inline) GrInt getInt() const {
        return _intValue;
    }

    pragma(inline) GrUInt getUInt() const {
        return _uintValue;
    }

    pragma(inline) GrChar getChar() const {
        return cast(GrChar) _uintValue;
    }

    pragma(inline) GrByte getByte() const {
        return _byteValue;
    }

    pragma(inline) T getEnum(T)() const {
        return cast(T) _intValue;
    }

    pragma(inline) GrFloat getFloat() const {
        return _floatValue;
    }

    pragma(inline) GrDouble getDouble() const {
        return _doubleValue;
    }

    pragma(inline) GrPointer getPointer() const {
        return cast(GrPointer) _ptrValue;
    }

    pragma(inline) GrString getString() const {
        return cast(GrString) _ptrValue;
    }

    pragma(inline) GrList getList() const {
        return cast(GrList) _ptrValue;
    }

    pragma(inline) GrChannel getChannel() const {
        return cast(GrChannel) _ptrValue;
    }

    pragma(inline) GrObject getObject() const {
        return cast(GrObject) _ptrValue;
    }

    pragma(inline) T getNative(T)() const {
        return cast(T) _ptrValue;
    }

    pragma(inline) void setBool(GrBool value) {
        _intValue = cast(GrInt) value;
    }

    pragma(inline) void setInt(GrInt value) {
        _intValue = value;
    }

    pragma(inline) void setUInt(GrUInt value) {
        _uintValue = value;
    }

    pragma(inline) void setChar(GrChar value) {
        _uintValue = cast(GrUInt) value;
    }

    pragma(inline) void setByte(GrByte value) {
        _byteValue = value;
    }

    pragma(inline) void setEnum(T)(T value) {
        _intValue = cast(GrInt) value;
    }

    pragma(inline) void setFloat(GrFloat value) {
        _floatValue = value;
    }

    pragma(inline) void setDouble(GrDouble value) {
        _doubleValue = value;
    }

    pragma(inline) void setPointer(GrPointer value) {
        _ptrValue = value;
    }

    pragma(inline) void setString(GrString value) {
        _ptrValue = cast(GrPointer) value;
    }

    pragma(inline) void setString(string value) {
        (cast(GrString) _ptrValue) = value;
    }

    pragma(inline) void setList(GrList value) {
        _ptrValue = cast(GrPointer) value;
    }

    pragma(inline) void setList(GrValue[] value) {
        _ptrValue = cast(GrPointer) new GrList(value);
    }

    pragma(inline) void setChannel(GrChannel value) {
        _ptrValue = cast(GrPointer) value;
    }

    pragma(inline) void setObject(GrObject value) {
        _ptrValue = cast(GrPointer) value;
    }

    pragma(inline) void setNative(T)(T value) {
        _ptrValue = *cast(GrPointer*)&value;
    }
}
