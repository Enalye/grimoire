/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.assembly.bytecode;

import std.file, std.bitmanip, std.array, std.outbuffer;
import grimoire.assembly.symbol;

/// Low-level instructions for the VM.
enum GrOpcode {
    nop,
    throw_,
    try_,
    catch_,
    die,
    quit,
    yield,
    task,
    anonymousTask,
    new_,

    channel,
    send,
    receive,
    startSelectChannel,
    endSelectChannel,
    tryChannel,
    checkChannel,

    shiftStack,

    localStore,
    localStore2,
    localLoad,

    globalStore,
    globalStore2,
    globalLoad,

    refStore,
    refStore2,

    fieldRefStore,
    fieldRefLoad,
    fieldRefLoad2,
    fieldLoad,
    fieldLoad2,

    const_int,
    const_real,
    const_bool,
    const_string,
    const_meta,
    const_null,

    globalPush,
    globalPop,

    equal_int,
    equal_real,
    equal_string,
    notEqual_int,
    notEqual_real,
    notEqual_string,
    greaterOrEqual_int,
    greaterOrEqual_real,
    lesserOrEqual_int,
    lesserOrEqual_real,
    greater_int,
    greater_real,
    lesser_int,
    lesser_real,
    checkNull,

    and_int,
    or_int,
    not_int,
    concatenate_string,
    add_int,
    add_real,
    substract_int,
    substract_real,
    multiply_int,
    multiply_real,
    divide_int,
    divide_real,
    remainder_int,
    remainder_real,
    negative_int,
    negative_real,
    increment_int,
    increment_real,
    decrement_int,
    decrement_real,

    copy,
    swap,

    setupIterator,

    localStack,
    call,
    anonymousCall,
    primitiveCall,
    return_,
    unwind,
    defer,
    jump,
    jumpEqual,
    jumpNotEqual,

    array,
    length_array,
    index_array,
    index2_array,
    index3_array,

    concatenate_array,
    append_array,
    prepend_array,

    equal_array,
    notEqual_array,

    debugProfileBegin,
    debugProfileEnd
}

/// Class reference
package(grimoire) class GrClassBuilder {
    /// Class name
    string name;
    /// All its fields
    string[] fields;
}

/// Compiled form of grimoire.
final class GrBytecode {
    package(grimoire) {
        /// Data used to setup GrCall objects.
        struct PrimitiveReference {
            /// Callback index
            int index;
            /// Parameters
            uint params;
            /// Ditto
            uint[] parameters;
            /// Signature
            string[] inSignature, outSignature;
        }

        /// Reference to a global variable.
        struct Variable {
            /// Register
            uint index;
            /// Type of value
            uint typeMask;
            /// Integral init value
            GrInt ivalue;
            /// Realing init value
            GrReal rvalue;
            /// String init value
            GrString svalue;
        }

        /// All the instructions.
        uint[] opcodes;

        /// Integer constants.
        GrInt[] iconsts;

        /// Realing point constants.
        GrReal[] rconsts;

        /// String constants.
        GrString[] sconsts;

        /// Callable primitives.
        PrimitiveReference[] primitives;

        /// All the classes.
        GrClassBuilder[] classes;

        /// Number of global variables declared.
        uint globalsCount;

        /// global event functions.
        /// Their name are in a mangled state.
        uint[string] events;

        /// Global variables
        Variable[string] variables;

        GrSymbol[] symbols;
    }

    private immutable magicWord = "grb";

    /// Default ctor
    this() {
    }

    /// Copy ctor
    this(GrBytecode bytecode) {
        opcodes = bytecode.opcodes;
        iconsts = bytecode.iconsts;
        rconsts = bytecode.rconsts;
        sconsts = bytecode.sconsts;
        primitives = bytecode.primitives;
        classes = bytecode.classes;
        globalsCount = bytecode.globalsCount;
        events = bytecode.events;
        variables = bytecode.variables;
        symbols = bytecode.symbols.dup; //@TODO: change the shallow copy
    }

