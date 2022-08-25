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

    static foreach (t; ["Int", "Real", "String", "Object"]) {
        mixin("
        GrType " ~ t ~ "ValueType = grAny(\"T\");
        GrType " ~ t ~ "QueueType = grGetForeignType(\"Queue\", [" ~ t ~ "ValueType]);
        
        
        
        ");
    }
}
