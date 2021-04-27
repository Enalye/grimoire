/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib;

import grimoire.compiler;

import grimoire.stdlib.array;
import grimoire.stdlib.string;
import grimoire.stdlib.channel;
import grimoire.stdlib.print;
import grimoire.stdlib.math;
import grimoire.stdlib.vector;
import grimoire.stdlib.color;
import grimoire.stdlib.test;
import grimoire.stdlib.time;
import grimoire.stdlib.typecast;
import grimoire.stdlib.pair;

/// Load the standard library
GrLibrary grLoadStdLibrary() {
    GrLibrary library = new GrLibrary;
    grLoadStdLibArray(library);
    grLoadStdLibString(library);
    grLoadStdLibChannel(library);
    grLoadStdLibPrint(library);
    grLoadStdLibMath(library);
    grLoadStdLibVector(library);
    grLoadStdLibColor(library);
    grLoadStdLibTest(library);
    grLoadStdLibTime(library);
    grLoadStdLibTypecast(library);
    grLoadStdLibPair(library);
    return library;
}