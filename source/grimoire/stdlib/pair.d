/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.pair;

import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibPair(GrLibrary library) {
    GrType pairType = library.addForeign("pair", ["K", "V"]);

    library.addOperator(&_new, GrLibrary.Operator.arrow, [
            grAny("K"), grAny("V")
        ], pairType);
}

final class GrPair {
    GrValue key, value;
}

private void _new(GrCall call) {
    GrPair pair = new GrPair;
    pair.key = call.getValue(0);
    pair.value = call.getValue(1);
    call.setForeign(pair);
}
