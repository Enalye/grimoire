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

module script.parser;

import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.math;
import std.file;
import std.meta;

import script.vm;
import script.lexer;
import script.mangle;
import script.type;
import script.primitive;
import script.bytecode;

class Parser {
	int[] iconsts;
	float[] fconsts;
	dstring[] sconsts;

	uint scopeLevel;

	Variable[dstring] globalVariables;
	Function[dstring] functions;
	Function[] anonymousFunctions;

	uint current;
	Function currentFunction;
	Function[] functionStack;
	FunctionCall[] functionCalls;

	uint[][] breaksJumps;
	uint[][] continuesJumps;
	uint[] continuesDestinations;

	Lexeme[] lexemes;

	void reset() {
		current = 0u;
	}

	void advance() {
		if(current < lexemes.length)
			current ++;
	}

    void goBack() {
        if(current > 0u)
            current --;
    }

	bool checkAdvance() {
		if(isEnd())
			return false;
		
		advance();
		return true;
	}

	void openBlock() {
		scopeLevel ++;
	}

	void closeBlock() {
		scopeLevel --;
	}

	bool isEnd(int offset = 0) {
		return (current + offset) >= cast(uint)lexemes.length;
	}

	Lexeme get(int offset = 0) {
		uint position = current + offset;
		if(position < 0 || position >= cast(uint)lexemes.length) {
			logError("Unexpected end of file");
		}
		return lexemes[position];
	}

	uint registerIntConstant(int value) {
		foreach(uint index, int iconst; iconsts) {
			if(iconst == value)
				return index;
		}
		iconsts ~= value;
		return cast(uint)iconsts.length - 1;
	}

	uint registerFloatConstant(float value) {
		foreach(uint index, float fconst; fconsts) {
			if(fconst == value)
				return index;
		}
		fconsts ~= value;
		return cast(uint)fconsts.length - 1;
	}

	uint registerStringConstant(dstring value) {
		foreach(uint index, dstring sconst; sconsts) {
			if(sconst == value)
				return index;
		}
		sconsts ~= value;
		return cast(uint)sconsts.length - 1;
	}

	Variable registerSpecialVariable(dstring name, VarType type) {
		name = "~"d ~ name;
		Variable specialVariable;
		auto previousVariable = (name in currentFunction.localVariables);
		if(previousVariable is null)
			specialVariable = registerLocalVariable(name, type);
		else
			specialVariable = *previousVariable;
        specialVariable.isAuto = false;
        specialVariable.isInitialized = true; //We shortcut this check
		return specialVariable;
	}

	Variable registerLocalVariable(dstring name, VarType type) {
        if(type.baseType == BaseType.StructType) {
            //Register each field
            auto structure = getStructure(type.mangledType);
            for(int i; i < structure.signature.length; i ++) {
                registerLocalVariable(name ~ "." ~ structure.fields[i], structure.signature[i]);
            }
            //Register the struct itself with the id of the first field
            auto previousVariable = (name in currentFunction.localVariables);
            if(previousVariable !is null)
                logError("Multiple declaration", "The local variable \'" ~ to!string(name) ~ "\' is already declared.");

            Variable variable = new Variable;
            variable.index = currentFunction.localVariableIndex;
            variable.isGlobal = false;
            variable.type = type;
            variable.name = name;
            currentFunction.localVariables[name] = variable;

            return variable;
        }
		//To do: check if declared globally

		//Check if declared locally.
		auto previousVariable = (name in currentFunction.localVariables);
		if(previousVariable !is null)
			logError("Multiple declaration", "The local variable \'" ~ to!string(name) ~ "\' is already declared.");

		Variable variable = new Variable;
        if(currentFunction.localFreeVariables.length) {
            variable.index = currentFunction.localFreeVariables[$ - 1];
            currentFunction.localFreeVariables.length --;
        }
        else {
		    variable.index = currentFunction.localVariableIndex;
            currentFunction.localVariableIndex ++;
        }
		variable.isGlobal = false;
		variable.type = type;
        variable.name = name;
		currentFunction.localVariables[name] = variable;

		return variable;
	}

	void beginFunction(dstring name, VarType[] signature, dstring[] inputVariables, bool isTask, VarType returnType = BaseType.VoidType) {
		dstring mangledName = mangleName(name, signature);

		auto func = mangledName in functions;
		if(func is null)
			logError("Undeclared function", "The function \'" ~ to!string(name) ~ "\' is not declared.");

		functionStack ~= currentFunction;
		currentFunction = *func;
	}

	void preBeginFunction(dstring name, VarType[] signature, dstring[] inputVariables, bool isTask, VarType returnType = BaseType.VoidType, bool isAnonymous = false) {
		Function func = new Function;
		func.isTask = isTask;
		func.signature = signature;
		func.returnType = returnType;

		if(isAnonymous) {
			func.index = cast(uint)anonymousFunctions.length;
			func.anonParent = currentFunction;
			func.anonReference = cast(uint)currentFunction.instructions.length;
			func.name = currentFunction.name ~ "@anon"d ~ to!dstring(func.index);
			anonymousFunctions ~= func;

			//Is replaced by the addr of the function later (see solveFunctionCalls).
			addInstruction(Opcode.LocalStore_Int, 0u);

			//Reserve constant for the function's address.
			func.anonIndex = cast(uint)iconsts.length;
			iconsts ~= 0u;
		}
		else {
			func.index = cast(uint)functions.length;
			func.name = name;

			dstring mangledName = mangleName(name, signature);
			auto previousFunc = (mangledName in functions);
			if(previousFunc !is null)
				logError("Multiple declaration", "The function \'" ~ to!string(name) ~ "\' is already declared.");
		
			functions[mangledName] = func;	
		}

		functionStack ~= currentFunction;
		currentFunction = func;
		addInstruction(Opcode.LocalStack, 0u);

		void fetchParameter(dstring name, VarType type) {
            final switch(type.baseType) with(BaseType) {
            case VoidType:
                logError("Invalid type", "Void is not a valid parameter type");
                break;
            case IntType:
            case BoolType:
            case FunctionType:
            case TaskType:
                func.nbIntegerParameters ++;
                if(func.isTask)
                    addInstruction(Opcode.GlobalPop_Int, 0u);
                break;
            case FloatType:
                func.nbFloatParameters ++;
                if(func.isTask)
                    addInstruction(Opcode.GlobalPop_Float, 0u);
                break;
            case StringType:
                func.nbStringParameters ++;
                if(func.isTask)
                    addInstruction(Opcode.GlobalPop_String, 0u);
                break;
            case ArrayType:
                func.nbStringParameters ++;
                if(func.isTask)
                    addInstruction(Opcode.GlobalPop_Array, 0u);
                break;
            case AnyType:
                func.nbAnyParameters ++;
                if(func.isTask)
                    addInstruction(Opcode.GlobalPop_Any, 0u);
                break;
            case ObjectType:
                func.nbObjectParameters ++;
                if(func.isTask)
                    addInstruction(Opcode.GlobalPop_Object, 0u);
                break;
            case StructType:
                auto structure = getStructure(type.mangledType);
                const auto nbFields = structure.signature.length;
                for(int i = 1; i <= structure.signature.length; i ++) {
                    fetchParameter(name ~ "." ~ structure.fields[nbFields - i], structure.signature[nbFields - i]);
                }
                break;
            }

            Variable newVar = new Variable;
            newVar.type = type;
            newVar.isInitialized = true;
            newVar.index = func.localVariableIndex;
            if(type.baseType != BaseType.StructType)
                func.localVariableIndex ++;
            newVar.isGlobal = false;
            newVar.name = name;
            func.localVariables[name] = newVar;
            if(type.baseType != BaseType.StructType)
                addSetInstruction(newVar);
        }

        foreach_reverse(size_t i, inputVariable; inputVariables) {
            fetchParameter(inputVariables[i], signature[i]);
        }
        

		/+if(func.nbIntegerParameters > 0u)
			addInstruction(Opcode.PopStack_Int, func.nbIntegerParameters);
        if(func.nbFloatParameters > 0u)
			addInstruction(Opcode.PopStack_Float, func.nbFloatParameters);
		if(func.nbStringParameters > 0u)
			addInstruction(Opcode.PopStack_String, func.nbStringParameters);
		if(func.nbAnyParameters > 0u)
			addInstruction(Opcode.PopStack_Any, func.nbAnyParameters);+/
	}

	void endFunction() {
		setInstruction(Opcode.LocalStack, 0u, currentFunction.localVariableIndex);
		if(!functionStack.length)
			logError("Missing symbol", "A \'}\' is missing, causing a mismatch");
		currentFunction = functionStack[$ - 1];
	}

	void preEndFunction() {
		if(!functionStack.length)
			logError("Missing symbol", "A \'}\' is missing, causing a mismatch");
		currentFunction = functionStack[$ - 1];
	}

	Function* getFunction(dstring name) {
		auto func = (name in functions);
		if(func is null)
			logError("Undeclared function", "The function \'" ~ to!string(name) ~ "\' is not declared");
		return func;
	}

	Variable getVariable(dstring name) {
		auto var = (name in currentFunction.localVariables);
		if(var is null)
		    logError("Undeclared variable", "The variable \'" ~ to!string(name) ~ "\' is not declared");
        return *var;
	}

	void addIntConstant(int value) {
		addInstruction(Opcode.Const_Int, registerIntConstant(value));
	}

	void addFloatConstant(float value) {
		addInstruction(Opcode.Const_Float, registerFloatConstant(value));
	}

	void addBoolConstant(bool value) {
		addInstruction(Opcode.Const_Bool, value);
	}

	void addStringConstant(dstring value) {
		addInstruction(Opcode.Const_String, registerStringConstant(value));
	}

	void addInstruction(Opcode opcode, int value = 0, bool isSigned = false) {
		if(currentFunction is null)
			logError("Not in function", "The expression is located outside of a function or task, which is forbidden");

		Instruction instruction;
		instruction.opcode = opcode;
		if(isSigned) {
			if((value >= 0x800000) || (-value >= 0x800000))
				logError("Internal failure", "An opcode\'s signed value is exceeding limits");		
			instruction.value = value + 0x800000;
		}
		else
			instruction.value = value;
		currentFunction.instructions ~= instruction;
	}

