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
    void setArrayIndex(GrContext context, int index) {
        switch(type) with(GrDynamicValueType) {
        case ArrayType:
            if(index >= _nvalue.length) {
                raise(context, "Array overflow");
                return;
            }
            this = _nvalue[index];
            return;
        case RefArrayType:
            if(index >= _refvalue.length) {
                raise(context, "Array overflow");
                return;
            }
            _refindex = &((*_refvalue)[index]);
            type = GrDynamicValueType.RefIndexType;
            return;
        case RefIndexType:
            _refindex = &(_refindex._nvalue[index]);
            return;
        default:
            raise(context, "Invalid reference");
            break;
        }
    }

    private void raise(GrContext context, dstring message) {
        context.engine.raise(context, message);

        //The context is still in an opcode
        //and will increment the pc, so we prevent that.
        context.pc --;
    }

    /// The value is now a reference for another value.
    void setRef(GrContext context, GrDynamicValue value) {
        if(type != GrDynamicValueType.RefIndexType)
            context.engine.raise(context, "Invalid reference");
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

    void call(GrContext context) {
        switch(type) with(GrDynamicValueType) {
        case FunctionType:
            context.engine.meta = "$f(" ~ context.engine.meta ~ ")()";
            if(context.engine.meta != _subType) {
                raiseCallError(context, GrDynamicValueType.FunctionType);
                return;
            }
            if((context.stackPos >> 1) >= context.callStackLimit)
                context.doubleCallStackSize();
            context.localsPos += context.callStack[context.stackPos];
            context.callStack[context.stackPos + 1u] = context.pc + 1u;
            context.stackPos += 2;
            context.astackPos --;
            context.pc = _ivalue;
            return;
        case TaskType:
            context.engine.meta = "$t(" ~ context.engine.meta ~ ")";
            if(context.engine.meta != _subType) {
                raiseCallError(context, GrDynamicValueType.TaskType);
                return;
            }
            GrContext newCoro = new GrContext(context.engine);
            newCoro.pc = _ivalue;
            context.engine.pushContext(newCoro);
            context.astackPos --;
            context.pc ++;
            return;
        default:
            context.engine.meta = "$f(" ~ context.engine.meta ~ ")()";
            raiseCallError(context, GrDynamicValueType.FunctionType);
            return;
        }
    }
    
    private void raiseCallError(GrContext context, GrDynamicValueType dstType) {
        context.engine.raise(context, "Call error: \'"
            ~ getPrettyType(this)
            ~ "\' -> \'"
            ~ getPrettyType(dstType, context.engine.meta)
            ~ "\'");
    }

    private void raiseConversionError(GrCall call, GrDynamicValueType dstType) {
        call.raise("Conversion error: \'"
            ~ getPrettyType(this)
            ~ "\' -> \'"
            ~ getPrettyType(dstType, call.meta)
            ~ "\'");
    }

    private dstring getPrettyType(GrDynamicValue value) {
        dstring prettyType;
        final switch(value.type) with(GrDynamicValueType) {
        case FunctionType:
        case TaskType:
            prettyType = to!dstring(grGetPrettyType(grUnmangle(value._subType)));
            break;
        case UndefinedType:
            prettyType = "undefined";
            break;
        case BoolType:
            prettyType = "bool";
            break;
        case IntType:
            prettyType = "int";
            break;
        case FloatType:
            prettyType = "float";
            break;
        case StringType:
            prettyType = "string";
            break;
        case ArrayType:
            prettyType = "array";
            break;
        case RefArrayType:
            prettyType = "refarray";
            break;
        case RefIndexType:
            prettyType = "refindex";
            break;
        }
        return prettyType;
    }

    private dstring getPrettyType(GrDynamicValueType dstType, dstring subType) {
        dstring prettyType;        
        final switch(dstType) with(GrDynamicValueType) {
        case FunctionType:
        case TaskType:
            prettyType = to!dstring(grGetPrettyType(grUnmangle(subType)));
            break;
        case UndefinedType:
            prettyType = "undefined";
            break;
        case BoolType:
            prettyType = "bool";
            break;
        case IntType:
            prettyType = "int";
            break;
        case FloatType:
            prettyType = "float";
            break;
        case StringType:
            prettyType = "string";
            break;
        case ArrayType:
            prettyType = "array";
            break;
        case RefArrayType:
            prettyType = "refarray";
            break;
        case RefIndexType:
            prettyType = "refindex";
            break;
        }
        return prettyType;
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

    void operationNot(GrContext context) {
        switch(type) with(GrDynamicValueType) {
        case BoolType:
            _ivalue = !_ivalue;
            return;
        default:
            raise(context, "Operation Error");
        }
    }

    bool operationAnd(GrContext context, ref GrDynamicValue dyn) {
        switch(type) with(GrDynamicValueType) {
        case BoolType:
            return _ivalue && dyn._ivalue;
        default:
            return false;
        }
    }

    bool operationOr(GrContext context, ref GrDynamicValue dyn) {
        switch(type) with(GrDynamicValueType) {
        case BoolType:
            return _ivalue || dyn._ivalue;
        default:
            return false;
        }
    }

    bool operationComparison(string op)(GrContext context, ref GrDynamicValue dyn) {
        if(type != dyn.type) {
            //Float/Int comparison are allowed
            if(type == GrDynamicValueType.IntType && dyn.type == GrDynamicValueType.FloatType)
                mixin("return (cast(float)_ivalue) " ~ op ~ " dyn._rvalue;");
            else if(type == GrDynamicValueType.FloatType && dyn.type == GrDynamicValueType.IntType)
                mixin("return _rvalue " ~ op ~ " cast(float)dyn._ivalue;");
            return false;
        }
        
        switch(type) with(GrDynamicValueType) {
        case IntType:
            mixin("return _ivalue " ~ op ~ " dyn._ivalue;");
        case FloatType:
            mixin("return _rvalue " ~ op ~ " dyn._rvalue;");
        default:
            return false;
        }
    }

    bool opEquals(ref GrDynamicValue dyn) {
        if(type != dyn.type)
            return false;

        switch(type) with(GrDynamicValueType) {
        case UndefinedType:
            return true;
        case FunctionType:
        case TaskType:
            return _subType == dyn._subType;
        case BoolType:
        case IntType:
            return _ivalue == dyn._ivalue;
        case FloatType:
            return _rvalue == dyn._rvalue;
        case StringType:
            return _svalue == dyn._svalue;
        case ArrayType:
        case RefArrayType:
            return _nvalue == dyn._nvalue;
        default:
            return false;
        }
    }	
}