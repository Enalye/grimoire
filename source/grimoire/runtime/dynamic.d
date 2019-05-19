/**
    Runtime dynamic value.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.runtime.dynamic;

import std.conv: to;
import grimoire.compiler;
import grimoire.runtime.context, grimoire.runtime.engine;

/**
    Lazy evaluation variable that can hold many types.
*/
struct GrDynamicValue {
    private union {
        int _ivalue;
        float _rvalue;
        dstring _svalue;
        GrDynamicValue[] _nvalue;
        GrDynamicValue* _refindex;
        GrDynamicValue[]* _refvalue;
    }
    private dstring _subType;

    /// Dynamic type.
    enum GrDynamicValueType {
        UndefinedType,
        FunctionType, TaskType,
        BoolType, IntType, FloatType, StringType, ArrayType, RefArrayType, RefIndexType
    }

    /// Dynamic type.
    GrDynamicValueType type;

    /// Sets a function.
    void setFunction(int addr, dstring subType) {
        type = GrDynamicValueType.FunctionType;
        _ivalue = addr;
        _subType = subType;
    }

    /// Sets a task.
    void setTask(int addr, dstring subType) {
        type = GrDynamicValueType.TaskType;
        _ivalue = addr;
        _subType = subType;
    }

    /// Sets the value to the boolean value.
    void setBool(int value) {
        type = GrDynamicValueType.BoolType;
        _ivalue = value;
    }

    /// Sets the value to integer.
    void setInt(int value) {
        type = GrDynamicValueType.IntType;
        _ivalue = value;
    }

    /// Sets the value to float.
    void setFloat(float value) {
        type = GrDynamicValueType.FloatType;
        _rvalue = value;
    }

    /// Sets the value to string.
    void setString(dstring value) {
        type = GrDynamicValueType.StringType;
        _svalue = value;
    }

    /// Sets the value to array.
    void setArray(GrDynamicValue[] value) {
        type = GrDynamicValueType.ArrayType;
        _nvalue = value;
    }

    /// Reference to an array.
    void setRefArray(GrDynamicValue[]* value) {
        type = GrDynamicValueType.RefArrayType;
        _refvalue = value;
    }

    /// The value is set to the value stored at the index of the current array.
    /// The value must be a valid indexable value.
    void setArrayIndex(int index) {
        switch(type) with(GrDynamicValueType) {
        case ArrayType:
            if(index >= _nvalue.length)
                throw new Exception("No error fallback implemented: array overflow");
            this = _nvalue[index];
            return;
        case RefArrayType:
            if(index >= _refvalue.length)
                throw new Exception("No error fallback implemented: array overflow");
            _refindex = &((*_refvalue)[index]);
            type = GrDynamicValueType.RefIndexType;
            return;
        case RefIndexType:
            _refindex = &(_refindex._nvalue[index]);
            return;
        default:
            throw new Exception("No error fallback implemented");
        }
    }

    /// The value is now a reference for another value.
    void setRef(GrDynamicValue value) {
        if(type != GrDynamicValueType.RefIndexType)
            throw new Exception("No error fallback implemented");
        *_refindex = value;
    }

    /// Converts and returns a boolean value.
    int getBool(GrCall call) {
        switch(type) with(GrDynamicValueType) {
        case BoolType:
        case IntType:
            return _ivalue;
        case FloatType:
            return to!int(_rvalue);
        case StringType:
            return _svalue == "true";           
        case RefIndexType:
            return _refindex.getBool(call);
        default:
            raiseConversionError(call, GrDynamicValueType.BoolType);
            return false;
        }
    }

    /// Converts and returns an integer value.
    int getInt(GrCall call) {
        switch(type) with(GrDynamicValueType) {
        case BoolType:
        case IntType:
            return _ivalue;
        case FloatType:
            return to!int(_rvalue);
        case StringType:
            return to!int(_svalue);          
        case RefIndexType:
            return _refindex.getBool(call);
        default:
            raiseConversionError(call, GrDynamicValueType.IntType);
            return 0;
        }
    }

    /// Converts and returns a float value.
    float getFloat(GrCall call) {
        switch(type) with(GrDynamicValueType) {
        case BoolType:
        case IntType:
            return to!float(_ivalue);
        case FloatType:
            return _rvalue;
        case StringType:
            return to!float(_svalue);         
        case RefIndexType:
            return _refindex.getFloat(call);
        default:
            raiseConversionError(call, GrDynamicValueType.FloatType);
            return 0f;
        }
    }

    /// Converts and returns a string value.
    dstring getString(GrCall call) {
        switch(type) with(GrDynamicValueType) {
        case UndefinedType:
            return "undefined";
        case FunctionType:
        case TaskType:
            return to!dstring(grGetPrettyType(grUnmangle(_subType)));
        case BoolType:
            return _ivalue ? "true" : "false";
        case IntType:
            return to!dstring(_ivalue);
        case FloatType:
            return to!dstring(_rvalue);
        case StringType:
            return _svalue;
        case ArrayType:
            dstring result = "[";
            int i;
            foreach(value; _nvalue) {
                result ~= value.getString(call);
                if((i + 2) <= _nvalue.length)
                    result ~= ", ";
                i ++;
            }
            result ~= "]";
            return result;
        case RefArrayType:
            dstring result = "[";
            int i;
            foreach(value; *_refvalue) {
                result ~= value.getString(call);
                if((i + 2) <= _nvalue.length)
                    result ~= ", ";
                i ++;
            }
            result ~= "]";
            return result;
        case RefIndexType:
            return _refindex.getString(call);
        default:
            raiseConversionError(call, GrDynamicValueType.StringType);
            return "";
        }
    }

