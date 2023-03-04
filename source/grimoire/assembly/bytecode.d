/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.assembly.bytecode;

import std.file, std.bitmanip, std.array, std.outbuffer;
import std.exception : enforce;

import grimoire.assembly.symbol;

/// Correspond à une version du langage. \
/// Un bytecode ayant une version différente ne pourra pas être chargé.
enum GR_VERSION = 800;

package(grimoire) {
    enum GR_MASK_INT = 0x1 << 1;
    enum GR_MASK_UINT = 0x1 << 2;
    enum GR_MASK_FLOAT = 0x1 << 3;
    enum GR_MASK_STRING = 0x1 << 4;
    enum GR_MASK_POINTER = 0x1 << 5;
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
    equal_uint,
    equal_float,
    equal_string,
    notEqual_int,
    notEqual_uint,
    notEqual_float,
    notEqual_string,
    greaterOrEqual_int,
    greaterOrEqual_uint,
    greaterOrEqual_float,
    lesserOrEqual_int,
    lesserOrEqual_uint,
    lesserOrEqual_float,
    greater_int,
    greater_uint,
    greater_float,
    lesser_int,
    lesser_uint,
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
    add_uint,
    add_float,
    substract_int,
    substract_uint,
    substract_float,
    multiply_int,
    multiply_uint,
    multiply_float,
    divide_int,
    divide_uint,
    divide_float,
    remainder_int,
    remainder_uint,
    remainder_float,
    negative_int,
    negative_float,
    increment_int,
    increment_uint,
    increment_float,
    decrement_int,
    decrement_uint,
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
            GrUInt uvalue;
            /// Valeur flottante initiale
            GrFloat fvalue;
            /// Valeur textuelle initiale
            string svalue;
        }

        /// Version du bytecode.
        uint grimoireVersion, userVersion;

        /// Toutes les instructions.
        uint[] opcodes;

        /// Constantes entières.
        GrInt[] iconsts;

        /// Constantes entières non-signées.
        GrUInt[] uconsts;

        /// Constantes flottantes.
        GrFloat[] fconsts;

        /// Constantes textuelles.
        string[] sconsts;

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
        void writeStr(ref Appender!(ubyte[]) buffer, string s) {
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
        foreach (GrUInt i; uconsts)
            buffer.append!GrUInt(i);
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
                buffer.append!GrUInt(reference.uvalue);
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
        string readStr(ref ubyte[] buffer) {
            string s;
            const uint size = buffer.read!uint();
            if (size == 0)
                return s;
            foreach (_; 0 .. size)
                s ~= buffer.read!char();
            return s;
        }

        enforce(buffer.length >= magicWord.length, "invalid bytecode");
        enforce(buffer[0 .. magicWord.length] == magicWord, "invalid bytecode");
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
            uconsts[i] = buffer.read!GrUInt();
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
                reference.uvalue = buffer.read!GrUInt();
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
        string getPrettyInstruction(GrOpcode op) {
            final switch (op) with (GrOpcode) {
            case nop:
                return "nop";
            case throw_:
                return "throw";
            case try_:
                return "try";
            case catch_:
                return "catch";
            case die:
                return "die";
            case exit:
                return "exit";
            case yield:
                return "yield";
            case task:
                return "task";
            case anonymousTask:
                return "atask";
            case new_:
                return "new";
            case channel:
                return "chan";
            case send:
                return "snd";
            case receive:
                return "rcv";
            case startSelectChannel:
                return "select_start";
            case endSelectChannel:
                return "select_end";
            case tryChannel:
                return "chan_try";
            case checkChannel:
                return "chan_check";
            case shiftStack:
                return "shift";
            case localStore:
                return "lstore";
            case localStore2:
                return "lstore2";
            case localLoad:
                return "lload";
            case globalStore:
                return "gstore";
            case globalStore2:
                return "gstore2";
            case globalLoad:
                return "glLoad";
            case refStore:
                return "rstore";
            case refStore2:
                return "rstore2";
            case fieldRefStore:
                return "frstore";
            case fieldRefLoad:
                return "frload";
            case fieldRefLoad2:
                return "frload2";
            case fieldLoad:
                return "fload";
            case fieldLoad2:
                return "fload2";
            case const_int:
                return "const.i";
            case const_uint:
                return "const.u";
            case const_float:
                return "const.f";
            case const_bool:
                return "const.b";
            case const_string:
                return "const.s";
            case const_meta:
                return "meta";
            case const_null:
                return "null";
            case globalPush:
                return "gpush";
            case globalPop:
                return "gpop";
            case equal_int:
                return "eq.i";
            case equal_uint:
                return "eq.u";
            case equal_float:
                return "eq.f";
            case equal_string:
                return "eq.s";
            case notEqual_int:
                return "neq.i";
            case notEqual_uint:
                return "neq.u";
            case notEqual_float:
                return "neq.f";
            case notEqual_string:
                return "neq.s";
            case greaterOrEqual_int:
                return "geq.i";
            case greaterOrEqual_uint:
                return "geq.u";
            case greaterOrEqual_float:
                return "geq.f";
            case lesserOrEqual_int:
                return "leq.i";
            case lesserOrEqual_uint:
                return "leq.u";
            case lesserOrEqual_float:
                return "leq.f";
            case greater_int:
                return "gt.i";
            case greater_uint:
                return "gt.u";
            case greater_float:
                return "gt.f";
            case lesser_int:
                return "lt.i";
            case lesser_uint:
                return "lt.u";
            case lesser_float:
                return "lt.f";
            case checkNull:
                return "check_null";
            case optionalTry:
                return "opt_try";
            case optionalOr:
                return "opt_or";
            case optionalCall:
                return "opt_call";
            case optionalCall2:
                return "opt_call2";
            case and_int:
                return "and.i";
            case or_int:
                return "or.i";
            case not_int:
                return "not.i";
            case concatenate_string:
                return "cat.s";
            case add_int:
                return "add.i";
            case add_uint:
                return "add.u";
            case add_float:
                return "add.f";
            case substract_int:
                return "sub.i";
            case substract_uint:
                return "sub.u";
            case substract_float:
                return "sub.f";
            case multiply_int:
                return "mul.i";
            case multiply_uint:
                return "mul.u";
            case multiply_float:
                return "mul.f";
            case divide_int:
                return "div.i";
            case divide_uint:
                return "div.u";
            case divide_float:
                return "div.f";
            case remainder_int:
                return "rem.i";
            case remainder_uint:
                return "rem.u";
            case remainder_float:
                return "rem.f";
            case negative_int:
                return "neg.i";
            case negative_float:
                return "neg.f";
            case increment_int:
                return "inc.i";
            case increment_uint:
                return "inc.u";
            case increment_float:
                return "inc.f";
            case decrement_int:
                return "dec.i";
            case decrement_uint:
                return "dec.u";
            case decrement_float:
                return "dec.f";
            case copy:
                return "copy";
            case swap:
                return "swap";
            case setupIterator:
                return "setup_it";
            case localStack:
                return "local";
            case call:
                return "call";
            case anonymousCall:
                return "acall";
            case primitiveCall:
                return "pcall";
            case safePrimitiveCall:
                return "spcall";
            case return_:
                return "ret";
            case unwind:
                return "unwind";
            case defer:
                return "defer";
            case jump:
                return "jmp";
            case jumpEqual:
                return "jmp_eq";
            case jumpNotEqual:
                return "jmp_neq";
            case list:
                return "list";
            case length_list:
                return "len";
            case index_list:
                return "idx";
            case index2_list:
                return "idx2";
            case index3_list:
                return "idx3";
            case concatenate_list:
                return "cat.l";
            case append_list:
                return "append";
            case prepend_list:
                return "prepend";
            case equal_list:
                return "eq.l";
            case notEqual_list:
                return "neq.l";
            case debugProfileBegin:
                return "dbg_prfbegin";
            case debugProfileEnd:
                return "dbg_prfend";
            }
        }

        import std.conv : to;
        import std.string : leftJustify;
        import grimoire.compiler;

        string result;
        uint i;
        foreach (uint opcode; opcodes) {
            GrOpcode op = cast(GrOpcode) grGetInstructionOpcode(opcode);

            string line = leftJustify("[" ~ to!string(i) ~ "]", 10) ~ leftJustify(
                getPrettyInstruction(op), 15);
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
