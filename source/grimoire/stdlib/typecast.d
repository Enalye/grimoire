/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.stdlib.typecast;

import std.conv;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

void grLoadStdLibTypecast(GrLibDefinition library) {
    library.setModule(["std", "typecast"]);

    library.setModuleInfo(GrLocale.fr_FR, "Fonctions de conversion.");
    library.setModuleInfo(GrLocale.en_US, "Conversion functions.");

    // as<int>
    library.addCast(&uint_as_int, grUInt, grInt);
    library.addCast(&float_as_int, grFloat, grInt, true);
    library.addCast(&bool_as_int, grBool, grInt);
    library.addCast(&enum_as_int, grAny("T"), grInt, false, [
            grConstraint("Enum", grAny("T"))
        ]);

    // as<uint>
    library.addCast(&int_as_uint, grInt, grUInt);
    library.addCast(&float_as_uint, grFloat, grUInt, true);
    library.addCast(&bool_as_uint, grBool, grUInt);

    // as<float>
    library.addCast(&int_as_float, grInt, grFloat);
    library.addCast(&uint_as_float, grUInt, grFloat);

    // as<string>
    library.addCast(&bool_as_str, grBool, grString);
    library.addCast(&int_as_str, grInt, grString);
    library.addCast(&uint_as_str, grUInt, grString);
    library.addCast(&float_as_str, grFloat, grString);
    library.addCast(&char_as_str, grChar, grString);
    library.addCast(&listStr_as_str, grPure(grList(grString)), grString);
    library.addCast(&listChar_as_str, grPure(grList(grChar)), grString);

    // as<list<string>>
    library.addCast(&str_as_listChar, grPure(grString), grList(grChar));
}

// as<int>
private void uint_as_int(GrCall call) {
    GrUInt value = call.getUInt(0);
    if (value > GrInt.max) {
        call.raise("OverflowError");
        return;
    }
    call.setInt(value);
}

private void float_as_int(GrCall call) {
    call.setInt(to!GrInt(call.getFloat(0)));
}

private void bool_as_int(GrCall call) {
    call.setInt(to!GrInt(call.getBool(0)));
}

private void enum_as_int(GrCall call) {
    call.setInt(call.getInt(0));
}

// as<uint>
private void int_as_uint(GrCall call) {
    GrInt value = call.getInt(0);
    if (value < 0) {
        call.raise("OverflowError");
        return;
    }
    call.setUInt(cast(GrUInt) value);
}

private void float_as_uint(GrCall call) {
    GrFloat value = call.getFloat(0);
    if (value < 0) {
        call.raise("OverflowError");
        return;
    }
    call.setUInt(cast(GrUInt) value);
}

private void bool_as_uint(GrCall call) {
    call.setUInt(to!GrUInt(call.getBool(0)));
}

// as<float>
private void int_as_float(GrCall call) {
    call.setFloat(to!GrFloat(call.getInt(0)));
}

private void uint_as_float(GrCall call) {
    call.setFloat(to!GrFloat(call.getUInt(0)));
}

// as<string>
private void bool_as_str(GrCall call) {
    call.setString(call.getBool(0) ? "true" : "false");
}

private void int_as_str(GrCall call) {
    call.setString(to!string(call.getInt(0)));
}

private void uint_as_str(GrCall call) {
    call.setString(to!string(call.getUInt(0)));
}

private void float_as_str(GrCall call) {
    call.setString(to!string(call.getFloat(0)));
}

private void char_as_str(GrCall call) {
    call.setString(to!string(call.getChar(0)));
}

private void listStr_as_str(GrCall call) {
    GrString str = new GrString;
    foreach (const GrString sub; call.getList(0).getStrings()) {
        str.pushBack(sub);
    }
    call.setString(str);
}

private void listChar_as_str(GrCall call) {
    call.setString(new GrString(call.getList(0).getChars()));
}

// as<list<char>>
private void str_as_listChar(GrCall call) {
    GrValue[] result;
    foreach (const GrChar sub; call.getString(0).chars) {
        result ~= GrValue(sub);
    }

    call.setList(result);
}