	void setInstruction(Opcode opcode, uint index, int value = 0u, bool isSigned = false) {
		if(currentFunction is null)
			logError("Not in function", "The expression is located outside of a function or task, which is forbidden");

		if(index >= currentFunction.instructions.length)
			logError("Internal failure", "An instruction's index is exeeding the function size");

		Instruction instruction;
		instruction.opcode = opcode;
		if(isSigned) {
			if((value >= 0x800000) || (-value >= 0x800000))
				logError("Internal failure", "An opcode\'s signed value is exceeding limits");				
			instruction.value = value + 0x800000;
		}
		else
			instruction.value = value;
		currentFunction.instructions[index] = instruction;
	}

    bool isBinaryOperator(LexemeType lexType) {
        if(lexType >= LexemeType.Add && lexType <= LexemeType.Xor)
            return true;
        else
            return false;
    }

    VarType addCustomBinaryOperator(LexemeType lexType, VarType leftType, VarType rightType) {
        VarType resultType = BaseType.VoidType;
        dstring mangledName = mangleName("@op_" ~ getLexemeTypeStr(lexType), [leftType, rightType]);
        
        //Primitive check
        if(isPrimitiveDeclared(mangledName)) {
            Primitive primitive = getPrimitive(mangledName);
            addInstruction(Opcode.PrimitiveCall, primitive.index);
            resultType = primitive.returnType;
        }

        //Function check
        if(resultType.baseType == BaseType.VoidType) {
    		auto func = (mangledName in functions);
            if(func !is null) {
                resultType = addFunctionCall(mangledName);
            }
        }

        return resultType;     
    }

    VarType addBinaryOperator(LexemeType lexType, VarType leftType, VarType rightType) {
        VarType resultType = BaseType.VoidType;

        if(leftType != rightType) {
            //Check custom operator
            resultType = addCustomBinaryOperator(lexType, leftType, rightType);

            //If there is no custom operator defined, we try to convert and then try again
            if(resultType.baseType == BaseType.VoidType) {
                resultType = convertType(rightType, leftType, true);
                if(resultType.baseType != BaseType.VoidType) {
                    resultType = addBinaryOperator(lexType, resultType, resultType);
                }
            }
        }
        else {
            resultType = addInternalOperator(lexType, leftType);
            if(resultType.baseType == BaseType.VoidType) {
                resultType = addCustomBinaryOperator(lexType, leftType, rightType);
            }
        }
        if(resultType.baseType == BaseType.VoidType)
            logError("Operator Undefined", "There is no "
                ~ to!string(getLexemeTypeStr(lexType))
                ~ " operator defined for \'"
                ~ displayType(leftType)
                ~ "\' and \'"
                ~ displayType(rightType)
                ~ "\'");
        return resultType;
    }

	VarType addOperator(LexemeType lexType, ref VarType[] typeStack) {
        if(isBinaryOperator(lexType)) {
            typeStack[$ - 2] = addBinaryOperator(lexType, typeStack[$ - 2], typeStack[$ - 1]);
            typeStack.length --;
            return typeStack[$ - 1];
        }
        /*else if(isUnaryOperator(lexType)) {
            //Todo: unary operator
        }*/

        return VarType(BaseType.VoidType);		
	}

    VarType addInternalOperator(LexemeType lexType, VarType varType) {
        switch(varType.baseType) with(BaseType) {
        case BoolType:
            switch(lexType) with(LexemeType) {
            case And:
				addInstruction(Opcode.AndInt);
                return VarType(BaseType.BoolType);
			case Or:
				addInstruction(Opcode.OrInt);
                return VarType(BaseType.BoolType);
			case Not:
				addInstruction(Opcode.NotInt);
                return VarType(BaseType.BoolType);				
            default:
                break;
            }
            break;
		case IntType:
			switch(lexType) with(LexemeType) {
			case Add:
				addInstruction(Opcode.AddInt);
				return VarType(BaseType.IntType);
			case Substract:
				addInstruction(Opcode.SubstractInt);
				return VarType(BaseType.IntType);
			case Multiply:
				addInstruction(Opcode.MultiplyInt);
				return VarType(BaseType.IntType);
			case Divide:
				addInstruction(Opcode.DivideInt);
				return VarType(BaseType.IntType);
            case Remainder:
				addInstruction(Opcode.RemainderInt);
				return VarType(BaseType.IntType);
			case Minus:
				addInstruction(Opcode.NegativeInt);
				return VarType(BaseType.IntType);
			case Plus:
				return VarType(BaseType.IntType);
			case Increment:
				addInstruction(Opcode.IncrementInt);
				return VarType(BaseType.IntType);
			case Decrement:
				addInstruction(Opcode.DecrementInt);
				return VarType(BaseType.IntType);
			case Equal:
				addInstruction(Opcode.Equal_Int);
				return VarType(BaseType.BoolType);
			case NotEqual:
				addInstruction(Opcode.NotEqual_Int);
				return VarType(BaseType.BoolType);
			case Greater:
				addInstruction(Opcode.GreaterInt);
				return VarType(BaseType.BoolType);
			case GreaterOrEqual:
				addInstruction(Opcode.GreaterOrEqual_Int);
				return VarType(BaseType.BoolType);
			case Lesser:
				addInstruction(Opcode.LesserInt);
				return VarType(BaseType.BoolType);
			case LesserOrEqual:
				addInstruction(Opcode.LesserOrEqual_Int);
                return VarType(BaseType.BoolType);				
			default:
				break;
			}
			break;
		case FloatType:
			switch(lexType) with(LexemeType) {
			case Add:
				addInstruction(Opcode.AddFloat);
				return VarType(BaseType.FloatType);
			case Substract:
				addInstruction(Opcode.SubstractFloat);
				return VarType(BaseType.FloatType);
			case Multiply:
				addInstruction(Opcode.MultiplyFloat);
				return VarType(BaseType.FloatType);
			case Divide:
				addInstruction(Opcode.DivideFloat);
				return VarType(BaseType.FloatType);
            case Remainder:
				addInstruction(Opcode.RemainderFloat);
				return VarType(BaseType.FloatType);
			case Minus:
				addInstruction(Opcode.NegativeFloat);
				return VarType(BaseType.FloatType);
			case Plus:
				return VarType(BaseType.FloatType);
			case Increment:
				addInstruction(Opcode.IncrementFloat);
				return VarType(BaseType.FloatType);
			case Decrement:
				addInstruction(Opcode.DecrementFloat);
				return VarType(BaseType.FloatType);
			case Equal:
				addInstruction(Opcode.Equal_Float);
				return VarType(BaseType.BoolType);
			case NotEqual:
				addInstruction(Opcode.NotEqual_Float);
				return VarType(BaseType.BoolType);
			case Greater:
				addInstruction(Opcode.GreaterFloat);
				return VarType(BaseType.BoolType);
			case GreaterOrEqual:
				addInstruction(Opcode.GreaterOrEqual_Float);
				return VarType(BaseType.BoolType);
			case Lesser:
				addInstruction(Opcode.LesserFloat);
				return VarType(BaseType.BoolType);
			case LesserOrEqual:
				addInstruction(Opcode.LesserOrEqual_Float);
				return VarType(BaseType.BoolType);
			default:
				break;
			}
			break;
		case StringType:
			switch(lexType) with(LexemeType) {
			case Concatenate:
				addInstruction(Opcode.ConcatenateString);
				return VarType(BaseType.StringType);
			case Equal:
				addInstruction(Opcode.Equal_String);
				return VarType(BaseType.BoolType);
			case NotEqual:
				addInstruction(Opcode.NotEqual_String);
				return VarType(BaseType.BoolType);
			default:
				break;
			}
			break;
		case AnyType:
			switch(lexType) with(LexemeType) {
			case Add:
				addInstruction(Opcode.AddAny);
				return VarType(BaseType.AnyType);
			case Substract:
				addInstruction(Opcode.SubstractAny);
				return VarType(BaseType.AnyType);
			case Multiply:
				addInstruction(Opcode.MultiplyAny);
				return VarType(BaseType.AnyType);
			case Divide:
				addInstruction(Opcode.DivideAny);
				return VarType(BaseType.AnyType);
            case Remainder:
				addInstruction(Opcode.RemainderAny);
				return VarType(BaseType.AnyType);
			case Minus:
				addInstruction(Opcode.NegativeAny);
				return VarType(BaseType.AnyType);
			case Plus:
				return VarType(BaseType.AnyType);
			case Increment:
				addInstruction(Opcode.IncrementAny);
				return VarType(BaseType.AnyType);
			case Decrement:
				addInstruction(Opcode.DecrementAny);
				return VarType(BaseType.AnyType);
			case Concatenate:
				addInstruction(Opcode.ConcatenateAny);
				return VarType(BaseType.AnyType);
			case Equal:
				addInstruction(Opcode.Equal_Any);
				return VarType(BaseType.AnyType);
			case NotEqual:
				addInstruction(Opcode.NotEqual_Any);
				return VarType(BaseType.AnyType);
			case Greater:
				addInstruction(Opcode.GreaterAny);
				return VarType(BaseType.AnyType);
			case GreaterOrEqual:
				addInstruction(Opcode.GreaterOrEqual_Any);
				return VarType(BaseType.AnyType);
			case Lesser:
				addInstruction(Opcode.LesserAny);
				return VarType(BaseType.AnyType);
			case LesserOrEqual:
				addInstruction(Opcode.LesserOrEqual_Any);
				return VarType(BaseType.AnyType);
			case And:
				addInstruction(Opcode.AndAny);
				return VarType(BaseType.AnyType);
			case Or:
				addInstruction(Opcode.OrAny);
				return VarType(BaseType.AnyType);
			case Not:
				addInstruction(Opcode.NotAny);
				return VarType(BaseType.AnyType);
			default:
				break;
			}
			break;
		default:
            break;
		}
        return VarType(BaseType.VoidType);
    }

