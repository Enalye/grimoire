/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.assembly.symbol;

import std.format, std.file, std.bitmanip, std.array, std.outbuffer;
import std.conv : to;

alias GrBool = bool;
alias GrByte = ubyte;
alias GrInt = int;
alias GrUInt = uint;
alias GrChar = dchar;
alias GrFloat = double;
alias GrPointer = void*;

/// Trace d’appels
struct GrStackTrace {
    /// Où l’erreur a été lancé dans cette fonction
    uint pc;
    /// Le nom de la fonction
    string name;
    /// Fichier source d’où la trace a été générée
    string file;
    /// Position dans le fichier source où l’erreur est survenue
    uint line;
    /// Ditto
    uint column;
}

/// Représente des informations de déboguage.
/// Doit toujours être spécialisé.
abstract class GrSymbol {
    /// Type de symbole
    enum Type : uint {
        none = 0,
        func
    }
    /// Ditto
    Type type;

    /// Sérialise le symbole vers le bytecode
    void serialize(ref Appender!(ubyte[]));
    /// Désérialise le symbole depuis le bytecode
    void deserialize(ref ubyte[] buffer);

    /// Formate les informations de déboguage
    string prettify();
}

/// Symbole de déboguage d’une fonction
final class GrFunctionSymbol : GrSymbol {
    public {
        /// Position de la fonction dans le bytecode
        uint start;
        /// Nombre d’opcodes dans la fonction
        uint length;
        /// Nom de la fonction
        string name;
        /// Fichier où la fonction est définie
        string file;
        /// Position d’origine du fichier source pour chaque instruction
        struct Position {
            /// Position source
            uint line, column;
        }
        /// Ditto
        Position[] positions;
    }

    this() {
        type = Type.func;
    }

    /// Sérialise le symbole vers le bytecode
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

    /// Désérialise the symbole depuis le bytecode
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

    /// Formate les informations de déboguage
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
