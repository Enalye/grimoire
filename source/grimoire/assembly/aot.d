/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.assembly.aot;

import std.conv : to;

import grimoire.assembly.bytecode;
import grimoire.assembly.symbol;

final class AOTCompiler {
    class Function {
        size_t address;
        string name;
        size_t id;
        Token[] tokens;
    }

    struct Token {
        GrOpcode opcode;

        union {
            bool bvalue;
            uint uvalue;
            int ivalue;
            float fvalue;
            double dvalue;
            string svalue;
        }
    }

    private {
        GrBytecode _bytecode;
        Function[] _functions;
    }

    /**
    Nécessite que le bytecode soit compilé avec les symboles.
    */
    this(GrBytecode bytecode_) {
        _bytecode = bytecode_;

        int id;
        foreach (symbol; _bytecode.symbols) {
            switch (symbol.type) with (GrSymbol.Type) {
            case func:
                GrFunctionSymbol funcSymbol = cast(GrFunctionSymbol) symbol;
                Function func = new Function;
                func.id = id;
                func.address = funcSymbol.start;
                func.name = funcSymbol.name;

                foreach (opcode; _bytecode.opcodes[funcSymbol.start ..
                        funcSymbol.start + funcSymbol.length]) {
                    func.tokens ~= tokenize(_bytecode, cast(int) func.address, opcode);
                }

                _functions ~= func;
                id++;
                break;
            default:
                break;
            }
        }
    }

    string compile() {
        string txt;
        foreach (Function func; _functions) {
            txt ~= "/// " ~ func.name ~ "\n";
            txt ~= "void _aot_" ~ to!string(func.id) ~ "() {\n";

            size_t i;
            while (i < func.tokens.length) {
                txt ~= _translate(func.tokens[i]);
                /*if (func.tokens[i].isValue) {

                }*/
                i ++;
            }

            txt ~= "}\n";
        }
        return txt;
    }

    private string _translate(Token token) {
        string txt;

        final switch (token.opcode) with (GrOpcode) {
        case nop:
            break;
        case throw_:
            txt = "throw new Exception(\"ERR (TEMP AOT)\");\n";
            break;
        case try_:
            txt = "try {\n";
            break;
        case catch_:
            txt = "} catch(Exception e) {}\n";
            break;
        case die:
            break;
        case exit:
            break;
        case yield:
            txt = "yield();";
            break;
        case task:
            break;
        case anonymousTask:
            break;
        case new_:
            break;
        case channel:
            break;
        case send:
            break;
        case receive:
            break;
        case startSelectChannel:
            break;
        case endSelectChannel:
            break;
        case tryChannel:
            break;
        case checkChannel:
            break;
        case shiftStack:
            break;
        case localStore:
            break;
        case localStore2:
            break;
        case localLoad:
            break;
        case globalStore:
            break;
        case globalStore2:
            break;
        case globalLoad:
            break;
        case refStore:
            break;
        case refStore2:
            break;
        case fieldRefStore:
            break;
        case fieldRefLoad:
            break;
        case fieldRefLoad2:
            break;
        case fieldLoad:
            break;
        case fieldLoad2:
            break;
        case parentStore:
            break;
        case parentLoad:
            break;
        case const_int:
            break;
        case const_uint:
            break;
        case const_byte:
            break;
        case const_float:
            break;
        case const_double:
            break;
        case const_bool:
            break;
        case const_string:
            break;
        case const_null:
            break;
        case globalPush:
            break;
        case globalPop:
            break;
        case equal_int:
            break;
        case equal_uint:
            break;
        case equal_byte:
            break;
        case equal_float:
            break;
        case equal_double:
            break;
        case equal_string:
            break;
        case notEqual_int:
            break;
        case notEqual_uint:
            break;
        case notEqual_byte:
            break;
        case notEqual_float:
            break;
        case notEqual_double:
            break;
        case notEqual_string:
            break;
        case greaterOrEqual_int:
            break;
        case greaterOrEqual_uint:
            break;
        case greaterOrEqual_byte:
            break;
        case greaterOrEqual_float:
            break;
        case greaterOrEqual_double:
            break;
        case lesserOrEqual_int:
            break;
        case lesserOrEqual_uint:
            break;
        case lesserOrEqual_byte:
            break;
        case lesserOrEqual_float:
            break;
        case lesserOrEqual_double:
            break;
        case greater_int:
            break;
        case greater_uint:
            break;
        case greater_byte:
            break;
        case greater_float:
            break;
        case greater_double:
            break;
        case lesser_int:
            break;
        case lesser_uint:
            break;
        case lesser_byte:
            break;
        case lesser_float:
            break;
        case lesser_double:
            break;
        case checkNull:
            break;
        case optionalTry:
            break;
        case optionalOr:
            break;
        case optionalCall:
            break;
        case optionalCall2:
            break;
        case and_int:
            break;
        case or_int:
            break;
        case not_int:
            break;
        case concatenate_string:
            break;
        case add_int:
            break;
        case add_uint:
            break;
        case add_byte:
            break;
        case add_float:
            break;
        case add_double:
            break;
        case substract_int:
            break;
        case substract_uint:
            break;
        case substract_byte:
            break;
        case substract_float:
            break;
        case substract_double:
            break;
        case multiply_int:
            break;
        case multiply_uint:
            break;
        case multiply_byte:
            break;
        case multiply_float:
            break;
        case multiply_double:
            break;
        case divide_int:
            break;
        case divide_uint:
            break;
        case divide_byte:
            break;
        case divide_float:
            break;
        case divide_double:
            break;
        case remainder_int:
            break;
        case remainder_uint:
            break;
        case remainder_byte:
            break;
        case remainder_float:
            break;
        case remainder_double:
            break;
        case negative_int:
            break;
        case negative_float:
            break;
        case negative_double:
            break;
        case increment_int:
            break;
        case increment_uint:
            break;
        case increment_byte:
            break;
        case increment_float:
            break;
        case increment_double:
            break;
        case decrement_int:
            break;
        case decrement_uint:
            break;
        case decrement_byte:
            break;
        case decrement_float:
            break;
        case decrement_double:
            break;
        case copy:
            break;
        case swap:
            break;
        case setupIterator:
            break;
        case localStack:
            break;
        case call:
            txt = "_aot_" ~ to!string(_getFunction(token.uvalue).id) ~ "();";
            break;
        case address:
            break;
        case closure:
            break;
        case extend:
            break;
        case anonymousCall:
            break;
        case primitiveCall:
            break;
        case safePrimitiveCall:
            break;
        case return_:
            break;
        case unwind:
            break;
        case defer:
            break;
        case jump:
            break;
        case jumpEqual:
            break;
        case jumpNotEqual:
            break;
        case list:
            break;
        case length_list:
            break;
        case index_list:
            break;
        case index2_list:
            break;
        case index3_list:
            break;
        case concatenate_list:
            break;
        case append_list:
            break;
        case prepend_list:
            break;
        case equal_list:
            break;
        case notEqual_list:
            break;
        case debugProfileBegin:
            break;
        case debugProfileEnd:
            break;
        }

        return txt;
    }

