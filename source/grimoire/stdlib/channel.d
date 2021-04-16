/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.channel;

import std.range;
import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibChannel(GrData data) {
    data.addPrimitive(&_size_i, "size", ["chan"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.chan)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfInt(subType.baseType);
            })
            ], [grInt]);
    data.addPrimitive(&_size_f, "size", ["chan"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.chan)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfFloat(subType.baseType);
            })
            ], [grInt]);
    data.addPrimitive(&_size_s, "size", ["chan"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.chan)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfString(subType.baseType);
            })
            ], [grInt]);
    data.addPrimitive(&_size_o, "size", ["chan"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.chan)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfObject(subType.baseType);
            })
            ], [grInt]);

    data.addPrimitive(&_capacity_i, "capacity", ["chan"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.chan)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfInt(subType.baseType);
            })
            ], [grInt]);
    data.addPrimitive(&_capacity_f, "capacity", ["chan"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.chan)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfFloat(subType.baseType);
            })
            ], [grInt]);
    data.addPrimitive(&_capacity_s, "capacity", ["chan"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.chan)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfString(subType.baseType);
            })
            ], [grInt]);
    data.addPrimitive(&_capacity_o, "capacity", ["chan"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.chan)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfObject(subType.baseType);
            })
            ], [grInt]);

    data.addPrimitive(&_empty_i, "empty?", ["chan"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.chan)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfInt(subType.baseType);
            })
            ], [grBool]);
    data.addPrimitive(&_empty_f, "empty?", ["chan"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.chan)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfFloat(subType.baseType);
            })
            ], [grBool]);
    data.addPrimitive(&_empty_s, "empty?", ["chan"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.chan)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfString(subType.baseType);
            })
            ], [grBool]);
    data.addPrimitive(&_empty_o, "empty?", ["chan"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.chan)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfObject(subType.baseType);
            })
            ], [grBool]);

    data.addPrimitive(&_full_i, "full?", ["chan"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.chan)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfInt(subType.baseType);
            })
            ], [grBool]);
    data.addPrimitive(&_full_f, "full?", ["chan"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.chan)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfFloat(subType.baseType);
            })
            ], [grBool]);
    data.addPrimitive(&_full_s, "full?", ["chan"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.chan)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfString(subType.baseType);
            })
            ], [grBool]);
    data.addPrimitive(&_full_o, "full?", ["chan"], [
            grAny("A", (type, data) {
                if (type.baseType != GrBaseType.chan)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOfObject(subType.baseType);
            })
            ], [grBool]);
}

private void _size_i(GrCall call) {
    call.setInt(cast(int) call.getIntChannel("chan").size);
}

private void _size_f(GrCall call) {
    call.setInt(cast(int) call.getFloatChannel("chan").size);
}

private void _size_s(GrCall call) {
    call.setInt(cast(int) call.getStringChannel("chan").size);
}

private void _size_o(GrCall call) {
    call.setInt(cast(int) call.getObjectChannel("chan").size);
}

private void _capacity_i(GrCall call) {
    call.setInt(cast(int) call.getIntChannel("chan").capacity);
}

private void _capacity_f(GrCall call) {
    call.setInt(cast(int) call.getFloatChannel("chan").capacity);
}

private void _capacity_s(GrCall call) {
    call.setInt(cast(int) call.getStringChannel("chan").capacity);
}

private void _capacity_o(GrCall call) {
    call.setInt(cast(int) call.getObjectChannel("chan").capacity);
}

private void _empty_i(GrCall call) {
    const GrIntChannel chan = call.getIntChannel("chan");
    call.setBool(chan.isEmpty);
}

private void _empty_f(GrCall call) {
    const GrFloatChannel chan = call.getFloatChannel("chan");
    call.setBool(chan.isEmpty);
}

private void _empty_s(GrCall call) {
    const GrStringChannel chan = call.getStringChannel("chan");
    call.setBool(chan.isEmpty);
}

private void _empty_o(GrCall call) {
    const GrObjectChannel chan = call.getObjectChannel("chan");
    call.setBool(chan.isEmpty);
}

private void _full_i(GrCall call) {
    const GrIntChannel chan = call.getIntChannel("chan");
    call.setBool(chan.isFull);
}

private void _full_f(GrCall call) {
    const GrFloatChannel chan = call.getFloatChannel("chan");
    call.setBool(chan.isFull);
}

private void _full_s(GrCall call) {
    const GrStringChannel chan = call.getStringChannel("chan");
    call.setBool(chan.isFull);
}

private void _full_o(GrCall call) {
    const GrObjectChannel chan = call.getObjectChannel("chan");
    call.setBool(chan.isFull);
}