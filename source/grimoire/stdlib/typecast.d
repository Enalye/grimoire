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
    library.addCast(&u_as_i, grUInt, grInt);
    library.addCast(&f_as_i, grFloat, grInt, true);
    library.addCast(&b_as_i, grBool, grInt);
    library.addCast(&e_as_i, grAny("T"), grInt, false, [
            grConstraint("Enum", grAny("T"))
        ]);

    // as<uint>
    library.addCast(&i_as_u, grInt, grUInt);
    library.addCast(&f_as_u, grFloat, grUInt, true);
    library.addCast(&b_as_u, grBool, grUInt);

    // as<float>
    library.addCast(&i_as_f, grInt, grFloat);
    library.addCast(&u_as_f, grUInt, grFloat);

    // as<string>
    library.addCast(&b_as_s, grBool, grString);
    library.addCast(&i_as_s, grInt, grString);
    library.addCast(&u_as_s, grUInt, grString);
    library.addCast(&f_as_s, grFloat, grString);
    library.addCast(&c_as_s, grChar, grString);
    library.addCast(&ls_as_s, grPure(grList(grString)), grString);
    library.addCast(&lc_as_s, grPure(grList(grChar)), grString);

    // as<list<string>>
    library.addCast(&s_as_lc, grPure(grString), grList(grChar));
}

// as<int>
private void u_as_i(GrCall call) {
    GrUInt value = call.getUInt(0);
    if (value > GrInt.max) {
        call.raise("OverflowError");
        return;
    }
    call.setInt(value);
}

private void f_as_i(GrCall call) {
    call.setInt(to!GrInt(call.getFloat(0)));
}

private void b_as_i(GrCall call) {
    call.setInt(to!GrInt(call.getBool(0)));
}

private void e_as_i(GrCall call) {
    call.setInt(call.getInt(0));
}

// as<uint>
private void i_as_u(GrCall call) {
    GrInt value = call.getInt(0);
    if (value < 0) {
        call.raise("OverflowError");
        return;
    }
    call.setUInt(cast(GrUInt) value);
}

private void f_as_u(GrCall call) {
    GrFloat value = call.getFloat(0);
    if (value < 0) {
        call.raise("OverflowError");
        return;
    }
    call.setUInt(cast(GrUInt) value);
}

private void b_as_u(GrCall call) {
    call.setUInt(to!GrUInt(call.getBool(0)));
}

// as<float>
private void i_as_f(GrCall call) {
    call.setFloat(to!GrFloat(call.getInt(0)));
}

private void u_as_f(GrCall call) {
    call.setFloat(to!GrFloat(call.getUInt(0)));
}

// as<string>
private void b_as_s(GrCall call) {
    call.setString(call.getBool(0) ? "true" : "false");
}

private void i_as_s(GrCall call) {
    call.setString(to!string(call.getInt(0)));
}

private void u_as_s(GrCall call) {
    call.setString(to!string(call.getUInt(0)));
}

private void f_as_s(GrCall call) {
    call.setString(to!string(call.getFloat(0)));
}

private void c_as_s(GrCall call) {
    call.setString(to!string(call.getChar(0)));
}

private void ls_as_s(GrCall call) {
    GrString str = new GrString;
    foreach (const GrString sub; call.getList(0).getStrings()) {
        str.pushBack(sub);
    }
    call.setString(str);
}

private void lc_as_s(GrCall call) {
    call.setString(new GrString(call.getList(0).getChars()));
}

// as<list<char>>
private void s_as_lc(GrCall call) {
    GrValue[] result;
    foreach (const GrChar sub; call.getString(0).chars) {
        result ~= GrValue(sub);
    }

    call.setList(result);
}