    private Token tokenize(GrBytecode _bytecode, int pos, uint instruction) {
        Token token;

        token.opcode = cast(GrOpcode)(instruction & 0xFF);

        switch (token.opcode) with (GrOpcode) {
        case task:
        case localStore: .. case localLoad:
        case globalStore: .. case globalLoad:
        case globalPush:
        case localStack: .. case call:
        case new_:
        case fieldRefLoad: .. case fieldLoad2:
        case channel:
        case list:
        case swap:
            token.uvalue = grGetInstructionUnsignedValue(instruction);
            break;
        case fieldRefStore:
            token.ivalue = grGetInstructionSignedValue(instruction);
            break;
        case shiftStack:
            token.ivalue = grGetInstructionSignedValue(instruction);
            break;
        case anonymousCall:
            token.uvalue = grGetInstructionUnsignedValue(instruction);
            break;
        case primitiveCall:
        case safePrimitiveCall: {
                const uint index = grGetInstructionUnsignedValue(instruction);
                /*if (index < primitives.length) {
                const GrBytecode.PrimitiveReference primitive = primitives[index];

                GrType[] inSignature, outSignature;
                foreach (type; primitive.inSignature) {
                    inSignature ~= grUnmangle(type);
                }
                foreach (type; primitive.outSignature) {
                    outSignature ~= grUnmangle(type);
                }

                //line ~= grGetPrettyFunction(primitive.name, inSignature, outSignature);
            }
            else {
                //line ~= to!string(index);
            }*/
            }
            break;
        case address:
        case closure:
            token.uvalue = _bytecode.uintConsts[grGetInstructionUnsignedValue(instruction)];
            break;
        case const_int:
            token.ivalue = _bytecode.intConsts[grGetInstructionUnsignedValue(instruction)];
            break;
        case const_uint:
            token.uvalue = _bytecode.uintConsts[grGetInstructionUnsignedValue(instruction)];
            break;
        case const_byte:
            token.uvalue = _bytecode.byteConsts[grGetInstructionUnsignedValue(instruction)];
            break;
        case const_float:
            token.fvalue = _bytecode.floatConsts[grGetInstructionUnsignedValue(instruction)];
            break;
        case const_bool:
            token.bvalue = grGetInstructionUnsignedValue(instruction) > 0;
            break;
        case const_string:
        case debugProfileBegin:
            token.svalue = _bytecode.strConsts[grGetInstructionUnsignedValue(instruction)];
            break;
        case jump: .. case jumpNotEqual:
            token.uvalue = pos + grGetInstructionSignedValue(instruction);
            break;
        case defer:
        case try_:
        case catch_:
        case tryChannel:
        case optionalCall:
        case optionalCall2:
            token.uvalue = pos + grGetInstructionSignedValue(instruction);
            break;
        default:
            break;
        }

        return token;
    }

    Function _getFunction(uint pos) {
        foreach (Function func; _functions) {
            if(func.address == pos) {
                return func;
            }
        }

        assert(false);
    }
}
