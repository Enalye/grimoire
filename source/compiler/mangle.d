/**
Grimoire
Copyright (c) 2017 Enalye

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising
from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product documentation would be appreciated but
	   is not required.

	2. Altered source versions must be plainly marked as such,
	   and must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source distribution.
*/

module compiler.mangle;

import std.conv: to;

import compiler.type;

dstring grType_mangleNamedFunction(dstring name, GrType[] signature) {
	dstring mangledName = name;
	foreach(type; signature) {
		mangledName ~= "$";
		final switch(type.baseType) with(GrBaseType) {
		case VoidType:
			mangledName ~= "v";
			break;
		case IntType:
			mangledName ~= "i";
			break;
		case FloatType:
			mangledName ~= "r";
			break;
		case BoolType:
			mangledName ~= "b";
			break;
		case StringType:
			mangledName ~= "s";
			break;
		case ArrayType:
			mangledName ~= "n";
			break;
		case ObjectType:
			mangledName ~= "o";
			break;
		case DynamicType:
			mangledName ~= "a";
			break;
        case StructType:
            mangledName ~= "d(" ~ type.mangledType ~ ")";
            break;
		case FunctionType:
            if(type.mangledReturnType.length == 0)
                type.mangledReturnType = "$v";
			mangledName ~= "f(" ~ type.mangledType ~ ")" ~ type.mangledReturnType;
			break;
		case TaskType:
            if(type.mangledReturnType.length == 0)
                type.mangledReturnType = "$v";
			mangledName ~= "t(" ~ type.mangledType ~ ")" ~ type.mangledReturnType;
			break;
		}
	}
	return mangledName;
}

GrType functionToVarType(GrFunction func) {
    GrType type = func.isTask ? GrBaseType.TaskType : GrBaseType.FunctionType;
    type.mangledType = grType_mangleNamedFunction("", func.signature);
    type.mangledReturnType = grType_mangleNamedFunction("", [func.returnType]);
    return type;
}

dstring grType_unmangleSubFunction(dstring mangledSignature, ref int i) {
    dstring subString;
    int blockCount = 1;
    if(i >= mangledSignature.length && mangledSignature[i] != '(')
        throw new Exception("Invalid mangling format");
    i ++;

    for(; i < mangledSignature.length; i ++) {
        switch(mangledSignature[i]) {
        case '(':
            blockCount ++;
            break;
        case ')':
            blockCount --;
            if(blockCount == 0) {
                return subString;
            }
            break;
        default:
            break;
        }
        subString ~= mangledSignature[i];
    }
    throw new Exception("Invalid mangling format");
}

GrType grType_unmangle(dstring mangledSignature) {
    GrType currentType = GrBaseType.VoidType;

    int i;
    if(i < mangledSignature.length) {
        //Type separator
        if(mangledSignature[i] != '$')
            throw new Exception("Invalid mangling format");
        i ++;

        //Value
        switch(mangledSignature[i]) {
        case 'v':
            currentType.baseType = GrBaseType.VoidType;
            break;
        case 'i':
            currentType.baseType = GrBaseType.IntType;
            break;
        case 'r':
            currentType.baseType = GrBaseType.FloatType;
            break;
        case 'b':
            currentType.baseType = GrBaseType.BoolType;
            break;
        case 's':
            currentType.baseType = GrBaseType.StringType;
            break;
        case 'n':
            currentType.baseType = GrBaseType.ArrayType;
            break;
        case 'o':
            currentType.baseType = GrBaseType.ObjectType;
            break;
        case 'a':
            currentType.baseType = GrBaseType.DynamicType;
            break;
        case 'd':
            currentType.baseType = GrBaseType.StructType;
            dstring structName;
            if((i + 2) >= mangledSignature.length)
                throw new Exception("Invalid mangling format");
            i ++;
            if(mangledSignature[i] != '(')
                throw new Exception("Invalid mangling format");
            i ++;
            while(mangledSignature[i] != ')') {
                structName ~= mangledSignature[i];
                i ++;
                if(i >= mangledSignature.length)
                    throw new Exception("Invalid mangling format");
            }
            currentType.mangledType = structName;
            break;
        case 'f':
            i ++;
            currentType.baseType = GrBaseType.FunctionType;
            currentType.mangledType = grType_unmangleSubFunction(mangledSignature, i);
            i ++;
            if((i + 1) >= mangledSignature.length || mangledSignature[i] != '$')
                throw new Exception("Invalid mangling format");
            i ++;
            currentType.mangledReturnType = "$";
            currentType.mangledReturnType ~= mangledSignature[i];
            break;
        case 't':
            currentType.baseType = GrBaseType.TaskType;
            currentType.mangledType = grType_unmangleSubFunction(mangledSignature, i);
            i ++;
            break;
        default:
            break;
        }
    }

    return currentType;
}

