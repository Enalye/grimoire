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

module script.type;

import std.conv: to;

import script.vm;
import script.coroutine;
import script.mangle;
import script.bytecode;

struct VarType {
    enum BaseType {
        VoidType, IntType, FloatType, BoolType, StringType,
        ArrayType, ObjectType, AnyType, FunctionType, TaskType,
        StructType
    }

    BaseType baseType;
    dstring mangledType, mangledReturnType;

    this(BaseType newBaseType) {
        baseType = newBaseType;
    }

    VarType opOpAssign(string op)(BaseType t) {
		mixin("baseType = baseType" ~ op ~ "t;");
		return this;
	}

    bool opEquals(const BaseType v) const {
		return (baseType == v);
	}

    bool opEquals(const VarType v) const {
        if(baseType != v.baseType)
            return false;
        if(baseType == BaseType.FunctionType || baseType == BaseType.TaskType)
           return mangledType == v.mangledType && mangledReturnType && v.mangledReturnType; 
        return true;
	}
}

alias BaseType = VarType.BaseType;

const VarType sVoidType = VarType(BaseType.VoidType);
const VarType sIntType = VarType(BaseType.IntType);
const VarType sFloatType = VarType(BaseType.FloatType);
const VarType sBoolType = VarType(BaseType.BoolType);
const VarType sStringType = VarType(BaseType.StringType);
const VarType sArrayType = VarType(BaseType.ArrayType);
const VarType sObjectType = VarType(BaseType.ObjectType);
const VarType sAnyType = VarType(BaseType.AnyType);


class Variable {
	VarType type;
	uint index;
	bool isGlobal, isInitialized, isAuto;
    dstring name;
}

class Structure {
    VarType[] signature;
    dstring[] fields;
}
Structure[dstring] structures;

VarType defineStructure(dstring name, dstring[] fields, VarType[] signature) {
    if(fields.length != signature.length)
        throw new Exception("Structure signature mismatch");
    Structure st = new Structure;
    st.signature = signature;
    st.fields = fields;
    structures[name] = st;

    VarType stType = BaseType.StructType;
    stType.mangledType = name;
    return stType;
}

bool isStructureType(dstring name) {
    if(name in structures)
        return true;
    return false;
}

Structure getStructure(dstring name) {
    auto structure = (name in structures);
    if(structure is null)
        throw new Exception("Undefined struct \'" ~ to!string(name) ~ "\'");
    return *structure;
}

void resolveStructuresDefinition() {
    foreach(structure; structures) {
        for(int i; i < structure.signature.length; i ++) {
            if(structure.signature[i].baseType == BaseType.VoidType) {
                if(isStructureType(structure.signature[i].mangledType)) {
                    structure.signature[i].baseType = BaseType.StructType;
                }
                else
                    throw new Exception("Cannot resolve def field");
            }
        }
    }
}

struct Instruction {
	Opcode opcode;
	uint value;
}

class Function {
	Variable[dstring] localVariables;
    uint[] localFreeVariables;
	Instruction[] instructions;
	uint stackSize, index;

	dstring name;
	VarType[] signature;
	VarType returnType;
	bool isTask, isAnonymous;

	FunctionCall[] functionCalls;
	Function anonParent;
	uint position, anonReference, anonIndex, localVariableIndex;

	uint nbStringParameters, nbIntegerParameters, nbFloatParameters,
		nbAnyParameters, nbObjectParameters;
}

class FunctionCall {
	dstring mangledName;
	uint position;
	Function caller, functionToCall;
	VarType expectedType;
    bool isAddress;
}
