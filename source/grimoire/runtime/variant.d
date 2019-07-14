/**
    Runtime dynamic value.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.runtime.variant;

import std.conv: to;
import grimoire.compiler;
import grimoire.runtime.context, grimoire.runtime.engine, grimoire.runtime.array;

/**
    Lazy evaluation variable that can hold many types.
*/
struct GrVariantValue {
    private union {
        int _ivalue;
        float _rvalue;
        dstring _svalue;
        void* _ovalue;
    }
    private dstring _subType;

    /// Variant type.
    enum GrVariantValueType {
        UndefinedType,
        FunctionType, TaskType,
        BoolType, IntType, FloatType, StringType, ArrayType, RefArrayType, ReferenceType
    }

    /// Variant type.
    GrVariantValueType type;

    /// Sets a function.
    void setFunction(int addr, dstring subType) {
        type = GrVariantValueType.FunctionType;
        _ivalue = addr;
        _subType = subType;
    }

    /// Sets a task.
    void setTask(int addr, dstring subType) {
        type = GrVariantValueType.TaskType;
        _ivalue = addr;
        _subType = subType;
    }

    /// Sets the value to the boolean value.
    void setBool(int value) {
        type = GrVariantValueType.BoolType;
        _ivalue = value;
    }

    /// Sets the value to integer.
    void setInt(int value) {
        type = GrVariantValueType.IntType;
        _ivalue = value;
    }

    /// Sets the value to float.
    void setFloat(float value) {
        type = GrVariantValueType.FloatType;
        _rvalue = value;
    }

    /// Sets the value to string.
    void setString(dstring value) {
        type = GrVariantValueType.StringType;
        _svalue = value;
    }

    /// Sets the value to array.
    void setArray(GrArrayValue value) {
        type = GrVariantValueType.ArrayType;
        _ovalue = cast(void*)value;
    }

