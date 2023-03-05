/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.stdlib.bitmanip;

import std.range;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

void grLoadStdLibBitmanip(GrLibDefinition library) {
    library.setModule(["std", "bitmanip"]);

    library.setModuleInfo(GrLocale.fr_FR, "Opérations pour effectuer des opérations binaires.");
    library.setModuleInfo(GrLocale.en_US, "Operations to make binary operations.");

    library.addOperator(&_shiftLeft!GrInt, GrLibrary.Operator.leftShift, [
            grInt, grInt
        ], grInt);
    library.addOperator(&_shiftLeft!GrUInt, GrLibrary.Operator.leftShift,
        [grUInt, grUInt], grUInt);
    library.addOperator(&_shiftLeft!GrByte, GrLibrary.Operator.leftShift,
        [grByte, grByte], grByte);

    library.addOperator(&_shiftRight!GrInt, GrLibrary.Operator.rightShift, [
            grInt, grInt
        ], grInt);
    library.addOperator(&_shiftRight!GrUInt, GrLibrary.Operator.rightShift,
        [grUInt, grUInt], grUInt);
    library.addOperator(&_shiftRight!GrByte, GrLibrary.Operator.rightShift,
        [grByte, grByte], grByte);

    library.addOperator(&_and!GrInt, GrLibrary.Operator.bitwiseAnd, [
            grInt, grInt
        ], grInt);
    library.addOperator(&_and!GrUInt, GrLibrary.Operator.bitwiseAnd, [
            grUInt, grUInt
        ], grUInt);
    library.addOperator(&_and!GrByte, GrLibrary.Operator.bitwiseAnd, [
            grByte, grByte
        ], grByte);

    library.addOperator(&_or!GrInt, GrLibrary.Operator.bitwiseOr, [grInt, grInt], grInt);
    library.addOperator(&_or!GrUInt, GrLibrary.Operator.bitwiseOr, [
            grUInt, grUInt
        ], grUInt);
    library.addOperator(&_or!GrByte, GrLibrary.Operator.bitwiseOr, [
            grByte, grByte
        ], grByte);

    library.addOperator(&_xor!GrInt, GrLibrary.Operator.bitwiseXor, [
            grByte, grByte
        ], grByte);
    library.addOperator(&_xor!GrUInt, GrLibrary.Operator.bitwiseXor, [
            grUInt, grUInt
        ], grUInt);
    library.addOperator(&_xor!GrByte, GrLibrary.Operator.bitwiseXor, [
            grByte, grByte
        ], grByte);

    library.addOperator(&_not!GrInt, GrLibrary.Operator.bitwiseNot, [grInt], grInt);
    library.addOperator(&_not!GrUInt, GrLibrary.Operator.bitwiseNot, [grUInt], grUInt);
    library.addOperator(&_not!GrByte, GrLibrary.Operator.bitwiseNot, [grByte], grByte);
}

private void _shiftLeft(T)(GrCall call) {
    static if (is(T == GrInt)) {
        const GrInt shift = call.getInt(1);
        if (shift > 31 || shift < -31) {
            call.raise("ShiftError");
            return;
        }
        call.setInt(shift < 0 ? call.getInt(0) >> -shift : call.getInt(0) << shift);
    }
    else static if (is(T == GrUInt)) {
        const GrUInt shift = call.getUInt(1);
        if (shift > 31) {
            call.raise("ShiftError");
            return;
        }
        call.setUInt(call.getUInt(0) << shift);
    }
    else static if (is(T == GrByte)) {
        const GrByte shift = call.getByte(1);
        if (shift > 7 || shift < -7) {
            call.raise("ShiftError");
            return;
        }
        call.setByte(cast(GrByte)(call.getByte(0) << shift));
    }
}

private void _shiftRight(T)(GrCall call) {
    static if (is(T == GrInt)) {
        const GrInt shift = call.getInt(1);
        if (shift > 31 || shift < -31) {
            call.raise("ShiftError");
            return;
        }
        call.setInt(shift < 0 ? call.getInt(0) << -shift : call.getInt(0) >> shift);
    }
    else static if (is(T == GrUInt)) {
        const GrUInt shift = call.getUInt(1);
        if (shift > 31) {
            call.raise("ShiftError");
            return;
        }
        call.setUInt(call.getUInt(0) >> shift);
    }
    else static if (is(T == GrByte)) {
        const GrByte shift = call.getByte(1);
        if (shift > 7 || shift < -7) {
            call.raise("ShiftError");
            return;
        }
        call.setByte(call.getByte(0) >> shift);
    }
}

private void _and(T)(GrCall call) {
    static if (is(T == GrInt)) {
        call.setInt(call.getInt(0) & call.getInt(1));
    }
    else static if (is(T == GrUInt)) {
        call.setUInt(call.getUInt(0) & call.getUInt(1));
    }
    else static if (is(T == GrByte)) {
        call.setByte(call.getByte(0) & call.getByte(1));
    }
}

private void _or(T)(GrCall call) {
    static if (is(T == GrInt)) {
        call.setInt(call.getInt(0) & call.getInt(1));
    }
    else static if (is(T == GrUInt)) {
        call.setUInt(call.getUInt(0) & call.getUInt(1));
    }
    else static if (is(T == GrByte)) {
        call.setByte(call.getByte(0) & call.getByte(1));
    }
    call.setInt(call.getInt(0) | call.getInt(1));
}

private void _xor(T)(GrCall call) {
    static if (is(T == GrInt)) {
        call.setInt(call.getInt(0) ^ call.getInt(1));
    }
    else static if (is(T == GrUInt)) {
        call.setUInt(call.getUInt(0) ^ call.getUInt(1));
    }
    else static if (is(T == GrByte)) {
        call.setByte(call.getByte(0) ^ call.getByte(1));
    }
}

private void _not(T)(GrCall call) {
    static if (is(T == GrInt)) {
        call.setInt(~call.getInt(0));
    }
    else static if (is(T == GrUInt)) {
        call.setUInt(~call.getUInt(0));
    }
    else static if (is(T == GrByte)) {
        call.setByte(cast(GrByte)~call.getByte(0));
    }
}