	void addSetInstruction(Variable variable, VarType valueType = BaseType.VoidType, bool isGettingValue = false) {
        if(variable is null) {
			addInstruction(isGettingValue ? Opcode.LocalStore2_Ref : Opcode.LocalStore_Ref);
            return;
        }
        
        if(!variable.isGlobal && variable.isAuto && !variable.isInitialized) {
            variable.isInitialized = true;
            variable.isAuto = false;
            variable.type = valueType;
            if(valueType.baseType == BaseType.StructType) {
                currentFunction.localFreeVariables ~= variable.index;
                auto structure = getStructure(valueType.mangledType);
                for(int i; i < structure.signature.length; i ++) {
                    registerLocalVariable(variable.name ~ "." ~ structure.fields[i], structure.signature[i]);
                }
            }
            else if(valueType.baseType == BaseType.VoidType)
                logError("Variable type error", "Cannot infer the type of variable");
        }
        
        if(valueType.baseType != BaseType.VoidType)
            convertType(valueType, variable.type);

		if(variable.isGlobal) {
			logError("Internal failure", "Global variable not implemented");
		}
		else {
            if(!variable.isInitialized && isGettingValue)
                logError("Uninitialized variable", "The variable is being used without being assigned");
            variable.isInitialized = true;
			switch(variable.type.baseType) with(BaseType) {
			case BoolType:
			case IntType:
			case FunctionType:
			case TaskType:
				addInstruction(isGettingValue ? Opcode.LocalStore2_Int : Opcode.LocalStore_Int, variable.index);
				break;
			case FloatType:
				addInstruction(isGettingValue ? Opcode.LocalStore2_Float : Opcode.LocalStore_Float, variable.index);
				break;
			case StringType:
				addInstruction(isGettingValue ? Opcode.LocalStore2_String : Opcode.LocalStore_String, variable.index);
				break;
            case ArrayType:
				addInstruction(isGettingValue ? Opcode.LocalStore2_Array : Opcode.LocalStore_Array, variable.index);
				break;
			case AnyType:
				addInstruction(isGettingValue ? Opcode.LocalStore2_Any : Opcode.LocalStore_Any, variable.index);
				break;
			case ObjectType:
				addInstruction(isGettingValue ? Opcode.LocalStore2_Object : Opcode.LocalStore_Object, variable.index);
				break;
            case StructType:
                auto structure = getStructure(variable.type.mangledType);
                const auto nbFields = structure.signature.length;
                for(int i = 1; i <= nbFields; i ++) {
                    addSetInstruction(getVariable(variable.name ~ "." ~ structure.fields[nbFields - i]), structure.signature[nbFields - i]);
                }
                break;
			default:
				logError("Invalid type", "Cannot assign to a \'" ~ to!string(variable.type) ~ "\' type");
			}
		}
	}

	void addGetInstruction(Variable variable, VarType expectedType = BaseType.VoidType) {
        if(variable.isGlobal) {
			logError("Internal failure", "Global variable not implemented");
		}
		else {
            if(!variable.isInitialized)
                logError("Uninitialized variable", "The variable is being used without being assigned");
			switch(variable.type.baseType) with(BaseType) {
			case BoolType:
			case IntType:
			case FunctionType:
			case TaskType:
				addInstruction(Opcode.LocalLoad_Int, variable.index);
				break;
			case FloatType:
				addInstruction(Opcode.LocalLoad_Float, variable.index);
				break;
			case StringType:
				addInstruction(Opcode.LocalLoad_String, variable.index);
				break;
			case ArrayType:
				addInstruction(Opcode.LocalLoad_Array, variable.index);
				break;
			case AnyType:
				addInstruction(Opcode.LocalLoad_Any, variable.index);
				break;
			case ObjectType:			
				addInstruction(Opcode.LocalLoad_Object, variable.index);
				break;
            case StructType:
                auto structure = getStructure(variable.type.mangledType);
                for(int i; i < structure.signature.length; i ++) {
                    addGetInstruction(getVariable(variable.name ~ "." ~ structure.fields[i]), structure.signature[i]);
                }
                break;
			default:
				logError("Invalid type", "Cannot fetch from a \'" ~ to!string(variable.type) ~ "\' type");
			}
		}
	}

    VarType addFunctionAddress(dstring mangledName) {
        FunctionCall call = new FunctionCall;
		call.mangledName = mangledName;
		call.caller = currentFunction;
		functionCalls ~= call;
		currentFunction.functionCalls ~= call;
        call.isAddress = true;

		auto func = (call.mangledName in functions);
		if(func !is null) {
		    call.functionToCall = *func;
            call.isAddress = true;
            call.position = cast(uint)currentFunction.instructions.length;
            addInstruction(Opcode.Const_Int, 0);

            return functionToVarType(*func);
        }

		return VarType(BaseType.VoidType);
    }

	VarType addFunctionCall(dstring mangledName) {
		FunctionCall call = new FunctionCall;
		call.mangledName = mangledName;
		call.caller = currentFunction;
		functionCalls ~= call;
		currentFunction.functionCalls ~= call;
        call.isAddress = false;

		auto func = (call.mangledName in functions);
		if(func !is null) {
			call.functionToCall = *func;
            if(func.isTask) {
                if(func.nbStringParameters > 0)
                    addInstruction(Opcode.GlobalPush_String, func.nbStringParameters);
                if(func.nbFloatParameters > 0)
                    addInstruction(Opcode.GlobalPush_Float, func.nbFloatParameters);
                if(func.nbIntegerParameters > 0)
                    addInstruction(Opcode.GlobalPush_Int, func.nbIntegerParameters);
                if(func.nbAnyParameters > 0)
                    addInstruction(Opcode.GlobalPush_Any, func.nbAnyParameters);
                if(func.nbObjectParameters > 0)
                    addInstruction(Opcode.GlobalPush_Object, func.nbObjectParameters);
            }

            call.position = cast(uint)currentFunction.instructions.length;
            addInstruction(Opcode.Call, 0);

			return func.returnType;
		}
		else
			logError("Undeclared function", "The function \'" ~ to!string(call.mangledName) ~ "\' is not declared");

		return VarType(BaseType.VoidType);
	}

	void setOpcode(ref uint[] opcodes, uint position, Opcode opcode, uint value = 0u, bool isSigned = false) {
		Instruction instruction;
		instruction.opcode = opcode;
		if(isSigned) {
			if((value >= 0x800000) || (-value >= 0x800000))
				logError("Internal failure", "An opcode\'s signed value is exceeding limits");	
			instruction.value = value + 0x800000;
		}
		else
			instruction.value = value;

		uint makeOpcode(uint instr, uint value) {
			return ((value << 8u) & 0xffffff00) | (instr & 0xff);
		}
		opcodes[position] = makeOpcode(cast(uint)instruction.opcode, instruction.value);
	}

	void solveFunctionCalls(ref uint[] opcodes) {
		foreach(FunctionCall call; functionCalls) {
			auto func = (call.mangledName in functions);
			if(func !is null) {
                if(call.isAddress)
                    setOpcode(opcodes, call.position, Opcode.Const_Int, registerIntConstant(func.position));
				else if(func.isTask)
					setOpcode(opcodes, call.position, Opcode.Task, func.position);
				else
					setOpcode(opcodes, call.position, Opcode.Call, func.position);
			}
			else
				logError("Undeclared function", "The function \'" ~ to!string(call.mangledName) ~ "\' is not declared");
		}

		foreach(func; anonymousFunctions) {
			iconsts[func.anonIndex] = func.position;
			setOpcode(opcodes, func.anonParent.position + func.anonReference, Opcode.Const_Int, func.anonIndex);
		}
	}

	void dump() {
		writeln("Code Generated:\n");
		foreach(uint i, int ivalue; iconsts)
			writeln(".iconst " ~ to!string(ivalue) ~ "\t;" ~ to!string(i));

		foreach(uint i, float fvalue; fconsts)
			writeln(".fconst " ~ to!string(fvalue) ~ "\t;" ~ to!string(i));

		foreach(uint i, dstring svalue; sconsts)
			writeln(".sconst " ~ to!string(svalue) ~ "\t;" ~ to!string(i));

		foreach(dstring funcName, Function func; functions) {
			if(func.isTask)
				writeln("\n.task " ~ funcName);
			else
				writeln("\n.function " ~ funcName);

			foreach(uint i, Instruction instruction; func.instructions) {
				writeln("[" ~ to!string(i) ~ "] " ~ to!string(instruction.opcode) ~ " " ~ to!string(instruction.value));
			}
		}
	}

	void parseScript(Lexer lexer) {
		preParseScript(lexer);
		reset();

		lexemes = lexer.lexemes;

		while(!isEnd()) {
			Lexeme lex = get();
			switch(lex.type) with(LexemeType) {
            case Struct:
                skipDeclaration();
                break;
			case Main:
				parseMainDeclaration();
				break;
			case TaskType:
				parseTaskDeclaration();
				break;
			case FunctionType:
				parseFunctionDeclaration();
				break;
			default:
				logError("Invalid type", "The type should be either main, func or task");
			}
		}
	}

	void preParseScript(Lexer lexer) {
		lexemes = lexer.lexemes;

        //Structure definitions
        while(!isEnd()) {
			Lexeme lex = get();
			switch(lex.type) with(LexemeType) {
            case Struct:
                parseStructureDeclaration();
                break;
			case Main:
			case TaskType:
			case FunctionType:
				skipDeclaration();
				break;
			default:
				logError("Invalid type", "The type should be either main, func or task");
			}
		}

        //Resolve all unresolved struct field types
        resolveStructuresDefinition();
        
        //Function definitions
        reset();
		while(!isEnd()) {
			Lexeme lex = get();
			switch(lex.type) with(LexemeType) {
            case Struct:
                skipDeclaration();
                break;
			case Main:
				preParseMainDeclaration();
				break;
			case TaskType:
				preParseTaskDeclaration();
				break;
			case FunctionType:
				preParseFunctionDeclaration();
				break;
			default:
				logError("Invalid type", "The type should be either main, func, task or struct");
			}
		}
	}

    void parseStructureDeclaration() {
		checkAdvance();
        if(get().type != LexemeType.Identifier)
            logError("Missing Identifier", "struct must have a name");
        dstring structName = get().svalue;
        checkAdvance();
        if(get().type != LexemeType.LeftCurlyBrace)
            logError("Missing {", "struct does not have a body");
        checkAdvance();

        dstring[] fields;
        VarType[] signature;
        while(!isEnd()) {
            if(get().type == LexemeType.VoidType)
                logError("No void plz", "svp");
            //Lazy check because we can't know about other structures
            auto fieldType = parseType(false);
            checkAdvance();

            //Unresolved type
            if(fieldType.baseType == BaseType.VoidType) {
                fieldType.mangledType = get().svalue;
                checkAdvance();
            }
            
            if(get().type != LexemeType.Identifier)
                logError("Missing Identifier", "struct field must have a name");

            auto fieldName = get().svalue;
            checkAdvance();

            signature ~= fieldType;
            fields ~= fieldName;

            if(get().type != LexemeType.Semicolon) 
                logError("Missing ;", "right there");
            checkAdvance();

            if(get().type == LexemeType.RightCurlyBrace) {
                checkAdvance();
                break;
            }
        }
        defineStructure(structName, fields, signature);
    }

    void skipDeclaration() {
        checkAdvance();
        while(!isEnd()) {
            if(get().type != LexemeType.LeftCurlyBrace) {
                checkAdvance();
            }
            else {
                skipBlock();
                return;
            }
        }
    }

