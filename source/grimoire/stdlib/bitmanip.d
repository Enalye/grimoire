/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.bitmanip;

import std.range;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

void grLoadStdLibBitmanip(GrLibDefinition library) {
    library.setModule(["std", "bitmanip"]);

    library.setModuleInfo(GrLocale.fr_FR, "Opérations pour effectuer des opérations binaires.");
    library.setModuleInfo(GrLocale.en_US, "Operations to make binary operations.");

    library.addOperator(&_shiftLeft, GrLibrary.Operator.leftShift, [grInt, grInt], grInt);
    library.addOperator(&_shiftRight, GrLibrary.Operator.rightShift, [grInt, grInt], grInt);
    library.addOperator(&_and, GrLibrary.Operator.bitwiseAnd, [grInt, grInt], grInt);
    library.addOperator(&_or, GrLibrary.Operator.bitwiseOr, [grInt, grInt], grInt);
    library.addOperator(&_xor, GrLibrary.Operator.bitwiseXor, [grInt, grInt], grInt);
    library.addOperator(&_not, GrLibrary.Operator.bitwiseNot, [grInt], grInt);
}

private void _shiftLeft(GrCall call) {
    call.setInt(call.getInt(0) << call.getInt(1));
}

private void _shiftRight(GrCall call) {
    call.setInt(call.getInt(0) >> call.getInt(1));
}

private void _and(GrCall call) {
    call.setInt(call.getInt(0) & call.getInt(1));
}

private void _or(GrCall call) {
    call.setInt(call.getInt(0) | call.getInt(1));
}

private void _xor(GrCall call) {
    call.setInt(call.getInt(0) ^ call.getInt(1));
}

private void _not(GrCall call) {
    call.setInt(~call.getInt(0));
}