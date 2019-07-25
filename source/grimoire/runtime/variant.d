/**
    Runtime dynamic value.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.runtime.variant;

import std.conv: to;
import grimoire.compiler;
import grimoire.runtime.context, grimoire.runtime.engine, grimoire.runtime.array, grimoire.runtime.call;

/**
    Lazy evaluation variable that can hold many types.
*/
struct GrVariant {
    private union {
        int _ivalue;
        float _rvalue;
        dstring _svalue;
        void* _ovalue;
    }
    private dstring _subType;

    /// Variant type.
    enum GrVariantType {
        UndefinedType,
        FunctionType, TaskType,
        BoolType, IntType, FloatType, StringType, ArrayType,
        ReferenceType
    }

    /// Variant type.
    GrVariantType type;

    /// Sets a function.
    void setFunction(int addr, dstring subType) {
        type = GrVariantType.FunctionType;
        _ivalue = addr;
        _subType = subType;
    }

    /// Sets a task.
    void setTask(int addr, dstring subType) {
        type = GrVariantType.TaskType;
        _ivalue = addr;
        _subType = subType;
    }

    /// Sets the value to the boolean value.
    void setBool(int value) {
        type = GrVariantType.BoolType;
        _ivalue = value;
    }

    /// Sets the value to integer.
    void setInt(int value) {
        type = GrVariantType.IntType;
        _ivalue = value;
    }

    /// Sets the value to float.
    void setFloat(float value) {
        type = GrVariantType.FloatType;
        _rvalue = value;
    }

    /// Sets the value to string.
    void setString(dstring value) {
        type = GrVariantType.StringType;
        _svalue = value;
    }

    /// Sets the value to array.
    void setArray(GrArray value) {
        type = GrVariantType.ArrayType;
        _ovalue = cast(void*)value;
    }

    /// The value is set to the value stored at the index of the current array.
    /// The value must be a valid indexable value.
    void setArrayIndex(GrContext context, int index) {
        switch(type) with(GrVariantType) {
        case ArrayType:
            GrArray ary = cast(GrArray)_ovalue;
            if(index >= ary.data.length) {
                raise(context, "Array overflow");
                return;
            }
            type = GrVariantType.ReferenceType;
            _ovalue = &ary.data[index];
            return;
        case ReferenceType:
            auto variant = cast(GrVariant*)_ovalue;
            if(variant.type != GrVariantType.ArrayType) {
                raise(context, "Invalid reference 2");
                return;
            }
            GrArray ary = cast(GrArray)((cast(GrVariant*)_ovalue)._ovalue);
            if(index >= ary.data.length) {
                raise(context, "Array overflow");
                return;
            }
            type = GrVariantType.ReferenceType;
            _ovalue = &ary.data[index];
            return;
        default:
            raise(context, "Invalid reference");
            break;
        }
    }

    //Inside a variant, only use this method for error handling
    private void raise(GrContext context, dstring message) {
        context.engine.raise(context, message);

        //The context is still in an opcode
        //and will increment the pc, so we prevent that.
        context.pc --;
    }

    /// The value is now a reference for another value.
    void setRef(GrContext context, GrVariant* value) {
        type = GrVariantType.ReferenceType;
        _ovalue = cast(void*)value;
    }

    alias storeIntRef = storeRef!int;
    alias storeFloatRef = storeRef!float;
    alias storeStringRef = storeRef!dstring;
    alias storeVariantRef = storeRef!GrVariant;
    alias storeObjectRef = storeRef!(void*);

    /// Modify the value referenced
    private void storeRef(T)(GrContext context, ref T value) {
        if(type != GrVariantType.ReferenceType) {
            raise(context, "Invalid reference");
            return;
        }
        static if(is(T == int)) {
            (cast(GrVariant*)_ovalue).setInt(value);
        }
        else static if(is(T == float)) {
            (cast(GrVariant*)_ovalue).setFloat(value);
        }
        else static if(is(T == dstring)) {
            (cast(GrVariant*)_ovalue).setString(value);
        }
        else static if(is(T == GrVariant)) {
            *(cast(GrVariant*)_ovalue) = value;
        }
        else static if(is(T == void*)) {
            //(cast(GrVariant*)_ovalue).setObject(value);
        }
    }

    /// Deep copy, used with the copy^ operator
    GrVariant copy() {
        if(type == GrVariantType.ReferenceType)
            return (cast(GrVariant*)_ovalue).copy();
        else if(type == GrVariantType.ArrayType) {
            GrVariant variant;
            variant.setArray(new GrArray(cast(GrArray)_ovalue));
            return variant;
        }
        else
            return this;
    }

