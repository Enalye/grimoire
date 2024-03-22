/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.library.system;

import grimoire;

void grLoadStdLibSystem(GrModule library) {
    library.setModule("system");

    library.setModuleInfo(GrLocale.fr_FR, "Fonctions basiques.");
    library.setModuleInfo(GrLocale.en_US, "Basic functions.");

    library.setDescription(GrLocale.fr_FR, "Renvoie `a` et `b` dans l’ordre inverse.");
    library.setDescription(GrLocale.en_US, "Returns `a` and `b` in reverse order.");
    library.setParameters(["a", "b"]);
    library.addFunction(&_swap_2, "swap", [grAny("T1"), grAny("T2")], [
            grAny("T2"), grAny("T1")
        ]);

    library.setDescription(GrLocale.fr_FR,
        "Renvoie `a` si `condition` est vrai, sinon renvoie `b`.");
    library.setDescription(GrLocale.en_US, "Returns `a` if `condition` is true, else returns `b`.");
    library.setParameters(["condition", "a", "b"]);
    library.addFunction(&_cond, "cond", [grBool, grAny("T"), grAny("T")], [
            grAny("T")
        ]);

    library.setDescription(GrLocale.fr_FR, "Retourne le type de `valeur`.");
    library.setDescription(GrLocale.en_US, "Returns the type of `value`.");
    library.setParameters(["value"]);
    library.addFunction(&_typeOf, "typeOf", [grAny("T")], [grString]);
}

private void _swap_2(GrCall call) {
    call.setValue(call.getValue(1));
    call.setValue(call.getValue(0));
}

private void _cond(GrCall call) {
    if (call.getBool(0))
        call.setValue(call.getValue(1));
    else
        call.setValue(call.getValue(2));
}

private void _typeOf(GrCall call) {
    call.setString(grGetPrettyType(grUnmangle(call.getInType(0))));
}
