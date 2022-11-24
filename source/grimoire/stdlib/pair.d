/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.stdlib.pair;

import grimoire.compiler, grimoire.runtime;

void grLoadStdLibPair(GrLibDefinition library) {
    library.setModule(["std", "pair"]);

    library.setModuleInfo(GrLocale.fr_FR, "Paire de clé/valeur.");
    library.setModuleInfo(GrLocale.en_US, "Pair of key/value.");

    GrType pairType = library.addNative("Pair", ["K", "V"]);

    library.addOperator(&_new, GrLibDefinition.Operator.arrow, [
            grAny("K"), grAny("V")
        ], pairType);

    library.addProperty(&_getKey, &_setKey, "key", pairType, grAny("K"));
    library.addProperty(&_getValue, &_setValue, "value", pairType, grAny("V"));
}

final class GrPair {
    GrValue key, value;
}

private void _new(GrCall call) {
    GrPair pair = new GrPair;
    pair.key = call.getValue(0);
    pair.value = call.getValue(1);
    call.setNative(pair);
}

private void _getKey(GrCall call) {
    GrPair pair = call.getNative!GrPair(0);
    call.setValue(pair.key);
}

private void _setKey(GrCall call) {
    GrPair pair = call.getNative!GrPair(0);
    pair.key = call.getValue(1);
    call.setValue(pair.key);
}

private void _getValue(GrCall call) {
    GrPair pair = call.getNative!GrPair(0);
    call.setValue(pair.value);
}

private void _setValue(GrCall call) {
    GrPair pair = call.getNative!GrPair(0);
    pair.value = call.getValue(1);
    call.setValue(pair.value);
}
