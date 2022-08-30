/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.array;

import grimoire.assembly;
import grimoire.compiler.primitive;
import grimoire.runtime.call;

/// Runtime array, can only hold one subtype.
final class GrArray {
    /// Payload
    GrValue[] data;
    GrInt size;
    GrInt elementSize;
}
