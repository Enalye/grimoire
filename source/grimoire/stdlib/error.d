/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.stdlib.error;

import grimoire.assembly, grimoire.compiler, grimoire.runtime;

void grLoadStdLibError(GrLibDefinition library) {
    library.setModule(["std", "error"]);

    library.setModuleInfo(GrLocale.fr_FR, "Fonctions pour aider la gestion d’erreur.");
    library.setModuleInfo(GrLocale.en_US, "Functions to help error handling.");

    library.setDescription(GrLocale.fr_FR,
        "Si `valeur` est faux, lance une exception `\"AssertError\"`.");
    library.setDescription(GrLocale.en_US,
        "If `value` is false, throw an exception `\"AssertError\"`.");
    library.setParameters(GrLocale.fr_FR, ["valeur"]);
    library.setParameters(GrLocale.en_US, ["value"]);
    library.addFunction(&_assert, "assert", [grBool]);

    library.setDescription(GrLocale.fr_FR, "Si `valeur` est faux, lance l’exception `erreur`.");
    library.setDescription(GrLocale.en_US, "If `value` is false, throw the exception `errror`.");
    library.setParameters(GrLocale.fr_FR, ["valeur", "erreur"]);
    library.setParameters(GrLocale.en_US, ["value", "error"]);
    library.addFunction(&_assert_msg, "assert", [grBool, grPure(grString)]);

    library.setDescription(GrLocale.fr_FR, "Fonction interne.");
    library.setDescription(GrLocale.en_US, "Internal function.");
    library.setParameters(GrLocale.fr_FR, ["valeur"]);
    library.setParameters(GrLocale.en_US, ["value"]);
    library.addFunction(&_setMeta, "_setMeta", [grPure(grString)]);
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

private void _setMeta(GrCall call) {
    const string value = call.getString(0).str;
    call.task.engine.meta = value;
}
