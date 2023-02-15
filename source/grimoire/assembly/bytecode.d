/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.assembly.bytecode;

import std.file, std.bitmanip, std.array, std.outbuffer;
import grimoire.assembly.symbol;

/// Correspond à une version du langage. \
/// Un bytecode ayant une version différente ne pourra pas être chargé.
enum GR_VERSION = 700;

package(grimoire) {
    enum GR_MASK_INT = 0x1;
    enum GR_MASK_UINT = 0x2;
    enum GR_MASK_FLOAT = 0x4;
    enum GR_MASK_STRING = 0x8;
    enum GR_MASK_POINTER = 0x10;
}

/// Instructions bas niveau de la machine virtuelle.
enum GrOpcode {
    nop,
    throw_,
    try_,
    catch_,
    die,
    exit,
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
    const_uint,
    const_float,
    const_bool,
    const_string,
    const_meta,
    const_null,

    globalPush,
    globalPop,

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
    checkNull,
    optionalTry,
    optionalOr,
    optionalCall,
    optionalCall2,

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

    copy,
    swap,

    setupIterator,

    localStack,
    call,
    anonymousCall,
    primitiveCall,
    safePrimitiveCall,
    return_,
    unwind,
    defer,
    jump,
    jumpEqual,
    jumpNotEqual,

    list,
    length_list,
    index_list,
    index2_list,
    index3_list,

    concatenate_list,
    append_list,
    prepend_list,

    equal_list,
    notEqual_list,

    debugProfileBegin,
    debugProfileEnd
}

private immutable string[] _prettyInstructions = [
    "nop", "throw", "try", "catch", "die", "exit", "yield", "task", "atask",
    "new", "chan", "snd", "rcv", "select_start", "select_end", "chan_try",
    "chan_check", "shift", "lstore", "lstore2", "lload", "gstore", "gstore2",
    "gload", "rstore", "rstore2", "frstore", "frload", "frload2", "fload",
    "fload2", "const.i", "const.u", "const.f", "const.b", "const.s", "meta",
    "null", "gpush", "gpop", "eq.i", "eq.f", "eq.s", "neq.i", "neq.f",
    "neq.s", "geq.i", "geq.f", "leq.i", "leq.f", "gt.i", "gt.f", "lt.i", "lt.f",
    "check_null", "opt_try", "opt_or", "opt_call", "opt_call2", "and.i", "or.i",
    "not.i", "cat.s", "add.i", "add.f", "sub.i", "sub.f", "mul.i", "mul.f",
    "div.i", "div.f", "rem.i", "rem.f", "neg.i", "neg.f", "inc.i", "inc.f",
    "dec.i", "dec.f", "copy", "swap", "setup_it", "local", "call", "acall",
    "pcall", "spcall", "ret", "unwind", "defer", "jmp", "jmp_eq", "jmp_neq",
    "list", "len", "idx", "idx2", "idx3", "cat.n", "append", "prepend",
    "eq.n", "neq.n", "dbg_prfbegin", "dbg_prfend"
];

/// Référence d’une classe.
package(grimoire) class GrClassBuilder {
    /// Nom de la classe
    string name;
    /// Les champs de la classe
    string[] fields;
}

