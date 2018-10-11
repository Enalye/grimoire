/**
    Runtime dynamic value.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.runtime.dynamic;

import std.conv: to;

/**
    Lazy evaluation variable that can hold many types.
*/
struct GrDynamicValue {
    private union {
        int ivalue;
        float fvalue;
        dstring svalue;
        GrDynamicValue[] nvalue;
        GrDynamicValue* refindex;
        GrDynamicValue[]* refvalue;
    }

    /// Dynamic type.
    enum Type {
        UndefinedType, BoolType, IntType, FloatType, StringType, ArrayType, RefArrayType, RefIndexType
    }

    /// Dynamic type.
    Type type;

    /// Sets the value to the boolean value.
    void setBool(int value) {
        type = Type.BoolType;
        ivalue = value;
    }

    /// Sets the value to integer.
    void setInt(int value) {
        type = Type.IntType;
        ivalue = value;
    }

    /// Sets the value to float.
    void setFloat(float value) {
        type = Type.FloatType;
        fvalue = value;
    }

    /// Sets the value to string.
    void setString(dstring value) {
        type = Type.StringType;
        svalue = value;
    }

    /// Sets the value to array.
    void setArray(GrDynamicValue[] value) {
        type = Type.ArrayType;
        nvalue = value;
    }

    /// Reference to an array.
    void setRefArray(GrDynamicValue[]* value) {
        type = Type.RefArrayType;
        refvalue = value;
    }

    /// The value is set to the value stored at the index of the current array.
    /// The value must be a valid indexable value.
    void setArrayIndex(int index) {
        switch(type) with(Type) {
        case ArrayType:
            if(index >= nvalue.length)
                throw new Exception("No error fallback implemented: array overflow");
            this = nvalue[index];
            return;
        case RefArrayType:
            if(index >= refvalue.length)
                throw new Exception("No error fallback implemented: array overflow");
            refindex = &((*refvalue)[index]);
            type = Type.RefIndexType;
            return;
        case RefIndexType:
            refindex = &(refindex.nvalue[index]);
            return;
        default:
            throw new Exception("No error fallback implemented");
        }
    }

    /// The value is now a reference for another value.
    void setRef(GrDynamicValue value) {
        if(type != Type.RefIndexType)
            throw new Exception("No error fallback implemented");
        *refindex = value;
    }

    /// Converts and returns a boolean value.
    int getBool() const {
        final switch(type) with(Type) {
        case UndefinedType:
            throw new Exception("No error fallback implemented");
        case BoolType:
        case IntType:
            return ivalue;
        case FloatType:
            return to!int(fvalue);
        case StringType:
            return svalue == "true";
        case ArrayType:
            throw new Exception("No error fallback implemented");            
        case RefArrayType:
            throw new Exception("No error fallback implemented");            
        case RefIndexType:
            return refindex.getBool();
        }
    }

    /// Converts and returns an integer value.
    int getInt() const {
        final switch(type) with(Type) {
        case UndefinedType:
            throw new Exception("No error fallback implemented");
        case BoolType:
        case IntType:
            return ivalue;
        case FloatType:
            return to!int(fvalue);
        case StringType:
            return to!int(svalue);
        case ArrayType:
            throw new Exception("No error fallback implemented");            
        case RefArrayType:
            throw new Exception("No error fallback implemented");            
        case RefIndexType:
            return refindex.getBool();
        }
    }

    /// Converts and returns a float value.
    float getFloat() const {
        final switch(type) with(Type) {
        case UndefinedType:
            throw new Exception("No error fallback implemented");
        case BoolType:
        case IntType:
            return to!float(ivalue);
        case FloatType:
            return fvalue;
        case StringType:
            return to!float(svalue);
        case ArrayType:
            throw new Exception("No error fallback implemented");            
        case RefArrayType:
            throw new Exception("No error fallback implemented");            
        case RefIndexType:
            return refindex.getFloat();
        }
    }

    /// Converts and returns a string value.
    dstring getString() const {
        final switch(type) with(Type) {
        case UndefinedType:
            throw new Exception("No error fallback implemented");
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
        case RefIndexType:
            return refindex.getString();
        }
    }

    /// Converts and returns an array value.
    GrDynamicValue[] getArray() {
        final switch(type) with(Type) {
        case UndefinedType:
            throw new Exception("No error fallback implemented");
        case BoolType:
            throw new Exception("No error fallback implemented");            
        case IntType:
            throw new Exception("No error fallback implemented");            
        case FloatType:
            throw new Exception("No error fallback implemented");            
        case StringType:
            GrDynamicValue[] array;
            foreach(character; svalue) {
                GrDynamicValue nElement;
                nElement.setString(to!dstring(character));
                array ~= nElement;
            }
            return array;
        case ArrayType:
            return nvalue;
        case RefArrayType:
            return *refvalue;
        case RefIndexType:
            return refindex.getArray();
        }
    }
    
    /// Copy operator.
    GrDynamicValue opOpAssign(string op)(GrDynamicValue v) {
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

    /// Increment and Decrement.
    GrDynamicValue opUnaryRight(string op)() {	
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

    /// + and -.
    GrDynamicValue opUnary(string op)() {	
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