/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.queue;

import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

package(grimoire.stdlib) void grLoadStdLibQueue(GrLibrary library) {
    library.addForeign("Queue", ["T"]);
    library.addForeign("QueueIterator", ["T"]);

    GrType valueType = grAny("T");
    GrType queueType = grGetForeignType("Queue", [valueType]);
}