    VarType parseType(bool mustBeType = true) {
        VarType currentType = BaseType.VoidType;

        Lexeme lex = get();
        if(!lex.isType) {
            if(lex.type == LexemeType.Identifier && isStructureType(lex.svalue)) {
                currentType.baseType = BaseType.StructType;
                currentType.mangledType = lex.svalue;
                return currentType;
            }
            else if(mustBeType) {
                logError("Excepted type", "A valid type is expected");
            }
            else {
                goBack();
                return currentType;
            }
        }

        switch(lex.type) with(LexemeType) {
        case VoidType:
            currentType.baseType = BaseType.VoidType;
            break;
        case IntType:
            currentType.baseType = BaseType.IntType;
            break;
        case FloatType:
            currentType.baseType = BaseType.FloatType;
            break;
        case BoolType:
            currentType.baseType = BaseType.BoolType;
            break;
        case StringType:
            currentType.baseType = BaseType.StringType;
            break;
        case ObjectType:
            currentType.baseType = BaseType.ObjectType;
            break;
        case ArrayType:
            currentType.baseType = BaseType.ArrayType;
            break;
        case AnyType:
            currentType.baseType = BaseType.AnyType;
            break;
        case FunctionType:
            currentType.baseType = BaseType.FunctionType;
            dstring[] temp; 
            currentType.mangledType = mangleName("", parseSignature(temp, true));
            currentType.mangledReturnType = mangleName("", [parseType(false)]);
            break;
        case TaskType:
            currentType.baseType = BaseType.TaskType;
            dstring[] temp; 
            currentType.mangledType = mangleName("", parseSignature(temp, true));
            currentType.mangledReturnType = mangleName("", [parseType(false)]);
            break;
        default:
            logError("Invalid type", "Cannot call a function with a parameter of type \'" ~ to!string(lex.type) ~ "\'");
        }

        return currentType;
    }

    void addGlobalPop(VarType type) {
        final switch(type.baseType) with(BaseType) {
        case VoidType:
            logError("Invalid type", "Void is not a valid parameter type");
            break;
        case IntType:
        case BoolType:
        case FunctionType:
        case TaskType:
            addInstruction(Opcode.GlobalPop_Int, 0u);
            break;
        case FloatType:
            addInstruction(Opcode.GlobalPop_Float, 0u);
            break;
        case StringType:
            addInstruction(Opcode.GlobalPop_String, 0u);
            break;
        case ArrayType:
            addInstruction(Opcode.GlobalPop_Array, 0u);
            break;
        case AnyType:
            addInstruction(Opcode.GlobalPop_Any, 0u);
            break;
        case ObjectType:
            addInstruction(Opcode.GlobalPop_Object, 0u);
            break;
        case StructType:
            auto structure = getStructure(type.mangledType);
            for(int i; i < structure.signature.length; i ++) {
                addGlobalPop(structure.signature[i]);
            }
            break;
        }
    }

    void addGlobalPush(VarType type, int nbPush = 1u) {
        final switch(type.baseType) with(BaseType) {
        case VoidType:
            logError("Invalid type", "Void is not a valid parameter type");
            break;
        case IntType:
        case BoolType:
        case FunctionType:
        case TaskType:
            addInstruction(Opcode.GlobalPush_Int, nbPush);
            break;
        case FloatType:
            addInstruction(Opcode.GlobalPush_Float, nbPush);
            break;
        case StringType:
            addInstruction(Opcode.GlobalPush_String, nbPush);
            break;
        case ArrayType:
            addInstruction(Opcode.GlobalPush_Array, nbPush);
            break;
        case AnyType:
            addInstruction(Opcode.GlobalPush_Any, nbPush);
            break;
        case ObjectType:
            addInstruction(Opcode.GlobalPush_Object, nbPush);
            break;
        case StructType:
            auto structure = getStructure(type.mangledType);
            for(int i = 1; i <= structure.signature.length; i ++) {
                addGlobalPush(structure.signature[structure.signature.length - i], nbPush);
            }
            break;
        }
    }

	VarType[] parseSignature(ref dstring[] inputVariables, bool asType = false) {
		VarType[] signature;

		checkAdvance();
		if(get().type != LexemeType.LeftParenthesis)
			logError("Missing symbol", "A signature should always start with \'(\'");

        bool startLoop = true;
		for(;;) {
			checkAdvance();
			Lexeme lex = get();

			if(startLoop && lex.type == LexemeType.RightParenthesis)
				break;
            startLoop = false;

            signature ~= parseType();

			

            //Is it a function type or a function declaration ?
            if(!asType) {
                checkAdvance();
                lex = get();
                if(get().type != LexemeType.Identifier)
                    logError("Missing identifier", "Expected a name such as \'foo\'");
                inputVariables ~= lex.svalue;
            }

			checkAdvance();
			lex = get();
			if(lex.type == LexemeType.RightParenthesis)
				break;
			else if(lex.type != LexemeType.Comma)
				logError("Missing symbol", "Either a \',\' or a \')\' is expected");
		}

		checkAdvance();

		return signature;
	}

	void parseMainDeclaration() {
		checkAdvance();
		beginFunction("main", [], [], false);
		parseBlock();
		addInstruction(Opcode.Kill);
		endFunction();
	}

	void preParseMainDeclaration() {
		checkAdvance();
		preBeginFunction("main", [], [], false);
		skipBlock();
		preEndFunction();
	}

	void parseTaskDeclaration() {
		checkAdvance();
		if(get().type != LexemeType.Identifier)
			logError("Missing identifier", "Expected a name such as \'foo\'");
		dstring name = get().svalue;
		dstring[] inputs;
		VarType[] signature = parseSignature(inputs);
		beginFunction(name, signature, inputs, true);
		parseBlock();
		addInstruction(Opcode.Kill);
		endFunction();
	}

	void preParseTaskDeclaration() {
		checkAdvance();
		if(get().type != LexemeType.Identifier)
			logError("Missing identifier", "Expected a name such as \'foo\'");
		dstring name = get().svalue;
		dstring[] inputs;
		VarType[] signature = parseSignature(inputs);
		preBeginFunction(name, signature, inputs, true);
		skipBlock();
		preEndFunction();
	}

	void parseFunctionDeclaration() {
		checkAdvance();
		if(get().type != LexemeType.Identifier)
			logError("Missing identifier", "Expected a name such as \'foo\'");
		dstring name = get().svalue;
        if(name == "operator") {
            checkAdvance();
            if(get().type >= LexemeType.Add && get().type <= LexemeType.Not) {
                name = "@op_" ~ getLexemeTypeStr(get().type);
            }
            else
                logError("Invalid Operator", "The specified operator must be valid");
        }
        writeln("parse: ", name);
		dstring[] inputs;
		VarType[] signature = parseSignature(inputs);

		parseType(false);
        checkAdvance();

		beginFunction(name, signature, inputs, false);
		parseBlock();
        if(currentFunction.instructions.length
            && currentFunction.instructions[$ - 1].opcode != Opcode.Return)
		    addInstruction(Opcode.Return);
		endFunction();
	}

	void preParseFunctionDeclaration() {
		checkAdvance();
		if(get().type != LexemeType.Identifier)
			logError("Missing identifier", "Expected a name such as \'foo\'");
		dstring name = get().svalue;
        if(name == "operator") {
            checkAdvance();
            if(get().type >= LexemeType.Add && get().type <= LexemeType.Not) {
                name = "@op_" ~ getLexemeTypeStr(get().type);
            }
            else
                logError("Invalid Operator", "The specified operator must be valid");
        }
        writeln("preparse: ", name);
		dstring[] inputs;
		VarType[] signature = parseSignature(inputs);

		//Return Type.
        VarType returnType = parseType(false);
        checkAdvance();

		preBeginFunction(name, signature, inputs, false, returnType);
		skipBlock();
		preEndFunction();
	}

	VarType parseAnonymousFunction(bool isTask) {
		dstring[] inputs;
		VarType returnType = BaseType.VoidType;
		VarType[] signature = parseSignature(inputs);

		if(!isTask) {
			//Return Type.
            returnType = parseType(false);
			checkAdvance();
		}

		preBeginFunction("$anon"d, signature, inputs, isTask, returnType, true);
		parseBlock();
		addInstruction(Opcode.Return);
		endFunction();

        VarType functionType = isTask ? BaseType.TaskType : BaseType.FunctionType;
        functionType.mangledType = mangleName("", signature);
        functionType.mangledReturnType = mangleName("", [returnType]);

        return functionType;
	}

	void parseBlock() {
		if(get().type != LexemeType.LeftCurlyBrace)
			logError("Missing symbol", "A block should always start with \'{\'");
		openBlock();

		if(!checkAdvance())
			logError("Unexpected end of file");

		whileLoop: while(!isEnd()) {
			Lexeme lex = get();
            switch(lex.type) with(LexemeType) {
            case Semicolon:
                advance();
                break;
            case RightCurlyBrace:
                break whileLoop;
            case If:
                parseIfStatement();
                break;
            case While:
                parseWhileStatement();
                break;
            case Do:
                parseDoWhileStatement();
                break;
            case For:
                parseForStatement();
                break;
            case Loop:
                parseLoopStatement();
                break;
            case Return:
                parseReturnStatement();
                break;
            case Yield:
                parseYield();
                break;
            case Continue:
                parseContinue();
                break;
            case Break:
                parseBreak();
                break;
            case VoidType: .. case AutoType:
                parseLocalDeclaration();
                break;
            case Identifier:
                if(isStructureType(lex.svalue))
                    parseLocalDeclaration();
                else
                    goto default;
                break;
            default:
                parseExpression();
                break;
            }
		}

		if(get().type != LexemeType.RightCurlyBrace)
			logError("Missing symbol", "A block should always end with \'}\'");
		closeBlock();
		checkAdvance();
	}

	void skipBlock() {
		if(get().type != LexemeType.LeftCurlyBrace)
			logError("Missing symbol", "A block should always start with \'{\'");
		openBlock();

		if(!checkAdvance())
			logError("Unexpected end of file");

		whileLoop: while(!isEnd()) {
			Lexeme lex = get();
			switch(lex.type) with(LexemeType) {
			case RightCurlyBrace:
				break whileLoop;
			case LeftCurlyBrace:
				skipBlock();
				break;
			default:
				checkAdvance();
				break;
			}
		}
		
		if(get().type != LexemeType.RightCurlyBrace)
			logError("Missing symbol", "A block should always end with \'}\'");
		closeBlock();
		checkAdvance();
	}