    /// Load from a file
    this(string filePath) {
        load(filePath);
    }

    /// Load from bytes
    this(ubyte[] buffer) {
        deserialize(buffer);
    }

    string[] getEvents() {
        return events.keys;
    }

    /// Save the bytecode to a file.
    void save(string fileName) {
        std.file.write(fileName, serialize());
    }

    /// Serialize the bytecode into an array.
    ubyte[] serialize() {
        void writeStr(ref Appender!(ubyte[]) buffer, GrString s) {
            buffer.append!uint(cast(uint) s.length);
            buffer.put(cast(ubyte[]) s);
        }

        Appender!(ubyte[]) buffer = appender!(ubyte[]);
        buffer.put(cast(ubyte[]) magicWord);

        buffer.append!uint(cast(uint) iconsts.length);
        buffer.append!uint(cast(uint) rconsts.length);
        buffer.append!uint(cast(uint) sconsts.length);
        buffer.append!uint(cast(uint) opcodes.length);

        buffer.append!uint(globalsCount);

        buffer.append!uint(cast(uint) events.length);
        buffer.append!uint(cast(uint) primitives.length);
        buffer.append!uint(cast(uint) classes.length);
        buffer.append!uint(cast(uint) variables.length);
        buffer.append!uint(cast(uint) symbols.length);

        foreach (GrInt i; iconsts)
            buffer.append!GrInt(i);
        foreach (GrReal i; rconsts)
            buffer.append!GrReal(i);
        foreach (string i; sconsts) {
            writeStr(buffer, i);
        }
        // Opcodes
        foreach (uint i; opcodes)
            buffer.append!uint(i);
        foreach (string ev, uint pos; events) {
            writeStr(buffer, ev);
            buffer.append!uint(pos);
        }

        foreach (primitive; primitives) {
            buffer.append!uint(cast(uint) primitive.index);
            buffer.append!uint(primitive.params);

            buffer.append!uint(cast(uint) primitive.inSignature.length);
            buffer.append!uint(cast(uint) primitive.outSignature.length);
            for (size_t i; i < primitive.inSignature.length; ++i) {
                buffer.append!uint(primitive.parameters[i]);
                writeStr(buffer, primitive.inSignature[i]);
            }
            for (size_t i; i < primitive.outSignature.length; ++i) {
                writeStr(buffer, primitive.outSignature[i]);
            }
        }

        foreach (class_; classes) {
            writeStr(buffer, class_.name);
            buffer.append!uint(cast(uint) class_.fields.length);
            foreach (field; class_.fields) {
                writeStr(buffer, field);
            }
        }

        foreach (string name, ref Variable reference; variables) {
            writeStr(buffer, name);
            buffer.append!uint(reference.index);
            buffer.append!uint(reference.typeMask);
            if (reference.typeMask & 0x1)
                buffer.append!GrInt(reference.ivalue);
            else if (reference.typeMask & 0x2)
                buffer.append!GrReal(reference.rvalue);
            else if (reference.typeMask & 0x4)
                writeStr(buffer, reference.svalue);
        }

        // Serialize symbols
        foreach (GrSymbol symbol; symbols) {
            buffer.append!uint(symbol.type);
            symbol.serialize(buffer);
        }

        return buffer.data;
    }

    /// Load the bytecode from a file.
    void load(string fileName) {
        deserialize(cast(ubyte[]) std.file.read(fileName));
    }

