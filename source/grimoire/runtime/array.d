/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.array;

import grimoire.assembly;
import grimoire.compiler.primitive;
import grimoire.runtime.call;

alias GrIntArray = GrArray!GrInt;
alias GrRealArray = GrArray!GrReal;
alias GrStringArray = GrArray!GrString;
alias GrObjectArray = GrArray!GrPtr;

/// Runtime array, can only hold one subtype.
final class GrArray(T) {
    /// Payload
    T[] data;
}