    void parseYield() {
		addInstruction(Opcode.Yield, 0u);
        advance();                    
    }

	//Break
	void openBreakableSection() {
		breaksJumps ~= [null];
	}

	void closeBreakableSection() {
		if(!breaksJumps.length)
			logError("Breakable section error", "A breakable section had a mismatch");

		uint[] continues = breaksJumps[$ - 1];
		breaksJumps.length --;

		foreach(position; continues)
			setInstruction(Opcode.Jump, position, cast(int)(position - currentFunction.instructions.length), true);
	}

	void parseBreak() {
		if(!breaksJumps.length)
			logError("Non breakable statement", "The break statement is not inside a breakable statement");

		breaksJumps[$ - 1] ~= cast(uint)currentFunction.instructions.length;
		addInstruction(Opcode.Jump);
		advance();
	}

	//Continue
	void openContinuableSection() {
		continuesJumps ~= [null];
	}

	void closeContinuableSection() {
		if(!continuesJumps.length)
			logError("Continuable section error", "A continuable section had a mismatch");

		uint[] continues = continuesJumps[$ - 1];
		uint destination = continuesDestinations[$ - 1];
		continuesJumps.length --;
		continuesDestinations.length --;

		foreach(position; continues)
			setInstruction(Opcode.Jump, position, cast(int)(position - destination), true);
	}

	void setContinuableSectionDestination() {
		continuesDestinations ~= cast(uint)currentFunction.instructions.length;
	}

	void parseContinue() {
		if(!continuesJumps.length)
			logError("Non continuable statement", "The continue statement is not inside a continuable statement");

		continuesJumps[$ - 1] ~= cast(uint)currentFunction.instructions.length;
		addInstruction(Opcode.Jump);
		advance();
	}

	//Type Identifier [= EXPRESSION] ;
	void parseLocalDeclaration() {
        //Variable type
        VarType type = BaseType.VoidType;
        bool isAuto;
        if(get().type == LexemeType.AutoType)
            isAuto = true;
        else
            type = parseType();
        checkAdvance();

        //Identifier
		if(get().type != LexemeType.Identifier)
			logError("Missing identifier", "Expected a name such as \'foo\'");

		dstring identifier = get().svalue;

        //Registering
		Variable variable = registerLocalVariable(identifier, type);
        variable.isAuto = isAuto;

        //A structure does not need to be initialized.
        if(variable.type == BaseType.StructType)
            variable.isInitialized = true;
		
		checkAdvance();
		switch(get().type) with(LexemeType) {
		case Assign:
			checkAdvance();
			VarType expressionType = parseSubExpression(false);
			addSetInstruction(variable, expressionType);
			break;
		case Semicolon:
			break;
		default:
			logError("Invalid symbol", "A declaration must either be terminated by a ; or assigned with =");
		}
	}

    VarType parseFunctionReturnType() {
        VarType returnType = BaseType.VoidType;
        if(get().isType) {
            switch(get().type) with(LexemeType) {
            case IntType:
                returnType = VarType(BaseType.IntType);
                break;
            case FloatType:
                returnType = VarType(BaseType.FloatType);
                break;
            case BoolType:
                returnType = VarType(BaseType.BoolType);
                break;
            case StringType:
                returnType = VarType(BaseType.StringType);
                break;
            case ObjectType:
                returnType = VarType(BaseType.ObjectType);
                break;
            case ArrayType:
                returnType = VarType(BaseType.ArrayType);
                break;
            case AnyType:
                returnType = VarType(BaseType.AnyType);
                break;
            case FunctionType:
                VarType type = BaseType.FunctionType;
                dstring[] temp; 
                type.mangledType = mangleName("", parseSignature(temp, true));
                returnType = type;
                break;
            case TaskType:
                VarType type = BaseType.TaskType;
                dstring[] temp; 
                type.mangledType = mangleName("", parseSignature(temp, true));
                returnType = type;
                break;
            default:
                logError("Invalid type", "A " ~ to!string(get().type) ~ " is not a valid return type");
            }

            checkAdvance();
        }

        return returnType;
    }

	void parseIfStatement() {
		advance();
		if(get().type != LexemeType.LeftParenthesis)
			logError("Missing symbol", "A condition should always start with \'(\'");

		advance();
		parseSubExpression();
		advance();

		uint jumpPosition = cast(uint)currentFunction.instructions.length;
		addInstruction(Opcode.JumpEqual); //Jumps to if(0).

		parseBlock(); //{ .. }

		//If(1){}, jumps out.
		uint[] exitJumps;
		exitJumps ~= cast(uint)currentFunction.instructions.length;
		addInstruction(Opcode.Jump);

		//If(0) destination.
		setInstruction(Opcode.JumpEqual, jumpPosition, cast(int)(currentFunction.instructions.length - jumpPosition), true);

		bool isElseIf;
		do {
			isElseIf = false;
			if(get().type == LexemeType.Else) {
				checkAdvance();
				if(get().type == LexemeType.If) {
					isElseIf = true;
					checkAdvance();
					if(get().type != LexemeType.LeftParenthesis)
						logError("Missing symbol", "A condition should always start with \'(\'");
					checkAdvance();

					parseSubExpression();

					jumpPosition = cast(uint)currentFunction.instructions.length;
					addInstruction(Opcode.JumpEqual); //Jumps to if(0).

					parseBlock(); //{ .. }

					//If(1){}, jumps out.
					exitJumps ~= cast(uint)currentFunction.instructions.length;
					addInstruction(Opcode.Jump);

					//If(0) destination.
					setInstruction(Opcode.JumpEqual, jumpPosition, cast(int)(currentFunction.instructions.length - jumpPosition), true);
				}
				else
					parseBlock();
			}
		}
		while(isElseIf);

		foreach(uint position; exitJumps)
			setInstruction(Opcode.Jump, position, cast(int)(currentFunction.instructions.length - position), true);
	}

	void parseWhileStatement() {
		advance();
		if(get().type != LexemeType.LeftParenthesis)
			logError("Missing symbol", "A condition should always start with \'(\'");

		/* While is breakable and continuable. */
		openBreakableSection();
		openContinuableSection();

		/* Continue jump. */
		setContinuableSectionDestination();

		uint conditionPosition,
			blockPosition = cast(uint)currentFunction.instructions.length;

		advance();
		parseSubExpression();

		advance();
		conditionPosition = cast(uint)currentFunction.instructions.length;
		addInstruction(Opcode.JumpEqual);

		parseBlock();

		addInstruction(Opcode.Jump, cast(int)(blockPosition - currentFunction.instructions.length), true);
		setInstruction(Opcode.JumpEqual, conditionPosition, cast(int)(currentFunction.instructions.length - conditionPosition), true);

		/* While is breakable and continuable. */
		closeBreakableSection();
		closeContinuableSection();
	}

	void parseDoWhileStatement() {
		advance();

		/* While is breakable and continuable. */
		openBreakableSection();
		openContinuableSection();

		uint blockPosition = cast(uint)currentFunction.instructions.length;

		parseBlock();
		if(get().type != LexemeType.While)
			logError("Missing while", "A do-while statement expects the keyword while after \'}\'");
		advance();

		/* Continue jump. */
		setContinuableSectionDestination();

		if(get().type != LexemeType.LeftParenthesis)
			logError("Missing symbol", "A condition should always start with \'(\'");

		advance();
		parseSubExpression();
		advance();

		addInstruction(Opcode.JumpNotEqual, cast(int)(blockPosition - currentFunction.instructions.length), true);

		/* While is breakable and continuable. */
		closeBreakableSection();
		closeContinuableSection();
	}

	void parseForStatement() {
		advance();
		if(get().type != LexemeType.LeftParenthesis)
			logError("Missing symbol", "A condition should always start with \'(\'");

		advance();
		Lexeme identifier = get();
		if(identifier.type != LexemeType.Identifier)
			logError("Missing identifier", "For syntax: for(identifier, array) {}");
		Variable variable = getVariable(identifier.svalue);
		 
		advance();
		if(get().type != LexemeType.Comma)
			logError("Missing symbol", "Did you forget the \',\' ?");
		advance();

		/* Init */
		Variable iterator = registerSpecialVariable("iterator"d ~ to!dstring(scopeLevel), VarType(BaseType.IntType));
		Variable index = registerSpecialVariable("index"d ~ to!dstring(scopeLevel), VarType(BaseType.IntType));
		Variable array = registerSpecialVariable("array"d ~ to!dstring(scopeLevel), VarType(BaseType.ArrayType));
		
		//From length to 0
		VarType arrayType = parseSubExpression();
		addSetInstruction(array, VarType(BaseType.VoidType), true);
		addInstruction(Opcode.ArrayLength);
		addInstruction(Opcode.LocalStore_upIterator);		
		addSetInstruction(iterator);

		//Set index to -1
		addIntConstant(-1);
		addSetInstruction(index);

		/* For is breakable and continuable. */
		openBreakableSection();
		openContinuableSection();

		/* Continue jump. */
		setContinuableSectionDestination();


		advance();
		uint blockPosition = cast(uint)currentFunction.instructions.length;

		addGetInstruction(iterator, VarType(BaseType.IntType));
		addInstruction(Opcode.DecrementInt);
		addSetInstruction(iterator);

		addGetInstruction(iterator, VarType(BaseType.IntType));
		uint jumpPosition = cast(uint)currentFunction.instructions.length;
		addInstruction(Opcode.JumpEqual);

		//Set Index
		addGetInstruction(array);
		addGetInstruction(index);
		addInstruction(Opcode.IncrementInt);
		addSetInstruction(index, VarType(BaseType.VoidType), true);
		addInstruction(Opcode.ArrayIndex);
		convertType(VarType(BaseType.AnyType), variable.type);
		addSetInstruction(variable);

		parseBlock();

		addInstruction(Opcode.Jump, cast(int)(blockPosition - currentFunction.instructions.length), true);
		setInstruction(Opcode.JumpEqual, jumpPosition, cast(int)(currentFunction.instructions.length - jumpPosition), true);

		/* For is breakable and continuable. */
		closeBreakableSection();
		closeContinuableSection();
	}

