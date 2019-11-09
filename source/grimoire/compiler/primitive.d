/**
    Primitives are hard-coded grimoire's functions, they are used the same as any other function.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.compiler.primitive;

import std.exception;
import std.conv;
import std.stdio;

import grimoire.runtime;
import grimoire.compiler.parser;
import grimoire.compiler.type;
import grimoire.compiler.mangle;
import grimoire.compiler.data;

/**
A single primitive.
*/
class GrPrimitive {
    /// The D function.
	GrCallback callback;
    /// Function parameters' type.
	GrType[] inSignature;
    /// Return values.
	GrType[] outSignature;
    /// Function parameters' name.
    dstring[] parameters;
    /// The base name of the function to call.
	dstring name,
    /// Name mangled with its parameters' type.
        mangledName;
    /// Function ID.
	uint index;
    /// For convertions: Can this convertion be used without "as" ?
    bool isExplicit;
    /// Runtime parameter for D functions. Contain all runtime information needed.
    GrCall callObject;

    //alias call = callObject.call;
}
