/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib;

import grimoire.compiler;

public import grimoire.stdlib.util;

import grimoire.stdlib.constraint;
import grimoire.stdlib.optional;
import grimoire.stdlib.system;
import grimoire.stdlib.list;
import grimoire.stdlib.hashmap;
import grimoire.stdlib.range;
import grimoire.stdlib.string;
import grimoire.stdlib.channel;
import grimoire.stdlib.log;
import grimoire.stdlib.math;
import grimoire.stdlib.error;
import grimoire.stdlib.time;
import grimoire.stdlib.typecast;
import grimoire.stdlib.pair;
import grimoire.stdlib.bitmanip;
import grimoire.stdlib.queue;
import grimoire.stdlib.circularbuffer;

/// Load the standard library
GrLibrary grLoadStdLibrary() {
    GrLibrary library = new GrLibrary;
    grLoadStdLibConstraint();
    grLoadStdLibSystem(library);
    grLoadStdLibOptional(library);
    grLoadStdLibLog(library);
    grLoadStdLibList(library);
    grLoadStdLibRange(library);
    grLoadStdLibString(library);
    grLoadStdLibChannel(library);
    grLoadStdLibMath(library);
    grLoadStdLibError(library);
    grLoadStdLibTime(library);
    grLoadStdLibTypecast(library);
    grLoadStdLibPair(library);
    grLoadStdLibBitmanip(library);
    grLoadStdLibHashMap(library);
    grLoadStdLibQueue(library);
    grLoadStdLibCircularBuffer(library);
    return library;
}