	void parseLoopStatement() {
		advance();
		if(get().type != LexemeType.LeftParenthesis)
			logError("Missing symbol", "A condition should always start with \'(\'");

		advance();

		/* Init */
		Variable iterator = registerSpecialVariable("iterator"d ~ to!dstring(scopeLevel), VarType(BaseType.IntType));
	
		//Init counter
		VarType type = parseSubExpression();
		convertType(type, VarType(BaseType.IntType));
		addInstruction(Opcode.LocalStore_upIterator);
		addSetInstruction(iterator);

		/* For is breakable and continuable. */
		openBreakableSection();
		openContinuableSection();

		/* Continue jump. */
		setContinuableSectionDestination();


		advance();
		uint blockPosition = cast(uint)currentFunction.instructions.length;

		addGetInstruction(iterator, VarType(BaseType.IntType));
		addInstruction(Opcode.DecrementInt);
		addSetInstruction(iterator);

		addGetInstruction(iterator, VarType(BaseType.IntType));
		uint jumpPosition = cast(uint)currentFunction.instructions.length;
		addInstruction(Opcode.JumpEqual);

		parseBlock();

		addInstruction(Opcode.Jump, cast(int)(blockPosition - currentFunction.instructions.length), true);
		setInstruction(Opcode.JumpEqual, jumpPosition, cast(int)(currentFunction.instructions.length - jumpPosition), true);

		/* For is breakable and continuable. */
		closeBreakableSection();
		closeContinuableSection();
	}

	void parseReturnStatement() {
		checkAdvance();
        if(currentFunction.name == "main") {
            addInstruction(Opcode.Kill);            
        }
        else if(currentFunction.returnType == VarType(BaseType.VoidType)) {
            addInstruction(Opcode.Return);
        }
        else {
            VarType returnedType = parseSubExpression(false);
            if(returnedType != currentFunction.returnType)
                logError("Invalid return type", "The returned type \'" ~ to!string(returnedType) ~ "\' does not match the function definition \'" ~ to!string(currentFunction.returnType) ~ "\'");

            addInstruction(Opcode.Return);
        }
	}

    uint getLeftOperatorPriority(LexemeType type) {
		switch(type) with(LexemeType) {
        case Assign: .. case PowerAssign:
            return 6;
        case Or:
            return 1;
        case Xor:
            return 2;
        case And:
            return 3;
        case Equal: .. case NotEqual:
            return 14;
        case GreaterOrEqual: .. case Lesser:
            return 15;
        case Add: .. case Substract:
            return 16;
        case Multiply: .. case Remainder:
            return 17;
        case Power:
            return 18;
        case Not:
        case Plus:
        case Minus:
        case Increment:
        case Decrement:
            return 19;
        default:
            logError("Unknown priority", "The operator is not listed in the operator priority table");
            return 0;
		}
	}

	uint getRightOperatorPriority(LexemeType type) {
		switch(type) with(LexemeType) {
        case Assign: .. case PowerAssign:
            return 20;
        case Or:
            return 1;
        case Xor:
            return 2;
        case And:
            return 3;
        case Equal: .. case NotEqual:
            return 4;
        case GreaterOrEqual: .. case Lesser:
            return 5;
        case Add: .. case Substract:
            return 7;
        case Multiply: .. case Remainder:
            return 8;
        case Power:
            return 9;
        case Not:
        case Plus:
        case Minus:
        case Increment:
        case Decrement:
            return 19;
        default:
            logError("Unknown priority", "The operator is not listed in the operator priority table");
            return 0;
		}
	}

	VarType convertType(VarType src, VarType dst, bool noFail = false, bool isExplicit = false) {
		switch(src.baseType) with(BaseType) {
        case FunctionType:
            switch(dst.baseType) with(BaseType) {
			case FunctionType:
                if(src.mangledType == dst.mangledType && src.mangledReturnType == dst.mangledReturnType)
				    return dst;
                break;
			/+case AnyType:
				addInstruction(Opcode.ConvertFunctionToAny);
				return AnyType;+/
			default:
				break;
			}
			break;
        case TaskType:
            switch(dst.baseType) with(BaseType) {
			case TaskType:
				if(src.mangledType == dst.mangledType && src.mangledReturnType == dst.mangledReturnType)
				    return dst;
                break;
			/+case AnyType:
				addInstruction(Opcode.ConvertTaskToAny);
				return AnyType;+/
			default:
				break;
			}
			break;
        case BoolType:
            switch(dst.baseType) with(BaseType) {
			case BoolType:
				return VarType(BoolType);
			case AnyType:
				addInstruction(Opcode.ConvertBoolToAny);
				return VarType(AnyType);
			default:
				break;
			}
			break;
		case IntType:
			switch(dst.baseType) with(BaseType) {
			case IntType:
				return VarType(IntType);
			case AnyType:
				addInstruction(Opcode.ConvertIntToAny);
				return VarType(AnyType);
			default:
				break;
			}
			break;
		case FloatType:
			switch(dst.baseType) with(BaseType) {
			case FloatType:
				return VarType(FloatType);
			case AnyType:
				addInstruction(Opcode.ConvertFloatToAny);
				return VarType(AnyType);
			default:
				break;
			}
			break;
		case StringType:
			switch(dst.baseType) with(BaseType) {
			case StringType:
				return VarType(StringType);
			case AnyType:
				addInstruction(Opcode.ConvertStringToAny);
				return VarType(AnyType);
			default:
				break;
			}
			break;
		case AnyType:
			switch(dst.baseType) with(BaseType) {
			case AnyType:
				return VarType(AnyType);
            case BoolType:
				addInstruction(Opcode.ConvertAnyToBool);
				return VarType(BoolType);
			case IntType:
				addInstruction(Opcode.ConvertAnyToInt);
				return VarType(IntType);
			case FloatType:
				addInstruction(Opcode.ConvertAnyToFloat);
				return VarType(FloatType);
			case StringType:
				addInstruction(Opcode.ConvertAnyToString);
				return VarType(StringType);
            case ArrayType:
				addInstruction(Opcode.ConvertAnyToArray);
				return VarType(ArrayType);
			default:
				break;
			}
			break;
		case ArrayType:
            switch(dst.baseType) with(BaseType) {
			case ArrayType:
				return VarType(ArrayType);
			case AnyType:
				addInstruction(Opcode.ConvertArrayToAny);
				return VarType(AnyType);
			default:
				break;
			}
            break;
        case StructType:
            switch(dst.baseType) with(BaseType) {
            case StructType:
                if(dst.mangledType != src.mangledType)
                    break;
                return dst;
            default:
                break;
            }
            break;
		default:
			break;
		}

        if(!noFail)
		    logError("Incompatible types", "Cannot convert \'" ~ displayType(src) ~ "\' to \'" ~ displayType(dst) ~ "\'");
		return VarType(BaseType.VoidType);	
	}

    void parseArrayBuilder() {
        if(get().type != LexemeType.LeftBracket)
            logError("Missing [", "Missing [");
        advance();

        int arraySize;
        while(get().type != LexemeType.RightBracket) {
            convertType(parseSubExpression(), sAnyType);
            arraySize ++;

            if(get().type == LexemeType.RightBracket)
                break;
            if(get().type != LexemeType.Comma)
                logError("Missing comma or ]", "bottom text");
            checkAdvance();
        }

        addInstruction(Opcode.ArrayBuild, arraySize);
        advance();
    }

    void parseArrayIndex(bool asRefType) {
        if(get().type != LexemeType.LeftBracket)
            logError("Missing [", "Missing [");
        advance();

        for(;;) {
            if(get().type == LexemeType.Comma)
                logError("Missing value", "bottom text");
            auto index = parseSubExpression();
            if(index.baseType == BaseType.VoidType)
                logError("Syntax Error", "right there");
            convertType(index, sIntType);

            if(get().type == LexemeType.RightBracket) {
                addInstruction(asRefType ? Opcode.ArrayIndexRef : Opcode.ArrayIndex);
                break;
            }
            if(get().type != LexemeType.Comma)
                logError("Missing comma or ]", "bottom text");
            checkAdvance();
            if(get().type == LexemeType.RightBracket)
                logError("Missing comma or ]", "bottom text");

            addInstruction(asRefType ? Opcode.ArrayIndexRef : Opcode.ArrayIndex);
            asRefType = true;
        }

        advance();
    }

    VarType parseStructureField(VarType type) {
        dstring fieldName;
        VarType fieldType = BaseType.VoidType;

        advance();
        if(type.baseType != BaseType.StructType)
            logError("Invalid type", "Cannot access struct field");
        if(get().type != LexemeType.Identifier)
            logError("Missing struct field", "Missing struct field");
        fieldName = get().svalue;
        advance();
        auto structure = getStructure(type.mangledType);
        const auto nbFields = structure.fields.length;
        for(int i = 1; i <= structure.fields.length; i ++) {
            if(fieldName == structure.fields[nbFields - i]) {
                fieldType = structure.signature[nbFields - i];
                addGlobalPush(fieldType, 1u);
            }
            else
                decreaseStack(structure.signature[nbFields - i], 1);
        }
        addGlobalPop(fieldType);
        return fieldType;
    }

    VarType parseConversionOperator(VarType[] typeStack) {
        if(!typeStack.length)
            logError("Conversion Error", "You can only convert a value");
        advance();
        auto asType = parseType();
        checkAdvance();
        convertType(typeStack[$ - 1], asType, false, true);
        typeStack[$ - 1] = asType;
        return asType;
    }

