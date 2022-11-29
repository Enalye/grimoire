/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.compiler.parser;

import std.stdio;
import std.format;
import std.string;
import std.array;
import std.conv;
import std.math;
import std.file;
import std.meta;

import grimoire.runtime;
import grimoire.assembly;
import grimoire.compiler.util;
import grimoire.compiler.lexer;
import grimoire.compiler.mangle;
import grimoire.compiler.type;
import grimoire.compiler.constraint;
import grimoire.compiler.primitive;
import grimoire.compiler.data;
import grimoire.compiler.pretty;
import grimoire.compiler.error;

/// Le parseur analyse les lexèmes produits par l’analyseur lexical et génère
/// les instructions qui seront liés ensuite par le compilateur.
final class GrParser {
    package {
        GrInt[] iconsts;
        GrFloat[] rconsts;
        GrStringValue[] sconsts;

        uint scopeLevel;

        GrVariable[] globalVariables;
        GrFunction[] instanciatedFunctions, functionsQueue, functions, events;
        GrFunction[] anonymousFunctions;
        GrTemplateFunction[] templatedFunctions;

        uint current;
        GrFunction currentFunction;
        GrFunction[] functionStack;
        GrFunctionCall[] functionCalls;

        uint[][] breaksJumps;
        uint[][] continuesJumps;
        uint[] continuesDestinations;
        bool[] continuesUseYield;

        GrLexeme[] lexemes;

        uint globalsCount;

        GrLocale _locale;
    }

    private {
        GrData _data;
        bool _isAssignationOptimizable;
        int _options;

        bool _mustDeferClassDeclaration;
        GrClassDefinition[] _deferredClassDeclarations;
    }

    this(GrLocale locale) {
        _locale = locale;
    }

    /// Revient au début de la séquence
    private void reset() {
        current = 0u;
    }

    /// Avance jusqu’au prochain lexème
    private void advance() {
        do {
            if (current < lexemes.length)
                current++;
        }
        while (current < lexemes.length && lexemes[current].type == GrLexeme.Type.nothing);
    }

    /// Retourne au dernier lexème
    private void goBack() {
        do {
            if (current > 0u)
                current--;
        }
        while (current > 0 && lexemes[current].type == GrLexeme.Type.nothing);
    }

    /// Vérifie si on est en fin de séquence, et avance au prochain lexème
    private bool checkAdvance() {
        if (isEnd())
            return false;

        advance();
        return true;
    }

    /// Début d’un bloc
    private void openBlock() {
        scopeLevel++;
        if (currentFunction)
            currentFunction.openScope();
    }

    /// Fin d’un bloc
    private void closeBlock() {
        scopeLevel--;
        if (currentFunction)
            currentFunction.closeScope();
    }

    /// Vérifie la fin de la séquence
    private bool isEnd(int offset = 0) {
        return (current + offset) >= cast(uint) lexemes.length;
    }

    /// Se place à un endroit arbitraire de la séquence
    private void set(uint position_) {
        current = position_;
        if (current < 0 || current >= cast(uint) lexemes.length) {
            current = 0;
        }
    }

    /// Renvoie le lexème de la position actuelle
    private GrLexeme get(int offset = 0) {
        const uint position = current + offset;
        if (position < 0 || position >= cast(uint) lexemes.length) {
            logError(getError(Error.eofReached), getError(Error.eof));
        }
        return lexemes[position];
    }

    /// Enregistre un nouvel entier et retourne son id
    private uint registerIntConstant(GrInt value) {
        foreach (size_t index, GrInt iconst; iconsts) {
            if (iconst == value)
                return cast(uint) index;
        }
        iconsts ~= value;
        return cast(uint) iconsts.length - 1;
    }

    /// Enregistre un nouveau flottant et retourne son id
    private uint registerFloatConstant(GrFloat value) {
        foreach (size_t index, GrFloat fconst; rconsts) {
            if (fconst == value)
                return cast(uint) index;
        }
        rconsts ~= value;
        return cast(uint) rconsts.length - 1;
    }

    /// Enregistre une nouvelle chaîne de caractères et retourne son id
    private uint registerStringConstant(GrStringValue value) {
        foreach (size_t index, GrStringValue sconst; sconsts) {
            if (sconst == value)
                return cast(uint) index;
        }
        sconsts ~= value;
        return cast(uint) sconsts.length - 1;
    }

    /// Enregistre une variable locale spéciale, utilisé par ex. pour les itérateurs
    private GrVariable registerSpecialVariable(string name, GrType type) {
        name = "~" ~ name;
        GrVariable specialVariable = registerVariable(name, type, false, false, false, false);
        specialVariable.isAuto = false;
        specialVariable.isInitialized = true; //We shortcut this check
        return specialVariable;
    }

    /// Enregistre une nouvelle variable
    private GrVariable registerVariable(string name, GrType type, bool isAuto,
        bool isGlobal, bool isConst, bool isPublic) {

        assertNoGlobalDeclaration(name, get().fileId, isPublic);

        GrVariable variable = new GrVariable;
        variable.isAuto = isAuto;
        variable.isGlobal = isGlobal;
        variable.isInitialized = false;
        variable.type = type;
        variable.isConst = isConst;
        variable.name = name;
        variable.isPublic = isPublic;
        variable.fileId = get().fileId;
        variable.lexPosition = current;

        if (!isAuto)
            setVariableRegister(variable);

        if (isGlobal)
            globalVariables ~= variable;
        else
            currentFunction.setLocal(variable);

        return variable;
    }

    private GrVariable getGlobalVariable(string name, uint fileId, bool isPublic = false) {
        foreach (GrVariable variable; globalVariables) {
            if (variable.name == name && (variable.fileId == fileId || variable.isPublic || isPublic))
                return variable;
        }
        return null;
    }

    private void assertNoGlobalDeclaration(string name, uint fileId, bool isPublic) {
        GrVariable variable;
        GrFunction func;
        if ((variable = getGlobalVariable(name, fileId, isPublic)) !is null)
            logError(format(getError(Error.nameXDefMultipleTimes), name),
                format(getError(Error.xRedefHere), name), "", 0,
                format(getError(Error.prevDefOfX), name), variable.lexPosition);
        if (_data.isPrimitiveDeclared(name))
            logError(format(getError(Error.nameXDefMultipleTimes), name),
                format(getError(Error.prevDefPrim), name));
        if ((func = getFunction(name, fileId, isPublic)) !is null)
            logError(format(getError(Error.nameXDefMultipleTimes), name),
                format(getError(Error.xRedefHere), name), "", 0,
                format(getError(Error.prevDefOfX), name), func.lexPosition);
        if ((func = getEvent(name)) !is null)
            logError(format(getError(Error.nameXDefMultipleTimes), name),
                format(getError(Error.xRedefHere), name), "", 0,
                format(getError(Error.prevDefOfX), name), func.lexPosition);
    }

    private void setVariableRegister(GrVariable variable) {
        final switch (variable.type.base) with (GrType.Base) {
        case int_:
        case bool_:
        case func:
        case task:
        case event:
        case enum_:
        case float_:
        case string_:
        case optional:
        case list:
        case class_:
        case native:
        case channel:
            if (variable.isGlobal) {
                variable.register = globalsCount;
                globalsCount++;
            }
            else {
                if (currentFunction.registerAvailables.length) {
                    variable.register = currentFunction.registerAvailables[$ - 1];
                    currentFunction.registerAvailables.length--;
                }
                else {
                    variable.register = currentFunction.localsCount;
                    currentFunction.localsCount++;
                }
            }
            break;
        case internalTuple:
        case reference:
        case null_:
        case void_:
            logError(format(getError(Error.cantDefVarOfTypeX),
                    getPrettyType(variable.type)), getError(Error.invalidType));
            break;
        }
    }

    private void beginGlobalScope() {
        GrFunction globalScope = getFunction("@global", 0);
        if (globalScope) {
            functionStack ~= currentFunction;
            currentFunction = globalScope;
        }
        else {
            GrFunction func = new GrFunction;
            func.name = "@global";
            func.mangledName = func.name;
            func.isTask = false;
            func.inSignature = [];
            func.outSignature = [];
            func.isPublic = true;
            func.fileId = 0;
            func.lexPosition = 0;
            functions ~= func;
            functionStack ~= currentFunction;
            currentFunction = func;
        }
    }

    private void endGlobalScope() {
        if (!functionStack.length)
            throw new Exception("global scope mismatch");

        currentFunction = functionStack[$ - 1];
        functionStack.length--;
    }

    private void beginFunction(string name, uint fileId, GrType[] signature, bool isEvent = false) {
        const string mangledName = grMangleComposite(name, signature);

        GrFunction func;
        if (isEvent)
            func = getEvent(mangledName);
        else
            func = getFunction(mangledName, fileId);

        if (func is null)
            logError(format(getError(Error.xNotDef), name), getError(Error.unknownFunc));

        functionStack ~= currentFunction;
        currentFunction = func;
    }

    private void preBeginFunction(string name, uint fileId, GrType[] signature,
        string[] inputVariables, bool isTask, GrType[] outSignature = [],
        bool isAnonymous = false, bool isEvent = false, bool isPublic = false) {
        GrFunction func = new GrFunction;
        func.isTask = isTask;
        func.isEvent = isEvent;
        func.inputVariables = inputVariables;
        func.inSignature = signature;
        func.outSignature = outSignature;
        func.fileId = fileId;

        if (isAnonymous) {
            func.anonParent = currentFunction;
            func.anonReference = cast(uint) currentFunction.instructions.length;
            func.name = currentFunction.name ~ "@anon" ~ to!string(func.index);
            func.mangledName = grMangleComposite(func.name, func.inSignature);
            anonymousFunctions ~= func;
            func.lexPosition = current;

            // Remplacé par l’adresse de la fonction dans `solveFunctionCalls()`
            addInstruction(GrOpcode.const_int, 0u);
        }
        else {
            func.name = name;
            func.isPublic = isPublic;

            func.mangledName = grMangleComposite(name, signature);
            assertNoGlobalDeclaration(func.mangledName, fileId, isPublic);

            func.lexPosition = current;
            functionsQueue ~= func;
        }

        functionStack ~= currentFunction;
        currentFunction = func;
        generateFunctionInputs();
    }

    private void endFunction() {
        int prependInstructionCount;
        if (_options & GrOption.profile) {
            prependInstructionCount++;
            const uint index = registerStringConstant(getPrettyFunction(currentFunction));
            addInstructionInFront(GrOpcode.debugProfileBegin, index);
        }

        if (currentFunction.localsCount > 0) {
            addInstructionInFront(GrOpcode.localStack, currentFunction.localsCount);
            prependInstructionCount++;
        }

        foreach (call; currentFunction.functionCalls)
            call.position += prependInstructionCount;

        currentFunction.offset += prependInstructionCount;

        if (!functionStack.length)
            throw new Exception("attempting to close a non-existing function");

        currentFunction = functionStack[$ - 1];
        functionStack.length--;
    }

    private void preEndFunction() {
        if (!functionStack.length)
            throw new Exception("attempting to close a non-existing function");
        currentFunction = functionStack[$ - 1];
        functionStack.length--;
    }

    /// Génère les opcodes pour récupérer les paramètres de la fonction
    void generateFunctionInputs() {
        void fetchParameter(string name, GrType type) {
            final switch (type.base) with (GrType.Base) {
            case void_:
            case null_:
                logError(format(getError(Error.cantUseTypeAsParam),
                        getPrettyType(type)), getError(Error.invalidParamType));
                break;
            case int_:
            case bool_:
            case func:
            case task:
            case event:
            case enum_:
            case float_:
            case string_:
            case optional:
            case list:
            case native:
            case class_:
            case channel:
            case reference:
                currentFunction.nbParameters++;
                if (currentFunction.isTask && !currentFunction.isEvent)
                    addInstruction(GrOpcode.globalPop, 0u);
                break;
            case internalTuple:
                throw new Exception("tuples are not allowed here");
            }

            GrVariable newVar = new GrVariable;
            newVar.type = type;
            newVar.isInitialized = true;
            newVar.isGlobal = false;
            newVar.name = name;
            newVar.fileId = get().fileId;
            newVar.lexPosition = current;
            currentFunction.setLocal(newVar);
            setVariableRegister(newVar);
            addSetInstruction(newVar, currentFunction.fileId, grVoid, false, true);
        }

        foreach_reverse (size_t i, inputVariable; currentFunction.inputVariables) {
            fetchParameter(currentFunction.inputVariables[i], currentFunction.inSignature[i]);
        }
    }

    GrFunction getFunction(string mangledName, uint fileId = 0, bool isPublic = false) {
        foreach (GrFunction func; functions) {
            if (func.mangledName == mangledName && (func.fileId == fileId ||
                    func.isPublic || isPublic)) {
                return func;
            }
        }
        foreach (GrFunction func; events) {
            if (func.mangledName == mangledName) {
                return func;
            }
        }
        return null;
    }

    auto getFirstMatchingFuncOrPrim(string name, GrType[] signature,
        uint fileId = 0, bool isPublic = false) {
        struct Result {
            GrPrimitive prim;
            GrFunction func;
        }

        void assertSignaturePurity(GrType[] funcSignature) {
            for (int i; i < signature.length; ++i) {
                final switch (signature[i].base) with (GrType.Base) {
                case void_:
                case null_:
                case int_:
                case float_:
                case bool_:
                case enum_:
                case func:
                case task:
                case event:
                case internalTuple:
                    continue;
                case string_:
                case optional:
                case list:
                case class_:
                case native:
                case channel:
                case reference:
                    if (signature[i].isPure && !funcSignature[i].isPure) {
                        logError(format(getError(Error.cantCallXWithArgsYBecausePure),
                                grGetPrettyFunctionCall(name, funcSignature),
                                grGetPrettyFunctionCall("", signature)),
                            getError(Error.callCanCauseASideEffect),
                            getError(Error.maybeUsePure), -1);
                    }
                    continue;
                }
            }
        }

        Result result;

        const string mangledName = grMangleComposite(name, signature);
        result.prim = _data.getPrimitive(mangledName);
        if (result.prim) {
            assertSignaturePurity(result.prim.inSignature);
            return result;
        }

        foreach (GrFunction func; functions) {
            if (func.mangledName == mangledName && (func.fileId == fileId ||
                    func.isPublic || isPublic)) {
                result.func = func;
                assertSignaturePurity(result.func.inSignature);
                return result;
            }
        }
        foreach (GrFunction func; functionsQueue) {
            if (func.mangledName == mangledName && (func.fileId == fileId ||
                    func.isPublic || isPublic)) {
                result.func = func;
                assertSignaturePurity(result.func.inSignature);
                return result;
            }
        }
        foreach (GrFunction func; instanciatedFunctions) {
            if (func.mangledName == mangledName && (func.fileId == fileId ||
                    func.isPublic || isPublic)) {
                functionsQueue ~= func;

                functionStack ~= currentFunction;
                currentFunction = func;
                generateFunctionInputs();
                currentFunction = functionStack[$ - 1];
                functionStack.length--;

                result.func = func;
                assertSignaturePurity(result.func.inSignature);
                return result;
            }
        }

        result.prim = _data.getCompatiblePrimitive(name, signature);
        if (result.prim) {
            assertSignaturePurity(result.prim.inSignature);
            return result;
        }

        foreach (GrFunction func; functions) {
            if (func.name == name && (func.fileId == fileId || func.isPublic || isPublic)) {
                if (_data.isSignatureCompatible(signature, func.inSignature,
                        false, fileId, isPublic)) {
                    result.func = func;
                    assertSignaturePurity(result.func.inSignature);
                    return result;
                }
            }
        }
        foreach (GrFunction func; functionsQueue) {
            if (func.name == name && (func.fileId == fileId || func.isPublic || isPublic)) {
                if (_data.isSignatureCompatible(signature, func.inSignature,
                        false, fileId, isPublic)) {
                    result.func = func;
                    assertSignaturePurity(result.func.inSignature);
                    return result;
                }
            }
        }

        foreach (GrFunction func; instanciatedFunctions) {
            if (func.name == name && (func.fileId == fileId || func.isPublic || isPublic)) {
                if (_data.isSignatureCompatible(signature, func.inSignature,
                        false, fileId, isPublic)) {
                    functionsQueue ~= func;

                    functionStack ~= currentFunction;
                    currentFunction = func;
                    generateFunctionInputs();
                    currentFunction = functionStack[$ - 1];
                    functionStack.length--;

                    result.func = func;
                    assertSignaturePurity(result.func.inSignature);
                    return result;
                }
            }
        }

        result.prim = _data.getAbstractPrimitive(name, signature);
        if (result.prim) {
            assertSignaturePurity(result.prim.inSignature);
            return result;
        }

        __functionLoop: foreach (GrTemplateFunction temp; templatedFunctions) {
            if (temp.name == name && (temp.fileId == fileId || temp.isPublic || isPublic)) {
                GrAnyData anyData = new GrAnyData;
                _data.setAnyData(anyData);

                if (_data.isSignatureCompatible(signature, temp.inSignature,
                        true, fileId, isPublic)) {
                    foreach (GrConstraint constraint; temp.constraints) {
                        if (!constraint.evaluate(_data, anyData))
                            continue __functionLoop;
                    }
                    GrType[] templateSignature;
                    for (int i; i < temp.templateVariables.length; ++i) {
                        templateSignature ~= anyData.get(temp.templateVariables[i]);
                    }
                    GrFunction func = parseTemplatedFunctionDeclaration(temp, templateSignature);
                    functionsQueue ~= func;

                    functionStack ~= currentFunction;
                    currentFunction = func;
                    generateFunctionInputs();
                    currentFunction = functionStack[$ - 1];
                    functionStack.length--;

                    result.func = func;
                    assertSignaturePurity(result.func.inSignature);
                    return result;
                }
            }
        }

        return result;
    }

    GrFunction getFunction(string name, GrType[] signature, uint fileId = 0, bool isPublic = false) {
        const string mangledName = grMangleComposite(name, signature);

        foreach (GrFunction func; events) {
            if (func.mangledName == mangledName) {
                return func;
            }
        }

        foreach (GrFunction func; functions) {
            if (func.mangledName == mangledName && (func.fileId == fileId ||
                    func.isPublic || isPublic)) {
                return func;
            }
        }
        foreach (GrFunction func; functions) {
            if (func.name == name && (func.fileId == fileId || func.isPublic || isPublic)) {
                if (_data.isSignatureCompatible(signature, func.inSignature,
                        false, fileId, isPublic))
                    return func;
            }
        }
        foreach (GrFunction func; functionsQueue) {
            if (func.mangledName == mangledName && (func.fileId == fileId ||
                    func.isPublic || isPublic)) {
                return func;
            }
        }
        foreach (GrFunction func; functionsQueue) {
            if (func.name == name && (func.fileId == fileId || func.isPublic || isPublic)) {
                if (_data.isSignatureCompatible(signature, func.inSignature,
                        false, fileId, isPublic))
                    return func;
            }
        }
        foreach (GrFunction func; instanciatedFunctions) {
            if (func.mangledName == mangledName && (func.fileId == fileId ||
                    func.isPublic || isPublic)) {
                functionsQueue ~= func;

                functionStack ~= currentFunction;
                currentFunction = func;
                generateFunctionInputs();
                currentFunction = functionStack[$ - 1];
                functionStack.length--;

                return func;
            }
        }
        foreach (GrFunction func; instanciatedFunctions) {
            if (func.name == name && (func.fileId == fileId || func.isPublic || isPublic)) {
                if (_data.isSignatureCompatible(signature, func.inSignature,
                        false, fileId, isPublic)) {
                    functionsQueue ~= func;

                    functionStack ~= currentFunction;
                    currentFunction = func;
                    generateFunctionInputs();
                    currentFunction = functionStack[$ - 1];
                    functionStack.length--;

                    return func;
                }
            }
        }

        __functionLoop: foreach (GrTemplateFunction temp; templatedFunctions) {
            if (temp.name == name && (temp.fileId == fileId || temp.isPublic || isPublic)) {
                GrAnyData anyData = new GrAnyData;
                _data.setAnyData(anyData);
                if (_data.isSignatureCompatible(signature, temp.inSignature,
                        true, fileId, isPublic)) {
                    foreach (GrConstraint constraint; temp.constraints) {
                        if (!constraint.evaluate(_data, anyData))
                            continue __functionLoop;
                    }
                    GrType[] templateSignature;
                    for (int i; i < temp.templateVariables.length; ++i) {
                        templateSignature ~= anyData.get(temp.templateVariables[i]);
                    }
                    GrFunction func = parseTemplatedFunctionDeclaration(temp, templateSignature);
                    functionsQueue ~= func;

                    functionStack ~= currentFunction;
                    currentFunction = func;
                    generateFunctionInputs();
                    currentFunction = functionStack[$ - 1];
                    functionStack.length--;

                    return func;
                }
            }
        }
        return null;
    }

    /// Supprime une fonction déclarée
    void removeFunction(string name) {
        import std.algorithm : remove;

        for (int i; i < functions.length; ++i) {
            if (functions[i].mangledName == name) {
                functions = remove(functions, i);
                return;
            }
        }
    }

    private GrFunction getEvent(string name) {
        foreach (GrFunction func; events) {
            if (func.mangledName == name)
                return func;
        }
        return null;
    }

    private GrFunction getAnonymousFunction(string name) {
        foreach (GrFunction func; anonymousFunctions) {
            if (func.mangledName == name)
                return func;
        }
        return null;
    }

    GrFunction getAnonymousFunction(string name, GrType[] signature, uint fileId) {
        foreach (GrFunction func; anonymousFunctions) {
            if (func.mangledName == name)
                return func;
        }
        foreach (GrFunction func; anonymousFunctions) {
            if (func.name == name) {
                if (_data.isSignatureCompatible(signature, func.inSignature, false, fileId))
                    return func;
            }
        }
        return null;
    }

    /// Récupère une variable déclarée
    private GrVariable getVariable(string name, uint fileId) {
        GrVariable globalVar = getGlobalVariable(name, fileId);
        if (globalVar !is null)
            return globalVar;

        GrVariable localVar = currentFunction.getLocal(name);
        if (!localVar)
            logError(format(getError(Error.xNotDecl), name), getError(Error.unknownVar), "", -1);
        return localVar;
    }

    private void addIntConstant(GrInt value) {
        addInstruction(GrOpcode.const_int, registerIntConstant(value));
    }

    private void addFloatConstant(GrFloat value) {
        addInstruction(GrOpcode.const_float, registerFloatConstant(value));
    }

    private void addBoolConstant(bool value) {
        addInstruction(GrOpcode.const_bool, value);
    }

    private void addStringConstant(GrStringValue value) {
        addInstruction(GrOpcode.const_string, registerStringConstant(value));
    }

    private void addMetaConstant(GrStringValue value) {
        addInstruction(GrOpcode.const_meta, registerStringConstant(value));
    }

    private void addInstruction(GrOpcode opcode, int value = 0, bool isSigned = false) {
        if (currentFunction is null)
            throw new Exception(
                "the expression is located outside of a function, task, or event which is forbidden");

        GrInstruction instruction;
        instruction.opcode = opcode;
        if (isSigned) {
            if ((value >= 0x800000) || (-value >= 0x800000))
                throw new Exception("an opcode's signed value is exceeding limits");
            instruction.value = value + 0x800000;
        }
        else
            instruction.value = value;
        currentFunction.instructions ~= instruction;

        if (_options & GrOption.symbols) {
            generateInstructionSymbol();
        }
    }

    private void addInstructionInFront(GrOpcode opcode, int value = 0, bool isSigned = false) {
        if (currentFunction is null)
            throw new Exception(
                "the expression is located outside of a function, task or event which is forbidden");

        GrInstruction instruction;
        instruction.opcode = opcode;
        if (isSigned) {
            if ((value >= 0x800000) || (-value >= 0x800000))
                throw new Exception("an opcode's signed value is exceeding limits");
            instruction.value = value + 0x800000;
        }
        else
            instruction.value = value;
        currentFunction.instructions = instruction ~ currentFunction.instructions;

        if (_options & GrOption.symbols) {
            generateInstructionSymbol();
        }
    }

    private void generateInstructionSymbol() {
        GrFunction.DebugPositionSymbol symbol;
        int lexPos = (cast(int) current) - 2;
        if (lexPos < 0) {
            lexPos = 0;
        }
        if (lexPos >= cast(uint) lexemes.length) {
            lexPos = cast(uint)((cast(int) lexemes.length) - 1);
        }
        GrLexeme lex = lexemes[lexPos];
        symbol.line = lex.line + 1;
        symbol.column = lex.column;
        currentFunction.debugSymbol ~= symbol;
    }

    private void setInstruction(GrOpcode opcode, uint index, int value = 0u, bool isSigned = false) {
        if (currentFunction is null)
            throw new Exception(
                "the expression is located outside of a function, task or event which is forbidden");

        if (index >= currentFunction.instructions.length)
            throw new Exception("an instruction's index is exeeding the function size");

        GrInstruction instruction;
        instruction.opcode = opcode;
        if (isSigned) {
            if ((value >= 0x800000) || (-value >= 0x800000))
                throw new Exception("an opcode's signed value is exceeding limits");
            instruction.value = value + 0x800000;
        }
        else
            instruction.value = value;
        currentFunction.instructions[index] = instruction;
    }

    private bool isBinaryOperator(GrLexeme.Type lexType) {
        if (lexType >= GrLexeme.Type.bitwiseAnd && lexType <= GrLexeme.Type.arrow)
            return true;
        else if (lexType == GrLexeme.Type.send)
            return true;
        else
            return false;
    }

    private bool isUnaryOperator(GrLexeme.Type lexType) {
        if (lexType >= GrLexeme.Type.plus && lexType <= GrLexeme.Type.minus)
            return true;
        else if (lexType >= GrLexeme.Type.increment && lexType <= GrLexeme.Type.decrement)
            return true;
        else if (lexType == GrLexeme.Type.not || lexType == GrLexeme.Type.bitwiseNot)
            return true;
        else if (lexType == GrLexeme.Type.receive)
            return true;
        else
            return false;
    }

    private GrType addCustomBinaryOperator(GrLexeme.Type lexType,
        GrType leftType, GrType rightType, uint fileId) {
        string name = "@operator_" ~ getPrettyLexemeType(lexType);
        GrType[] signature = [leftType, rightType];

        // primitive
        auto matching = getFirstMatchingFuncOrPrim(name, signature, fileId);
        if (matching.prim) {
            addInstruction(GrOpcode.primitiveCall, matching.prim.index);
            if (matching.prim.outSignature.length != 1uL) {
                logError(getError(Error.opMustHave1RetVal), format(getError(matching.prim.outSignature.length > 1 ?
                        Error.expected1RetValFoundX : Error.expected1RetValFoundXs),
                        matching.prim.outSignature.length));
            }
            return matching.prim.outSignature[0];
        }

        // fonction
        if (matching.func) {
            auto outSignature = addFunctionCall(matching.func, fileId);
            if (outSignature.length != 1uL) {
                logError(getError(Error.opMustHave1RetVal), format(getError(matching.func.outSignature.length > 1 ?
                        Error.expected1RetValFoundX : Error.expected1RetValFoundXs),
                        matching.func.outSignature.length));
            }
            return outSignature[0];
        }

        return grVoid;
    }

    private GrType addCustomUnaryOperator(GrLexeme.Type lexType, const GrType type, uint fileId) {
        string name = "@operator_" ~ getPrettyLexemeType(lexType);
        GrType[] signature = [type];

        // primitive
        auto matching = getFirstMatchingFuncOrPrim(name, signature, fileId);
        if (matching.prim) {
            addInstruction(GrOpcode.primitiveCall, matching.prim.index);
            if (matching.prim.outSignature.length != 1uL) {
                logError(getError(Error.opMustHave1RetVal), format(getError(matching.prim.outSignature.length > 1 ?
                        Error.expected1RetValFoundX : Error.expected1RetValFoundXs),
                        matching.prim.outSignature.length));
            }
            return matching.prim.outSignature[0];
        }

        // fonction
        if (matching.func) {
            auto outSignature = addFunctionCall(matching.func, fileId);
            if (outSignature.length != 1uL) {
                logError(getError(Error.opMustHave1RetVal), format(getError(matching.func.outSignature.length > 1 ?
                        Error.expected1RetValFoundX : Error.expected1RetValFoundXs),
                        matching.func.outSignature.length));
            }
            return outSignature[0];
        }

        return grVoid;
    }

    private GrType addBinaryOperator(GrLexeme.Type lexType, GrType leftType,
        GrType rightType, uint fileId) {
        if (leftType.base == GrType.Base.internalTuple || rightType.base ==
            GrType.Base.internalTuple)
            logError(getError(Error.cantUseOpOnMultipleVal), getError(Error.exprYieldsMultipleVal));
        GrType resultType = GrType.Base.void_;

        if (lexType != GrLexeme.Type.optionalOr) {
            if (leftType.base == GrType.Base.optional && rightType.base != GrType.Base.optional) {
                rightType = grOptional(rightType);
            }
            else if (rightType.base == GrType.Base.optional && leftType.base != GrType
                .Base.optional) {
                leftType = grOptional(leftType);
            }
        }

        if (lexType == GrLexeme.Type.optionalOr && leftType.base == GrType.Base.optional) {
            GrType optionalType = grUnmangle(leftType.mangledType);
            if (rightType.base == GrType.Base.optional)
                convertType(rightType, leftType, fileId);
            else
                convertType(rightType, optionalType, fileId);
            addInstruction(GrOpcode.optionalOr);
            resultType = rightType;
        }
        else if (leftType.base == GrType.Base.enum_ && rightType.base == GrType.Base.enum_ &&
            leftType.mangledType == rightType.mangledType) {
            resultType = addInternalOperator(lexType, leftType);
        }
        else if (leftType.base == GrType.Base.channel) {
            GrType channelType = grUnmangle(leftType.mangledType);
            convertType(rightType, channelType, fileId);
            resultType = addInternalOperator(lexType, leftType);
            if (resultType.base == GrType.Base.void_) {
                resultType = addCustomBinaryOperator(lexType, leftType, rightType, fileId);
            }
        }
        else if (lexType == GrLexeme.Type.concatenate &&
            leftType.base == GrType.Base.list && leftType != rightType) {
            const GrType subType = grUnmangle(leftType.mangledType);
            convertType(rightType, subType, fileId);
            addInstruction(GrOpcode.append_list);
            resultType = leftType;
        }
        else if (lexType == GrLexeme.Type.concatenate &&
            rightType.base == GrType.Base.list && leftType != rightType) {
            const GrType subType = grUnmangle(rightType.mangledType);
            convertType(leftType, subType, fileId);
            addInstruction(GrOpcode.prepend_list);
            resultType = rightType;
        }
        else if (lexType == GrLexeme.Type.concatenate &&
            leftType.base == GrType.Base.string_ && leftType != rightType) {
            convertType(rightType, leftType, fileId);
            resultType = addInternalOperator(lexType, leftType);
        }
        else if (lexType == GrLexeme.Type.concatenate &&
            rightType.base == GrType.Base.string_ && leftType != rightType) {
            convertType(leftType, rightType, fileId);
            resultType = addInternalOperator(lexType, rightType, true);
        }
        else if (leftType.base == GrType.Base.int_ && rightType.base == GrType.Base.float_) {
            // Cas particulier: on a besoin de convertir l’entier en flottant
            // et d’inverser les deux valeurs
            addInstruction(GrOpcode.swap);
            convertType(leftType, rightType, fileId);
            resultType = addInternalOperator(lexType, rightType, true);

            // Puis on cherche un opérateur surchargé
            if (resultType.base == GrType.Base.void_) {
                resultType = addCustomBinaryOperator(lexType, rightType, rightType, fileId);
            }
        }
        else if (leftType != rightType) {
            // On cherche un opérateur surchargé
            resultType = addCustomBinaryOperator(lexType, leftType, rightType, fileId);

            // S’il y en a pas, on tente une conversion, puis on réessaye
            if (resultType.base == GrType.Base.void_) {
                resultType = convertType(rightType, leftType, fileId, true);
                if (resultType.base != GrType.Base.void_) {
                    resultType = addBinaryOperator(lexType, resultType, resultType, fileId);
                }
            }
        }
        else {
            resultType = addInternalOperator(lexType, leftType);
            if (resultType.base == GrType.Base.void_) {
                resultType = addCustomBinaryOperator(lexType, leftType, rightType, fileId);
            }
        }
        if (resultType.base == GrType.Base.void_)
            logError(format(getError(Error.noXBinaryOpDefForYAndZ), getPrettyLexemeType(lexType),
                    getPrettyType(leftType), getPrettyType(rightType)),
                getError(Error.unknownOp), "", -1);
        return resultType;
    }

    private GrType addUnaryOperator(GrLexeme.Type lexType, const GrType type, uint fileId) {
        if (type.base == GrType.Base.internalTuple)
            logError(getError(Error.cantUseOpOnMultipleVal), getError(Error.exprYieldsMultipleVal));
        GrType resultType = GrType.Base.void_;

        resultType = addInternalOperator(lexType, type);
        if (resultType.base == GrType.Base.void_) {
            resultType = addCustomUnaryOperator(lexType, type, fileId);
        }

        if (resultType.base == GrType.Base.void_)
            logError(format(getError(Error.noXUnaryOpDefForY), getPrettyLexemeType(lexType),
                    getPrettyType(type)), getError(Error.unknownOp));
        return resultType;
    }