    /// Deserialize the bytecode from an array.
    void deserialize(ubyte[] buffer) {
        GrString readStr(ref ubyte[] buffer) {
            GrString s;
            const uint size = buffer.read!uint();
            if (size == 0)
                return s;
            foreach (_; 0 .. size)
                s ~= buffer.read!char();
            return s;
        }

        if (buffer.length < magicWord.length)
            throw new Exception("invalid bytecode");
        if (buffer[0 .. magicWord.length] != magicWord)
            throw new Exception("invalid bytecode");
        buffer = buffer[magicWord.length .. $];

        iconsts.length = buffer.read!uint();
        rconsts.length = buffer.read!uint();
        sconsts.length = buffer.read!uint();
        opcodes.length = buffer.read!uint();

        globalsCount = buffer.read!uint();

        const uint eventsCount = buffer.read!uint();
        primitives.length = buffer.read!uint();
        classes.length = buffer.read!uint();
        const uint variableCount = buffer.read!uint();
        symbols.length = buffer.read!uint();

        for (uint i; i < iconsts.length; ++i) {
            iconsts[i] = buffer.read!GrInt();
        }

        for (uint i; i < rconsts.length; ++i) {
            rconsts[i] = buffer.read!GrReal();
        }

        for (uint i; i < sconsts.length; ++i) {
            sconsts[i] = readStr(buffer);
        }

        // Opcodes
        for (size_t i; i < opcodes.length; ++i) {
            opcodes[i] = buffer.read!uint();
        }

        events.clear();
        for (uint i; i < eventsCount; ++i) {
            const string ev = readStr(buffer);
            events[ev] = buffer.read!uint();
        }

        for (size_t i; i < primitives.length; ++i) {
            primitives[i].index = buffer.read!uint();
            primitives[i].params = buffer.read!uint();

            const uint inParamsCount = buffer.read!uint();
            const uint outParamsCount = buffer.read!uint();
            primitives[i].parameters.length = inParamsCount;
            primitives[i].inSignature.length = inParamsCount;
            primitives[i].outSignature.length = outParamsCount;
            for (size_t y; y < inParamsCount; ++y) {
                primitives[i].parameters[y] = buffer.read!uint();
                primitives[i].inSignature[y] = readStr(buffer);
            }
            for (size_t y; y < outParamsCount; ++y) {
                primitives[i].outSignature[y] = readStr(buffer);
            }
        }

        for (size_t i; i < classes.length; ++i) {
            GrClassBuilder class_ = new GrClassBuilder;
            class_.name = readStr(buffer);
            class_.fields.length = buffer.read!uint();

            for (size_t y; y < class_.fields.length; ++y) {
                class_.fields[y] = readStr(buffer);
            }

            classes[i] = class_;
        }

        variables.clear();
        for (uint i; i < variableCount; ++i) {
            const string name = readStr(buffer);
            Variable reference;
            reference.index = buffer.read!uint();
            reference.typeMask = buffer.read!uint();
            if (reference.typeMask & 0x1)
                reference.ivalue = buffer.read!GrInt();
            else if (reference.typeMask & 0x2)
                reference.rvalue = buffer.read!GrReal();
            else if (reference.typeMask & 0x4)
                reference.svalue = readStr(buffer);
            variables[name] = reference;
        }

        // Deserialize symbols
        for (uint i; i < symbols.length; ++i) {
            GrSymbol symbol;
            const uint type = buffer.read!uint();
            if (type > GrSymbol.Type.max)
                return;
            final switch (type) with (GrSymbol.Type) {
            case none:
                break;
            case function_:
                symbol = new GrFunctionSymbol;
                break;
            }
            symbol.type = cast(GrSymbol.Type) type;
            symbol.deserialize(buffer);
            symbols[i] = symbol;
        }
    }
}

/// Get the unsigned value part of an instruction
pure uint grGetInstructionUnsignedValue(uint instruction) {
    return (instruction >> 8u) & 0xffffff;
}

/// Get the signed value part of an instruction
pure int grGetInstructionSignedValue(uint instruction) {
    return (cast(int)((instruction >> 8u) & 0xffffff)) - 0x800000;
}

/// Get the opcode part of an instruction
pure uint grGetInstructionOpcode(uint instruction) {
    return instruction & 0xff;
}

/// Format an instruction.
pure uint grMakeInstruction(uint instr, uint value1, uint value2) {
    return ((value2 << 16u) & 0xffff0000) | ((value1 << 8u) & 0xff00) | (instr & 0xff);
}