/// Forme compilée d’un code grimoire.
final class GrBytecode {
    package(grimoire) {
        /// Données utilisées pour créer les objets `GrCall`.
        struct PrimitiveReference {
            /// L’index de la primitive
            int index;
            /// Nom de la primitive
            string name;
            /// Paramètres
            uint params;
            /// Ditto
            uint[] parameters;
            /// Signature
            string[] inSignature, outSignature;
        }

        struct EnumReference {
            struct Field {
                string name;
                GrInt value;
            }

            string name;
            Field[] fields;
        }

        /// Référence une variable globale.
        struct Variable {
            /// L’index de la variable
            uint index;
            /// Type de valeur
            uint typeMask;
            /// Valeur entière initiale
            GrInt ivalue;
            /// Valeur entière non-signée initiale
            GrUint uvalue;
            /// Valeur flottante initiale
            GrFloat fvalue;
            /// Valeur textuelle initiale
            GrStringValue svalue;
        }

        /// Version du bytecode.
        uint grimoireVersion, userVersion;

        /// Toutes les instructions.
        uint[] opcodes;

        /// Constantes entières.
        GrInt[] iconsts;

        /// Constantes entières non-signées.
        GrUint[] uconsts;

        /// Constantes flottantes.
        GrFloat[] fconsts;

        /// Constantes textuelles.
        GrStringValue[] sconsts;

        /// Primitives appelables.
        PrimitiveReference[] primitives;

        /// Énumérations.
        EnumReference[] enums;

        /// Toutes les classes.
        GrClassBuilder[] classes;

        /// Nombre de variables globales déclarées.
        uint globalsCount;

        /// Événements globaux
        uint[string] events;

        /// Variables globales
        Variable[string] variables;

        /// Symboles de déboguage
        GrSymbol[] symbols;
    }

    /// Préfixe des fichiers grimoires compilés.
    private immutable magicWord = "grb";

    this() {
    }

    /// Charger depuis un bytecode
    this(GrBytecode bytecode) {
        opcodes = bytecode.opcodes;
        iconsts = bytecode.iconsts;
        uconsts = bytecode.uconsts;
        fconsts = bytecode.fconsts;
        sconsts = bytecode.sconsts;
        primitives = bytecode.primitives;
        enums = bytecode.enums;
        classes = bytecode.classes;
        globalsCount = bytecode.globalsCount;
        events = bytecode.events;
        variables = bytecode.variables;
        symbols = bytecode.symbols.dup; //@TODO: changer la copie superficielle
    }

    /// Charger depuis un fichier
    this(string filePath) {
        load(filePath);
    }

    /// Charger depuis un buffer
    this(ubyte[] buffer) {
        deserialize(buffer);
    }

    /// Vérifie si la version de grimoire est correcte
    bool checkVersion(uint userVersion_ = 0u) {
        return (grimoireVersion == GR_VERSION) && (userVersion == userVersion_);
    }

    /// Enregistre le bytecode dans un fichier.
    void save(string fileName) {
        std.file.write(fileName, serialize());
    }

    /// Récupère l’ensemble des événements globaux.
    string[] getEvents() {
        return events.keys;
    }

