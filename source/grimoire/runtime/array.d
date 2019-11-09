/**
Array.

Copyright: (c) Enalye 2018
License: Zlib
Authors: Enalye
*/

module grimoire.runtime.array;

import grimoire.core;
import grimoire.compiler.primitive;

import grimoire.runtime.call;

alias GrIntArray = GrArray!int;
alias GrFloatArray = GrArray!float;
alias GrStringArray = GrArray!dstring;
alias GrObjectArray = GrArray!(void*);

/// Runtime array, can only hold one subtype.
final class GrArray(T) {
    /// Payload
	T[] data;
}