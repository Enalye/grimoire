/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib;

import grimoire.compiler;

import grimoire.stdlib.array;
import grimoire.stdlib.print;
import grimoire.stdlib.math;
import grimoire.stdlib.test;
import grimoire.stdlib.time;
import grimoire.stdlib.typecast;

/// Load the standard library
void grLoadStdLibrary(GrData data) {
    grLoadStdLibArray(data);
    grLoadStdLibPrint(data);
    grLoadStdLibMath(data);
    grLoadStdLibTest(data);
    grLoadStdLibTime(data);
    grLoadStdLibTypecast(data);
}