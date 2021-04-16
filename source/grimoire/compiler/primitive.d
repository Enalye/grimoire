/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
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
A single primitive. \
Primitives are hard-coded grimoire's functions, they are used the same way as other functions.
*/
class GrPrimitive {
    /// The D function.
	GrCallback callback;
    /// Function parameters' type.
	GrType[] inSignature;
    /// Return values.
	GrType[] outSignature;
    /// Function parameters' name.
    string[] parameters;
    /// The base name of the function to call.
	string name,
    /// Name mangled with its parameters' type.
        mangledName;
    /// Function ID.
	uint index;
    /// For convertions: Can this convertion be used without "as" ?
    bool isExplicit;
    /// If the primitive has a generic parameter type, it becomes abstract
    bool isAbstract;
    /// Runtime parameter for D functions. Contain all runtime information needed.
    GrCall callObject;

    /// Ctor
    this() {}

    /// Ditto
    this(GrPrimitive primitive) {
        callback = primitive.callback;
        inSignature = primitive.inSignature;
        outSignature = primitive.outSignature;
        parameters = primitive.parameters;
        name = primitive.name;
        mangledName = primitive.mangledName;
        index = primitive.index;
        isExplicit = primitive.isExplicit;
        callObject = primitive.callObject;
    }
}
