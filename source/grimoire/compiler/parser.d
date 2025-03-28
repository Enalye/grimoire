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
import std.exception : enforce;

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
        GrInt[] intConsts;
        GrUInt[] uintConsts;
        GrByte[] byteConsts;
        GrFloat[] floatConsts;
        GrDouble[] doubleConsts;
        string[] strConsts;

        uint scopeLevel;

        GrVariable[] globalVariables;
        GrFunction[] functionsQueue, functions, events;
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
        foreach (size_t index, GrInt intConst; intConsts) {
            if (intConst == value)
                return cast(uint) index;
        }
        intConsts ~= value;
        return cast(uint) intConsts.length - 1;
    }

    /// Enregistre un nouvel entier non-signé et retourne son id
    private uint registerUIntConstant(GrUInt value) {
        foreach (size_t index, GrUInt uintConst; uintConsts) {
            if (uintConst == value)
                return cast(uint) index;
        }
        uintConsts ~= value;
        return cast(uint) uintConsts.length - 1;
    }

    /// Enregistre un nouvel octet non-signé et retourne son id
    private uint registerByteConstant(GrByte value) {
        foreach (size_t index, GrByte byteConst; byteConsts) {
            if (byteConst == value)
                return cast(uint) index;
        }
        byteConsts ~= value;
        return cast(uint) byteConsts.length - 1;
    }

    /// Enregistre un nouveau flottant et retourne son id
    private uint registerFloatConstant(GrFloat value) {
        foreach (size_t index, GrFloat floatConst; floatConsts) {
            if (floatConst == value)
                return cast(uint) index;
        }
        floatConsts ~= value;
        return cast(uint) floatConsts.length - 1;
    }

    /// Enregistre un nouveau flottant double précision et retourne son id
    private uint registerDoubleConstant(GrDouble value) {
        foreach (size_t index, GrFloat doubleConst; doubleConsts) {
            if (doubleConst == value)
                return cast(uint) index;
        }
        doubleConsts ~= value;
        return cast(uint) doubleConsts.length - 1;
    }

    /// Enregistre une nouvelle chaîne de caractères et retourne son id
    private uint registerStringConstant(string value) {
        foreach (size_t index, string strConst; strConsts) {
            if (strConst == value)
                return cast(uint) index;
        }
        strConsts ~= value;
        return cast(uint) strConsts.length - 1;
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
    private GrVariable registerVariable(string name, GrType type, bool isAuto, bool isGlobal, bool isConst,
        bool isExport, bool isDeferred = false, uint lexPosition = 0, bool hasPosition = false) {

        size_t fileId = get().fileId;

        { // On vérifie si d’autres définitions existent
            bool isAlreadyDeclared, hasDeclPosition;
            uint declPosition;

            /*foreach (GrVariable variable; globalVariables) {
                if (variable.name == name && (variable.fileId == fileId ||
                        variable.isExport || isExport)) {
                    isAlreadyDeclared = true;
                    declPosition = variable.lexPosition;
                    hasDeclPosition = variable.hasLexPosition;
                    break;
                }
            }

            if (!isAlreadyDeclared) {
                foreach (primitive; _data._abstractPrimitives) {
                    if (primitive.name == name) {
                        isAlreadyDeclared = true;
                        break;
                    }
                }
            }

            if (!isAlreadyDeclared) {
                foreach (GrTemplateFunction func; templatedFunctions) {
                    if (func.name == name && (func.fileId == fileId || func.isExport || isExport)) {
                        isAlreadyDeclared = true;
                        declPosition = func.nameLexPosition;
                        hasDeclPosition = true;
                    }
                }
            }
            */

            if (isAlreadyDeclared) {
                if (hasPosition) {
                    current = lexPosition;
                }

                if (hasDeclPosition) {
                    logError(format(getError(Error.nameXDefMultipleTimes), name),
                        format(getError(Error.xRedefHere), name), "", 0,
                        format(getError(Error.prevDefOfX), name), declPosition);
                }
                else {
                    logError(format(getError(Error.nameXDefMultipleTimes),
                            name), format(getError(Error.prevDefPrim), name));
                }
            }
        }

        GrVariable variable = new GrVariable;
        variable.isAuto = isAuto;
        variable.isGlobal = isGlobal;
        variable.isInitialized = false;
        variable.type = type;
        variable.isConst = isConst;
        variable.name = name;
        variable.isExport = isExport;
        variable.fileId = fileId;

        if (hasPosition) {
            variable.hasLexPosition = true;
            variable.lexPosition = lexPosition;
        }
        else {
            variable.lexPosition = current;
        }

        if (!isAuto)
            setVariableRegister(variable);

        if (!isDeferred) {
            if (isGlobal)
                globalVariables ~= variable;
            else
                currentFunction.setLocal(variable);
        }

        return variable;
    }

    private GrVariable getGlobalVariable(string name, size_t fileId, bool isExport = false) {
        foreach (GrVariable variable; globalVariables) {
            if (variable.name == name && (variable.fileId == fileId || variable.isExport || isExport))
                return variable;
        }
        return null;
    }

    private void setVariableRegister(GrVariable variable) {
        if (variable.type.isInternal) {
            logError(format(getError(Error.cantDefVarOfTypeX),
                    getPrettyType(variable.type)), getError(Error.invalidType));
        }

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
            func.isExport = true;
            func.fileId = 0;
            func.lexPosition = 0;
            functions ~= func;
            functionStack ~= currentFunction;
            currentFunction = func;
        }
    }

    private void endGlobalScope() {
        enforce!GrCompilerException(functionStack.length, "global scope mismatch");

        currentFunction = functionStack[$ - 1];
        functionStack.length--;
    }

    private void beginFunction(string name, size_t fileId, GrType[] signature, bool isEvent = false) {
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

    private void preBeginFunction(string name, uint nameLexPosition, size_t fileId,
        GrType[] signature, string[] inputVariables, bool isTask, GrType[] outSignature = [
        ], bool isAnonymous = false, bool isEvent = false, bool isExport = false) {
        GrFunction func = new GrFunction;
        func.isTask = isTask;
        func.isEvent = isEvent;
        func.inputVariables = inputVariables;
        func.inSignature = signature;
        func.outSignature = outSignature;
        func.fileId = fileId;
        func.nameLexPosition = nameLexPosition;

        if (isAnonymous) {
            func.anonParent = currentFunction;
            func.anonReference = cast(uint) currentFunction.instructions.length;
            func.name = currentFunction.name ~ "@anon" ~ to!string(currentFunction.anonCount);
            currentFunction.anonCount++;
            func.mangledName = grMangleComposite(func.name, func.inSignature);
            anonymousFunctions ~= func;
            func.lexPosition = current;

            func.makeClosure();

            // Remplacé par l’adresse de la fonction dans `solveFunctionCalls()`
            addInstruction(GrOpcode.closure, 0u);

            // Limite la taille de la pile à celle qu’attend la tâche
            addInstruction(GrOpcode.extend, func.anonParent.localsCount);
        }
        else {
            func.name = name;
            func.isExport = isExport;

            func.mangledName = grMangleComposite(name, signature);

            { // On vérifie si d’autres définitions existent
                bool isAlreadyDeclared, isPrimitive;
                uint declPosition;

                foreach (GrVariable variable; globalVariables) {
                    if (variable.name == name && (variable.fileId == fileId ||
                            variable.isExport || isExport)) {
                        isAlreadyDeclared = true;
                        declPosition = variable.lexPosition;
                        break;
                    }
                }

                foreach (primitive; _data._abstractPrimitives) {
                    if (primitive.mangledName == func.mangledName) {
                        isAlreadyDeclared = true;
                        isPrimitive = true;
                        break;
                    }
                }

                foreach (GrTemplateFunction otherFunc; templatedFunctions) {
                    if (otherFunc.name == name && (otherFunc.fileId == fileId ||
                            otherFunc.isExport || isExport)) {
                        if (grMangleComposite(otherFunc.name,
                                otherFunc.inSignature) == func.mangledName) {
                            isAlreadyDeclared = true;
                            declPosition = otherFunc.nameLexPosition;
                        }
                    }
                }

                if (isAlreadyDeclared) {
                    current = nameLexPosition;

                    if (isPrimitive) {
                        logError(format(getError(Error.funcXDefMultipleTimes),
                                grGetPrettyFunction(func)),
                            format(getError(Error.prevDefPrim), name));
                    }
                    else {
                        logError(format(getError(Error.funcXDefMultipleTimes),
                                grGetPrettyFunction(func)), format(getError(Error.xRedefHere), name), "", 0,
                            format(getError(Error.prevDefOfX), name), declPosition);
                    }
                }
            }

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

        enforce!GrCompilerException(functionStack.length,
            "attempting to close a non-existing function");
        currentFunction = functionStack[$ - 1];
        functionStack.length--;
    }

    private void preEndFunction() {
        enforce!GrCompilerException(functionStack.length,
            "attempting to close a non-existing function");
        currentFunction = functionStack[$ - 1];
        functionStack.length--;
    }

    /// Génère les opcodes pour récupérer les paramètres de la fonction
    void generateFunctionInputs() {
        void fetchParameter(string name, GrType type) {
            if (!type.isValid) {
                logError(format(getError(Error.cantUseTypeAsParam),
                        getPrettyType(type)), getError(Error.invalidParamType));
            }

            currentFunction.nbParameters++;

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

    GrFunction getFunction(string mangledName, size_t fileId = 0, bool isExport = false) {
        foreach (GrFunction func; functions) {
            if (func.mangledName == mangledName && (func.fileId == fileId ||
                    func.isExport || isExport)) {
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
        size_t fileId = 0, bool isExport = false) {
        struct Result {
            GrPrimitive prim;
            GrFunction func;
        }

        Result result;

        foreach (ref GrType type; signature) {
            if (!type.isValid) {
                logError(format(getError(Error.cantUseTypeAsParam),
                        getPrettyType(type)), getError(Error.invalidParamType));
            }
        }

        size_t arity = signature.length;

        if (name == "@as") {
            arity = 1;
        }
        else if (name.length >= "@static_".length && name[0 .. "@static_".length] == "@static_") {
            if (signature.length) {
                arity--;
            }
        }

        bool checkSignaturePurity(GrType[] funcSignature) {
            for (int i; i < signature.length; ++i) {
                final switch (signature[i].base) with (GrType.Base) {
                case void_:
                case null_:
                case int_:
                case uint_:
                case char_:
                case byte_:
                case float_:
                case double_:
                case bool_:
                case enum_:
                case func:
                case task:
                case event:
                case instance:
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
                        return false;
                    }
                    continue;
                }
            }
            return true;
        }

        struct AvailableFunc {
            enum Type {
                function_,
                primitive,
                tempFunction,
                tempPrimitive
            }

            Type type;

            union {
                GrFunction func;
                GrPrimitive prim;
                GrTemplateFunction tempFunc;
            }
        }

        AvailableFunc[] fetchAvailableFuncs(string name, size_t fileId, bool isExport) {
            AvailableFunc[] availableFuncs;
            foreach (GrFunction func; functions ~ functionsQueue) {
                if (func.name == name && (func.fileId == fileId || func.isExport || isExport)) {
                    AvailableFunc av;
                    av.func = func;
                    av.type = AvailableFunc.Type.function_;
                    availableFuncs ~= av;
                }
            }
            foreach (GrTemplateFunction func; templatedFunctions) {
                if (func.name == name && (func.fileId == fileId || func.isExport || isExport)) {
                    AvailableFunc av;
                    av.tempFunc = func;
                    av.type = AvailableFunc.Type.tempFunction;
                    availableFuncs ~= av;
                }
            }
            foreach (GrPrimitive prim; _data._primitives) {
                if (prim.name == name) {
                    AvailableFunc av;
                    av.prim = prim;
                    av.type = AvailableFunc.Type.primitive;
                    availableFuncs ~= av;
                }
            }
            foreach (GrPrimitive prim; _data._abstractPrimitives) {
                if (prim.name == name) {
                    AvailableFunc av;
                    av.prim = prim;
                    av.type = AvailableFunc.Type.tempPrimitive;
                    availableFuncs ~= av;
                }
            }

            return availableFuncs;
        }

        AvailableFunc[] filterAvailableFuncs(AvailableFunc[] availableFuncs,
            string name, GrType[] signature, size_t fileId, bool isExport) {

            const string mangledName = grMangleComposite(name, signature);
            int minScore = int.max - 1;
            AvailableFunc[] filteredFuncs;

            if (name == "@as")
                minScore = 0;

            foreach (AvailableFunc av; availableFuncs) {
                int currentScore = int.max;

                final switch (av.type) with (AvailableFunc.Type) {
                case function_:
                    if (av.func.mangledName == mangledName) {
                        currentScore = -2;
                    }
                    else if (minScore >= -1 && _data.isSignatureCompatible(signature,
                            av.func.inSignature, false, fileId, isExport)) {
                        if (checkSignaturePurity(av.func.inSignature))
                            currentScore = -1;
                    }
                    else if (minScore > 0) {
                        uint nbOperations;
                        if (convertSignature(nbOperations, signature, arity,
                                av.func.inSignature, false, fileId, true)) {
                            if (checkSignaturePurity(av.func.inSignature))
                                currentScore = nbOperations + 1;
                        }
                    }
                    break;
                case primitive:
                    if (av.prim.mangledName == mangledName) {
                        currentScore = -2;
                    }
                    else if (minScore >= -1 && _data.isSignatureCompatible(signature,
                            av.prim.inSignature, false, fileId, true)) {
                        if (checkSignaturePurity(av.prim.inSignature))
                            currentScore = -1;
                    }
                    else if (minScore > 0) {
                        uint nbOperations;
                        if (convertSignature(nbOperations, signature, arity,
                                av.prim.inSignature, false, fileId, true)) {
                            if (checkSignaturePurity(av.prim.inSignature))
                                currentScore = nbOperations + 1;
                        }
                    }
                    break;
                case tempFunction:
                    GrAnyData anyData = new GrAnyData;
                    _data.setAnyData(anyData);

                    if (minScore >= 0 && _data.isSignatureCompatible(signature,
                            av.tempFunc.inSignature, true, fileId, isExport)) {
                        bool isValid = true;
                        foreach (ref GrConstraint constraint; av.tempFunc.constraints) {
                            if (!constraint.evaluate(_data, anyData)) {
                                isValid = false;
                                break;
                            }
                        }
                        if (isValid && checkSignaturePurity(av.tempFunc.inSignature))
                            currentScore = 0;
                    }
                    else if (minScore > 0) {
                        uint nbOperations;
                        anyData = new GrAnyData;
                        _data.setAnyData(anyData);

                        if (convertSignature(nbOperations, signature, arity,
                                av.tempFunc.inSignature, true, fileId, true)) {
                            bool isValid = true;
                            foreach (ref GrConstraint constraint; av.tempFunc.constraints) {
                                if (!constraint.evaluate(_data, anyData)) {
                                    isValid = false;
                                    break;
                                }
                            }
                            if (isValid && checkSignaturePurity(av.tempFunc.inSignature))
                                currentScore = nbOperations + 1;
                        }
                    }
                    break;
                case tempPrimitive:
                    GrAnyData anyData = new GrAnyData;
                    _data.setAnyData(anyData);

                    if (minScore >= 0 && _data.isSignatureCompatible(signature,
                            av.prim.inSignature, true, fileId, true)) {
                        bool isValid = true;
                        foreach (ref GrConstraint constraint; av.prim.constraints) {
                            if (!constraint.evaluate(_data, anyData)) {
                                isValid = false;
                                break;
                            }
                        }
                        if (isValid && checkSignaturePurity(av.prim.inSignature))
                            currentScore = 0;
                    }
                    else if (minScore > 0) {
                        uint nbOperations;
                        anyData = new GrAnyData;
                        _data.setAnyData(anyData);

                        if (convertSignature(nbOperations, signature, arity,
                                av.prim.inSignature, true, fileId, true)) {
                            bool isValid = true;
                            foreach (ref GrConstraint constraint; av.prim.constraints) {
                                if (!constraint.evaluate(_data, anyData)) {
                                    isValid = false;
                                    break;
                                }
                            }
                            if (isValid && checkSignaturePurity(av.prim.inSignature))
                                currentScore = nbOperations + 1;
                        }
                    }
                    break;
                }

                if (currentScore == minScore) {
                    filteredFuncs ~= av;
                }
                if (currentScore < minScore) {
                    minScore = currentScore;
                    filteredFuncs.length = 0;
                    filteredFuncs ~= av;
                }
            }

            return filteredFuncs;
        }

        AvailableFunc[] filterSpecializedFuncs(AvailableFunc[] availableFuncs) {
            AvailableFunc[] filteredFuncs = availableFuncs;

            for (size_t paramIdx; paramIdx < arity; ++paramIdx) {
                int minScore = -1;
                availableFuncs = filteredFuncs;
                filteredFuncs.length = 0;

                if (availableFuncs.length <= 1) {
                    return availableFuncs;
                }

                foreach (AvailableFunc av; availableFuncs) {
                    int score;

                    final switch (av.type) with (AvailableFunc.Type) {
                    case function_:
                        score = _data.getTypeSpecializationScore(av.func.inSignature[paramIdx]);
                        break;
                    case primitive:
                    case tempPrimitive:
                        score = _data.getTypeSpecializationScore(av.prim.inSignature[paramIdx]);
                        break;
                    case tempFunction:
                        score = _data.getTypeSpecializationScore(av.tempFunc.inSignature[paramIdx]);
                        break;
                    }

                    if (score > minScore) {
                        minScore = score;
                        filteredFuncs.length = 0;
                        filteredFuncs ~= av;
                    }
                    else if (score == minScore) {
                        filteredFuncs ~= av;
                    }
                }
            }

            return filteredFuncs;
        }

        AvailableFunc[] filterReifiedFuncs(AvailableFunc[] availableFuncs) {
            AvailableFunc[] filteredFuncs;
            bool hasReifiedFunc;

            foreach (AvailableFunc av; availableFuncs) {
                final switch (av.type) with (AvailableFunc.Type) {
                case function_:
                case primitive:
                    if (!hasReifiedFunc) {
                        hasReifiedFunc = true;
                        filteredFuncs.length = 0;
                    }
                    filteredFuncs ~= av;
                    break;
                case tempFunction:
                case tempPrimitive:
                    if (hasReifiedFunc) {
                        continue;
                    }
                    filteredFuncs ~= av;
                    break;
                }
            }

            return filteredFuncs;
        }

        AvailableFunc[] availableFuncs = fetchAvailableFuncs(name, fileId, isExport);
        availableFuncs = filterAvailableFuncs(availableFuncs, name, signature, fileId, isExport);
        availableFuncs = filterSpecializedFuncs(availableFuncs);
        availableFuncs = filterReifiedFuncs(availableFuncs);

        if (availableFuncs.length > 1) {
            string[] matchingFuncNames;
            foreach (AvailableFunc av; availableFuncs) {
                final switch (av.type) with (AvailableFunc.Type) {
                case function_:
                    matchingFuncNames ~= getPrettyFunction(av.func);
                    break;
                case primitive:
                    matchingFuncNames ~= grGetPrettyFunction(av.prim.name,
                        av.prim.inSignature, av.prim.outSignature);
                    break;
                case tempFunction:
                    matchingFuncNames ~= grGetPrettyFunction(av.tempFunc.name,
                        av.tempFunc.inSignature, av.tempFunc.outSignature);
                    break;
                case tempPrimitive:
                    matchingFuncNames ~= grGetPrettyFunction(av.prim.name,
                        av.prim.inSignature, av.prim.outSignature);
                    break;
                }
            }
            string errorNote;
            if (matchingFuncNames.length) {
                foreach (size_t i, const string value; matchingFuncNames) {
                    errorNote ~= "`" ~ value ~ "`";
                    if ((i + 1) < matchingFuncNames.length)
                        errorNote ~= ", ";
                }
                errorNote ~= ".";
            }

            logError(format(getError(Error.callXIsAmbiguous), grGetPrettyFunctionCall(name, signature)),
                getError(Error.callMatchesSeveralInstances),
                format(getError(Error.matchingInstancesAreX), errorNote), -1);
        }
        else if (availableFuncs.length) {
            AvailableFunc bestMatch = availableFuncs[0];
            uint nbOperations;

            final switch (bestMatch.type) with (AvailableFunc.Type) {
            case function_:
                convertSignature(nbOperations, signature, arity,
                    bestMatch.func.inSignature, false, fileId, false);
                result.func = bestMatch.func;
                break;
            case primitive:
                convertSignature(nbOperations, signature, arity,
                    bestMatch.prim.inSignature, false, fileId, false);
                result.prim = bestMatch.prim;
                break;
            case tempFunction:
                GrAnyData anyData = new GrAnyData;
                _data.setAnyData(anyData);

                convertSignature(nbOperations, signature, arity,
                    bestMatch.tempFunc.inSignature, true, fileId, false);

                GrType[] templateSignature;
                for (int i; i < bestMatch.tempFunc.templateVariables.length; ++i) {
                    templateSignature ~= anyData.get(bestMatch.tempFunc.templateVariables[i]);
                }
                GrFunction func = parseTemplatedFunctionDeclaration(bestMatch.tempFunc,
                    templateSignature);
                functionsQueue ~= func;

                functionStack ~= currentFunction;
                currentFunction = func;
                generateFunctionInputs();
                currentFunction = functionStack[$ - 1];
                functionStack.length--;

                result.func = func;
                break;
            case tempPrimitive:
                GrAnyData anyData = new GrAnyData;
                _data.setAnyData(anyData);

                convertSignature(nbOperations, signature, arity,
                    bestMatch.prim.inSignature, true, fileId, false);

                result.prim = _data.reifyPrimitive(bestMatch.prim);
                break;
            }
        }
        return result;
    }

    GrFunction getFunction(string name, GrType[] signature, size_t fileId = 0, bool isExport = false) {
        const string mangledName = grMangleComposite(name, signature);

        foreach (GrFunction func; events) {
            if (func.mangledName == mangledName) {
                return func;
            }
        }

        foreach (GrFunction func; functions) {
            if (func.mangledName == mangledName && (func.fileId == fileId ||
                    func.isExport || isExport)) {
                return func;
            }
        }
        foreach (GrFunction func; functions) {
            if (func.name == name && (func.fileId == fileId || func.isExport || isExport)) {
                if (_data.isSignatureCompatible(signature, func.inSignature,
                        false, fileId, isExport))
                    return func;
            }
        }
        foreach (GrFunction func; functionsQueue) {
            if (func.mangledName == mangledName && (func.fileId == fileId ||
                    func.isExport || isExport)) {
                return func;
            }
        }
        foreach (GrFunction func; functionsQueue) {
            if (func.name == name && (func.fileId == fileId || func.isExport || isExport)) {
                if (_data.isSignatureCompatible(signature, func.inSignature,
                        false, fileId, isExport))
                    return func;
            }
        }

        __functionLoop: foreach (GrTemplateFunction temp; templatedFunctions) {
            if (temp.name == name && (temp.fileId == fileId || temp.isExport || isExport)) {
                GrAnyData anyData = new GrAnyData;
                _data.setAnyData(anyData);
                if (_data.isSignatureCompatible(signature, temp.inSignature,
                        true, fileId, isExport)) {
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

    GrFunction getAnonymousFunction(string name, GrType[] signature, size_t fileId) {
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
    private GrVariable getVariable(string name, size_t fileId) {
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

    private void addUIntConstant(GrUInt value) {
        addInstruction(GrOpcode.const_uint, registerUIntConstant(value));
    }

    private void addByteConstant(GrByte value) {
        addInstruction(GrOpcode.const_byte, registerByteConstant(value));
    }

    private void addFloatConstant(GrFloat value) {
        addInstruction(GrOpcode.const_float, registerFloatConstant(value));
    }

    private void addDoubleConstant(GrDouble value) {
        addInstruction(GrOpcode.const_double, registerDoubleConstant(value));
    }

    private void addBoolConstant(bool value) {
        addInstruction(GrOpcode.const_bool, value);
    }

    private void addStringConstant(string value) {
        addInstruction(GrOpcode.const_string, registerStringConstant(value));
    }

    private void addInstruction(GrOpcode opcode, int value = 0, bool isSigned = false) {
        enforce!GrCompilerException(currentFunction,
            "the expression is located outside of a function, task, or event which is forbidden");

        GrInstruction instruction;
        instruction.opcode = opcode;
        if (isSigned) {
            enforce!GrCompilerException((value < 0x800000) && (-value < 0x800000),
                "an opcode's signed value is exceeding limits");
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
        enforce!GrCompilerException(currentFunction,
            "the expression is located outside of a function, task or event which is forbidden");

        GrInstruction instruction;
        instruction.opcode = opcode;
        if (isSigned) {
            enforce!GrCompilerException((value < 0x800000) && (-value < 0x800000),
                "an opcode's signed value is exceeding limits");
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
        symbol.line = lex.line;
        symbol.column = lex.column;
        currentFunction.debugSymbol ~= symbol;
    }

    private void setInstruction(GrOpcode opcode, uint index, int value = 0u, bool isSigned = false) {
        enforce!GrCompilerException(currentFunction,
            "the expression is located outside of a function, task or event which is forbidden");

        enforce!GrCompilerException(index < currentFunction.instructions.length,
            "an instruction's index is exeeding the function size");

        GrInstruction instruction;
        instruction.opcode = opcode;
        if (isSigned) {
            enforce!GrCompilerException((value < 0x800000) && (-value < 0x800000),
                "an opcode's signed value is exceeding limits");
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
        GrType leftType, GrType rightType, size_t fileId) {
        string name = "@operator_" ~ getPrettyLexemeType(lexType);
        GrType[] signature = [leftType, rightType];

        // primitive
        auto matching = getFirstMatchingFuncOrPrim(name, signature, fileId);
        if (matching.prim) {
            addInstruction(_options & GrOption.safe ? GrOpcode.safePrimitiveCall
                    : GrOpcode.primitiveCall, matching.prim.index);
            if (matching.prim.outSignature.length != 1uL) {
                logError(getError(Error.opMustHave1RetVal), format(getError(matching.prim.outSignature.length > 1 ?
                        Error.expected1RetValFoundXs : Error.expected1RetValFoundX),
                        matching.prim.outSignature.length));
            }
            return matching.prim.outSignature[0];
        }

        // fonction
        if (matching.func) {
            auto outSignature = addFunctionCall(matching.func, fileId);
            if (outSignature.length != 1uL) {
                logError(getError(Error.opMustHave1RetVal), format(getError(matching.func.outSignature.length > 1 ?
                        Error.expected1RetValFoundXs : Error.expected1RetValFoundX),
                        matching.func.outSignature.length));
            }
            return outSignature[0];
        }

        return grVoid;
    }

    private GrType addCustomUnaryOperator(GrLexeme.Type lexType, const GrType type, size_t fileId) {
        string name = "@operator_" ~ getPrettyLexemeType(lexType);
        GrType[] signature = [type];

        // primitive
        auto matching = getFirstMatchingFuncOrPrim(name, signature, fileId);
        if (matching.prim) {
            addInstruction(_options & GrOption.safe ? GrOpcode.safePrimitiveCall
                    : GrOpcode.primitiveCall, matching.prim.index);
            if (matching.prim.outSignature.length != 1uL) {
                logError(getError(Error.opMustHave1RetVal), format(getError(matching.prim.outSignature.length > 1 ?
                        Error.expected1RetValFoundXs : Error.expected1RetValFoundX),
                        matching.prim.outSignature.length));
            }
            return matching.prim.outSignature[0];
        }

        // fonction
        if (matching.func) {
            auto outSignature = addFunctionCall(matching.func, fileId);
            if (outSignature.length != 1uL) {
                logError(getError(Error.opMustHave1RetVal), format(getError(matching.func.outSignature.length > 1 ?
                        Error.expected1RetValFoundXs : Error.expected1RetValFoundX),
                        matching.func.outSignature.length));
            }
            return outSignature[0];
        }

        return grVoid;
    }

    private GrType addBinaryOperator(GrLexeme.Type lexType, GrType leftType,
        GrType rightType, size_t fileId) {
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
            addInstruction(GrOpcode.swap, 1);
            convertType(leftType, rightType, fileId);
            resultType = addInternalOperator(lexType, rightType, true);
        }
        else if (leftType.isFloating && rightType.isIntegral) {
            // On converti l’entier en flottant
            convertType(rightType, leftType, fileId);
            resultType = addInternalOperator(lexType, leftType);

            // Puis on cherche un opérateur surchargé
            if (resultType.base == GrType.Base.void_) {
                resultType = addCustomBinaryOperator(lexType, rightType, rightType, fileId);
            }
        }
        else if (leftType.isIntegral && rightType.isFloating) {
            // Cas particulier: on a besoin de convertir l’entier en flottant
            // et d’inverser les deux valeurs
            addInstruction(GrOpcode.swap, 1);
            convertType(leftType, rightType, fileId);
            resultType = addInternalOperator(lexType, rightType, true);

            // Puis on cherche un opérateur surchargé
            if (resultType.base == GrType.Base.void_) {
                resultType = addCustomBinaryOperator(lexType, rightType, rightType, fileId);
            }
        }
        else if (leftType != rightType) {
            if (leftType.isNumeric && rightType.isNumeric) {
                if (leftType.numericPriority > rightType.numericPriority) {
                    convertType(rightType, leftType, fileId);
                    resultType = addInternalOperator(lexType, leftType);
                }
                else {
                    addInstruction(GrOpcode.swap, 1);
                    convertType(leftType, rightType, fileId);
                    resultType = addInternalOperator(lexType, rightType, true);
                }
            }

            // On cherche un opérateur surchargé
            if (resultType.base == GrType.Base.void_) {
                resultType = addCustomBinaryOperator(lexType, leftType, rightType, fileId);
            }

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

    private GrType addUnaryOperator(GrLexeme.Type lexType, const GrType type, size_t fileId) {
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

    private GrType addOperator(GrLexeme.Type lexType, ref GrType[] typeStack, size_t fileId) {
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
                if (isSwapped)
                    addInstruction(GrOpcode.lesserOrEqual_int);
                else
                    addInstruction(GrOpcode.greater_int);
                return GrType(GrType.Base.bool_);
            case greaterOrEqual:
                if (isSwapped)
                    addInstruction(GrOpcode.lesser_int);
                else
                    addInstruction(GrOpcode.greaterOrEqual_int);
                return GrType(GrType.Base.bool_);
            case lesser:
                if (isSwapped)
                    addInstruction(GrOpcode.greaterOrEqual_int);
                else
                    addInstruction(GrOpcode.lesser_int);
                return GrType(GrType.Base.bool_);
            case lesserOrEqual:
                if (isSwapped)
                    addInstruction(GrOpcode.greater_int);
                else
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
                if (isSwapped)
                    addInstruction(GrOpcode.swap, 1);
                addInstruction(GrOpcode.substract_int);
                return GrType(GrType.Base.int_);
            case multiply:
                addInstruction(GrOpcode.multiply_int);
                return GrType(GrType.Base.int_);
            case divide:
                if (isSwapped)
                    addInstruction(GrOpcode.swap, 1);
                addInstruction(GrOpcode.divide_int);
                return GrType(GrType.Base.int_);
            case remainder:
                if (isSwapped)
                    addInstruction(GrOpcode.swap, 1);
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
                if (isSwapped)
                    addInstruction(GrOpcode.lesserOrEqual_int);
                else
                    addInstruction(GrOpcode.greater_int);
                return GrType(GrType.Base.bool_);
            case greaterOrEqual:
                if (isSwapped)
                    addInstruction(GrOpcode.lesser_int);
                else
                    addInstruction(GrOpcode.greaterOrEqual_int);
                return GrType(GrType.Base.bool_);
            case lesser:
                if (isSwapped)
                    addInstruction(GrOpcode.greaterOrEqual_int);
                else
                    addInstruction(GrOpcode.lesser_int);
                return GrType(GrType.Base.bool_);
            case lesserOrEqual:
                if (isSwapped)
                    addInstruction(GrOpcode.greater_int);
                else
                    addInstruction(GrOpcode.lesserOrEqual_int);
                return GrType(GrType.Base.bool_);
            case not:
                addInstruction(GrOpcode.not_int);
                return GrType(GrType.Base.bool_);
            default:
                break;
            }
            break;
        case uint_:
            switch (lexType) with (GrLexeme.Type) {
            case add:
                addInstruction(GrOpcode.add_uint);
                return GrType(GrType.Base.uint_);
            case substract:
                if (isSwapped)
                    addInstruction(GrOpcode.swap, 1);
                addInstruction(GrOpcode.substract_uint);
                return GrType(GrType.Base.uint_);
            case multiply:
                addInstruction(GrOpcode.multiply_uint);
                return GrType(GrType.Base.uint_);
            case divide:
                if (isSwapped)
                    addInstruction(GrOpcode.swap, 1);
                addInstruction(GrOpcode.divide_uint);
                return GrType(GrType.Base.uint_);
            case remainder:
                if (isSwapped)
                    addInstruction(GrOpcode.swap, 1);
                addInstruction(GrOpcode.remainder_uint);
                return GrType(GrType.Base.uint_);
            case plus:
                return GrType(GrType.Base.uint_);
            case increment:
                addInstruction(GrOpcode.increment_uint);
                return GrType(GrType.Base.uint_);
            case decrement:
                addInstruction(GrOpcode.decrement_uint);
                return GrType(GrType.Base.uint_);
            case equal:
                addInstruction(GrOpcode.equal_uint);
                return GrType(GrType.Base.bool_);
            case notEqual:
                addInstruction(GrOpcode.notEqual_uint);
                return GrType(GrType.Base.bool_);
            case greater:
                if (isSwapped)
                    addInstruction(GrOpcode.lesserOrEqual_uint);
                else
                    addInstruction(GrOpcode.greater_uint);
                return GrType(GrType.Base.bool_);
            case greaterOrEqual:
                if (isSwapped)
                    addInstruction(GrOpcode.lesser_uint);
                else
                    addInstruction(GrOpcode.greaterOrEqual_uint);
                return GrType(GrType.Base.bool_);
            case lesser:
                if (isSwapped)
                    addInstruction(GrOpcode.greaterOrEqual_uint);
                else
                    addInstruction(GrOpcode.lesser_uint);
                return GrType(GrType.Base.bool_);
            case lesserOrEqual:
                if (isSwapped)
                    addInstruction(GrOpcode.greater_uint);
                else
                    addInstruction(GrOpcode.lesserOrEqual_uint);
                return GrType(GrType.Base.bool_);
            default:
                break;
            }
            break;
        case char_:
            switch (lexType) with (GrLexeme.Type) {
            case equal:
                addInstruction(GrOpcode.equal_uint);
                return GrType(GrType.Base.bool_);
            case notEqual:
                addInstruction(GrOpcode.notEqual_uint);
                return GrType(GrType.Base.bool_);
            default:
                break;
            }
            break;
        case byte_:
            switch (lexType) with (GrLexeme.Type) {
            case add:
                addInstruction(GrOpcode.add_byte);
                return GrType(GrType.Base.byte_);
            case substract:
                if (isSwapped)
                    addInstruction(GrOpcode.swap, 1);
                addInstruction(GrOpcode.substract_byte);
                return GrType(GrType.Base.byte_);
            case multiply:
                addInstruction(GrOpcode.multiply_byte);
                return GrType(GrType.Base.byte_);
            case divide:
                if (isSwapped)
                    addInstruction(GrOpcode.swap, 1);
                addInstruction(GrOpcode.divide_byte);
                return GrType(GrType.Base.byte_);
            case remainder:
                if (isSwapped)
                    addInstruction(GrOpcode.swap, 1);
                addInstruction(GrOpcode.remainder_byte);
                return GrType(GrType.Base.byte_);
            case plus:
                return GrType(GrType.Base.byte_);
            case increment:
                addInstruction(GrOpcode.increment_byte);
                return GrType(GrType.Base.byte_);
            case decrement:
                addInstruction(GrOpcode.decrement_byte);
                return GrType(GrType.Base.byte_);
            case equal:
                addInstruction(GrOpcode.equal_byte);
                return GrType(GrType.Base.bool_);
            case notEqual:
                addInstruction(GrOpcode.notEqual_byte);
                return GrType(GrType.Base.bool_);
            case greater:
                if (isSwapped)
                    addInstruction(GrOpcode.lesserOrEqual_byte);
                else
                    addInstruction(GrOpcode.greater_byte);
                return GrType(GrType.Base.bool_);
            case greaterOrEqual:
                if (isSwapped)
                    addInstruction(GrOpcode.lesser_byte);
                else
                    addInstruction(GrOpcode.greaterOrEqual_byte);
                return GrType(GrType.Base.bool_);
            case lesser:
                if (isSwapped)
                    addInstruction(GrOpcode.greaterOrEqual_byte);
                else
                    addInstruction(GrOpcode.lesser_byte);
                return GrType(GrType.Base.bool_);
            case lesserOrEqual:
                if (isSwapped)
                    addInstruction(GrOpcode.greater_byte);
                else
                    addInstruction(GrOpcode.lesserOrEqual_byte);
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
                    addInstruction(GrOpcode.swap, 1);
                addInstruction(GrOpcode.substract_float);
                return GrType(GrType.Base.float_);
            case multiply:
                addInstruction(GrOpcode.multiply_float);
                return GrType(GrType.Base.float_);
            case divide:
                if (isSwapped)
                    addInstruction(GrOpcode.swap, 1);
                addInstruction(GrOpcode.divide_float);
                return GrType(GrType.Base.float_);
            case remainder:
                if (isSwapped)
                    addInstruction(GrOpcode.swap, 1);
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
        case double_:
            switch (lexType) with (GrLexeme.Type) {
            case add:
                addInstruction(GrOpcode.add_double);
                return GrType(GrType.Base.double_);
            case substract:
                if (isSwapped)
                    addInstruction(GrOpcode.swap, 1);
                addInstruction(GrOpcode.substract_double);
                return GrType(GrType.Base.double_);
            case multiply:
                addInstruction(GrOpcode.multiply_double);
                return GrType(GrType.Base.double_);
            case divide:
                if (isSwapped)
                    addInstruction(GrOpcode.swap, 1);
                addInstruction(GrOpcode.divide_double);
                return GrType(GrType.Base.double_);
            case remainder:
                if (isSwapped)
                    addInstruction(GrOpcode.swap, 1);
                addInstruction(GrOpcode.remainder_double);
                return GrType(GrType.Base.double_);
            case minus:
                addInstruction(GrOpcode.negative_double);
                return GrType(GrType.Base.double_);
            case plus:
                return GrType(GrType.Base.double_);
            case increment:
                addInstruction(GrOpcode.increment_double);
                return GrType(GrType.Base.double_);
            case decrement:
                addInstruction(GrOpcode.decrement_double);
                return GrType(GrType.Base.double_);
            case equal:
                addInstruction(GrOpcode.equal_double);
                return GrType(GrType.Base.bool_);
            case notEqual:
                addInstruction(GrOpcode.notEqual_double);
                return GrType(GrType.Base.bool_);
            case greater:
                if (isSwapped)
                    addInstruction(GrOpcode.lesserOrEqual_double);
                else
                    addInstruction(GrOpcode.greater_double);
                return GrType(GrType.Base.bool_);
            case greaterOrEqual:
                if (isSwapped)
                    addInstruction(GrOpcode.lesser_double);
                else
                    addInstruction(GrOpcode.greaterOrEqual_double);
                return GrType(GrType.Base.bool_);
            case lesser:
                if (isSwapped)
                    addInstruction(GrOpcode.greaterOrEqual_double);
                else
                    addInstruction(GrOpcode.lesser_double);
                return GrType(GrType.Base.bool_);
            case lesserOrEqual:
                if (isSwapped)
                    addInstruction(GrOpcode.greater_double);
                else
                    addInstruction(GrOpcode.lesserOrEqual_double);
                return GrType(GrType.Base.bool_);
            default:
                break;
            }
            break;
        case string_:
            switch (lexType) with (GrLexeme.Type) {
            case concatenate:
                if (isSwapped)
                    addInstruction(GrOpcode.swap, 1);
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

    private void addSetInstruction(GrVariable variable, size_t fileId,
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

            if (valueType.isInternal) {
                logError(format(getError(Error.cantAssignToAXVar),
                        getPrettyType(variable.type)), getError(Error.ValNotAssignable));
            }

            addInstruction(isExpectingValue ? GrOpcode.refStore2 : GrOpcode.refStore);
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
            if (!variable.type.isValid) {
                logError(format(getError(Error.cantAssignToAXVar),
                        getPrettyType(variable.type)), getError(Error.ValNotAssignable));
            }

            addInstruction(GrOpcode.fieldRefStore, (isExpectingValue ||
                    variable.isOptional) ? 0 : -1, true);
        }
        else if (variable.isGlobal) {
            if (variable.type.isInternal) {
                logError(format(getError(Error.cantAssignToAXVar),
                        getPrettyType(variable.type)), getError(Error.ValNotAssignable));
            }

            addInstruction(isExpectingValue ? GrOpcode.globalStore2
                    : GrOpcode.globalStore, variable.register);
        }
        else {
            if (variable.type.isInternal) {
                logError(format(getError(Error.cantAssignToAXVar),
                        getPrettyType(variable.type)), getError(Error.ValNotAssignable));
            }

            addInstruction(isExpectingValue ? GrOpcode.localStore2
                    : GrOpcode.localStore, variable.register);
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

        enforce!GrCompilerException(!variable.isField, "attempt to get field value");

        if (variable.isGlobal) {
            if (variable.type.isInternal) {
                logError(format(getError(Error.cantGetValueOfX),
                        getPrettyType(variable.type)), getError(Error.valNotFetchable));
            }

            if (allowOptimization && currentFunction.instructions.length &&
                currentFunction.instructions[$ - 1].opcode == GrOpcode.globalStore &&
                currentFunction.instructions[$ - 1].value == variable.register)
                currentFunction.instructions[$ - 1].opcode = GrOpcode.globalStore2;
            else
                addInstruction(GrOpcode.globalLoad, variable.register);
        }
        else {
            if (!variable.isInitialized)
                logError(getError(Error.locVarUsedNotAssigned), getError(Error.varNotInit));

            if (variable.type.isInternal) {
                logError(format(getError(Error.cantGetValueOfX),
                        getPrettyType(variable.type)), getError(Error.valNotFetchable));
            }

            if (allowOptimization && currentFunction.instructions.length &&
                currentFunction.instructions[$ - 1].opcode == GrOpcode.localStore &&
                currentFunction.instructions[$ - 1].value == variable.register)
                currentFunction.instructions[$ - 1].opcode = GrOpcode.localStore2;
            else
                addInstruction(GrOpcode.localLoad, variable.register);
        }
    }

    private GrType addFunctionAddress(string name, GrType[] signature, size_t fileId) {
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
            addInstruction(GrOpcode.address, 0u);

            return grGetFunctionAsType(func);
        }
        return grVoid;
    }

    private GrType addFunctionAddress(GrFunction func, size_t fileId) {
        if (func.name == "@global")
            return grVoid;
        GrFunctionCall call = new GrFunctionCall;
        call.caller = currentFunction;
        functionCalls ~= call;
        currentFunction.functionCalls ~= call;
        call.isAddress = true;
        call.functionToCall = func;
        call.position = cast(uint) currentFunction.instructions.length;
        addInstruction(GrOpcode.address, 0u);
        return grGetFunctionAsType(func);
    }

    private GrType[] addFunctionCall(string name, GrType[] signature, size_t fileId) {
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

            call.position = cast(uint) currentFunction.instructions.length;
            addInstruction(GrOpcode.call, 0);

            if (func.isTask) {
                addInstruction(GrOpcode.extend, func.nbParameters);
            }
            return func.outSignature;
        }
        else
            logError(format(getError(Error.xNotDecl), getPrettyFunctionCall(name,
                    signature)), getError(Error.unknownFunc), "", -1);

        return [];
    }

    private GrType[] addFunctionCall(GrFunction func, size_t fileId) {
        GrFunctionCall call = new GrFunctionCall;
        call.name = func.name;
        call.signature = func.inSignature;
        call.caller = currentFunction;
        functionCalls ~= call;
        currentFunction.functionCalls ~= call;
        call.isAddress = false;
        call.fileId = fileId;

        call.functionToCall = func;

        call.position = cast(uint) currentFunction.instructions.length;
        addInstruction(GrOpcode.call, 0);

        if (func.isTask) {
            addInstruction(GrOpcode.extend, func.nbParameters);
        }
        return func.outSignature;
    }

    private void setOpcode(ref uint[] opcodes, uint position, GrOpcode opcode,
        uint value = 0u, bool isSigned = false) {
        GrInstruction instruction;
        instruction.opcode = opcode;
        if (isSigned) {
            enforce!GrCompilerException((value < 0x800000) && (-value < 0x800000),
                "an opcode's signed value is exceeding limits");
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
                    setOpcode(opcodes, call.position, GrOpcode.address,
                        registerUIntConstant(func.position));
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
                GrOpcode.closure, registerUIntConstant(func.position));
    }

    package void dump() {
        writeln("Code Generated:\n");
        foreach (size_t i, GrInt intValue; intConsts)
            writeln(".intConst " ~ to!string(intValue) ~ "\t;" ~ to!string(i));

        foreach (size_t i, GrUInt uintValue; uintConsts)
            writeln(".uintConst " ~ to!string(uintValue) ~ "\t;" ~ to!string(i));

        foreach (size_t i, GrByte byteValue; byteConsts)
            writeln(".byteConst " ~ to!string(byteValue) ~ "\t;" ~ to!string(i));

        foreach (size_t i, GrFloat floatValue; floatConsts)
            writeln(".floatConst " ~ to!string(floatValue) ~ "\t;" ~ to!string(i));

        foreach (size_t i, GrDouble doubleValue; doubleConsts)
            writeln(".doubleConst " ~ to!string(doubleValue) ~ "\t;" ~ to!string(i));

        foreach (size_t i, string strValue; strConsts)
            writeln(".strConst " ~ strValue ~ "\t;" ~ to!string(i));

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

        bool isExport;
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
            isExport = false;
            if (lex.type == GrLexeme.Type.export_) {
                isExport = true;
                checkAdvance();
                lex = get();
            }
            switch (lex.type) with (GrLexeme.Type) {
            case semicolon:
                checkAdvance();
                break;
            case class_:
                registerClassDeclaration(isExport);
                break;
            case enum_:
                parseEnumDeclaration(isExport);
                break;
            case event:
            case task:
            case func:
                skipDeclaration();
                break;
            case nothing:
                checkAdvance();
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
            isExport = false;
            if (lex.type == GrLexeme.Type.export_) {
                isExport = true;
                checkAdvance();
                lex = get();
            }
            switch (lex.type) with (GrLexeme.Type) {
            case semicolon:
                checkAdvance();
                break;
            case alias_:
                parseTypeAliasDeclaration(isExport);
                break;
            case event:
            case task:
            case func:
            case class_:
            case enum_:
                skipDeclaration();
                break;
            case nothing:
                checkAdvance();
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
            isExport = false;
            if (lex.type == GrLexeme.Type.export_) {
                isExport = true;
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
                parseEventDeclaration(isExport);
                break;
            case task:
                if (get(1).type != GrLexeme.Type.identifier && get(1).type != GrLexeme.Type.lesser)
                    goto case intType;
                parseTaskDeclaration(isExport);
                break;
            case func:
                if (get(1).type != GrLexeme.Type.identifier && !get(1)
                    .isOperator && get(1).type != GrLexeme.Type.as && get(1)
                    .type != GrLexeme.Type.lesser)
                    goto case intType;
                parseFunctionDeclaration(isExport);
                break;
            case intType: .. case channelType:
            case var:
            case const_:
            case pure_:
            case identifier:
            case alias_:
                skipExpression();
                break;
            case nothing:
                checkAdvance();
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
            isExport = false;
            if (lex.type == GrLexeme.Type.export_) {
                isExport = true;
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
                parseVariableDeclaration(false, true, isExport);
                break;
            case const_:
                parseVariableDeclaration(true, true, isExport);
                break;
            case alias_:
                skipExpression();
                break;
            case nothing:
                checkAdvance();
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
                func.templateSignature[i], func.fileId, func.isExport);
        }
        current = func.lexPosition;
        parseWhereStatement(func.templateVariables);
        openDeferrableSection();
        parseBlock(false, false, true);
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
    private void parseTypeAliasDeclaration(bool isExport) {
        const size_t fileId = get().fileId;
        checkAdvance();

        if (get().type != GrLexeme.Type.identifier)
            logError(format(getError(Error.expectedTypeAliasNameFoundX),
                    getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));
        const string typeAliasName = get().strValue;
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

        if (_data.isTypeDeclared(typeAliasName, fileId, isExport))
            logError(format(getError(Error.nameXDefMultipleTimes),
                    typeAliasName), format(getError(Error.alreadyDef), typeAliasName));
        _data.addAlias(typeAliasName, type, fileId, isExport);
    }

    /// Analyse la déclaration d’une énumération
    private void parseEnumDeclaration(bool isExport) {
        const size_t fileId = get().fileId;
        checkAdvance();
        if (get().type != GrLexeme.Type.identifier)
            logError(format(getError(Error.expectedEnumNameFoundX),
                    getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));
        const string enumName = get().strValue;
        checkAdvance();
        if (get().type != GrLexeme.Type.leftCurlyBrace)
            logError(getError(Error.enumDefNotHaveBody), format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.leftCurlyBrace),
                    getPrettyLexemeType(get().type)));
        checkAdvance();

        string[] fields;
        int[] values;

        int lastValue = -1;
        while (!isEnd()) {
            if (get().type == GrLexeme.Type.rightCurlyBrace) {
                checkAdvance();
                break;
            }
            if (get().type != GrLexeme.Type.identifier)
                logError(format(getError(Error.expectedEnumFieldFoundX),
                        getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));

            auto fieldName = get().strValue;
            checkAdvance();
            fields ~= fieldName;

            if (get().type == GrLexeme.Type.assign) {
                checkAdvance();

                bool isNeg;
                if (get().type == GrLexeme.Type.substract) {
                    isNeg = true;
                    checkAdvance();
                }

                if (get().type != GrLexeme.Type.int_) {
                    logError(getError(Error.missingEnumConstantValue),
                        format(getError(Error.expectedIntFoundX), getPrettyLexemeType(get().type)));
                }

                lastValue = get().intValue;
                if (isNeg)
                    lastValue = -lastValue;

                checkAdvance();
            }
            else {
                lastValue++;
            }

            values ~= lastValue;

            if (get().type != GrLexeme.Type.semicolon)
                logError(getError(Error.missingSemicolonAfterEnumField), format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.semicolon),
                        getPrettyLexemeType(get().type)));
            checkAdvance();
        }
        if (_data.isTypeDeclared(enumName, fileId, isExport))
            logError(format(getError(Error.nameXDefMultipleTimes), enumName),
                format(getError(Error.xAlreadyDecl), enumName));
        _data.addEnum(enumName, fields, values, fileId, isExport);
    }

    /// Déclare une nouvelle classe sans l’analyser
    private void registerClassDeclaration(bool isExport) {
        const size_t fileId = get().fileId;

        checkAdvance();
        if (get().type != GrLexeme.Type.identifier)
            logError(format(getError(Error.expectedClassNameFoundX),
                    getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));

        const string className = get().strValue;
        checkAdvance();

        if (_data.isTypeDeclared(className, fileId, isExport))
            logError(format(getError(Error.nameXDefMultipleTimes), className),
                format(getError(Error.xAlreadyDecl), className));

        string[] templateVariables = parseTemplateVariables();
        const uint declPosition = current;

        _data.registerClass(className, fileId, isExport, templateVariables, declPosition);

        skipDeclaration();
    }

    /// Récupère une classe. \
    /// Réifie la classe si besoin.
    private GrClassDefinition getClass(string mangledType, size_t fileId) {
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
                class_.templateTypes[i], class_.fileId, class_.isExport);
        }

        uint[] fieldPositions;
        string parentClassName;

        // Héritage
        if (get().type == GrLexeme.Type.colon) {
            checkAdvance();
            if (get().type != GrLexeme.Type.identifier)
                logError(getError(Error.parentClassNameMissing),
                    format(getError(Error.expectedClassNameFoundX), getPrettyLexemeType(get().type)));
            parentClassName = get().strValue;
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
            if (get().type == GrLexeme.Type.export_) {
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

                const string fieldName = get().strValue;
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
            class_.fieldsInfo[i].isExport = fieldScopes[i];
            class_.fieldsInfo[i].position = fieldPositions[i];
        }
        current = tempPos;
        _data.clearTemplateAliases();
        resolveClassInheritence(class_);
    }

    /// Récupère les champs et la signature de la classe mère
    private void resolveClassInheritence(GrClassDefinition class_) {
        size_t fileId = class_.fileId;
        string parent = class_.parent;
        GrClassDefinition lastClass = class_;
        string[] usedClasses = [class_.name];

        while (parent.length) {
            GrClassDefinition parentClass = getClass(parent, fileId);
            if (!parentClass) {
                GrNativeDefinition parentNative = _data.getNative(parent);

                if (!parentNative) {
                    set(lastClass.position + 1u);
                    logError(format(getError(Error.xCantInheritFromY), getPrettyType(grGetClassType(class_.name)),
                            grUnmangleComposite(parent).name), getError(Error.unknownClass));
                }

                class_.nativeParent = parentNative;
                break;
            }
            for (int i; i < usedClasses.length; ++i) {
                if (parent == usedClasses[i]) {
                    set(lastClass.position + 1u);
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
        if (lex.type == GrLexeme.Type.leftBracket) {
            currentType.base = GrType.Base.list;
            checkAdvance();
            GrType subType = parseType(mustBeType, templateVariables);

            if (get().type != GrLexeme.Type.rightBracket) {
                logError(format(getError(Error.missingXInListSignature),
                        getPrettyLexemeType(GrLexeme.Type.rightCurlyBrace)),
                    format(getError(Error.expectedXFoundY),
                        getPrettyLexemeType(GrLexeme.Type.rightCurlyBrace),
                        getPrettyLexemeType(get().type)));
            }
            checkAdvance();
            currentType.mangledType = grMangle(subType);
        }
        else if (!lex.isType) {
            if (lex.type == GrLexeme.Type.identifier) {
                foreach (tempVar; templateVariables) {
                    if (tempVar == lex.strValue) {
                        checkAdvance();
                        currentType = grAny(lex.strValue);
                        break;
                    }
                }
            }
            if (!currentType.isAny) {
                if (lex.type == GrLexeme.Type.identifier &&
                    _data.isTypeAlias(lex.strValue, lex.fileId, false)) {
                    currentType = _data.getTypeAlias(lex.strValue, lex.fileId).type;
                    checkAdvance();
                }
                else if (lex.type == GrLexeme.Type.identifier &&
                    _data.isClass(lex.strValue, lex.fileId, false)) {
                    currentType.base = GrType.Base.class_;
                    checkAdvance();
                    currentType.mangledType = grMangleComposite(lex.strValue,
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
                    _data.isEnum(lex.strValue, lex.fileId, false)) {
                    currentType.base = GrType.Base.enum_;
                    currentType.mangledType = lex.strValue;
                    checkAdvance();
                }
                else if (lex.type == GrLexeme.Type.identifier && _data.isNative(lex.strValue)) {
                    currentType.base = GrType.Base.native;
                    currentType.mangledType = lex.strValue;
                    checkAdvance();
                    currentType.mangledType = grMangleComposite(lex.strValue,
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
                        lex.strValue : getPrettyLexemeType(lex.type);
                    logError(format(getError(Error.xNotValidType), typeName),
                        format(getError(Error.expectedValidTypeFoundX), typeName));
                }
            }
        }
        else {
            switch (lex.type) with (GrLexeme.Type) {
            case intType:
                currentType.base = GrType.Base.int_;
                checkAdvance();
                break;
            case uintType:
                currentType.base = GrType.Base.uint_;
                checkAdvance();
                break;
            case byteType:
                currentType.base = GrType.Base.byte_;
                checkAdvance();
                break;
            case charType:
                currentType.base = GrType.Base.char_;
                checkAdvance();
                break;
            case floatType:
                currentType.base = GrType.Base.float_;
                checkAdvance();
                break;
            case doubleType:
                currentType.base = GrType.Base.double_;
                checkAdvance();
                break;
            case boolType:
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
            case instance:
                currentType.base = GrType.Base.instance;
                checkAdvance();
                break;
            case channelType:
                currentType.base = GrType.Base.channel;
                checkAdvance();
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
        if (!type.isValid) {
            logError(format(getError(Error.xNotValidType), getPrettyType(type)),
                format(getError(Error.expectedIdentifierFoundX), getPrettyLexemeType(get().type)));
        }

        addInstruction(GrOpcode.globalPop, 0u);
    }

    private void addGlobalPush(GrType type, int nbPush = 1u) {
        if (nbPush == 0)
            return;

        if (!type.isValid) {
            logError(format(getError(Error.xNotValidType), getPrettyType(type)),
                format(getError(Error.expectedIdentifierFoundX), getPrettyLexemeType(get().type)));
        }

        addInstruction(GrOpcode.globalPush, nbPush);
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
            variables ~= get().strValue;
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
            return [];

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
            inputVariables ~= lex.strValue;
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

    private void parseEventDeclaration(bool isExport) {
        if (isExport)
            logError(getError(Error.addingExportBeforeEventIsRedundant),
                getError(Error.eventAlreadyExported));
        checkAdvance();
        if (get().type != GrLexeme.Type.identifier)
            logError(format(getError(Error.expectedIdentifierFoundX),
                    getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));
        string name = get().strValue;
        uint nameLexPosition = current;
        string[] inputs;
        checkAdvance();
        GrType[] signature = parseInSignature(inputs);
        preBeginFunction(name, nameLexPosition, get().fileId, signature,
            inputs, false, [], false, true, true);
        skipBlock(true);
        preEndFunction();
    }

    private void parseTaskDeclaration(bool isExport) {
        checkAdvance();
        string[] templateVariables = parseTemplateVariables();
        if (get().type != GrLexeme.Type.identifier)
            logError(format(getError(Error.expectedIdentifierFoundX),
                    getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));

        string name = get().strValue;
        uint nameLexPosition = current;
        checkAdvance();

        GrTemplateFunction temp = new GrTemplateFunction;
        temp.isTask = true;
        temp.name = name;
        temp.templateVariables = templateVariables;
        temp.fileId = get().fileId;
        temp.isExport = isExport;
        temp.nameLexPosition = nameLexPosition;
        temp.lexPosition = current;

        string[] inputs;
        temp.inSignature = parseInSignature(inputs, templateVariables);
        temp.constraints = parseWhereStatement(templateVariables);
        templatedFunctions ~= temp;
        skipBlock(true);
    }

    private void parseFunctionDeclaration(bool isExport) {
        checkAdvance();
        string[] templateVariables = parseTemplateVariables();
        string name;
        bool isConversion, isOperator;
        GrType staticType;
        uint lexPosition;
        uint nameLexPosition = current;

        if (get().type == GrLexeme.Type.as) {
            checkAdvance();
            name = "@as";
            isConversion = true;
        }
        else if (get().type == GrLexeme.Type.at) {
            checkAdvance();
            nameLexPosition = current;
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

                nameLexPosition = current;
                name ~= "." ~ get().strValue;
                checkAdvance();
            }
        }
        else if (get().type == GrLexeme.Type.identifier) {
            if (get().strValue == "operator") {
                advance();
                if (get().type == GrLexeme.Type.string_) {
                    lexPosition = current;
                    if (!isOverridableOperator(get().strValue)) {
                        logError(format(getError(Error.cantOverrideXOp), get()
                                .strValue), getError(Error.opCantBeOverriden));
                    }
                    name = get().strValue;
                    isOperator = true;
                    checkAdvance();
                }
                else {
                    logError(format(getError(Error.expectedXFoundY), getPrettyLexemeType(GrLexeme.Type.string_),
                            getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));
                }
            }
            else {
                name = get().strValue;
                checkAdvance();
            }
        }
        else {
            logError(format(getError(Error.expectedIdentifierFoundX),
                    getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));
        }

        GrTemplateFunction temp = new GrTemplateFunction;
        temp.isTask = false;
        temp.isConversion = isConversion;
        temp.templateVariables = templateVariables;
        temp.fileId = get().fileId;
        temp.isExport = isExport;
        temp.nameLexPosition = nameLexPosition;
        temp.lexPosition = current;

        string[] inputs;
        temp.inSignature = parseInSignature(inputs, templateVariables);
        temp.outSignature = parseSignature(templateVariables);

        if (isOperator) {
            if (temp.inSignature.length == 0 || temp.inSignature.length > 2) {
                logError(getError(Error.opMustHave1Or2Args),
                    getError(Error.opCantBeOverriden), "", lexPosition - current);
            }

            if (temp.outSignature.length != 1) {
                logError(getError(Error.opMustHave1RetVal), format(getError(temp.outSignature.length > 1 ?
                        Error.expected1RetValFoundXs : Error.expected1RetValFoundX),
                        temp.outSignature.length), "", lexPosition - current);
            }

            if (!isOperatorUnary(name) && temp.inSignature.length == 1) {
                logError(format(getError(Error.xNotUnaryOp), name),
                    getError(Error.opCantBeOverriden), "", lexPosition - current);
            }

            if (!isOperatorBinary(name) && temp.inSignature.length == 2) {
                logError(format(getError(Error.xNotBinaryOp), name),
                    getError(Error.opCantBeOverriden), "", lexPosition - current);
            }

            name = "@operator_" ~ name;
        }

        if (isConversion)
            temp.inSignature ~= temp.outSignature;
        else if (staticType.base != GrType.Base.void_)
            temp.inSignature ~= staticType;

        temp.name = name;
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

            GrConstraint.Data constraintData = _data.getConstraintData(get().strValue);
            if (!constraintData) {
                const string[] nearestValues = findNearestStrings(get()
                        .strValue, _data.getAllConstraintsName());
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
                        get().strValue), format(getError(Error.validConstraintsAreX), errorNote));
            }
            checkAdvance();
            GrType[] parameters = parseTemplateSignature(templateVariables);
            constraints ~= GrConstraint(constraintData.predicate,
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
                temp.fileId, temp.isExport);
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
        else {
            outSignature = [grInstance];
        }

        GrFunction func = new GrFunction;
        func.isTask = temp.isTask;
        func.name = temp.name;
        func.inputVariables = inputs;
        func.inSignature = inSignature;
        func.outSignature = outSignature;
        func.fileId = temp.fileId;
        func.isExport = temp.isExport;
        func.nameLexPosition = temp.nameLexPosition;
        func.lexPosition = current;
        func.templateVariables = temp.templateVariables;
        func.templateSignature = templateList;

        _data.clearTemplateAliases();
        current = lastPosition;
        return func;
    }

    private GrType parseAnonymousFunction(bool isTask, bool isEvent) {
        uint nameLexPosition = current;
        checkAdvance();

        string[] inputs;
        GrType[] outSignature;
        GrType[] inSignature = parseInSignature(inputs);

        if (!isTask && !isEvent) {
            // Type de retour
            outSignature = parseSignature();
        }
        else {
            outSignature = [grInstance];
        }
        preBeginFunction("$anon", nameLexPosition, get().fileId, inSignature,
            inputs, isTask, outSignature, true, isEvent);
        openDeferrableSection();
        parseBlock(false);

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
    private void parseBlock(bool createScope = true,
        bool changeOptimizationBlockLevel = false, bool mustBeMultiline = false) {
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

        if (createScope)
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
                parseExitStatement();
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

        if (createScope)
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
        if (get().type != GrLexeme.Type.semicolon)
            logError(format(getError(Error.missingSemicolonAfterX), getPrettyLexemeType(GrLexeme.Type.die)),
                format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.semicolon), getPrettyLexemeType(get().type)));
        advance();
    }

    private void parseExitStatement() {
        if (!currentFunction.instructions.length ||
            currentFunction.instructions[$ - 1].opcode != GrOpcode.exit)
            addExit();
        advance();
        if (get().type != GrLexeme.Type.semicolon)
            logError(format(getError(Error.missingSemicolonAfterX), getPrettyLexemeType(GrLexeme.Type.exit)),
                format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.semicolon), getPrettyLexemeType(get().type)));
        advance();
    }

    private void parseYieldStatement() {
        addInstruction(GrOpcode.yield, 0u);
        advance();
        if (get().type != GrLexeme.Type.semicolon)
            logError(format(getError(Error.missingSemicolonAfterX), getPrettyLexemeType(GrLexeme.Type.yield)),
                format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.semicolon), getPrettyLexemeType(get().type)));
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

        const size_t fileId = get().fileId;
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
            GrVariable errVariable = registerVariable(get().strValue, grString,
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

            parseBlock(true, true);

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
        enforce!GrCompilerException(currentFunction.deferrableSections.length,
            "attempting to close a non-existing function");

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
            parseBlock(true, true);
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
        enforce!GrCompilerException(breaksJumps.length,
            "attempting to close a non-existing function");

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
        if (get().type != GrLexeme.Type.semicolon)
            logError(format(getError(Error.missingSemicolonAfterX), getPrettyLexemeType(GrLexeme.Type.break_)),
                format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.semicolon), getPrettyLexemeType(get().type)));
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
        enforce!GrCompilerException(continuesJumps.length,
            "attempting to close a non-existing function");

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
        if (get().type != GrLexeme.Type.semicolon)
            logError(format(getError(Error.missingSemicolonAfterX), getPrettyLexemeType(GrLexeme.Type.continue_)),
                format(getError(Error.expectedXFoundY),
                    getPrettyLexemeType(GrLexeme.Type.semicolon), getPrettyLexemeType(get().type)));
        advance();
    }

    private void parseVariableDeclaration(bool isConst, bool isGlobal, bool isExport) {
        checkAdvance();

        GrType type = GrType.Base.void_;
        bool isAuto;

        string[] identifiers;
        uint[] nameLexPositions;
        do {
            if (get().type == GrLexeme.Type.comma)
                checkAdvance();

            if (get().type != GrLexeme.Type.identifier)
                logError(format(getError(Error.expectedIdentifierFoundX),
                        getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));

            identifiers ~= get().strValue;
            nameLexPositions ~= current;
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
        foreach (size_t i, string identifier; identifiers) {
            GrVariable lvalue = registerVariable(identifier, type, isAuto,
                isGlobal, isConst, isExport, true, nameLexPositions[i], true);
            lvalues ~= lvalue;
        }

        parseAssignList(lvalues, true);

        foreach (GrVariable lvalue; lvalues) {
            if (isGlobal)
                globalVariables ~= lvalue;
            else
                currentFunction.setLocal(lvalue);
        }
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

        parseBlock(true, true); //{ .. }

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

                    parseBlock(true, true); //{ .. }

                    // On sort du bloc avec un saut
                    exitJumps ~= cast(uint) currentFunction.instructions.length;
                    addInstruction(GrOpcode.jump);

                    // On met la destination du saut du `if`/`unless` s’il n’est pas vérifié
                    setInstruction(isNegative ? GrOpcode.jumpNotEqual : GrOpcode.jumpEqual, jumpPosition,
                        cast(int)(currentFunction.instructions.length - jumpPosition), true);
                }
                else
                    parseBlock(true, true);
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
            channelSize = lex.intValue > int.max ? 1 : cast(int) lex.intValue;
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

        if (!subType.isValid) {
            logError(format(getError(Error.chanCantBeOfTypeX),
                    getPrettyType(grChannel(subType))), getError(Error.invalidChanType));
        }

        addInstruction(GrOpcode.channel, channelSize);

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
        const size_t fileId = get().fileId;
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

            parseBlock(true, true);

            exitJumps ~= cast(uint) currentFunction.instructions.length;
            addInstruction(GrOpcode.jump);

            // On saute au cas suivant
            setInstruction(GrOpcode.jumpEqual, jumpPosition,
                cast(int)(currentFunction.instructions.length - jumpPosition), true);
        }

        if (hasDefaultCase) {
            const uint tmp = current;
            current = defaultCasePosition;
            parseBlock(true, true);
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
    default BLOCK
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

            parseBlock(true, true);

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
            parseBlock(true, true);
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

        parseBlock(true, true);

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

        parseBlock(true, true);

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

        uint lexPosition = current;
        if (get().type != GrLexeme.Type.identifier)
            logError(format(getError(Error.expectedIdentifierFoundX),
                    getPrettyLexemeType(get().type)), getError(Error.missingIdentifier));
        const string identifier = get().strValue;
        checkAdvance();

        if (get().type == GrLexeme.Type.colon) {
            checkAdvance();
            type = parseType(true);
        }
        else {
            isAuto = true;
        }

        return registerVariable(identifier, type, isTyped ? isAuto : true, false,
            false, false, false, lexPosition, true);
    }

    /// Permet l’itération sur une liste ou un itérateur
    private void parseForStatement() {
        advance();

        bool isYieldable;
        if (get().type == GrLexeme.Type.yield) {
            isYieldable = true;
            advance();
        }

        const size_t fileId = get().fileId;
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

                if (!subType.isValid) {
                    logError(format(getError(Error.listCantBeOfTypeX),
                            getPrettyType(grList(subType))), getError(Error.invalidListType));
                }

                addInstruction(GrOpcode.length_list);
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

                if (!subType.isValid) {
                    logError(format(getError(Error.listCantBeOfTypeX),
                            getPrettyType(grList(subType))), getError(Error.invalidListType));
                }

                addInstruction(GrOpcode.index2_list);
                convertType(subType, variable.type, fileId);
                addSetInstruction(variable, fileId);

                parseBlock(true, true);

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
                    addInstruction(_options & GrOption.safe ? GrOpcode.safePrimitiveCall
                            : GrOpcode.primitiveCall, nextPrim.index);
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

        const size_t fileId = get().fileId;
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

        parseBlock(true, true);

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
        const size_t fileId = get().fileId;

        checkDeferStatement();
        checkAdvance();
        if (currentFunction.isTask || currentFunction.isEvent) {
            if (!currentFunction.instructions.length ||
                currentFunction.instructions[$ - 1].opcode != GrOpcode.die)
                addDie();
        }
        else {
            if (!currentFunction.outSignature.length && get().type != GrLexeme.Type.semicolon) {
                logError(getError(Error.mismatchedNumRetVal),
                    format(getError(Error.expectedXRetValFoundY),
                        currentFunction.outSignature.length, 1));
            }
            else if (currentFunction.outSignature.length && get().type == GrLexeme.Type.semicolon) {
                logError(getError(Error.mismatchedNumRetVal),
                    format(getError(Error.expectedXRetValFoundY),
                        currentFunction.outSignature.length, 0));
            }

            GrType[] expressionTypes;
            if (currentFunction.outSignature.length) {
                for (;;) {
                    if (expressionTypes.length >= currentFunction.outSignature.length) {
                        logError(getError(Error.mismatchedNumRetVal),
                            format(getError(currentFunction.outSignature.length > 1 ?
                                Error.expectedXRetValsFoundY : Error.expectedXRetValFoundY),
                                currentFunction.outSignature.length, expressionTypes.length + 1),
                            format(getError(Error.retSignatureOfTypeX),
                                getPrettyFunctionCall("", currentFunction.outSignature)), -1);
                    }
                    GrType type = parseSubExpression(
                        GR_SUBEXPR_TERMINATE_SEMICOLON |
                            GR_SUBEXPR_TERMINATE_COMMA | GR_SUBEXPR_EXPECTING_VALUE).type;
                    if (type.base == GrType.Base.internalTuple) {
                        auto types = grUnpackTuple(type);
                        if (types.length) {
                            foreach (subType; types) {
                                if (expressionTypes.length >= currentFunction.outSignature.length) {
                                    logError(getError(Error.mismatchedNumRetVal),
                                        format(getError(currentFunction.outSignature.length > 1 ?
                                            Error.expectedXRetValsFoundY
                                            : Error.expectedXRetValFoundY),
                                            currentFunction.outSignature.length, types.length),
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
    private void addExit() {
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

    private bool convertSignature(ref uint operations, GrType[] srcSignature, size_t arity,
        GrType[] dstSignature, bool isAbstract = false, size_t fileId = 0, bool isTest = false) {
        const size_t len = srcSignature.length;
        if (len != dstSignature.length)
            return false;

        if (len == 0)
            return true;

        if (arity > len || arity < 0)
            arity = len;

        operations = 0;

        int[] swapOperations;

        for (size_t i = 0; i < len; ++i) {
            GrType srcType = srcSignature[i];
            GrType dstType = dstSignature[i];

            if ((i + 1) > arity) {
                if (!_data.isSignatureCompatible([srcType], [dstType], isAbstract, fileId)) {
                    return false;
                }
                break;
            }

            if (!_data.isSignatureCompatible([srcType], [dstType], isAbstract, fileId)) {
                int op = (cast(int)(arity - i)) - 1;
                if (!isTest && op > 0) {
                    swapOperations ~= op;
                    addInstruction(GrOpcode.swap, op);
                }

                GrType result = convertType(srcType, dstType, fileId, true, false, isTest);
                if (result.base == GrType.Base.void_)
                    return false;

                if (!isTest && op > 0)
                    addInstruction(GrOpcode.swap, op);
                operations++;
            }
        }

        return true;
    }

    /// Tente de convertir le type source au type destinataire.
    private GrType convertType(GrType src, GrType dst, size_t fileId = 0,
        bool noFail = false, bool isExplicit = false, bool isTest = false) {

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
            case uint_:
            case char_:
            case byte_:
            case float_:
            case double_:
            case string_:
            case enum_:
            case instance:
                return dst;
            case class_:
                string className = src.mangledType;
                for (;;) {
                    if (className == dst.mangledType)
                        return dst;
                    const GrClassDefinition classType = getClass(className, fileId);
                    if (!classType || !classType.parent.length)
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
                    if (!nativeType || !nativeType.parent.length)
                        break;
                    nativeName = nativeType.parent;
                }
                break;
            }
        }

        if (src.base == GrType.Base.class_ && dst.base == GrType.Base.native) {
            GrClassDefinition class_ = getClass(src.mangledType, fileId);
            if (class_ && class_.nativeParent) {
                string nativeName = class_.nativeParent.name;
                for (;;) {
                    if (nativeName == dst.mangledType) {
                        if (!isTest)
                            addInstruction(GrOpcode.parentLoad);
                        return dst;
                    }
                    const GrNativeDefinition nativeType = _data.getNative(nativeName);
                    if (!nativeType || !nativeType.parent.length)
                        break;
                    nativeName = nativeType.parent;
                }
            }
        }

        if (dst.base == GrType.Base.optional) {
            if (src.base == GrType.Base.null_)
                return dst;

            GrType subType = grUnmangle(dst.mangledType);

            if (convertType(src, subType, fileId, noFail, isExplicit, isTest).base == subType.base)
                return dst;
        }

        if (src.base == GrType.Base.internalTuple || dst.base == GrType.Base.internalTuple)
            logError(format(getError(Error.expectedXFoundY), getPrettyType(dst),
                    getPrettyType(src)), getError(Error.mismatchedTypes), "", -1);

        if (dst.base == GrType.Base.bool_) {
            if (src.isNullable) {
                if (!isTest)
                    addInstruction(GrOpcode.checkNull);
                return dst;
            }
        }

        // Conversion personnalisée
        if (addCustomConversion(src, dst, isExplicit, get().fileId, isTest) == dst)
            return dst;

        if (!noFail)
            logError(format(getError(Error.cantConvertXToY), getPrettyType(src),
                    getPrettyType(dst)), getError(Error.noConvAvailable), "", -1);
        return GrType(GrType.Base.void_);
    }

    /// Convertit avec une fonction
    private GrType addCustomConversion(GrType leftType, GrType rightType,
        bool isExplicit, size_t fileId, bool isTest = false) {
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
            if (!isTest) {
                addInstruction(_options & GrOption.safe ? GrOpcode.safePrimitiveCall
                        : GrOpcode.primitiveCall, matching.prim.index);
            }
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
                if (!isTest)
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
        size_t fileId = get().fileId;
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

                // Si la classe a un parent natif, on l’instancie ici, puis on l’associe avec parentStore
                if (class_.nativeParent) {
                    string name = "@static_" ~ grUnmangleComposite(class_.nativeParent.name).name;
                    GrType[] signature = [
                        GrType(GrType.Base.native, class_.nativeParent.name)
                    ];
                    auto matching = getFirstMatchingFuncOrPrim(name, signature, fileId);
                    if (matching.prim) {
                        addInstruction(_options & GrOption.safe ? GrOpcode.safePrimitiveCall
                                : GrOpcode.primitiveCall, matching.prim.index);
                    }
                    else if (matching.func) {
                        addFunctionCall(matching.func, fileId);
                    }
                    else {
                        logError(format(getError(Error.xNotDecl), getPrettyFunctionCall(name,
                                signature)), getError(Error.unknownFunc), "", -1);
                    }
                    addInstruction(GrOpcode.parentStore);
                }

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
                        const string fieldName = get().strValue;
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

                name ~= "." ~ get().strValue;
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
                addInstruction(_options & GrOption.safe ? GrOpcode.safePrimitiveCall
                        : GrOpcode.primitiveCall, matching.prim.index);
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
        const size_t fileId = get().fileId;
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
                defaultListSize = lex.intValue > int.max ? 0 : cast(int) lex.intValue;
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

        if (!subType.isValid) {
            logError(format(getError(Error.listCantBeOfTypeX),
                    getPrettyType(grList(subType))), getError(Error.invalidListType));
        }

        addInstruction(GrOpcode.list, listSize);

        return listType;
    }

    private GrType parseListIndex(GrType listType) {
        const size_t fileId = get().fileId;
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

                    if (!subType.isValid) {
                        logError(format(getError(Error.listCantBeOfTypeX),
                                getPrettyType(grList(subType))), getError(Error.invalidListType));
                    }

                    addInstruction(GrOpcode.index_list);

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

                if (!subType.isValid) {
                    logError(format(getError(Error.listCantBeOfTypeX),
                            getPrettyType(listType)), getError(Error.invalidListType));
                }

                addInstruction(GrOpcode.index2_list);

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

        const size_t fileId = get().fileId;
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
        const size_t fileId = get().fileId;
        if (get().type != GrLexeme.Type.identifier)
            logError(format(getError(Error.expectedVarFoundX),
                    getPrettyLexemeType(get().type)), getError(Error.missingVar));

        const string identifierName = get().strValue;

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
            case period:
            case identifier:
                checkAdvance();
                break;
            default:
                break __skipLoop;
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
        const size_t fileId = get().fileId;
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

    private void addDefaultValue(GrType type, size_t fileId) {
        final switch (type.base) with (GrType.Base) {
        case int_:
        case bool_:
        case enum_:
            addIntConstant(0);
            break;
        case uint_:
        case char_:
            addUIntConstant(0u);
            break;
        case byte_:
            addByteConstant(0u);
            break;
        case float_:
            addFloatConstant(0f);
            break;
        case double_:
            addDoubleConstant(0.0);
            break;
        case string_:
            addStringConstant("");
            break;
        case func:
            uint nameLexPosition = current;
            GrType[] inSignature = grUnmangleSignature(type.mangledType);
            GrType[] outSignature = grUnmangleSignature(type.mangledReturnType);
            string[] inputs;
            for (int i; i < inSignature.length; ++i) {
                inputs ~= to!string(i);
            }
            preBeginFunction("$anon", nameLexPosition, fileId, inSignature,
                inputs, false, outSignature, true);
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
            uint nameLexPosition = current;
            GrType[] inSignature = grUnmangleSignature(type.mangledType);
            string[] inputs;
            for (int i; i < inSignature.length; ++i) {
                inputs ~= to!string(i);
            }
            preBeginFunction("$anon", nameLexPosition, fileId, inSignature,
                inputs, true, [], true);
            openDeferrableSection();
            addDie();
            closeDeferrableSection();
            registerDeferBlocks();
            endFunction();
            break;
        case event:
            uint nameLexPosition = current;
            GrType[] inSignature = grUnmangleSignature(type.mangledType);
            string[] inputs;
            for (int i; i < inSignature.length; ++i) {
                inputs ~= to!string(i);
            }
            preBeginFunction("$anon", nameLexPosition, fileId, inSignature,
                inputs, true, [], true, true);
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

            if (!subTypes[0].isValid) {
                logError(format(getError(Error.listCantBeOfTypeX),
                        getPrettyType(grList(subTypes[0]))), getError(Error.invalidListType));
            }

            addInstruction(GrOpcode.list, 0);
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

            if (!subTypes[0].isValid) {
                logError(format(getError(Error.chanCantBeOfTypeX),
                        getPrettyType(grChannel(subTypes[0]))), getError(Error.invalidChanType));
            }

            addInstruction(GrOpcode.channel, 1);
            break;
        case class_:
        case native:
            string name = "@static_" ~ grUnmangleComposite(type.mangledType).name;
            auto matching = getFirstMatchingFuncOrPrim(name, [type], get().fileId);

            if (matching.prim) {
                addInstruction(_options & GrOption.safe ? GrOpcode.safePrimitiveCall
                        : GrOpcode.primitiveCall, matching.prim.index);
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
        case instance:
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
        case uint_:
        case char_:
        case byte_:
        case bool_:
        case func:
        case task:
        case event:
        case instance:
        case enum_:
        case float_:
        case double_:
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
        const size_t fileId = get().fileId;
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
            logError(format(getError(Error.cantInferTypeOfX), get().strValue),
                getError(Error.funcTypeCantBeInferred));

        GrType funcType = addFunctionAddress(get().strValue,
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
        size_t fileId;

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
                            if (!currentType.isValid) {
                                logError(format(getError(Error.listCantBeIndexedByX),
                                        getPrettyType(currentType)),
                                    getError(Error.invalidListIndexType));
                            }

                            setInstruction(GrOpcode.index3_list,
                                cast(int) currentFunction.instructions.length - 1);
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
                        if (!currentType.isValid) {
                            logError(format(getError(Error.listCantBeIndexedByX),
                                    getPrettyType(currentType)),
                                getError(Error.invalidListIndexType));
                        }

                        setInstruction(GrOpcode.index2_list,
                            cast(int) currentFunction.instructions.length - 1);
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
                addIntConstant(lex.intValue);
                hasValue = true;
                typeStack ~= currentType;
                checkAdvance();
                break;
            case uint_:
                currentType = GrType(GrType.Base.uint_);
                addUIntConstant(lex.uintValue);
                hasValue = true;
                typeStack ~= currentType;
                checkAdvance();
                break;
            case byte_:
                currentType = GrType(GrType.Base.byte_);
                addByteConstant(lex.byteValue);
                hasValue = true;
                typeStack ~= currentType;
                checkAdvance();
                break;
            case char_:
                currentType = GrType(GrType.Base.char_);
                addUIntConstant(lex.uintValue);
                hasValue = true;
                typeStack ~= currentType;
                checkAdvance();
                break;
            case float_:
                currentType = GrType(GrType.Base.float_);
                addFloatConstant(lex.floatValue);
                hasValue = true;
                typeStack ~= currentType;
                checkAdvance();
                break;
            case double_:
                currentType = GrType(GrType.Base.double_);
                addDoubleConstant(lex.doubleValue);
                hasValue = true;
                typeStack ~= currentType;
                checkAdvance();
                break;
            case bool_:
                currentType = GrType(GrType.Base.bool_);
                addBoolConstant(lex.boolValue);
                hasValue = true;
                typeStack ~= currentType;
                checkAdvance();
                break;
            case string_:
                currentType = GrType(GrType.Base.string_);
                addStringConstant(lex.strValue);
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
            case default_:
                hasValue = true;
                checkAdvance();
                if (get().type != GrLexeme.Type.lesser)
                    logError(format(getError(Error.expectedXFoundY), getPrettyLexemeType(GrLexeme.Type.lesser),
                            getPrettyLexemeType(get().type)), format(getError(Error.missingX),
                            getPrettyLexemeType(GrLexeme.Type.lesser)));

                checkAdvance();
                currentType = parseType();
                addDefaultValue(currentType, fileId);

                distinguishTemplateLexemes();
                if (get().type != GrLexeme.Type.greater)
                    logError(format(getError(Error.expectedXFoundY), getPrettyLexemeType(GrLexeme.Type.greater),
                            getPrettyLexemeType(get().type)), format(getError(Error.missingX),
                            getPrettyLexemeType(GrLexeme.Type.greater)));
                checkAdvance();

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
                if (!hadValue) { // Enumération implicite
                    string enumName = currentFunction.getImplicitEnum();
                    if (!enumName.length)
                        logError(getError(Error.cantInferEnum),
                            format(getError(Error.expectedEnumNameFoundX), "."), "", -1);

                    const GrEnumDefinition definition = _data.getEnum(enumName, fileId);
                    if (get().type != GrLexeme.Type.identifier)
                        logError(getError(Error.expectedConstNameAfterEnumType),
                            getError(Error.missingEnumConstantName));
                    const string fieldName = get().strValue;
                    if (!definition.hasField(fieldName)) {
                        string[] fieldNames;
                        foreach (field; definition.fields) {
                            fieldNames ~= field.name;
                        }
                        const string[] nearestValues = findNearestStrings(fieldName, fieldNames);
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

                    currentType = GrType(GrType.Base.enum_);
                    currentType.mangledType = definition.name;
                    addIntConstant(definition.getField(fieldName));

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
                bool isOptionalCall;
                bool hasField;
                uint optionalCallPosition;
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
                    logError(format(getError(Error.expectedFieldNameFoundX),
                            getPrettyLexemeType(get().type)), getError(Error.missingField));
                const string identifier = get().strValue;

                GrNativeDefinition nativeParent;
                if (currentType.base == GrType.Base.class_) {
                    GrClassDefinition class_ = getClass(currentType.mangledType, get().fileId);
                    if (!class_)
                        logError(format(getError(Error.xNotDecl),
                                getPrettyType(currentType)), getError(Error.unknownType));

                    if (class_.nativeParent) {
                        nativeParent = class_.nativeParent;
                    }
                }

                if (currentType.base == GrType.Base.native || nativeParent) {
                    GrNativeDefinition native = nativeParent ? nativeParent : _data.getNative(
                        currentType.mangledType);
                    if (!native)
                        logError(format(getError(Error.xNotDecl),
                                getPrettyType(currentType)), getError(Error.unknownType));

                    const string propertyName = "@property_" ~ identifier;
                    GrType[] signature = nativeParent ? [
                        GrType(GrType.Base.native, nativeParent.name)
                    ] : [currentType];

                    GrLexeme.Type operatorType = get(1).type;

                    auto getFunc = getFirstMatchingFuncOrPrim(propertyName, signature, fileId);
                    if (getFunc.prim) {
                        checkAdvance();

                        if (nativeParent)
                            addInstruction(GrOpcode.parentLoad);

                        if (operatorType != GrLexeme.Type.assign) {
                            if (requireLValue(operatorType)) {
                                addInstruction(GrOpcode.copy);
                            }

                            addInstruction(_options & GrOption.safe ? GrOpcode.safePrimitiveCall
                                    : GrOpcode.primitiveCall, getFunc.prim.index);
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
                            else {
                                currentType = subType;
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
                            if (signature.length > 1)
                                signature[1] = currentType;
                            auto setFunc = getFirstMatchingFuncOrPrim(propertyName,
                                signature, fileId);
                            if (setFunc.prim) {
                                addInstruction(_options & GrOption.safe ? GrOpcode.safePrimitiveCall
                                        : GrOpcode.primitiveCall, setFunc.prim.index);
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
                if (currentType.base == GrType.Base.class_) {
                    GrClassDefinition class_ = getClass(currentType.mangledType, get().fileId);
                    if (!class_)
                        logError(format(getError(Error.xNotDecl),
                                getPrettyType(currentType)), getError(Error.unknownType));
                    const auto nbFields = class_.signature.length;
                    for (int i; i < nbFields; i++) {
                        if (identifier == class_.fields[i]) {
                            if ((class_.fieldsInfo[i].fileId != fileId) &&
                                !class_.fieldsInfo[i].isExport)
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

                if (!requireLValue(operatorType)) {
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
                        addInstruction(_options & GrOption.safe ? GrOpcode.safePrimitiveCall
                                : GrOpcode.primitiveCall, matching.prim.index);
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
                        addInstruction(_options & GrOption.safe ? GrOpcode.safePrimitiveCall
                                : GrOpcode.primitiveCall, matching.prim.index);
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
            case function_:
                // Se réfère à la fonction actuelle
                checkAdvance();
                currentType = addFunctionAddress(currentFunction, get().fileId);
                if (currentType.base == GrType.Base.void_)
                    logError(format(getError(Error.xMustBeInsideFuncOrTask),
                            getPrettyLexemeType(GrLexeme.Type.function_)),
                        format(getError(Error.xRefNoFuncNorTask),
                            getPrettyLexemeType(GrLexeme.Type.function_)), "", -1);
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
            case self:
                addInstruction(GrOpcode.self);
                currentType = grInstance;
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
        if (!type.isValid) {
            logError(format(getError(Error.cantLoadFieldOfTypeX),
                    getPrettyType(type)), getError(Error.fieldTypeIsInvalid));
        }

        addInstruction(asCopy ? GrOpcode.fieldLoad2 : GrOpcode.fieldLoad, index);
    }

    /// Analyse un appel de fonction sur un type anonyme
    private GrType parseAnonymousCall(GrType type, GrType selfType = grVoid) {
        const size_t fileId = get().fileId;

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

        // Récupère les paramètres de la tâche créée
        if (type.base == GrType.Base.task)
            addInstruction(GrOpcode.extend, cast(int) signature.length);

        return retTypes;
    }

    /// Analyse un identificateur ou un appel de fonction
    /// et retourne le type déduit et sa `lvalue`.
    private GrType parseIdentifier(ref GrVariable variableRef,
        GrType expectedType, GrType selfType = grVoid, bool isAssignment = false) {
        GrType returnType = GrType.Base.void_;
        GrLexeme identifier = get();
        bool isFunctionCall = false, isMethodCall = false, hasParenthesis = false;
        string identifierName = identifier.strValue;
        const size_t fileId = identifier.fileId;

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
                                        Error.expectedXArgsFoundY : Error.expectedXArgFoundY),
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
                            format(getError(anonSignature.length > 1 ? Error.expectedXArgsFoundY : Error.expectedXArgFoundY),
                                anonSignature.length, signature.length),
                            format(getError(Error.funcIsOfTypeX), getPrettyType(variable.type)));
                    }
                }

                // Appel anonyme
                addGetInstruction(variable);

                returnType = grPackTuple(grUnmangleSignature(variable.type.mangledReturnType));

                if (variable.type.base == GrType.Base.func)
                    addInstruction(GrOpcode.anonymousCall, 0u);
                else if (variable.type.base == GrType.Base.task)
                    addInstruction(GrOpcode.anonymousTask, 0u);

                // Récupère les paramètres de la tâche créée
                if (variable.type.base == GrType.Base.task)
                    addInstruction(GrOpcode.extend, cast(int) signature.length);

                _data.addDefinition(identifier, variable);
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
                    addInstruction(_options & GrOption.safe ? GrOpcode.safePrimitiveCall
                            : GrOpcode.primitiveCall, matching.prim.index);
                    returnType = grPackTuple(matching.prim.outSignature);
                    _data.addDefinition(identifier, matching.prim);
                }
                else if (matching.func) {
                    returnType = grPackTuple(addFunctionCall(matching.func, fileId));
                    _data.addDefinition(identifier, matching.func);
                }
                else {
                    logError(format(getError(Error.xNotDecl), getPrettyFunctionCall(identifierName,
                            signature)), getError(Error.unknownFunc), "", -1);
                }
            }
        }
        else if (_data.isEnum(identifier.strValue, fileId, false)) {
            const GrEnumDefinition definition = _data.getEnum(identifier.strValue, fileId);
            _data.addDefinition(identifier, definition);

            if (get().type != GrLexeme.Type.period)
                logError(getError(Error.expectedDotAfterEnumType),
                    getError(Error.missingEnumConstantName));
            checkAdvance();

            if (get().type != GrLexeme.Type.identifier)
                logError(getError(Error.expectedConstNameAfterEnumType),
                    getError(Error.missingEnumConstantName));

            const string fieldName = get().strValue;
            if (!definition.hasField(fieldName)) {
                string[] fieldNames;
                foreach (field; definition.fields) {
                    fieldNames ~= field.name;
                }
                const string[] nearestValues = findNearestStrings(fieldName, fieldNames);
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
            _data.addDefinition(get(), definition);
            checkAdvance();

            returnType = GrType(GrType.Base.enum_);
            returnType.mangledType = definition.name;
            currentFunction.setImplicitEnum(definition.name);
            addIntConstant(definition.getField(fieldName));
        }
        else {
            // Variable déclarée
            variableRef = getVariable(identifierName, fileId);
            _data.addDefinition(identifier, variableRef);

            returnType = variableRef.type;
            if (returnType.base == GrType.Base.enum_)
                currentFunction.setImplicitEnum(returnType.mangledType);
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

        if (lexemes.length) {
            GrLexeme lex = (isEnd() && offset >= 0) ? get(-1) : get(offset);
            error.filePath = lex.getFile();
            error.lineText = lex.getLine().replace("\t", " ");
            error.line = lex.line;
            error.column = lex.column;
            error.textLength = lex.textLength;
        }
        else {
            error.filePath = "";
            error.lineText = "";
            error.line = 1u; // Par convention, la première ligne commence à 1, et non 0.
            error.column = 0u;
            error.textLength = 0u;
        }

        if (otherInfo.length) {
            error.otherInfo = otherInfo;

            set(otherPos);

            if (lexemes.length) {
                GrLexeme otherLex = isEnd() ? get(-1) : get();
                error.otherFilePath = otherLex.getFile();
                error.otherLineText = otherLex.getLine().replace("\t", " ");
                error.otherLine = otherLex.line;
                error.otherColumn = otherLex.column;
                error.otherTextLength = otherLex.textLength;
            }
            else {
                error.otherFilePath = "";
                error.otherLineText = "";
                error.otherLine = 1u; // Par convention, la première ligne commence à 1, et non 0.
                error.otherColumn = 0u;
                error.otherTextLength = 0u;
            }
        }
        throw new GrParserException(error);
    }

    private enum Error {
        eofReached,
        eof,
        nameXDefMultipleTimes,
        funcXDefMultipleTimes,
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
        callXIsAmbiguous,
        callMatchesSeveralInstances,
        matchingInstancesAreX,
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
        addingExportBeforeEventIsRedundant,
        eventAlreadyExported,
        cantOverrideXOp,
        opCantBeOverriden,
        xNotUnaryOp,
        xNotBinaryOp,
        opMustHave1Or2Args,
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
        missingSemicolonAfterX,
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
        cantInferEnum,
        expectedDotAfterEnumType,
        missingEnumConstantName,
        missingEnumConstantValue,
        expectedConstNameAfterEnumType,
        xIsAbstract,
        xIsAbstractAndCannotBeInstanciated,
        expectedOptionalType,
        opMustFollowAnOptionalType,
        cantConvertXToY,
        noConvAvailable
    }

    private string getError(Error error) {
        final switch (_locale) with (GrLocale) {
        case en_US:
            final switch (error) with (Error) {
            case eofReached:
                return "reached the end of the file";
            case eof:
                return "unexpected end of file";
            case unknownFunc:
                return "unknown function";
            case unknownVar:
                return "unknown variable";
            case unknownOp:
                return "unknown operator";
            case unknownClass:
                return "unknown class";
            case unknownType:
                return "unknown type";
            case unknownOpPriority:
                return "unknown operator priority";
            case unknownField:
                return "unknown field";
            case invalidType:
                return "invalid type";
            case invalidParamType:
                return "invalid parameter type";
            case invalidChanType:
                return "invalid channel type";
            case invalidListType:
                return "invalid list type";
            case invalidListIndexType:
                return "invalid list index type";
            case xNotDef:
                return "`%s` is not defined";
            case xNotDecl:
                return "`%s` is not declared";
            case nameXDefMultipleTimes:
                return "the name `%s` is defined multiple times";
            case funcXDefMultipleTimes:
                return "the function `%s` is defined multiple times";
            case xRedefHere:
                return "`%s` is redefined here";
            case prevDefOfX:
                return "previous definition of `%s`";
            case prevDefPrim:
                return "`%s` is already defined as a primitive";
            case alreadyDef:
                return "`%s` is already declared";
            case cantDefVarOfTypeX:
                return "can't define a variable of type %s";
            case cantUseTypeAsParam:
                return "can't use `%s` as a parameter type";
            case opMustHave1RetVal:
                return "an operator must have only one return value";
            case expected1RetValFoundX:
                return "expected 1 return value, found %s return value";
            case expected1RetValFoundXs:
                return "expected 1 return value, found %s return values";
            case cantUseOpOnMultipleVal:
                return "can't use an operator on multiple values";
            case exprYieldsMultipleVal:
                return "the expression yields multiple values";
            case noXUnaryOpDefForY:
                return "there is no `%s` unary operator defined for `%s`";
            case noXBinaryOpDefForYAndZ:
                return "there is no `%s` binary operator defined for `%s` and `%s`";
            case exprIsConstAndCantBeModified:
                return "the expression is const and can't be modified";
            case xIsConstAndCantBeModified:
                return "`%s` is const and can't be modified";
            case cantModifyAConst:
                return "can't modify a const";
            case callXIsAmbiguous:
                return "the call `%s` to an overloaded function is ambiguous";
            case callMatchesSeveralInstances:
                return "this call matches several instances";
            case matchingInstancesAreX:
                return "matching instances are: %s";
            case cantAssignToAXVar:
                return "can't assign to a `%s` variable";
            case ValNotAssignable:
                return "the value is not assignable";
            case cantInferTypeOfVar:
                return "can't infer the type of variable";
            case varNotInit:
                return "the variable has not been initialized";
            case locVarUsedNotAssigned:
                return "the local variable is being used without being assigned";
            case cantGetValueOfX:
                return "can't get the value of `%s`";
            case valNotFetchable:
                return "the value is not fetchable";
            case globalDeclExpected:
                return "a global declaration is expected";
            case globalDeclExpectedFoundX:
                return "a global declaration is expected, found `%s`";
            case funcMissingRetAtEnd:
                return "the function is missing a return at the end of the scope";
            case missingRet:
                return "missing `return`";
            case expectedTypeAliasNameFoundX:
                return "expected type alias name, found `%s`";
            case expectedEnumNameFoundX:
                return "expected enum name, found `%s`";
            case expectedXFoundY:
                return "expected `%s`, found `%s`";
            case missingIdentifier:
                return "missing identifier";
            case missingColonBeforeType:
                return "missing `:` before type";
            case missingSemicolonAfterType:
                return "missing `;` after type";
            case enumDefNotHaveBody:
                return "the enum definition does not have a body";
            case expectedEnumFieldFoundX:
                return "expected enum field, found `%s`";
            case missingSemicolonAfterEnumField:
                return "missing `;` after type enum field";
            case xAlreadyDecl:
                return "`%s` is already declared";
            case expectedClassNameFoundX:
                return "expected class name, found `%s`";
            case parentClassNameMissing:
                return "the parent class name is missing";
            case classHaveNoBody:
                return "the class does not have a body";
            case missingSemicolonAfterClassFieldDecl:
                return "missing `;` after class field declaration";
            case xCantInheritFromY:
                return "`%s` can't inherit from `%s`";
            case xIncludedRecursively:
                return "`%s` is included recursively";
            case recursiveInheritence:
                return "recursive inheritence";
            case fieldXDeclMultipleTimes:
                return "the field `%s` is declared multiple times";
            case recursiveDecl:
                return "recursive declaration";
            case xNotValidType:
                return "`%s` is not a valid type";
            case expectedValidTypeFoundX:
                return "expected a valid type, found `%s`";
            case listCanOnlyContainOneTypeOfVal:
                return "a list can only contain one type of value";
            case conflictingListSignature:
                return "conflicting list signature";
            case tryUsingXInstead:
                return "try using `%s` instead";
            case channelCanOnlyContainOneTypeOfVal:
                return "a channel can only contain one type of value";
            case conflictingChannelSignature:
                return "conflicting channel signature";
            case missingTemplateVal:
                return "missing template value";
            case templateValShouldBeSeparatedByComma:
                return "template values should be separated by a comma";
            case templateTypesShouldBeSeparatedByComma:
                return "template types should be separated by a comma";
            case missingParentheses:
                return "missing parentheses";
            case paramShouldBeSeparatedByComma:
                return "parameters should be separated by a comma";
            case expectedIdentifierFoundX:
                return "expected identifier, found `%s`";
            case typesShouldBeSeparatedByComma:
                return "types should be separated by a comma";
            case addingExportBeforeEventIsRedundant:
                return "adding `export` before `event` is redundant";
            case eventAlreadyExported:
                return "event is already exported";
            case cantOverrideXOp:
                return "can't override `%s` operator";
            case opCantBeOverriden:
                return "this operator can't be overriden";
            case xNotUnaryOp:
                return "`%s` is not an unary operator";
            case xNotBinaryOp:
                return "`%s` is not a binary operator";
            case opMustHave1Or2Args:
                return "an operator must have 1 or 2 arguments";
            case missingConstraint:
                return "missing constraint";
            case xIsNotAKnownConstraint:
                return "`%s` is not a known constraint";
            case validConstraintsAreX:
                return "valid constraints are: %s";
            case expectedColonAfterType:
                return "`:` expected after a type";
            case constraintTakesXArgButYWereSupplied:
                return "the constraint takes %s argument but %s were supplied";
            case constraintTakesXArgsButYWereSupplied:
                return "the constraint takes %s arguments but %s were supplied";
            case convMustHave1RetVal:
                return "a conversion must have only one return value";
            case convMustHave1Param:
                return "a conversion must have only one parameter";
            case expected1ParamFoundX:
                return "expected 1 parameter, found %s parameter";
            case expected1ParamFoundXs:
                return "expected 1 parameter, found %s parameters";
            case missingCurlyBraces:
                return "missing curly braces";
            case expectedIntFoundX:
                return "expected int_, found `%s`";
            case deferInsideDefer:
                return "`defer` inside another `defer`";
            case cantDeferInsideDefer:
                return "can't `defer` inside another `defer`";
            case xInsideDefer:
                return "`%s` inside a defer";
            case cantXInsideDefer:
                return "can't `%s` inside a defer";
            case breakOutsideLoop:
                return "`break` outside of a loop";
            case cantBreakOutsideLoop:
                return "can't `break` outside of a loop";
            case continueOutsideLoop:
                return "`continue` outside of a loop";
            case cantContinueOutsideLoop:
                return "can't `continue` outside of a loop";
            case xNotValidRetType:
                return "`%s` is not a valid return type";
            case chanSizeMustBePositive:
                return "a channel size must be a positive integer value";
            case listSizeMustBePositive:
                return "an list size must be a positive integer value";
            case missingCommaOrGreaterInsideChanSignature:
                return "missing `,` or `>` inside channel signature";
            case missingCommaOrGreaterInsideListSignature:
                return "missing `,` or `>` inside list signature";
            case missingXInChanSignature:
                return "missing `%s` after the channel signature";
            case missingXInListSignature:
                return "missing `%s` after the list signature";
            case missingXInNullSignature:
                return "missing `%s` after the null signature";
            case chanSizeMustBeOneOrHigher:
                return "the channel size must be one or higher";
            case listSizeMustBeZeroOrHigher:
                return "the list size must be zero or higher";
            case expectedAtLeastSizeOf1FoundX:
                return "expected at least a size of 1, found %s";
            case expectedCommaOrGreaterFoundX:
                return "expected `,` or `>`, found `%s`";
            case chanCantBeOfTypeX:
                return "a channel can't be of type `%s`";
            case missingParenthesesAfterX:
                return "missing parentheses after `%s`";
            case missingCommaInX:
                return "missing comma in `%s`";
            case onlyOneDefaultCasePerX:
                return "there must be only up to one default case per `%s`";
            case defaultCaseAlreadyDef:
                return "default case already defined";
            case prevDefaultCaseDef:
                return "previous default case definition";
            case missingWhileOrUntilAfterLoop:
                return "missing `while` or `until` after the loop";
            case expectedWhileOrUntilFoundX:
                return "expected `while` or `until`, found `%s`";
            case listCantBeOfTypeX:
                return "a list can't be of type `%s`";
            case primXMustRetOptional:
                return "the primitive `%s` must return an optional type";
            case signatureMismatch:
                return "signature mismatch";
            case funcXMustRetOptional:
                return "the function `%s` must return an optional type";
            case notIterable:
                return "not iterable";
            case forCantIterateOverX:
                return "for can't iterate over a `%s`";
            case cantEvalArityUnknownCompound:
                return "can't evaluate the arity of an unknown compound";
            case arityEvalError:
                return "arity evaluation error";
            case typeOfIteratorMustBeIntNotX:
                return "the type of the iterator must be an `int`, not `%s`";
            case iteratorMustBeInt:
                return "the iterator must be an `int`";
            case mismatchedNumRetVal:
                return "mismatched number of return values";
            case expectedXRetValFoundY:
                return "expected %s return value, found %s";
            case expectedXRetValsFoundY:
                return "expected %s return values, found %s";
            case retSignatureOfTypeX:
                return "the return signature is of type `%s`";
            case retTypeXNotMatchSignatureY:
                return "the returned type `%s` does not match the signature `%s`";
            case expectedXVal:
                return "expected `%s` value";
            case opNotListedInOpPriorityTable:
                return "the operator is not listed in the operator priority table";
            case mismatchedTypes:
                return "mismatched types";
            case missingX:
                return "missing `%s`";
            case xNotClassType:
                return "`%s` is not a class type";
            case fieldXInitMultipleTimes:
                return "the field `%s` is initialized multiple times";
            case xAlreadyInit:
                return "`%s` is already initialized";
            case prevInit:
                return "previous initialization";
            case fieldXNotExist:
                return "the field `%s` doesn't exist";
            case expectedFieldNameFoundX:
                return "expected field name, found `%s`";
            case missingField:
                return "missing field";
            case indexesShouldBeSeparatedByComma:
                return "indexes should be separated by a comma";
            case missingVal:
                return "missing value";
            case expectedIndexFoundComma:
                return "an index is expected, found `,`";
            case expectedIntFoundNothing:
                return "expected `int`, found nothing";
            case noValToConv:
                return "no value to convert";
            case expectedVarFoundX:
                return "expected variable, found `%s`";
            case missingVar:
                return "missing variable";
            case exprYieldsNoVal:
                return "the expression yields no value";
            case expectedValFoundNothing:
                return "expected value, found nothing";
            case missingSemicolonAfterExprList:
                return "missing `;` after expression list";
            case tryingAssignXValsToYVar:
                return "trying to assign `%s` values to %s variable";
            case tryingAssignXValsToYVars:
                return "trying to assign `%s` values to %s variables";
            case moreValThanVarToAssign:
                return "there are more values than variable to assign to";
            case assignationMissingVal:
                return "the assignation is missing a value";
            case expressionEmpty:
                return "the expression is empty";
            case firstValOfAssignmentListCantBeEmpty:
                return "first value of an assignment list can't be empty";
            case cantInferTypeWithoutAssignment:
                return "can't infer the type without assignment";
            case missingTypeInfoOrInitVal:
                return "missing type information or initial value";
            case missingSemicolonAfterAssignmentList:
                return "missing `;` after assignment list";
            case missingSemicolonAfterX:
                return "missing `;` after `%s`";
            case typeXHasNoDefaultVal:
                return "the type `%s` has no default value";
            case cantInitThisType:
                return "can't initialize this type";
            case expectedFuncNameFoundX:
                return "expected function name, found `%s`";
            case missingFuncName:
                return "missing function name";
            case cantInferTypeOfX:
                return "can't infer the type of `%s`";
            case funcTypeCantBeInferred:
                return "the function type can't be inferred";
            case unexpectedXFoundInExpr:
                return "unexpected `%s` found in expression";
            case xCantExistInsideThisExpr:
                return "a `%s` can't exist inside this expression";
            case methodCallMustBePlacedAfterVal:
                return "a method call must be placed after a value";
            case listCantBeIndexedByX:
                return "a list can't be indexed by a `%s`";
            case cantAccessFieldOnTypeX:
                return "can't access a field on type `%s`";
            case expectedClassFoundX:
                return "expected a class, found `%s`";
            case xOnTypeYIsPrivate:
                return "`%s` on type `%s` is private";
            case privateField:
                return "private field";
            case noFieldXOnTypeY:
                return "no field `%s` on type `%s`";
            case availableFieldsAreX:
                return "available fields are: %s";
            case missingParamOnMethodCall:
                return "missing parameter on method call";
            case xMustBePlacedAfterVal:
                return "`%s` must be placed after a value";
            case xMustBeInsideFuncOrTask:
                return "`%s` must be inside a function or a task";
            case xRefNoFuncNorTask:
                return "`%s` references no function nor task";
            case valBeforeAssignationNotReferenceable:
                return "the value before assignation is not referenceable";
            case missingRefBeforeAssignation:
                return "missing reference before assignation";
            case cantDoThisKindOfOpOnLeftSideOfAssignement:
                return "can't do this kind of operation on the left side of an assignment";
            case unexpectedOp:
                return "unexpected operation";
            case unOpMustHave1Operand:
                return "an unary operation must have 1 operand";
            case binOpMustHave2Operands:
                return "a binary operation must have 2 operands";
            case unexpectedXSymbolInExpr:
                return "unexpected `%s` symbol in the expression";
            case unexpectedSymbol:
                return "unexpected symbol";
            case missingSemicolonAtEndOfExpr:
                return "missing `;` at the end of the expression";
            case cantLoadFieldOfTypeX:
                return "can't load a field of type `%s`";
            case fieldTypeIsInvalid:
                return "the field type is invalid";
            case xNotCallable:
                return "`%s` is not callable";
            case xNotFuncNorTask:
                return "`%s` is not a function nor a task";
            case funcTakesXArgButMoreWereSupplied:
                return "the function takes %s argument but more were supplied";
            case funcTakesXArgsButMoreWereSupplied:
                return "the function takes %s arguments but more were supplied";
            case funcIsOfTypeX:
                return "the function is of type `%s`";
            case expectedXArg:
                return "expected %s argument";
            case expectedXArgs:
                return "expected %s arguments";
            case funcTakesXArgButYWereSupplied:
                return "the function takes %s argument but %s were supplied";
            case funcTakesXArgsButYWereSupplied:
                return "the function takes %s arguments but %s were supplied";
            case expectedXArgFoundY:
                return "expected %s argument, found %s";
            case expectedXArgsFoundY:
                return "expected %s arguments, found %s";
            case funcOrTaskExpectedFoundX:
                return "function or task expected, found `%s`";
            case funcDefHere:
                return "function defined here";
            case cantInferEnum:
                return "can't infer the enum type";
            case expectedDotAfterEnumType:
                return "expected a `.` after the enum type";
            case missingEnumConstantName:
                return "missing the enum field name";
            case missingEnumConstantValue:
                return "missing the enum field value";
            case expectedConstNameAfterEnumType:
                return "expected an enum field name after the enum type";
            case xIsAbstract:
                return "`%s` is abstract";
            case xIsAbstractAndCannotBeInstanciated:
                return "`%s` is abstract and can't be instanciated";
            case expectedOptionalType:
                return "`?` expect an optional type";
            case opMustFollowAnOptionalType:
                return "`?` must be placed after the optional to unwrap";
            case cantConvertXToY:
                return "can't convert `%s` to `%s`";
            case noConvAvailable:
                return "no conversion available";
            }
        case fr_FR:
            final switch (error) with (Error) {
            case eofReached:
                return "fin de fichier atteinte";
            case eof:
                return "fin de fichier inattendue";
            case unknownFunc:
                return "fonction inconnue";
            case unknownVar:
                return "variable inconnue";
            case unknownOp:
                return "opérateur inconnu";
            case unknownClass:
                return "classe inconnue";
            case unknownType:
                return "type inconnu";
            case unknownOpPriority:
                return "priorité d’opérateur inconnue";
            case unknownField:
                return "champ inconnu";
            case invalidType:
                return "type invalide";
            case invalidParamType:
                return "type de paramètre invalide";
            case invalidChanType:
                return "type de canal invalide";
            case invalidListType:
                return "type de liste invalide";
            case invalidListIndexType:
                return "type d’index de liste invalide";
            case xNotDef:
                return "`%s` n’est pas défini";
            case xNotDecl:
                return "`%s` n’est pas déclaré";
            case nameXDefMultipleTimes:
                return "le nom `%s` est défini plusieurs fois";
            case funcXDefMultipleTimes:
                return "la fonction `%s` est définie plusieurs fois";
            case xRedefHere:
                return "`%s` est redéfini ici";
            case prevDefOfX:
                return "précédente définition de `%s`";
            case prevDefPrim:
                return "`%s` est déjà défini en tant que primitive";
            case alreadyDef:
                return "`%s` est déjà défini";
            case cantDefVarOfTypeX:
                return "impossible définir une variable du type %s";
            case cantUseTypeAsParam:
                return "impossible d’utiliser `%s` comme type de paramètre";
            case opMustHave1RetVal:
                return "un operateur ne doit avoir qu'une valeur de retour";
            case expected1RetValFoundX:
                return "1 valeur de retour attendue, %s valeur trouvée";
            case expected1RetValFoundXs:
                return "1 valeur de retour attendue, %s valeurs trouvées";
            case cantUseOpOnMultipleVal:
                return "impossible d’utiliser un opérateur sur plusieurs valeurs";
            case exprYieldsMultipleVal:
                return "l’expression délivre plusieurs valeurs";
            case noXUnaryOpDefForY:
                return "il n’y a pas d’opérateur unaire `%s` défini pour `%s`";
            case noXBinaryOpDefForYAndZ:
                return "il n’y pas d’opérateur binaire `%s` défini pour `%s` et `%s`";
            case exprIsConstAndCantBeModified:
                return "l’expression est constante et ne peut être assigné";
            case xIsConstAndCantBeModified:
                return "`%s` est constant et ne peut être assigné";
            case cantModifyAConst:
                return "impossible de modifier un type constant";
            case callXIsAmbiguous:
                return "l’appel `%s` d’une fonction surchargée est ambigüe";
            case callMatchesSeveralInstances:
                return "l’appel correspond à plusieurs instances";
            case matchingInstancesAreX:
                return "les instances correspondantes sont: %s";
            case cantAssignToAXVar:
                return "impossible d’assigner à une variable `%s`";
            case ValNotAssignable:
                return "la valeur est non-assignable";
            case cantInferTypeOfVar:
                return "impossible d’inférer le type de la variable";
            case varNotInit:
                return "la variable n’a pas été initialisée";
            case locVarUsedNotAssigned:
                return "la variable locale est utilisée sans avoir été assignée";
            case cantGetValueOfX:
                return "impossible de récupérer la valeure de `%s`";
            case valNotFetchable:
                return "la valeur n’est pas récupérable";
            case globalDeclExpected:
                return "une déclaration globale est attendue";
            case globalDeclExpectedFoundX:
                return "une déclaration globale est attendue, `%s` trouvé";
            case funcMissingRetAtEnd:
                return "il manque un retour en fin de fonction";
            case missingRet:
                return "`return` manquant";
            case expectedTypeAliasNameFoundX:
                return "nom d’alias de type attendu, `%s` trouvé";
            case expectedEnumNameFoundX:
                return "nom d'énumération attendu, `%s` trouvé";
            case expectedXFoundY:
                return "`%s` attendu, `%s` trouvé";
            case missingIdentifier:
                return "identificateur attendu";
            case missingColonBeforeType:
                return "`:` manquant avant le type";
            case missingSemicolonAfterType:
                return "`;` manquant après le type";
            case enumDefNotHaveBody:
                return "la définition de l’énumération n’a pas de corps";
            case expectedEnumFieldFoundX:
                return "champ attendu dans l’énumération, `%s` trouvé";
            case missingSemicolonAfterEnumField:
                return "`;` manquant après le champ de l’énumération";
            case xAlreadyDecl:
                return "`%s` est déjà déclaré";
            case expectedClassNameFoundX:
                return "nom de classe attendu, `%s` trouvé";
            case parentClassNameMissing:
                return "le nom de la classe parente est manquante";
            case classHaveNoBody:
                return "la classe n’a pas de corps";
            case missingSemicolonAfterClassFieldDecl:
                return "`;` manquant après le champ de la classe";
            case xCantInheritFromY:
                return "`%s` ne peut pas hériter de `%s`";
            case xIncludedRecursively:
                return "`%s` est inclus récursivement";
            case recursiveInheritence:
                return "héritage récursif";
            case fieldXDeclMultipleTimes:
                return "le champ `%s` est déclaré plusieurs fois";
            case recursiveDecl:
                return "déclaration récursive";
            case xNotValidType:
                return "`%s` n’est pas un type valide";
            case expectedValidTypeFoundX:
                return "type valide attendu, `%s` trouvé";
            case listCanOnlyContainOneTypeOfVal:
                return "une liste ne peut contenir qu’un type de valeur";
            case conflictingListSignature:
                return "signature de liste conflictuelle";
            case tryUsingXInstead:
                return "utilisez plutôt `%s`";
            case channelCanOnlyContainOneTypeOfVal:
                return "un canal ne peut contenir qu’un type de valeur";
            case conflictingChannelSignature:
                return "signature de canal conflictuelle";
            case missingTemplateVal:
                return "valeur de patron manquante";
            case templateValShouldBeSeparatedByComma:
                return "les valeurs de patron doivent être séparées par des virgules";
            case templateTypesShouldBeSeparatedByComma:
                return "les types de patron doivent être séparés par des virgules";
            case missingParentheses:
                return "parenthèses manquantes";
            case paramShouldBeSeparatedByComma:
                return "les paramètres doivent être séparées par des virgules";
            case expectedIdentifierFoundX:
                return "identificateur attendu, `%s` trouvé";
            case typesShouldBeSeparatedByComma:
                return "les types doivent être séparés par des virgules";
            case addingExportBeforeEventIsRedundant:
                return "ajouter `export` devant `event` est redondant";
            case eventAlreadyExported:
                return "les events sont déjà exportés";
            case cantOverrideXOp:
                return "impossible de surcharger l’opérateur `%s`";
            case opCantBeOverriden:
                return "cet opérateur ne peut être surchargé";
            case xNotUnaryOp:
                return "`%s` n’est pas un opérateur unaire";
            case xNotBinaryOp:
                return "`%s` n’est pas un opérateur binaire";
            case opMustHave1Or2Args:
                return "un opérateur doit avoir 1 ou 2 arguments";
            case missingConstraint:
                return "contrainte manquante";
            case xIsNotAKnownConstraint:
                return "`%s` n’est pas une contrainte connue";
            case validConstraintsAreX:
                return "les contraintes valides sont: %s";
            case expectedColonAfterType:
                return "`:` attendu après le type";
            case constraintTakesXArgButYWereSupplied:
                return "cette contrainte prend %s argument mais %s ont été fournis";
            case constraintTakesXArgsButYWereSupplied:
                return "cette contrainte prend %s arguments mais %s ont été fournis";
            case convMustHave1RetVal:
                return "une conversion ne peut avoir qu’une seule valeur de retour";
            case convMustHave1Param:
                return "une conversion ne peut avoir qu’un seul paramètre";
            case expected1ParamFoundX:
                return "1 paramètre attendu, %s paramètre trouvé";
            case expected1ParamFoundXs:
                return "1 paramètre attendu, %s paramètres trouvés";
            case missingCurlyBraces:
                return "accolades manquantes";
            case expectedIntFoundX:
                return "entier attendu, `%s` trouvé";
            case deferInsideDefer:
                return "`defer` à l’intérieur d’un autre `defer`";
            case cantDeferInsideDefer:
                return "impossible de faire un `defer` dans un autre `defer`";
            case xInsideDefer:
                return "`%s` à l’intérieur d’un `defer`";
            case cantXInsideDefer:
                return "impossible de faire un `%s` dans un `defer`";
            case breakOutsideLoop:
                return "`break` en dehors d’une boucle";
            case cantBreakOutsideLoop:
                return "impossible de `break` en dehors d’une boucle";
            case continueOutsideLoop:
                return "`continue` en dehors d’une boucle";
            case cantContinueOutsideLoop:
                return "impossible de `continue` en dehors d’une boucle";
            case xNotValidRetType:
                return "`%s` n’est pas un type de retour valide";
            case chanSizeMustBePositive:
                return "la taille d’un canal doit être un entier positif";
            case listSizeMustBePositive:
                return "la taille d’une liste doit être un entier positif";
            case missingCommaOrGreaterInsideChanSignature:
                return "`,` ou `)` manquant dans la signature du canal";
            case missingCommaOrGreaterInsideListSignature:
                return "`,` ou `)` manquant dans la signature de la liste";
            case missingXInChanSignature:
                return "`%s` manquantes après la signature du canal";
            case missingXInListSignature:
                return "`%s` manquantes après la signature de la liste";
            case missingXInNullSignature:
                return "`%s` manquantes après la signature du type nul";
            case chanSizeMustBeOneOrHigher:
                return "la taille du canal doit être de un ou plus";
            case listSizeMustBeZeroOrHigher:
                return "la taille d’une liste doit être supérieure à zéro";
            case expectedAtLeastSizeOf1FoundX:
                return "une taille de 1 minimum attendue, %s trouvé";
            case expectedCommaOrGreaterFoundX:
                return "`,` ou `>` attendu, `%s` trouvé";
            case chanCantBeOfTypeX:
                return "un canal ne peut être de type `%s`";
            case missingParenthesesAfterX:
                return "parenthèses manquantes après `%s`";
            case missingCommaInX:
                return "virgule manquante dans `%s`";
            case onlyOneDefaultCasePerX:
                return "il ne peut y avoir un maximum d’un cas par défaut dans un `%s`";
            case defaultCaseAlreadyDef:
                return "le cas par défaut a déjà été défini";
            case prevDefaultCaseDef:
                return "précédente définition du cas par défaut";
            case missingWhileOrUntilAfterLoop:
                return "`tant` ou `jusque` manquant après la boucle";
            case expectedWhileOrUntilFoundX:
                return "`tant` ou `jusque` attendu, `%s` trouvé";
            case listCantBeOfTypeX:
                return "une liste ne peut pas être de type `%s`";
            case primXMustRetOptional:
                return "la primitive `%s` doit retourner un type optionnel";
            case signatureMismatch:
                return "la signature ne correspond pas";
            case funcXMustRetOptional:
                return "la function `%s` doit retourner un type optionnel";
            case notIterable:
                return "non-itérable";
            case forCantIterateOverX:
                return "for ne peut itérer sur `%s`";
            case cantEvalArityUnknownCompound:
                return "impossible de calculer l’arité d’un composé inconnu";
            case arityEvalError:
                return "erreur de calcul d’arité";
            case typeOfIteratorMustBeIntNotX:
                return "le type d’un itérateur doit être un entier, pas `%s`";
            case iteratorMustBeInt:
                return "l’itérateur doit être un entier";
            case mismatchedNumRetVal:
                return "le nombre de valeur de retour ne correspond pas";
            case expectedXRetValFoundY:
                return "%s valeur de retour attendue, %s trouvé";
            case expectedXRetValsFoundY:
                return "%s valeurs de retour attendues, %s trouvé";
            case retSignatureOfTypeX:
                return "la signature de retour est `%s`";
            case retTypeXNotMatchSignatureY:
                return "le type retourné `%s` ne correspond pas avec la signature `%s`";
            case expectedXVal:
                return "type `%s` attendu";
            case opNotListedInOpPriorityTable:
                return "l’opérateur n’est pas listé dans la liste de priorité d’opérateurs";
            case mismatchedTypes:
                return "types différents";
            case missingX:
                return "`%s` manquant";
            case xNotClassType:
                return "`%s` n’est pas un type de classe";
            case fieldXInitMultipleTimes:
                return "le champ `%s` est initialisé plusieurs fois";
            case xAlreadyInit:
                return "`%s` est déjà initialisé";
            case prevInit:
                return "initialisation précédente";
            case fieldXNotExist:
                return "le champ `%s` n’existe pas";
            case expectedFieldNameFoundX:
                return "nom de champ attendu, `%s` trouvé";
            case missingField:
                return "champ manquant";
            case indexesShouldBeSeparatedByComma:
                return "les index doivent être séparés par une virgule";
            case missingVal:
                return "valeur manquante";
            case expectedIndexFoundComma:
                return "un index est attendu, `,` trouvé";
            case expectedIntFoundNothing:
                return "entier attendu, rien de trouvé";
            case noValToConv:
                return "aucune valeur à convertir";
            case expectedVarFoundX:
                return "variable attendu, `%s` trouvé";
            case missingVar:
                return "variable manquante";
            case exprYieldsNoVal:
                return "l’expression ne rend aucune valeur";
            case expectedValFoundNothing:
                return "valeur attendue, rien de trouvé";
            case missingSemicolonAfterExprList:
                return "`;` manquant après la liste d’expressions";
            case tryingAssignXValsToYVar:
                return "tentative d’assigner `%s` valeurs à %s variable";
            case tryingAssignXValsToYVars:
                return "tentative d’assigner `%s` valeurs à %s variables";
            case moreValThanVarToAssign:
                return "il y a plus de valeurs que de variables auquels affecter";
            case assignationMissingVal:
                return "il manque une valeur à l’assignation";
            case expressionEmpty:
                return "l’expression est vide";
            case firstValOfAssignmentListCantBeEmpty:
                return "la première valeur d’une liste d’assignation ne peut être vide";
            case cantInferTypeWithoutAssignment:
                return "impossible d’inférer le type sans assignation";
            case missingTypeInfoOrInitVal:
                return "information de type ou valeur initiale manquante";
            case missingSemicolonAfterAssignmentList:
                return "`;` manquant après la liste d’assignation";
            case missingSemicolonAfterX:
                return "`;` manquant après `%s`";
            case typeXHasNoDefaultVal:
                return "le type `%s` n’a pas de valeur par défaut";
            case cantInitThisType:
                return "impossible d’initialiser ce type";
            case expectedFuncNameFoundX:
                return "nom de fonction attendu, `%s` trouvé";
            case missingFuncName:
                return "nom de fonction manquant";
            case cantInferTypeOfX:
                return "impossible d’inférer le type de `%s`";
            case funcTypeCantBeInferred:
                return "le type de la fonction ne peut pas être inféré";
            case unexpectedXFoundInExpr:
                return "`%s` inattendu dans l’expression";
            case xCantExistInsideThisExpr:
                return "un `%s` ne peut exister dans l’expression";
            case methodCallMustBePlacedAfterVal:
                return "un appel de méthode doit se placer après une valeur";
            case listCantBeIndexedByX:
                return "une liste ne peut pas être indexé par un `%s`";
            case cantAccessFieldOnTypeX:
                return "impossible d’accéder à un champ sur `%s`";
            case expectedClassFoundX:
                return "classe attendue, `%s` trouvé";
            case xOnTypeYIsPrivate:
                return "`%s` du type `%s` est privé";
            case privateField:
                return "champ privé";
            case noFieldXOnTypeY:
                return "aucun champ `%s` dans `%s`";
            case availableFieldsAreX:
                return "les champs disponibles sont: %s";
            case missingParamOnMethodCall:
                return "paramètre manquant dans l’appel de méthode";
            case xMustBePlacedAfterVal:
                return "`%s` doit être placé après une valeur";
            case xMustBeInsideFuncOrTask:
                return "`%s` doit être à l’intérieur d’une fonction ou d’une tâche";
            case xRefNoFuncNorTask:
                return "`%s` ne référence aucune fonction ou tâche";
            case valBeforeAssignationNotReferenceable:
                return "la valeur devant l’assignation n’est pas référençable";
            case missingRefBeforeAssignation:
                return "référence manquante avant l’assignation";
            case cantDoThisKindOfOpOnLeftSideOfAssignement:
                return "ce genre d’opération est impossible à gauche d’une assignation";
            case unexpectedOp:
                return "opération inattendue";
            case unOpMustHave1Operand:
                return "une opération unaire doit avoir 1 opérande";
            case binOpMustHave2Operands:
                return "une opération binaire doit avoir 2 opérandes";
            case unexpectedXSymbolInExpr:
                return "symbole `%s` inattendu dans l’expression";
            case unexpectedSymbol:
                return "symbole inattendu";
            case missingSemicolonAtEndOfExpr:
                return "`;` manquant en fin d’expression";
            case cantLoadFieldOfTypeX:
                return "impossible de charger un champ de type `%s`";
            case fieldTypeIsInvalid:
                return "le type de champ est invalide";
            case xNotCallable:
                return "`%s` n’est pas appelable";
            case xNotFuncNorTask:
                return "`%s` n’est ni une fonction ni une tâche";
            case funcTakesXArgButMoreWereSupplied:
                return "cette fonction prend %s argument mais plus ont été fournis";
            case funcTakesXArgsButMoreWereSupplied:
                return "cette fonction prend %s arguments mais plus ont été fournis";
            case funcIsOfTypeX:
                return "cette fonction est de type `%s`";
            case expectedXArg:
                return "%s argument attendu";
            case expectedXArgs:
                return "%s arguments attendus";
            case funcTakesXArgButYWereSupplied:
                return "cette fonction prend %s argument mais %s ont été fournis";
            case funcTakesXArgsButYWereSupplied:
                return "cette fonction prend %s arguments mais %s ont été fournis";
            case expectedXArgFoundY:
                return "%s argument attendu, %s trouvé";
            case expectedXArgsFoundY:
                return "%s arguments attendus, %s trouvé";
            case funcOrTaskExpectedFoundX:
                return "fonction ou tâche attendu, `%s` trouvé";
            case funcDefHere:
                return "fonction définie là";
            case cantInferEnum:
                return "impossible d’inférer le type de l’énumération";
            case expectedDotAfterEnumType:
                return "`.` attendu après le type de l’énumération";
            case missingEnumConstantName:
                return "nom du champ de l’énumération attendu";
            case missingEnumConstantValue:
                return "valeur du champ de l’énumération attendue";
            case expectedConstNameAfterEnumType:
                return "nom du champ attendu après le type de l’énumération";
            case xIsAbstract:
                return "`%s` est abstrait";
            case xIsAbstractAndCannotBeInstanciated:
                return "`%s` est abstrait et ne peut pas être instancié";
            case expectedOptionalType:
                return "`?` nécessite un type optionnel";
            case opMustFollowAnOptionalType:
                return "`?` doit être placé après le type optionnel à déballer";
            case cantConvertXToY:
                return "impossible de convertir `%s` en `%s`";
            case noConvAvailable:
                return "aucune conversion disponible";
            }
        }
    }
}

/// Décrit une erreur syntaxique
package final class GrParserException : GrCompilerException {
    GrError error;

    this(GrError error_, string file = __FILE__, size_t line = __LINE__) {
        super(error_.message, file, line);
        error = error_;
    }
}
