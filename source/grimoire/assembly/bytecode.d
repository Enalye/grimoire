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
    enum GR_MASK_BYTE = 0x1 << 3;
    enum GR_MASK_FLOAT = 0x1 << 4;
    enum GR_MASK_DOUBLE = 0x1 << 5;
    enum GR_MASK_STRING = 0x1 << 6;
    enum GR_MASK_POINTER = 0x1 << 7;
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
    const_byte,
    const_float,
    const_double,
    const_bool,
    const_string,
    const_meta,
    const_null,

    globalPush,
    globalPop,

    equal_int,
    equal_uint,
    equal_byte,
    equal_float,
    equal_double,
    equal_string,
    notEqual_int,
    notEqual_uint,
    notEqual_byte,
    notEqual_float,
    notEqual_double,
    notEqual_string,
    greaterOrEqual_int,
    greaterOrEqual_uint,
    greaterOrEqual_byte,
    greaterOrEqual_float,
    greaterOrEqual_double,
    lesserOrEqual_int,
    lesserOrEqual_uint,
    lesserOrEqual_byte,
    lesserOrEqual_float,
    lesserOrEqual_double,
    greater_int,
    greater_uint,
    greater_byte,
    greater_float,
    greater_double,
    lesser_int,
    lesser_uint,
    lesser_byte,
    lesser_float,
    lesser_double,
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
    add_byte,
    add_float,
    add_double,
    substract_int,
    substract_uint,
    substract_byte,
    substract_float,
    substract_double,
    multiply_int,
    multiply_uint,
    multiply_byte,
    multiply_float,
    multiply_double,
    divide_int,
    divide_uint,
    divide_byte,
    divide_float,
    divide_double,
    remainder_int,
    remainder_uint,
    remainder_byte,
    remainder_float,
    remainder_double,
    negative_int,
    negative_float,
    negative_double,
    increment_int,
    increment_uint,
    increment_byte,
    increment_float,
    increment_double,
    decrement_int,
    decrement_uint,
    decrement_byte,
    decrement_float,
    decrement_double,

    copy,
    swap,

    setupIterator,

    localStack,
    call,
    address,
    closure,
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
            /// Valeur initiale
            union {
                /// Valeur entière
                GrInt intValue;
                /// Valeur entière non-signée
                GrUInt uintValue;
                /// Valeur sur 1 octet
                GrByte byteValue;
                /// Valeur flottante
                GrFloat floatValue;
                /// Valeur flottante double précision
                GrFloat doubleValue;
                /// Valeur textuelle
                string strValue;
            }
        }

        /// Version du bytecode.
        uint grimoireVersion, userVersion;

        /// Toutes les instructions.
        uint[] opcodes;

        /// Constantes entières.
        GrInt[] intConsts;

        /// Constantes entières non-signées.
        GrUInt[] uintConsts;

        /// Constantes sur 1 octet.
        GrByte[] byteConsts;

        /// Constantes flottantes.
        GrFloat[] floatConsts;

        /// Constantes flottantes double précision.
        GrDouble[] doubleConsts;

        /// Constantes textuelles.
        string[] strConsts;

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
        intConsts = bytecode.intConsts;
        uintConsts = bytecode.uintConsts;
        byteConsts = bytecode.byteConsts;
        floatConsts = bytecode.floatConsts;
        doubleConsts = bytecode.doubleConsts;
        strConsts = bytecode.strConsts;
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

        buffer.append!uint(cast(uint) intConsts.length);
        buffer.append!uint(cast(uint) uintConsts.length);
        buffer.append!uint(cast(uint) byteConsts.length);
        buffer.append!uint(cast(uint) floatConsts.length);
        buffer.append!uint(cast(uint) doubleConsts.length);
        buffer.append!uint(cast(uint) strConsts.length);
        buffer.append!uint(cast(uint) opcodes.length);

        buffer.append!uint(globalsCount);

        buffer.append!uint(cast(uint) events.length);
        buffer.append!uint(cast(uint) primitives.length);
        buffer.append!uint(cast(uint) enums.length);
        buffer.append!uint(cast(uint) classes.length);
        buffer.append!uint(cast(uint) variables.length);
        buffer.append!uint(cast(uint) symbols.length);

        foreach (GrInt i; intConsts)
            buffer.append!GrInt(i);
        foreach (GrUInt i; uintConsts)
            buffer.append!GrUInt(i);
        foreach (GrByte i; byteConsts)
            buffer.append!GrByte(i);
        foreach (GrFloat i; floatConsts)
            buffer.append!GrFloat(i);
        foreach (GrFloat i; doubleConsts)
            buffer.append!GrDouble(i);
        foreach (string i; strConsts) {
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
                buffer.append!GrInt(reference.intValue);
            else if (reference.typeMask & GR_MASK_UINT)
                buffer.append!GrUInt(reference.uintValue);
            else if (reference.typeMask & GR_MASK_BYTE)
                buffer.append!GrByte(reference.byteValue);
            else if (reference.typeMask & GR_MASK_FLOAT)
                buffer.append!GrFloat(reference.floatValue);
            else if (reference.typeMask & GR_MASK_DOUBLE)
                buffer.append!GrFloat(reference.doubleValue);
            else if (reference.typeMask & GR_MASK_STRING)
                writeStr(buffer, reference.strValue);
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

        intConsts.length = buffer.read!uint();
        uintConsts.length = buffer.read!uint();
        byteConsts.length = buffer.read!uint();
        floatConsts.length = buffer.read!uint();
        doubleConsts.length = buffer.read!uint();
        strConsts.length = buffer.read!uint();
        opcodes.length = buffer.read!uint();

        globalsCount = buffer.read!uint();

        const uint eventsCount = buffer.read!uint();
        primitives.length = buffer.read!uint();
        enums.length = buffer.read!uint();
        classes.length = buffer.read!uint();
        const uint variableCount = buffer.read!uint();
        symbols.length = buffer.read!uint();

        for (uint i; i < intConsts.length; ++i) {
            intConsts[i] = buffer.read!GrInt();
        }

        for (uint i; i < uintConsts.length; ++i) {
            uintConsts[i] = buffer.read!GrUInt();
        }

        for (uint i; i < byteConsts.length; ++i) {
            byteConsts[i] = buffer.read!GrByte();
        }

        for (uint i; i < floatConsts.length; ++i) {
            floatConsts[i] = buffer.read!GrFloat();
        }

        for (uint i; i < doubleConsts.length; ++i) {
            doubleConsts[i] = buffer.read!GrDouble();
        }

        for (uint i; i < strConsts.length; ++i) {
            strConsts[i] = readStr(buffer);
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
                reference.intValue = buffer.read!GrInt();
            else if (reference.typeMask & GR_MASK_UINT)
                reference.uintValue = buffer.read!GrUInt();
            else if (reference.typeMask & GR_MASK_BYTE)
                reference.byteValue = buffer.read!GrByte();
            else if (reference.typeMask & GR_MASK_FLOAT)
                reference.floatValue = buffer.read!GrFloat();
            else if (reference.typeMask & GR_MASK_DOUBLE)
                reference.doubleValue = buffer.read!GrDouble();
            else if (reference.typeMask & GR_MASK_STRING)
                reference.strValue = readStr(buffer);
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
            case const_byte:
                return "const.b";
            case const_float:
                return "const.f";
            case const_double:
                return "const.d";
            case const_bool:
                return "const.bool";
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
            case equal_byte:
                return "eq.b";
            case equal_float:
                return "eq.f";
            case equal_double:
                return "eq.d";
            case equal_string:
                return "eq.s";
            case notEqual_int:
                return "neq.i";
            case notEqual_uint:
                return "neq.u";
            case notEqual_byte:
                return "neq.b";
            case notEqual_float:
                return "neq.f";
            case notEqual_double:
                return "neq.d";
            case notEqual_string:
                return "neq.s";
            case greaterOrEqual_int:
                return "geq.i";
            case greaterOrEqual_uint:
                return "geq.u";
            case greaterOrEqual_byte:
                return "geq.b";
            case greaterOrEqual_float:
                return "geq.f";
            case greaterOrEqual_double:
                return "geq.d";
            case lesserOrEqual_int:
                return "leq.i";
            case lesserOrEqual_uint:
                return "leq.u";
            case lesserOrEqual_byte:
                return "leq.b";
            case lesserOrEqual_float:
                return "leq.f";
            case lesserOrEqual_double:
                return "leq.d";
            case greater_int:
                return "gt.i";
            case greater_uint:
                return "gt.u";
            case greater_byte:
                return "gt.b";
            case greater_float:
                return "gt.f";
            case greater_double:
                return "gt.d";
            case lesser_int:
                return "lt.i";
            case lesser_uint:
                return "lt.u";
            case lesser_byte:
                return "lt.b";
            case lesser_float:
                return "lt.f";
            case lesser_double:
                return "lt.d";
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
            case add_byte:
                return "add.b";
            case add_float:
                return "add.f";
            case add_double:
                return "add.d";
            case substract_int:
                return "sub.i";
            case substract_uint:
                return "sub.u";
            case substract_byte:
                return "sub.b";
            case substract_float:
                return "sub.f";
            case substract_double:
                return "sub.d";
            case multiply_int:
                return "mul.i";
            case multiply_uint:
                return "mul.u";
            case multiply_byte:
                return "mul.b";
            case multiply_float:
                return "mul.f";
            case multiply_double:
                return "mul.d";
            case divide_int:
                return "div.i";
            case divide_uint:
                return "div.u";
            case divide_byte:
                return "div.b";
            case divide_float:
                return "div.f";
            case divide_double:
                return "div.d";
            case remainder_int:
                return "rem.i";
            case remainder_uint:
                return "rem.u";
            case remainder_byte:
                return "rem.b";
            case remainder_float:
                return "rem.f";
            case remainder_double:
                return "rem.d";
            case negative_int:
                return "neg.i";
            case negative_float:
                return "neg.f";
            case negative_double:
                return "neg.d";
            case increment_int:
                return "inc.i";
            case increment_uint:
                return "inc.u";
            case increment_byte:
                return "inc.b";
            case increment_float:
                return "inc.f";
            case increment_double:
                return "inc.d";
            case decrement_int:
                return "dec.i";
            case decrement_uint:
                return "dec.u";
            case decrement_byte:
                return "dec.b";
            case decrement_float:
                return "dec.f";
            case decrement_double:
                return "dec.d";
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
            case address:
                return "addr";
            case closure:
                return "closure";
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

            switch (op) with (GrOpcode) {
            case task:
            case localStore: .. case localLoad:
            case globalStore: .. case globalLoad:
            case globalPush:
            case localStack: .. case call:
            case new_:
            case fieldRefLoad: .. case fieldLoad2:
            case channel:
            case list:
                line ~= to!string(grGetInstructionUnsignedValue(opcode));
                break;
            case fieldRefStore:
                line ~= to!string(grGetInstructionSignedValue(opcode));
                break;
            case shiftStack:
                line ~= to!string(grGetInstructionSignedValue(opcode));
                break;
            case anonymousCall:
                line ~= to!string(grGetInstructionUnsignedValue(opcode));
                break;
            case primitiveCall:
            case safePrimitiveCall: {
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
                break;
            case address:
            case closure:
                line ~= to!string(uintConsts[grGetInstructionUnsignedValue(opcode)]);
                break;
            case const_int:
                line ~= to!string(intConsts[grGetInstructionUnsignedValue(opcode)]);
                break;
            case const_uint:
                line ~= to!string(uintConsts[grGetInstructionUnsignedValue(opcode)]);
                break;
            case const_byte:
                line ~= to!string(byteConsts[grGetInstructionUnsignedValue(opcode)]);
                break;
            case const_float:
                line ~= to!string(floatConsts[grGetInstructionUnsignedValue(opcode)]);
                break;
            case const_bool:
                line ~= (grGetInstructionUnsignedValue(opcode) ? "true" : "false");
                break;
            case const_string:
            case const_meta:
            case debugProfileBegin:
                line ~= "\"" ~ to!string(strConsts[grGetInstructionUnsignedValue(opcode)]) ~ "\"";
                break;
            case jump: .. case jumpNotEqual:
                line ~= to!string(i + grGetInstructionSignedValue(opcode));
                break;
            case defer:
            case try_:
            case catch_:
            case tryChannel:
            case optionalCall:
            case optionalCall2:
                line ~= to!string(i + grGetInstructionSignedValue(opcode));
                break;
            default:
                break;
            }

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
