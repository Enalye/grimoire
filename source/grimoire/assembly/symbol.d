/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.assembly.symbol;

import std.format, std.file, std.bitmanip, std.array, std.outbuffer;
import std.conv : to;

alias GrBool = bool;
alias GrInt = int;
alias GrUInt = uint;
alias GrByte = ubyte;
alias GrChar = dchar;
alias GrFloat = float;
alias GrDouble = double;
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
    size_t line;
    /// Ditto
    size_t column;
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
        size_t start;
        /// Nombre d’opcodes dans la fonction
        size_t length;
        /// Nom de la fonction
        string name;
        /// Fichier où la fonction est définie
        string file;
        /// Position d’origine du fichier source pour chaque instruction
        struct Position {
            /// Position source
            size_t line, column;
        }
        /// Ditto
        Position[] positions;
    }

    this() {
        type = Type.func;
    }

    /// Sérialise le symbole vers le bytecode
    override void serialize(ref Appender!(ubyte[]) buffer) {
        buffer.append!size_t(start);
        buffer.append!size_t(length);

        writeStr(buffer, name);
        writeStr(buffer, file);

        buffer.append!size_t(positions.length);
        for (size_t i; i < positions.length; ++i) {
            buffer.append!size_t(positions[i].line);
            buffer.append!size_t(positions[i].column);
        }
    }

    /// Désérialise the symbole depuis le bytecode
    override void deserialize(ref ubyte[] buffer) {
        start = buffer.read!size_t();
        length = buffer.read!size_t();

        name = readStr(buffer);
        file = readStr(buffer);

        positions.length = buffer.read!size_t();
        for (size_t i; i < positions.length; ++i) {
            positions[i].line = buffer.read!size_t();
            positions[i].column = buffer.read!size_t();
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