    /// Sérialise le bytecode
    ubyte[] serialize() {
        void writeStr(ref Appender!(ubyte[]) buffer, GrStringValue s) {
            buffer.append!uint(cast(uint) s.length);
            buffer.put(cast(ubyte[]) s);
        }

        Appender!(ubyte[]) buffer = appender!(ubyte[]);
        buffer.put(cast(ubyte[]) magicWord);

        buffer.append!uint(cast(uint) grimoireVersion);
        buffer.append!uint(cast(uint) userVersion);

        buffer.append!uint(cast(uint) iconsts.length);
        buffer.append!uint(cast(uint) uconsts.length);
        buffer.append!uint(cast(uint) fconsts.length);
        buffer.append!uint(cast(uint) sconsts.length);
        buffer.append!uint(cast(uint) opcodes.length);

        buffer.append!uint(globalsCount);

        buffer.append!uint(cast(uint) events.length);
        buffer.append!uint(cast(uint) primitives.length);
        buffer.append!uint(cast(uint) enums.length);
        buffer.append!uint(cast(uint) classes.length);
        buffer.append!uint(cast(uint) variables.length);
        buffer.append!uint(cast(uint) symbols.length);

        foreach (GrInt i; iconsts)
            buffer.append!GrInt(i);
        foreach (GrInt i; uconsts)
            buffer.append!GrUint(i);
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
            writeStr(buffer, primitive.name);
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

        foreach (enum_; enums) {
            writeStr(buffer, enum_.name);
            buffer.append!uint(cast(uint) enum_.fields.length);
            for (size_t i; i < enum_.fields.length; ++i) {
                writeStr(buffer, enum_.fields[i].name);
                buffer.append!uint(enum_.fields[i].value);
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
            if (reference.typeMask & GR_MASK_INT)
                buffer.append!GrInt(reference.ivalue);
            else if (reference.typeMask & GR_MASK_UINT)
                buffer.append!GrUint(reference.uvalue);
            else if (reference.typeMask & GR_MASK_FLOAT)
                buffer.append!GrFloat(reference.fvalue);
            else if (reference.typeMask & GR_MASK_STRING)
                writeStr(buffer, reference.svalue);
        }

        // Sérialise les symboles
        foreach (GrSymbol symbol; symbols) {
            buffer.append!uint(symbol.type);
            symbol.serialize(buffer);
        }

        return buffer.data;
    }

    /// Charge le bytecode depuis un fichier
    void load(string fileName) {
        deserialize(cast(ubyte[]) std.file.read(fileName));
    }

    /// Désérialise le bytecode depuis un buffer
    void deserialize(ubyte[] buffer) {
        GrStringValue readStr(ref ubyte[] buffer) {
            GrStringValue s;
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

        grimoireVersion = buffer.read!uint();
        userVersion = buffer.read!uint();

        // Si la version diffère, l’encodage de la suite peut-être différent
        // On évite donc de désérialiser la suite
        if (grimoireVersion != GR_VERSION)
            return;

        iconsts.length = buffer.read!uint();
        uconsts.length = buffer.read!uint();
        fconsts.length = buffer.read!uint();
        sconsts.length = buffer.read!uint();
        opcodes.length = buffer.read!uint();

        globalsCount = buffer.read!uint();

        const uint eventsCount = buffer.read!uint();
        primitives.length = buffer.read!uint();
        enums.length = buffer.read!uint();
        classes.length = buffer.read!uint();
        const uint variableCount = buffer.read!uint();
        symbols.length = buffer.read!uint();

        for (uint i; i < iconsts.length; ++i) {
            iconsts[i] = buffer.read!GrInt();
        }

        for (uint i; i < uconsts.length; ++i) {
            uconsts[i] = buffer.read!GrUint();
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
            primitives[i].name = readStr(buffer);
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

        for (size_t i; i < enums.length; ++i) {
            enums[i].name = readStr(buffer);
            const uint fieldsCount = buffer.read!uint();
            enums[i].fields.length = fieldsCount;
            for (size_t y; y < fieldsCount; ++y) {
                enums[i].fields[y].name = readStr(buffer);
                enums[i].fields[y].value = buffer.read!uint();
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
            if (reference.typeMask & GR_MASK_INT)
                reference.ivalue = buffer.read!GrInt();
            else if (reference.typeMask & GR_MASK_UINT)
                reference.uvalue = buffer.read!GrUint();
            else if (reference.typeMask & GR_MASK_FLOAT)
                reference.fvalue = buffer.read!GrFloat();
            else if (reference.typeMask & GR_MASK_STRING)
                reference.svalue = readStr(buffer);
            variables[name] = reference;
        }

        // Désérialise les symboles
        for (uint i; i < symbols.length; ++i) {
            GrSymbol symbol;
            const uint type = buffer.read!uint();
            if (type > GrSymbol.Type.max)
                return;
            final switch (type) with (GrSymbol.Type) {
            case none:
                break;
            case func:
                symbol = new GrFunctionSymbol;
                break;
            }
            symbol.type = cast(GrSymbol.Type) type;
            symbol.deserialize(buffer);
            symbols[i] = symbol;
        }
    }

    /// Formate la liste des instructions du bytecode dans un format lisible.
    string prettify() {
        import std.conv : to;
        import std.string : leftJustify;
        import grimoire.compiler;

        string result;
        uint i;
        foreach (uint opcode; opcodes) {
            GrOpcode op = cast(GrOpcode) grGetInstructionOpcode(opcode);

            string line = leftJustify("[" ~ to!string(i) ~ "]", 10) ~ leftJustify(
                _prettyInstructions[op], 15);
            if ((op == GrOpcode.task) || (op >= GrOpcode.localStore &&
                    op <= GrOpcode.localLoad) || (op >= GrOpcode.globalStore && op <= GrOpcode.globalLoad) ||
                op == GrOpcode.globalPush || (op >= GrOpcode.localStack && op <= GrOpcode.call) ||
                (op == GrOpcode.new_) || (op >= GrOpcode.fieldRefLoad &&
                    op <= GrOpcode.fieldLoad2) || (op == GrOpcode.channel) || (op == GrOpcode.list))
                line ~= to!string(grGetInstructionUnsignedValue(opcode));
            else if (op == GrOpcode.fieldRefStore)
                line ~= to!string(grGetInstructionSignedValue(opcode));
            else if (op == GrOpcode.shiftStack)
                line ~= to!string(grGetInstructionSignedValue(opcode));
            else if (op == GrOpcode.anonymousCall)
                line ~= to!string(grGetInstructionUnsignedValue(opcode));
            else if (op == GrOpcode.primitiveCall || op == GrOpcode.safePrimitiveCall) {
                const uint index = grGetInstructionUnsignedValue(opcode);
                if (index < primitives.length) {
                    const GrBytecode.PrimitiveReference primitive = primitives[index];

                    GrType[] inSignature, outSignature;
                    foreach (type; primitive.inSignature) {
                        inSignature ~= grUnmangle(type);
                    }
                    foreach (type; primitive.outSignature) {
                        outSignature ~= grUnmangle(type);
                    }

                    line ~= grGetPrettyFunction(primitive.name, inSignature, outSignature);
                }
                else {
                    line ~= to!string(index);
                }
            }
            else if (op == GrOpcode.const_int)
                line ~= to!string(iconsts[grGetInstructionUnsignedValue(opcode)]);
            else if (op == GrOpcode.const_uint)
                line ~= to!string(uconsts[grGetInstructionUnsignedValue(opcode)]);
            else if (op == GrOpcode.const_float)
                line ~= to!string(fconsts[grGetInstructionUnsignedValue(opcode)]);
            else if (op == GrOpcode.const_bool)
                line ~= (grGetInstructionUnsignedValue(opcode) ? "true" : "false");
            else if (op == GrOpcode.const_string || op == GrOpcode.const_meta ||
                op == GrOpcode.debugProfileBegin)
                line ~= "\"" ~ to!string(sconsts[grGetInstructionUnsignedValue(opcode)]) ~ "\"";
            else if (op >= GrOpcode.jump && op <= GrOpcode.jumpNotEqual)
                line ~= to!string(i + grGetInstructionSignedValue(opcode));
            else if (op == GrOpcode.defer || op == GrOpcode.try_ || op == GrOpcode.catch_ ||
                op == GrOpcode.tryChannel || op == GrOpcode.optionalCall ||
                op == GrOpcode.optionalCall2)
                line ~= to!string(i + grGetInstructionSignedValue(opcode));

            i++;
            result ~= line ~ "\n";
        }
        return result;
    }
}

/// Récupère la partie valeur non-signée d’une instruction
pure uint grGetInstructionUnsignedValue(uint instruction) {
    return (instruction >> 8u) & 0xffffff;
}

/// Récupère la partie valeur signée d’une instruction
pure int grGetInstructionSignedValue(uint instruction) {
    return (cast(int)((instruction >> 8u) & 0xffffff)) - 0x800000;
}

/// Récupère la partie instruction d’une instruction
pure uint grGetInstructionOpcode(uint instruction) {
    return instruction & 0xff;
}

/// Forme une instruction.
pure uint grMakeInstruction(uint instr, uint value1, uint value2) {
    return ((value2 << 16u) & 0xffff0000) | ((value1 << 8u) & 0xff00) | (instr & 0xff);
}
