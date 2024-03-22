/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.library.error;

import grimoire;

void grLoadStdLibError(GrModule library) {
    library.setModule("error");

    library.setModuleInfo(GrLocale.fr_FR, "Fonctions pour aider la gestion d’erreur.");
    library.setModuleInfo(GrLocale.en_US, "Functions to help error handling.");

    library.setDescription(GrLocale.fr_FR,
        "Si `value` est faux, lance une exception `\"AssertError\"`.");
    library.setDescription(GrLocale.en_US,
        "If `value` is false, throw an exception `\"AssertError\"`.");
    library.setParameters(["value"]);
    library.addFunction(&_assert, "assert", [grBool]);

    library.setDescription(GrLocale.fr_FR, "Si `value` est faux, lance l’exception.");
    library.setDescription(GrLocale.en_US, "If `value` is false, throw the exception.");
    library.setParameters(["value", "error"]);
    library.addFunction(&_assert_msg, "assert", [grBool, grPure(grString)]);
}

private void _assert(GrCall call) {
    const GrBool value = call.getBool(0);
    if (!value)
        call.raise("AssertError");
}

private void _assert_msg(GrCall call) {
    const GrBool value = call.getBool(0);
    if (!value)
        call.raise(call.getString(1));
}
