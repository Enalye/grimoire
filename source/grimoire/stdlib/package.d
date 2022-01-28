/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib;

import grimoire.compiler;

public import grimoire.stdlib.util;

import grimoire.stdlib.system;
import grimoire.stdlib.array;
import grimoire.stdlib.dictionary;
import grimoire.stdlib.range;
import grimoire.stdlib.string;
import grimoire.stdlib.channel;
import grimoire.stdlib.log;
import grimoire.stdlib.math;
import grimoire.stdlib.vec2;
import grimoire.stdlib.color;
import grimoire.stdlib.test;
import grimoire.stdlib.time;
import grimoire.stdlib.typecast;
import grimoire.stdlib.pair;
import grimoire.stdlib.bitmanip;
import grimoire.stdlib.any;

/// Load the standard library
GrLibrary grLoadStdLibrary() {
    ///@TODO: Change this
    _paramError = "Null parameter";
    _classError = "Unknown class";

    GrLibrary library = new GrLibrary;
    grLoadStdLibLog(library);
    grLoadStdLibSystem(library);
    grLoadStdLibArray(library);
    grLoadStdLibDictionary(library);
    grLoadStdLibRange(library);
    grLoadStdLibString(library);
    grLoadStdLibChannel(library);
    grLoadStdLibMath(library);
    grLoadStdLibVec2(library);
    grLoadStdLibColor(library);
    grLoadStdLibTest(library);
    grLoadStdLibTime(library);
    grLoadStdLibTypecast(library);
    grLoadStdLibPair(library);
    grLoadStdLibBitmanip(library);
    grLoadStdLibAny(library);
    return library;
}