	void parseExpression(VarType currentType = BaseType.VoidType) {
		Variable[] lvalues;
		LexemeType[] operatorsStack;
		VarType[] typeStack;
        VarType lastType = currentType;
		bool isReturningValue = false,
			hasValue = false, hadValue = false,
            hasLValue = false, hadLValue = false,
            hasReference = false, hadReference = false,
			isRightUnaryOperator = true, isEndOfExpression = false;

		if(lastType != VarType(BaseType.VoidType))
			isReturningValue = true;

		do {
			if(hasValue && currentType != lastType && lastType != VarType(BaseType.VoidType)) {
                lastType = currentType;//convertType(currentType, lastType);
				currentType = lastType;
			}
            else
                lastType = currentType;

			isRightUnaryOperator = false;
			hadValue = hasValue;
			hasValue = false;

			hadLValue = hasLValue;
			hasLValue = false;

            hadReference = hasReference;
            hasReference = false;

			Lexeme lex = get();
			switch(lex.type) with(LexemeType) {
			case Comma:
			case Semicolon:
			case RightParenthesis:
				isEndOfExpression = true;
				break;
			case LeftParenthesis:
                advance();
				currentType = parseSubExpression();
                advance();
				hasValue = true;
				break;
            case LeftBracket:
                //Index
                if(hadValue) {
                    hadValue = false;
                    currentType = VarType(BaseType.AnyType);
                    lastType = VarType(BaseType.AnyType);
                    parseArrayIndex(hadReference);
                    hasLValue = true;
                    lvalues ~= null;
                }
                //Build new array
                else {
                    currentType = VarType(BaseType.ArrayType);
                    parseArrayBuilder();
                }
                hasValue = true;
                break;
            case Period:
                currentType = parseStructureField(currentType);
                lastType = currentType;
                hadValue = false;
                hasValue = true;
                //Type stack
                break;
			case Integer:
				currentType = VarType(BaseType.IntType);
				addIntConstant(lex.ivalue);
				hasValue = true;
                typeStack ~= currentType;
				checkAdvance();
				break;
			case Float:
				currentType = VarType(BaseType.FloatType);
				addFloatConstant(lex.fvalue);
				hasValue = true;
                typeStack ~= currentType;
				checkAdvance();
				break;
			case Boolean:
				currentType = VarType(BaseType.BoolType);
				addBoolConstant(lex.bvalue);
				hasValue = true;
                typeStack ~= currentType;
				checkAdvance();
				break;
			case String:
				currentType = VarType(BaseType.StringType);
				addStringConstant(lex.svalue);
				hasValue = true;
                typeStack ~= currentType;
				checkAdvance();
				break;
            case Pointer:
                currentType = parseFunctionPointer(currentType);
                hasValue = true;
                typeStack ~= currentType;
                break;
            case As:
                if(!hadValue)
                    logError("","");
                currentType = parseConversionOperator(typeStack);
                hasValue = true;
                hadValue = false;
                break;
			case FunctionType:
				currentType = parseAnonymousFunction(false);
				hasValue = true;
                typeStack ~= currentType;
				break;
			case TaskType:
				currentType = parseAnonymousFunction(true);
				hasValue = true;
                typeStack ~= currentType;
				break;
			case Assign: .. case PowerAssign:
				if(!hadLValue)
					logError("Expression invalid", "Missing lvalue in expression");
				hadLValue = false;
				goto case Multiply;
			case Add:
				if(!hadValue)
					lex.type = LexemeType.Plus;
				goto case Multiply;
			case Substract:
				if(!hadValue)
					lex.type = LexemeType.Minus;
				goto case Multiply;
			case Increment: .. case Decrement:
				isRightUnaryOperator = true;
				goto case Multiply;
			case Multiply: .. case Xor:
				if(!hadValue && lex.type != LexemeType.Plus && lex.type != LexemeType.Minus && lex.type != LexemeType.Not)
					logError("Expected value", "A value is missing");

				while(operatorsStack.length && getLeftOperatorPriority(operatorsStack[$ - 1]) > getRightOperatorPriority(lex.type)) {
					LexemeType operator = operatorsStack[$ - 1];
                    writeln("1: ", typeStack);
					switch(operator) with(LexemeType) {
					case Assign:
						addSetInstruction(lvalues[$ - 1], currentType, true);
						lvalues.length --;
						break;
					case AddAssign: .. case PowerAssign:
						currentType = addOperator(operator - (LexemeType.AddAssign - LexemeType.Add), typeStack);
						addSetInstruction(lvalues[$ - 1], currentType, true);
						lvalues.length --;
						break;
					case Increment: .. case Decrement:
						currentType = addOperator(operator, typeStack);
						addSetInstruction(lvalues[$ - 1], currentType, true);
						lvalues.length --;
						break;
					default:
						currentType = addOperator(operator, typeStack);
						break;
					}
					
					operatorsStack.length --;
				}

				operatorsStack ~= lex.type;
				if(hadValue && isRightUnaryOperator) {
					hasValue = true;
					hadValue = false;
				}
				else
					hasValue = false;
				checkAdvance();
				break;
			case Identifier:
				Variable lvalue;
				currentType = parseIdentifier(lvalue, lastType);
				
                //Check if there is an assignement or not, discard if it's only a rvalue
                const auto nextLexeme = get();
				if(lvalue !is null && requireLValue(nextLexeme.type)) {
					hasLValue = true;
					lvalues ~= lvalue;

                    if(lvalue.isAuto)
                        hasValue = true;
				}

                if(!hasLValue && nextLexeme.type == LexemeType.LeftBracket)
                    hasReference = true;

				if(currentType != VarType(BaseType.VoidType)) {
					hasValue = true;
                    typeStack ~= currentType;
                }
				break;
			default:
				logError("Unexpected symbol", "Invalid \'" ~ to!string(lex.type) ~ "\' symbol in the expression");
			}

			if(hasValue && hadValue)
				logError("Missing symbol", "The expression is not terminated by a \';\'");
		}
		while(!isEndOfExpression);

		if(operatorsStack.length) {
			if(!hadValue) {
				if(!isRightUnaryOperator)
					logError("Expected value", "A value is missing");
				else
					logError("Expected value", "A value is missing");
			}
		}

		while(operatorsStack.length) {
                    writeln("2: ", typeStack);
			LexemeType operator = operatorsStack[$ - 1];

			switch(operator) with(LexemeType) {
			case Assign:
                if(operatorsStack.length == 1 && !isReturningValue) {
				    addSetInstruction(lvalues[$ - 1], currentType, false);
                    currentType = VarType(BaseType.VoidType);
                }
                else {
				    addSetInstruction(lvalues[$ - 1], currentType, true);
                }
				lvalues.length --;
				break;
			case AddAssign: .. case PowerAssign:
				currentType = addOperator(operator - (LexemeType.AddAssign - LexemeType.Add), typeStack);
				if(operatorsStack.length == 1 && !isReturningValue) {
				    addSetInstruction(lvalues[$ - 1], currentType, false);
                    currentType = VarType(BaseType.VoidType);
                }
                else {
				    addSetInstruction(lvalues[$ - 1], currentType, true);
                }			
				lvalues.length --;
				break;
			case Increment: .. case Decrement:
				currentType = addOperator(operator, typeStack);
				if(operatorsStack.length == 1 && !isReturningValue) {
				    addSetInstruction(lvalues[$ - 1], currentType, false);
                    currentType = VarType(BaseType.VoidType);
                }
                else {
				    addSetInstruction(lvalues[$ - 1], currentType, true);
                }	
				lvalues.length --;
				break;
			default:
				currentType = addOperator(operator, typeStack);
				break;
			}
			operatorsStack.length --;
		}

		if(currentType != VarType(BaseType.VoidType) && !isReturningValue)
			decreaseStack(currentType, 1u);
	}

    void decreaseStack(VarType type, ushort count) {
        switch(type.baseType) with(BaseType) {
        case IntType:
        case BoolType:
        case FunctionType:
        case TaskType:
            addInstruction(Opcode.PopStack_Int, count);
            break;
        case FloatType:
            addInstruction(Opcode.PopStack_Float, count);
            break;
        case StringType:
            addInstruction(Opcode.PopStack_String, count);
            break;
        case ArrayType:
            addInstruction(Opcode.PopStack_Array, count);
            break;
        case AnyType:
            addInstruction(Opcode.PopStack_Any, count);
            break;
        case ObjectType:
            addInstruction(Opcode.PopStack_Object, count);
            break;
        default:
            break;
        }
    }

    bool requireLValue(LexemeType operatorType) {
        switch(operatorType) with(LexemeType) {
        case Increment:
        case Decrement:
        case Assign: .. case PowerAssign:
            return true;
        default:
            return false;
        }
    }

    VarType parseFunctionPointer(VarType currentType) {
        checkAdvance();
        if(get().type == LexemeType.LeftParenthesis) {
            checkAdvance();
            VarType refType = parseType();
            checkAdvance();
            if(get().type != LexemeType.RightParenthesis)
                logError("Missing symbol", "Expected a \')\' after the type");
            checkAdvance();
            if(currentType.baseType == BaseType.VoidType)
                currentType = refType;
            else
                currentType = convertType(refType, currentType);
        }
        if(get().type != LexemeType.Identifier)
            logError("Function name expected", "The name of the func or task is required after \'&\'");
        if(currentType.baseType != BaseType.FunctionType && currentType.baseType != BaseType.TaskType)
            logError("Function ref error", "Cannot infer the type of \'" ~ to!string(get().svalue) ~ "\'");

        VarType funcType = addFunctionAddress(get().svalue ~ currentType.mangledType);
        convertType(funcType, currentType);
        checkAdvance();
        return currentType;
    }