GrType[] grType_unmangleSignature(dstring mangledSignature) {
    GrType[] unmangledSignature;

    int i;
    while(i < mangledSignature.length) {
        //Type separator
        if(mangledSignature[i] != '$')
            throw new Exception("Invalid mangling format");
        i ++;

        //Value
        GrType currentType = GrBaseType.VoidType;
        switch(mangledSignature[i]) {
        case 'v':
            currentType.baseType = GrBaseType.VoidType;
            break;
        case 'i':
            currentType.baseType = GrBaseType.IntType;
            break;
        case 'r':
            currentType.baseType = GrBaseType.FloatType;
            break;
        case 'b':
            currentType.baseType = GrBaseType.BoolType;
            break;
        case 's':
            currentType.baseType = GrBaseType.StringType;
            break;
        case 'n':
            currentType.baseType = GrBaseType.ArrayType;
            break;
        case 'o':
            currentType.baseType = GrBaseType.ObjectType;
            break;
        case 'a':
            currentType.baseType = GrBaseType.DynamicType;
            break;
        case 'd':
            currentType.baseType = GrBaseType.StructType;
            dstring structName;
            if((i + 2) >= mangledSignature.length)
                throw new Exception("Invalid mangling format");
            i ++;
            if(mangledSignature[i] != '(')
                throw new Exception("Invalid mangling format");
            i ++;
            while(mangledSignature[i] != ')') {
                structName ~= mangledSignature[i];
                i ++;
                if(i >= mangledSignature.length)
                    throw new Exception("Invalid mangling format");
            }
            currentType.mangledType = structName;
            break;
        case 'f':
            i ++;
            currentType.baseType = GrBaseType.FunctionType;
            currentType.mangledType = grType_unmangleSubFunction(mangledSignature, i);

            i ++;
            if((i + 1) >= mangledSignature.length || mangledSignature[i] != '$')
                throw new Exception("Invalid mangling format");
            i ++;
            currentType.mangledReturnType = "$";
            currentType.mangledReturnType ~= mangledSignature[i];
            break;
        case 't':
            i ++;
            currentType.baseType = GrBaseType.TaskType;
            currentType.mangledType = grType_unmangleSubFunction(mangledSignature, i);
            break;
        default:
            break;
        }
        unmangledSignature ~= currentType;
        i ++;
    }
    return unmangledSignature;
}

string grType_getDisplay(GrType variableType) {
    final switch(variableType.baseType) with(GrBaseType) {
    case VoidType:
        return "void";
    case IntType:
        return "int";
    case FloatType:
        return "float";
    case BoolType:
        return "bool";
    case StringType:
        return "string";
    case ArrayType:
        return "array";
    case ObjectType:
        return "object";
    case DynamicType:
        return "var";
    case FunctionType:
        string result = "func(";
        int i;
        auto parameters = grType_unmangleSignature(variableType.mangledType);
        foreach(parameter; parameters) {
            result ~= grType_getDisplay(parameter);
            if((i + 2) <= parameters.length)
                result ~= ", ";
            i ++;
        }
        auto retType = grType_unmangle(variableType.mangledReturnType);
        result ~= ")";
        if(retType != GrBaseType.VoidType) {
            result ~= " " ~ grType_getDisplay(retType);
        }
        return result;
    case TaskType:
        string result = "task(";
        int i;
        auto parameters = grType_unmangleSignature(variableType.mangledType);
        foreach(parameter; parameters) {
            result ~= grType_getDisplay(parameter);
            if((i + 2) <= parameters.length)
                result ~= ", ";
            i ++;
        }
        result ~= ")";
        return result;
    case StructType:
        return to!string(variableType.mangledType);
    }
}