    /// The value is set to the value stored at the index of the current array.
    /// The value must be a valid indexable value.
    void setArrayIndex(GrContext context, int index) {
        switch(type) with(GrVariantValueType) {
        case ArrayType:
            GrArrayValue ary = cast(GrArrayValue)_ovalue;
            if(index >= ary.data.length) {
                raise(context, "Array overflow");
                return;
            }
            type = GrVariantValueType.ReferenceType;
            _ovalue = &ary.data[index];
            return;
        case ReferenceType:
            auto variant = cast(GrVariantValue*)_ovalue;
            if(variant.type != GrVariantValueType.ArrayType) {
                raise(context, "Invalid reference 2");
                return;
            }
            GrArrayValue ary = cast(GrArrayValue)((cast(GrVariantValue*)_ovalue)._ovalue);
            if(index >= ary.data.length) {
                raise(context, "Array overflow");
                return;
            }
            type = GrVariantValueType.ReferenceType;
            _ovalue = &ary.data[index];
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
    void setRef(GrContext context, GrVariantValue* value) {
        type = GrVariantValueType.ReferenceType;
        _ovalue = cast(void*)value;
    }

    void storeRef(GrContext context, ref GrVariantValue value) {
        if(type != GrVariantValueType.ReferenceType)
            context.engine.raise(context, "Invalid reference");
        *(cast(GrVariantValue*)_ovalue) = value;
    }

    GrVariantValue copy() {
        if(type == GrVariantValueType.ReferenceType)
            return (cast(GrVariantValue*)_ovalue).copy();
        else if(type == GrVariantValueType.ArrayType) {
            GrVariantValue variant;
            variant.setArray(new GrArrayValue(cast(GrArrayValue)_ovalue));
            return variant;
        }
        else
            return this;
    }

    /// Converts and returns a boolean value.
    int getBool(GrCall call) {
        switch(type) with(GrVariantValueType) {
        case BoolType:
        case IntType:
            return _ivalue;
        case FloatType:
            return to!int(_rvalue);
        case StringType:
            return _svalue == "true";           
        case ReferenceType:
            return (cast(GrVariantValue*)_ovalue).getBool(call);
        default:
            raiseConversionError(call, GrVariantValueType.BoolType);
            return false;
        }
    }

    /// Converts and returns an integer value.
    int getInt(GrCall call) {
        switch(type) with(GrVariantValueType) {
        case BoolType:
        case IntType:
            return _ivalue;
        case FloatType:
            return to!int(_rvalue);
        case StringType:
            return to!int(_svalue);          
        case ReferenceType:
            return (cast(GrVariantValue*)_ovalue).getBool(call);
        default:
            raiseConversionError(call, GrVariantValueType.IntType);
            return 0;
        }
    }

    /// Converts and returns a float value.
    float getFloat(GrCall call) {
        switch(type) with(GrVariantValueType) {
        case BoolType:
        case IntType:
            return to!float(_ivalue);
        case FloatType:
            return _rvalue;
        case StringType:
            return to!float(_svalue);         
        case ReferenceType:
            return (cast(GrVariantValue*)_ovalue).getFloat(call);
        default:
            raiseConversionError(call, GrVariantValueType.FloatType);
            return 0f;
        }
    }

    /// Converts and returns a string value.
    dstring getString(GrCall call) {
        switch(type) with(GrVariantValueType) {
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
            return (cast(GrArrayValue)_ovalue).getString(call);
        case ReferenceType:
            return (cast(GrVariantValue*)_ovalue).getString(call);
        default:
            raiseConversionError(call, GrVariantValueType.StringType);
            return "";
        }
    }

    /// Converts and returns an array value.
    GrArrayValue getArray(GrCall call) {
        switch(type) with(GrVariantValueType) {
        case StringType:
            GrArrayValue array;
            foreach(character; _svalue) {
                GrVariantValue nElement;
                nElement.setString(to!dstring(character));
                array.data ~= nElement;
            }
            return array;
        case ArrayType:
            return cast(GrArrayValue)_ovalue;
        case ReferenceType:
            return (cast(GrVariantValue*)_ovalue).getArray(call);
        default:
            raiseConversionError(call, GrVariantValueType.ArrayType);
            return new GrArrayValue;
        }
    }

    int getFunction(GrCall call) {
        switch(type) with(GrVariantValueType) {
        case FunctionType:
            if(_subType != call.meta)
                raiseConversionError(call, GrVariantValueType.FunctionType);
            return _ivalue;
        default:
            raiseConversionError(call, GrVariantValueType.FunctionType);
            return 0;
        }
    }

    int getTask(GrCall call) {
        switch(type) with(GrVariantValueType) {
        case TaskType:
            if(_subType != call.meta)
                raiseConversionError(call, GrVariantValueType.TaskType);
            return _ivalue;
        default:
            raiseConversionError(call, GrVariantValueType.TaskType);
            return 0;
        }
    }

    void call(GrContext context) {
        switch(type) with(GrVariantValueType) {
        case FunctionType:
            context.engine.meta = "$f(" ~ context.engine.meta ~ ")()";
            if(context.engine.meta != _subType) {
                raiseCallError(context, GrVariantValueType.FunctionType);
                return;
            }
            if((context.stackPos >> 1) >= context.callStackLimit)
                context.doubleCallStackSize();
            context.localsPos += context.callStack[context.stackPos];
            context.callStack[context.stackPos + 1u] = context.pc + 1u;
            context.stackPos += 2;
            context.vstackPos --;
            context.pc = _ivalue;
            return;
        case TaskType:
            context.engine.meta = "$t(" ~ context.engine.meta ~ ")";
            if(context.engine.meta != _subType) {
                raiseCallError(context, GrVariantValueType.TaskType);
                return;
            }
            GrContext newCoro = new GrContext(context.engine);
            newCoro.pc = _ivalue;
            context.engine.pushContext(newCoro);
            context.vstackPos --;
            context.pc ++;
            return;
        default:
            context.engine.meta = "$f(" ~ context.engine.meta ~ ")()";
            raiseCallError(context, GrVariantValueType.FunctionType);
            return;
        }
    }
    
    private void raiseCallError(GrContext context, GrVariantValueType dstType) {
        context.engine.raise(context, "Call error: \'"
            ~ getPrettyType(this)
            ~ "\' -> \'"
            ~ getPrettyType(dstType, context.engine.meta)
            ~ "\'");
    }

    private void raiseConversionError(GrCall call, GrVariantValueType dstType) {
        call.raise("Conversion error: \'"
            ~ getPrettyType(this)
            ~ "\' -> \'"
            ~ getPrettyType(dstType, call.meta)
            ~ "\'");
    }

    private dstring getPrettyType(GrVariantValue value) {
        dstring prettyType;
        final switch(value.type) with(GrVariantValueType) {
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
        case ReferenceType:
            prettyType = "refindex";
            break;
        }
        return prettyType;
    }

    private dstring getPrettyType(GrVariantValueType dstType, dstring subType) {
        dstring prettyType;        
        final switch(dstType) with(GrVariantValueType) {
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
        case ReferenceType:
            prettyType = "refindex";
            break;
        }
        return prettyType;
    }
    
    /// Copy operator.
    GrVariantValue opOpAssign(string op)(GrVariantValue v) {
        static if(op == "+" || op == "-" || op == "*" || op == "/" || op == "%") {
            switch(type) with(GrVariantValueType) {
            case BoolType:
                switch(v.type) with(GrVariantValueType) {
                case BoolType:
                    mixin("_ivalue = _ivalue " ~ op ~ " v._ivalue;");
                    break;
                default:
                    break;
                }
                break;
            case IntType:
                switch(v.type) with(GrVariantValueType) {
                case IntType:
                    mixin("_ivalue = _ivalue " ~ op ~ " v._ivalue;");
                    break;
                case FloatType:
                    type = GrVariantValueType.FloatType;
                    mixin("_rvalue = to!float(_ivalue) " ~ op ~ " v._rvalue;");
                    break;
                default:
                    break;
                }
                break;
            case FloatType:
                switch(v.type) with(GrVariantValueType) {
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
            switch(type) with(GrVariantValueType) {
            case BoolType:
            case IntType:
            case FloatType:
                //error
                break;
            case StringType:
                switch(v.type) with(GrVariantValueType) {
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
    GrVariantValue opUnaryRight(string op)() {	
        switch(type) with(GrVariantValueType) {
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
    GrVariantValue opUnary(string op)() {	
        switch(type) with(GrVariantValueType) {
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
        switch(type) with(GrVariantValueType) {
        case BoolType:
            _ivalue = !_ivalue;
            return;
        default:
            raise(context, "Operation Error");
        }
    }

    bool operationAnd(GrContext context, ref GrVariantValue dyn) {
        switch(type) with(GrVariantValueType) {
        case BoolType:
            return _ivalue && dyn._ivalue;
        default:
            return false;
        }
    }

    bool operationOr(GrContext context, ref GrVariantValue dyn) {
        switch(type) with(GrVariantValueType) {
        case BoolType:
            return _ivalue || dyn._ivalue;
        default:
            return false;
        }
    }

    bool operationComparison(string op)(GrContext context, ref GrVariantValue dyn) {
        if(type != dyn.type) {
            //Float/Int comparison are allowed
            if(type == GrVariantValueType.IntType && dyn.type == GrVariantValueType.FloatType)
                mixin("return (cast(float)_ivalue) " ~ op ~ " dyn._rvalue;");
            else if(type == GrVariantValueType.FloatType && dyn.type == GrVariantValueType.IntType)
                mixin("return _rvalue " ~ op ~ " cast(float)dyn._ivalue;");
            return false;
        }
        
        switch(type) with(GrVariantValueType) {
        case IntType:
            mixin("return _ivalue " ~ op ~ " dyn._ivalue;");
        case FloatType:
            mixin("return _rvalue " ~ op ~ " dyn._rvalue;");
        default:
            return false;
        }
    }

    bool opEquals(ref GrVariantValue dyn) {
        if(type != dyn.type)
            return false;

        switch(type) with(GrVariantValueType) {
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
            return _ovalue == dyn._ovalue;
        default:
            return false;
        }
    }	
}