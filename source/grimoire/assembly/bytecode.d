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
    raise_,
    try_,
    catch_,
    kill_,
    killAll_,
    yield,
    task,
    anonymousTask,
    new_,

    channel_int,
    channel_float,
    channel_string,
    channel_object,
    send_int,
    send_float,
    send_string,
    send_object,
    receive_int,
    receive_float,
    receive_string,
    receive_object,
    startSelectChannel,
    endSelectChannel,
    tryChannel,
    checkChannel,

    shiftStack_int,
    shiftStack_float,
    shiftStack_string,
    shiftStack_object,

    localStore_int,
    localStore_float,
    localStore_string,
    localStore_object,
    localStore2_int,
    localStore2_float,
    localStore2_string,
    localStore2_object,
    localLoad_int,
    localLoad_float,
    localLoad_string,
    localLoad_object,

    globalStore_int,
    globalStore_float,
    globalStore_string,
    globalStore_object,
    globalStore2_int,
    globalStore2_float,
    globalStore2_string,
    globalStore2_object,
    globalLoad_int,
    globalLoad_float,
    globalLoad_string,
    globalLoad_object,

    refStore_int,
    refStore_float,
    refStore_string,
    refStore_object,
    refStore2_int,
    refStore2_float,
    refStore2_string,
    refStore2_object,

    fieldStore_int,
    fieldStore_float,
    fieldStore_string,
    fieldStore_object,
    fieldLoad,
    fieldLoad2,
    fieldLoad_int,
    fieldLoad_float,
    fieldLoad_string,
    fieldLoad_object,
    fieldLoad2_int,
    fieldLoad2_float,
    fieldLoad2_string,
    fieldLoad2_object,

    const_int,
    const_float,
    const_bool,
    const_string,
    const_meta,
    const_null,

    globalPush_int,
    globalPush_float,
    globalPush_string,
    globalPush_object,
    globalPop_int,
    globalPop_float,
    globalPop_string,
    globalPop_object,

    equal_int,
    equal_float,
    equal_string,
    notEqual_int,
    notEqual_float,
    notEqual_string,
    greaterOrEqual_int,
    greaterOrEqual_float,
    lesserOrEqual_int,
    lesserOrEqual_float,
    greater_int,
    greater_float,
    lesser_int,
    lesser_float,
    isNonNull_object,

    and_int,
    or_int,
    not_int,
    concatenate_string,
    add_int,
    add_float,
    substract_int,
    substract_float,
    multiply_int,
    multiply_float,
    divide_int,
    divide_float,
    remainder_int,
    remainder_float,
    negative_int,
    negative_float,
    increment_int,
    increment_float,
    decrement_int,
    decrement_float,

    copy_int,
    copy_float,
    copy_string,
    copy_object,
    swap_int,
    swap_float,
    swap_string,
    swap_object,

    setupIterator,

    localStack_int,
    localStack_float,
    localStack_string,
    localStack_object,
    call,
    anonymousCall,
    primitiveCall,
    return_,
    unwind,
    defer,
    jump,
    jumpEqual,
    jumpNotEqual,

    array_int,
    array_float,
    array_string,
    array_object,
    length_int,
    length_float,
    length_string,
    length_object,
    index_int,
    index_float,
    index_string,
    index_object,
    index2_int,
    index2_float,
    index2_string,
    index2_object,
    index3_int,
    index3_float,
    index3_string,
    index3_object,

    concatenate_intArray,
    concatenate_floatArray,
    concatenate_stringArray,
    concatenate_objectArray,
    append_int,
    append_float,
    append_string,
    append_object,
    prepend_int,
    prepend_float,
    prepend_string,
    prepend_object,

    equal_intArray,
    equal_floatArray,
    equal_stringArray,
    notEqual_intArray,
    notEqual_floatArray,
    notEqual_stringArray,

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
            uint iparams, fparams, sparams, oparams;
            /// Ditto
            uint[] parameters;
        }

        /// Reference to a global variable.
        struct Variable {
            /// Register
            uint index;
            /// Type of value
            uint typeMask;
            /// Integral init value
            GrInt ivalue;
            /// Floating init value
            GrFloat fvalue;
            /// String init value
            GrString svalue;
        }

        /// All the instructions.
        uint[] opcodes;

        /// Integer constants.
        GrInt[] iconsts;

        /// Floating point constants.
        GrFloat[] fconsts;

        /// String constants.
        GrString[] sconsts;

        /// Callable primitives.
        PrimitiveReference[] primitives;

        /// All the classes.
        GrClassBuilder[] classes;

        /// Number of int based global variables declared.
        uint iglobalsCount;
        /// Number of float based global variables declared.
        uint fglobalsCount;
        /// Number of string based global variables declared.
        uint sglobalsCount;
        /// Number of ptr based global variables declared.
        uint oglobalsCount;

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
        fconsts = bytecode.fconsts;
        sconsts = bytecode.sconsts;
        primitives = bytecode.primitives;
        classes = bytecode.classes;
        iglobalsCount = bytecode.iglobalsCount;
        fglobalsCount = bytecode.fglobalsCount;
        sglobalsCount = bytecode.sglobalsCount;
        oglobalsCount = bytecode.oglobalsCount;
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
        buffer.append!uint(cast(uint) fconsts.length);
        buffer.append!uint(cast(uint) sconsts.length);
        buffer.append!uint(cast(uint) opcodes.length);

        buffer.append!uint(iglobalsCount);
        buffer.append!uint(fglobalsCount);
        buffer.append!uint(sglobalsCount);
        buffer.append!uint(oglobalsCount);

        buffer.append!uint(cast(uint) events.length);
        buffer.append!uint(cast(uint) primitives.length);
        buffer.append!uint(cast(uint) classes.length);
        buffer.append!uint(cast(uint) variables.length);
        buffer.append!uint(cast(uint) symbols.length);

        foreach (GrInt i; iconsts)
            buffer.append!GrInt(i);
        foreach (GrFloat i; fconsts)
            buffer.append!GrFloat(i);
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
            buffer.append!uint(primitive.iparams);
            buffer.append!uint(primitive.fparams);
            buffer.append!uint(primitive.sparams);
            buffer.append!uint(primitive.oparams);

            buffer.append!uint(cast(uint) primitive.parameters.length);
            foreach (int i; primitive.parameters)
                buffer.append!uint(i);
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
                buffer.append!GrFloat(reference.fvalue);
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
        fconsts.length = buffer.read!uint();
        sconsts.length = buffer.read!uint();
        opcodes.length = buffer.read!uint();

        iglobalsCount = buffer.read!uint();
        fglobalsCount = buffer.read!uint();
        sglobalsCount = buffer.read!uint();
        oglobalsCount = buffer.read!uint();

        const uint eventsCount = buffer.read!uint();
        primitives.length = buffer.read!uint();
        classes.length = buffer.read!uint();
        const uint variableCount = buffer.read!uint();
        symbols.length = buffer.read!uint();

        for (uint i; i < iconsts.length; ++i) {
            iconsts[i] = buffer.read!GrInt();
        }

        for (uint i; i < fconsts.length; ++i) {
            fconsts[i] = buffer.read!GrFloat();
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
            primitives[i].iparams = buffer.read!uint();
            primitives[i].fparams = buffer.read!uint();
            primitives[i].sparams = buffer.read!uint();
            primitives[i].oparams = buffer.read!uint();

            primitives[i].parameters.length = buffer.read!uint();
            for (size_t y; y < primitives[i].parameters.length; ++y) {
                primitives[i].parameters[y] = buffer.read!uint();
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
                reference.fvalue = buffer.read!GrFloat();
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
