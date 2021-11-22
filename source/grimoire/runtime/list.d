/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.list;

import grimoire.assembly;
import grimoire.compiler.primitive;
import grimoire.runtime.call;

alias GrIntList = GrList!GrInt;
alias GrFloatList = GrList!GrFloat;
alias GrStringList = GrList!GrString;
alias GrObjectList = GrList!GrPtr;

/// Runtime list, can only hold one subtype.
final class GrList(T) {
    /// Payload
	T[] data;
}