    private GrType addOperator(GrLexeme.Type lexType, ref GrType[] typeStack, uint fileId) {
        if (isBinaryOperator(lexType)) {
            typeStack[$ - 2] = addBinaryOperator(lexType, typeStack[$ - 2],
                typeStack[$ - 1], fileId);
            typeStack.length--;
            return typeStack[$ - 1];
        }
        else if (isUnaryOperator(lexType)) {
            typeStack[$ - 1] = addUnaryOperator(lexType, typeStack[$ - 1], fileId);
            return typeStack[$ - 1];
        }

        return GrType(GrType.Base.void_);
    }

    private GrType addInternalOperator(GrLexeme.Type lexType, GrType varType, bool isSwapped = false) {
        switch (varType.base) with (GrType.Base) {
        case optional:
            switch (lexType) with (GrLexeme.Type) {
            case not:
                addInstruction(GrOpcode.checkNull);
                addInstruction(GrOpcode.not_int);
                return GrType(GrType.Base.bool_);
            default:
                break;
            }
            break;
        case class_:
        case native:
            switch (lexType) with (GrLexeme.Type) {
            case not:
                addInstruction(GrOpcode.shiftStack, -1);
                addInstruction(GrOpcode.const_bool, 0);
                return GrType(GrType.Base.bool_);
            default:
                break;
            }
            break;
        case enum_:
            switch (lexType) with (GrLexeme.Type) {
            case equal:
                addInstruction(GrOpcode.equal_int);
                return GrType(GrType.Base.bool_);
            case notEqual:
                addInstruction(GrOpcode.notEqual_int);
                return GrType(GrType.Base.bool_);
            case greater:
                addInstruction(GrOpcode.greater_int);
                return GrType(GrType.Base.bool_);
            case greaterOrEqual:
                addInstruction(GrOpcode.greaterOrEqual_int);
                return GrType(GrType.Base.bool_);
            case lesser:
                addInstruction(GrOpcode.lesser_int);
                return GrType(GrType.Base.bool_);
            case lesserOrEqual:
                addInstruction(GrOpcode.lesserOrEqual_int);
                return GrType(GrType.Base.bool_);
            default:
                break;
            }
            break;
        case bool_:
            switch (lexType) with (GrLexeme.Type) {
            case and:
                addInstruction(GrOpcode.and_int);
                return GrType(GrType.Base.bool_);
            case or:
                addInstruction(GrOpcode.or_int);
                return GrType(GrType.Base.bool_);
            case not:
                addInstruction(GrOpcode.not_int);
                return GrType(GrType.Base.bool_);
            default:
                break;
            }
            break;
        case int_:
            switch (lexType) with (GrLexeme.Type) {
            case add:
                addInstruction(GrOpcode.add_int);
                return GrType(GrType.Base.int_);
            case substract:
                addInstruction(GrOpcode.substract_int);
                return GrType(GrType.Base.int_);
            case multiply:
                addInstruction(GrOpcode.multiply_int);
                return GrType(GrType.Base.int_);
            case divide:
                addInstruction(GrOpcode.divide_int);
                return GrType(GrType.Base.int_);
            case remainder:
                addInstruction(GrOpcode.remainder_int);
                return GrType(GrType.Base.int_);
            case minus:
                addInstruction(GrOpcode.negative_int);
                return GrType(GrType.Base.int_);
            case plus:
                return GrType(GrType.Base.int_);
            case increment:
                addInstruction(GrOpcode.increment_int);
                return GrType(GrType.Base.int_);
            case decrement:
                addInstruction(GrOpcode.decrement_int);
                return GrType(GrType.Base.int_);
            case equal:
                addInstruction(GrOpcode.equal_int);
                return GrType(GrType.Base.bool_);
            case notEqual:
                addInstruction(GrOpcode.notEqual_int);
                return GrType(GrType.Base.bool_);
            case greater:
                addInstruction(GrOpcode.greater_int);
                return GrType(GrType.Base.bool_);
            case greaterOrEqual:
                addInstruction(GrOpcode.greaterOrEqual_int);
                return GrType(GrType.Base.bool_);
            case lesser:
                addInstruction(GrOpcode.lesser_int);
                return GrType(GrType.Base.bool_);
            case lesserOrEqual:
                addInstruction(GrOpcode.lesserOrEqual_int);
                return GrType(GrType.Base.bool_);
            case not:
                addInstruction(GrOpcode.not_int);
                return GrType(GrType.Base.bool_);
            default:
                break;
            }
            break;
        case float_:
            switch (lexType) with (GrLexeme.Type) {
            case add:
                addInstruction(GrOpcode.add_float);
                return GrType(GrType.Base.float_);
            case substract:
                if (isSwapped)
                    addInstruction(GrOpcode.swap);
                addInstruction(GrOpcode.substract_float);
                return GrType(GrType.Base.float_);
            case multiply:
                addInstruction(GrOpcode.multiply_float);
                return GrType(GrType.Base.float_);
            case divide:
                if (isSwapped)
                    addInstruction(GrOpcode.swap);
                addInstruction(GrOpcode.divide_float);
                return GrType(GrType.Base.float_);
            case remainder:
                if (isSwapped)
                    addInstruction(GrOpcode.swap);
                addInstruction(GrOpcode.remainder_float);
                return GrType(GrType.Base.float_);
            case minus:
                addInstruction(GrOpcode.negative_float);
                return GrType(GrType.Base.float_);
            case plus:
                return GrType(GrType.Base.float_);
            case increment:
                addInstruction(GrOpcode.increment_float);
                return GrType(GrType.Base.float_);
            case decrement:
                addInstruction(GrOpcode.decrement_float);
                return GrType(GrType.Base.float_);
            case equal:
                addInstruction(GrOpcode.equal_float);
                return GrType(GrType.Base.bool_);
            case notEqual:
                addInstruction(GrOpcode.notEqual_float);
                return GrType(GrType.Base.bool_);
            case greater:
                if (isSwapped)
                    addInstruction(GrOpcode.lesserOrEqual_float);
                else
                    addInstruction(GrOpcode.greater_float);
                return GrType(GrType.Base.bool_);
            case greaterOrEqual:
                if (isSwapped)
                    addInstruction(GrOpcode.lesser_float);
                else
                    addInstruction(GrOpcode.greaterOrEqual_float);
                return GrType(GrType.Base.bool_);
            case lesser:
                if (isSwapped)
                    addInstruction(GrOpcode.greaterOrEqual_float);
                else
                    addInstruction(GrOpcode.lesser_float);
                return GrType(GrType.Base.bool_);
            case lesserOrEqual:
                if (isSwapped)
                    addInstruction(GrOpcode.greater_float);
                else
                    addInstruction(GrOpcode.lesserOrEqual_float);
                return GrType(GrType.Base.bool_);
            default:
                break;
            }
            break;
        case string_:
            switch (lexType) with (GrLexeme.Type) {
            case concatenate:
                if (isSwapped)
                    addInstruction(GrOpcode.swap);
                addInstruction(GrOpcode.concatenate_string);
                return GrType(GrType.Base.string_);
            case equal:
                addInstruction(GrOpcode.equal_string);
                return GrType(GrType.Base.bool_);
            case notEqual:
                addInstruction(GrOpcode.notEqual_string);
                return GrType(GrType.Base.bool_);
            default:
                break;
            }
            break;
        case list:
            switch (lexType) with (GrLexeme.Type) {
            case equal:
                addInstruction(GrOpcode.equal_list);
                break;
            case notEqual:
                addInstruction(GrOpcode.notEqual_list);
                break;
            case concatenate:
                addInstruction(GrOpcode.concatenate_list);
                break;
            default:
                break;
            }
            break;
        case channel:
            switch (lexType) with (GrLexeme.Type) {
            case send:
                addInstruction(GrOpcode.send);
                return grUnmangle(varType.mangledType);
            case receive:
                addInstruction(GrOpcode.receive);
                return grUnmangle(varType.mangledType);
            default:
                break;
            }
            break;
        default:
            break;
        }
        return GrType(GrType.Base.void_);
    }

    private void addSetInstruction(GrVariable variable, uint fileId,
        GrType valueType = grVoid, bool isExpectingValue = false, bool isInitialization = false) {
        _isAssignationOptimizable = true;
        if (variable.isConst && !isInitialization) {
            if (variable.type.base == GrType.Base.reference)
                logError(getError(Error.exprIsConstAndCantBeModified),
                    getError(Error.cantModifyAConst));
            else
                logError(format(getError(Error.xIsConstAndCantBeModified),
                        variable.name), getError(Error.cantModifyAConst));
        }

        if (variable.type.base == GrType.Base.reference) {
            valueType = convertType(valueType, grUnmangle(variable.type.mangledType), fileId);
            final switch (valueType.base) with (GrType.Base) {
            case bool_:
            case int_:
            case func:
            case task:
            case event:
            case optional:
            case channel:
            case enum_:
            case float_:
            case string_:
            case class_:
            case list:
            case native:
                addInstruction(isExpectingValue ? GrOpcode.refStore2 : GrOpcode.refStore);
                break;
            case void_:
            case null_:
            case internalTuple:
            case reference:
                logError(format(getError(Error.cantAssignToAXVar),
                        getPrettyType(variable.type)), getError(Error.ValNotAssignable));
            }
            return;
        }

        if (variable.isAuto && !variable.isInitialized) {
            variable.isInitialized = true;
            variable.isAuto = false;
            if (variable.type.base == GrType.Base.optional && valueType.base != GrType
                .Base.optional)
                valueType = grOptional(valueType);
            variable.isOptional = false;
            valueType.isPure = valueType.isPure || variable.type.isPure;
            variable.type = valueType;
            if (valueType.base == GrType.Base.void_)
                logError(getError(Error.cantInferTypeOfVar), getError(Error.varNotInit));
            else
                setVariableRegister(variable);
        }

        if (valueType.base != GrType.Base.void_)
            convertType(valueType, variable.type, fileId);

        variable.isInitialized = true;

        if (variable.isField) {
            final switch (variable.type.base) with (GrType.Base) {
            case bool_:
            case int_:
            case func:
            case task:
            case event:
            case enum_:
            case float_:
            case string_:
            case optional:
            case native:
            case reference:
            case channel:
            case list:
            case class_:
                addInstruction(GrOpcode.fieldRefStore, (isExpectingValue ||
                        variable.isOptional) ? 0 : -1, true);
                break;
            case void_:
            case null_:
            case internalTuple:
                logError(format(getError(Error.cantAssignToAXVar),
                        getPrettyType(variable.type)), getError(Error.ValNotAssignable));
            }
        }
        else if (variable.isGlobal) {
            final switch (variable.type.base) with (GrType.Base) {
            case bool_:
            case int_:
            case func:
            case task:
            case event:
            case enum_:
            case float_:
            case string_:
            case optional:
            case channel:
            case class_:
            case list:
            case native:
                addInstruction(isExpectingValue ? GrOpcode.globalStore2
                        : GrOpcode.globalStore, variable.register);
                break;
            case void_:
            case null_:
            case internalTuple:
            case reference:
                logError(format(getError(Error.cantAssignToAXVar),
                        getPrettyType(variable.type)), getError(Error.ValNotAssignable));
            }
        }
        else {
            final switch (variable.type.base) with (GrType.Base) {
            case bool_:
            case int_:
            case func:
            case task:
            case event:
            case enum_:
            case float_:
            case string_:
            case optional:
            case list:
            case class_:
            case native:
            case channel:
                addInstruction(isExpectingValue ? GrOpcode.localStore2
                        : GrOpcode.localStore, variable.register);
                break;
            case void_:
            case null_:
            case internalTuple:
            case reference:
                logError(format(getError(Error.cantAssignToAXVar),
                        getPrettyType(variable.type)), getError(Error.ValNotAssignable));
            }
        }

        if (variable.isOptional && variable.isField) {
            if (variable.type.base != GrType.Base.optional)
                variable.type = grOptional(variable.type);

            setInstruction(GrOpcode.optionalCall, variable.optionalPosition,
                cast(int)(currentFunction.instructions.length - variable.optionalPosition), true);

            if (!isExpectingValue)
                addInstruction(GrOpcode.shiftStack, -1, true);
        }
    }

    /// Ajoute une instruction de chargement. \
    /// Peut aussi optimiser une instruction d’enregistrement qui le précède.
    void addGetInstruction(GrVariable variable, GrType expectedType = grVoid,
        bool allowOptimization = true) {
        if (!_isAssignationOptimizable) {
            /+--------------------------
                L’optimisation des accesseurs doit prendre en compte les différences de portée
                puisque les sauts peuvent briser l’état de la machine virtuelle.

                Dans cet exemple, on ne doit pas optimiser car la pile sera vide lors du
                second passage:

                "func maFonction() {
                    var a = true;
                    loop {
                        if(a) {}  // a se situe après a = true, donc on optimise ?
                        yield;
                    } // On resaute vers le début de la boucle où il y a lstore2, plantant la machine virtuelle.
                }"
                Pour éviter ça, on empêche l’optimisation sur différents niveaux de portée.
            -------------------------+/
            allowOptimization = false;
        }

