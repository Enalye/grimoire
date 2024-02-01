/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.stdlib.io;

import std.conv : to;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

void grLoadStdLibIo(GrLibDefinition library) {
    library.setModule("io");

    library.setDescription(GrLocale.fr_FR, "Affiche le contenu de `valeur`.");
    library.setDescription(GrLocale.en_US, "Display `value`'s content.");

    library.setParameters(GrLocale.fr_FR, ["valeur"]);
    library.setParameters(GrLocale.en_US, ["value"]);

    library.addFunction(&_print, "print", [grPure(grAny("T"))]);
}

private void _print(GrCall call) {
    string formatValue(GrType type, GrValue value) {
        final switch (type.base) with (GrType.Base) {
        case int_:
            return to!string(value.getInt());
        case uint_:
            return to!string(value.getUInt());
        case char_:
            return to!string(value.getChar());
        case byte_:
            return to!string(value.getByte());
        case bool_:
            return value.getBool() ? "true" : "false";
        case func:
        case task:
        case event:
            return grGetPrettyType(type, false);
        case enum_:
            return type.mangledType ~ "." ~ call.getEnumFieldName(type.mangledType, value.getInt());
        case float_:
            return to!string(value.getFloat());
        case double_:
            return to!string(value.getDouble());
        case string_:
            return value.getString().str;
        case optional:
            if (value.isNull())
                return "null";
            return formatValue(grUnmangle(type.mangledType), value);
        case list:
            GrType subType = grUnmangle(type.mangledType);
            GrList list = value.getList();
            string txt = "[";
            for (GrInt i; i < list.size(); ++i) {
                if (i != 0) {
                    txt ~= ", ";
                }
                txt ~= formatValue(subType, list[i]);
            }
            txt ~= "]";
            return txt;
        case class_:
        case native:
            return grGetPrettyType(type, false);
        case channel:
            GrType subType = grUnmangle(type.mangledType);
            GrChannel channel = value.getChannel();
            string txt = "{";
            for (GrInt i; i < channel.size(); ++i) {
                if (i != 0) {
                    txt ~= ", ";
                }
                txt ~= formatValue(subType, channel.data[i]);
            }
            txt ~= "}";
            return txt;
        case internalTuple:
            return "(tuple)";
        case reference:
            return "(ref)";
        case null_:
            return "null";
        case void_:
            return "void";
        }
    }

    grPrint(formatValue(grUnmangle(call.getInType(0)), call.getValue(0)));
}
