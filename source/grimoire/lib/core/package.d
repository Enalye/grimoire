/**
    FFI lib.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.lib.core;

import grimoire.lib.api;

void grLib_std_core_load() {
    grLib_addPrimitive(&showStack, "showStack", [], []);
}

import std.stdio;
private void showStack(GrCall call) {
    writeln("Stack Status:\n",
        "stack: ", call.context.stackPos, "\n",
        "loc: ", call.context.localsPos, "\n",
        "call: ", call.context.deferPos);
}