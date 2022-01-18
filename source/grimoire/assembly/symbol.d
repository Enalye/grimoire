/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.assembly.symbol;

import std.format, std.file, std.bitmanip, std.array, std.outbuffer;

alias GrBool = bool;
alias GrInt = long;
alias GrReal = double;
alias GrString = string;
alias GrPtr = void*;

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