    /// Converts and returns an array value.
    GrDynamicValue[] getArray(GrCall call) {
        switch(type) with(GrDynamicValueType) {
        case StringType:
            GrDynamicValue[] array;
            foreach(character; _svalue) {
                GrDynamicValue nElement;
                nElement.setString(to!dstring(character));
                array ~= nElement;
            }
            return array;
        case ArrayType:
            return _nvalue;
        case RefArrayType:
            return *_refvalue;
        case RefIndexType:
            return _refindex.getArray(call);
        default:
            raiseConversionError(call, GrDynamicValueType.ArrayType);
            return [];
        }
    }

    int getFunction(GrCall call) {
        switch(type) with(GrDynamicValueType) {
        case FunctionType:
            if(_subType != call.meta)
                raiseConversionError(call, GrDynamicValueType.FunctionType);
            return _ivalue;
        default:
            raiseConversionError(call, GrDynamicValueType.FunctionType);
            return 0;
        }
    }

    int getTask(GrCall call) {
        switch(type) with(GrDynamicValueType) {
        case TaskType:
            if(_subType != call.meta)
                raiseConversionError(call, GrDynamicValueType.TaskType);
            return _ivalue;
        default:
            raiseConversionError(call, GrDynamicValueType.TaskType);
            return 0;
        }
    }

    private void raiseConversionError(GrCall call, GrDynamicValueType dstType) {
        dstring src, dst;
        final switch(type) with(GrDynamicValueType) {
        case FunctionType:
        case TaskType:
            src = to!dstring(grGetPrettyType(grUnmangle(_subType)));
            break;
        case UndefinedType:
            src = "undefined";
            break;
        case BoolType:
            src = "bool";
            break;
        case IntType:
            src = "int";
            break;
        case FloatType:
            src = "float";
            break;
        case StringType:
            src = "string";
            break;
        case ArrayType:
            src = "array";
            break;
        case RefArrayType:
            src = "refarray";
            break;
        case RefIndexType:
            src = "refindex";
            break;
        }
        final switch(dstType) with(GrDynamicValueType) {
        case FunctionType:
        case TaskType:
            dst = to!dstring(grGetPrettyType(grUnmangle(call.meta)));
            break;
        case UndefinedType:
            dst = "undefined";
            break;
        case BoolType:
            dst = "bool";
            break;
        case IntType:
            dst = "int";
            break;
        case FloatType:
            dst = "float";
            break;
        case StringType:
            dst = "string";
            break;
        case ArrayType:
            dst = "array";
            break;
        case RefArrayType:
            dst = "refarray";
            break;
        case RefIndexType:
            dst = "refindex";
            break;
        }
        call.raise("Conversion Error: \'" ~ src ~ "\' -> \'" ~ dst ~ "\'");
    }
    
    /// Copy operator.
    GrDynamicValue opOpAssign(string op)(GrDynamicValue v) {
        static if(op == "+" || op == "-" || op == "*" || op == "/" || op == "%") {
            switch(type) with(GrDynamicValueType) {
            case BoolType:
                switch(v.type) with(GrDynamicValueType) {
                case BoolType:
                    mixin("_ivalue = _ivalue " ~ op ~ " v._ivalue;");
                    break;
                default:
                    break;
                }
                break;
            case IntType:
                switch(v.type) with(GrDynamicValueType) {
                case IntType:
                    mixin("_ivalue = _ivalue " ~ op ~ " v._ivalue;");
                    break;
                case FloatType:
                    type = GrDynamicValueType.FloatType;
                    mixin("_rvalue = to!float(_ivalue) " ~ op ~ " v._rvalue;");
                    break;
                default:
                    break;
                }
                break;
            case FloatType:
                switch(v.type) with(GrDynamicValueType) {
                case IntType:
                    mixin("_rvalue = _rvalue " ~ op ~ " to!float(v._ivalue);");
                    break;
                case FloatType:
                    mixin("_rvalue = _rvalue " ~ op ~ " v._rvalue;");
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
            switch(type) with(GrDynamicValueType) {
            case BoolType:
            case IntType:
            case FloatType:
                //error
                break;
            case StringType:
                switch(v.type) with(GrDynamicValueType) {
                case StringType:
                    mixin("_svalue = _svalue " ~ op ~ " v._svalue;");
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
        switch(type) with(GrDynamicValueType) {
        case IntType:
            mixin("_ivalue" ~ op ~ ";");
            break;
        case FloatType:
            mixin("_rvalue" ~ op ~ ";");				
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
        switch(type) with(GrDynamicValueType) {
        case IntType:
            mixin("_ivalue = " ~ op ~ " _ivalue;");
            break;
        case FloatType:
            mixin("_rvalue = " ~ op ~ " _rvalue;");				
            break;
        case StringType:
        default:
            //error
            break;
        }
        return this;
    }	
}