        if (variable.isField) {
            throw new Exception("attempt to get field value");
        }
        else if (variable.isGlobal) {
            final switch (variable.type.base) with (GrType.Base) {
            case bool_:
            case int_:
            case func:
            case task:
            case event:
            case enum_:
            case float_:
            case string_:
            case optional:
            case list:
            case class_:
            case native:
            case channel:
                if (allowOptimization && currentFunction.instructions.length &&
                    currentFunction.instructions[$ - 1].opcode == GrOpcode.globalStore &&
                    currentFunction.instructions[$ - 1].value == variable.register)
                    currentFunction.instructions[$ - 1].opcode = GrOpcode.globalStore2;
                else
                    addInstruction(GrOpcode.globalLoad, variable.register);
                break;
            case void_:
            case null_:
            case internalTuple:
            case reference:
                logError(format(getError(Error.cantGetValueOfX),
                        getPrettyType(variable.type)), getError(Error.valNotFetchable));
            }
        }
        else {
            if (!variable.isInitialized)
                logError(getError(Error.locVarUsedNotAssigned), getError(Error.varNotInit));

            final switch (variable.type.base) with (GrType.Base) {
            case bool_:
            case int_:
            case func:
            case task:
            case event:
            case enum_:
            case float_:
            case string_:
            case optional:
            case list:
            case class_:
            case native:
            case channel:
                if (allowOptimization && currentFunction.instructions.length &&
                    currentFunction.instructions[$ - 1].opcode == GrOpcode.localStore &&
                    currentFunction.instructions[$ - 1].value == variable.register)
                    currentFunction.instructions[$ - 1].opcode = GrOpcode.localStore2;
                else
                    addInstruction(GrOpcode.localLoad, variable.register);
                break;
            case void_:
            case null_:
            case internalTuple:
            case reference:
                logError(format(getError(Error.cantGetValueOfX),
                        getPrettyType(variable.type)), getError(Error.valNotFetchable));
            }
        }
    }

    private GrType addFunctionAddress(string name, GrType[] signature, uint fileId) {
        if (name == "@global")
            return grVoid;
        GrFunctionCall call = new GrFunctionCall;
        call.name = name;
        call.signature = signature;
        call.caller = currentFunction;
        functionCalls ~= call;
        currentFunction.functionCalls ~= call;
        call.isAddress = true;
        auto func = getFunction(name, signature, fileId);
        if (func is null)
            func = getAnonymousFunction(name, signature, fileId);
        if (func !is null) {
            call.functionToCall = func;
            call.position = cast(uint) currentFunction.instructions.length;
            addInstruction(GrOpcode.const_int, 0);

            return grGetFunctionAsType(func);
        }
        return grVoid;
    }

    private GrType addFunctionAddress(GrFunction func, uint fileId) {
        if (func.name == "@global")
            return grVoid;
        GrFunctionCall call = new GrFunctionCall;
        call.caller = currentFunction;
        functionCalls ~= call;
        currentFunction.functionCalls ~= call;
        call.isAddress = true;
        call.functionToCall = func;
        call.position = cast(uint) currentFunction.instructions.length;
        addInstruction(GrOpcode.const_int, 0);
        return grGetFunctionAsType(func);
    }

    private GrType[] addFunctionCall(string name, GrType[] signature, uint fileId) {
        GrFunctionCall call = new GrFunctionCall;
        call.name = name;
        call.signature = signature;
        call.caller = currentFunction;
        functionCalls ~= call;
        currentFunction.functionCalls ~= call;
        call.isAddress = false;
        call.fileId = fileId;

        GrFunction func = getFunction(name, signature, call.fileId, false);
        if (func) {
            call.functionToCall = func;
            if (func.isTask) {
                if (func.nbParameters > 0)
                    addInstruction(GrOpcode.globalPush, func.nbParameters);
            }

            call.position = cast(uint) currentFunction.instructions.length;
            addInstruction(GrOpcode.call, 0);

            return func.outSignature;
        }
        else
            logError(format(getError(Error.xNotDecl), getPrettyFunctionCall(name,
                    signature)), getError(Error.unknownFunc), "", -1);

        return [];
    }

    private GrType[] addFunctionCall(GrFunction func, uint fileId) {
        GrFunctionCall call = new GrFunctionCall;
        call.name = func.name;
        call.signature = func.inSignature;
        call.caller = currentFunction;
        functionCalls ~= call;
        currentFunction.functionCalls ~= call;
        call.isAddress = false;
        call.fileId = fileId;

        call.functionToCall = func;
        if (func.isTask) {
            if (func.nbParameters > 0)
                addInstruction(GrOpcode.globalPush, func.nbParameters);
        }

        call.position = cast(uint) currentFunction.instructions.length;
        addInstruction(GrOpcode.call, 0);

        return func.outSignature;
    }

    private void setOpcode(ref uint[] opcodes, uint position, GrOpcode opcode,
        uint value = 0u, bool isSigned = false) {
        GrInstruction instruction;
        instruction.opcode = opcode;
        if (isSigned) {
            if ((value >= 0x800000) || (-value >= 0x800000))
                throw new Exception("an opcode's signed value is exceeding limits");
            instruction.value = value + 0x800000;
        }
        else
            instruction.value = value;

        uint makeOpcode(uint instr, uint value) {
            return ((value << 8u) & 0xffffff00) | (instr & 0xff);
        }

        opcodes[position] = makeOpcode(cast(uint) instruction.opcode, instruction.value);
    }

    package void solveFunctionCalls(ref uint[] opcodes) {
        foreach (GrFunctionCall call; functionCalls) {
            GrFunction func = call.functionToCall;
            if (!func)
                func = getFunction(call.name, call.signature, call.fileId);
            if (!func)
                func = getAnonymousFunction(call.name, call.signature, call.fileId);
            if (func) {
                if (call.isAddress)
                    setOpcode(opcodes, call.position, GrOpcode.const_int,
                        registerIntConstant(func.position));
                else if (func.isTask)
                    setOpcode(opcodes, call.position, GrOpcode.task, func.position);
                else
                    setOpcode(opcodes, call.position, GrOpcode.call, func.position);
            }
            else
                logError(format(getError(Error.xNotDecl), getPrettyFunctionCall(call.name,
                        call.signature)), getError(Error.unknownFunc));
        }

        foreach (func; anonymousFunctions)
            setOpcode(opcodes, func.anonParent.position + func.anonParent.offset + func.anonReference,
                GrOpcode.const_int, registerIntConstant(func.position));
    }

    package void dump() {
        writeln("Code Generated:\n");
        foreach (size_t i, GrInt ivalue; iconsts)
            writeln(".iconst " ~ to!string(ivalue) ~ "\t;" ~ to!string(i));

        foreach (size_t i, GrFloat rvalue; rconsts)
            writeln(".fconst " ~ to!string(rvalue) ~ "\t;" ~ to!string(i));

        foreach (size_t i, GrStringValue svalue; sconsts)
            writeln(".sconst " ~ to!string(svalue) ~ "\t;" ~ to!string(i));

        foreach (GrFunction func; functions) {
            if (func.isEvent)
                writeln("\n.event " ~ func.name);
            else if (func.isTask)
                writeln("\n.task " ~ func.name);
            else
                writeln("\n.func " ~ func.name);

            foreach (size_t i, GrInstruction instruction; func.instructions) {
                writeln("[" ~ to!string(i) ~ "] " ~ to!string(
                        instruction.opcode) ~ " " ~ to!string(instruction.value));
            }
        }
    }

    package void parseScript(GrData data, GrLexer lexer, int options) {
        _data = data;
        _options = options;

        bool isPublic;
        lexemes = lexer.lexemes;

        beginGlobalScope();
        foreach (GrVariableDefinition variableDef; _data._variableDefinitions) {
            GrVariable variable = registerVariable(variableDef.name,
                variableDef.type, false, true, variableDef.isConst, true);
            variableDef.register = variable.register;
        }
        endGlobalScope();

        // Définitions des types
        while (!isEnd()) {
            GrLexeme lex = get();
            isPublic = false;
            if (lex.type == GrLexeme.Type.public_) {
                isPublic = true;
                checkAdvance();
                lex = get();
            }
            switch (lex.type) with (GrLexeme.Type) {
            case semicolon:
                checkAdvance();
                break;
            case class_:
                registerClassDeclaration(isPublic);
                break;
            case enum_:
                parseEnumDeclaration(isPublic);
                break;
            case event:
            case task:
            case func:
                skipDeclaration();
                break;
            case alias_:
            default:
                skipExpression();
                break;
            }
        }

        // Alias de types
        reset();
        while (!isEnd()) {
            GrLexeme lex = get();
            isPublic = false;
            if (lex.type == GrLexeme.Type.public_) {
                isPublic = true;
                checkAdvance();
                lex = get();
            }
            switch (lex.type) with (GrLexeme.Type) {
            case semicolon:
                checkAdvance();
                break;
            case alias_:
                parseTypeAliasDeclaration(isPublic);
                break;
            case event:
            case task:
            case func:
            case class_:
            case enum_:
                skipDeclaration();
                break;
            default:
                skipExpression();
                break;
            }
        }

        foreach (GrClassDefinition class_; _deferredClassDeclarations) {
            parseClassDeclaration(class_);
        }

        // Définitions des fonctions
        reset();
        while (!isEnd()) {
            GrLexeme lex = get();
            isPublic = false;
            if (lex.type == GrLexeme.Type.public_) {
                isPublic = true;
                checkAdvance();
                lex = get();
            }
            switch (lex.type) with (GrLexeme.Type) {
            case semicolon:
                checkAdvance();
                break;
            case enum_:
            case class_:
                skipDeclaration();
                break;
            case event:
                parseEventDeclaration(isPublic);
                break;
            case task:
                if (get(1).type != GrLexeme.Type.identifier && get(1).type != GrLexeme.Type.lesser)
                    goto case integerType;
                parseTaskDeclaration(isPublic);
                break;
            case func:
                if (get(1).type != GrLexeme.Type.identifier && !get(1)
                    .isOperator && get(1).type != GrLexeme.Type.as && get(1)
                    .type != GrLexeme.Type.lesser)
                    goto case integerType;
                parseFunctionDeclaration(isPublic);
                break;
            case integerType: .. case channelType:
            case var:
            case const_:
            case pure_:
            case identifier:
            case alias_:
                skipExpression();
                break;
            default:
                logError(getError(Error.globalDeclExpected),
                    format(getError(Error.globalDeclExpectedFoundX),
                        getPrettyLexemeType(get().type)));
            }
        }

        // Définitions des variables globales
        reset();
        beginGlobalScope();
        while (!isEnd()) {
            GrLexeme lex = get();
            isPublic = false;
            if (lex.type == GrLexeme.Type.public_) {
                isPublic = true;
                checkAdvance();
                lex = get();
            }
            switch (lex.type) with (GrLexeme.Type) {
            case semicolon:
                checkAdvance();
                break;
            case event:
            case enum_:
            case class_:
                skipDeclaration();
                break;
            case task:
                skipDeclaration();
                break;
            case func:
                skipDeclaration();
                break;
            case var:
                parseVariableDeclaration(false, true, isPublic);
                break;
            case const_:
                parseVariableDeclaration(true, true, isPublic);
                break;
            case alias_:
                skipExpression();
                break;
            default:
                logError(getError(Error.globalDeclExpected),
                    format(getError(Error.globalDeclExpectedFoundX),
                        getPrettyLexemeType(get().type)));
            }
        }
        endGlobalScope();

        while (functionsQueue.length) {
            GrFunction func = functionsQueue[$ - 1];
            functionsQueue.length--;
            parseFunction(func);
        }
    }

    /// Analyse le contenu des fonctions globales
    void parseFunction(GrFunction func) {
        if (func.isEvent) {
            func.index = cast(uint) events.length;
            events ~= func;
        }
        else {
            func.index = cast(uint) functions.length;
            functions ~= func;
        }

        functionStack ~= currentFunction;
        currentFunction = func;

        for (int i; i < func.templateVariables.length; ++i) {
            _data.addTemplateAlias(func.templateVariables[i],
                func.templateSignature[i], func.fileId, func.isPublic);
        }
        current = func.lexPosition;
        parseWhereStatement(func.templateVariables);
        openDeferrableSection();
        parseBlock(false, true);
        if (func.isTask || func.isEvent) {
            if (!currentFunction.instructions.length ||
                currentFunction.instructions[$ - 1].opcode != GrOpcode.die)
                addDie();
        }
        else {
            if (!currentFunction.outSignature.length) {
                if (!currentFunction.instructions.length ||
                    currentFunction.instructions[$ - 1].opcode != GrOpcode.return_)
                    addReturn();
            }
            else {
                if (!currentFunction.instructions.length ||
                    currentFunction.instructions[$ - 1].opcode != GrOpcode.return_)
                    logError(getError(Error.funcMissingRetAtEnd), getError(Error.missingRet));
            }
        }
        closeDeferrableSection();
        registerDeferBlocks();

        endFunction();
        _data.clearTemplateAliases();
    }

    /// Analyse la déclaration d’un alias de type
    private void parseTypeAliasDeclaration(bool isPublic) {
        const uint fileId = get().fileId;
        checkAdvance();

        if (get().type != GrLexeme.Type.identifier)
            logError(format(getError(Error.expectedTypeAliasNameFoundX),
                    getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));
        const string typeAliasName = get().svalue;
        checkAdvance();

        if (get().type != GrLexeme.Type.colon)
            logError(getError(Error.missingColonBeforeType), format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.colon), getPrettyLexemeType(get().type)));
        checkAdvance();

        _mustDeferClassDeclaration = true;
        GrType type = parseType(true);
        _mustDeferClassDeclaration = false;

        if (get().type != GrLexeme.Type.semicolon)
            logError(getError(Error.missingSemicolonAfterType), format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.semicolon), getPrettyLexemeType(get().type)));

        if (_data.isTypeDeclared(typeAliasName, fileId, isPublic))
            logError(format(getError(Error.nameXDefMultipleTimes),
                    typeAliasName), format(getError(Error.alreadyDef), typeAliasName));
        _data.addAlias(typeAliasName, type, fileId, isPublic);
    }

    /// Analyse la déclaration d’une énumération
    private void parseEnumDeclaration(bool isPublic) {
        const uint fileId = get().fileId;
        checkAdvance();
        if (get().type != GrLexeme.Type.identifier)
            logError(format(getError(Error.expectedEnumNameFoundX),
                    getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));
        const string enumName = get().svalue;
        checkAdvance();
        if (get().type != GrLexeme.Type.leftCurlyBrace)
            logError(getError(Error.enumDefNotHaveBody), format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.leftCurlyBrace),
                    getPrettyLexemeType(get().type)));
        checkAdvance();

        string[] fields;
        while (!isEnd()) {
            if (get().type == GrLexeme.Type.rightCurlyBrace) {
                checkAdvance();
                break;
            }
            if (get().type != GrLexeme.Type.identifier)
                logError(format(getError(Error.expectedEnumFieldFoundX),
                        getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));

            auto fieldName = get().svalue;
            checkAdvance();
            fields ~= fieldName;

            if (get().type != GrLexeme.Type.semicolon)
                logError(getError(Error.missingSemicolonAfterEnumField), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.semicolon),
                        getPrettyLexemeType(get().type)));
            checkAdvance();
        }
        if (_data.isTypeDeclared(enumName, fileId, isPublic))
            logError(format(getError(Error.nameXDefMultipleTimes), enumName),
                format(getError(Error.xAlreadyDecl), enumName));
        _data.addEnum(enumName, fields, fileId, isPublic);
    }

    /// Déclare une nouvelle classe sans l’analyser
    private void registerClassDeclaration(bool isPublic) {
        const uint fileId = get().fileId;

        checkAdvance();
        if (get().type != GrLexeme.Type.identifier)
            logError(format(getError(Error.expectedClassNameFoundX),
                    getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));

        const string className = get().svalue;
        checkAdvance();

        if (_data.isTypeDeclared(className, fileId, isPublic))
            logError(format(getError(Error.nameXDefMultipleTimes), className),
                format(getError(Error.xAlreadyDecl), className));

        string[] templateVariables = parseTemplateVariables();
        const uint declPosition = current;

        _data.registerClass(className, fileId, isPublic, templateVariables, declPosition);

        skipDeclaration();
    }

    /// Récupère une classe. \
    /// Réifie la classe si besoin.
    private GrClassDefinition getClass(string mangledType, uint fileId) {
        GrClassDefinition class_ = _data.getClass(mangledType, fileId);
        if (!class_)
            return null;
        if (_mustDeferClassDeclaration) {
            _deferredClassDeclarations ~= class_;
        }
        else {
            parseClassDeclaration(class_);
        }
        return class_;
    }

    /// Réifie une classe
    private void parseClassDeclaration(GrClassDefinition class_) {
        if (class_.isParsed)
            return;
        class_.isParsed = true;
        uint tempPos = current;
        current = class_.position;

        for (int i; i < class_.templateVariables.length; ++i) {
            _data.addTemplateAlias(class_.templateVariables[i],
                class_.templateTypes[i], class_.fileId, class_.isPublic);
        }

        uint[] fieldPositions;
        string parentClassName;

        // Héritage
        if (get().type == GrLexeme.Type.colon) {
            checkAdvance();
            if (get().type != GrLexeme.Type.identifier)
                logError(getError(Error.parentClassNameMissing),
                    format(getError(Error.expectedClassNameFoundX), getPrettyLexemeType(get().type)));
            parentClassName = get().svalue;
            checkAdvance();
            parentClassName = grMangleComposite(parentClassName, parseTemplateSignature());
        }
        if (get().type != GrLexeme.Type.leftCurlyBrace)
            logError(getError(Error.classHaveNoBody), format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.leftCurlyBrace),
                    getPrettyLexemeType(get().type)));
        checkAdvance();

        string[] fields;
        GrType[] signature;
        bool[] fieldScopes, fieldConsts;
        while (!isEnd()) {
            if (get().type == GrLexeme.Type.rightCurlyBrace) {
                checkAdvance();
                break;
            }

            bool isFieldPublic = false;
            if (get().type == GrLexeme.Type.public_) {
                isFieldPublic = true;
                checkAdvance();
            }

            if (get().type != GrLexeme.Type.var && get().type != GrLexeme.Type.const_)
                logError(format(getError(Error.unexpectedXSymbolInExpr),
                        getPrettyLexemeType(get().type)), getError(Error.unexpectedSymbol));

            const isConst = get().type == GrLexeme.Type.const_;
            checkAdvance();

            uint fieldCount;
            do {
                if (get().type == GrLexeme.Type.comma)
                    checkAdvance();

                const string fieldName = get().svalue;
                fields ~= fieldName;
                fieldScopes ~= isFieldPublic;
                fieldPositions ~= current;
                fieldCount++;
                checkAdvance();
            }
            while (get().type == GrLexeme.Type.comma);

            if (get().type != GrLexeme.Type.colon)
                logError(format(getError(Error.expectedXFoundY), getPrettyLexemeType(GrLexeme.Type.colon),
                        getPrettyLexemeType(get().type)), format(getError(Error.missingX),
                        getPrettyLexemeType(GrLexeme.Type.colon)));

            checkAdvance();

            GrType fieldType = parseType();

            while (fieldCount--)
                signature ~= fieldType;
            fieldConsts ~= isConst;

            if (get().type != GrLexeme.Type.semicolon)
                logError(getError(Error.missingSemicolonAfterClassFieldDecl), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.semicolon),
                        getPrettyLexemeType(get().type)));
            checkAdvance();

            if (get().type == GrLexeme.Type.rightCurlyBrace) {
                checkAdvance();
                break;
            }
        }

        class_.parent = parentClassName;
        class_.signature = signature;
        class_.fields = fields;
        class_.fieldConsts = fieldConsts;

        class_.fieldsInfo.length = fields.length;
        for (int i; i < class_.fieldsInfo.length; ++i) {
            class_.fieldsInfo[i].fileId = class_.fileId;
            class_.fieldsInfo[i].isPublic = fieldScopes[i];
            class_.fieldsInfo[i].position = fieldPositions[i];
        }
        current = tempPos;
        _data.clearTemplateAliases();
        resolveClassInheritence(class_);
    }

    /// Récupère les champs et la signature de la classe mère
    private void resolveClassInheritence(GrClassDefinition class_) {
        uint fileId = class_.fileId;
        string parent = class_.parent;
        GrClassDefinition lastClass = class_;
        string[] usedClasses = [class_.name];

        while (parent.length) {
            GrClassDefinition parentClass = getClass(parent, fileId);
            if (!parentClass) {
                set(lastClass.position + 2u);
                logError(format(getError(Error.xCantInheritFromY),
                        getPrettyType(grGetClassType(class_.name)), parent),
                    getError(Error.unknownClass));
            }
            for (int i; i < usedClasses.length; ++i) {
                if (parent == usedClasses[i]) {
                    set(lastClass.position + 2u);
                    logError(format(getError(Error.xIncludedRecursively),
                            getPrettyType(grGetClassType(parent))),
                        getError(Error.recursiveInheritence));
                }
            }
            usedClasses ~= parent;
            class_.fields = parentClass.fields ~ class_.fields;
            class_.signature = parentClass.signature ~ class_.signature;
            class_.fieldsInfo = parentClass.fieldsInfo ~ class_.fieldsInfo;
            class_.fieldConsts = parentClass.fieldConsts ~ class_.fieldConsts;
            fileId = parentClass.fileId;
            parent = parentClass.parent;
            lastClass = parentClass;
        }
        for (int i; i < class_.signature.length; ++i) {
            for (int y; y < class_.fields.length; ++y) {
                if (i != y && class_.fields[i] == class_.fields[y]) {
                    int first;
                    int second;
                    if (class_.fieldsInfo[i].position < class_.fieldsInfo[y].position) {
                        first = i;
                        second = y;
                    }
                    else {
                        first = y;
                        second = i;
                    }
                    set(class_.fieldsInfo[second].position);
                    logError(format(getError(Error.fieldXDeclMultipleTimes), class_.fields[second]),
                        format(getError(Error.xRedefHere), class_.fields[second]),
                        "", 0, format(getError(Error.prevDefOfX),
                            class_.fields[first]), class_.fieldsInfo[first].position);
                }
            }
            if (class_.signature[i].base != GrType.Base.class_) {
                for (int y; y < usedClasses.length; ++y) {
                    if (class_.signature[i].mangledType == usedClasses[y]) {
                        set(class_.fieldsInfo[i].position);
                        logError(format(getError(Error.xIncludedRecursively),
                                class_.signature[i].mangledType), getError(Error.recursiveDecl));
                    }
                }
            }
        }
    }

    private void skipDeclaration() {
        checkAdvance();
        while (!isEnd()) {
            if (get().type != GrLexeme.Type.leftCurlyBrace) {
                checkAdvance();
            }
            else {
                skipBlock();
                return;
            }
        }
    }

    private void skipExpression() {
        checkAdvance();
        while (!isEnd()) {
            switch (get().type) with (GrLexeme.Type) {
            case semicolon:
                checkAdvance();
                return;
            case leftCurlyBrace:
                skipBlock();
                break;
            default:
                checkAdvance();
                break;
            }
        }
    }

    private GrType parseType(bool mustBeType = true, string[] templateVariables = [
        ]) {
        GrType currentType = GrType.Base.void_;
        bool isPure;

        if (get().type == GrLexeme.Type.pure_) {
            checkAdvance();
            isPure = true;
        }

        GrLexeme lex = get();
        if (!lex.isType) {
            if (lex.type == GrLexeme.Type.identifier) {
                foreach (tempVar; templateVariables) {
                    if (tempVar == lex.svalue) {
                        checkAdvance();
                        currentType = grAny(lex.svalue);
                        break;
                    }
                }
            }
            if (!currentType.isAny) {
                if (lex.type == GrLexeme.Type.identifier &&
                    _data.isTypeAlias(lex.svalue, lex.fileId, false)) {
                    currentType = _data.getTypeAlias(lex.svalue, lex.fileId).type;
                    checkAdvance();
                }
                else if (lex.type == GrLexeme.Type.identifier &&
                    _data.isClass(lex.svalue, lex.fileId, false)) {
                    currentType.base = GrType.Base.class_;
                    checkAdvance();
                    currentType.mangledType = grMangleComposite(lex.svalue,
                        parseTemplateSignature(templateVariables));
                    if (mustBeType) {
                        GrClassDefinition class_ = getClass(currentType.mangledType, lex.fileId);
                        if (!class_)
                            logError(format(getError(Error.xIsAbstract), getPrettyType(currentType)),
                                format(getError(Error.xIsAbstractAndCannotBeInstanciated),
                                    getPrettyType(currentType)), "", -1);
                    }
                }
                else if (lex.type == GrLexeme.Type.identifier &&
                    _data.isEnum(lex.svalue, lex.fileId, false)) {
                    currentType.base = GrType.Base.enum_;
                    currentType.mangledType = lex.svalue;
                    checkAdvance();
                }
                else if (lex.type == GrLexeme.Type.identifier && _data.isNative(lex.svalue)) {
                    currentType.base = GrType.Base.native;
                    currentType.mangledType = lex.svalue;
                    checkAdvance();
                    currentType.mangledType = grMangleComposite(lex.svalue,
                        parseTemplateSignature(templateVariables));
                    if (mustBeType) {
                        GrNativeDefinition native = _data.getNative(currentType.mangledType);
                        if (!native)
                            logError(format(getError(Error.xIsAbstract), getPrettyType(currentType)),
                                format(getError(Error.xIsAbstractAndCannotBeInstanciated),
                                    getPrettyType(currentType)), "", -1);
                    }
                }
                else if (mustBeType) {
                    const string typeName = lex.type == GrLexeme.Type.identifier ?
                        lex.svalue : getPrettyLexemeType(lex.type);
                    logError(format(getError(Error.xNotValidType), typeName),
                        format(getError(Error.expectedValidTypeFoundX), typeName));
                }
            }
        }
        else {
            switch (lex.type) with (GrLexeme.Type) {
            case integerType:
                currentType.base = GrType.Base.int_;
                checkAdvance();
                break;
            case floatType:
                currentType.base = GrType.Base.float_;
                checkAdvance();
                break;
            case booleanType:
                currentType.base = GrType.Base.bool_;
                checkAdvance();
                break;
            case stringType:
                currentType.base = GrType.Base.string_;
                checkAdvance();
                break;
            case listType:
                currentType.base = GrType.Base.list;
                checkAdvance();
                string[] temp;
                auto signature = parseTemplateSignature(templateVariables);
                if (signature.length > 1) {
                    logError(getError(Error.listCanOnlyContainOneTypeOfVal), getError(Error.conflictingListSignature),
                        format(getError(Error.tryUsingXInstead),
                            getPrettyType(grList(signature[0]))), -1);
                }
                else if (signature.length == 0) {
                    logError(getError(Error.listCanOnlyContainOneTypeOfVal), format(getError(Error.expectedXFoundY),
                            getPrettyLexemeType(GrLexeme.Type.lesser),
                            getPrettyLexemeType(get().type)));
                }
                currentType.mangledType = grMangleSignature(signature);
                break;
            case func:
                currentType.base = GrType.Base.func;
                checkAdvance();
                currentType.mangledType = grMangleSignature(parseSignature(templateVariables));
                currentType.mangledReturnType = grMangleSignature(parseSignature(templateVariables));
                break;
            case task:
                currentType.base = GrType.Base.task;
                checkAdvance();
                currentType.mangledType = grMangleSignature(parseSignature(templateVariables));
                break;
            case event:
                currentType.base = GrType.Base.event;
                checkAdvance();
                currentType.mangledType = grMangleSignature(parseSignature(templateVariables));
                break;
            case channelType:
                currentType.base = GrType.Base.channel;
                checkAdvance();
                string[] temp;
                GrType[] signature = parseTemplateSignature(templateVariables);
                if (signature.length != 1)
                    logError(getError(Error.channelCanOnlyContainOneTypeOfVal),
                        getError(Error.conflictingChannelSignature),
                        format(getError(Error.tryUsingXInstead),
                            getPrettyType(grChannel(signature[0]))), -1);
                currentType.mangledType = grMangleSignature(signature);
                break;
            default:
                logError(format(getError(Error.xNotValidType), getPrettyLexemeType(lex.type)),
                    format(getError(Error.expectedIdentifierFoundX),
                        getPrettyLexemeType(get().type)));
            }
        }

        if (get().type == GrLexeme.Type.optional) {
            checkAdvance();
            currentType.mangledType = grMangleSignature([currentType]);
            currentType.base = GrType.Base.optional;
        }

        currentType.isPure = isPure;

        return currentType;
    }

    private void addGlobalPop(GrType type) {
        final switch (type.base) with (GrType.Base) {
        case internalTuple:
        case null_:
        case void_:
            logError(format(getError(Error.xNotValidType), getPrettyType(type)),
                format(getError(Error.expectedIdentifierFoundX), getPrettyLexemeType(get().type)));
            break;
        case int_:
        case bool_:
        case func:
        case task:
        case event:
        case enum_:
        case float_:
        case string_:
        case class_:
        case optional:
        case list:
        case native:
        case channel:
        case reference:
            addInstruction(GrOpcode.globalPop, 0u);
            break;
        }
    }

    private void addGlobalPush(GrType type, int nbPush = 1u) {
        if (nbPush == 0)
            return;
        final switch (type.base) with (GrType.Base) {
        case internalTuple:
        case null_:
        case void_:
            logError(format(getError(Error.xNotValidType), getPrettyType(type)),
                format(getError(Error.expectedIdentifierFoundX), getPrettyLexemeType(get().type)));
            break;
        case int_:
        case bool_:
        case func:
        case task:
        case event:
        case enum_:
        case float_:
        case string_:
        case class_:
        case optional:
        case list:
        case native:
        case channel:
        case reference:
            addInstruction(GrOpcode.globalPush, nbPush);
            break;
        }
    }

    private void addGlobalPush(GrType[] signature) {
        if (signature.length > 0)
            addInstruction(GrOpcode.globalPush, cast(uint) signature.length);
    }

    private string[] parseTemplateVariables() {
        string[] variables;
        if (get().type != GrLexeme.Type.lesser)
            return variables;
        checkAdvance();
        distinguishTemplateLexemes();
        if (get().type == GrLexeme.Type.greater) {
            checkAdvance();
            return variables;
        }
        for (;;) {
            if (get().type != GrLexeme.Type.identifier)
                logError(format(getError(Error.expectedIdentifierFoundX),
                        getPrettyLexemeType(get().type)), getError(Error.missingTemplateVal));
            variables ~= get().svalue;
            checkAdvance();

            distinguishTemplateLexemes();
            const GrLexeme lex = get();
            if (lex.type == GrLexeme.Type.greater) {
                checkAdvance();
                break;
            }
            else if (lex.type != GrLexeme.Type.comma)
                logError(getError(Error.templateValShouldBeSeparatedByComma), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.comma), getPrettyLexemeType(lex.type)));
            checkAdvance();
        }
        return variables;
    }

    private GrType[] parseTemplateSignature(string[] templateVariables = []) {
        GrType[] signature;
        if (get().type != GrLexeme.Type.lesser)
            return signature;
        checkAdvance();
        distinguishTemplateLexemes();
        if (get().type == GrLexeme.Type.greater) {
            checkAdvance();
            return signature;
        }
        for (;;) {
            signature ~= parseType(true, templateVariables);

            distinguishTemplateLexemes();
            const GrLexeme lex = get();
            if (lex.type == GrLexeme.Type.greater) {
                checkAdvance();
                break;
            }
            else if (lex.type != GrLexeme.Type.comma)
                logError(getError(Error.templateTypesShouldBeSeparatedByComma), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.comma), getPrettyLexemeType(lex.type)));
            checkAdvance();
        }
        return signature;
    }

    private GrType[] parseInSignature(ref string[] inputVariables, string[] templateVariables = [
        ]) {
        GrType[] inSignature;

        if (get().type != GrLexeme.Type.leftParenthesis)
            logError(getError(Error.missingParentheses), format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.leftParenthesis),
                    getPrettyLexemeType(get().type)));

        bool startLoop = true;
        for (;;) {
            checkAdvance();
            GrLexeme lex = get();

            if (startLoop && lex.type == GrLexeme.Type.rightParenthesis)
                break;
            startLoop = false;

            lex = get();
            if (get().type != GrLexeme.Type.identifier)
                logError(format(getError(Error.expectedIdentifierFoundX),
                        getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));
            inputVariables ~= lex.svalue;
            checkAdvance();

            if (get().type != GrLexeme.Type.colon)
                logError(getError(Error.missingColonBeforeType), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.colon), getPrettyLexemeType(get().type)));
            checkAdvance();

            inSignature ~= parseType(true, templateVariables);

            lex = get();
            if (lex.type == GrLexeme.Type.rightParenthesis)
                break;
            else if (lex.type != GrLexeme.Type.comma)
                logError(getError(Error.paramShouldBeSeparatedByComma), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.comma), getPrettyLexemeType(get().type)));
        }
        checkAdvance();

        return inSignature;
    }

    private GrType[] parseSignature(string[] templateVariables = []) {
        GrType[] outSignature;
        if (get().type != GrLexeme.Type.leftParenthesis)
            return outSignature;
        checkAdvance();
        if (get().type == GrLexeme.Type.rightParenthesis) {
            checkAdvance();
            return outSignature;
        }
        for (;;) {
            outSignature ~= parseType(true, templateVariables);

            const GrLexeme lex = get();
            if (lex.type == GrLexeme.Type.rightParenthesis) {
                checkAdvance();
                break;
            }
            else if (lex.type != GrLexeme.Type.comma)
                logError(getError(Error.typesShouldBeSeparatedByComma), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.comma), getPrettyLexemeType(lex.type)));
            checkAdvance();
        }
        return outSignature;
    }

    private void parseEventDeclaration(bool isPublic) {
        if (isPublic)
            logError(getError(Error.addingPubBeforeEventIsRedundant),
                getError(Error.eventAlreadyPublic));
        checkAdvance();
        if (get().type != GrLexeme.Type.identifier)
            logError(format(getError(Error.expectedIdentifierFoundX),
                    getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));
        string name = get().svalue;
        string[] inputs;
        checkAdvance();
        GrType[] signature = parseInSignature(inputs);
        preBeginFunction(name, get().fileId, signature, inputs, false, [], false, true, true);
        skipBlock(true);
        preEndFunction();
    }

    private void parseTaskDeclaration(bool isPublic) {
        checkAdvance();
        string[] templateVariables = parseTemplateVariables();
        if (get().type != GrLexeme.Type.identifier)
            logError(format(getError(Error.expectedIdentifierFoundX),
                    getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));

        string name = get().svalue;
        checkAdvance();

        GrTemplateFunction temp = new GrTemplateFunction;
        temp.isTask = true;
        temp.name = name;
        temp.templateVariables = templateVariables;
        temp.fileId = get().fileId;
        temp.isPublic = isPublic;
        temp.lexPosition = current;

        string[] inputs;
        temp.inSignature = parseInSignature(inputs, templateVariables);
        temp.constraints = parseWhereStatement(templateVariables);
        templatedFunctions ~= temp;
        skipBlock(true);
    }

    private void parseFunctionDeclaration(bool isPublic) {
        checkAdvance();
        string[] templateVariables = parseTemplateVariables();
        string name;
        bool isConversion;
        GrType staticType;

        if (get().type == GrLexeme.Type.as) {
            checkAdvance();
            name = "@as";
            isConversion = true;
        }
        else if (get().type == GrLexeme.Type.at) {
            checkAdvance();
            staticType = parseType(true, templateVariables);
            name = "@static_" ~ grUnmangleComposite(staticType.mangledType).name;

            if (staticType.base == GrType.Base.void_)
                logError(format(getError(Error.xNotDecl),
                        getPrettyType(staticType)), getError(Error.unknownType));

            if (get().type == GrLexeme.Type.period) {
                checkAdvance();
                if (get().type != GrLexeme.Type.identifier)
                    logError(format(getError(Error.expectedIdentifierFoundX),
                            getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));

                name ~= "." ~ get().svalue;
                checkAdvance();
            }
        }
        else if (get().type == GrLexeme.Type.identifier) {
            if (get().svalue == "operator") {
                advance();
                if (get().isOverridableOperator()) {
                    name = "@operator_" ~ getPrettyLexemeType(get().type);
                    checkAdvance();
                }
                else if (get().isOperator) {
                    logError(format(getError(Error.cantOverrideXOp),
                            getPrettyLexemeType(get().type)), getError(Error.opCantBeOverriden));
                }
                else {
                    logError(format(getError(Error.expectedIdentifierFoundX),
                            getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));
                }
            }
            else {
                name = get().svalue;
                checkAdvance();
            }
        }
        else {
            logError(format(getError(Error.expectedIdentifierFoundX),
                    getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));
        }

        GrTemplateFunction temp = new GrTemplateFunction;
        temp.isTask = false;
        temp.name = name;
        temp.isConversion = isConversion;
        temp.templateVariables = templateVariables;
        temp.fileId = get().fileId;
        temp.isPublic = isPublic;
        temp.lexPosition = current;

        string[] inputs;
        temp.inSignature = parseInSignature(inputs, templateVariables);
        temp.outSignature = parseSignature(templateVariables);

        if (name == "@as")
            temp.inSignature ~= temp.outSignature;
        else if (staticType.base != GrType.Base.void_)
            temp.inSignature ~= staticType;

        temp.constraints = parseWhereStatement(templateVariables);
        templatedFunctions ~= temp;
        skipBlock(true);
    }

    private GrConstraint[] parseWhereStatement(string[] templateVariables) {
        GrConstraint[] constraints;
        if (get().type != GrLexeme.Type.where)
            return constraints;
        checkAdvance();

        for (;;) {
            GrType type = parseType(true, templateVariables);

            if (get().type != GrLexeme.Type.colon)
                logError(getError(Error.expectedColonAfterType), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.colon), getPrettyLexemeType(get().type)));
            checkAdvance();

            if (get().type != GrLexeme.Type.identifier)
                logError(getError(Error.missingConstraint), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.identifier),
                        getPrettyLexemeType(get().type)));

            GrConstraint.Data constraintData = grGetConstraint(get().svalue);
            if (!constraintData.predicate) {
                const string[] nearestValues = findNearestStrings(get().svalue,
                    grGetAllConstraintsName());
                string errorNote;
                if (nearestValues.length) {
                    foreach (size_t i, const string value; nearestValues) {
                        errorNote ~= "`" ~ value ~ "`";
                        if ((i + 1) < nearestValues.length)
                            errorNote ~= ", ";
                    }
                    errorNote ~= ".";
                }
                logError(getError(Error.missingConstraint), format(getError(Error.xIsNotAKnownConstraint),
                        get().svalue), format(getError(Error.validConstraintsAreX), errorNote));
            }
            checkAdvance();
            GrType[] parameters = parseTemplateSignature(templateVariables);
            constraints ~= new GrConstraint(constraintData.predicate,
                constraintData.arity, type, parameters);
            if (constraintData.arity != parameters.length)
                logError(format(getError(constraintData.arity > 1 ? Error.constraintTakesXArgsButYWereSupplied
                        : Error.constraintTakesXArgButYWereSupplied),
                        constraintData.arity, parameters.length),
                    format(getError(constraintData.arity > 1 ? Error.expectedXArgsFoundY
                        : Error.expectedXArgFoundY), constraintData.arity, parameters.length),
                    "", -1);

            if (get().type != GrLexeme.Type.comma)
                break;
            advance();
        }
        return constraints;
    }

    private GrFunction parseTemplatedFunctionDeclaration(GrTemplateFunction temp,
        GrType[] templateList) {
        const auto lastPosition = current;
        current = temp.lexPosition;

        for (int i; i < temp.templateVariables.length; ++i) {
            _data.addTemplateAlias(temp.templateVariables[i], templateList[i],
                temp.fileId, temp.isPublic);
        }

        string[] inputs;
        GrType[] inSignature = parseInSignature(inputs);
        GrType[] outSignature;

        if (!temp.isTask) {
            // Type de retour
            if (temp.isConversion) {
                if (inSignature.length != 1uL) {
                    logError(getError(Error.convMustHave1Param), format(getError(inSignature.length > 1 ?
                            Error.expected1ParamFoundXs : Error.expected1ParamFoundX),
                            inSignature.length));
                }
                outSignature = parseSignature();
                if (outSignature.length != 1uL) {
                    logError(getError(Error.convMustHave1RetVal), format(getError(outSignature.length > 1 ?
                            Error.expected1RetValFoundXs : Error.expected1RetValFoundX),
                            outSignature.length));
                }

                inSignature ~= outSignature[0];
            }
            else
                outSignature = parseSignature();
        }

        GrFunction func = new GrFunction;
        func.isTask = temp.isTask;
        func.name = temp.name;
        func.inputVariables = inputs;
        func.inSignature = inSignature;
        func.outSignature = outSignature;
        func.fileId = temp.fileId;
        func.isPublic = temp.isPublic;
        func.lexPosition = current;
        func.templateVariables = temp.templateVariables;
        func.templateSignature = templateList;

        _data.clearTemplateAliases();
        current = lastPosition;
        return func;
    }

    private GrType parseAnonymousFunction(bool isTask, bool isEvent) {
        checkAdvance();

        string[] inputs;
        GrType[] outSignature;
        GrType[] inSignature = parseInSignature(inputs);

        if (!isTask && !isEvent) {
            // Type de retour
            outSignature = parseSignature();
        }
        preBeginFunction("$anon", get().fileId, inSignature, inputs, isTask,
            outSignature, true, isEvent);
        openDeferrableSection();
        parseBlock();

        if (isTask || isEvent) {
            if (!currentFunction.instructions.length ||
                currentFunction.instructions[$ - 1].opcode != GrOpcode.die)
                addDie();
        }
        else {
            if (!outSignature.length) {
                if (!currentFunction.instructions.length ||
                    currentFunction.instructions[$ - 1].opcode != GrOpcode.return_)
                    addReturn();
            }
            else {
                if (!currentFunction.instructions.length ||
                    currentFunction.instructions[$ - 1].opcode != GrOpcode.return_)
                    logError(getError(Error.funcMissingRetAtEnd), getError(Error.missingRet));
            }
        }

        closeDeferrableSection();
        registerDeferBlocks();

        endFunction();

        GrType func = isEvent ? GrType.Base.event : (isTask ? GrType.Base.task : GrType.Base.func);
        func.mangledType = grMangleSignature(inSignature);
        func.mangledReturnType = grMangleSignature(outSignature);

        return func;
    }

    /**
    Parse either multiple lines between `{` and `}` or a single expression.
    */
    private void parseBlock(bool changeOptimizationBlockLevel = false, bool mustBeMultiline = false) {
        if (changeOptimizationBlockLevel)
            _isAssignationOptimizable = false;
        bool isMultiline;
        if (get().type == GrLexeme.Type.leftCurlyBrace) {
            isMultiline = true;
            if (!checkAdvance())
                logError(getError(Error.eof), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.rightCurlyBrace),
                        getPrettyLexemeType(get().type)));
        }
        else if (mustBeMultiline) {
            logError(getError(Error.missingCurlyBraces), format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.leftCurlyBrace),
                    getPrettyLexemeType(get().type)));
        }
        openBlock();

        void parseStatement() {
            switch (get().type) with (GrLexeme.Type) {
            case semicolon:
            case rightCurlyBrace:
                advance();
                break;
            case leftCurlyBrace:
                parseBlock();
                break;
            case defer:
                parseDeferStatement();
                break;
            case if_:
            case unless:
                parseIfStatement();
                break;
            case switch_:
                parseSwitchStatement();
                break;
            case select:
                parseSelectStatement();
                break;
            case until:
            case while_:
                parseWhileStatement();
                break;
            case do_:
                parseDoWhileStatement();
                break;
            case for_:
                parseForStatement();
                break;
            case loop:
                parseLoopStatement();
                break;
            case throw_:
                parseThrowStatement();
                break;
            case try_:
                parseExceptionHandler();
                break;
            case return_:
                parseReturnStatement();
                break;
            case die:
                parseDieStatement();
                break;
            case exit:
                parseQuitStatement();
                break;
            case yield:
                parseYieldStatement();
                break;
            case continue_:
                parseContinueStatement();
                break;
            case break_:
                parseBreakStatement();
                break;
            case var:
                parseVariableDeclaration(false, false, false);
                break;
            case const_:
                parseVariableDeclaration(true, false, false);
                break;
            default:
                parseExpression();
                break;
            }
        }

        if (isMultiline) {
            while (!isEnd()) {
                if (get().type == GrLexeme.Type.rightCurlyBrace)
                    break;
                parseStatement();
            }
        }
        else {
            if (get().type != GrLexeme.Type.semicolon)
                parseStatement();
            else if (get().type == GrLexeme.Type.semicolon)
                checkAdvance();
        }

        if (isMultiline) {
            if (get().type != GrLexeme.Type.rightCurlyBrace)
                logError(getError(Error.missingCurlyBraces), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.rightCurlyBrace),
                        getPrettyLexemeType(get().type)));
            checkAdvance();
        }
        closeBlock();
        if (changeOptimizationBlockLevel)
            _isAssignationOptimizable = false;
    }

    private void skipBlock(bool mustBeMultiline = false) {
        bool isMultiline;
        if (get().type == GrLexeme.Type.leftCurlyBrace) {
            isMultiline = true;
            if (!checkAdvance())
                logError(getError(Error.eof), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.rightCurlyBrace),
                        getPrettyLexemeType(get().type)));
        }
        else if (mustBeMultiline) {
            logError(getError(Error.missingCurlyBraces), format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.leftCurlyBrace),
                    getPrettyLexemeType(get().type)));
        }
        openBlock();

        void skipStatement() {
            switch (get().type) with (GrLexeme.Type) {
            case leftParenthesis:
                skipParenthesis();
                break;
            case leftBracket:
                skipBrackets();
                break;
            case leftCurlyBrace:
                skipBlock();
                break;
            case defer:
                checkAdvance();
                skipBlock();
                break;
            case switch_:
                checkAdvance();
                skipParenthesis();
                while (get().type == GrLexeme.Type.case_) {
                    checkAdvance();
                    if (get().type == GrLexeme.Type.leftParenthesis)
                        skipParenthesis();
                    skipBlock();
                }
                break;
            case if_:
            case unless:
                checkAdvance();
                skipParenthesis();
                skipBlock();
                break;
            case select:
                checkAdvance();
                while (get().type == GrLexeme.Type.case_) {
                    checkAdvance();
                    if (get().type == GrLexeme.Type.leftParenthesis)
                        skipParenthesis();
                    skipBlock();
                }
                break;
            case until:
            case while_:
                checkAdvance();
                skipBlock();
                break;
            case do_:
                checkAdvance();
                skipBlock();
                checkAdvance();
                skipParenthesis();
                break;
            case for_:
                checkAdvance();
                skipParenthesis();
                skipBlock();
                break;
            case loop:
                checkAdvance();
                if (get().type == GrLexeme.Type.leftParenthesis)
                    skipParenthesis();
                skipBlock();
                break;
            case throw_:
                checkAdvance();
                skipBlock();
                break;
            case try_:
                checkAdvance();
                skipBlock();
                if (get().type == GrLexeme.Type.catch_) {
                    checkAdvance();
                    skipParenthesis();
                    skipBlock();
                }
                break;
            case yield:
                checkAdvance();
                break;
            case return_:
                checkAdvance();
                skipBlock();
                break;
            default:
                while (!isEnd() && get().type != GrLexeme.Type.semicolon)
                    checkAdvance();
                if (!isEnd() && get().type == GrLexeme.Type.semicolon)
                    checkAdvance();
                break;
            }
        }

        if (isMultiline) {
            while (!isEnd()) {
                if (get().type == GrLexeme.Type.rightCurlyBrace)
                    break;
                switch (get().type) with (GrLexeme.Type) {
                case leftParenthesis:
                    skipParenthesis();
                    break;
                case leftBracket:
                    skipBrackets();
                    break;
                case leftCurlyBrace:
                    skipBlock();
                    break;
                default:
                    checkAdvance();
                    break;
                }
            }

            if (get().type != GrLexeme.Type.rightCurlyBrace)
                logError(getError(Error.missingCurlyBraces), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.rightCurlyBrace),
                        getPrettyLexemeType(get().type)));
            checkAdvance();
        }
        else {
            if (get().type != GrLexeme.Type.semicolon)
                skipStatement();
            else if (get().type == GrLexeme.Type.semicolon)
                checkAdvance();
        }

        closeBlock();
    }

    private void parseDieStatement() {
        if (!currentFunction.instructions.length ||
            currentFunction.instructions[$ - 1].opcode != GrOpcode.die)
            addDie();
        advance();
    }

    private void parseQuitStatement() {
        if (!currentFunction.instructions.length ||
            currentFunction.instructions[$ - 1].opcode != GrOpcode.exit)
            addQuit();
        advance();
    }

    private void parseYieldStatement() {
        addInstruction(GrOpcode.yield, 0u);
        advance();
    }

    // Gestion d’erreurs
    private void parseThrowStatement() {
        advance();
        GrType type = parseSubExpression(GR_SUBEXPR_TERMINATE_SEMICOLON | GR_SUBEXPR_EXPECTING_VALUE)
            .type;
        checkAdvance();
        convertType(type, grString);
        addInstruction(GrOpcode.throw_);
        checkDeferStatement();
    }

    private void parseExceptionHandler() {
        advance();

        const auto isolatePosition = currentFunction.instructions.length;
        addInstruction(GrOpcode.try_);

        parseBlock();

        const uint fileId = get().fileId;
        if (get().type == GrLexeme.Type.catch_) {
            advance();

            if (get().type != GrLexeme.Type.leftParenthesis)
                logError(format(getError(Error.missingParenthesesAfterX), getPrettyLexemeType(GrLexeme.Type.else_)),
                    format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.leftParenthesis),
                        getPrettyLexemeType(get().type)));
            advance();

            if (get().type != GrLexeme.Type.identifier)
                logError(getError(Error.missingIdentifier),
                    format(getError(Error.expectedIdentifierFoundX),
                        getPrettyLexemeType(get().type)));
            GrVariable errVariable = registerVariable(get().svalue, grString,
                false, false, false, false);

            advance();
            if (get().type != GrLexeme.Type.rightParenthesis)
                logError(getError(Error.missingParentheses), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.rightParenthesis),
                        getPrettyLexemeType(get().type)));
            advance();

            const auto capturePosition = currentFunction.instructions.length;
            addInstruction(GrOpcode.catch_);

            addInstruction(GrOpcode.globalPop);
            addSetInstruction(errVariable, fileId, grString);

            parseBlock(true);

            const auto endPosition = currentFunction.instructions.length;

            setInstruction(GrOpcode.try_, cast(uint) isolatePosition,
                cast(uint)(capturePosition - isolatePosition), true);
            setInstruction(GrOpcode.catch_, cast(uint) capturePosition,
                cast(uint)(endPosition - capturePosition), true);
        }
        else {
            const auto capturePosition = currentFunction.instructions.length;
            addInstruction(GrOpcode.catch_);
            addInstruction(GrOpcode.globalPop);
            addInstruction(GrOpcode.shiftStack, 1, true);

            const auto endPosition = currentFunction.instructions.length;

            setInstruction(GrOpcode.try_, cast(uint) isolatePosition,
                cast(uint)(capturePosition - isolatePosition), true);
            setInstruction(GrOpcode.catch_, cast(uint) capturePosition,
                cast(uint)(endPosition - capturePosition), true);
        }
    }

    // Bloc de code différé
    private void openDeferrableSection() {
        auto deferrableSection = new GrDeferrableSection;
        deferrableSection.deferInitPositions = cast(uint) currentFunction.instructions.length;
        currentFunction.deferrableSections ~= deferrableSection;

        currentFunction.isDeferrableSectionLocked.length++;
    }

    private void closeDeferrableSection() {
        if (!currentFunction.deferrableSections.length)
            throw new Exception("attempting to close a non-existing function");

        foreach (deferBlock; currentFunction.deferrableSections[$ - 1].deferredBlocks) {
            currentFunction.registeredDeferBlocks ~= deferBlock;
        }

        currentFunction.deferrableSections.length--;
        currentFunction.isDeferrableSectionLocked.length--;
    }

    private void parseDeferStatement() {
        if (currentFunction.isDeferrableSectionLocked[$ - 1])
            logError(getError(Error.deferInsideDefer), getError(Error.cantDeferInsideDefer));
        advance();

        // On enregistre la position du bloc pour une analyse ultérieure
        GrDeferBlock deferBlock = new GrDeferBlock;
        deferBlock.position = cast(uint) currentFunction.instructions.length;
        deferBlock.parsePosition = current;
        deferBlock.scopeLevel = scopeLevel;
        currentFunction.deferrableSections[$ - 1].deferredBlocks ~= deferBlock;

        addInstruction(GrOpcode.defer);

        // On analysera le bloc différé à la fin du bloc extérieur
        skipBlock();
    }

    private void checkDeferStatement() {
        if (currentFunction.isDeferrableSectionLocked[$ - 1]) {
            GrLexeme.Type type = get().type;
            logError(format(getError(Error.xInsideDefer), getPrettyLexemeType(type)),
                format(getError(Error.cantXInsideDefer), getPrettyLexemeType(type)));
        }
    }

    private void registerDeferBlocks() {
        const auto tempParsePosition = current;
        const auto startDeferPos = cast(uint) currentFunction.instructions.length;

        const int tempScopeLevel = scopeLevel;
        while (currentFunction.registeredDeferBlocks.length) {
            GrDeferBlock deferBlock = currentFunction.registeredDeferBlocks[0];
            currentFunction.registeredDeferBlocks = currentFunction.registeredDeferBlocks[1 .. $];

            setInstruction(GrOpcode.defer, deferBlock.position,
                cast(int)(currentFunction.instructions.length - deferBlock.position), true);
            current = deferBlock.parsePosition;
            scopeLevel = deferBlock.scopeLevel;

            currentFunction.isDeferrableSectionLocked[$ - 1] = true;
            parseBlock(true);
            currentFunction.isDeferrableSectionLocked[$ - 1] = false;

            addInstruction(GrOpcode.unwind);
        }
        currentFunction.registeredDeferBlocks.length = 0;
        current = tempParsePosition;
        scopeLevel = tempScopeLevel;
    }

    // Ouvre une section pouvant être quitté
    private void openBreakableSection() {
        breaksJumps ~= [null];
        _isAssignationOptimizable = false;
    }

    // Ferme une section pouvant être quitté
    private void closeBreakableSection() {
        if (!breaksJumps.length)
            throw new Exception("attempting to close a non-existing function");

        uint[] breaks = breaksJumps[$ - 1];
        breaksJumps.length--;

        foreach (position; breaks)
            setInstruction(GrOpcode.jump, position,
                cast(int)(currentFunction.instructions.length - position), true);
        _isAssignationOptimizable = false;
    }

    private void parseBreakStatement() {
        if (!breaksJumps.length)
            logError(getError(Error.breakOutsideLoop), getError(Error.cantBreakOutsideLoop));

        breaksJumps[$ - 1] ~= cast(uint) currentFunction.instructions.length;
        addInstruction(GrOpcode.jump);
        advance();
    }

    // Ouvre une section pouvant être réitéré
    private void openContinuableSection(bool isYieldable) {
        continuesJumps.length++;
        continuesUseYield ~= isYieldable;
        _isAssignationOptimizable = false;
    }

    // Ferme une section pouvant être réitéré
    private void closeContinuableSection() {
        if (!continuesJumps.length)
            throw new Exception("attempting to close a non-existing function");

        uint[] continues = continuesJumps[$ - 1];
        const uint destination = continuesDestinations[$ - 1];
        continuesJumps.length--;
        continuesDestinations.length--;
        continuesUseYield.length--;

        foreach (position; continues)
            setInstruction(GrOpcode.jump, position, cast(int)(destination - position), true);
        _isAssignationOptimizable = false;
    }

    private void setContinuableSectionDestination() {
        continuesDestinations ~= cast(uint) currentFunction.instructions.length;
    }

    private void parseContinueStatement() {
        if (!continuesJumps.length)
            logError(getError(Error.continueOutsideLoop), getError(Error.cantContinueOutsideLoop));

        if (continuesUseYield[$ - 1])
            addInstruction(GrOpcode.yield);
        continuesJumps[$ - 1] ~= cast(uint) currentFunction.instructions.length;
        addInstruction(GrOpcode.jump);
        advance();
    }

    private void parseVariableDeclaration(bool isConst, bool isGlobal, bool isPublic) {
        checkAdvance();

        GrType type = GrType.Base.void_;
        bool isAuto;

        string[] identifiers;
        do {
            if (get().type == GrLexeme.Type.comma)
                checkAdvance();

            if (get().type != GrLexeme.Type.identifier)
                logError(format(getError(Error.expectedIdentifierFoundX),
                        getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));

            identifiers ~= get().svalue;
            checkAdvance();
        }
        while (get().type == GrLexeme.Type.comma);

        if (get().type == GrLexeme.Type.colon) {
            checkAdvance();
            type = parseType(true);
        }
        else {
            isAuto = true;
        }

        GrVariable[] lvalues;
        foreach (string identifier; identifiers) {
            lvalues ~= registerVariable(identifier, type, isAuto, isGlobal, isConst, isPublic);
        }

        parseAssignList(lvalues, true);
    }

    private GrType parseFunctionReturnType() {
        GrType returnType = GrType.Base.void_;
        if (get().isType) {
            switch (get().type) with (GrLexeme.Type) {
            case integerType:
                returnType = GrType(GrType.Base.int_);
                break;
            case floatType:
                returnType = GrType(GrType.Base.float_);
                break;
            case booleanType:
                returnType = GrType(GrType.Base.bool_);
                break;
            case stringType:
                returnType = GrType(GrType.Base.string_);
                break;
            case listType:
                returnType = GrType(GrType.Base.list);
                break;
            case func:
                GrType type = GrType.Base.func;
                checkAdvance();
                type.mangledType = grMangleSignature(parseSignature());
                returnType = type;
                break;
            case task:
                GrType type = GrType.Base.task;
                checkAdvance();
                type.mangledType = grMangleSignature(parseSignature());
                returnType = type;
                break;
            case event:
                GrType type = GrType.Base.event;
                checkAdvance();
                type.mangledType = grMangleSignature(parseSignature());
                returnType = type;
                break;
            default:
                logError(format(getError(Error.xNotValidRetType), getPrettyLexemeType(get().type)),
                    format(getError(Error.xNotValidRetType), getPrettyLexemeType(get().type)));
            }
            checkAdvance();
        }

        return returnType;
    }

    /**
    ---
    if(SUBEXPR) BLOCK
    else if(SUBEXPR) BLOCK
    else unless(SUBEXPR) BLOCK
    else(SUBEXPR) BLOCK
    ---
    */
    private void parseIfStatement() {
        bool isNegative = get().type == GrLexeme.Type.unless;
        advance();
        if (isNegative && get().type == GrLexeme.Type.if_)
            advance();
        if (get().type != GrLexeme.Type.leftParenthesis)
            logError(format(getError(Error.missingParenthesesAfterX), getPrettyLexemeType(isNegative ?
                    GrLexeme.Type.unless : GrLexeme.Type.if_)), format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.leftParenthesis),
                    getPrettyLexemeType(get().type)));

        advance();
        GrSubExprResult result = parseSubExpression();
        convertType(result.type, grBool, get().fileId);
        advance();

        // Si le `if` ou  `unless` n’est pas vérifié, on saute vers la fin du bloc
        uint jumpPosition = cast(uint) currentFunction.instructions.length;
        addInstruction(isNegative ? GrOpcode.jumpNotEqual : GrOpcode.jumpEqual);

        parseBlock(true); //{ .. }

        // Si des `else` sont présent, alors on doit pouvoir sortir du bloc avec un saut
        uint[] exitJumps;
        if (get().type == GrLexeme.Type.else_) {
            exitJumps ~= cast(uint) currentFunction.instructions.length;
            addInstruction(GrOpcode.jump);
        }

        // On met la destination du saut du `if`/`unless` s’il n’est pas vérifié
        setInstruction(isNegative ? GrOpcode.jumpNotEqual : GrOpcode.jumpEqual, jumpPosition,
            cast(int)(currentFunction.instructions.length - jumpPosition), true);

        bool isElseIf;
        do {
            isElseIf = false;
            if (get().type == GrLexeme.Type.else_) {
                checkAdvance();
                if (get().type == GrLexeme.Type.if_ || get().type == GrLexeme.Type.unless) {
                    isNegative = get().type == GrLexeme.Type.unless;
                    isElseIf = true;
                    checkAdvance();
                    if (isNegative && get().type == GrLexeme.Type.if_)
                        checkAdvance();
                    if (get().type != GrLexeme.Type.leftParenthesis)
                        logError(format(getError(Error.missingParenthesesAfterX), getPrettyLexemeType(isNegative ?
                                GrLexeme.Type.unless : GrLexeme.Type.if_)), format(getError(Error.expectedXFoundY),
                                getPrettyLexemeType(GrLexeme.Type.leftParenthesis),
                                getPrettyLexemeType(get().type)));
                    checkAdvance();

                    parseSubExpression();
                    advance();

                    jumpPosition = cast(uint) currentFunction.instructions.length;
                    // Si le `if` ou  `unless` n’est pas vérifié, on saute vers la fin du bloc
                    addInstruction(isNegative ? GrOpcode.jumpNotEqual : GrOpcode.jumpEqual);

                    parseBlock(true); //{ .. }

                    // On sort du bloc avec un saut
                    exitJumps ~= cast(uint) currentFunction.instructions.length;
                    addInstruction(GrOpcode.jump);

                    // On met la destination du saut du `if`/`unless` s’il n’est pas vérifié
                    setInstruction(isNegative ? GrOpcode.jumpNotEqual : GrOpcode.jumpEqual, jumpPosition,
                        cast(int)(currentFunction.instructions.length - jumpPosition), true);
                }
                else
                    parseBlock(true);
            }
        }
        while (isElseIf);

        foreach (uint position; exitJumps)
            setInstruction(GrOpcode.jump, position,
                cast(int)(currentFunction.instructions.length - position), true);
    }

    private GrType parseChannelBuilder() {
        GrType channelType = GrType.Base.channel;
        int channelSize = 1;

        checkAdvance();
        if (get().type != GrLexeme.Type.lesser)
            logError(format(getError(Error.missingXInChanSignature), getPrettyLexemeType(GrLexeme.Type.lesser)),
                format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.lesser), getPrettyLexemeType(get().type)));
        checkAdvance();
        GrType subType = parseType();

        distinguishTemplateLexemes();
        GrLexeme lex = get();
        if (lex.type == GrLexeme.Type.comma) {
            checkAdvance();
            lex = get();
            if (lex.type != GrLexeme.Type.int_)
                logError(getError(Error.chanSizeMustBePositive),
                    format(getError(Error.expectedIntFoundX), getPrettyLexemeType(get().type)));
            channelSize = lex.ivalue > int.max ? 1 : cast(int) lex.ivalue;
            if (channelSize < 1)
                logError(getError(Error.chanSizeMustBeOneOrHigher),
                    format(getError(Error.expectedAtLeastSizeOf1FoundX), channelSize));
            checkAdvance();
        }
        else if (lex.type != GrLexeme.Type.greater) {
            logError(getError(Error.missingCommaOrGreaterInsideChanSignature),
                format(getError(Error.expectedCommaOrGreaterFoundX),
                    getPrettyLexemeType(get().type)));
        }
        distinguishTemplateLexemes();
        lex = get();
        if (lex.type != GrLexeme.Type.greater)
            logError(format(getError(Error.missingXInChanSignature), getPrettyLexemeType(GrLexeme.Type.greater)),
                format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.greater), getPrettyLexemeType(get().type)));
        checkAdvance();
        channelType.mangledType = grMangleSignature([subType]);

        final switch (subType.base) with (GrType.Base) {
        case int_:
        case bool_:
        case func:
        case task:
        case event:
        case enum_:
        case float_:
        case string_:
        case class_:
        case optional:
        case list:
        case native:
        case channel:
        case reference:
            addInstruction(GrOpcode.channel, channelSize);
            break;
        case void_:
        case null_:
        case internalTuple:
            logError(format(getError(Error.chanCantBeOfTypeX),
                    getPrettyType(grChannel(subType))), getError(Error.invalidChanType));
        }
        return channelType;
    }

    /**
    ---
    switch(SUBEXPR)
    case(SUBEXPR) BLOCK
    case(SUBEXPR) BLOCK
    default BLOCK
    ---
    */
    private void parseSwitchStatement() {
        advance();
        if (get().type != GrLexeme.Type.leftParenthesis)
            logError(format(getError(Error.missingParenthesesAfterX), getPrettyLexemeType(GrLexeme.Type.switch_)),
                format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.leftParenthesis),
                    getPrettyLexemeType(get().type)));

        advance();
        const uint fileId = get().fileId;
        GrType switchType = parseSubExpression().type;
        GrVariable switchVar = registerSpecialVariable("switch", switchType);
        addSetInstruction(switchVar, fileId);
        advance();

        // On peut sortir d’un `switch`
        openBreakableSection();
        uint[] exitJumps;
        uint jumpPosition, casePosition, defaultCasePosition, defaultCaseKeywordPosition;
        bool hasCase, hasDefaultCase;

        while (get().type == GrLexeme.Type.case_ || get().type == GrLexeme.Type.default_) {
            casePosition = current;
            if (get().type == GrLexeme.Type.default_) {
                advance();
                if (hasDefaultCase)
                    logError(format(getError(Error.onlyOneDefaultCasePerX),
                            getPrettyLexemeType(GrLexeme.Type.switch_)),
                        getError(Error.defaultCaseAlreadyDef), "", casePosition - current,
                        getError(Error.prevDefaultCaseDef), defaultCaseKeywordPosition);
                hasDefaultCase = true;
                defaultCasePosition = current;
                defaultCaseKeywordPosition = casePosition;
                skipBlock();
                continue;
            }
            advance();
            if (get().type != GrLexeme.Type.leftParenthesis)
                logError(format(getError(Error.missingParenthesesAfterX), getPrettyLexemeType(GrLexeme.Type.case_)),
                    format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.leftParenthesis),
                        getPrettyLexemeType(get().type)));
            advance();
            hasCase = true;
            addGetInstruction(switchVar);
            GrType caseType = parseSubExpression().type;
            addBinaryOperator(GrLexeme.Type.equal, switchType, caseType, fileId);
            advance();

            // On saute au cas suivant
            jumpPosition = cast(uint) currentFunction.instructions.length;
            addInstruction(GrOpcode.jumpEqual);

            parseBlock(true);

            exitJumps ~= cast(uint) currentFunction.instructions.length;
            addInstruction(GrOpcode.jump);

            // On saute au cas suivant
            setInstruction(GrOpcode.jumpEqual, jumpPosition,
                cast(int)(currentFunction.instructions.length - jumpPosition), true);
        }

        if (hasDefaultCase) {
            const uint tmp = current;
            current = defaultCasePosition;
            parseBlock(true);
            current = tmp;
        }

        // Un `break` finit ici
        closeBreakableSection();

        foreach (uint position; exitJumps)
            setInstruction(GrOpcode.jump, position,
                cast(int)(currentFunction.instructions.length - position), true);
    }

    /**
    ---
    select
    case(SUBEXPR) BLOCK
    case(SUBEXPR) BLOCK
    case() BLOCK
    ---
    */
    private void parseSelectStatement() {
        advance();

        // On peut sortir d’un `select`
        openBreakableSection();
        uint[] exitJumps;
        uint jumpPosition, casePosition, defaultCasePosition, defaultCaseKeywordPosition;
        bool hasCase, hasDefaultCase;
        uint startJump = cast(uint) currentFunction.instructions.length;

        addInstruction(GrOpcode.startSelectChannel);
        while (get().type == GrLexeme.Type.case_ || get().type == GrLexeme.Type.default_) {
            casePosition = current;
            if (get().type == GrLexeme.Type.default_) {
                advance();
                if (hasDefaultCase)
                    logError(format(getError(Error.onlyOneDefaultCasePerX), getPrettyLexemeType(GrLexeme.Type.select)),
                        getError(Error.defaultCaseAlreadyDef), "", casePosition - current,
                        getError(Error.prevDefaultCaseDef), defaultCaseKeywordPosition);
                hasDefaultCase = true;
                defaultCasePosition = current;
                defaultCaseKeywordPosition = casePosition;
                skipBlock();
                continue;
            }
            advance();
            if (get().type != GrLexeme.Type.leftParenthesis)
                logError(format(getError(Error.missingParenthesesAfterX), getPrettyLexemeType(GrLexeme.Type.case_)),
                    format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.leftParenthesis),
                        getPrettyLexemeType(get().type)));
            advance();
            hasCase = true;
            jumpPosition = cast(uint) currentFunction.instructions.length;
            addInstruction(GrOpcode.tryChannel);
            parseSubExpression();
            advance();

            addInstruction(GrOpcode.checkChannel);

            parseBlock(true);

            exitJumps ~= cast(uint) currentFunction.instructions.length;
            addInstruction(GrOpcode.jump);

            setInstruction(GrOpcode.tryChannel, jumpPosition,
                cast(int)(currentFunction.instructions.length - jumpPosition), true);
        }

        if (hasDefaultCase) {
            // Si un cas par défaut est spécifié, il s’exécutera si aucun autre cas n’est traitable.
            // De même, ça rend l’opération `select` non-bloquante care au moins un cas est garanti de s’exécuter.
            const uint tmp = current;
            current = defaultCasePosition;
            parseBlock(true);
            current = tmp;
        }
        else {
            // Sans cas par défaut, `select` est une opération bloquante jusqu’à ce q’un cas soit traité.
            // On ajoute donc un `yield`, puis on saute au début du `select` pour l’évaluer à nouveau.
            addInstruction(GrOpcode.yield);
            addInstruction(GrOpcode.jump,
                cast(int)(startJump - currentFunction.instructions.length), true);
        }

        // Un `break` finit ici
        closeBreakableSection();

        foreach (uint position; exitJumps)
            setInstruction(GrOpcode.jump, position,
                cast(int)(currentFunction.instructions.length - position), true);
        addInstruction(GrOpcode.endSelectChannel);
    }

    /**
    ---
    while [yield] (SUBEXPR)
        BLOCK
    ---
    */
    private void parseWhileStatement() {
        const bool isNegative = get().type == GrLexeme.Type.until;
        advance();

        bool isYieldable;
        if (get().type == GrLexeme.Type.yield) {
            isYieldable = true;
            advance();
        }

        if (get().type != GrLexeme.Type.leftParenthesis)
            logError(format(getError(Error.missingParenthesesAfterX), getPrettyLexemeType(isNegative ?
                    GrLexeme.Type.until : GrLexeme.Type.while_)), format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.leftParenthesis),
                    getPrettyLexemeType(get().type)));

        // `while` peut avoir un `break` ou un `continue`.
        openBreakableSection();
        openContinuableSection(isYieldable);

        // Le `continue` retourne ici
        setContinuableSectionDestination();

        uint conditionPosition, blockPosition = cast(uint) currentFunction.instructions.length;

        advance();
        parseSubExpression();

        advance();
        conditionPosition = cast(uint) currentFunction.instructions.length;
        addInstruction(GrOpcode.jumpEqual);

        parseBlock(true);

        if (isYieldable)
            addInstruction(GrOpcode.yield);

        addInstruction(GrOpcode.jump,
            cast(int)(blockPosition - currentFunction.instructions.length), true);
        setInstruction(isNegative ? GrOpcode.jumpNotEqual : GrOpcode.jumpEqual, conditionPosition,
            cast(int)(currentFunction.instructions.length - conditionPosition), true);

        // `while` peut avoir un `break` ou un `continue`.
        closeBreakableSection();
        closeContinuableSection();
    }

    /**
    ---
    do BLOCK
    while(SUBEXPR)
    ---
    */
    private void parseDoWhileStatement() {
        advance();

        bool isYieldable;
        if (get().type == GrLexeme.Type.yield) {
            isYieldable = true;
            advance();
        }

        // `while` peut avoir un `break` ou un `continue`.
        openBreakableSection();
        openContinuableSection(isYieldable);

        uint blockPosition = cast(uint) currentFunction.instructions.length;

        parseBlock(true);

        bool isNegative;
        if (get().type == GrLexeme.Type.until)
            isNegative = true;
        else if (get().type != GrLexeme.Type.while_)
            logError(getError(Error.missingWhileOrUntilAfterLoop),
                format(getError(Error.expectedWhileOrUntilFoundX), getPrettyLexemeType(get().type)));
        advance();

        // Le `continue` retourne ici
        setContinuableSectionDestination();

        if (get().type != GrLexeme.Type.leftParenthesis)
            logError(format(getError(Error.missingParenthesesAfterX), getPrettyLexemeType(isNegative ?
                    GrLexeme.Type.until : GrLexeme.Type.while_)), format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.leftParenthesis),
                    getPrettyLexemeType(get().type)));

        advance();
        parseSubExpression();
        advance();

        if (isYieldable)
            addInstruction(GrOpcode.yield);

        addInstruction(isNegative ? GrOpcode.jumpEqual : GrOpcode.jumpNotEqual,
            cast(int)(blockPosition - currentFunction.instructions.length), true);

        // `while` peut avoir un `break` ou un `continue`.
        closeBreakableSection();
        closeContinuableSection();
    }

    /// Analyse une déclaration de variable utilisé dans pour les boucles `for` et `loop`
    private GrVariable parseIteratorDeclaration() {
        GrType type;
        bool isAuto, isTyped = true;

        if (get().type != GrLexeme.Type.identifier)
            logError(format(getError(Error.expectedIdentifierFoundX),
                    getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));
        const string identifier = get().svalue;
        checkAdvance();

        if (get().type == GrLexeme.Type.colon) {
            checkAdvance();
            type = parseType(true);
        }
        else {
            isAuto = true;
        }

        return registerVariable(identifier, type, isTyped ? isAuto : true, false, false, false);
    }

    /// Permet l’itération sur une liste ou un itérateur
    private void parseForStatement() {
        advance();

        bool isYieldable;
        if (get().type == GrLexeme.Type.yield) {
            isYieldable = true;
            advance();
        }

        const uint fileId = get().fileId;
        if (get().type != GrLexeme.Type.leftParenthesis)
            logError(format(getError(Error.missingParenthesesAfterX), getPrettyLexemeType(GrLexeme.Type.for_)),
                format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.leftParenthesis),
                    getPrettyLexemeType(get().type)));

        advance();
        currentFunction.openScope();

        GrVariable variable = parseIteratorDeclaration();

        if (get().type != GrLexeme.Type.comma)
            logError(format(getError(Error.missingCommaInX), getPrettyLexemeType(GrLexeme.Type.for_)),
                format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.comma), getPrettyLexemeType(get().type)));
        advance();

        GrType containerType = parseSubExpression().type;

        switch (containerType.base) with (GrType.Base) {
        case list: {
                // Initialisation
                GrType subType = grUnmangle(containerType.mangledType);
                GrVariable iterator = registerSpecialVariable("it", grInt);
                GrVariable index = registerSpecialVariable("idx", grInt);
                GrVariable list = registerSpecialVariable("ary", containerType);

                if (variable.isAuto && subType.base != GrType.Base.void_) {
                    variable.isAuto = false;
                    variable.type = subType;
                    setVariableRegister(variable);
                }

                // De la taille de la liste jusqu’à 0
                addSetInstruction(list, fileId, containerType, true);
                final switch (subType.base) with (GrType.Base) {
                case bool_:
                case int_:
                case func:
                case task:
                case event:
                case enum_:
                case float_:
                case string_:
                case optional:
                case list:
                case class_:
                case native:
                case channel:
                case reference:
                    addInstruction(GrOpcode.length_list);
                    break;
                case void_:
                case null_:
                case internalTuple:
                    logError(format(getError(Error.listCantBeOfTypeX),
                            getPrettyType(grList(subType))), getError(Error.invalidListType));
                    break;
                }
                addInstruction(GrOpcode.setupIterator);
                addSetInstruction(iterator, fileId);

                // On met l’index à -1
                addIntConstant(-1);
                addSetInstruction(index, fileId);

                // `for` peut avoir un `break` ou un `continue`.
                openBreakableSection();
                openContinuableSection(isYieldable);

                // Le `continue` arrive ici
                setContinuableSectionDestination();

                advance();
                uint blockPosition = cast(uint) currentFunction.instructions.length;

                addGetInstruction(iterator, GrType(GrType.Base.int_));
                addInstruction(GrOpcode.decrement_int);
                addSetInstruction(iterator, fileId);

                addGetInstruction(iterator, GrType(GrType.Base.int_));
                uint jumpPosition = cast(uint) currentFunction.instructions.length;
                addInstruction(GrOpcode.jumpEqual);

                // On met à jour l’index
                addGetInstruction(list);
                addGetInstruction(index);
                addInstruction(GrOpcode.increment_int);
                addSetInstruction(index, fileId, grVoid, true);
                final switch (subType.base) with (GrType.Base) {
                case bool_:
                case int_:
                case func:
                case task:
                case event:
                case enum_:
                case float_:
                case string_:
                case optional:
                case list:
                case class_:
                case native:
                case channel:
                case reference:
                    addInstruction(GrOpcode.index2_list);
                    break;
                case void_:
                case null_:
                case internalTuple:
                    logError(format(getError(Error.listCantBeOfTypeX),
                            getPrettyType(grList(subType))), getError(Error.invalidListType));
                    break;
                }
                convertType(subType, variable.type, fileId);
                addSetInstruction(variable, fileId);

                parseBlock(true);

                if (isYieldable)
                    addInstruction(GrOpcode.yield);

                addInstruction(GrOpcode.jump,
                    cast(int)(blockPosition - currentFunction.instructions.length), true);
                setInstruction(GrOpcode.jumpEqual, jumpPosition,
                    cast(int)(currentFunction.instructions.length - jumpPosition), true);

                // Fin de la section
                closeBreakableSection();
                closeContinuableSection();
            }
            break;
        case native:
        case class_: {
                GrVariable iterator = registerSpecialVariable("it", containerType);

                GrType subType;
                auto matching = getFirstMatchingFuncOrPrim("next", [
                        containerType
                    ], fileId);
                GrFunction nextFunc = matching.func;
                GrPrimitive nextPrim = matching.prim;
                if (nextPrim) {
                    if (nextPrim.outSignature.length != 1 ||
                        nextPrim.outSignature[0].base != GrType.Base.optional) {
                        logError(format(getError(Error.primXMustRetOptional), getPrettyFunctionCall("next",
                                [containerType])), getError(Error.signatureMismatch));
                    }
                    subType = grUnmangle(nextPrim.outSignature[0].mangledType);
                }
                else if (nextFunc) {
                    if (nextFunc.outSignature.length != 1 ||
                        nextFunc.outSignature[0].base != GrType.Base.optional) {
                        logError(format(getError(Error.funcXMustRetOptional),
                                getPrettyFunction(nextFunc)), getError(Error.signatureMismatch));
                    }
                    subType = grUnmangle(nextFunc.outSignature[0].mangledType);
                }
                else {
                    logError(format(getError(Error.xNotDef), getPrettyFunctionCall("next",
                            [containerType])), getError(Error.notIterable));
                }

                if (variable.isAuto && subType.base != GrType.Base.void_) {
                    variable.isAuto = false;
                    variable.type = subType;
                    setVariableRegister(variable);
                }
                addSetInstruction(iterator, fileId, containerType);

                // `for` peut avoir un `break` ou un `continue`.
                openBreakableSection();
                openContinuableSection(isYieldable);

                // Le `continue` arrive ici
                setContinuableSectionDestination();

                advance();
                uint blockPosition = cast(uint) currentFunction.instructions.length;

                addGetInstruction(iterator, containerType);
                if (nextPrim)
                    addInstruction(GrOpcode.primitiveCall, nextPrim.index);
                else
                    addFunctionCall(nextFunc, fileId);

                uint jumpPosition = cast(uint) currentFunction.instructions.length;
                addInstruction(GrOpcode.optionalCall2);

                addSetInstruction(variable, fileId, subType);

                parseBlock();

                if (isYieldable)
                    addInstruction(GrOpcode.yield);

                addInstruction(GrOpcode.jump,
                    cast(int)(blockPosition - currentFunction.instructions.length), true);
                setInstruction(GrOpcode.optionalCall2, jumpPosition,
                    cast(int)(currentFunction.instructions.length - jumpPosition), true);

                // Fin de la section
                closeBreakableSection();
                closeContinuableSection();
            }
            break;
        default:
            logError(format(getError(Error.forCantIterateOverX),
                    getPrettyType(containerType)), getError(Error.notIterable));
            break;
        }
        currentFunction.closeScope();
    }

    /// Ignore tout depuis un `(` jusqu’à son `)` correspondant.
    private void skipParenthesis() {
        if (get().type != GrLexeme.Type.leftParenthesis)
            return;
        advance();

        __loop: while (!isEnd()) {
            switch (get().type) with (GrLexeme.Type) {
            case rightParenthesis:
                advance();
                return;
            case rightBracket:
            case rightCurlyBrace:
            case semicolon:
                break __loop;
            case leftParenthesis:
                skipParenthesis();
                break;
            case leftBracket:
                skipBrackets();
                break;
            case leftCurlyBrace:
                skipBlock();
                break;
            default:
                advance();
                break;
            }
        }
    }

    /// Ignore tout depuis un `[` jusqu’à son `]` correspondant.
    private void skipBrackets() {
        if (get().type != GrLexeme.Type.leftBracket)
            return;
        advance();

        __loop: while (!isEnd()) {
            switch (get().type) with (GrLexeme.Type) {
            case rightBracket:
                advance();
                return;
            case rightParenthesis:
            case rightCurlyBrace:
            case semicolon:
                break __loop;
            case leftParenthesis:
                skipParenthesis();
                break;
            case leftBracket:
                skipBrackets();
                break;
            case leftCurlyBrace:
                skipBlock();
                break;
            default:
                advance();
                break;
            }
        }
    }

    /// Retourne le nombre de paramètres séparés par des virgules à l’intérieur d’une paire de `()`, `[]` ou `{}`.
    private int checkArity() {
        int arity;
        const int position = current;

        bool useParenthesis, useBrackets, useCurlyBraces;

        switch (get().type) with (GrLexeme.Type) {
        case leftParenthesis:
            advance();
            useParenthesis = true;
            if (get(1).type != GrLexeme.Type.rightParenthesis)
                arity++;
            break;
        case leftBracket:
            advance();
            useBrackets = true;
            if (get(1).type != GrLexeme.Type.rightBracket)
                arity++;
            break;
        case leftCurlyBrace:
            advance();
            useCurlyBraces = true;
            if (get(1).type != GrLexeme.Type.rightCurlyBrace)
                arity++;
            break;
        default:
            logError(getError(Error.cantEvalArityUnknownCompound), getError(Error.arityEvalError));
            break;
        }

        __loop: while (!isEnd()) {
            switch (get().type) with (GrLexeme.Type) {
            case comma:
                arity++;
                advance();
                break;
            case rightParenthesis:
                if (!useParenthesis)
                    goto default;
                break __loop;
            case rightBracket:
                if (!useBrackets)
                    goto default;
                break __loop;
            case rightCurlyBrace:
                if (!useCurlyBraces)
                    goto default;
                break __loop;
            case semicolon:
                break __loop;
            case leftParenthesis:
                skipParenthesis();
                break;
            case leftBracket:
                skipBrackets();
                break;
            case leftCurlyBrace:
                skipBlock();
                break;
            default:
                advance();
                break;
            }
        }

        current = position;
        return arity;
    }

    /**
    Il y a trois types de boucles `loop`
    - La boucle infinie sans paramètres:
    ---
    loop print("Infini !");
    ---
    - La boucle finie, avec un paramètre:
    ---
    loop(5) print("Je m’affiche 5 fois!");
    ---
    - La boucle finie avec un itérateur:
    ---
    loop(i, 5) print("Itérateur = " ~ i as string);
    ---
    */
    private void parseLoopStatement() {
        bool isInfinite, hasCustomIterator;
        GrVariable iterator, customIterator;

        const uint fileId = get().fileId;
        currentFunction.openScope();
        advance();

        bool isYieldable;
        if (get().type == GrLexeme.Type.yield) {
            isYieldable = true;
            advance();
        }

        if (get().type == GrLexeme.Type.leftParenthesis) {
            const int arity = checkArity();
            advance();
            if (arity == 2) {
                hasCustomIterator = true;
                customIterator = parseIteratorDeclaration();
                if (customIterator.isAuto) {
                    customIterator.isAuto = false;
                    customIterator.type = grInt;
                    setVariableRegister(customIterator);
                }
                else if (customIterator.type != grInt) {
                    logError(format(getError(Error.typeOfIteratorMustBeIntNotX),
                            getPrettyType(customIterator.type)), getError(Error.iteratorMustBeInt));
                }

                addIntConstant(-1);
                addSetInstruction(customIterator, fileId);

                if (get().type != GrLexeme.Type.comma)
                    logError(format(getError(Error.missingCommaInX), getPrettyLexemeType(GrLexeme.Type.loop)),
                        format(getError(Error.expectedXFoundY),
                            getPrettyLexemeType(GrLexeme.Type.comma),
                            getPrettyLexemeType(get().type)));
                advance();
            }

            // Initialisation du compteur
            iterator = registerSpecialVariable("it", GrType(GrType.Base.int_));

            GrType type = parseSubExpression().type;
            advance();

            convertType(type, grInt, fileId);
            addInstruction(GrOpcode.setupIterator);
            addSetInstruction(iterator, fileId);
        }
        else
            isInfinite = true;

        // `for` peut avoir un `break` ou un `continue`.
        openBreakableSection();
        openContinuableSection(isYieldable);

        // Le `continue` arrive ici
        setContinuableSectionDestination();

        uint blockPosition = cast(uint) currentFunction.instructions.length;
        uint jumpPosition;

        if (!isInfinite) {
            addGetInstruction(iterator, grInt, false);
            addInstruction(GrOpcode.decrement_int);
            addSetInstruction(iterator, fileId);

            addGetInstruction(iterator, grInt);
            jumpPosition = cast(uint) currentFunction.instructions.length;
            addInstruction(GrOpcode.jumpEqual);

            if (hasCustomIterator) {
                addGetInstruction(customIterator, grInt, false);
                addInstruction(GrOpcode.increment_int);
                addSetInstruction(customIterator, fileId);
            }
        }

        parseBlock(true);

        if (isYieldable)
            addInstruction(GrOpcode.yield);

        addInstruction(GrOpcode.jump,
            cast(int)(blockPosition - currentFunction.instructions.length), true);
        if (!isInfinite)
            setInstruction(GrOpcode.jumpEqual, jumpPosition,
                cast(int)(currentFunction.instructions.length - jumpPosition), true);

        /* For peut avoir un `break` ou un `continue`. */
        closeBreakableSection();
        closeContinuableSection();
        currentFunction.closeScope();
    }

    /**
    Quitte la fonction et retourne les valeurs correspondantes à la signature de sortie de la fonction.
    ---
    return "Hello"; // Returne une chaîne de caractères.
    return; // Ne returne rien mais quitte quand même la fonction
    ---
    */
    private void parseReturnStatement() {
        const uint fileId = get().fileId;

        checkDeferStatement();
        checkAdvance();
        if (currentFunction.isTask || currentFunction.isEvent) {
            if (!currentFunction.instructions.length ||
                currentFunction.instructions[$ - 1].opcode != GrOpcode.die)
                addDie();
        }
        else {
            GrType[] expressionTypes;
            for (;;) {
                if (expressionTypes.length >= currentFunction.outSignature.length) {
                    logError(getError(Error.expectedXRetValFoundY),
                        format(getError(currentFunction.outSignature.length > 1 ?
                            Error.expectedXRetValsFoundY : Error.expectedXRetValFoundY),
                            currentFunction.outSignature.length, expressionTypes.length),
                        format(getError(Error.retSignatureOfTypeX),
                            getPrettyFunctionCall("", currentFunction.outSignature)), -1);
                }
                GrType type = parseSubExpression(
                    GR_SUBEXPR_TERMINATE_SEMICOLON | GR_SUBEXPR_TERMINATE_COMMA |
                        GR_SUBEXPR_EXPECTING_VALUE).type;
                if (type.base == GrType.Base.internalTuple) {
                    auto types = grUnpackTuple(type);
                    if (types.length) {
                        foreach (subType; types) {
                            if (expressionTypes.length >= currentFunction.outSignature.length) {
                                logError(getError(Error.expectedXRetValFoundY),
                                    format(getError(currentFunction.outSignature.length > 1 ?
                                        Error.expectedXRetValsFoundY
                                        : Error.expectedXRetValFoundY),
                                        currentFunction.outSignature.length, expressionTypes.length),
                                    format(getError(Error.retSignatureOfTypeX),
                                        getPrettyFunctionCall("", currentFunction.outSignature)),
                                    -1);
                            }
                            expressionTypes ~= convertType(subType,
                                currentFunction.outSignature[expressionTypes.length], fileId);
                        }
                    }
                    else
                        logError(getError(Error.exprYieldsNoVal),
                            getError(Error.expectedValFoundNothing));
                }
                else if (type.base != GrType.Base.void_) {
                    expressionTypes ~= convertType(type,
                        currentFunction.outSignature[expressionTypes.length], fileId);
                }
                if (get().type != GrLexeme.Type.comma)
                    break;
                checkAdvance();
            }
            if (get().type != GrLexeme.Type.semicolon)
                logError(getError(Error.missingSemicolonAfterExprList), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.semicolon),
                        getPrettyLexemeType(get().type)));
            checkAdvance();

            addReturn();

            for (int i; i < expressionTypes.length; i++) {
                if (expressionTypes[i] != currentFunction.outSignature[i])
                    logError(format(getError(Error.retTypeXNotMatchSignatureY), getPrettyType(expressionTypes[i]),
                            getPrettyType(currentFunction.outSignature[i])), format(getError(Error.expectedXVal),
                            getPrettyType(currentFunction.outSignature[i])),
                        format(getError(Error.retSignatureOfTypeX),
                            getPrettyFunctionCall("", currentFunction.outSignature)), -1);
            }
        }
    }

    /// Ajoute une instruction `return` qui dépile la pile d’appel.
    private void addReturn() {
        if (_options & GrOption.profile) {
            addInstruction(GrOpcode.debugProfileEnd);
        }
        addInstruction(GrOpcode.return_);
    }

    /// Ajoute une instruction `die` qui arrête la tâche actuelle.
    private void addDie() {
        checkDeferStatement();
        if (_options & GrOption.profile) {
            addInstruction(GrOpcode.debugProfileEnd);
        }
        addInstruction(GrOpcode.die);
    }

    /// Ajoute une instruction `exit` qui arrête toutes les tâches.
    private void addQuit() {
        checkDeferStatement();
        if (_options & GrOption.profile) {
            addInstruction(GrOpcode.debugProfileEnd);
        }
        addInstruction(GrOpcode.exit);
    }

    /// Priorité des opérateurs arithmétiques
    private int getLeftOperatorPriority(GrLexeme.Type type) {
        switch (type) with (GrLexeme.Type) {
        case assign: .. case powerAssign:
            return -1;
        case optionalOr:
            return 0;
        case arrow:
            return 1;
        case or:
            return 2;
        case and:
            return 3;
        case equal:
        case doubleEqual:
        case threeWayComparison:
        case notEqual:
        case greaterOrEqual:
        case greater:
        case lesserOrEqual:
        case lesser:
            return 4;
        case concatenate:
            return 5;
        case interval:
            return 6;
        case bitwiseOr:
        case bitwiseAnd:
        case bitwiseXor:
            return 7;
        case leftShift:
        case rightShift:
            return 8;
        case add:
        case substract:
            return 9;
        case multiply:
        case divide:
            return 10;
        case remainder:
            return 11;
        case power:
            return 12;
        case send:
            return 13;
        case not:
        case plus:
        case minus:
        case receive:
            return 14;
        case bitwiseNot:
            return 15;
        case increment:
        case decrement:
            return 16;
        default:
            logError(getError(Error.opNotListedInOpPriorityTable),
                getError(Error.unknownOpPriority));
            return 0;
        }
    }

    /// Priorité des opérateurs arithmétiques
    private int getRightOperatorPriority(GrLexeme.Type type) {
        switch (type) with (GrLexeme.Type) {
        case assign: .. case powerAssign:
            return 20;
        case optionalOr:
            return 0;
        case arrow:
            return 1;
        case or:
            return 2;
        case and:
            return 3;
        case equal:
        case doubleEqual:
        case threeWayComparison:
        case notEqual:
        case greaterOrEqual:
        case greater:
        case lesserOrEqual:
        case lesser:
            return 4;
        case concatenate:
            return 5;
        case interval:
            return 6;
        case bitwiseOr:
        case bitwiseAnd:
        case bitwiseXor:
            return 7;
        case leftShift:
        case rightShift:
            return 8;
        case add:
        case substract:
            return 9;
        case multiply:
        case divide:
            return 10;
        case remainder:
            return 11;
        case power:
            return 12;
        case send:
            return 13;
        case not:
        case plus:
        case minus:
        case receive:
            return 14;
        case bitwiseNot:
            return 15;
        case increment:
        case decrement:
            return 16;
        default:
            logError(getError(Error.opNotListedInOpPriorityTable),
                getError(Error.unknownOpPriority));
            return 0;
        }
    }

    /// Tente de convertir le type source au type destinataire.
    private GrType convertType(GrType src, GrType dst, uint fileId = 0,
        bool noFail = false, bool isExplicit = false) {
        if (src.base == dst.base) {
            final switch (src.base) with (GrType.Base) {
            case func:
                if (src.mangledType == dst.mangledType &&
                    src.mangledReturnType == dst.mangledReturnType)
                    return dst;
                break;
            case task:
            case event:
                if (src.mangledType == dst.mangledType)
                    return dst;
                break;
            case null_:
                break;
            case void_:
            case bool_:
            case int_:
            case float_:
            case string_:
            case enum_:
                return dst;
            case class_:
                string className = src.mangledType;
                for (;;) {
                    if (className == dst.mangledType)
                        return dst;
                    const GrClassDefinition classType = getClass(className, fileId);
                    if (!classType.parent.length)
                        break;
                    className = classType.parent;
                }
                break;
            case optional:
            case list:
            case channel:
            case reference:
            case internalTuple:
                if (dst.mangledType == src.mangledType)
                    return dst;
                break;
            case native:
                string nativeName = src.mangledType;
                for (;;) {
                    if (dst.mangledType == nativeName)
                        return dst;
                    const GrNativeDefinition nativeType = _data.getNative(nativeName);
                    if (!nativeType.parent.length)
                        break;
                    nativeName = nativeType.parent;
                }
                break;
            }
        }

        if (dst.base == GrType.Base.optional) {
            if (src.base == GrType.Base.null_)
                return dst;

            GrType subType = grUnmangle(dst.mangledType);

            if (convertType(src, subType, fileId, noFail, isExplicit).base == subType.base)
                return dst;
        }

        if (src.base == GrType.Base.internalTuple || dst.base == GrType.Base.internalTuple)
            logError(format(getError(Error.expectedXFoundY), getPrettyType(dst),
                    getPrettyType(src)), getError(Error.mismatchedTypes), "", -1);

        if (dst.base == GrType.Base.bool_) {
            final switch (src.base) with (GrType.Base) {
            case func:
            case task:
            case event:
            case void_:
            case bool_:
            case int_:
            case float_:
            case string_:
            case enum_:
            case list:
            case class_:
            case native:
            case channel:
            case reference:
            case internalTuple:
                break;
            case optional:
            case null_:
                addInstruction(GrOpcode.checkNull);
                return dst;
            }
        }

        // Conversion personnalisée
        if (addCustomConversion(src, dst, isExplicit, get().fileId) == dst)
            return dst;

        if (!noFail)
            logError(format(getError(Error.expectedXFoundY), getPrettyType(dst),
                    getPrettyType(src)), getError(Error.mismatchedTypes), "", -1);
        return GrType(GrType.Base.void_);
    }

    /// Convertit avec une fonction
    private GrType addCustomConversion(GrType leftType, GrType rightType,
        bool isExplicit, uint fileId) {
        GrType resultType = GrType.Base.void_;

        // Contrairement aux autres fonctions, on a besoin que le type de retour (`rightType`)
        // fasse partie de la signature.
        string name = "@as";
        GrType[] signature = [leftType, rightType];

        // primitive
        auto matching = getFirstMatchingFuncOrPrim(name, signature, fileId);
        if (matching.prim) {
            // On empêche certaines conversions implicites
            // Par ex: float -> int à cause d’un risque de perte d’information.
            if (matching.prim.isExplicit && !isExplicit)
                return resultType;
            addInstruction(GrOpcode.primitiveCall, matching.prim.index);
            if (matching.prim.outSignature.length != 1uL) {
                logError(getError(Error.opMustHave1RetVal), format(getError(matching.prim.outSignature.length > 1 ?
                        Error.expectedXRetValsFoundY : Error.expectedXRetValFoundY),
                        1, matching.prim.outSignature.length));
            }
            resultType = rightType;
        }

        // fonction
        if (resultType.base == GrType.Base.void_) {
            if (matching.func) {
                addFunctionCall(matching.func, fileId);
                if (matching.func.outSignature.length != 1uL) {
                    logError(getError(Error.opMustHave1RetVal), format(getError(matching.func.outSignature.length > 1 ?
                            Error.expectedXRetValsFoundY : Error.expectedXRetValFoundY),
                            1, matching.func.outSignature.length));
                }
                resultType = rightType;
            }
        }
        return resultType;
    }

    private GrType[] parseStaticCall() {
        GrType[] outputs;

        if (get().type != GrLexeme.Type.at)
            logError(format(getError(Error.expectedXFoundY), getPrettyLexemeType(GrLexeme.Type.at),
                    getPrettyLexemeType(get().type)), format(getError(Error.missingX),
                    getPrettyLexemeType(GrLexeme.Type.at)));
        checkAdvance();
        if (get().type != GrLexeme.Type.identifier)
            logError(format(getError(Error.expectedXFoundY), getPrettyLexemeType(GrLexeme.Type.identifier),
                    getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));
        uint fileId = get().fileId;
        GrType objectType = parseType(true);

        // Init
        if (get().type == GrLexeme.Type.leftCurlyBrace) {
            switch (objectType.base) with (GrType.Base) {
            case class_:
                outputs = [objectType];

                GrClassDefinition class_ = getClass(objectType.mangledType, fileId);
                if (!class_)
                    logError(format(getError(Error.xNotDecl),
                            getPrettyType(objectType)), getError(Error.unknownClass), "", -1);
                addInstruction(GrOpcode.new_, cast(uint) class_.index);

                bool[] initFields;
                uint[] lexPositions;
                initFields.length = class_.fields.length;
                lexPositions.length = class_.fields.length;

                checkAdvance();
                while (!isEnd()) {
                    if (get().type == GrLexeme.Type.rightCurlyBrace) {
                        checkAdvance();
                        break;
                    }
                    else if (get().type == GrLexeme.Type.identifier) {
                        const string fieldName = get().svalue;
                        checkAdvance();
                        bool hasField = false;

                        for (int i; i < class_.fields.length; ++i) {
                            if (class_.fields[i] == fieldName) {
                                hasField = true;

                                if (initFields[i])
                                    logError(format(getError(Error.fieldXInitMultipleTimes), fieldName),
                                        format(getError(Error.xAlreadyInit), fieldName), "", -1,
                                        getError(Error.prevInit), lexPositions[i] - 1);

                                initFields[i] = true;
                                lexPositions[i] = current;

                                GrVariable fieldLValue = new GrVariable;
                                fieldLValue.isInitialized = false;
                                fieldLValue.isField = true;
                                fieldLValue.type = class_.signature[i];
                                fieldLValue.isConst = class_.fieldConsts[i];
                                fieldLValue.register = i;
                                fieldLValue.fileId = get().fileId;
                                fieldLValue.lexPosition = current;
                                addInstruction(GrOpcode.fieldRefLoad2, fieldLValue.register);
                                parseAssignList([fieldLValue], true);
                                break;
                            }
                        }
                        if (!hasField)
                            logError(format(getError(Error.fieldXNotExist),
                                    fieldName), getError(Error.unknownField));
                    }
                    else {
                        logError(format(getError(Error.expectedFieldNameFoundX),
                                getPrettyLexemeType(get().type)), getError(Error.missingField));
                    }
                }

                for (int i; i < class_.fields.length; ++i) {
                    if (initFields[i])
                        continue;

                    GrVariable fieldLValue = new GrVariable;
                    fieldLValue.isInitialized = false;
                    fieldLValue.isField = true;
                    fieldLValue.type = class_.signature[i];
                    fieldLValue.isConst = class_.fieldConsts[i];
                    fieldLValue.register = i;
                    fieldLValue.fileId = get().fileId;
                    fieldLValue.lexPosition = current;
                    addInstruction(GrOpcode.fieldRefLoad2, fieldLValue.register);
                    addDefaultValue(fieldLValue.type, fileId);
                    addSetInstruction(fieldLValue, fileId, fieldLValue.type);
                }
                break;
            case native:
            default:
                logError(format(getError(Error.xNotClassType),
                        getPrettyType(objectType)), getError(Error.invalidType), "", -1);
                break;
            }
        }
        else {
            string name = "@static_" ~ grUnmangleComposite(objectType.mangledType).name;

            if (get().type == GrLexeme.Type.period) {
                checkAdvance();
                if (get().type != GrLexeme.Type.identifier)
                    logError(format(getError(Error.expectedIdentifierFoundX),
                            getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));

                name ~= "." ~ get().svalue;
                checkAdvance();
            }

            GrType[] signature;
            if (get().type == GrLexeme.Type.leftParenthesis) {
                advance();
                if (get().type == GrLexeme.Type.rightParenthesis) {
                    advance();
                }
                else {
                    for (;;) {
                        auto type = parseSubExpression(
                            GR_SUBEXPR_TERMINATE_COMMA | GR_SUBEXPR_TERMINATE_PARENTHESIS |
                                GR_SUBEXPR_EXPECTING_VALUE).type;
                        if (type.base == GrType.Base.internalTuple) {
                            auto types = grUnpackTuple(type);
                            if (types.length)
                                signature ~= types;
                            else
                                logError(getError(Error.exprYieldsNoVal),
                                    getError(Error.expectedValFoundNothing));
                        }
                        else
                            signature ~= type;

                        if (get().type == GrLexeme.Type.rightParenthesis) {
                            advance();
                            break;
                        }
                        advance();
                    }
                }
            }
            signature ~= objectType;

            // Appel de fonction
            auto matching = getFirstMatchingFuncOrPrim(name, signature, fileId);
            if (matching.prim) {
                addInstruction(GrOpcode.primitiveCall, matching.prim.index);
                outputs = matching.prim.outSignature;
            }
            else if (matching.func) {
                addFunctionCall(matching.func, fileId);
                outputs = matching.func.outSignature;
            }
            else {
                logError(format(getError(Error.xNotDecl), getPrettyFunctionCall(name,
                        signature)), getError(Error.unknownFunc), "", -1);
            }
        }

        return outputs;
    }

    /**
    Parse une création de liste
    Le type est optionnel si la liste n’est pas vide.
    S’il n’est pas spécifié, le sous-type de la liste
    sera assigné à celui du premier élément de la liste.
    ---
    list<int>[1, 2, 3]
    ["1", "2", "3"]
    list<string>[]
    ---
    */
    private GrType parseListBuilder() {
        GrType listType = GrType(GrType.Base.list);
        GrType subType = grVoid;
        const uint fileId = get().fileId;
        int listSize, defaultListSize;

        // Type explicite comme: list<int>[1, 2, 3] ou taille par défaut comme: list<int>(5, 0)
        if (get().type == GrLexeme.Type.listType) {
            checkAdvance();
            if (get().type != GrLexeme.Type.lesser)
                logError(format(getError(Error.missingXInListSignature), getPrettyLexemeType(GrLexeme.Type.lesser)),
                    format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.lesser), getPrettyLexemeType(get().type)));
            checkAdvance();
            subType = parseType();

            distinguishTemplateLexemes();
            GrLexeme lex = get();
            if (lex.type == GrLexeme.Type.comma) {
                checkAdvance();
                lex = get();
                if (lex.type != GrLexeme.Type.int_)
                    logError(getError(Error.listSizeMustBePositive),
                        format(getError(Error.expectedIntFoundX), getPrettyLexemeType(get().type)));
                defaultListSize = lex.ivalue > int.max ? 0 : cast(int) lex.ivalue;
                if (defaultListSize < 0)
                    logError(getError(Error.listSizeMustBeZeroOrHigher),
                        format(getError(Error.expectedAtLeastSizeOf1FoundX), defaultListSize));
                checkAdvance();
            }
            else if (lex.type != GrLexeme.Type.greater) {
                logError(getError(Error.missingCommaOrGreaterInsideListSignature),
                    format(getError(Error.expectedCommaOrGreaterFoundX),
                        getPrettyLexemeType(get().type)));
            }
            distinguishTemplateLexemes();
            lex = get();
            if (lex.type != GrLexeme.Type.greater)
                logError(format(getError(Error.missingXInListSignature), getPrettyLexemeType(GrLexeme.Type.greater)),
                    format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.greater), getPrettyLexemeType(get().type)));
            checkAdvance();
            listType.mangledType = grMangleSignature([subType]);
        }

        if (get().type == GrLexeme.Type.leftBracket) {
            advance();

            while (get().type != GrLexeme.Type.rightBracket) {
                if (subType.base == GrType.Base.void_) {
                    // Type implicite spécifié par le type du premier élément
                    subType = parseSubExpression(
                        GR_SUBEXPR_TERMINATE_BRACKET | GR_SUBEXPR_TERMINATE_COMMA |
                            GR_SUBEXPR_EXPECTING_VALUE).type;
                    listType.mangledType = grMangleSignature([subType]);
                    if (subType.base == GrType.Base.void_)
                        logError(format(getError(Error.listCantBeOfTypeX),
                                getPrettyType(listType)), getError(Error.invalidListType));
                }
                else {
                    convertType(parseSubExpression(
                            GR_SUBEXPR_TERMINATE_BRACKET | GR_SUBEXPR_TERMINATE_COMMA | GR_SUBEXPR_EXPECTING_VALUE)
                            .type, subType, fileId);
                }
                listSize++;

                if (get().type == GrLexeme.Type.rightBracket)
                    break;
                if (get().type != GrLexeme.Type.comma)
                    logError(getError(Error.indexesShouldBeSeparatedByComma), format(getError(Error.expectedXFoundY),
                            getPrettyLexemeType(GrLexeme.Type.comma),
                            getPrettyLexemeType(get().type)));
                checkAdvance();
            }
            checkAdvance();
        }

        for (; listSize < defaultListSize; ++listSize) {
            addDefaultValue(subType, fileId);
        }

        final switch (subType.base) with (GrType.Base) {
        case bool_:
        case int_:
        case func:
        case task:
        case event:
        case enum_:
        case float_:
        case string_:
        case optional:
        case list:
        case class_:
        case native:
        case channel:
        case reference:
            addInstruction(GrOpcode.list, listSize);
            break;
        case void_:
        case null_:
        case internalTuple:
            logError(format(getError(Error.listCantBeOfTypeX),
                    getPrettyType(grList(subType))), getError(Error.invalidListType));
            break;
        }
        return listType;
    }

    private GrType parseListIndex(GrType listType) {
        const uint fileId = get().fileId;
        advance();

        for (;;) {
            if (get().type == GrLexeme.Type.comma)
                logError(getError(Error.expectedIndexFoundComma), getError(Error.missingVal));

            auto index = parseSubExpression(
                GR_SUBEXPR_TERMINATE_BRACKET | GR_SUBEXPR_TERMINATE_COMMA |
                    GR_SUBEXPR_EXPECTING_VALUE).type;

            if (index.base == GrType.Base.void_)
                logError(getError(Error.expectedIntFoundNothing), getError(Error.missingVal));
            convertType(index, grInt, fileId);

            if (get().type == GrLexeme.Type.rightBracket) {
                switch (listType.base) with (GrType.Base) {
                case list:
                    const GrType subType = grUnmangle(listType.mangledType);
                    final switch (subType.base) with (GrType.Base) {
                    case bool_:
                    case int_:
                    case func:
                    case task:
                    case event:
                    case enum_:
                    case float_:
                    case string_:
                    case optional:
                    case list:
                    case class_:
                    case native:
                    case channel:
                    case reference:
                        addInstruction(GrOpcode.index_list);
                        break;
                    case void_:
                    case null_:
                    case internalTuple:
                        logError(format(getError(Error.listCantBeOfTypeX),
                                getPrettyType(grList(subType))), getError(Error.invalidListType));
                        break;
                    }
                    bool isPure = listType.isPure;
                    listType = subType;
                    listType.isPure = listType.isPure || isPure;
                    break;
                default:
                    logError(getError(Error.invalidListType), format(getError(Error.expectedXFoundY),
                            getPrettyLexemeType(GrLexeme.Type.listType), getPrettyType(listType)));
                }
                break;
            }
            if (get().type != GrLexeme.Type.comma)
                logError(getError(Error.indexesShouldBeSeparatedByComma), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.comma), getPrettyLexemeType(get().type)));
            checkAdvance();
            if (get().type == GrLexeme.Type.rightBracket)
                logError(getError(Error.indexesShouldBeSeparatedByComma), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.comma), getPrettyLexemeType(get().type)));

            switch (listType.base) with (GrType.Base) {
            case list:
                const GrType subType = grUnmangle(listType.mangledType);
                final switch (subType.base) with (GrType.Base) {
                case bool_:
                case int_:
                case func:
                case task:
                case event:
                case enum_:
                case float_:
                case string_:
                case optional:
                case list:
                case class_:
                case native:
                case channel:
                case reference:
                    addInstruction(GrOpcode.index_list);
                    break;
                case void_:
                case null_:
                case internalTuple:
                    logError(format(getError(Error.listCantBeOfTypeX),
                            getPrettyType(listType)), getError(Error.invalidListType));
                    break;
                }
                bool isPure = listType.isPure;
                listType = subType;
                listType.isPure = listType.isPure || isPure;
                break;
            default:
                logError(getError(Error.invalidListType), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.listType), getPrettyType(listType)));
            }
        }
        advance();
        return listType;
    }

    /**
    Analyse une opération de conversion.
    ---
    1 as<float>
    ---
    */
    private GrType parseConversionOperator(GrType[] typeStack) {
        if (!typeStack.length)
            logError(getError(Error.noValToConv), getError(Error.missingVal));
        checkAdvance();

        const uint fileId = get().fileId;
        if (get().type != GrLexeme.Type.lesser)
            logError(format(getError(Error.expectedXFoundY), getPrettyLexemeType(GrLexeme.Type.lesser),
                    getPrettyLexemeType(get().type)), format(getError(Error.missingX),
                    getPrettyLexemeType(GrLexeme.Type.lesser)));
        checkAdvance();

        GrType type = parseType();

        distinguishTemplateLexemes();
        if (get().type != GrLexeme.Type.greater)
            logError(format(getError(Error.expectedXFoundY), getPrettyLexemeType(GrLexeme.Type.greater),
                    getPrettyLexemeType(get().type)), format(getError(Error.missingX),
                    getPrettyLexemeType(GrLexeme.Type.greater)));
        checkAdvance();

        convertType(typeStack[$ - 1], type, fileId, false, true);
        typeStack[$ - 1] = type;
        return type;
    }

    /// Analyse un élément assignable nommé ou `lvalue`
    private GrVariable parseLValue() {
        const uint fileId = get().fileId;
        if (get().type != GrLexeme.Type.identifier)
            logError(format(getError(Error.expectedVarFoundX),
                    getPrettyLexemeType(get().type)), getError(Error.missingVar));

        const string identifierName = get().svalue;

        checkAdvance();

        GrVariable localLValue = currentFunction.getLocal(identifierName);
        if (localLValue !is null)
            return localLValue;

        GrVariable globalLValue = getGlobalVariable(identifierName, fileId);
        if (globalLValue !is null)
            return globalLValue;

        logError(format(getError(Error.expectedVarFoundX),
                getPrettyLexemeType(get().type)), getError(Error.missingVar));
        return null;
    }

    /// Analyse une simple expression
    private void parseExpression() {
        bool isAssignmentList;
        const auto tempPos = current;
        __skipLoop: while (!isEnd()) {
            switch (get().type) with (GrLexeme.Type) {
            case leftBracket:
                skipBrackets();
                break;
            case leftParenthesis:
                skipParenthesis();
                break;
            case leftCurlyBrace:
                skipBlock();
                break;
            case semicolon:
                isAssignmentList = false;
                break __skipLoop;
            case comma:
                isAssignmentList = true;
                break __skipLoop;
            default:
                checkAdvance();
                break;
            }
        }
        current = tempPos;

        if (isAssignmentList) {
            // Récupère la liste des `lvalues`
            GrVariable[] lvalues;
            do {
                if (lvalues.length)
                    checkAdvance();
                // Identificateur
                if (get().type != GrLexeme.Type.identifier)
                    logError(format(getError(Error.expectedIdentifierFoundX),
                            getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));
                lvalues ~= parseSubExpression(
                    GR_SUBEXPR_TERMINATE_COMMA | GR_SUBEXPR_TERMINATE_ASSIGN |
                        GR_SUBEXPR_EXPECTING_LVALUE).lvalue;
            }
            while (get().type == GrLexeme.Type.comma);

            parseAssignList(lvalues);
        }
        else {
            parseSubExpression(GR_SUBEXPR_TERMINATE_SEMICOLON | GR_SUBEXPR_MUST_CLEAN);
            checkAdvance();
        }
    }

    /// Analyse la partie droite d’une assignation multiple
    private GrType[] parseExpressionList() {
        GrType[] expressionTypes;
        for (;;) {
            GrType type = parseSubExpression(
                GR_SUBEXPR_TERMINATE_SEMICOLON | GR_SUBEXPR_TERMINATE_COMMA |
                    GR_SUBEXPR_EXPECTING_VALUE).type;
            if (type.base == GrType.Base.internalTuple) {
                auto types = grUnpackTuple(type);
                if (!types.length)
                    logError(getError(Error.exprYieldsNoVal),
                        getError(Error.expectedValFoundNothing));
                else {
                    foreach (subType; types)
                        expressionTypes ~= subType;
                }
            }
            else if (type.base != GrType.Base.void_)
                expressionTypes ~= type;
            if (get().type != GrLexeme.Type.comma)
                break;
            checkAdvance();
        }
        if (get().type != GrLexeme.Type.semicolon)
            logError(getError(Error.missingSemicolonAfterExprList), format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.semicolon), getPrettyLexemeType(get().type)));
        checkAdvance();
        return expressionTypes;
    }

    /// Analyse la partie droite d’une assignation multiple et les associe avec les `lvalues`
    private void parseAssignList(GrVariable[] lvalues, bool isInitialization = false) {
        const uint fileId = get().fileId;
        switch (get().type) with (GrLexeme.Type) {
        case assign:
            advance();
            GrType[] expressionTypes = parseExpressionList();

            if (expressionTypes.length > lvalues.length) {
                logError(format(getError(lvalues.length > 1 ? Error.tryingAssignXValsToYVars
                        : Error.tryingAssignXValsToYVar), expressionTypes.length, lvalues.length),
                    getError(Error.moreValThanVarToAssign), "", -1);
            }
            else if (!expressionTypes.length) {
                logError(getError(Error.assignationMissingVal),
                    getError(Error.expressionEmpty), "", -1);
            }

            int variableIndex = to!int(lvalues.length) - 1;
            int expressionIndex = to!int(expressionTypes.length) - 1;
            bool passThrough;
            GrVariable[] skippedLvalues;
            while (variableIndex > expressionIndex) {
                addSetInstruction(lvalues[variableIndex], fileId,
                    expressionTypes[expressionIndex], true, isInitialization);
                variableIndex--;
                passThrough = true;
            }
            if (passThrough) {
                if (expressionTypes[expressionIndex].base == GrType.Base.void_) {
                    skippedLvalues ~= lvalues[variableIndex];
                }
                else {
                    addSetInstruction(lvalues[variableIndex], fileId,
                        lvalues[variableIndex + 1].type, false, isInitialization);
                }
                variableIndex--;
                expressionIndex--;
            }
            while (variableIndex >= 0) {
                if (expressionTypes[expressionIndex].base == GrType.Base.void_) {
                    skippedLvalues ~= lvalues[variableIndex];
                }
                else {
                    while (skippedLvalues.length) {
                        addSetInstruction(skippedLvalues[$ - 1], fileId,
                            expressionTypes[expressionIndex], true, isInitialization);
                        skippedLvalues.length--;
                    }
                    addSetInstruction(lvalues[variableIndex], fileId,
                        expressionTypes[expressionIndex], false, isInitialization);
                }
                variableIndex--;
                expressionIndex--;
            }
            if (skippedLvalues.length)
                logError(getError(Error.firstValOfAssignmentListCantBeEmpty),
                    getError(Error.missingVal));
            break;
        case semicolon:
            if (isInitialization) {
                foreach (lvalue; lvalues) {
                    if (lvalue.isAuto)
                        logError(getError(Error.cantInferTypeWithoutAssignment),
                            getError(Error.missingTypeInfoOrInitVal), "", -1);
                    addDefaultValue(lvalue.type, fileId);
                    addSetInstruction(lvalue, fileId, lvalue.type, false, isInitialization);
                }
            }
            advance();
            break;
        default:
            logError(getError(Error.missingSemicolonAfterAssignmentList), format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.semicolon), getPrettyLexemeType(get().type)));
        }
    }

    private void addDefaultValue(GrType type, uint fileId) {
        final switch (type.base) with (GrType.Base) {
        case int_:
        case bool_:
        case enum_:
            addIntConstant(0);
            break;
        case float_:
            addFloatConstant(0f);
            break;
        case string_:
            addStringConstant("");
            break;
        case func:
            GrType[] inSignature = grUnmangleSignature(type.mangledType);
            GrType[] outSignature = grUnmangleSignature(type.mangledReturnType);
            string[] inputs;
            for (int i; i < inSignature.length; ++i) {
                inputs ~= to!string(i);
            }
            preBeginFunction("$anon", fileId, inSignature, inputs, false, outSignature, true);
            openDeferrableSection();
            foreach (outType; outSignature) {
                addDefaultValue(outType, fileId);
            }
            addReturn();
            closeDeferrableSection();
            registerDeferBlocks();
            endFunction();
            break;
        case task:
            GrType[] inSignature = grUnmangleSignature(type.mangledType);
            string[] inputs;
            for (int i; i < inSignature.length; ++i) {
                inputs ~= to!string(i);
            }
            preBeginFunction("$anon", fileId, inSignature, inputs, true, [], true);
            openDeferrableSection();
            addDie();
            closeDeferrableSection();
            registerDeferBlocks();
            endFunction();
            break;
        case event:
            GrType[] inSignature = grUnmangleSignature(type.mangledType);
            string[] inputs;
            for (int i; i < inSignature.length; ++i) {
                inputs ~= to!string(i);
            }
            preBeginFunction("$anon", fileId, inSignature, inputs, true, [], true, true);
            openDeferrableSection();
            addDie();
            closeDeferrableSection();
            registerDeferBlocks();
            endFunction();
            break;
        case list:
            GrType[] subTypes = grUnmangleSignature(type.mangledType);
            if (subTypes.length != 1)
                logError(getError(Error.listCanOnlyContainOneTypeOfVal), getError(Error.conflictingListSignature),
                    format(getError(Error.tryUsingXInstead), getPrettyType(grList(subTypes[0]))));
            final switch (subTypes[0].base) with (GrType.Base) {
            case bool_:
            case int_:
            case func:
            case task:
            case event:
            case enum_:
            case float_:
            case string_:
            case optional:
            case list:
            case class_:
            case native:
            case channel:
            case reference:
                addInstruction(GrOpcode.list, 0);
                break;
            case void_:
            case null_:
            case internalTuple:
                logError(format(getError(Error.listCantBeOfTypeX),
                        getPrettyType(grList(subTypes[0]))), getError(Error.invalidListType));
                break;
            }
            break;
        case optional:
            addInstruction(GrOpcode.const_null);
            break;
        case channel:
            GrType[] subTypes = grUnmangleSignature(type.mangledType);
            if (subTypes.length != 1)
                logError(getError(Error.channelCanOnlyContainOneTypeOfVal),
                    getError(Error.conflictingChannelSignature),
                    format(getError(Error.tryUsingXInstead), getPrettyType(grChannel(subTypes[0]))));
            final switch (subTypes[0].base) with (GrType.Base) {
            case int_:
            case bool_:
            case func:
            case task:
            case event:
            case enum_:
            case float_:
            case string_:
            case class_:
            case optional:
            case list:
            case native:
            case channel:
            case reference:
                addInstruction(GrOpcode.channel, 1);
                break;
            case void_:
            case null_:
            case internalTuple:
                logError(format(getError(Error.chanCantBeOfTypeX),
                        getPrettyType(grChannel(subTypes[0]))), getError(Error.invalidChanType));
            }
            break;
        case class_:
        case native:
            string name = "@static_" ~ grUnmangleComposite(type.mangledType).name;
            auto matching = getFirstMatchingFuncOrPrim(name, [type], get().fileId);

            if (matching.prim) {
                addInstruction(GrOpcode.primitiveCall, matching.prim.index);
                if (matching.prim.outSignature.length != 1 || matching.prim.outSignature[0] != type)
                    goto case void_;
            }
            else if (matching.func) {
                addFunctionCall(matching.func, fileId);
                if (matching.func.outSignature.length != 1 || matching.func.outSignature[0] != type)
                    goto case void_;
            }
            else {
                goto case void_;
            }
            break;
        case reference:
        case void_:
        case null_:
        case internalTuple:
            logError(format(getError(Error.typeXHasNoDefaultVal),
                    getPrettyType(type)), getError(Error.cantInitThisType));
        }
    }

    /// Compte le nombre de types utilisés
    private int countSubTypes(GrType type) {
        int counter;
        final switch (type.base) with (GrType.Base) {
        case int_:
        case bool_:
        case func:
        case task:
        case event:
        case enum_:
        case float_:
        case string_:
        case class_:
        case optional:
        case list:
        case native:
        case channel:
        case reference:
            counter++;
            break;
        case void_:
        case null_:
            throw new Exception("the type can't be counted as a subtype");
        case internalTuple:
            auto types = grUnpackTuple(type);
            if (!types.length)
                logError(getError(Error.exprYieldsNoVal), getError(Error.expectedValFoundNothing));
            else {
                foreach (subType; types)
                    counter += countSubTypes(subType);
            }
            break;
        }
        return counter;
    }

    /// Ajoute une instruction pour dépler des valeurs de la pile d’opérations
    private void shiftStackPosition(GrType type, short count) {
        const auto counter = countSubTypes(type);
        if (counter)
            addInstruction(GrOpcode.shiftStack, counter * count, true);
    }

    /// Est-ce que cette opération a besoin d’une `lvalue` ?
    private bool requireLValue(GrLexeme.Type operatorType) {
        switch (operatorType) with (GrLexeme.Type) {
        case increment:
        case decrement:
        case assign: .. case powerAssign:
            return true;
        default:
            return false;
        }
    }

    /**
    Analyse une référence de fonction globale. \
    Traite la fonction comme si elle était anonyme.
    ---
    var fonction = &<func(string)()> maFonction;
    fonction("Bonjour");
    ---
    */
    private GrType parseFunctionPointer() {
        const uint fileId = get().fileId;
        if (get().type != GrLexeme.Type.lesser)
            logError(format(getError(Error.expectedXFoundY), getPrettyLexemeType(GrLexeme.Type.lesser),
                    getPrettyLexemeType(get().type)), format(getError(Error.missingX),
                    getPrettyLexemeType(GrLexeme.Type.lesser)));
        checkAdvance();

        GrType type = parseType();
        distinguishTemplateLexemes();
        if (get().type != GrLexeme.Type.greater)
            logError(format(getError(Error.expectedXFoundY), getPrettyLexemeType(GrLexeme.Type.greater),
                    getPrettyLexemeType(get().type)), format(getError(Error.missingX),
                    getPrettyLexemeType(GrLexeme.Type.greater)));
        checkAdvance();

        if (get().type != GrLexeme.Type.identifier)
            logError(format(getError(Error.expectedFuncNameFoundX),
                    getPrettyLexemeType(get().type)), getError(Error.missingFuncName));

        if (type.base != GrType.Base.func && type.base != GrType.Base.task &&
            type.base != GrType.Base.event)
            logError(format(getError(Error.cantInferTypeOfX), get().svalue),
                getError(Error.funcTypeCantBeInferred));

        GrType funcType = addFunctionAddress(get().svalue,
            grUnmangleSignature(type.mangledType), get().fileId);
        type = convertType(funcType, type, fileId);
        checkAdvance();
        return type;
    }

    private enum {
        GR_SUBEXPR_TERMINATE_SEMICOLON = 0x1,
        GR_SUBEXPR_TERMINATE_BRACKET = 0x2,
        GR_SUBEXPR_TERMINATE_COMMA = 0x4,
        GR_SUBEXPR_TERMINATE_PARENTHESIS = 0x8,
        GR_SUBEXPR_TERMINATE_ASSIGN = 0x10,
        GR_SUBEXPR_MUST_CLEAN = 0x20,
        GR_SUBEXPR_EXPECTING_VALUE = 0x40,
        GR_SUBEXPR_EXPECTING_LVALUE = 0x80,
    }

    private struct GrSubExprResult {
        GrType type;
        GrVariable lvalue;
    }

    /// Évalue une sous-expression
    private GrSubExprResult parseSubExpression(
        int flags = GR_SUBEXPR_TERMINATE_PARENTHESIS | GR_SUBEXPR_EXPECTING_VALUE) {
        const bool useSemicolon = (flags & GR_SUBEXPR_TERMINATE_SEMICOLON) > 0;
        const bool useBracket = (flags & GR_SUBEXPR_TERMINATE_BRACKET) > 0;
        const bool useComma = (flags & GR_SUBEXPR_TERMINATE_COMMA) > 0;
        const bool useParenthesis = (flags & GR_SUBEXPR_TERMINATE_PARENTHESIS) > 0;
        const bool useAssign = (flags & GR_SUBEXPR_TERMINATE_ASSIGN) > 0;
        const bool mustCleanValue = (flags & GR_SUBEXPR_MUST_CLEAN) > 0;
        const bool isExpectingValue = (flags & GR_SUBEXPR_EXPECTING_VALUE) > 0;
        const bool isExpectingLValue = (flags & GR_SUBEXPR_EXPECTING_LVALUE) > 0;

        GrVariable[] lvalues;
        GrLexeme.Type[] operatorsStack;
        GrType[] typeStack;
        GrType currentType = grVoid, lastType = grVoid;
        bool hasValue = false, hadValue = false, hasLValue = false, hadLValue = false, hasReference = false,
            hadReference = false, isRightUnaryOperator = true, isEndOfExpression = false;

        GrSubExprResult result;
        uint fileId;

        do {
            if (hasValue && currentType != lastType && lastType != grVoid) {
                lastType = currentType;
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

            GrLexeme lex = get();
            fileId = lex.fileId;
            switch (lex.type) with (GrLexeme.Type) {
            case semicolon:
                if (useSemicolon)
                    isEndOfExpression = true;
                else
                    logError(format(getError(Error.unexpectedXFoundInExpr), getPrettyLexemeType(lex.type)),
                        format(getError(Error.xCantExistInsideThisExpr),
                            getPrettyLexemeType(lex.type)));
                break;
            case comma:
                if (useComma)
                    isEndOfExpression = true;
                else
                    logError(format(getError(Error.unexpectedXFoundInExpr), getPrettyLexemeType(lex.type)),
                        format(getError(Error.xCantExistInsideThisExpr),
                            getPrettyLexemeType(lex.type)));
                break;
            case rightParenthesis:
                if (useParenthesis)
                    isEndOfExpression = true;
                else
                    logError(format(getError(Error.unexpectedXFoundInExpr), getPrettyLexemeType(lex.type)),
                        format(getError(Error.xCantExistInsideThisExpr),
                            getPrettyLexemeType(lex.type)));
                break;
            case rightBracket:
                if (useBracket)
                    isEndOfExpression = true;
                else
                    logError(format(getError(Error.unexpectedXFoundInExpr), getPrettyLexemeType(lex.type)),
                        format(getError(Error.xCantExistInsideThisExpr),
                            getPrettyLexemeType(lex.type)));
                break;
            case leftParenthesis:
                if (hadValue) {
                    currentType = parseAnonymousCall(typeStack[$ - 1]);
                    // Débale la valeur pour 1 ou moins de types de retour.
                    // S’il y a plus d’une valeur, on laisse comme tel pour `parseExpressionList()`.
                    if (currentType.base == GrType.Base.internalTuple) {
                        auto types = grUnpackTuple(currentType);
                        if (!types.length)
                            currentType = grVoid;
                        else if (types.length == 1uL)
                            currentType = types[0];
                    }
                    if (currentType.base == GrType.Base.void_) {
                        typeStack.length--;
                    }
                    else {
                        hadValue = false;
                        hasValue = true;
                        typeStack[$ - 1] = currentType;
                    }
                }
                else {
                    advance();
                    currentType = parseSubExpression().type;
                    advance();
                    hasValue = true;
                    typeStack ~= currentType;
                }
                break;
            case colon:
                advance();
                if (!hadValue)
                    logError(getError(Error.methodCallMustBePlacedAfterVal),
                        getError(Error.missingVal));
                bool isOptionalCall;
                uint optionalCallPosition, nbReturnValues;
                if (get().type == GrLexeme.Type.optional) {
                    checkAdvance();
                    if (typeStack[$ - 1].base == GrType.Base.optional) {
                        typeStack[$ - 1] = grUnmangle(typeStack[$ - 1].mangledType);
                        currentType = typeStack[$ - 1];
                        isOptionalCall = true;
                        optionalCallPosition = cast(uint) currentFunction.instructions.length;
                        addInstruction(GrOpcode.optionalCall);
                    }
                }
                if (get().type != GrLexeme.Type.identifier)
                    logError(format(getError(Error.expectedFuncNameFoundX),
                            getPrettyLexemeType(get().type)), getError(Error.missingFuncName));

                GrType selfType = grVoid;
                selfType = typeStack[$ - 1];
                typeStack.length--;
                hadValue = false;

                GrVariable lvalue;
                currentType = parseIdentifier(lvalue, lastType, selfType, isExpectingLValue);
                // Débale la valeur pour 1 ou moins de types de retour.
                // S’il y a plus d’une valeur, on laisse comme tel pour `parseExpressionList()`.
                if (currentType.base == GrType.Base.internalTuple) {
                    auto types = grUnpackTuple(currentType);
                    nbReturnValues = cast(uint) types.length;
                    if (!types.length)
                        currentType = grVoid;
                    else if (types.length == 1uL)
                        currentType = isOptionalCall ? grOptional(types[0]) : types[0];
                    else if (isOptionalCall) {
                        for (size_t i; i < types.length; ++i) {
                            if (types[i].base != GrType.Base.optional)
                                types[i] = grOptional(types[i]);
                        }
                        currentType = grPackTuple(types);
                    }
                }
                else if (isOptionalCall) {
                    currentType = grOptional(currentType);
                    nbReturnValues = 1;
                }

                if (isOptionalCall) {
                    const uint jumpPosition = cast(uint) currentFunction.instructions.length;
                    addInstruction(GrOpcode.jump);

                    setInstruction(GrOpcode.optionalCall, optionalCallPosition,
                        cast(int)(currentFunction.instructions.length - optionalCallPosition), true);

                    for (uint i; i < nbReturnValues; ++i)
                        addInstruction(GrOpcode.const_null);

                    setInstruction(GrOpcode.jump, jumpPosition,
                        cast(int)(currentFunction.instructions.length - jumpPosition), true);
                }

                const auto nextLexeme = get();
                if (nextLexeme.type == GrLexeme.Type.leftBracket)
                    hasReference = true;
                if (currentType != GrType(GrType.Base.void_)) {
                    hasValue = true;
                    typeStack ~= currentType;
                }
                break;
            case listType:
                currentType = parseListBuilder();
                typeStack ~= currentType;
                hasValue = true;
                break;
            case leftBracket:
                // Index
                if (hadValue) {
                    hadValue = false;
                    currentType = parseListIndex(lastType);
                    hasReference = true;
                    // Vérifie si c’est une assignation ou non, on ignore si c’est une `rvalue`
                    const auto nextLexeme = get();
                    if (requireLValue(nextLexeme.type) || (isExpectingLValue &&
                            nextLexeme.type == GrLexeme.Type.comma)) {
                        if ((nextLexeme.type > GrLexeme.Type.assign && nextLexeme.type <= GrLexeme.Type.powerAssign) ||
                            nextLexeme.type == GrLexeme.Type.increment ||
                            nextLexeme.type == GrLexeme.Type.decrement) {
                            final switch (currentType.base) with (GrType.Base) {
                            case bool_:
                            case int_:
                            case func:
                            case task:
                            case event:
                            case enum_:
                            case float_:
                            case string_:
                            case optional:
                            case list:
                            case class_:
                            case native:
                            case channel:
                            case reference:
                                setInstruction(GrOpcode.index3_list,
                                    cast(int) currentFunction.instructions.length - 1);
                                break;
                            case void_:
                            case null_:
                            case internalTuple:
                                logError(format(getError(Error.listCantBeIndexedByX),
                                        getPrettyType(currentType)),
                                    getError(Error.invalidListIndexType));
                                break;
                            }
                        }
                        hasLValue = true;
                        GrVariable refVar = new GrVariable;
                        refVar.isConst = currentType.isPure;
                        refVar.type.base = GrType.Base.reference;
                        refVar.type.mangledType = grMangleSignature([
                            currentType
                        ]);
                        lvalues ~= refVar;
                    }
                    else {
                        final switch (currentType.base) with (GrType.Base) {
                        case bool_:
                        case int_:
                        case func:
                        case task:
                        case event:
                        case enum_:
                        case float_:
                        case string_:
                        case optional:
                        case list:
                        case class_:
                        case native:
                        case channel:
                        case reference:
                            setInstruction(GrOpcode.index2_list,
                                cast(int) currentFunction.instructions.length - 1);
                            break;
                        case void_:
                        case null_:
                        case internalTuple:
                            logError(format(getError(Error.listCantBeIndexedByX),
                                    getPrettyType(currentType)),
                                getError(Error.invalidListIndexType));
                            break;
                        }
                    }
                    lastType = currentType;
                    typeStack[$ - 1] = currentType;
                    hasValue = true;
                }
                else {
                    currentType = parseListBuilder();
                    typeStack ~= currentType;
                    hasValue = true;
                }
                break;
            case int_:
                currentType = GrType(GrType.Base.int_);
                addIntConstant(lex.ivalue);
                hasValue = true;
                typeStack ~= currentType;
                checkAdvance();
                break;
            case float_:
                currentType = GrType(GrType.Base.float_);
                addFloatConstant(lex.rvalue);
                hasValue = true;
                typeStack ~= currentType;
                checkAdvance();
                break;
            case bool_:
                currentType = GrType(GrType.Base.bool_);
                addBoolConstant(lex.bvalue);
                hasValue = true;
                typeStack ~= currentType;
                checkAdvance();
                break;
            case string_:
                currentType = GrType(GrType.Base.string_);
                addStringConstant(lex.svalue);
                hasValue = true;
                typeStack ~= currentType;
                checkAdvance();
                break;
            case null_:
                currentType = GrType(GrType.Base.null_);
                hasValue = true;
                addInstruction(GrOpcode.const_null);
                checkAdvance();
                if (get().type == GrLexeme.Type.lesser) {
                    checkAdvance();
                    GrType subType = parseType();
                    if (subType.base != GrType.Base.void_)
                        currentType = grOptional(subType);

                    distinguishTemplateLexemes();
                    if (get().type != GrLexeme.Type.greater)
                        logError(format(getError(Error.missingXInNullSignature),
                                getPrettyLexemeType(GrLexeme.Type.greater)),
                            format(getError(Error.expectedXFoundY),
                                getPrettyLexemeType(GrLexeme.Type.greater),
                                getPrettyLexemeType(get().type)));
                    checkAdvance();
                }
                typeStack ~= currentType;
                break;
            case at:
                GrType[] types = parseStaticCall();

                if (!types.length)
                    currentType = grVoid;
                else if (types.length == 1uL)
                    currentType = types[0];
                else
                    currentType = grPackTuple(types);

                hadValue = false;
                if (currentType.base == GrType.Base.void_) {
                    hasValue = false;
                }
                else {
                    hasValue = true;
                }

                typeStack ~= currentType;
                break;
            case channelType:
                currentType = parseChannelBuilder();
                hasValue = true;
                typeStack ~= currentType;
                break;
            case period:
                checkAdvance();
                bool isOptionalCall;
                bool hasField;
                uint optionalCallPosition;
                if (get().type == GrLexeme.Type.optional) {
                    checkAdvance();
                    if (currentType.base == GrType.Base.optional) {
                        currentType = grUnmangle(typeStack[$ - 1].mangledType);
                        isOptionalCall = true;
                        optionalCallPosition = cast(uint) currentFunction.instructions.length;
                        addInstruction(GrOpcode.optionalCall);
                    }
                }
                if (get().type != GrLexeme.Type.identifier)
                    logError(format(getError(Error.expectedFieldNameFoundX),
                            getPrettyLexemeType(get().type)), getError(Error.missingField));
                const string identifier = get().svalue;

                if (currentType.base == GrType.Base.native) {
                    GrNativeDefinition native = _data.getNative(currentType.mangledType);
                    if (!native)
                        logError(format(getError(Error.xNotDecl),
                                getPrettyType(currentType)), getError(Error.unknownType));

                    const string propertyName = "@property_" ~ identifier;
                    GrType[] signature = [currentType];

                    GrLexeme.Type operatorType = get(1).type;

                    auto getFunc = getFirstMatchingFuncOrPrim(propertyName, signature, fileId);
                    if (getFunc.prim) {
                        checkAdvance();

                        if (operatorType != GrLexeme.Type.assign) {
                            if (requireLValue(operatorType)) {
                                addInstruction(GrOpcode.copy);
                            }

                            addInstruction(GrOpcode.primitiveCall, getFunc.prim.index);
                            currentType = getFunc.prim.outSignature[0];
                        }

                        bool isSet;
                        if (operatorType >= GrLexeme.Type.assign &&
                            operatorType <= GrLexeme.Type.powerAssign) {
                            isSet = true;
                            checkAdvance();
                            GrType subType = parseSubExpression(
                                GR_SUBEXPR_TERMINATE_COMMA | GR_SUBEXPR_TERMINATE_PARENTHESIS |
                                    GR_SUBEXPR_EXPECTING_VALUE | GR_SUBEXPR_TERMINATE_SEMICOLON)
                                .type;
                            if (subType.base == GrType.Base.internalTuple) {
                                auto types = grUnpackTuple(subType);
                                if (types.length)
                                    signature ~= types;
                                else
                                    logError(getError(Error.exprYieldsNoVal),
                                        getError(Error.expectedValFoundNothing));
                            }
                            else
                                signature ~= subType;

                            if (operatorType != GrLexeme.Type.assign) {
                                currentType = addBinaryOperator(operatorType - (
                                        GrLexeme.Type.bitwiseAndAssign - GrLexeme.Type.bitwiseAnd),
                                    currentType, subType, fileId);
                            }
                        }
                        else if (operatorType == GrLexeme.Type.increment ||
                            operatorType == GrLexeme.Type.decrement) {
                            isSet = true;
                            checkAdvance();
                            currentType = addUnaryOperator(operatorType, currentType, fileId);
                            signature ~= currentType;
                        }

                        if (isSet) {
                            auto setFunc = getFirstMatchingFuncOrPrim(propertyName,
                                signature, fileId);
                            if (setFunc.prim) {
                                addInstruction(GrOpcode.primitiveCall, setFunc.prim.index);
                                currentType = grPackTuple(setFunc.prim.outSignature);
                                if (currentType.base == GrType.Base.internalTuple) {
                                    GrType[] types = grUnpackTuple(currentType);
                                    if (types.length)
                                        currentType = types[0];
                                    else
                                        logError(getError(Error.exprYieldsNoVal),
                                            getError(Error.expectedValFoundNothing));
                                }
                            }
                            else {
                                logError(format(getError(Error.xNotDecl), getPrettyFunctionCall(propertyName,
                                        signature)), getError(Error.unknownFunc), "", -1);
                            }
                        }

                        if (isOptionalCall) {
                            if (currentType.base != GrType.Base.optional)
                                currentType = grOptional(currentType);

                            setInstruction(GrOpcode.optionalCall, optionalCallPosition,
                                cast(int)(currentFunction.instructions.length - optionalCallPosition),
                                true);
                        }

                        if (hadValue)
                            typeStack[$ - 1] = currentType;
                        else
                            typeStack ~= currentType;

                        hasValue = true;
                        hadValue = false;
                        hasLValue = false;
                        hadLValue = false;
                        break;
                    }
                }
                else if (currentType.base == GrType.Base.class_) {
                    GrClassDefinition class_ = getClass(currentType.mangledType, get().fileId);
                    if (!class_)
                        logError(format(getError(Error.xNotDecl),
                                getPrettyType(currentType)), getError(Error.unknownType));
                    const auto nbFields = class_.signature.length;
                    for (int i; i < nbFields; i++) {
                        if (identifier == class_.fields[i]) {
                            if ((class_.fieldsInfo[i].fileId != fileId) &&
                                !class_.fieldsInfo[i].isPublic)
                                logError(format(getError(Error.xOnTypeYIsPrivate), identifier,
                                        getPrettyType(currentType)),
                                    getError(Error.privateField), "");
                            checkAdvance();
                            hasField = true;

                            GrType selfType = currentType;

                            bool isPure = currentType.isPure;
                            currentType = class_.signature[i];
                            currentType.isField = true;
                            GrVariable fieldLValue = new GrVariable;
                            fieldLValue.name = identifier;
                            fieldLValue.isInitialized = true;
                            fieldLValue.isField = true;
                            currentType.isPure = currentType.isPure || isPure;
                            fieldLValue.isConst = class_.fieldConsts[i] || isPure;
                            fieldLValue.type = currentType;
                            fieldLValue.register = i;
                            fieldLValue.fileId = get().fileId;
                            fieldLValue.lexPosition = current;
                            fieldLValue.isOptional = isOptionalCall;
                            fieldLValue.optionalPosition = optionalCallPosition;

                            if (requireLValue(get().type)) {
                                if (hadLValue)
                                    lvalues[$ - 1] = fieldLValue;
                                else
                                    lvalues ~= fieldLValue;
                                hasLValue = true;
                            }

                            if (hadValue)
                                typeStack[$ - 1] = currentType;
                            else
                                typeStack ~= currentType;

                            hasValue = true;
                            hadValue = false;
                            hadLValue = false;

                            switch (get().type) with (GrLexeme.Type) {
                            case period:
                                if (currentType.base == GrType.Base.func ||
                                    currentType.base == GrType.Base.task)
                                    goto case leftParenthesis;
                                addInstruction(GrOpcode.fieldLoad, fieldLValue.register);
                                break;
                            case assign:
                                addInstruction(GrOpcode.fieldRefLoad, fieldLValue.register);
                                break;
                            case increment:
                            case decrement:
                            case bitwiseAndAssign: .. case powerAssign:
                                addLoadFieldInstruction(currentType, fieldLValue.register, true);
                                break;
                            case leftParenthesis:
                                addInstruction(GrOpcode.copy);
                                addLoadFieldInstruction(currentType, fieldLValue.register, false);
                                currentType = parseAnonymousCall(typeStack[$ - 1], selfType);
                                // Débale la valeur pour 1 ou moins de types de retour.
                                // S’il y a plus d’une valeur, on laisse comme tel pour `parseExpressionList()`.
                                if (currentType.base == GrType.Base.internalTuple) {
                                    auto types = grUnpackTuple(currentType);
                                    if (!types.length)
                                        currentType = grVoid;
                                    else if (types.length == 1uL)
                                        currentType = types[0];
                                }
                                if (currentType.base == GrType.Base.void_) {
                                    typeStack.length--;
                                    hadValue = false;
                                    hasValue = false;
                                }
                                else {
                                    hadValue = false;
                                    hasValue = true;
                                    typeStack[$ - 1] = currentType;
                                }
                                break;
                            case comma:
                                if (isExpectingLValue)
                                    goto case assign;
                                goto default;
                            default:
                                addLoadFieldInstruction(currentType, fieldLValue.register, false);
                                break;
                            }

                            if (isOptionalCall) {
                                setInstruction(GrOpcode.optionalCall, optionalCallPosition,
                                    cast(int)(
                                        currentFunction.instructions.length - optionalCallPosition),
                                    true);
                            }
                            break;
                        }
                    }
                    if (hasField)
                        break;
                    /*if (!hasField) {
                        const string[] nearestValues = findNearestStrings(identifier, class_.fields);
                        string errorNote;
                        if (nearestValues.length) {
                            foreach (size_t i, const string value; nearestValues) {
                                errorNote ~= "`" ~ value ~ "`";
                                if ((i + 1) < nearestValues.length)
                                    errorNote ~= ", ";
                            }
                            errorNote ~= ".";
                        }
                        logError(format(getError(Error.noFieldXOnTypeY), identifier, getPrettyType(currentType)),
                            getError(Error.unknownField),
                            format(getError(Error.availableFieldsAreX), errorNote), -1);
                    }*/
                }

                GrType[] signature = [currentType];

                GrLexeme.Type operatorType = get(1).type;

                if (operatorType == GrLexeme.Type.leftParenthesis) {
                    uint nbReturnValues;

                    GrType selfType = grVoid;
                    selfType = typeStack[$ - 1];
                    typeStack.length--;
                    hadValue = false;

                    GrVariable lvalue;
                    currentType = parseIdentifier(lvalue, lastType, selfType, isExpectingLValue);
                    // Débale la valeur pour 1 ou moins de types de retour.
                    // S’il y a plus d’une valeur, on laisse comme tel pour `parseExpressionList()`.
                    if (currentType.base == GrType.Base.internalTuple) {
                        auto types = grUnpackTuple(currentType);
                        nbReturnValues = cast(uint) types.length;
                        if (!types.length)
                            currentType = grVoid;
                        else if (types.length == 1uL)
                            currentType = isOptionalCall ? grOptional(types[0]) : types[0];
                        else if (isOptionalCall) {
                            for (size_t i; i < types.length; ++i) {
                                if (types[i].base != GrType.Base.optional)
                                    types[i] = grOptional(types[i]);
                            }
                            currentType = grPackTuple(types);
                        }
                    }
                    else if (isOptionalCall) {
                        currentType = grOptional(currentType);
                        nbReturnValues = 1;
                    }

                    if (isOptionalCall) {
                        const uint jumpPosition = cast(uint) currentFunction.instructions.length;
                        addInstruction(GrOpcode.jump);

                        setInstruction(GrOpcode.optionalCall, optionalCallPosition,
                            cast(int)(currentFunction.instructions.length - optionalCallPosition),
                            true);

                        for (uint i; i < nbReturnValues; ++i)
                            addInstruction(GrOpcode.const_null);

                        setInstruction(GrOpcode.jump, jumpPosition,
                            cast(int)(currentFunction.instructions.length - jumpPosition), true);
                    }

                    const auto nextLexeme = get();
                    if (nextLexeme.type == GrLexeme.Type.leftBracket)
                        hasReference = true;
                    if (currentType != GrType(GrType.Base.void_)) {
                        hasValue = true;
                        typeStack ~= currentType;
                    }
                    break;
                }

                checkAdvance();
                GrType[] outputs;
                if (operatorType != GrLexeme.Type.assign) {
                    if (requireLValue(operatorType)) {
                        addInstruction(GrOpcode.copy);
                    }

                    auto matching = getFirstMatchingFuncOrPrim(identifier, signature, fileId);
                    if (matching.prim) {
                        addInstruction(GrOpcode.primitiveCall, matching.prim.index);
                        outputs = matching.prim.outSignature;
                    }
                    else if (matching.func) {
                        outputs = addFunctionCall(matching.func, fileId);
                    }
                    else {
                        logError(format(getError(Error.xNotDecl), getPrettyFunctionCall(identifier,
                                signature)), getError(Error.unknownFunc), "", -1);
                    }
                }

                bool isSet;
                if (operatorType >= GrLexeme.Type.assign && operatorType <= GrLexeme
                    .Type.powerAssign) {
                    if (operatorType != GrLexeme.Type.assign && outputs.length != 1)
                        logError(getError(Error.binOpMustHave2Operands), format(getError((outputs.length + 1) > 1 ?
                                Error.expectedXRetValsFoundY : Error.expectedXRetValFoundY),
                                2, outputs.length));

                    isSet = true;
                    checkAdvance();
                    GrType subType = parseSubExpression(GR_SUBEXPR_TERMINATE_COMMA | GR_SUBEXPR_TERMINATE_PARENTHESIS |
                            GR_SUBEXPR_EXPECTING_VALUE | GR_SUBEXPR_TERMINATE_SEMICOLON).type;
                    if (subType.base == GrType.Base.internalTuple) {
                        auto types = grUnpackTuple(subType);
                        if (types.length)
                            signature ~= types;
                        else
                            logError(getError(Error.exprYieldsNoVal),
                                getError(Error.expectedValFoundNothing));
                    }
                    else
                        signature ~= subType;

                    if (operatorType != GrLexeme.Type.assign && signature.length != 1)
                        logError(getError(Error.binOpMustHave2Operands), format(getError((signature.length + 1) > 1 ?
                                Error.expectedXRetValsFoundY : Error.expectedXRetValFoundY),
                                2, signature.length));

                    if (operatorType != GrLexeme.Type.assign) {
                        currentType = addBinaryOperator(operatorType - (
                                GrLexeme.Type.bitwiseAndAssign - GrLexeme.Type.bitwiseAnd),
                            currentType, subType, fileId);
                    }
                }
                else if (operatorType == GrLexeme.Type.increment ||
                    operatorType == GrLexeme.Type.decrement) {
                    if (outputs.length != 1)
                        logError(getError(Error.unOpMustHave1Operand),
                            format(getError(Error.expectedXRetValFoundY), 1, outputs.length));

                    isSet = true;
                    checkAdvance();
                    currentType = addUnaryOperator(operatorType, currentType, fileId);
                    signature ~= currentType;
                }

                if (isSet) {
                    outputs.length = 0;

                    auto matching = getFirstMatchingFuncOrPrim(identifier, signature, fileId);
                    if (matching.prim) {
                        addInstruction(GrOpcode.primitiveCall, matching.prim.index);
                        currentType = grPackTuple(matching.prim.outSignature);
                        if (currentType.base == GrType.Base.internalTuple) {
                            outputs = grUnpackTuple(currentType);
                        }
                        else if (currentType != grVoid)
                            outputs = [currentType];
                    }
                    else {
                        logError(format(getError(Error.xNotDecl), getPrettyFunctionCall(identifier,
                                signature)), getError(Error.unknownFunc), "", -1);
                    }
                }

                if (outputs.length == 1uL)
                    currentType = outputs[0];
                else if (outputs.length)
                    currentType = grPackTuple(outputs);
                else
                    currentType = grVoid;

                if (isOptionalCall) {
                    if (currentType.base != GrType.Base.optional && currentType != grVoid)
                        currentType = grOptional(currentType);

                    setInstruction(GrOpcode.optionalCall, optionalCallPosition,
                        cast(int)(currentFunction.instructions.length - optionalCallPosition), true);
                }

                if (currentType != grVoid) {
                    if (hadValue)
                        typeStack[$ - 1] = currentType;
                    else
                        typeStack ~= currentType;

                    hasValue = true;
                    hadValue = false;
                    hasLValue = false;
                    hadLValue = false;
                }
                else {
                    hasValue = false;
                    hadValue = false;
                    hasLValue = false;
                    hadLValue = false;
                }

                /*else {
                    logError(format(getError(Error.cantAccessFieldOnTypeX), getPrettyType(currentType)),
                        format(getError(Error.expectedClassFoundX), getPrettyType(currentType)));
                }*/
                break;
            case bitwiseAnd:
                if (get(1).type != GrLexeme.Type.lesser)
                    goto case bitwiseOr;
                checkAdvance();
                currentType = parseFunctionPointer();
                typeStack ~= currentType;
                hasValue = true;
                break;
            case as:
                if (!hadValue)
                    logError(format(getError(Error.xMustBePlacedAfterVal),
                            getPrettyLexemeType(GrLexeme.Type.as)), getError(Error.missingVal));
                currentType = parseConversionOperator(typeStack);
                hasValue = true;
                hadValue = false;
                break;
            case self:
                // Se réfère à la fonction actuelle
                checkAdvance();
                currentType = addFunctionAddress(currentFunction, get().fileId);
                if (currentType.base == GrType.Base.void_)
                    logError(format(getError(Error.xMustBeInsideFuncOrTask), getPrettyLexemeType(GrLexeme.Type.self)),
                        format(getError(Error.xRefNoFuncNorTask),
                            getPrettyLexemeType(GrLexeme.Type.self)), "", -1);
                typeStack ~= currentType;
                hasValue = true;
                break;
            case func:
                currentType = parseAnonymousFunction(false, false);
                typeStack ~= currentType;
                hasValue = true;
                break;
            case task:
                currentType = parseAnonymousFunction(true, false);
                typeStack ~= currentType;
                hasValue = true;
                break;
            case event:
                currentType = parseAnonymousFunction(false, true);
                typeStack ~= currentType;
                hasValue = true;
                break;
            case assign:
                if (useAssign) {
                    isEndOfExpression = true;
                    break;
                }
                goto case bitwiseAndAssign;
            case bitwiseAndAssign: .. case powerAssign:
                if (!hadLValue)
                    logError(getError(Error.valBeforeAssignationNotReferenceable),
                        getError(Error.missingRefBeforeAssignation));
                hadLValue = false;
                goto case multiply;
            case add:
                if (!hadValue)
                    lex.type = GrLexeme.Type.plus;
                goto case multiply;
            case concatenate:
                if (!hadValue)
                    lex.type = GrLexeme.Type.bitwiseNot;
                goto case multiply;
            case substract:
                if (!hadValue)
                    lex.type = GrLexeme.Type.minus;
                goto case multiply;
            case send:
                if (!hadValue)
                    lex.type = GrLexeme.Type.receive;
                goto case multiply;
            case increment: .. case decrement:
                isRightUnaryOperator = true;
                goto case multiply;
            case optional:
                if (!hadValue)
                    logError(format(getError(Error.xMustBePlacedAfterVal),
                            getPrettyLexemeType(GrLexeme.Type.optional)),
                        getError(Error.missingVal));

                if (currentType.base != GrType.Base.optional)
                    logError(getError(Error.expectedOptionalType),
                        getError(Error.opMustFollowAnOptionalType));

                checkAdvance();
                currentType = grUnmangle(currentType.mangledType);
                addInstruction(GrOpcode.optionalTry);

                typeStack[$ - 1] = currentType;
                hasValue = true;
                hadValue = false;
                break;
            case and:
            case or:
            case bitwiseOr:
            case bitwiseXor:
            case optionalOr:
            case multiply:
            case divide:
            case remainder: .. case not:
                if (isExpectingLValue)
                    logError(getError(
                            Error.cantDoThisKindOfOpOnLeftSideOfAssignement),
                        getError(Error.unexpectedOp));
                if (!hadValue && !isUnaryOperator(lex.type))
                    logError(getError(Error.binOpMustHave2Operands), getError(Error.missingVal));

                while (operatorsStack.length &&
                    getLeftOperatorPriority(operatorsStack[$ - 1]) > getRightOperatorPriority(
                        lex.type)) {
                    GrLexeme.Type operator = operatorsStack[$ - 1];

                    switch (operator) with (GrLexeme.Type) {
                    case assign:
                        addSetInstruction(lvalues[$ - 1], fileId, currentType, true);
                        currentType = lvalues[$ - 1].type;
                        lvalues.length--;
                        break;
                    case bitwiseAndAssign: .. case powerAssign:
                        currentType = addOperator(operator - (GrLexeme.Type.bitwiseAndAssign - GrLexeme.Type.bitwiseAnd),
                            typeStack, fileId);
                        addSetInstruction(lvalues[$ - 1], fileId, currentType, true);
                        lvalues.length--;
                        break;
                    case increment: .. case decrement:
                        currentType = addOperator(operator, typeStack, fileId);
                        addSetInstruction(lvalues[$ - 1], fileId, currentType, true);
                        lvalues.length--;
                        break;
                    default:
                        currentType = addOperator(operator, typeStack, fileId);
                        break;
                    }

                    operatorsStack.length--;
                }

                operatorsStack ~= lex.type;
                if (hadValue && isRightUnaryOperator) {
                    hasValue = true;
                    hadValue = false;
                }
                else
                    hasValue = false;
                checkAdvance();
                break;
            case identifier:
                GrVariable lvalue;
                currentType = parseIdentifier(lvalue, lastType, grVoid, isExpectingLValue);
                // Débale la valeur pour 1 ou moins de types de retour.
                // S’il y a plus d’une valeur, on laisse comme tel pour `parseExpressionList()`.
                if (currentType.base == GrType.Base.internalTuple) {
                    auto types = grUnpackTuple(currentType);
                    if (!types.length)
                        currentType = grVoid;
                    else if (types.length == 1uL)
                        currentType = types[0];
                }

                // Vérifie si c’est une assignation ou non, on ignore si c’est une `rvalue`
                const auto nextLexeme = get();
                if (lvalue !is null && (requireLValue(nextLexeme.type) ||
                        (isExpectingLValue && nextLexeme.type == GrLexeme.Type.comma))) {
                    hasLValue = true;
                    lvalues ~= lvalue;

                    if (lvalue.isAuto)
                        hasValue = true;
                }

                if (!hasLValue && nextLexeme.type == GrLexeme.Type.leftBracket)
                    hasReference = true;

                if (currentType != GrType(GrType.Base.void_)) {
                    hasValue = true;
                    typeStack ~= currentType;
                }
                break;
            default:
                logError(format(getError(Error.unexpectedXSymbolInExpr),
                        getPrettyLexemeType(lex.type)), getError(Error.unexpectedSymbol));
            }

            if (hasValue && hadValue)
                logError(getError(Error.missingSemicolonAtEndOfExpr), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.semicolon),
                        getPrettyLexemeType(get().type)));
        }
        while (!isEndOfExpression);

        if (operatorsStack.length) {
            if (!hadValue) {
                logError(getError(Error.binOpMustHave2Operands), getError(Error.missingVal));
            }
        }

        while (operatorsStack.length) {
            GrLexeme.Type operator = operatorsStack[$ - 1];

            switch (operator) with (GrLexeme.Type) {
            case assign:
                addSetInstruction(lvalues[$ - 1], fileId, currentType,
                    isExpectingValue || operatorsStack.length > 1uL);
                currentType = lvalues[$ - 1].type;
                lvalues.length--;

                if (operatorsStack.length <= 1uL)
                    hadValue = false;
                break;
            case bitwiseAndAssign: .. case powerAssign:
                currentType = addOperator(
                    operator - (GrLexeme.Type.bitwiseAndAssign - GrLexeme.Type.bitwiseAnd),
                    typeStack, fileId);
                addSetInstruction(lvalues[$ - 1], fileId, currentType,
                    isExpectingValue || operatorsStack.length > 1uL);
                lvalues.length--;

                if (operatorsStack.length <= 1uL)
                    hadValue = false;
                break;
            case increment: .. case decrement:
                currentType = addOperator(operator, typeStack, fileId);
                addSetInstruction(lvalues[$ - 1], fileId, currentType,
                    isExpectingValue || operatorsStack.length > 1uL);
                lvalues.length--;

                if (operatorsStack.length <= 1uL)
                    hadValue = false;
                break;
            default:
                currentType = addOperator(operator, typeStack, fileId);
                break;
            }

            operatorsStack.length--;
        }

        if (isExpectingLValue) {
            if (!hadLValue)
                logError(getError(Error.valBeforeAssignationNotReferenceable),
                    getError(Error.missingRefBeforeAssignation));
            result.lvalue = lvalues[$ - 1];
        }

        if (mustCleanValue && hadValue && currentType.base != GrType.Base.void_)
            shiftStackPosition(currentType, -1);

        result.type = currentType;
        return result;
    }

    private void addLoadFieldInstruction(GrType type, uint index, bool asCopy) {
        final switch (type.base) with (GrType.Base) {
        case bool_:
        case int_:
        case func:
        case task:
        case event:
        case enum_:
        case float_:
        case string_:
        case reference:
        case channel:
        case class_:
        case optional:
        case list:
        case native:
            addInstruction(asCopy ? GrOpcode.fieldLoad2 : GrOpcode.fieldLoad, index);
            break;
        case internalTuple:
        case null_:
        case void_:
            logError(format(getError(Error.cantLoadFieldOfTypeX),
                    getPrettyType(type)), getError(Error.fieldTypeIsInvalid));
            break;
        }
    }

    /// Analyse un appel de fonction sur un type anonyme
    private GrType parseAnonymousCall(GrType type, GrType selfType = grVoid) {
        const uint fileId = get().fileId;

        if (type.base != GrType.Base.func && type.base != GrType.Base.task)
            logError(format(getError(Error.xNotCallable), getPrettyType(type)),
                format(getError(Error.xNotFuncNorTask), getPrettyType(type)));

        // Analyse de la signature avec conversion de type
        GrType[] signature;
        GrType[] anonSignature = grUnmangleSignature(type.mangledType);
        int i;
        if (selfType != grVoid) {
            signature ~= convertType(selfType, anonSignature[i], fileId);
            i++;
        }
        if (get().type == GrLexeme.Type.leftParenthesis) {
            checkAdvance();
            if (get().type != GrLexeme.Type.rightParenthesis) {
                for (;;) {
                    if (i >= anonSignature.length) {
                        logError(format(getError(anonSignature.length > 1 ?
                                Error.funcTakesXArgsButMoreWereSupplied : Error.funcTakesXArgButMoreWereSupplied),
                                anonSignature.length), format(getError(anonSignature.length > 1 ?
                                Error.expectedXArg : Error.expectedXArgs),
                                anonSignature.length), format(getError(Error.funcIsOfTypeX),
                                getPrettyType(type)));
                    }
                    GrType subType = parseSubExpression(
                        GR_SUBEXPR_TERMINATE_COMMA | GR_SUBEXPR_TERMINATE_PARENTHESIS |
                            GR_SUBEXPR_EXPECTING_VALUE).type;
                    if (subType.base == GrType.Base.internalTuple) {
                        auto types = grUnpackTuple(subType);
                        if (types.length) {
                            for (int y; y < types.length; y++, i++) {
                                if (i >= anonSignature.length) {
                                    logError(format(getError(anonSignature.length > 1 ?
                                            Error.funcTakesXArgsButMoreWereSupplied
                                            : Error.funcTakesXArgButMoreWereSupplied),
                                            anonSignature.length), format(getError(anonSignature.length > 1 ?
                                            Error.expectedXArg : Error.expectedXArgs),
                                            anonSignature.length), format(getError(Error.funcIsOfTypeX),
                                            getPrettyType(type)));
                                }
                                signature ~= convertType(types[y], anonSignature[i], fileId);
                            }
                        }
                        else
                            logError(getError(Error.exprYieldsNoVal),
                                getError(Error.expectedValFoundNothing));
                    }
                    else {
                        signature ~= convertType(subType, anonSignature[i], fileId);
                        i++;
                    }
                    if (get().type == GrLexeme.Type.rightParenthesis) {
                        checkAdvance();
                        break;
                    }
                    advance();
                }
            }
            else {
                checkAdvance();
            }
        }
        if (signature.length != anonSignature.length) {
            logError(format(getError(anonSignature.length > 1 ? Error.funcTakesXArgsButYWereSupplied
                    : Error.funcTakesXArgButYWereSupplied), anonSignature.length, signature.length),
                format(getError(anonSignature.length > 1 ?
                    Error.expectedXArgsFoundY
                    : Error.expectedXArgFoundY), anonSignature.length, signature.length),
                format(getError(Error.funcIsOfTypeX), getPrettyType(type)));
        }

        // Pousse les valeurs sur la pile globale pour la tâche créée
        if (type.base == GrType.Base.task)
            addGlobalPush(signature);

        // Appel anonyme
        GrType retTypes = grPackTuple(grUnmangleSignature(type.mangledReturnType));

        if (type.base == GrType.Base.func) {
            int offset = cast(int) anonSignature.length;

            if (selfType != grVoid)
                offset--;

            addInstruction(GrOpcode.anonymousCall, offset);
        }
        else
            addInstruction(GrOpcode.anonymousTask, 0u);
        return retTypes;
    }

    /// Analyse un identificateur ou un appel de fonction
    /// et retourne le type déduit et sa `lvalue`.
    private GrType parseIdentifier(ref GrVariable variableRef,
        GrType expectedType, GrType selfType = grVoid, bool isAssignment = false) {
        GrType returnType = GrType.Base.void_;
        const GrLexeme identifier = get();
        bool isFunctionCall = false, isMethodCall = false, hasParenthesis = false;
        string identifierName = identifier.svalue;
        const uint fileId = identifier.fileId;

        advance();

        if (selfType.base != GrType.Base.void_) {
            isMethodCall = true;
            isFunctionCall = true;
        }

        if (get().type == GrLexeme.Type.leftParenthesis) {
            isFunctionCall = true;
            hasParenthesis = true;
        }

        if (isFunctionCall) {
            GrType[] signature;

            if (hasParenthesis)
                advance();

            GrVariable variable = currentFunction.getLocal(identifierName);
            if (!variable)
                variable = getGlobalVariable(identifierName, fileId);
            if (variable) {
                if (variable.type.base != GrType.Base.func && variable.type.base != GrType
                    .Base.task)
                    logError(format(getError(Error.xNotCallable), identifierName),
                        format(getError(Error.funcOrTaskExpectedFoundX),
                            getPrettyType(variable.type)), "", -1);
                // Analyse de la signature avec conversion de type
                GrType[] anonSignature = grUnmangleSignature(variable.type.mangledType);
                int i;
                if (isMethodCall) {
                    if (!anonSignature.length)
                        logError(getError(Error.missingParamOnMethodCall),
                            getError(Error.methodCallMustBePlacedAfterVal));
                    signature ~= convertType(selfType, anonSignature[i], fileId);
                    i++;
                }
                if (hasParenthesis && get().type != GrLexeme.Type.rightParenthesis) {
                    for (;;) {
                        if (i >= anonSignature.length) {
                            logError(format(getError(anonSignature.length > 1 ?
                                    Error.funcTakesXArgsButMoreWereSupplied : Error.funcTakesXArgButMoreWereSupplied),
                                    anonSignature.length), format(getError(anonSignature.length > 1 ?
                                    Error.expectedXArgs : Error.expectedXArg),
                                    anonSignature.length), format(getError(Error.funcIsOfTypeX),
                                    getPrettyType(variable.type)),
                                0, getError(Error.funcDefHere), variable.lexPosition);
                        }
                        GrType subType = parseSubExpression(
                            GR_SUBEXPR_TERMINATE_COMMA | GR_SUBEXPR_TERMINATE_PARENTHESIS |
                                GR_SUBEXPR_EXPECTING_VALUE).type;
                        if (subType.base == GrType.Base.internalTuple) {
                            auto types = grUnpackTuple(subType);
                            if (types.length) {
                                for (int y; y < types.length; y++, i++) {
                                    if (i >= anonSignature.length) {
                                        logError(format(getError(anonSignature.length > 1 ?
                                                Error.funcTakesXArgsButMoreWereSupplied
                                                : Error.funcTakesXArgButMoreWereSupplied),
                                                anonSignature.length), format(getError(anonSignature.length > 1 ?
                                                Error.expectedXArgs : Error.expectedXArg),
                                                anonSignature.length),
                                            format(getError(Error.funcIsOfTypeX),
                                                getPrettyType(variable.type)), 0,
                                            getError(Error.funcDefHere), variable.lexPosition);
                                    }
                                    signature ~= convertType(types[y], anonSignature[i], fileId);
                                }
                            }
                            else
                                logError(getError(Error.exprYieldsNoVal),
                                    getError(Error.expectedValFoundNothing));
                        }
                        else {
                            signature ~= convertType(subType, anonSignature[i], fileId);
                            i++;
                        }
                        if (get().type == GrLexeme.Type.rightParenthesis) {
                            if (signature.length != anonSignature.length) {
                                logError(format(getError(anonSignature.length > 1 ?
                                        Error.funcTakesXArgsButYWereSupplied : Error.funcTakesXArgButYWereSupplied),
                                        anonSignature.length, signature.length),
                                    format(getError(anonSignature.length > 1 ?
                                        Error.expectedXArgsFoundY
                                        : Error.expectedXArgFoundY),
                                        anonSignature.length, signature.length),
                                    format(getError(Error.funcIsOfTypeX),
                                        getPrettyType(variable.type)));
                            }
                            break;
                        }
                        advance();
                    }
                    if (hasParenthesis && get().type == GrLexeme.Type.rightParenthesis)
                        advance();
                }
                else {
                    if (hasParenthesis && get().type == GrLexeme.Type.rightParenthesis)
                        advance();
                    if (signature.length != anonSignature.length) {
                        logError(format(getError(anonSignature.length > 1 ?
                                Error.funcTakesXArgsButYWereSupplied : Error.funcTakesXArgButYWereSupplied),
                                anonSignature.length, signature.length),
                            format(getError(anonSignature.length > 1 ? Error.expectedXArgsFoundY
                                : Error.expectedXArgFoundY),
                                anonSignature.length, signature.length),
                            format(getError(Error.funcIsOfTypeX), getPrettyType(variable.type)));
                    }
                }

                // Pousse les valeurs sur la pile globale pour la tâche créée
                if (variable.type.base == GrType.Base.task)
                    addGlobalPush(signature);

                // Appel anonyme
                addGetInstruction(variable);

                returnType = grPackTuple(grUnmangleSignature(variable.type.mangledReturnType));

                if (variable.type.base == GrType.Base.func)
                    addInstruction(GrOpcode.anonymousCall, 0u);
                else if (variable.type.base == GrType.Base.task)
                    addInstruction(GrOpcode.anonymousTask, 0u);
            }
            else {
                if (isMethodCall) {
                    if (selfType.base == GrType.Base.internalTuple)
                        signature ~= grUnpackTuple(selfType);
                    else
                        signature ~= selfType;
                }
                //Signature parsing, no coercion is made
                // Analyse de la signature sans coercition
                if (hasParenthesis && get().type != GrLexeme.Type.rightParenthesis) {
                    for (;;) {
                        auto type = parseSubExpression(
                            GR_SUBEXPR_TERMINATE_COMMA | GR_SUBEXPR_TERMINATE_PARENTHESIS |
                                GR_SUBEXPR_EXPECTING_VALUE).type;
                        if (type.base == GrType.Base.internalTuple) {
                            auto types = grUnpackTuple(type);
                            if (types.length)
                                signature ~= types;
                            else
                                logError(getError(Error.exprYieldsNoVal),
                                    getError(Error.expectedValFoundNothing));
                        }
                        else
                            signature ~= type;

                        if (get().type == GrLexeme.Type.rightParenthesis)
                            break;
                        advance();
                    }
                }
                if (hasParenthesis && get().type == GrLexeme.Type.rightParenthesis)
                    advance();

                // Appel de fonction
                auto matching = getFirstMatchingFuncOrPrim(identifierName, signature, fileId);
                if (matching.prim) {
                    addInstruction(GrOpcode.primitiveCall, matching.prim.index);
                    returnType = grPackTuple(matching.prim.outSignature);
                }
                else if (matching.func) {
                    returnType = grPackTuple(addFunctionCall(matching.func, fileId));
                }
                else {
                    logError(format(getError(Error.xNotDecl), getPrettyFunctionCall(identifierName,
                            signature)), getError(Error.unknownFunc), "", -1);
                }
            }
        }
        else if (_data.isEnum(identifier.svalue, fileId, false)) {
            const GrEnumDefinition definition = _data.getEnum(identifier.svalue, fileId);
            if (get().type != GrLexeme.Type.period)
                logError(getError(Error.expectedDotAfterEnumType),
                    getError(Error.missingEnumConstantName));
            checkAdvance();
            if (get().type != GrLexeme.Type.identifier)
                logError(getError(Error.expectedConstNameAfterEnumType),
                    getError(Error.missingEnumConstantName));
            const string fieldName = get().svalue;
            if (!definition.hasField(fieldName)) {
                const string[] nearestValues = findNearestStrings(fieldName, definition.fields);
                string errorNote;
                if (nearestValues.length) {
                    foreach (size_t i, const string value; nearestValues) {
                        errorNote ~= "`" ~ value ~ "`";
                        if ((i + 1) < nearestValues.length)
                            errorNote ~= ", ";
                    }
                    errorNote ~= ".";
                }
                logError(format(getError(Error.noFieldXOnTypeY), fieldName, definition.name),
                    getError(Error.unknownField),
                    format(getError(Error.availableFieldsAreX), errorNote));
            }
            checkAdvance();

            returnType = GrType(GrType.Base.enum_);
            returnType.mangledType = definition.name;
            addIntConstant(definition.getField(fieldName));
        }
        else {
            // Variable déclarée
            variableRef = getVariable(identifierName, fileId);
            returnType = variableRef.type;
            // Si c’est une assignation, on veut que l’instruction pour charger la valeur
            // soit après l’assignation et non avant.
            const auto nextLexeme = get();
            if (!(nextLexeme.type == GrLexeme.Type.assign || (isAssignment &&
                    nextLexeme.type == GrLexeme.Type.comma)))
                addGetInstruction(variableRef, expectedType);
        }
        return returnType;
    }

    /// À appeler avant un `>` attendu.
    /// Permet d’empêcher les symboles comme `>>` d’être mal interprétés.
    private void distinguishTemplateLexemes() {
        switch (get().type) with (GrLexeme.Type) {
        case rightShift:
            lexemes[current].type = GrLexeme.Type.greater;
            lexemes[current].textLength = 1;
            lexemes[current + 1].type = GrLexeme.Type.greater;
            break;
        case greaterOrEqual:
            lexemes[current].type = GrLexeme.Type.greater;
            lexemes[current].textLength = 1;
            lexemes[current + 1].type = GrLexeme.Type.equal;
            break;
        default:
            return;
        }
    }

    private string getPrettyFunctionCall(string name, GrType[] signature) {
        return grGetPrettyFunctionCall(name, signature);
    }

    private string getPrettyFunction(GrFunction func) {
        return grGetPrettyFunction(func);
    }

    private string getPrettyType(GrType type) {
        return grGetPrettyType(type);
    }

    private string getPrettyLexemeType(GrLexeme.Type type) {
        return grGetPrettyLexemeType(type);
    }

    /// Vérifie et lance une erreur.
    private void assertError(bool assertion, string message, string info,
        string note = "", int offset = 0) {
        if (assertion)
            return;
        logError(message, info, note, offset);
    }

    /// Génère une erreur et lance une exception.
    private void logError(string message, string info, string note = "",
        int offset = 0, string otherInfo = "", uint otherPos = 0) {
        GrError error = new GrError;
        error.type = GrError.Type.parser;
        error.message = message;
        error.info = info;
        error.note = note;

        GrLexeme lex = (isEnd() && offset >= 0) ? get(-1) : get(offset);
        error.filePath = lex.getFile();
        error.lineText = lex.getLine().replace("\t", " ");
        error.line = lex.line + 1u; // Par convention, la première ligne commence à 1, et non 0.
        error.column = lex.column;
        error.textLength = lex.textLength;

        if (otherInfo.length) {
            error.otherInfo = otherInfo;

            set(otherPos);

            GrLexeme otherLex = isEnd() ? get(-1) : get();
            error.otherFilePath = otherLex.getFile();
            error.otherLineText = otherLex.getLine().replace("\t", " ");
            error.otherLine = otherLex.line + 1u; // Par convention, la première ligne commence à 1, et non 0.
            error.otherColumn = otherLex.column;
            error.otherTextLength = otherLex.textLength;
        }
        throw new GrParserException(error);
    }

    private enum Error {
        eofReached,
        eof,
        nameXDefMultipleTimes,
        xRedefHere,
        prevDefOfX,
        prevDefPrim,
        alreadyDef,
        cantDefVarOfTypeX,
        invalidType,
        xNotDef,
        unknownFunc,
        cantUseTypeAsParam,
        invalidParamType,
        xNotDecl,
        unknownVar,
        opMustHave1RetVal,
        expected1RetValFoundX,
        expected1RetValFoundXs,
        cantUseOpOnMultipleVal,
        exprYieldsMultipleVal,
        noXUnaryOpDefForY,
        noXBinaryOpDefForYAndZ,
        unknownOp,
        exprIsConstAndCantBeModified,
        xIsConstAndCantBeModified,
        cantModifyAConst,
        cantCallXWithArgsYBecausePure,
        callCanCauseASideEffect,
        maybeUsePure,
        cantAssignToAXVar,
        ValNotAssignable,
        cantInferTypeOfVar,
        varNotInit,
        cantGetValueOfX,
        valNotFetchable,
        unknownClass,
        unknownType,
        locVarUsedNotAssigned,
        globalDeclExpected,
        globalDeclExpectedFoundX,
        funcMissingRetAtEnd,
        missingRet,
        expectedTypeAliasNameFoundX,
        expectedEnumNameFoundX,
        expectedXFoundY,
        missingIdentifier,
        missingColonBeforeType,
        missingSemicolonAfterType,
        enumDefNotHaveBody,
        expectedEnumFieldFoundX,
        missingSemicolonAfterEnumField,
        xAlreadyDecl,
        expectedClassNameFoundX,
        parentClassNameMissing,
        classHaveNoBody,
        missingSemicolonAfterClassFieldDecl,
        xCantInheritFromY,
        xIncludedRecursively,
        recursiveInheritence,
        fieldXDeclMultipleTimes,
        recursiveDecl,
        xNotValidType,
        expectedValidTypeFoundX,
        listCanOnlyContainOneTypeOfVal,
        conflictingListSignature,
        tryUsingXInstead,
        channelCanOnlyContainOneTypeOfVal,
        conflictingChannelSignature,
        missingTemplateVal,
        templateValShouldBeSeparatedByComma,
        templateTypesShouldBeSeparatedByComma,
        missingParentheses,
        paramShouldBeSeparatedByComma,
        expectedIdentifierFoundX,
        typesShouldBeSeparatedByComma,
        addingPubBeforeEventIsRedundant,
        eventAlreadyPublic,
        cantOverrideXOp,
        opCantBeOverriden,
        missingConstraint,
        xIsNotAKnownConstraint,
        validConstraintsAreX,
        expectedColonAfterType,
        constraintTakesXArgButYWereSupplied,
        constraintTakesXArgsButYWereSupplied,
        convMustHave1RetVal,
        convMustHave1Param,
        expected1ParamFoundX,
        expected1ParamFoundXs,
        missingCurlyBraces,
        deferInsideDefer,
        cantDeferInsideDefer,
        xInsideDefer,
        cantXInsideDefer,
        breakOutsideLoop,
        cantBreakOutsideLoop,
        continueOutsideLoop,
        cantContinueOutsideLoop,
        xNotValidRetType,
        chanSizeMustBePositive,
        listSizeMustBePositive,
        missingCommaOrGreaterInsideChanSignature,
        missingCommaOrGreaterInsideListSignature,
        missingXInChanSignature,
        missingXInListSignature,
        missingXInNullSignature,
        expectedIntFoundX,
        chanSizeMustBeOneOrHigher,
        listSizeMustBeZeroOrHigher,
        expectedAtLeastSizeOf1FoundX,
        expectedCommaOrGreaterFoundX,
        chanCantBeOfTypeX,
        invalidChanType,
        missingParenthesesAfterX,
        missingCommaInX,
        onlyOneDefaultCasePerX,
        defaultCaseAlreadyDef,
        prevDefaultCaseDef,
        missingWhileOrUntilAfterLoop,
        expectedWhileOrUntilFoundX,
        listCantBeOfTypeX,
        invalidListType,
        primXMustRetOptional,
        signatureMismatch,
        funcXMustRetOptional,
        notIterable,
        forCantIterateOverX,
        cantEvalArityUnknownCompound,
        arityEvalError,
        typeOfIteratorMustBeIntNotX,
        iteratorMustBeInt,
        mismatchedNumRetVal,
        expectedXRetValFoundY,
        expectedXRetValsFoundY,
        retSignatureOfTypeX,
        retTypeXNotMatchSignatureY,
        expectedXVal,
        opNotListedInOpPriorityTable,
        unknownOpPriority,
        mismatchedTypes,
        missingX,
        xNotClassType,
        fieldXInitMultipleTimes,
        xAlreadyInit,
        prevInit,
        fieldXNotExist,
        unknownField,
        expectedFieldNameFoundX,
        missingField,
        indexesShouldBeSeparatedByComma,
        missingVal,
        expectedIndexFoundComma,
        expectedIntFoundNothing,
        noValToConv,
        expectedVarFoundX,
        missingVar,
        exprYieldsNoVal,
        expectedValFoundNothing,
        missingSemicolonAfterExprList,
        tryingAssignXValsToYVar,
        tryingAssignXValsToYVars,
        moreValThanVarToAssign,
        assignationMissingVal,
        expressionEmpty,
        firstValOfAssignmentListCantBeEmpty,
        cantInferTypeWithoutAssignment,
        missingTypeInfoOrInitVal,
        missingSemicolonAfterAssignmentList,
        typeXHasNoDefaultVal,
        cantInitThisType,
        expectedFuncNameFoundX,
        missingFuncName,
        cantInferTypeOfX,
        funcTypeCantBeInferred,
        unexpectedXFoundInExpr,
        xCantExistInsideThisExpr,
        methodCallMustBePlacedAfterVal,
        listCantBeIndexedByX,
        invalidListIndexType,
        cantAccessFieldOnTypeX,
        expectedClassFoundX,
        xOnTypeYIsPrivate,
        privateField,
        noFieldXOnTypeY,
        availableFieldsAreX,
        missingParamOnMethodCall,
        xMustBePlacedAfterVal,
        xMustBeInsideFuncOrTask,
        xRefNoFuncNorTask,
        valBeforeAssignationNotReferenceable,
        missingRefBeforeAssignation,
        cantDoThisKindOfOpOnLeftSideOfAssignement,
        unexpectedOp,
        unOpMustHave1Operand,
        binOpMustHave2Operands,
        unexpectedXSymbolInExpr,
        unexpectedSymbol,
        missingSemicolonAtEndOfExpr,
        cantLoadFieldOfTypeX,
        fieldTypeIsInvalid,
        xNotCallable,
        xNotFuncNorTask,
        funcTakesXArgButMoreWereSupplied,
        funcTakesXArgsButMoreWereSupplied,
        funcIsOfTypeX,
        expectedXArg,
        expectedXArgs,
        funcTakesXArgButYWereSupplied,
        funcTakesXArgsButYWereSupplied,
        expectedXArgFoundY,
        expectedXArgsFoundY,
        funcOrTaskExpectedFoundX,
        funcDefHere,
        expectedDotAfterEnumType,
        missingEnumConstantName,
        expectedConstNameAfterEnumType,
        xIsAbstract,
        xIsAbstractAndCannotBeInstanciated,
        expectedOptionalType,
        opMustFollowAnOptionalType
    }

    private string getError(Error error) {
        immutable string[Error][GrLocale.max + 1] messages = [
            [ // en_US
                Error.eofReached: "reached the end of the file",
                Error.eof: "unexpected end of file",
                Error.unknownFunc: "unknown function",
                Error.unknownVar: "unknown variable",
                Error.unknownOp: "unknown operator",
                Error.unknownClass: "unknown class",
                Error.unknownType: "unknown type",
                Error.unknownOpPriority: "unknown operator priority",
                Error.unknownField: "unknown field",
                Error.invalidType: "invalid type",
                Error.invalidParamType: "invalid parameter type",
                Error.invalidChanType: "invalid channel type",
                Error.invalidListType: "invalid list type",
                Error.invalidListIndexType: "invalid list index type",
                Error.xNotDef: "`%s` is not defined",
                Error.xNotDecl: "`%s` is not declared",
                Error.nameXDefMultipleTimes: "the name `%s` is defined multiple times",
                Error.xRedefHere: "`%s` is redefined here",
                Error.prevDefOfX: "previous definition of `%s`",
                Error.prevDefPrim: "`%s` is already defined as a primitive",
                Error.alreadyDef: "`%s` is already declared",
                Error.cantDefVarOfTypeX: "can't define a variable of type %s",
                Error.cantUseTypeAsParam: "can't use `%s` as a parameter type",
                Error.opMustHave1RetVal: "an operator must have only one return value",
                Error.expected1RetValFoundX: "expected 1 return value, found %s return value",
                Error.expected1RetValFoundXs: "expected 1 return value, found %s return values",
                Error.cantUseOpOnMultipleVal: "can't use an operator on multiple values",
                Error.exprYieldsMultipleVal: "the expression yields multiple values",
                Error.noXUnaryOpDefForY: "there is no `%s` unary operator defined for `%s`",
                Error.noXBinaryOpDefForYAndZ: "there is no `%s` binary operator defined for `%s` and `%s`",
                Error.exprIsConstAndCantBeModified: "the expression is const and can't be modified",
                Error.xIsConstAndCantBeModified: "`%s` is const and can't be modified",
                Error.cantModifyAConst: "can't modify a const",
                Error.cantCallXWithArgsYBecausePure: "can't call `%s` with arguments `%s` because a pure parameter is mutable",
                Error.callCanCauseASideEffect: "this call may trigger a side effet",
                Error.maybeUsePure: "maybe you should change the function's parameter to `pure` ?",
                Error.cantAssignToAXVar: "can't assign to a `%s` variable",
                Error.ValNotAssignable: "the value is not assignable",
                Error.cantInferTypeOfVar: "can't infer the type of variable",
                Error.varNotInit: "the variable has not been initialized",
                Error.locVarUsedNotAssigned: "the local variable is being used without being assigned",
                Error.cantGetValueOfX: "can't get the value of `%s`",
                Error.valNotFetchable: "the value is not fetchable",
                Error.globalDeclExpected: "a global declaration is expected",
                Error.globalDeclExpectedFoundX: "a global declaration is expected, found `%s`",
                Error.funcMissingRetAtEnd: "the function is missing a return at the end of the scope",
                Error.missingRet: "missing `return`",
                Error.expectedTypeAliasNameFoundX: "expected type alias name, found `%s`",
                Error.expectedEnumNameFoundX: "expected enum name, found `%s`",
                Error.expectedXFoundY: "expected `%s`, found `%s`",
                Error.missingIdentifier: "missing identifier",
                Error.missingColonBeforeType: "missing `:` before type",
                Error.missingSemicolonAfterType: "missing `;` after type",
                Error.enumDefNotHaveBody: "the enum definition does not have a body",
                Error.expectedEnumFieldFoundX: "expected enum field, found `%s`",
                Error.missingSemicolonAfterEnumField: "missing `;` after type enum field",
                Error.xAlreadyDecl: "`%s` is already declared",
                Error.expectedClassNameFoundX: "expected class name, found `%s`",
                Error.parentClassNameMissing: "the parent class name is missing",
                Error.classHaveNoBody: "the class does not have a body",
                Error.missingSemicolonAfterClassFieldDecl: "missing `;` after class field declaration",
                Error.xCantInheritFromY: "`%s` can't inherit from `%s`",
                Error.xIncludedRecursively: "`%s` is included recursively",
                Error.recursiveInheritence: "recursive inheritence",
                Error.fieldXDeclMultipleTimes: "the field `%s` is declared multiple times",
                Error.recursiveDecl: "recursive declaration",
                Error.xNotValidType: "`%s` is not a valid type",
                Error.expectedValidTypeFoundX: "expected a valid type, found `%s`",
                Error.listCanOnlyContainOneTypeOfVal: "a list can only contain one type of value",
                Error.conflictingListSignature: "conflicting list signature",
                Error.tryUsingXInstead: "try using `%s` instead",
                Error.channelCanOnlyContainOneTypeOfVal: "a channel can only contain one type of value",
                Error.conflictingChannelSignature: "conflicting channel signature",
                Error.missingTemplateVal: "missing template value",
                Error.templateValShouldBeSeparatedByComma: "template values should be separated by a comma",
                Error.templateTypesShouldBeSeparatedByComma: "template types should be separated by a comma",
                Error.missingParentheses: "missing parentheses",
                Error.paramShouldBeSeparatedByComma: "parameters should be separated by a comma",
                Error.expectedIdentifierFoundX: "expected identifier, found `%s`",
                Error.typesShouldBeSeparatedByComma: "types should be separated by a comma",
                Error.addingPubBeforeEventIsRedundant: "adding `public` before `event` is redundant",
                Error.eventAlreadyPublic: "event is already public",
                Error.cantOverrideXOp: "can't override `%s` operator",
                Error.opCantBeOverriden: "this operator can't be overriden",
                Error.missingConstraint: "missing constraint",
                Error.xIsNotAKnownConstraint: "`%s` is not a known constraint",
                Error.validConstraintsAreX: "valid constraints are: %s",
                Error.expectedColonAfterType: "`:` expected after a type",
                Error.constraintTakesXArgButYWereSupplied: "the constraint takes %s argument but %s were supplied",
                Error.constraintTakesXArgsButYWereSupplied: "the constraint takes %s arguments but %s were supplied",
                Error.convMustHave1RetVal: "a conversion must have only one return value",
                Error.convMustHave1Param: "a conversion must have only one parameter",
                Error.expected1ParamFoundX: "expected 1 parameter, found %s parameter",
                Error.expected1ParamFoundXs: "expected 1 parameter, found %s parameters",
                Error.missingCurlyBraces: "missing curly braces",
                Error.expectedIntFoundX: "expected int_, found `%s`",
                Error.deferInsideDefer: "`defer` inside another `defer`",
                Error.cantDeferInsideDefer: "can't `defer` inside another `defer`",
                Error.xInsideDefer: "`%s` inside a defer",
                Error.cantXInsideDefer: "can't `%s` inside a defer",
                Error.breakOutsideLoop: "`break` outside of a loop",
                Error.cantBreakOutsideLoop: "can't `break` outside of a loop",
                Error.continueOutsideLoop: "`continue` outside of a loop",
                Error.cantContinueOutsideLoop: "can't `continue` outside of a loop",
                Error.xNotValidRetType: "`%s` is not a valid return type",
                Error.chanSizeMustBePositive: "a channel size must be a positive integer value",
                Error.listSizeMustBePositive: "an list size must be a positive integer value",
                Error.missingCommaOrGreaterInsideChanSignature: "missing `,` or `>` inside channel signature",
                Error.missingCommaOrGreaterInsideListSignature: "missing `,` or `>` inside list signature",
                Error.missingXInChanSignature: "missing `%s` after the channel signature",
                Error.missingXInListSignature: "missing `%s` after the list signature",
                Error.missingXInNullSignature: "missing `%s` after the null signature",
                Error.chanSizeMustBeOneOrHigher: "the channel size must be one or higher",
                Error.listSizeMustBeZeroOrHigher: "the list size must be zero or higher",
                Error.expectedAtLeastSizeOf1FoundX: "expected at least a size of 1, found %s",
                Error.expectedCommaOrGreaterFoundX: "expected `,` or `>`, found `%s`",
                Error.chanCantBeOfTypeX: "a channel can't be of type `%s`",
                Error.missingParenthesesAfterX: "missing parentheses after `%s`",
                Error.missingCommaInX: "missing comma in `%s`",
                Error.onlyOneDefaultCasePerX: "there must be only up to one default case per `%s`",
                Error.defaultCaseAlreadyDef: "default case already defined",
                Error.prevDefaultCaseDef: "previous default case definition",
                Error.missingWhileOrUntilAfterLoop: "missing `while` or `until` after the loop",
                Error.expectedWhileOrUntilFoundX: "expected `while` or `until`, found `%s`",
                Error.listCantBeOfTypeX: "a list can't be of type `%s`",
                Error.primXMustRetOptional: "the primitive `%s` must return an optional type",
                Error.signatureMismatch: "signature mismatch",
                Error.funcXMustRetOptional: "the function `%s` must return an optional type",
                Error.notIterable: "not iterable",
                Error.forCantIterateOverX: "for can't iterate over a `%s`",
                Error.cantEvalArityUnknownCompound: "can't evaluate the arity of an unknown compound",
                Error.arityEvalError: "arity evaluation error",
                Error.typeOfIteratorMustBeIntNotX: "the type of the iterator must be an `int`, not `%s`",
                Error.iteratorMustBeInt: "the iterator must be an `int`",
                Error.mismatchedNumRetVal: "mismatched number of return values",
                Error.expectedXRetValFoundY: "expected %s return value, found %s",
                Error.expectedXRetValsFoundY: "expected %s return values, found %s",
                Error.retSignatureOfTypeX: "the return signature is of type `%s`",
                Error.retTypeXNotMatchSignatureY: "the returned type `%s` does not match the signature `%s`",
                Error.expectedXVal: "expected `%s` value",
                Error.opNotListedInOpPriorityTable: "the operator is not listed in the operator priority table",
                Error.mismatchedTypes: "mismatched types",
                Error.missingX: "missing `%s`",
                Error.xNotClassType: "`%s` is not a class type",
                Error.fieldXInitMultipleTimes: "the field `%s` is initialized multiple times",
                Error.xAlreadyInit: "`%s` is already initialized",
                Error.prevInit: "previous initialization",
                Error.fieldXNotExist: "the field `%s` doesn't exist",
                Error.expectedFieldNameFoundX: "expected field name, found `%s`",
                Error.missingField: "missing field",
                Error.indexesShouldBeSeparatedByComma: "indexes should be separated by a comma",
                Error.missingVal: "missing value",
                Error.expectedIndexFoundComma: "an index is expected, found `,`",
                Error.expectedIntFoundNothing: "expected `int`, found nothing",
                Error.noValToConv: "no value to convert",
                Error.expectedVarFoundX: "expected variable, found `%s`",
                Error.missingVar: "missing variable",
                Error.exprYieldsNoVal: "the expression yields no value",
                Error.expectedValFoundNothing: "expected value, found nothing",
                Error.missingSemicolonAfterExprList: "missing `;` after expression list",
                Error.tryingAssignXValsToYVar: "trying to assign `%s` values to %s variable",
                Error.tryingAssignXValsToYVars: "trying to assign `%s` values to %s variables",
                Error.moreValThanVarToAssign: "there are more values than variable to assign to",
                Error.assignationMissingVal: "the assignation is missing a value",
                Error.expressionEmpty: "the expression is empty",
                Error.firstValOfAssignmentListCantBeEmpty: "first value of an assignment list can't be empty",
                Error.cantInferTypeWithoutAssignment: "can't infer the type without assignment",
                Error.missingTypeInfoOrInitVal: "missing type information or initial value",
                Error.missingSemicolonAfterAssignmentList: "missing `;` after assignment list",
                Error.typeXHasNoDefaultVal: "the type `%s` has no default value",
                Error.cantInitThisType: "can't initialize this type",
                Error.expectedFuncNameFoundX: "expected function name, found `%s`",
                Error.missingFuncName: "missing function name",
                Error.cantInferTypeOfX: "can't infer the type of `%s`",
                Error.funcTypeCantBeInferred: "the function type can't be inferred",
                Error.unexpectedXFoundInExpr: "unexpected `%s` found in expression",
                Error.xCantExistInsideThisExpr: "a `%s` can't exist inside this expression",
                Error.methodCallMustBePlacedAfterVal: "a method call must be placed after a value",
                Error.listCantBeIndexedByX: "a list can't be indexed by a `%s`",
                Error.cantAccessFieldOnTypeX: "can't access a field on type `%s`",
                Error.expectedClassFoundX: "expected a class, found `%s`",
                Error.xOnTypeYIsPrivate: "`%s` on type `%s` is private",
                Error.privateField: "private field",
                Error.noFieldXOnTypeY: "no field `%s` on type `%s`",
                Error.availableFieldsAreX: "available fields are: %s",
                Error.missingParamOnMethodCall: "missing parameter on method call",
                Error.xMustBePlacedAfterVal: "`%s` must be placed after a value",
                Error.xMustBeInsideFuncOrTask: "`%s` must be inside a function or a task",
                Error.xRefNoFuncNorTask: "`%s` references no function nor task",
                Error.valBeforeAssignationNotReferenceable: "the value before assignation is not referenceable",
                Error.missingRefBeforeAssignation: "missing reference before assignation",
                Error.cantDoThisKindOfOpOnLeftSideOfAssignement: "can't do this kind of operation on the left side of an assignment",
                Error.unexpectedOp: "unexpected operation",
                Error.unOpMustHave1Operand: "an unary operation must have 1 operand",
                Error.binOpMustHave2Operands: "a binary operation must have 2 operands",
                Error.unexpectedXSymbolInExpr: "unexpected `%s` symbol in the expression",
                Error.unexpectedSymbol: "unexpected symbol",
                Error.missingSemicolonAtEndOfExpr: "missing `;` at the end of the expression",
                Error.cantLoadFieldOfTypeX: "can't load a field of type `%s`",
                Error.fieldTypeIsInvalid: "the field type is invalid",
                Error.xNotCallable: "`%s` is not callable",
                Error.xNotFuncNorTask: "`%s` is not a function nor a task",
                Error.funcTakesXArgButMoreWereSupplied: "the function takes %s argument but more were supplied",
                Error.funcTakesXArgsButMoreWereSupplied: "the function takes %s arguments but more were supplied",
                Error.funcIsOfTypeX: "the function is of type `%s`",
                Error.expectedXArg: "expected %s argument",
                Error.expectedXArgs: "expected %s arguments",
                Error.funcTakesXArgButYWereSupplied: "the function takes %s argument but %s were supplied",
                Error.funcTakesXArgsButYWereSupplied: "the function takes %s arguments but %s were supplied",
                Error.expectedXArgFoundY: "expected %s argument, found %s",
                Error.expectedXArgsFoundY: "expected %s arguments, found %s",
                Error.funcOrTaskExpectedFoundX: "function or task expected, found `%s`",
                Error.funcDefHere: "function defined here",
                Error.expectedDotAfterEnumType: "expected a `.` after the enum type",
                Error.missingEnumConstantName: "missing the enum constant name",
                Error.expectedConstNameAfterEnumType: "expected a constant name after the enum type",
                Error.xIsAbstract: "`%s` is abstract",
                Error.xIsAbstractAndCannotBeInstanciated: "`%s` is abstract and can't be instanciated",
                Error.expectedOptionalType: "`?` expect an optional type",
                Error.opMustFollowAnOptionalType: "`?` must be placed after the optional to unwrap"
            ],
            [ // fr_FR
                Error.eofReached: "fin de fichier atteinte",
                Error.eof: "fin de fichier inattendue",
                Error.unknownFunc: "fonction inconnue",
                Error.unknownVar: "variable inconnue",
                Error.unknownOp: "opérateur inconnu",
                Error.unknownClass: "classe inconnue",
                Error.unknownType: "type inconnu",
                Error.unknownOpPriority: "priorité d’opérateur inconnue",
                Error.unknownField: "champ inconnu",
                Error.invalidType: "type invalide",
                Error.invalidParamType: "type de paramètre invalide",
                Error.invalidChanType: "type de canal invalide",
                Error.invalidListType: "type de liste invalide",
                Error.invalidListIndexType: "type d’index de liste invalide",
                Error.xNotDef: "`%s` n’est pas défini",
                Error.xNotDecl: "`%s` n’est pas déclaré",
                Error.nameXDefMultipleTimes: "le nom `%s` est défini plusieurs fois",
                Error.xRedefHere: "`%s` est redéfini ici",
                Error.prevDefOfX: "précédente définition de `%s`",
                Error.prevDefPrim: "`%s` est déjà défini en tant que primitive",
                Error.alreadyDef: "`%s` est déjà défini",
                Error.cantDefVarOfTypeX: "impossible définir une variable du type %s",
                Error.cantUseTypeAsParam: "impossible d’utiliser `%s` comme type de paramètre",
                Error.opMustHave1RetVal: "un operateur ne doit avoir qu'une valeur de retour",
                Error.expected1RetValFoundX: "1 valeur de retour attendue, %s valeur trouvée",
                Error.expected1RetValFoundXs: "1 valeur de retour attendue, %s valeurs trouvées",
                Error.cantUseOpOnMultipleVal: "impossible d’utiliser un opérateur sur plusieurs valeurs",
                Error.exprYieldsMultipleVal: "l’expression délivre plusieurs valeurs",
                Error.noXUnaryOpDefForY: "il n’y a pas d’opérateur unaire `%s` défini pour `%s`",
                Error.noXBinaryOpDefForYAndZ: "il n’y pas d’opérateur binaire `%s` défini pour `%s` et `%s`",
                Error.exprIsConstAndCantBeModified: "l’expression est constante et ne peut être assigné",
                Error.xIsConstAndCantBeModified: "`%s` est constant et ne peut être assigné",
                Error.cantModifyAConst: "impossible de modifier un type constant",
                Error.cantCallXWithArgsYBecausePure: "impossible d’appeler `%s` avec les arguments `%s` car un paramètre pur est modifiable",
                Error.callCanCauseASideEffect: "l’appel risque de créer un effet de bord",
                Error.maybeUsePure: "peut-être voudriez-vous changer le paramètre de la fonction en `pure` ?",
                Error.cantAssignToAXVar: "impossible d’assigner à une variable `%s`",
                Error.ValNotAssignable: "la valeur est non-assignable",
                Error.cantInferTypeOfVar: "impossible d’inférer le type de la variable",
                Error.varNotInit: "la variable n’a pas été initialisée",
                Error.locVarUsedNotAssigned: "la variable locale est utilisée sans avoir été assignée",
                Error.cantGetValueOfX: "impossible de récupérer la valeure de `%s`",
                Error.valNotFetchable: "la valeur n’est pas récupérable",
                Error.globalDeclExpected: "une déclaration globale est attendue",
                Error.globalDeclExpectedFoundX: "une déclaration globale est attendue, `%s` trouvé",
                Error.funcMissingRetAtEnd: "il manque un retour en fin de fonction",
                Error.missingRet: "`return` manquant",
                Error.expectedTypeAliasNameFoundX: "nom d’alias de type attendu, `%s` trouvé",
                Error.expectedEnumNameFoundX: "nom d'énumération attendu, `%s` trouvé",
                Error.expectedXFoundY: "`%s` attendu, `%s` trouvé",
                Error.missingIdentifier: "identificateur attendu",
                Error.missingColonBeforeType: "`:` manquant avant le type",
                Error.missingSemicolonAfterType: "`;` manquant après le type",
                Error.enumDefNotHaveBody: "la définition de l’énumération n’a pas de corps",
                Error.expectedEnumFieldFoundX: "champ attendu dans l’énumération, `%s` trouvé",
                Error.missingSemicolonAfterEnumField: "`;` manquant après le champ de l’énumération",
                Error.xAlreadyDecl: "`%s` est déjà déclaré",
                Error.expectedClassNameFoundX: "nom de classe attendu, `%s` trouvé",
                Error.parentClassNameMissing: "le nom de la classe parente est manquante",
                Error.classHaveNoBody: "la classe n’a pas de corps",
                Error.missingSemicolonAfterClassFieldDecl: "`;` manquant après le champ de la classe",
                Error.xCantInheritFromY: "`%s` ne peut pas hériter de `%s`",
                Error.xIncludedRecursively: "`%s` est inclus récursivement",
                Error.recursiveInheritence: "héritage récursif",
                Error.fieldXDeclMultipleTimes: "le champ `%s` est déclaré plusieurs fois",
                Error.recursiveDecl: "déclaration récursive",
                Error.xNotValidType: "`%s` n’est pas un type valide",
                Error.expectedValidTypeFoundX: "type valide attendu, `%s` trouvé",
                Error.listCanOnlyContainOneTypeOfVal: "une liste ne peut contenir qu’un type de valeur",
                Error.conflictingListSignature: "signature de liste conflictuelle",
                Error.tryUsingXInstead: "utilisez plutôt `%s`",
                Error.channelCanOnlyContainOneTypeOfVal: "un canal ne peut contenir qu’un type de valeur",
                Error.conflictingChannelSignature: "signature de canal conflictuelle",
                Error.missingTemplateVal: "valeur de patron manquante",
                Error.templateValShouldBeSeparatedByComma: "les valeurs de patron doivent être séparées par des virgules",
                Error.templateTypesShouldBeSeparatedByComma: "les types de patron doivent être séparés par des virgules",
                Error.missingParentheses: "parenthèses manquantes",
                Error.paramShouldBeSeparatedByComma: "les paramètres doivent être séparées par des virgules",
                Error.expectedIdentifierFoundX: "identificateur attendu, `%s` trouvé",
                Error.typesShouldBeSeparatedByComma: "les types doivent être séparés par des virgules",
                Error.addingPubBeforeEventIsRedundant: "ajouter `public` devant `event` est redondant",
                Error.eventAlreadyPublic: "les events sont déjà publiques",
                Error.cantOverrideXOp: "impossible de surcharger l’opérateur `%s`",
                Error.opCantBeOverriden: "cet opérateur ne peut être surchargé",
                Error.missingConstraint: "contrainte manquante",
                Error.xIsNotAKnownConstraint: "`%s` n’est pas une contrainte connue",
                Error.validConstraintsAreX: "les contraintes valides sont: %s",
                Error.expectedColonAfterType: "`:` attendu après le type",
                Error.constraintTakesXArgButYWereSupplied: "cette contrainte prend %s argument mais %s ont été fournis",
                Error.constraintTakesXArgsButYWereSupplied: "cette contrainte prend %s arguments mais %s ont été fournis",
                Error.convMustHave1RetVal: "une conversion ne peut avoir qu’une seule valeur de retour",
                Error.convMustHave1Param: "une conversion ne peut avoir qu’un seul paramètre",
                Error.expected1ParamFoundX: "1 paramètre attendu, %s paramètre trouvé",
                Error.expected1ParamFoundXs: "1 paramètre attendu, %s paramètres trouvés",
                Error.missingCurlyBraces: "accolades manquantes",
                Error.expectedIntFoundX: "entier attendu, `%s` trouvé",
                Error.deferInsideDefer: "`defer` à l’intérieur d’un autre `defer`",
                Error.cantDeferInsideDefer: "impossible de faire un `defer` dans un autre `defer`",
                Error.xInsideDefer: "`%s` à l’intérieur d’un `defer`",
                Error.cantXInsideDefer: "impossible de faire un `%s` dans un `defer`",
                Error.breakOutsideLoop: "`break` en dehors d’une boucle",
                Error.cantBreakOutsideLoop: "impossible de `break` en dehors d’une boucle",
                Error.continueOutsideLoop: "`continue` en dehors d’une boucle",
                Error.cantContinueOutsideLoop: "impossible de `continue` en dehors d’une boucle",
                Error.xNotValidRetType: "`%s` n’est pas un type de retour valide",
                Error.chanSizeMustBePositive: "la taille d’un canal doit être un entier positif",
                Error.listSizeMustBePositive: "la taille d’une liste doit être un entier positif",
                Error.missingCommaOrGreaterInsideChanSignature: "`,` ou `)` manquant dans la signature du canal",
                Error.missingCommaOrGreaterInsideListSignature: "`,` ou `)` manquant dans la signature de la liste",
                Error.missingXInChanSignature: "`%s` manquantes après la signature du canal",
                Error.missingXInListSignature: "`%s` manquantes après la signature de la liste",
                Error.missingXInNullSignature: "`%s` manquantes après la signature du type nul",
                Error.chanSizeMustBeOneOrHigher: "la taille du canal doit être de un ou plus",
                Error.listSizeMustBeZeroOrHigher: "la taille d’une liste doit être supérieure à zéro",
                Error.expectedAtLeastSizeOf1FoundX: "une taille de 1 minimum attendue, %s trouvé",
                Error.expectedCommaOrGreaterFoundX: "`,` ou `>` attendu, `%s` trouvé",
                Error.chanCantBeOfTypeX: "un canal ne peut être de type `%s`",
                Error.missingParenthesesAfterX: "parenthèses manquantes après `%s`",
                Error.missingCommaInX: "virgule manquante dans `%s`",
                Error.onlyOneDefaultCasePerX: "il ne peut y avoir un maximum d’un cas par défaut dans un `%s`",
                Error.defaultCaseAlreadyDef: "le cas par défaut a déjà été défini",
                Error.prevDefaultCaseDef: "précédente définition du cas par défaut",
                Error.missingWhileOrUntilAfterLoop: "`tant` ou `jusque` manquant après la boucle",
                Error.expectedWhileOrUntilFoundX: "`tant` ou `jusque` attendu, `%s` trouvé",
                Error.listCantBeOfTypeX: "une liste ne peut pas être de type `%s`",
                Error.primXMustRetOptional: "la primitive `%s` doit retourner un type optionnel",
                Error.signatureMismatch: "la signature ne correspond pas",
                Error.funcXMustRetOptional: "la function `%s` doit retourner un type optionnel",
                Error.notIterable: "non-itérable",
                Error.forCantIterateOverX: "for ne peut itérer sur `%s`",
                Error.cantEvalArityUnknownCompound: "impossible de calculer l’arité d’un composé inconnu",
                Error.arityEvalError: "erreur de calcul d’arité",
                Error.typeOfIteratorMustBeIntNotX: "le type d’un itérateur doit être un entier, pas `%s`",
                Error.iteratorMustBeInt: "l’itérateur doit être un entier",
                Error.mismatchedNumRetVal: "le nombre de valeur de retour ne correspond pas",
                Error.expectedXRetValFoundY: "%s valeur de retour attendue, %s trouvé",
                Error.expectedXRetValsFoundY: "%s valeurs de retour attendues, %s trouvé",
                Error.retSignatureOfTypeX: "la signature de retour est `%s`",
                Error.retTypeXNotMatchSignatureY: "le type retourné `%s` ne correspond pas avec la signature `%s`",
                Error.expectedXVal: "type `%s` attendu",
                Error.opNotListedInOpPriorityTable: "l’opérateur n’est pas listé dans la liste de priorité d’opérateurs",
                Error.mismatchedTypes: "types différents",
                Error.missingX: "`%s` manquant",
                Error.xNotClassType: "`%s` n’est pas un type de classe",
                Error.fieldXInitMultipleTimes: "le champ `%s` est initialisé plusieurs fois",
                Error.xAlreadyInit: "`%s` est déjà initialisé",
                Error.prevInit: "initialisation précédente",
                Error.fieldXNotExist: "le champ `%s` n’existe pas",
                Error.expectedFieldNameFoundX: "nom de champ attendu, `%s` trouvé",
                Error.missingField: "champ manquant",
                Error.indexesShouldBeSeparatedByComma: "les index doivent être séparés par une virgule",
                Error.missingVal: "valeur manquante",
                Error.expectedIndexFoundComma: "un index est attendu, `,` trouvé",
                Error.expectedIntFoundNothing: "entier attendu, rien de trouvé",
                Error.noValToConv: "aucune valeur à convertir",
                Error.expectedVarFoundX: "variable attendu, `%s` trouvé",
                Error.missingVar: "variable manquante",
                Error.exprYieldsNoVal: "l’expression ne rend aucune valeur",
                Error.expectedValFoundNothing: "valeur attendue, rien de trouvé",
                Error.missingSemicolonAfterExprList: "`;` manquant après la liste d’expressions",
                Error.tryingAssignXValsToYVar: "tentative d’assigner `%s` valeurs à %s variable",
                Error.tryingAssignXValsToYVars: "tentative d’assigner `%s` valeurs à %s variables",
                Error.moreValThanVarToAssign: "il y a plus de valeurs que de variables auquels affecter",
                Error.assignationMissingVal: "il manque une valeur à l’assignation",
                Error.expressionEmpty: "l’expression est vide",
                Error.firstValOfAssignmentListCantBeEmpty: "la première valeur d’une liste d’assignation ne peut être vide",
                Error.cantInferTypeWithoutAssignment: "impossible d’inférer le type sans assignation",
                Error.missingTypeInfoOrInitVal: "information de type ou valeur initiale manquante",
                Error.missingSemicolonAfterAssignmentList: "`;` manquant après la liste d’assignation",
                Error.typeXHasNoDefaultVal: "le type `%s` n’a pas de valeur par défaut",
                Error.cantInitThisType: "impossible d’initialiser ce type",
                Error.expectedFuncNameFoundX: "nom de fonction attendu, `%s` trouvé",
                Error.missingFuncName: "nom de fonction manquant",
                Error.cantInferTypeOfX: "impossible d’inférer le type de `%s`",
                Error.funcTypeCantBeInferred: "le type de la fonction ne peut pas être inféré",
                Error.unexpectedXFoundInExpr: "`%s` inattendu dans l’expression",
                Error.xCantExistInsideThisExpr: "un `%s` ne peut exister dans l’expression",
                Error.methodCallMustBePlacedAfterVal: "un appel de méthode doit se placer après une valeur",
                Error.listCantBeIndexedByX: "une liste ne peut pas être indexé par un `%s`",
                Error.cantAccessFieldOnTypeX: "impossible d’accéder à un champ sur `%s`",
                Error.expectedClassFoundX: "classe attendue, `%s` trouvé",
                Error.xOnTypeYIsPrivate: "`%s` du type `%s` est privé",
                Error.privateField: "champ privé",
                Error.noFieldXOnTypeY: "aucun champ `%s` dans `%s`",
                Error.availableFieldsAreX: "les champs disponibles sont: %s",
                Error.missingParamOnMethodCall: "paramètre manquant dans l’appel de méthode",
                Error.xMustBePlacedAfterVal: "`%s` doit être placé après une valeur",
                Error.xMustBeInsideFuncOrTask: "`%s` doit être à l’intérieur d’une fonction ou d’une tâche",
                Error.xRefNoFuncNorTask: "`%s` ne référence aucune fonction ou tâche",
                Error.valBeforeAssignationNotReferenceable: "la valeur devant l’assignation n’est pas référençable",
                Error.missingRefBeforeAssignation: "référence manquante avant l’assignation",
                Error.cantDoThisKindOfOpOnLeftSideOfAssignement: "ce genre d’opération est impossible à gauche d’une assignation",
                Error.unexpectedOp: "opération inattendue",
                Error.unOpMustHave1Operand: "une opération unaire doit avoir 1 opérande",
                Error.binOpMustHave2Operands: "une opération binaire doit avoir 2 opérandes",
                Error.unexpectedXSymbolInExpr: "symbole `%s` inattendu dans l’expression",
                Error.unexpectedSymbol: "symbole inattendu",
                Error.missingSemicolonAtEndOfExpr: "`;` manquant en fin d’expression",
                Error.cantLoadFieldOfTypeX: "impossible de charger un champ de type `%s`",
                Error.fieldTypeIsInvalid: "le type de champ est invalide",
                Error.xNotCallable: "`%s` n’est pas appelable",
                Error.xNotFuncNorTask: "`%s` n’est ni une fonction ni une tâche",
                Error.funcTakesXArgButMoreWereSupplied: "cette fonction prend %s argument mais plus ont été fournis",
                Error.funcTakesXArgsButMoreWereSupplied: "cette fonction prend %s arguments mais plus ont été fournis",
                Error.funcIsOfTypeX: "cette fonction est de type `%s`",
                Error.expectedXArg: "%s argument attendu",
                Error.expectedXArgs: "%s arguments attendus",
                Error.funcTakesXArgButYWereSupplied: "cette fonction prend %s argument mais %s ont été fournis",
                Error.funcTakesXArgsButYWereSupplied: "cette fonction prend %s arguments mais %s ont été fournis",
                Error.expectedXArgFoundY: "%s argument attendu, %s trouvé",
                Error.expectedXArgsFoundY: "%s arguments attendus, %s trouvé",
                Error.funcOrTaskExpectedFoundX: "fonction ou tâche attendu, `%s` trouvé",
                Error.funcDefHere: "fonction définie là",
                Error.expectedDotAfterEnumType: "`.` attendu après le type d’énumération",
                Error.missingEnumConstantName: "nom de la constante d’énumération attendu",
                Error.expectedConstNameAfterEnumType: "nom de la constante attendue après le type d’énumération",
                Error.xIsAbstract: "`%s` est abstrait",
                Error.xIsAbstractAndCannotBeInstanciated: "`%s` est abstrait et ne peut pas être instancié",
                Error.expectedOptionalType: "`?` nécessite un type optionnel",
                Error.opMustFollowAnOptionalType: "`?` doit être placé après le type optionnel à déballer"
            ]
        ];
        return messages[_locale][error];
    }
}

/// Décrit une erreur syntaxique
package final class GrParserException : Exception {
    GrError error;

    this(GrError error_, string file = __FILE__, size_t line = __LINE__) {
        super(error_.message, file, line);
        error = error_;
    }
}