    /// Converts and returns a boolean value.
    int getBool(GrCall call) {
        switch(type) with(GrVariantType) {
        case BoolType:
        case IntType:
            return _ivalue;
        case FloatType:
            return to!int(_rvalue);
        case StringType:
            return _svalue == "true";           
        case ReferenceType:
            return (cast(GrVariant*)_ovalue).getBool(call);
        default:
            raiseConversionError(call, GrVariantType.BoolType);
            return false;
        }
    }

    /// Converts and returns an integer value.
    int getInt(GrCall call) {
        switch(type) with(GrVariantType) {
        case BoolType:
        case IntType:
            return _ivalue;
        case FloatType:
            return to!int(_rvalue);
        case StringType:
            return to!int(_svalue);          
        case ReferenceType:
            return (cast(GrVariant*)_ovalue).getBool(call);
        default:
            raiseConversionError(call, GrVariantType.IntType);
            return 0;
        }
    }

    /// Converts and returns a float value.
    float getFloat(GrCall call) {
        switch(type) with(GrVariantType) {
        case BoolType:
        case IntType:
            return to!float(_ivalue);
        case FloatType:
            return _rvalue;
        case StringType:
            return to!float(_svalue);         
        case ReferenceType:
            return (cast(GrVariant*)_ovalue).getFloat(call);
        default:
            raiseConversionError(call, GrVariantType.FloatType);
            return 0f;
        }
    }

    /// Converts and returns a string value.
    dstring getString(GrCall call) {
        switch(type) with(GrVariantType) {
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
            return (cast(GrArray)_ovalue).getString(call);
        case ReferenceType:
            return (cast(GrVariant*)_ovalue).getString(call);
        default:
            raiseConversionError(call, GrVariantType.StringType);
            return "";
        }
    }

    /// Converts and returns an array value.
    GrArray getArray(GrCall call) {
        switch(type) with(GrVariantType) {
        case StringType:
            GrArray array;
            foreach(character; _svalue) {
                GrVariant nElement;
                nElement.setString(to!dstring(character));
                array.data ~= nElement;
            }
            return array;
        case ArrayType:
            return cast(GrArray)_ovalue;
        case ReferenceType:
            return (cast(GrVariant*)_ovalue).getArray(call);
        default:
            raiseConversionError(call, GrVariantType.ArrayType);
            return new GrArray;
        }
    }

    int getFunction(GrCall call) {
        switch(type) with(GrVariantType) {
        case FunctionType:
            if(_subType != call.meta)
                raiseConversionError(call, GrVariantType.FunctionType);
            return _ivalue;
        default:
            raiseConversionError(call, GrVariantType.FunctionType);
            return 0;
        }
    }

    int getTask(GrCall call) {
        switch(type) with(GrVariantType) {
        case TaskType:
            if(_subType != call.meta)
                raiseConversionError(call, GrVariantType.TaskType);
            return _ivalue;
        default:
            raiseConversionError(call, GrVariantType.TaskType);
            return 0;
        }
    }

