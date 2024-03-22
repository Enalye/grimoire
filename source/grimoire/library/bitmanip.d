/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.library.bitmanip;

import std.range;
import grimoire;

void grLoadStdLibBitmanip(GrModule library) {
    library.setModule("bitmanip");

    library.setModuleInfo(GrLocale.fr_FR, "Opérations pour effectuer des opérations binaires.");
    library.setModuleInfo(GrLocale.en_US, "Operations to make binary operations.");

    library.addOperator(&_shiftLeft!GrInt, GrModuleDef.Operator.leftShift, [
            grInt, grInt
        ], grInt);
    library.addOperator(&_shiftLeft!GrUInt, GrModuleDef.Operator.leftShift,
        [grUInt, grUInt], grUInt);
    library.addOperator(&_shiftLeft!GrByte, GrModuleDef.Operator.leftShift,
        [grByte, grByte], grByte);

    library.addOperator(&_shiftRight!GrInt, GrModuleDef.Operator.rightShift, [
            grInt, grInt
        ], grInt);
    library.addOperator(&_shiftRight!GrUInt, GrModuleDef.Operator.rightShift,
        [grUInt, grUInt], grUInt);
    library.addOperator(&_shiftRight!GrByte, GrModuleDef.Operator.rightShift,
        [grByte, grByte], grByte);

    library.addOperator(&_and!GrInt, GrModuleDef.Operator.bitwiseAnd, [
            grInt, grInt
        ], grInt);
    library.addOperator(&_and!GrUInt, GrModuleDef.Operator.bitwiseAnd, [
            grUInt, grUInt
        ], grUInt);
    library.addOperator(&_and!GrByte, GrModuleDef.Operator.bitwiseAnd, [
            grByte, grByte
        ], grByte);

    library.addOperator(&_or!GrInt, GrModuleDef.Operator.bitwiseOr, [grInt, grInt], grInt);
    library.addOperator(&_or!GrUInt, GrModuleDef.Operator.bitwiseOr, [
            grUInt, grUInt
        ], grUInt);
    library.addOperator(&_or!GrByte, GrModuleDef.Operator.bitwiseOr, [
            grByte, grByte
        ], grByte);

    library.addOperator(&_xor!GrInt, GrModuleDef.Operator.bitwiseXor, [
            grByte, grByte
        ], grByte);
    library.addOperator(&_xor!GrUInt, GrModuleDef.Operator.bitwiseXor, [
            grUInt, grUInt
        ], grUInt);
    library.addOperator(&_xor!GrByte, GrModuleDef.Operator.bitwiseXor, [
            grByte, grByte
        ], grByte);

    library.addOperator(&_not!GrInt, GrModuleDef.Operator.bitwiseNot, [grInt], grInt);
    library.addOperator(&_not!GrUInt, GrModuleDef.Operator.bitwiseNot, [grUInt], grUInt);
    library.addOperator(&_not!GrByte, GrModuleDef.Operator.bitwiseNot, [grByte], grByte);
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
