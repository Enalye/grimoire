/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.assembly.symbol;

import std.format, std.file, std.bitmanip, std.array, std.outbuffer;
import std.conv : to;

alias GrBool = bool;
alias GrInt = int;
alias GrReal = double;
alias GrString = string;
alias GrArray = GrValue[];
alias GrPtr = void*;

/// Runtime array, can only hold one subtype.
package(grimoire) final class GrArrayWrapper {
    /// Payload
    private {
        GrValue[] _data;
    }

    this() {
    }

    this(GrArray value) {
        _data = value;
    }

    this(GrInt initialSize) {
        _data.reserve(initialSize);
    }

    @property {
        pragma(inline) GrInt length() {
            return cast(GrInt) _data.length;
        }

        pragma(inline) GrArray data() {
            return _data;
        }

        pragma(inline) GrArray data(GrArray value) {
            return _data = value;
        }
    }

    pragma(inline) void append(GrValue value) {
        _data ~= value;
    }
}

/// Runtime string
package(grimoire) final class GrStringWrapper {
    private {
        string _data;
    }

    this() {
    }

    this(GrBool value) {
        _data = value ? "true" : "false";
    }

    this(GrInt value) {
        _data = to!string(value);
    }

    this(GrReal value) {
        _data = to!string(value);
    }

    this(GrStringWrapper str) {
        _data = str._data.dup;
    }

    this(string str) {
        _data = str;
    }

    @property {
        GrInt length() {
            return cast(GrInt) _data.length;
        }

        pragma(inline) GrString data() {
            return _data;
        }

        pragma(inline) GrString data(GrString value) {
            return _data = value;
        }
    }

    void append(GrStringWrapper str) {
        _data ~= str._data;
    }
}

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
        _ovalue = cast(GrPtr) new GrArrayWrapper(value);
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

/// Stack trace
struct GrStackTrace {
    /// Where the error was raised inside this function
    uint pc;
    /// The name of the function
    string name;
    /// Source file from where the stack trace was generated
    string file;
    /// Position inside the source file where the error happened
    uint line;
    /// Ditto
    uint column;
}

/**
A class that contains debug information, should always be overridden
*/
abstract class GrSymbol {
    /// Type of symbol
    enum Type : uint {
        none = 0,
        function_
    }
    /// Ditto
    Type type;

    /// Serialize the symbol into the bytecode
    void serialize(ref Appender!(ubyte[]));
    /// Deserialize the symbol from the bytecode
    void deserialize(ref ubyte[] buffer);

    /**
    Stringify the debug information
    */
    string prettify();
}

/**

*/
final class GrFunctionSymbol : GrSymbol {
    public {
        /**
        Location of the function in the bytecode
        */
        uint start;
        /**
        Number of opcodes in the function
        */
        uint length;
        /**
        Name of the function
        */
        string name;
        /// File where the function is defined
        string file;
        /// Corresponding position in the source for each bytecode
        struct Position {
            /// Source coordinates
            uint line, column;
        }
        /// Ditto
        Position[] positions;
    }

    /// Ctor
    this() {
        type = Type.function_;
    }

    /// Serialize the symbol into the bytecode
    override void serialize(ref Appender!(ubyte[]) buffer) {
        buffer.append!uint(start);
        buffer.append!uint(length);

        writeStr(buffer, name);
        writeStr(buffer, file);

        buffer.append!uint(cast(uint) positions.length);
        for (uint i; i < positions.length; ++i) {
            buffer.append!uint(positions[i].line);
            buffer.append!uint(positions[i].column);
        }
    }

    /// Deserialize the symbol from the bytecode
    override void deserialize(ref ubyte[] buffer) {
        start = buffer.read!uint();
        length = buffer.read!uint();

        name = readStr(buffer);
        file = readStr(buffer);

        positions.length = buffer.read!uint();
        for (uint i; i < positions.length; ++i) {
            positions[i].line = buffer.read!uint();
            positions[i].column = buffer.read!uint();
        }
    }

    override string prettify() {
        return format("%d+%d\t%s", start, length, name);
    }
}

private string readStr(ref ubyte[] buffer) {
    string s;
    const uint size = buffer.read!uint();
    if (size == 0)
        return s;
    foreach (_; 0 .. size)
        s ~= buffer.read!char();
    return s;
}

private void writeStr(ref Appender!(ubyte[]) buffer, string s) {
    buffer.append!uint(cast(uint) s.length);
    buffer.put(cast(ubyte[]) s);
}
