/**
    Grimoire virtual machine.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module runtime.vm;

import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.math;

import core.indexedarray;
import compiler.all;
import assembly.all;
import runtime.coroutine;
import runtime.dynamic;
import runtime.array;

/**Grimoire virtual machine*/
class GrVM {
    private {
        uint[] _opcodes;

        int[] _iconsts;
        float[] _fconsts;
        dstring[] _sconsts;

        int[] _iglobals;
        float[] _fglobals;
        dstring[] _sglobals;

        int[] _iglobalStack;
        float[] _fglobalStack;
        dstring[] _sglobalStack;
        GrDynamicValue[][] _nglobalStack;
        GrDynamicValue[] _aglobalStack;
        void*[] _oglobalStack;
	    IndexedArray!(GrCoroutine, 256u) _coroutines = new IndexedArray!(GrCoroutine, 256u)();
    }

    __gshared bool isRunning = true;

    @property {
        /// Check if there is a coroutine currently running.
        bool hasCoroutines() const { return _coroutines.length > 0uL; }
    }

    /// Default.
	this() {}

    /// Load the bytecode.
	this(GrBytecode bytecode) {
		load(bytecode);
	}

    /// Load the bytecode.
	void load(GrBytecode bytecode) {
		_iconsts = bytecode.iconsts;
		_fconsts = bytecode.fconsts;
		_sconsts = bytecode.sconsts;
		_opcodes = bytecode.opcodes;
	}

    /**
        Create the main coroutine.
        You must call this function before running the vm.
    */
    void spawn() {
		_coroutines.push(new GrCoroutine(this));
	}