	VarType parseSubExpression(bool useParenthesis = true) {
		Variable[] lvalues;
		LexemeType[] operatorsStack;
		VarType[] typeStack;
		VarType currentType = VarType(BaseType.VoidType), lastType = VarType(BaseType.VoidType);
		bool hasValue = false, hadValue = false,
        hasLValue = false, hadLValue = false,
        hasReference = false, hadReference = false,
		isRightUnaryOperator = true, isEndOfExpression = false;

		do {
			if(hasValue && currentType != lastType && lastType != VarType(BaseType.VoidType)) {
				lastType = currentType;//convertType(currentType, lastType);
				currentType = lastType;
			}
            else
                lastType = currentType;

			isRightUnaryOperator = false;
			hadValue = hasValue;
			hasValue = false;

			hadLValue = hasLValue;
			hasLValue = false;

            hadReference = hasReference;
            hasReference = false;

			Lexeme lex = get();
			switch(lex.type) with(LexemeType) {
			case Semicolon:
				if(useParenthesis)
					logError("Unexpected symbol", "A \';\' cannot exist inside this expression");
				else
					isEndOfExpression = true;
				break;
			case Comma:
				if(useParenthesis)
					isEndOfExpression = true;
				else
					logError("Unexpected symbol", "A \',\' cannot exist inside this expression");
				break;
			case RightParenthesis:
				if(useParenthesis)
					isEndOfExpression = true;
				else
					logError("Unexpected symbol", "A \')\' cannot exist inside this expression");
				break;
            case RightBracket:
				if(useParenthesis)
					isEndOfExpression = true;
				else
					logError("Unexpected symbol", "A \']\' cannot exist inside this expression");
				break;
			case LeftParenthesis:
                advance();
				currentType = parseSubExpression();
                advance();
				hasValue = true;
				break;
            case LeftBracket:
                //Index
                if(hadValue) {
                    hadValue = false;
                    currentType = VarType(BaseType.AnyType);
                    lastType = VarType(BaseType.AnyType);
                    parseArrayIndex(hadReference);
                    hasLValue = true;
                    lvalues ~= null;
                }
                //Build new array
                else {
                    currentType = VarType(BaseType.ArrayType);
                    parseArrayBuilder();
                }
                hasValue = true;
                break;
            case Period:
                currentType = parseStructureField(currentType);
                lastType = currentType;
                hadValue = false;
                hasValue = true;
                break;
			case Integer:
				currentType = VarType(BaseType.IntType);
				addIntConstant(lex.ivalue);
				hasValue = true;
                typeStack ~= currentType;
				checkAdvance();
				break;
			case Float:
				currentType = VarType(BaseType.FloatType);
				addFloatConstant(lex.fvalue);
				hasValue = true;
                typeStack ~= currentType;
				checkAdvance();
				break;
			case Boolean:
				currentType = VarType(BaseType.BoolType);
				addBoolConstant(lex.bvalue);
				hasValue = true;
                typeStack ~= currentType;
				checkAdvance();
				break;
			case String:
				currentType = VarType(BaseType.StringType);
				addStringConstant(lex.svalue);
				hasValue = true;
                typeStack ~= currentType;
				checkAdvance();
				break;
            case Pointer:
                currentType = parseFunctionPointer(currentType);
                typeStack ~= currentType;
                hasValue = true;
                break;
            case As:
                if(!hadValue)
                    logError("","");
                currentType = parseConversionOperator(typeStack);
                hasValue = true;
                hadValue = false;
                break;
			case FunctionType:
				currentType = parseAnonymousFunction(false);
                typeStack ~= currentType;
				hasValue = true;
				break;
			case TaskType:
				currentType = parseAnonymousFunction(true);
                typeStack ~= currentType;
				hasValue = true;
				break;
			case Assign: .. case PowerAssign:
				if(!hadLValue)
					logError("Expression invalid", "Missing lvalue in expression");
				hadLValue = false;
				goto case Multiply;
			case Add:
				if(!hadValue)
					lex.type = LexemeType.Plus;
				goto case Multiply;
			case Substract:
				if(!hadValue)
					lex.type = LexemeType.Minus;
				goto case Multiply;
			case Increment: .. case Decrement:
				isRightUnaryOperator = true;
				goto case Multiply;
			case Multiply: .. case Xor:
				if(!hadValue && lex.type != LexemeType.Plus && lex.type != LexemeType.Minus && lex.type != LexemeType.Not)
					logError("Expected value", "A value is missing");

				while(operatorsStack.length && getLeftOperatorPriority(operatorsStack[$ - 1]) > getRightOperatorPriority(lex.type)) {
					LexemeType operator = operatorsStack[$ - 1];
	
					switch(operator) with(LexemeType) {
					case Assign:
						addSetInstruction(lvalues[$ - 1], currentType, true);
						lvalues.length --;
						break;
					case AddAssign: .. case PowerAssign:
						currentType = addOperator(operator - (LexemeType.AddAssign - LexemeType.Add), typeStack);
						addSetInstruction(lvalues[$ - 1], currentType, true);
						lvalues.length --;
						break;
					case Increment: .. case Decrement:
						currentType = addOperator(operator, typeStack);
						addSetInstruction(lvalues[$ - 1], currentType, true);
						lvalues.length --;
						break;
					default:
						currentType = addOperator(operator, typeStack);
						break;
					}

					operatorsStack.length --;
				}

				operatorsStack ~= lex.type;
				if(hadValue && isRightUnaryOperator) {
					hasValue = true;
					hadValue = false;
				}
				else
					hasValue = false;
				checkAdvance();
				break;
			case Identifier:
				Variable lvalue;
				currentType = parseIdentifier(lvalue, lastType);

                //Check if there is an assignement or not, discard if it's only a rvalue
                const auto nextLexeme = get();
				if(lvalue !is null && requireLValue(nextLexeme.type)) {
					hasLValue = true;
					lvalues ~= lvalue;

                    if(lvalue.isAuto)
                        hasValue = true;
				}

                if(!hasLValue && nextLexeme.type == LexemeType.LeftBracket)
                    hasReference = true;

				if(currentType != VarType(BaseType.VoidType)) {
					hasValue = true;
                    typeStack ~= currentType;
                }
				break;
			default:
				logError("Unexpected symbol", "Invalid \'" ~ to!string(lex.type) ~ "\' symbol in the expression");
			}

			if(hasValue && hadValue)
				logError("Missing symbol", "The expression is not terminated by a \';\'");
		}
		while(!isEndOfExpression);

		if(operatorsStack.length) {
			if(!hadValue) {
				if(!isRightUnaryOperator)
					logError("Expected value", "A value is missing");
				else
					logError("Expected value", "A value is missing");
			}
		}

		while(operatorsStack.length) {
			LexemeType operator = operatorsStack[$ - 1];
	
			switch(operator) with(LexemeType) {
			case Assign:
				addSetInstruction(lvalues[$ - 1], currentType, true);
				lvalues.length --;
				break;
			case AddAssign: .. case PowerAssign:
				currentType = addOperator(operator - (LexemeType.AddAssign - LexemeType.Add), typeStack);
				addSetInstruction(lvalues[$ - 1], currentType, true);			
				lvalues.length --;
				break;
			case Increment: .. case Decrement:
				currentType = addOperator(operator, typeStack);
				addSetInstruction(lvalues[$ - 1], currentType, true);
				lvalues.length --;
				break;
			default:
				currentType = addOperator(operator, typeStack);
				break;
			}

			operatorsStack.length --;
		}
        
        return currentType;
	}

	//Parse an identifier or function call and return the deduced return type and lvalue.
	VarType parseIdentifier(ref Variable variable, VarType expectedType = BaseType.VoidType) {
		VarType returnType = BaseType.VoidType;
		Lexeme identifier = get();		
		bool isFunctionCall = false;
        dstring identifierName = identifier.svalue;

		advance();

        if(get().type == LexemeType.Period) {
			auto structVar = getVariable(identifier.svalue);
            if(structVar is null || structVar.type.baseType != BaseType.StructType)
                logError("Invalid symbol", "You can only access a field from a struct");
            else {
                do {
                    checkAdvance();
                    if(get().type != LexemeType.Identifier)
                        logError("Missing identifier", "A struct field must have a name");
                    identifierName ~= "." ~ get().svalue;
                    checkAdvance();
                }
                while(get().type == LexemeType.Period);
            }
        }

		if(get().type == LexemeType.LeftParenthesis)
			isFunctionCall = true;

		if(isFunctionCall) {
			VarType[] signature;
			advance();

			auto var = (identifierName in currentFunction.localVariables);
			if(var !is null) {
                //Signature parsing with type conversion
                VarType[] anonSignature = unmangleSignature(var.type.mangledType);
                int i;
                if(get().type != LexemeType.RightParenthesis) {
                    for(;;) {
                        if(i >= anonSignature.length)
                            logError("Invalid anonymous call", "The number of parameters does not match");
                        VarType subType = parseSubExpression();
                        signature ~= convertType(subType, anonSignature[i]);
                        if(get().type == LexemeType.RightParenthesis)
                            break;
                        advance();
                        i ++;
                    }
                }
                checkAdvance();

				//Anonymous call.
				bool hasAnonFunc = false;
				addGetInstruction(*var);
                
				returnType = unmangleType(var.type.mangledReturnType);

				if(var.type.baseType == BaseType.FunctionType)
					addInstruction(Opcode.AnonymousCall, 0u);
				else if(var.type.baseType == BaseType.TaskType)
					addInstruction(Opcode.AnonymousTask, 0u);
				else
					logError("Invalid anonymous type", "debug");

				/*foreach(anonFunc; anonymousFunctions) {
					if(anonFunc.name == currentFunction.name) {

						hasAnonFunc = true;
						break;
					}
				}*/
			}
			else {
                //Signature parsing, no coercion is made
                if(get().type != LexemeType.RightParenthesis) {
                    for(;;) {
                        signature ~= parseSubExpression();
                        if(get().type == LexemeType.RightParenthesis)
                            break;
                        advance();
                    }
                }
                checkAdvance();

                //Mangling function name
				dstring mangledName = mangleName(identifierName, signature);
				
				//Primitive call.
				if(isPrimitiveDeclared(mangledName)) {
					Primitive primitive = getPrimitive(mangledName);
					addInstruction(Opcode.PrimitiveCall, primitive.index);
					returnType = primitive.returnType;
				}
				else //Function/Task call.
					returnType = addFunctionCall(mangledName);
			}
		}
		else {
			//Declared variable.
			variable = getVariable(identifierName);
			returnType = variable.type;
            //If it's an assignement, we want the GET instruction to be after the assignement, not there.
            const auto nextLexeme = get();
            if(nextLexeme.type == LexemeType.LeftBracket) {
                addInstruction(Opcode.LocalLoad_Ref);
                returnType = VarType(BaseType.AnyType);
            }
            else if(nextLexeme.type != LexemeType.Assign)
                addGetInstruction(variable, expectedType);
		}
		return returnType;
	}

	//Error handling
	struct Error {
		dstring msg, info;
		Lexeme lex;
		bool mustHalt;
	}

	Error[] errors;

	void logWarning(string msg, string info = "") {
		Error error;
		error.msg = to!dstring(msg);
		error.info = to!dstring(info);
		error.lex = get();
		error.mustHalt = false;
		errors ~= error;
	}

	void logError(string msg, string info = "") {
		Error error;
		error.msg = to!dstring(msg);
		error.info = to!dstring(info);
		error.mustHalt = true;
		if(isEnd()) {
			error.lex = get(-1);
		}
		else
			error.lex = get();

		errors ~= error;
		raiseError();
	}

	void raiseError() {
		foreach(error; errors) {
			dstring report;

			//Separator
			if(error.mustHalt)
				report ~= "\n\033[0;36m--\033[0;91m Error \033[0;36m-------------------- " ~ error.lex.lexer.file ~ "\033[0m\n";
			else
				report ~= "\n\033[0;36m--\033[0;93m Warning \033[0;36m-------------------- " ~ error.lex.lexer.file ~ "\033[0m\n";

			//Error report
			report ~= error.msg ~ ":\033[1;34m\n";

			//Script snippet
			dstring lineNumber = to!dstring(error.lex.line + 1u) ~ "| ";
			report ~= lineNumber;
			report ~= error.lex.getLine().replace("\t", " ") ~ "\n";

			//Red underline
			foreach(x; 1 .. lineNumber.length + error.lex.column)
				report ~= " ";

			if(error.mustHalt)
				report ~= "\033[1;31m"; //Red color
			else
				report ~= "\033[1;93m"; //Red color

			foreach(x; 0 .. error.lex.textLength)
				report ~= "^";
			report ~= "\033[0m\n"; //White color

			//Error description
			if(error.info.length)
				report ~= error.info ~ ".\n";
			writeln(report);
		}
		throw new Exception("\033[0mCompilation aborted...");
	}
}