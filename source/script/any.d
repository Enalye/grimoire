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

module script.any;

import std.conv: to;

struct AnyValue {
    private union {
        int ivalue;
        float fvalue;
        dstring svalue;
        AnyValue[] nvalue;
        AnyValue* refindex;
        AnyValue[]* refvalue;
    }

    enum Type {
        UndefinedType, BoolType, IntType, FloatType, StringType, ArrayType, RefArrayType, RefIndex
    }

    Type type;

    void setBool(int value) {
        type = Type.BoolType;
        ivalue = value;
    }

    void setInteger(int value) {
        type = Type.IntType;
        ivalue = value;
    }

    void setFloat(float value) {
        type = Type.FloatType;
        fvalue = value;
    }

    void setString(dstring value) {
        type = Type.StringType;
        svalue = value;
    }

    void setArray(AnyValue[] value) {
        type = Type.ArrayType;
        nvalue = value;
    }

    void setRefArray(AnyValue[]* value) {
        type = Type.RefArrayType;
        refvalue = value;
    }

    void setArrayIndex(int index) {
        switch(type) with(Type) {
        case ArrayType:
            if(index >= nvalue.length)
                throw new Exception("setArrayIndex: Array overflow");
            this = nvalue[index];
            return;
        case RefArrayType:
            if(index >= refvalue.length)
                throw new Exception("setArrayIndex: Array overflow");
            refindex = &((*refvalue)[index]);
            type = Type.RefIndex;
            return;
        case RefIndex:
            refindex = &(refindex.nvalue[index]);
            return;
        default:
            throw new Exception("setRefArrayIndex: Any type error");
        }
    }

    void setRef(AnyValue value) {
        if(type != Type.RefIndex)
            throw new Exception("setRefArrayIndex: Any type error");
        *refindex = value;
    }

    int getBool() const {
        switch(type) with(Type) {
        case BoolType:
        case IntType:
            return ivalue;
        case FloatType:
            return to!int(fvalue);
        case StringType:
            return svalue == "true";
        default:
            //error
            return 0;
        }
    }

    int getInteger() const {
        switch(type) with(Type) {
        case BoolType:
        case IntType:
            return ivalue;
        case FloatType:
            return to!int(fvalue);
        case StringType:
            return to!int(svalue);
        default:
            //error
            return 0;
        }
    }

    float getFloat() const {
        switch(type) with(Type) {
        case BoolType:
        case IntType:
            return to!float(ivalue);
        case FloatType:
            return fvalue;
        case StringType:
            return to!float(svalue);
        default:
            //error
            return 0;
        }
    }

    dstring getString() const {
        switch(type) with(Type) {
        case BoolType:
            return ivalue ? "true" : "false";
        case IntType:
            return to!dstring(ivalue);
        case FloatType:
            return to!dstring(fvalue);
        case StringType:
            return svalue;
        case ArrayType:
            dstring result = "[";
            int i;
            foreach(value; nvalue) {
                result ~= value.getString();
                if((i + 2) <= nvalue.length)
                    result ~= ", ";
                i ++;
            }
            result ~= "]";
            return result;
        case RefArrayType:
            dstring result = "[";
            int i;
            foreach(value; *refvalue) {
                result ~= value.getString();
                if((i + 2) <= nvalue.length)
                    result ~= ", ";
                i ++;
            }
            result ~= "]";
            return result;
        case RefIndex:
            return refindex.getString();
        default:
            return "";
        }
    }

    AnyValue[] getArray() {
        switch(type) with(Type) {
        case BoolType:
            return [];
        case IntType:
            return [];
        case FloatType:
            return [];
        case StringType:
            return [];
        case ArrayType:
            return nvalue;
        case RefArrayType:
            return *refvalue;
        case RefIndex:
            return refindex.getArray();
        default:
            return [];
        }
    }
    
    AnyValue opOpAssign(string op)(AnyValue v) {
        static if(op == "+" || op == "-" || op == "*" || op == "/" || op == "%") {
            switch(type) with(Type) {
            case BoolType:
                switch(v.type) with(Type) {
                case BoolType:
                    mixin("ivalue = ivalue " ~ op ~ " v.ivalue;");
                    break;
                default:
                    break;
                }
                break;
            case IntType:
                switch(v.type) with(Type) {
                case IntType:
                    mixin("ivalue = ivalue " ~ op ~ " v.ivalue;");
                    break;
                case FloatType:
                    type = Type.FloatType;
                    mixin("fvalue = to!float(ivalue) " ~ op ~ " v.fvalue;");
                    break;
                default:
                    break;
                }
                break;
            case FloatType:
                switch(v.type) with(Type) {
                case IntType:
                    mixin("fvalue = fvalue " ~ op ~ " to!float(v.ivalue);");
                    break;
                case FloatType:
                    mixin("fvalue = fvalue " ~ op ~ " v.fvalue;");
                    break;
                default:
                    break;
                }
                break;
            case StringType:
            default:
                //error
                break;
            }
        }
        else static if(op == "~") {
            switch(type) with(Type) {
            case BoolType:
            case IntType:
            case FloatType:
                //error
                break;
            case StringType:
                switch(v.type) with(Type) {
                case StringType:
                    mixin("svalue = svalue " ~ op ~ " v.svalue;");
                    break;
                default:
                    break;
                }
                break;
            default:
                //error
                break;
            }
        }
        return this;
    }

    AnyValue opUnaryRight(string op)() {	
        switch(type) with(Type) {
        case IntType:
            mixin("ivalue" ~ op ~ ";");
            break;
        case FloatType:
            mixin("fvalue" ~ op ~ ";");				
            break;
        case StringType:
        default:
            //error
            break;
        }
        return this;
    }

    AnyValue opUnary(string op)() {	
        switch(type) with(Type) {
        case IntType:
            mixin("ivalue = " ~ op ~ " ivalue;");
            break;
        case FloatType:
            mixin("fvalue = " ~ op ~ " fvalue;");				
            break;
        case StringType:
        default:
            //error
            break;
        }
        return this;
    }	
}