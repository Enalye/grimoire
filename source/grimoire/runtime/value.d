/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.value;

import grimoire.assembly;
import grimoire.runtime.string;
import grimoire.runtime.array;

package(grimoire) enum GR_NULL = 0xffffUL << 48;

struct GrValue {
    package(grimoire) union {
        GrInt _ivalue;
        GrReal _rvalue;
        GrPtr _ovalue;
        ulong _bytes;
    }

    this(GrInt value) {
        _ivalue = value;
    }

    this(GrReal value) {
        _rvalue = value;
    }

    this(GrArray value) {
        _ovalue = cast(GrPtr) value;
    }

    this(GrValue[] value) {
        _ovalue = cast(GrPtr) new GrArray(value);
    }

    this(GrStr value) {
        _ovalue = cast(GrPtr) new GrString(value);
    }

    this(GrPtr value) {
        _ovalue = value;
    }

    pragma(inline) void setNull() {
        _bytes = GR_NULL;
    }

    pragma(inline) GrBool getBool() {
        return cast(GrBool) _ivalue;
    }

    pragma(inline) void setBool(GrBool value) {
        _ivalue = cast(GrInt) value;
    }

    pragma(inline) GrInt getInt() {
        return _ivalue;
    }

    pragma(inline) void setInt(GrInt value) {
        _ivalue = value;
    }

    pragma(inline) GrReal getReal() {
        return _rvalue;
    }

    pragma(inline) void setReal(GrReal value) {
        _rvalue = value;
    }

    pragma(inline) GrPtr getPtr() {
        return _ovalue;
    }

    pragma(inline) void setPtr(GrPtr value) {
        _ovalue = value;
    }

    pragma(inline) GrString getString() const {
        return cast(GrString) _ovalue;
    }

    pragma(inline) GrStr getStringData() const {
        return (cast(GrString) _ovalue).data;
    }

    pragma(inline) void setString(GrString value) {
        _ovalue = cast(GrPtr) value;
    }

    pragma(inline) void setString(GrStr value) {
        (cast(GrString) _ovalue) = value;
    }

    pragma(inline) GrArray getArray() const {
        return cast(GrArray) _ovalue;
    }

    pragma(inline) GrValue[] getArrayData() const {
        return (cast(GrArray) _ovalue).data;
    }

    pragma(inline) void setArray(GrArray value) {
        _ovalue = cast(GrPtr) value;
    }

    pragma(inline) void setArray(GrValue[] value) {
        (cast(GrArray) _ovalue) = value;
    }

    @property {
        pragma(inline) GrBool isNull() const {
            return _bytes == GR_NULL;
        }
    }
}