    void call(GrContext context) {
        switch(type) with(GrVariantType) {
        case FunctionType:
            context.engine.meta = "$f(" ~ context.engine.meta ~ ")()";
            if(context.engine.meta != _subType) {
                raiseCallError(context, GrVariantType.FunctionType);
                return;
            }
            if((context.stackPos >> 1) >= context.callStackLimit)
                context.doubleCallStackSize();
            context.localsPos += context.callStack[context.stackPos].localStackSize;
            context.callStack[context.stackPos].retPosition = context.pc + 1u;
            context.stackPos ++;
            context.vstackPos --;
            context.pc = _ivalue;
            return;
        case TaskType:
            context.engine.meta = "$t(" ~ context.engine.meta ~ ")";
            if(context.engine.meta != _subType) {
                raiseCallError(context, GrVariantType.TaskType);
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
            raiseCallError(context, GrVariantType.FunctionType);
            return;
        }
    }
    
    private void raiseCallError(GrContext context, GrVariantType dstType) {
        context.engine.raise(context, "Call error: \'"
            ~ getPrettyType(this)
            ~ "\' -> \'"
            ~ getPrettyType(dstType, context.engine.meta)
            ~ "\'");
    }

    private void raiseConversionError(GrCall call, GrVariantType dstType) {
        call.raise("Conversion error: \'"
            ~ getPrettyType(this)
            ~ "\' -> \'"
            ~ getPrettyType(dstType, call.meta)
            ~ "\'");
    }

    private dstring getPrettyType(GrVariant value) {
        dstring prettyType;
        final switch(value.type) with(GrVariantType) {
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
        case ReferenceType:
            prettyType = "ref";
            break;
        }
        return prettyType;
    }

    private dstring getPrettyType(GrVariantType dstType, dstring subType) {
        dstring prettyType;        
        final switch(dstType) with(GrVariantType) {
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
        case ReferenceType:
            prettyType = "ref";
            break;
        }
        return prettyType;
    }
    
    /// Copy operator.
    GrVariant opOpAssign(string op)(GrVariant v) {
        static if(op == "+" || op == "-" || op == "*" || op == "/" || op == "%") {
            switch(type) with(GrVariantType) {
            case BoolType:
                switch(v.type) with(GrVariantType) {
                case BoolType:
                    mixin("_ivalue = _ivalue " ~ op ~ " v._ivalue;");
                    break;
                default:
                    break;
                }
                break;
            case IntType:
                switch(v.type) with(GrVariantType) {
                case IntType:
                    mixin("_ivalue = _ivalue " ~ op ~ " v._ivalue;");
                    break;
                case FloatType:
                    type = GrVariantType.FloatType;
                    mixin("_rvalue = to!float(_ivalue) " ~ op ~ " v._rvalue;");
                    break;
                default:
                    break;
                }
                break;
            case FloatType:
                switch(v.type) with(GrVariantType) {
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
        return this;
    }

    void concatenate(GrContext context, ref GrVariant value) {
        switch(type) with(GrVariantType) {
        case BoolType:
        case FunctionType:
        case TaskType:
        case IntType:
            switch(value.type) with(GrVariantType) {
            case ArrayType:
                (cast(GrArray)value._ovalue).prepend(this);
                setArray(cast(GrArray)value._ovalue);
                break;
            case StringType:
                _svalue = to!dstring(_ivalue) ~ value._svalue;
                type = GrVariantType.StringType;
                break;
            default:
                raise(context, "Concatenation error");
                break;
            }
            break;
        case FloatType:
            switch(value.type) with(GrVariantType) {
            case ArrayType:
                (cast(GrArray)value._ovalue).prepend(this);
                setArray(cast(GrArray)value._ovalue);
                break;
            case StringType:
                _svalue = to!dstring(_rvalue) ~ value._svalue;
                type = GrVariantType.StringType;
                break;
            default:
                raise(context, "Concatenation error");
                break;
            }
            break;       
        case StringType:
            switch(value.type) with(GrVariantType) {
            case ArrayType:
                (cast(GrArray)value._ovalue).prepend(this);
                setArray(cast(GrArray)value._ovalue);
                break;
            case StringType:
                _svalue = _svalue ~ value._svalue;
                break;
            default:
                break;
            }
            break;
        case ArrayType:
            switch(value.type) with(GrVariantType) {
            case ArrayType:
                (cast(GrArray)_ovalue).data ~= (cast(GrArray)value._ovalue).data;
                break;
            case BoolType:
            case FunctionType:
            case TaskType:
            case IntType:
            case FloatType:
            case StringType:
                (cast(GrArray)_ovalue).append(value);
                break;
            default:
                break;
            }
            break;
        default:
            raise(context, "Concatenation error");
            break;
        }
    }

    /// Increment and Decrement.
    GrVariant opUnaryRight(string op)() {	
        switch(type) with(GrVariantType) {
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
    GrVariant opUnary(string op)() {	
        switch(type) with(GrVariantType) {
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
        switch(type) with(GrVariantType) {
        case BoolType:
            _ivalue = !_ivalue;
            return;
        default:
            raise(context, "Operation Error");
        }
    }

    bool operationAnd(GrContext context, ref GrVariant dyn) {
        switch(type) with(GrVariantType) {
        case BoolType:
            return _ivalue && dyn._ivalue;
        default:
            return false;
        }
    }

    bool operationOr(GrContext context, ref GrVariant dyn) {
        switch(type) with(GrVariantType) {
        case BoolType:
            return _ivalue || dyn._ivalue;
        default:
            return false;
        }
    }

    bool operationComparison(string op)(GrContext context, ref GrVariant dyn) {
        if(type != dyn.type) {
            //Float/Int comparison are allowed
            if(type == GrVariantType.IntType && dyn.type == GrVariantType.FloatType)
                mixin("return (cast(float)_ivalue) " ~ op ~ " dyn._rvalue;");
            else if(type == GrVariantType.FloatType && dyn.type == GrVariantType.IntType)
                mixin("return _rvalue " ~ op ~ " cast(float)dyn._ivalue;");
            return false;
        }
        
        switch(type) with(GrVariantType) {
        case IntType:
            mixin("return _ivalue " ~ op ~ " dyn._ivalue;");
        case FloatType:
            mixin("return _rvalue " ~ op ~ " dyn._rvalue;");
        default:
            return false;
        }
    }

    bool opEquals(ref GrVariant dyn) {
        if(type != dyn.type)
            return false;

        switch(type) with(GrVariantType) {
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