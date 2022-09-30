module grimoire.runtime.value;

import grimoire.assembly;
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

    this(GrString value) {
        _ovalue = cast(GrPtr) new GrStringWrapper(value);
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

    pragma(inline) GrBool setBool(GrBool value) {
        return _ivalue = cast(GrInt) value;
    }

    pragma(inline) GrInt getInt() {
        return _ivalue;
    }

    pragma(inline) GrInt setInt(GrInt value) {
        return _ivalue = value;
    }

    pragma(inline) GrReal getReal() {
        return _rvalue;
    }

    pragma(inline) GrReal setReal(GrReal value) {
        return _rvalue = value;
    }

    pragma(inline) GrPtr getPtr() {
        return _ovalue;
    }

    pragma(inline) GrPtr setPtr(GrPtr value) {
        return _ovalue = value;
    }

    pragma(inline) GrString getString() const {
        return (cast(GrStringWrapper) _ovalue).data;
    }

    pragma(inline) GrString setString(GrString value) {
        return (cast(GrStringWrapper) _ovalue).data = value;
    }

    @property {
        pragma(inline) GrBool isNull() const {
            return _bytes == GR_NULL;
        }
    }
}