    /// Run the vm until all the coroutine are finished or in yield.
	void process() {
		coroutinesLabel: for(uint index = 0u; index < _coroutines.length; index ++) {
			GrCoroutine coro = _coroutines.data[index];
			while(isRunning) {
				uint opcode = _opcodes[coro.pc];
				switch (grBytecode_getOpcode(opcode)) with(GrOpcode) {
                case Nop:
                    coro.pc ++;
                    break;
                case Panic:
                    

                    break;
				case Task:
					GrCoroutine newCoro = new GrCoroutine(this);
					newCoro.pc = grBytecode_getUnsignedValue(opcode);
					_coroutines.push(newCoro);
					coro.pc ++;
					break;
				case AnonymousTask:
					GrCoroutine newCoro = new GrCoroutine(this);
					newCoro.pc = coro.istack[$ - 1];
					coro.istack.length --;
					_coroutines.push(newCoro);
					coro.pc ++;
					break;
				case Kill:
                    //Check for deferred calls.
                    if(coro.deferStack[$ - 1].length) {
                        //Pop the last defer and run it.
                        coro.pc = coro.deferStack[$ - 1][$ - 1];
                        coro.deferStack[$ - 1].length --;

                        //Flag as killed so the entire stack will be unwinded.
                        coro.isKilled = true;
                    }
                    else if(coro.stackPos) {
                        //Pop the defer scope.
                        coro.deferStack.length --;

                        //Then returns to the last context.
                        coro.stackPos -= 2;
                        coro.pc = coro.callStack[coro.stackPos + 1u];
                        coro.valuesPos -= coro.callStack[coro.stackPos];

                        //Flag as killed so the entire stack will be unwinded.
                        coro.isKilled = true;
                    }
                    else {
                        //No need to flag if the call stac is empty without any deferred statement.
                        _coroutines.markInternalForRemoval(index);
					    continue coroutinesLabel;
                    }
					break;
				case Yield:
					coro.pc ++;
					continue coroutinesLabel;
				case PopStack_Int:
					coro.istack.length -= grBytecode_getUnsignedValue(opcode);
					coro.pc ++;
					break;
				case PopStack_Float:
					coro.fstack.length -= grBytecode_getUnsignedValue(opcode);
					coro.pc ++;
					break;
				case PopStack_String:
					coro.sstack.length -= grBytecode_getUnsignedValue(opcode);
					coro.pc ++;
					break;
                case PopStack_Array:
					coro.nstack.length -= grBytecode_getUnsignedValue(opcode);
					coro.pc ++;
					break;
				case PopStack_Any:
					coro.astack.length -= grBytecode_getUnsignedValue(opcode);
					coro.pc ++;
					break;
				case PopStack_Object:
					coro.ostack.length -= grBytecode_getUnsignedValue(opcode);
					coro.pc ++;
					break;
				case LocalStore_Int:
					coro.ivalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)] = coro.istack[$ - 1];
                    coro.istack.length --;	
					coro.pc ++;
					break;
				case LocalStore_Float:
					coro.fvalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)] = coro.fstack[$ - 1];
                    coro.fstack.length --;	
					coro.pc ++;
					break;
				case LocalStore_String:
					coro.svalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)] = coro.sstack[$ - 1];		
                    coro.sstack.length --;	
					coro.pc ++;
					break;
                case LocalStore_Array:
					coro.nvalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)] = coro.nstack[$ - 1];		
                    coro.nstack.length --;	
					coro.pc ++;
					break;
				case LocalStore_Any:
					coro.avalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)] = coro.astack[$ - 1];
                    coro.astack.length --;	
					coro.pc ++;
					break;
                case LocalStore_Ref:
                    coro.astack[$ - 2].setRef(coro.astack[$ - 1]);
                    coro.astack.length -= 2;
                    coro.pc ++;
                    break;
				case LocalStore_Object:
					coro.ovalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)] = coro.ostack[$ - 1];
                    coro.ostack.length --;	
					coro.pc ++;
					break;
                case LocalStore2_Int:
					coro.ivalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)] = coro.istack[$ - 1];
					coro.pc ++;
					break;
				case LocalStore2_Float:
					coro.fvalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)] = coro.fstack[$ - 1];
					coro.pc ++;
					break;
				case LocalStore2_String:
					coro.svalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)] = coro.sstack[$ - 1];		
					coro.pc ++;
					break;
                case LocalStore2_Array:
					coro.nvalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)] = coro.nstack[$ - 1];		
					coro.pc ++;
					break;
				case LocalStore2_Any:
					coro.avalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)] = coro.astack[$ - 1];
					coro.pc ++;
					break;
                case LocalStore2_Ref:
                    coro.astack[$ - 2].setRef(coro.astack[$ - 1]);
                    coro.astack.length --;
                    coro.pc ++;
                    break;
				case LocalStore2_Object:
					coro.ovalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)] = coro.ostack[$ - 1];
					coro.pc ++;
					break;
				case LocalLoad_Int:
					coro.istack ~= coro.ivalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)];
					coro.pc ++;
					break;
				case LocalLoad_Float:
					coro.fstack ~= coro.fvalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)];
					coro.pc ++;
					break;
				case LocalLoad_String:
					coro.sstack ~= coro.svalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)];
					coro.pc ++;
					break;
                case LocalLoad_Array:
					coro.nstack ~= coro.nvalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)];
					coro.pc ++;
					break;
				case LocalLoad_Any:
					coro.astack ~= coro.avalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)];
					coro.pc ++;
					break;
                case LocalLoad_Ref:
                    GrDynamicValue value;
                    value.setRefArray(&coro.nvalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)]);
                    coro.astack ~= value;					
					coro.pc ++;
					break;
				case LocalLoad_Object:
					coro.ostack ~= coro.ovalues[coro.valuesPos + grBytecode_getUnsignedValue(opcode)];
					coro.pc ++;
					break;
				case Const_Int:
					coro.istack ~= _iconsts[grBytecode_getUnsignedValue(opcode)];
					coro.pc ++;
					break;
				case Const_Float:
					coro.fstack ~= _fconsts[grBytecode_getUnsignedValue(opcode)];
					coro.pc ++;
					break;
				case Const_Bool:
					coro.istack ~= grBytecode_getUnsignedValue(opcode);
					coro.pc ++;
					break;
				case Const_String:
					coro.sstack ~= _sconsts[grBytecode_getUnsignedValue(opcode)];
					coro.pc ++;
					break;
				case GlobalPush_Int:
					uint nbParams = grBytecode_getUnsignedValue(opcode);
					for(uint i = 0u; i < nbParams; i++)
						_iglobalStack ~= coro.istack[($ - nbParams) + i];
					coro.istack.length -= nbParams;
					coro.pc ++;
					break;
				case GlobalPush_Float:
					uint nbParams = grBytecode_getUnsignedValue(opcode);
					for(uint i = 0u; i < nbParams; i++)
						_fglobalStack ~= coro.fstack[($ - nbParams) + i];
					coro.fstack.length -= nbParams;
					coro.pc ++;
					break;
				case GlobalPush_String:
					uint nbParams = grBytecode_getUnsignedValue(opcode);
					for(uint i = 0u; i < nbParams; i++)
						_sglobalStack ~= coro.sstack[($ - nbParams) + i];
					coro.sstack.length -= nbParams;
					coro.pc ++;
					break;
                case GlobalPush_Array:
					uint nbParams = grBytecode_getUnsignedValue(opcode);
					for(uint i = 0u; i < nbParams; i++)
						_nglobalStack ~= coro.nstack[($ - nbParams) + i];
					coro.nstack.length -= nbParams;
					coro.pc ++;
					break;
				case GlobalPush_Any:
					uint nbParams = grBytecode_getUnsignedValue(opcode);
					for(uint i = 0u; i < nbParams; i++)
						_aglobalStack ~= coro.astack[($ - nbParams) + i];
					coro.astack.length -= nbParams;
					coro.pc ++;
					break;
				case GlobalPush_Object:
					uint nbParams = grBytecode_getUnsignedValue(opcode);
					for(uint i = 0u; i < nbParams; i++)
						_oglobalStack ~= coro.ostack[($ - nbParams) + i];
					coro.ostack.length -= nbParams;
					coro.pc ++;
					break;
				case GlobalPop_Int:
					coro.istack ~= _iglobalStack[$ - 1];
					_iglobalStack.length --;
					coro.pc ++;
					break;
				case GlobalPop_Float:
					coro.fstack ~= _fglobalStack[$ - 1];
					_fglobalStack.length --;
					coro.pc ++;
					break;
				case GlobalPop_String:
					coro.sstack ~= _sglobalStack[$ - 1];
					_sglobalStack.length --;
					coro.pc ++;
					break;
                case GlobalPop_Array:
					coro.nstack ~= _nglobalStack[$ - 1];
					_nglobalStack.length --;
					coro.pc ++;
					break;
				case GlobalPop_Any:
					coro.astack ~= _aglobalStack[$ - 1];
					_aglobalStack.length --;
					coro.pc ++;
					break;
				case GlobalPop_Object:
					coro.ostack ~= _oglobalStack[$ - 1];
					_oglobalStack.length --;
					coro.pc ++;
					break;
                case ConvertBoolToAny:
					GrDynamicValue value;
					value.setBool(coro.istack[$ - 1]);
					coro.istack.length --;
					coro.astack ~= value;
					coro.pc ++;
					break;
				case ConvertIntToAny:
					GrDynamicValue value;
					value.setInteger(coro.istack[$ - 1]);
					coro.istack.length --;
					coro.astack ~= value;
					coro.pc ++;
					break;
				case ConvertFloatToAny:
					GrDynamicValue value;
					value.setFloat(coro.fstack[$ - 1]);
					coro.fstack.length --;
					coro.astack ~= value;
					coro.pc ++;
					break;
				case ConvertStringToAny:
					GrDynamicValue value;
					value.setString(coro.sstack[$ - 1]);
					coro.sstack.length --;
					coro.astack ~= value;
					coro.pc ++;
					break;
                case ConvertArrayToAny:
					GrDynamicValue value;
					value.setArray(coro.nstack[$ - 1]);
					coro.nstack.length --;
					coro.astack ~= value;
					coro.pc ++;
					break;
				case ConvertAnyToBool:
					coro.istack ~= coro.astack[$ - 1].getBool();
					coro.astack.length --;
					coro.pc ++;
					break;
                case ConvertAnyToInt:
					coro.istack ~= coro.astack[$ - 1].getInteger();
					coro.astack.length --;
					coro.pc ++;
					break;
				case ConvertAnyToFloat:
					coro.fstack ~= coro.astack[$ - 1].getFloat();
					coro.astack.length --;
					coro.pc ++;
					break;
				case ConvertAnyToString:
					coro.sstack ~= coro.astack[$ - 1].getString();
					coro.astack.length --;
					coro.pc ++;
					break;
                case ConvertAnyToArray:
					coro.nstack ~= coro.astack[$ - 1].getArray();
					coro.astack.length --;
					coro.pc ++;
					break;
				case Equal_Int:
					coro.istack[$ - 2] = coro.istack[$ - 2] == coro.istack[$ - 1];
					coro.istack.length --;
					coro.pc ++;
					break;
				case Equal_Float:
					coro.istack ~= coro.fstack[$ - 2] == coro.fstack[$ - 1];
					coro.fstack.length -= 2;
					coro.pc ++;
					break;
				case Equal_String:
					coro.istack ~= coro.sstack[$ - 2] == coro.sstack[$ - 1];
					coro.sstack.length -= 2;
					coro.pc ++;
					break;
				//Equal_Any
				case NotEqual_Int:
					coro.istack[$ - 2] = coro.istack[$ - 2] != coro.istack[$ - 1];
					coro.istack.length --;
					coro.pc ++;
					break;
				case NotEqual_Float:
					coro.istack ~= coro.fstack[$ - 2] != coro.fstack[$ - 1];
					coro.fstack.length -= 2;
					coro.pc ++;
					break;
				case NotEqual_String:
					coro.istack ~= coro.sstack[$ - 2] != coro.sstack[$ - 1];
					coro.sstack.length -= 2;
					coro.pc ++;
					break;
				//NotEqual_Any
				case GreaterOrEqual_Int:
					coro.istack[$ - 2] = coro.istack[$ - 2] >= coro.istack[$ - 1];
					coro.istack.length --;
					coro.pc ++;
					break;
				case GreaterOrEqual_Float:
					coro.istack ~= coro.fstack[$ - 2] >= coro.fstack[$ - 1];
					coro.fstack.length -= 2;
					coro.pc ++;
					break;
					//Any
				case LesserOrEqual_Int:
					coro.istack[$ - 2] = coro.istack[$ - 2] <= coro.istack[$ - 1];
					coro.istack.length --;
					coro.pc ++;
					break;
				case LesserOrEqual_Float:
					coro.istack ~= coro.fstack[$ - 2] <= coro.fstack[$ - 1];
					coro.fstack.length -= 2;
					coro.pc ++;
					break;
					//any
				case GreaterInt:
					coro.istack[$ - 2] = coro.istack[$ - 2] > coro.istack[$ - 1];
					coro.istack.length --;
					coro.pc ++;
					break;
				case GreaterFloat:
					coro.istack ~= coro.fstack[$ - 2] > coro.fstack[$ - 1];
					coro.fstack.length -= 2;
					coro.pc ++;
					break;
					//any
				case LesserInt:
					coro.istack[$ - 2] = coro.istack[$ - 2] < coro.istack[$ - 1];
					coro.istack.length --;
					coro.pc ++;
					break;
				case LesserFloat:
					coro.istack ~= coro.fstack[$ - 2] < coro.fstack[$ - 1];
					coro.fstack.length -= 2;
					coro.pc ++;
					break;
					//any
				case AndInt:
					coro.istack[$ - 2] = coro.istack[$ - 2] && coro.istack[$ - 1];
					coro.istack.length --;
					coro.pc ++;
					break;
				case OrInt:
					coro.istack[$ - 2] = coro.istack[$ - 2] || coro.istack[$ - 1];
					coro.istack.length --;
					coro.pc ++;
					break;
				case NotInt:
					coro.istack[$ - 1] = !coro.istack[$ - 1];
					coro.pc ++;
					break;
					//any
				case AddInt:
					coro.istack[$ - 2] += coro.istack[$ - 1];
					coro.istack.length --;
					coro.pc ++;
					break;
				case AddFloat:
					coro.fstack[$ - 2] += coro.fstack[$ - 1];
					coro.fstack.length --;
					coro.pc ++;
					break;
				case AddAny:
					coro.astack[$ - 2] += coro.astack[$ - 1];
					coro.astack.length --;
					coro.pc ++;
					break;
				case ConcatenateString:
					coro.sstack[$ - 2] ~= coro.sstack[$ - 1];
					coro.sstack.length --;
					coro.pc ++;
					break;
				case ConcatenateAny:
					coro.astack[$ - 2] ~= coro.astack[$ - 1];
					coro.astack.length --;
					coro.pc ++;
					break;
				case SubstractInt:
					coro.istack[$ - 2] -= coro.istack[$ - 1];
					coro.istack.length --;
					coro.pc ++;
					break;
				case SubstractFloat:
					coro.fstack[$ - 2] -= coro.fstack[$ - 1];
					coro.fstack.length --;
					coro.pc ++;
					break;
				case SubstractAny:
					coro.astack[$ - 2] -= coro.astack[$ - 1];
					coro.astack.length --;
					coro.pc ++;
					break;
				case MultiplyInt:
					coro.istack[$ - 2] *= coro.istack[$ - 1];
					coro.istack.length --;
					coro.pc ++;
					break;
				case MultiplyFloat:
					coro.fstack[$ - 2] *= coro.fstack[$ - 1];
					coro.fstack.length --;
					coro.pc ++;
					break;
				case MultiplyAny:
					coro.astack[$ - 2] *= coro.astack[$ - 1];
					coro.astack.length --;
					coro.pc ++;
					break;
				case DivideInt:
					coro.istack[$ - 2] /= coro.istack[$ - 1];
					coro.istack.length --;
					coro.pc ++;
					break;
				case DivideFloat:
					coro.fstack[$ - 2] /= coro.fstack[$ - 1];
					coro.fstack.length --;
					coro.pc ++;
					break;
				case DivideAny:
					coro.astack[$ - 2] /= coro.astack[$ - 1];
					coro.astack.length --;
					coro.pc ++;
					break;
				case RemainderInt:
					coro.istack[$ - 2] %= coro.istack[$ - 1];
					coro.istack.length --;
					coro.pc ++;
					break;
				case RemainderFloat:
					coro.fstack[$ - 2] %= coro.fstack[$ - 1];
					coro.fstack.length --;
					coro.pc ++;
					break;
				case RemainderAny:
					coro.astack[$ - 2] %= coro.astack[$ - 1];
					coro.astack.length --;
					coro.pc ++;
					break;
				case NegativeInt:
					coro.istack[$ - 1] = -coro.istack[$ - 1];
					coro.pc ++;
					break;
				case NegativeFloat:
					coro.fstack[$ - 1] = -coro.fstack[$ - 1];
					coro.pc ++;
					break;
				case NegativeAny:
					coro.astack[$ - 1] = -coro.astack[$ - 1];
					coro.pc ++;
					break;
				case IncrementInt:
					coro.istack[$ - 1] ++;
					coro.pc ++;
					break;
				case IncrementFloat:
					coro.fstack[$ - 1] += 1f;
					coro.pc ++;
					break;
				case IncrementAny:
					coro.astack[$ - 1] ++;
					coro.pc ++;
					break;
				case DecrementInt:
					coro.istack[$ - 1] --;
					coro.pc ++;
					break;
				case DecrementFloat:
					coro.fstack[$ - 1] -= 1f;
					coro.pc ++;
					break;
				case DecrementAny:
					coro.astack[$ - 1] --;
					coro.pc ++;
					break;
				case LocalStore_upIterator:
					if(coro.istack[$ - 1] < 0)
						coro.istack[$ - 1] = 0;
					coro.istack[$ - 1] ++;
					coro.pc ++;
					break;
				case Return:
                    //Check for deferred calls.
                    if(coro.deferStack[$ - 1].length) {
                        //Pop the last defer and run it.
                        coro.pc = coro.deferStack[$ - 1][$ - 1];
                        coro.deferStack[$ - 1].length --;
                    }
                    else {
                        //Pop the defer scope.
                        coro.deferStack.length --;

                        //Then returns to the last context.
                        coro.stackPos -= 2;
                        coro.pc = coro.callStack[coro.stackPos + 1u];
                        coro.valuesPos -= coro.callStack[coro.stackPos];
                    }
					break;
                case Unwind:
                    //Check for deferred calls.
                    if(coro.deferStack[$ - 1].length) {
                        //Pop the next defer and run it.
                        coro.pc = coro.deferStack[$ - 1][$ - 1];
                        coro.deferStack[$ - 1].length --;
                    }
                    else if(coro.isKilled) {
                        if(coro.stackPos) {
                            //Pop the defer scope.
                            coro.deferStack.length --;

                            //Then returns to the last context without modifying the pc.
                            coro.stackPos -= 2;
                            coro.valuesPos -= coro.callStack[coro.stackPos];
                        }
                        else {
                            //Every deferred call has been executed, now die.
                            _coroutines.markInternalForRemoval(index);
					        continue coroutinesLabel;
                        }
                    }
                    else {
                        //Pop the defer scope.
                        coro.deferStack.length --;

                        //Then returns to the last context.
                        coro.stackPos -= 2;
                        coro.pc = coro.callStack[coro.stackPos + 1u];
                        coro.valuesPos -= coro.callStack[coro.stackPos];
                    }
                    break;
                case Defer:
                    coro.deferStack[$ - 1] ~= coro.pc + grBytecode_getSignedValue(opcode);
					coro.pc ++;
                    break;
				case LocalStack:
                    auto stackSize = grBytecode_getUnsignedValue(opcode);
					coro.callStack[coro.stackPos] = stackSize;
                    stackSize = coro.valuesPos + stackSize;
                    coro.ivalues.length = stackSize;
                    coro.fvalues.length = stackSize;
                    coro.svalues.length = stackSize;
                    coro.nvalues.length = stackSize;
                    coro.avalues.length = stackSize;
                    coro.ovalues.length = stackSize;
                    coro.deferStack.length ++;
					coro.pc ++;
					break;
				case Call:
					coro.valuesPos += coro.callStack[coro.stackPos];
					coro.callStack[coro.stackPos + 1u] = coro.pc + 1u;
					coro.stackPos += 2;
					coro.pc = grBytecode_getUnsignedValue(opcode);
					break;
				case AnonymousCall:
					coro.valuesPos += coro.callStack[coro.stackPos];
					coro.callStack[coro.stackPos + 1u] = coro.pc + 1u;
					coro.stackPos += 2;
					coro.pc = coro.istack[$ - 1];
					coro.istack.length --;
					break;
				case PrimitiveCall:
					primitives[grBytecode_getUnsignedValue(opcode)].callback(coro);
					coro.pc ++;
					break;
				case Jump:
					coro.pc += grBytecode_getSignedValue(opcode);
					break;
				case JumpEqual:
					if(coro.istack[$ - 1])
						coro.pc ++;
					else
						coro.pc += grBytecode_getSignedValue(opcode);
					coro.istack.length --;
					break;
				case JumpNotEqual:
					if(coro.istack[$ - 1])
						coro.pc += grBytecode_getSignedValue(opcode);
					else
						coro.pc ++;
					coro.istack.length --;
					break;
                case ArrayBuild:
                    GrDynamicValue[] ary;
                    const auto arySize = grBytecode_getUnsignedValue(opcode);
                    for(int i = arySize; i > 0; i --) {
                        ary ~= coro.astack[$ - i];
                    }
                    coro.astack.length -= arySize;
                    coro.nstack ~= ary;
                    coro.pc ++;
                    break;
				case ArrayLength:
					coro.istack ~= cast(int)coro.nstack[$ - 1].length;
                    coro.nstack.length --;
					coro.pc ++;
					break;
				case ArrayIndex:
					coro.astack ~= coro.nstack[$ - 1][coro.istack[$ - 1]];
					coro.nstack.length --;					
					coro.istack.length --;					
					coro.pc ++;
					break;
                case ArrayIndexRef:
                    coro.astack[$ - 1].setArrayIndex(coro.istack[$ - 1]);
                    coro.istack.length --;
					coro.pc ++;
					break;
				default:
					throw new Exception("Invalid instruction");
				}
			}
		}
		_coroutines.sweepMarkedData();
    }
}