/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.runtime.engine;

import std.string;
import std.array;
import std.conv;
import std.math;
import std.algorithm.mutation : swapAt;
import std.typecons : Nullable;
import std.exception : enforce;

import grimoire.compiler;
import grimoire.assembly;
import grimoire.runtime.call;
import grimoire.runtime.channel;
import grimoire.runtime.closure;
import grimoire.runtime.error;
import grimoire.runtime.event;
import grimoire.runtime.list;
import grimoire.runtime.object;
import grimoire.runtime.string;
import grimoire.runtime.task;
import grimoire.runtime.value;

/// La machine virtuelle de grimoire
class GrEngine {
    private {
        /// Le bytecode
        GrBytecode _bytecode;

        /// Les variables globales
        GrValue[] _globals;

        /// La pile globale
        GrValue[] _globalStack;

        /// Liste des tâche en exécution
        GrTask[] _tasks;

        /// Empêche la création de nouvelles tâches après un exit
        bool _allowEventCall;

        /// État de panique global
        /// Signifie que la tâche impliquée n’a pas correctement géré son exception
        bool _isPanicking;
        /// Message de panique non-géré
        string _panicMessage;
        /// Les traces d’appel sont générés chaque fois qu’une erreur est lancé
        GrStackTrace[] _stackTraces;

        /// Primitives
        GrCallback[] _callbacks;
        /// Ditto
        GrCall[] _calls;

        /// Version
        uint _userVersion;

        /// Classes
        GrClassBuilder[string] _classBuilders;

        /// Sortie par défaut
        void function(string) _stdOut = &_defaultOutput;
    }

    enum Priority {
        immediate,
        normal
    }

    /// Moyen externe d’arrêter la machine virtuelle
    shared bool isRunning = false;

    @property {
        /// Vérifie si une tâche est en cours d’exécution
        bool hasTasks() const {
            return _tasks.length > 0uL;
        }

        /// Est-ce que la machine virtuelle est en panique ?
        bool isPanicking() const {
            return _isPanicking;
        }

        /// Si la machine virtuelle a lancé une erreur, des traces d’appel sont générées
        const(GrStackTrace[]) stackTraces() const {
            return _stackTraces;
        }

        /// Le message de panique
        string panicMessage() const {
            return _panicMessage;
        }
    }

    this(uint userVersion = 0u) {
        _userVersion = userVersion;
    }

    /**
    Ajoute une nouvelle bibliothèque.
    ___
    Elle doit être appelé avant de charger le bytecode. \
    Elle doit être identique à celle du compilateur. \
    Et elle doit être appelé dans le même ordre.
    */
    final void addLibrary(GrLibrary library) {
        foreach (loader; library.loaders) {
            GrModuleDef def = new GrModuleDef;
            loader(def);
            _callbacks ~= def._callbacks;
        }
    }

    /// Ditto
    final void addLibrary(string filePath) {
        import core.runtime;

        void* dlib;
        version (Windows) {
            dlib = Runtime.loadLibrary(filePath);
        }
        else version (Posix) {
            import core.sys.posix.dlfcn : dlopen, RTLD_LAZY;

            dlib = dlopen(toStringz(filePath), RTLD_LAZY);
        }

        enforce!GrRuntimeException(dlib, format!"library `%s` not found"(filePath));

        typeof(&_GRLIBSYMBOL) libFunc;

        version (Windows) {
            import core.sys.windows.winbase : GetProcAddress;

            libFunc = cast(typeof(&_GRLIBSYMBOL)) GetProcAddress(dlib,
                toStringz(_GRLIBSYMBOLMANGLED));
        }
        else version (Posix) {
            import core.sys.posix.dlfcn : dlsym;

            libFunc = cast(typeof(&_GRLIBSYMBOL)) dlsym(dlib, toStringz(_GRLIBSYMBOLMANGLED));
        }
        enforce!GrRuntimeException(libFunc, format!"library `%s` is not valid"(filePath));

        GrLibrary library = libFunc();
        foreach (loader; library.loaders) {
            GrModuleDef def = new GrModuleDef;
            loader(def);
            _callbacks ~= def._callbacks;
        }
    }

    /// Charge le bytecode.
    final bool load(GrBytecode bytecode) {
        isRunning = false;

        if (!bytecode.checkVersion(_userVersion)) {
            _bytecode = null;
            return false;
        }

        foreach (filePath; bytecode.libraries) {
            addLibrary(filePath);
        }

        _bytecode = bytecode;
        _globals = new GrValue[_bytecode.globalsCount];
        _tasks ~= new GrTask(this);

        // Prépare les primitives
        for (uint i; i < _bytecode.primitives.length; ++i) {
            enforce!GrRuntimeException(_bytecode.primitives[i].index < _callbacks.length,
                "callback index out of bounds");

            _calls ~= new GrCall(_callbacks[_bytecode.primitives[i].index],
                _bytecode.primitives[i].name, _bytecode.primitives[i]);
        }

        foreach (ref globalRef; _bytecode.variables) {
            const uint typeMask = globalRef.typeMask;
            const uint index = globalRef.index;
            if (typeMask & GR_MASK_INT)
                _globals[index]._intValue = globalRef.intValue;
            else if (typeMask & GR_MASK_UINT)
                _globals[index]._uintValue = globalRef.uintValue;
            else if (typeMask & GR_MASK_FLOAT)
                _globals[index]._floatValue = globalRef.floatValue;
            else if (typeMask & GR_MASK_DOUBLE)
                _globals[index]._doubleValue = globalRef.doubleValue;
            else if (typeMask & GR_MASK_STRING)
                _globals[index]._ptrValue = cast(GrPointer) new GrString(globalRef.strValue);
            else if (typeMask & GR_MASK_POINTER)
                _globals[index]._ptrValue = null;
        }

        // Indexe les classes
        for (size_t index; index < _bytecode.classes.length; index++) {
            GrClassBuilder classBuilder = _bytecode.classes[index];
            _classBuilders[classBuilder.name] = classBuilder;
        }

        isRunning = true;
        _allowEventCall = true;
        return true;
    }

    /// Vérifie si un événément existe
    bool hasEvent(const string name, const GrType[] signature = []) const {
        const string mangledName = grMangleComposite(name, signature);
        return (mangledName in _bytecode.events) !is null;
    }

    /// Récupère la liste des événements du bytecode. \
    /// Les noms sont sous la forme décorée.
    string[] getEvents() {
        return _bytecode.events.keys;
    }

    /// Récupère un événement à l’adresse indiqué. \
    /// Si l’adresse ne correspond à aucun événement, il ne sera pas retourné.
    GrEvent getEvent(GrClosure closure) const {
        foreach (string name, uint address; _bytecode.events) {
            if (address == closure.pc)
                return new GrEvent(name, address, closure);
        }
        return null;
    }

    /// Récupère l’événement correspondant au nom indiqué.
    GrEvent getEvent(const string name_, const GrType[] signature = []) const {
        const string mangledName = grMangleComposite(name_, signature);
        foreach (string name, uint address; _bytecode.events) {
            if (mangledName == name)
                return new GrEvent(name, address, null);
        }
        return null;
    }

    /**
    Crée une nouvelle tâche à partir d’un événement.
    ---
    event monÉvénement() {
        print("Bonjour!");
    }
    ---
    */
    GrTask callEvent(const string name, const GrType[] signature = [], GrValue[] parameters = [
        ]) {

        if (!isRunning || !_allowEventCall)
            return null;

        const string mangledName = grMangleComposite(name, signature);
        const auto event = mangledName in _bytecode.events;

        if (event is null)
            return null;

        enforce!GrRuntimeException(signature.length == parameters.length,
            "the number of parameters (" ~ to!string(
                parameters.length) ~ ") of `" ~ grGetPrettyFunctionCall(
                mangledName) ~ "` mismatch its definition");

        GrTask task = new GrTask(this);
        task.pc = *event;

        if (parameters.length > task.stack.length)
            task.stack.length = parameters.length;

        for (size_t i; i < parameters.length; ++i)
            task.stack[i] = parameters[i];
        task.stackPos = (cast(int) parameters.length) - 1;

        _tasks ~= task;
        return task;
    }

    /// Ditto
    GrTask callEvent(GrEvent event, GrValue[] parameters = []) {
        if (!isRunning || !_allowEventCall || event is null)
            return null;

        enforce!GrRuntimeException(event.signature.length == parameters.length,
            "the number of parameters (" ~ to!string(
                parameters.length) ~ ") of `" ~ grGetPrettyFunctionCall(event.name,
                event.signature) ~ "` mismatch its definition");

        GrTask task = new GrTask(this);
        task.pc = event.address;

        if (parameters.length > task.stack.length)
            task.stack.length = parameters.length;

        for (size_t i; i < parameters.length; ++i)
            task.stack[i] = parameters[i];
        task.stackPos = (cast(int) parameters.length) - 1;
        task.closure = event.closure;

        _tasks ~= task;
        return task;
    }

    /// Capture une erreur non-géré et tue la machine virtuelle
    void panic() {
        _tasks.length = 0;
    }

    /// Génère les traces d’appel de la tâche
    private void generateStackTrace(GrTask task) {
        {
            GrStackTrace trace;
            trace.pc = task.pc;
            auto func = getFunctionInfo(task.pc);
            if (func.isNull) {
                trace.name = "?";
            }
            else {
                trace.name = func.get.name;
                trace.file = func.get.file;
                uint index = cast(uint)(cast(int) trace.pc - cast(int) func.get.start);
                if (index < 0 || index >= func.get.positions.length) {
                    trace.line = 0;
                    trace.column = 0;
                }
                else {
                    auto position = func.get.positions[index];
                    trace.line = position.line;
                    trace.column = position.column;
                }
            }
            _stackTraces ~= trace;
        }

        for (int i = task.stackFramePos - 1; i >= 0; i--) {
            GrStackTrace trace;
            trace.pc = cast(uint)((cast(int) task.callStack[i].retPosition) - 1);
            auto func = getFunctionInfo(trace.pc);
            if (func.isNull) {
                trace.name = "?";
            }
            else {
                trace.name = func.get.name;
                trace.file = func.get.file;
                uint index = cast(uint)(cast(int) trace.pc - cast(int) func.get.start);
                if (index < 0 || index >= func.get.positions.length) {
                    trace.line = 1;
                    trace.column = 0;
                }
                else {
                    auto position = func.get.positions[index];
                    trace.line = position.line;
                    trace.column = position.column;
                }
            }
            _stackTraces ~= trace;
        }
    }

    /// Essaye de récupérer le symbole d’une fonction depuis sa position dans le bytecode
    private Nullable!(GrFunctionSymbol) getFunctionInfo(uint position) {
        Nullable!(GrFunctionSymbol) bestInfo;
        foreach (const GrSymbol symbol; _bytecode.symbols) {
            if (symbol.type == GrSymbol.Type.func) {
                auto info = cast(GrFunctionSymbol) symbol;
                if (info.start <= position && info.start + info.length > position) {
                    if (bestInfo.isNull) {
                        bestInfo = info;
                    }
                    else {
                        if (bestInfo.get.length > info.length) {
                            bestInfo = info;
                        }
                    }
                }
            }
        }
        return bestInfo;
    }

    /**
    Lance une erreur depuis une tâche et lance la procédure de récupération.
    ___
    Pour chaque fonction remonté, on cherche un `try/catch` qui l’englobe. \
    Si aucun n’est trouvé, chaque `defer` dans la fonction est exécuté et \
    ainsi de suite pour la prochaine fonction dans la pile d’appel.
    ___
    Si rien ne permet la capture de l’erreur dans la tâche, la machine virtuelle entrera en panique. \
    Chaque tâche exécura ses propres `defer` et sera tué.
    */
    void raise(GrTask task, string message) {
        if (task.isPanicking)
            return;

        // Message d’erreur
        _globalStack ~= GrValue(message);

        generateStackTrace(task);

        // On indique que la tâche est en panique jusqu’à ce qu’un `catch` est trouvé
        task.isPanicking = true;

        if (task.callStack.length && task.callStack[task.stackFramePos].exceptionHandlers.length) {
            // Un gestionnaire d’erreur a été trouvé dans la fonction, on y va
            task.pc = task.callStack[task.stackFramePos].exceptionHandlers[$ - 1];
        }
        else {
            // Aucun gestionnaire d’erreur de trouvé dans la fonction,
            // on déroule le code différé, puis on quitte la fonction.
            task.pc = cast(uint)(cast(int) _bytecode.opcodes.length - 1);
        }
    }

    /// Marque toutes les tâches comme morte et empêche toute nouvelle tâche d’être créée
    private void killTasks() {
        foreach (task; _tasks) {
            task.pc = cast(uint)(cast(int) _bytecode.opcodes.length - 1);
            task.isKilled = true;
        }
        _allowEventCall = false;
    }

    /// Signale la tâche comme morte
    void killTask(GrTask task) {
        if (task.engine != this)
            return;
        task.pc = cast(uint)(cast(int) _bytecode.opcodes.length - 1);
        task.isKilled = true;
    }

    alias getBoolVariable = getVariable!bool;
    alias getIntVariable = getVariable!GrInt;
    alias getUIntVariable = getVariable!GrUInt;
    alias getCharVariable = getVariable!GrChar;
    alias getByteVariable = getVariable!GrByte;
    alias getFloatVariable = getVariable!GrFloat;
    alias getDoubleVariable = getVariable!GrDouble;
    alias getPointerVariable = getVariable!GrPointer;

    pragma(inline) T getEnumVariable(T)(string name) const {
        return cast(T) getVariable!GrInt(name);
    }

    pragma(inline) GrString getStringVariable(string name) const {
        return cast(GrString) getVariable!GrPointer(name);
    }

    pragma(inline) GrList getListVariable(string name) const {
        return cast(GrList) getVariable!GrPointer(name);
    }

    pragma(inline) GrTask getTaskVariable(string name) const {
        return cast(GrTask) getVariable!GrPointer(name);
    }

    pragma(inline) GrChannel getChannelVariable(string name) const {
        return cast(GrChannel) getVariable!GrPointer(name);
    }

    pragma(inline) GrObject getObjectVariable(string name) const {
        return cast(GrObject) getVariable!GrPointer(name);
    }

    pragma(inline) T getNativeVariable(T)(string name) const {
        // On change en objet d’abord pour éviter un plantage en changeant pour une classe mère
        return cast(T) cast(Object) getVariable!GrPointer(name);
    }

    pragma(inline) private T getVariable(T)(string name) const {
        const auto variable = name in _bytecode.variables;
        enforce!GrRuntimeException(variable, "no global variable `" ~ name ~ "` defined");

        static if (is(T == GrInt)) {
            return _globals[variable.index]._intValue;
        }
        else static if (is(T == GrUInt)) {
            return _globals[variable.index]._uintValue;
        }
        else static if (is(T == GrChar)) {
            return cast(GrChar) _globals[variable.index]._uintValue;
        }
        else static if (is(T == GrByte)) {
            return _globals[variable.index]._byteValue;
        }
        else static if (is(T == GrBool)) {
            return _globals[variable.index]._intValue > 0;
        }
        else static if (is(T == GrFloat)) {
            return _globals[variable.index]._floatValue;
        }
        else static if (is(T == GrDouble)) {
            return _globals[variable.index]._doubleValue;
        }
        else static if (is(T == GrDouble)) {
            return _globals[variable.index]._doubleValue;
        }
        else static if (is(T == GrPointer)) {
            return cast(GrPointer) _globals[variable.index]._ptrValue;
        }
    }

    alias setBoolVariable = setVariable!GrBool;
    alias setIntVariable = setVariable!GrInt;
    alias setUIntVariable = setVariable!GrUInt;
    alias setCharVariable = setVariable!GrChar;
    alias setByteVariable = setVariable!GrByte;
    alias setFloatVariable = setVariable!GrFloat;
    alias setDoubleVariable = setVariable!GrDouble;
    alias setPointerVariable = setVariable!GrPointer;

    pragma(inline) void setEnumVariable(T)(string name, T value) {
        setVariable!GrInt(name, cast(GrInt) value);
    }

    pragma(inline) void setStringVariable(string name, string value) {
        setVariable!GrPointer(name, cast(GrPointer) new GrString(value));
    }

    pragma(inline) void setListVariable(string name, GrList value) {
        setVariable!GrPointer(name, cast(GrPointer) value);
    }

    pragma(inline) void setListVariable(string name, GrValue[] value) {
        setVariable!GrPointer(name, cast(GrPointer) new GrList(value));
    }

    pragma(inline) void setTaskVariable(string name, GrTask value) {
        setVariable!GrPointer(name, cast(GrPointer) value);
    }

    pragma(inline) void setChannelVariable(string name, GrChannel value) {
        setVariable!GrPointer(name, cast(GrPointer) value);
    }

    pragma(inline) void setObjectVariable(string name, GrObject value) {
        setVariable!GrPointer(name, cast(GrPointer) value);
    }

    pragma(inline) void setNativeVariable(T)(string name, T value) {
        setVariable!GrPointer(name, *cast(GrPointer*)&value);
    }

    pragma(inline) private void setVariable(T)(string name, T value) {
        const auto variable = name in _bytecode.variables;
        enforce!GrRuntimeException(variable, "no global variable `" ~ name ~ "` defined");

        static if (is(T == GrInt) || is(T == GrBool)) {
            _globals[variable.index]._intValue = value;
        }
        else static if (is(T == GrUInt) || is(T == GrChar)) {
            _globals[variable.index]._uintValue = value;
        }
        else static if (is(T == GrByte)) {
            _globals[variable.index]._byteValue = value;
        }
        else static if (is(T == GrFloat)) {
            _globals[variable.index]._floatValue = value;
        }
        else static if (is(T == GrDouble)) {
            _globals[variable.index]._doubleValue = value;
        }
        else static if (is(T == GrDouble)) {
            _globals[variable.index]._doubleValue = value;
        }
        else static if (is(T == GrPointer)) {
            _globals[variable.index]._ptrValue = value;
        }
    }

    /// Exécute la machine virtuelle jusqu’à ce que toutes les tâches finissent ou soient suspendues
    void process() {
        import std.algorithm.mutation : remove, swap;

        /*
        if (_createdTasks.length) {
            foreach_reverse (task; _createdTasks)
                _tasks ~= task;
            _createdTasks.length = 0;

            swap(_globalStack, _globalStackOut);
        }*/

        tasksLabel: for (uint index = 0u; index < _tasks.length;) {
            GrTask currentTask = _tasks[index];
            if (currentTask.blocker) {
                if (!currentTask.blocker.run()) {
                    index++;
                    continue;
                }
                currentTask.blocker = null;
            }
            while (isRunning) {
                const uint opcode = _bytecode.opcodes[currentTask.pc];
                final switch (opcode & 0xFF) with (GrOpcode) {
                case nop:
                    currentTask.pc++;
                    break;
                case extend:
                    // On ne doit jamais tomber sur cet opcode directement
                    raise(currentTask, "InvalidOpcode");
                    break;
                case throw_:
                    if (!currentTask.isPanicking) {
                        // Message d’erreur
                        _globalStack ~= currentTask.stack[currentTask.stackPos];
                        currentTask.stackPos--;
                        generateStackTrace(currentTask);

                        // On indique que la tâche est en panique jusqu’à ce qu’un `catch` est trouvé
                        currentTask.isPanicking = true;
                    }

                    // Un gestionnaire d’erreur a été trouvé dans la fonction, on y va
                    if (currentTask.callStack[currentTask.stackFramePos].exceptionHandlers.length) {
                        currentTask.pc =
                            currentTask.callStack[currentTask.stackFramePos]
                            .exceptionHandlers[$ - 1];
                    } // Aucun gestionnaire d’erreur de trouvé dans la fonction,
                    // on déroule le code différé, puis on quitte la fonction.

                    // On vérifie les appel différés puisqu’on va quitter la fonction
                    else if (currentTask.callStack[currentTask.stackFramePos].deferStack.length) {
                        // Dépile le dernier `defer` et l’exécute
                        currentTask.pc =
                            currentTask.callStack[currentTask.stackFramePos].deferStack[$ - 1];
                        currentTask.callStack[currentTask.stackFramePos].deferStack.length--;
                        // La recherche d’un gestionnaire d’erreur sera fait par l’`unwind`
                        // après que tous les `defer` aient été appelé dans cette fonction
                    }
                    else if (currentTask.stackFramePos) {
                        // Puis on quitte vers la fonction précédente,
                        // `raise` sera de nouveau exécuté
                        currentTask.stackFramePos--;
                        currentTask.localsPos -=
                            currentTask.callStack[currentTask.stackFramePos].localStackSize;

                        if (_isDebug)
                            _debugProfileEnd();
                    }
                    else {
                        // On tue les autres tâches
                        killTasks();

                        // La machine virtuelle est maintenant en panique
                        _isPanicking = true;
                        _panicMessage = (cast(GrString) _globalStack[$ - 1]._ptrValue).str;
                        _globalStack.length--;

                        // Tous les appels différés ont été exécuté, on tue la tâche
                        _tasks = _tasks.remove(index);
                        continue tasksLabel;
                    }
                    break;
                case try_:
                    currentTask.callStack[currentTask.stackFramePos].exceptionHandlers ~=
                        currentTask.pc + grGetInstructionSignedValue(opcode);
                    currentTask.pc++;
                    break;
                case catch_:
                    currentTask.callStack[currentTask.stackFramePos].exceptionHandlers.length--;
                    if (currentTask.isPanicking) {
                        currentTask.isPanicking = false;
                        _stackTraces.length = 0;
                        currentTask.pc++;
                    }
                    else {
                        currentTask.pc += grGetInstructionSignedValue(opcode);
                    }
                    break;
                case task:
                    const uint pc = grGetInstructionUnsignedValue(opcode);

                    // Cet opcode est forcément suivi de extend
                    const uint size = grGetInstructionUnsignedValue(
                        _bytecode.opcodes[currentTask.pc + 1]);

                    GrTask nTask = new GrTask(this, size + 4);
                    nTask.pc = pc;
                    _tasks ~= nTask;

                    currentTask.stackPos++;
                    currentTask.stackPos -= size;
                    nTask.stack[0 .. size] =
                        currentTask.stack[currentTask.stackPos .. currentTask.stackPos + size];
                    nTask.stackPos = (cast(int) size) - 1;

                    currentTask.stack[currentTask.stackPos]._ptrValue = cast(GrPointer) nTask;

                    currentTask.pc += 2;
                    break;
                case anonymousTask:
                    // Cet opcode est forcément suivi de extend
                    const uint size = grGetInstructionUnsignedValue(
                        _bytecode.opcodes[currentTask.pc + 1]);

                    GrTask nTask = new GrTask(this, size + 4);

                    currentTask.stackPos -= size;
                    GrClosure closure = cast(GrClosure) currentTask
                        .stack[currentTask.stackPos]._ptrValue;
                    nTask.pc = closure.pc;

                    if (closure.caller) {
                        nTask.closure = closure;
                    }
                    _tasks ~= nTask;

                    nTask.stack[0 .. size] =
                        currentTask.stack[currentTask.stackPos + 1 .. currentTask.stackPos + 1 +
                            size];
                    nTask.stackPos = (cast(int) size) - 1;

                    currentTask.stack[currentTask.stackPos]._ptrValue = cast(GrPointer) nTask;
                    currentTask.pc += 2;
                    break;
                case self:
                    currentTask.stackPos++;
                    currentTask.stack[currentTask.stackPos]._ptrValue = cast(GrPointer) currentTask;
                    currentTask.pc++;
                    break;
                case die:
                    // On vérifie les appel différés
                    if (currentTask.callStack[currentTask.stackFramePos].deferStack.length) {
                        // Dépile le dernier `defer` et l’exécute
                        currentTask.pc =
                            currentTask.callStack[currentTask.stackFramePos].deferStack[$ - 1];
                        currentTask.callStack[currentTask.stackFramePos].deferStack.length--;

                        // On marque la tâche comme morte afin que la pile soit déroulée
                        currentTask.isKilled = true;
                    }
                    else if (currentTask.stackFramePos) {
                        // Puis on retourne à la fonction précédente sans modifier le pointeur d’instruction
                        currentTask.stackFramePos--;
                        currentTask.localsPos -=
                            currentTask.callStack[currentTask.stackFramePos].localStackSize;

                        // On marque la tâche comme morte afin que la pile soit déroulée
                        currentTask.isKilled = true;
                    }
                    else {
                        // il y a plus rien à faire, on tue la tâche
                        currentTask.isKilled = true;
                        _tasks = _tasks.remove(index);
                        continue tasksLabel;
                    }
                    break;
                case exit:
                    killTasks();
                    index++;
                    continue tasksLabel;
                case yield:
                    currentTask.pc++;
                    index++;
                    continue tasksLabel;
                case new_:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos]._ptrValue = cast(GrPointer) new GrObject(
                        _bytecode.classes[grGetInstructionUnsignedValue(opcode)]);
                    currentTask.pc++;
                    break;
                case channel:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos]._ptrValue = cast(
                        GrPointer) new GrChannel(grGetInstructionUnsignedValue(opcode));
                    currentTask.pc++;
                    break;
                case send:
                    GrChannel chan = cast(GrChannel) currentTask
                        .stack[currentTask.stackPos - 1]._ptrValue;
                    if (!chan.isOwned) {
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isLocked = true;
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            currentTask.stackPos -= 2;
                            raise(currentTask, "ChannelError");
                        }
                    }
                    else if (chan.canSend) {
                        currentTask.isLocked = false;
                        chan.send(currentTask.stack[currentTask.stackPos]);
                        currentTask.stack[currentTask.stackPos - 1] =
                            currentTask.stack[currentTask.stackPos];
                        currentTask.stackPos--;
                        currentTask.pc++;
                    }
                    else {
                        currentTask.isLocked = true;
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            index++;
                            continue tasksLabel;
                        }
                    }
                    break;
                case receive:
                    GrChannel chan = cast(GrChannel) currentTask
                        .stack[currentTask.stackPos]._ptrValue;
                    if (!chan.isOwned) {
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isLocked = true;
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            currentTask.stackPos--;
                            raise(currentTask, "ChannelError");
                        }
                    }
                    else if (chan.canReceive) {
                        currentTask.isLocked = false;
                        currentTask.stack[currentTask.stackPos] = chan.receive();
                        currentTask.pc++;
                    }
                    else {
                        chan.setReceiverReady();
                        currentTask.isLocked = true;
                        if (currentTask.isEvaluatingChannel) {
                            currentTask.restoreState();
                            currentTask.isEvaluatingChannel = false;
                            currentTask.pc = currentTask.selectPositionJump;
                        }
                        else {
                            index++;
                            continue tasksLabel;
                        }
                    }
                    break;
                case startSelectChannel:
                    currentTask.pushState();
                    currentTask.pc++;
                    break;
                case endSelectChannel:
                    currentTask.popState();
                    currentTask.pc++;
                    break;
                case tryChannel:
                    if (currentTask.isEvaluatingChannel)
                        raise(currentTask, "SelectError");
                    currentTask.isEvaluatingChannel = true;
                    currentTask.selectPositionJump = currentTask.pc + grGetInstructionSignedValue(
                        opcode);
                    currentTask.pc++;
                    break;
                case checkChannel:
                    if (!currentTask.isEvaluatingChannel)
                        raise(currentTask, "SelectError");
                    currentTask.isEvaluatingChannel = false;
                    currentTask.restoreState();
                    currentTask.pc++;
                    break;
                case shiftStack:
                    currentTask.stackPos += grGetInstructionSignedValue(opcode);
                    currentTask.pc++;
                    break;
                case localStore:
                    currentTask.locals[currentTask.localsPos + grGetInstructionUnsignedValue(
                            opcode)] = currentTask.stack[currentTask.stackPos];
                    currentTask.stackPos--;
                    currentTask.pc++;
                    break;
                case localStore2:
                    currentTask.locals[currentTask.localsPos + grGetInstructionUnsignedValue(
                            opcode)] = currentTask.stack[currentTask.stackPos];
                    currentTask.pc++;
                    break;
                case localLoad:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos] =
                        currentTask.locals[currentTask.localsPos + grGetInstructionUnsignedValue(
                                opcode)];
                    currentTask.pc++;
                    break;
                case globalStore:
                    _globals[grGetInstructionUnsignedValue(opcode)] = currentTask
                        .stack[currentTask.stackPos];
                    currentTask.stackPos--;
                    currentTask.pc++;
                    break;
                case globalStore2:
                    _globals[grGetInstructionUnsignedValue(opcode)] = currentTask
                        .stack[currentTask.stackPos];
                    currentTask.pc++;
                    break;
                case globalLoad:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos] = _globals[grGetInstructionUnsignedValue(
                            opcode)];
                    currentTask.pc++;
                    break;
                case refStore:
                    *(cast(GrValue*) currentTask.stack[currentTask.stackPos - 1]._ptrValue) = currentTask
                        .stack[currentTask.stackPos];
                    currentTask.stackPos -= 2;
                    currentTask.pc++;
                    break;
                case refStore2:
                    *(cast(GrValue*) currentTask.stack[currentTask.stackPos - 1]._ptrValue) = currentTask
                        .stack[currentTask.stackPos];
                    currentTask.stack[currentTask.stackPos - 1] =
                        currentTask.stack[currentTask.stackPos];
                    currentTask.stackPos--;
                    currentTask.pc++;
                    break;
                case fieldRefStore:
                    currentTask.stackPos--;
                    (cast(GrField) currentTask.stack[currentTask.stackPos]._ptrValue).value =
                        currentTask.stack[currentTask.stackPos + 1];
                    currentTask.stack[currentTask.stackPos] =
                        currentTask.stack[currentTask.stackPos + 1];
                    currentTask.stackPos += grGetInstructionSignedValue(opcode);
                    currentTask.pc++;
                    break;
                case fieldRefLoad:
                    if (!currentTask.stack[currentTask.stackPos]._ptrValue) {
                        raise(currentTask, "NullError");
                        break;
                    }
                    currentTask.stack[currentTask.stackPos]._ptrValue = cast(GrPointer)(
                        (cast(GrObject) currentTask.stack[currentTask.stackPos]._ptrValue)
                            ._fields[grGetInstructionUnsignedValue(opcode)]);
                    currentTask.pc++;
                    break;
                case fieldRefLoad2:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos]._ptrValue = cast(GrPointer)(
                        (cast(GrObject) currentTask.stack[currentTask.stackPos - 1]._ptrValue)
                            ._fields[grGetInstructionUnsignedValue(opcode)]);
                    currentTask.pc++;
                    break;
                case fieldLoad:
                    if (!currentTask.stack[currentTask.stackPos]._ptrValue) {
                        raise(currentTask, "NullError");
                        break;
                    }
                    currentTask.stack[currentTask.stackPos] = (cast(
                            GrObject) currentTask.stack[currentTask.stackPos]._ptrValue)
                        ._fields[grGetInstructionUnsignedValue(opcode)].value;
                    currentTask.pc++;
                    break;
                case fieldLoad2:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    GrField field = (cast(
                            GrObject) currentTask.stack[currentTask.stackPos - 1]._ptrValue)
                        ._fields[grGetInstructionUnsignedValue(opcode)];
                    currentTask.stack[currentTask.stackPos] = field.value;
                    currentTask.stack[currentTask.stackPos - 1]._ptrValue = cast(GrPointer) field;
                    currentTask.pc++;
                    break;
                case parentStore:
                    currentTask.stackPos--;
                    GrObject obj = cast(GrObject) currentTask.stack[currentTask.stackPos]._ptrValue;
                    obj._nativeParent = currentTask.stack[currentTask.stackPos + 1]._ptrValue;
                    currentTask.pc++;
                    break;
                case parentLoad:
                    currentTask.stack[currentTask.stackPos]._ptrValue = (cast(
                            GrObject) currentTask.stack[currentTask.stackPos]._ptrValue)
                        ._nativeParent;
                    currentTask.pc++;
                    break;
                case const_int:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        _bytecode.intConsts[grGetInstructionUnsignedValue(opcode)];
                    currentTask.pc++;
                    break;
                case const_uint:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos]._uintValue =
                        _bytecode.uintConsts[grGetInstructionUnsignedValue(opcode)];
                    currentTask.pc++;
                    break;
                case const_byte:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos]._byteValue =
                        _bytecode.byteConsts[grGetInstructionUnsignedValue(opcode)];
                    currentTask.pc++;
                    break;
                case const_float:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos]._floatValue =
                        _bytecode.floatConsts[grGetInstructionUnsignedValue(opcode)];
                    currentTask.pc++;
                    break;
                case const_double:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos]._doubleValue =
                        _bytecode.doubleConsts[grGetInstructionUnsignedValue(opcode)];
                    currentTask.pc++;
                    break;
                case const_bool:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos]._intValue = grGetInstructionUnsignedValue(
                        opcode);
                    currentTask.pc++;
                    break;
                case const_string:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos]._ptrValue = cast(GrPointer) new GrString(
                        _bytecode.strConsts[grGetInstructionUnsignedValue(opcode)]);
                    currentTask.pc++;
                    break;
                case const_null:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos].setNull();
                    currentTask.pc++;
                    break;
                case globalPush:
                    const uint nbParams = grGetInstructionUnsignedValue(opcode);
                    for (uint i = 1u; i <= nbParams; i++)
                        _globalStack ~= currentTask.stack[(currentTask.stackPos - nbParams) + i];
                    currentTask.stackPos -= nbParams;
                    currentTask.pc++;
                    break;
                case globalPop:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos] = _globalStack[$ - 1];
                    _globalStack.length--;
                    currentTask.pc++;
                    break;
                case equal_int:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._intValue ==
                        currentTask.stack[currentTask.stackPos + 1]._intValue;
                    currentTask.pc++;
                    break;
                case equal_uint:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._uintValue ==
                        currentTask.stack[currentTask.stackPos + 1]._uintValue;
                    currentTask.pc++;
                    break;
                case equal_byte:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._byteValue ==
                        currentTask.stack[currentTask.stackPos + 1]._byteValue;
                    currentTask.pc++;
                    break;
                case equal_float:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue = currentTask.stack[currentTask.stackPos]
                        ._floatValue == currentTask.stack[currentTask.stackPos + 1]._floatValue;
                    currentTask.pc++;
                    break;
                case equal_double:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue = currentTask.stack[currentTask.stackPos]
                        ._doubleValue == currentTask.stack[currentTask.stackPos + 1]._doubleValue;
                    currentTask.pc++;
                    break;
                case equal_string:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue = (cast(
                            GrString) currentTask.stack[currentTask.stackPos]._ptrValue).str == (
                        cast(GrString) currentTask.stack[currentTask.stackPos + 1]._ptrValue).str;
                    currentTask.pc++;
                    break;
                case notEqual_int:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._intValue !=
                        currentTask.stack[currentTask.stackPos + 1]._intValue;
                    currentTask.pc++;
                    break;
                case notEqual_uint:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._uintValue !=
                        currentTask.stack[currentTask.stackPos + 1]._uintValue;
                    currentTask.pc++;
                    break;
                case notEqual_byte:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._byteValue !=
                        currentTask.stack[currentTask.stackPos + 1]._byteValue;
                    currentTask.pc++;
                    break;
                case notEqual_float:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue = currentTask.stack[currentTask.stackPos]
                        ._floatValue != currentTask.stack[currentTask.stackPos + 1]._floatValue;
                    currentTask.pc++;
                    break;
                case notEqual_double:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue = currentTask.stack[currentTask.stackPos]
                        ._doubleValue != currentTask.stack[currentTask.stackPos + 1]._doubleValue;
                    currentTask.pc++;
                    break;
                case notEqual_string:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue = (cast(
                            GrString) currentTask.stack[currentTask.stackPos]._ptrValue).str != (
                        cast(GrString) currentTask.stack[currentTask.stackPos + 1]._ptrValue).str;
                    currentTask.pc++;
                    break;
                case greaterOrEqual_int:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._intValue >=
                        currentTask.stack[currentTask.stackPos + 1]._intValue;
                    currentTask.pc++;
                    break;
                case greaterOrEqual_uint:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._uintValue >=
                        currentTask.stack[currentTask.stackPos + 1]._uintValue;
                    currentTask.pc++;
                    break;
                case greaterOrEqual_byte:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._byteValue >=
                        currentTask.stack[currentTask.stackPos + 1]._byteValue;
                    currentTask.pc++;
                    break;
                case greaterOrEqual_float:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue = currentTask.stack[currentTask.stackPos]
                        ._floatValue >= currentTask.stack[currentTask.stackPos + 1]._floatValue;
                    currentTask.pc++;
                    break;
                case greaterOrEqual_double:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue = currentTask.stack[currentTask.stackPos]
                        ._doubleValue >= currentTask.stack[currentTask.stackPos + 1]._doubleValue;
                    currentTask.pc++;
                    break;
                case lesserOrEqual_int:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._intValue <=
                        currentTask.stack[currentTask.stackPos + 1]._intValue;
                    currentTask.pc++;
                    break;
                case lesserOrEqual_uint:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._uintValue <=
                        currentTask.stack[currentTask.stackPos + 1]._uintValue;
                    currentTask.pc++;
                    break;
                case lesserOrEqual_byte:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._byteValue <=
                        currentTask.stack[currentTask.stackPos + 1]._byteValue;
                    currentTask.pc++;
                    break;
                case lesserOrEqual_float:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue = currentTask.stack[currentTask.stackPos]
                        ._floatValue <= currentTask.stack[currentTask.stackPos + 1]._floatValue;
                    currentTask.pc++;
                    break;
                case lesserOrEqual_double:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue = currentTask.stack[currentTask.stackPos]
                        ._doubleValue <= currentTask.stack[currentTask.stackPos + 1]._doubleValue;
                    currentTask.pc++;
                    break;
                case greater_int:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._intValue >
                        currentTask.stack[currentTask.stackPos + 1]._intValue;
                    currentTask.pc++;
                    break;
                case greater_uint:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._uintValue >
                        currentTask.stack[currentTask.stackPos + 1]._uintValue;
                    currentTask.pc++;
                    break;
                case greater_byte:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._byteValue >
                        currentTask.stack[currentTask.stackPos + 1]._byteValue;
                    currentTask.pc++;
                    break;
                case greater_float:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._floatValue >
                        currentTask.stack[currentTask.stackPos + 1]._floatValue;
                    currentTask.pc++;
                    break;
                case greater_double:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue = currentTask.stack[currentTask.stackPos]
                        ._doubleValue > currentTask.stack[currentTask.stackPos + 1]._doubleValue;
                    currentTask.pc++;
                    break;
                case lesser_int:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._intValue <
                        currentTask.stack[currentTask.stackPos + 1]._intValue;
                    currentTask.pc++;
                    break;
                case lesser_uint:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._uintValue <
                        currentTask.stack[currentTask.stackPos + 1]._uintValue;
                    currentTask.pc++;
                    break;
                case lesser_byte:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._byteValue <
                        currentTask.stack[currentTask.stackPos + 1]._byteValue;
                    currentTask.pc++;
                    break;
                case lesser_float:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._floatValue <
                        currentTask.stack[currentTask.stackPos + 1]._floatValue;
                    currentTask.pc++;
                    break;
                case lesser_double:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue = currentTask.stack[currentTask.stackPos]
                        ._doubleValue < currentTask.stack[currentTask.stackPos + 1]._doubleValue;
                    currentTask.pc++;
                    break;
                case checkNull:
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._bytes != GR_NULL;
                    currentTask.pc++;
                    break;
                case optionalTry:
                    currentTask.pc++;
                    if (currentTask.stack[currentTask.stackPos]._bytes == GR_NULL) {
                        currentTask.pc--;
                        raise(currentTask, "NullError");
                    }
                    break;
                case optionalOr:
                    currentTask.stackPos--;
                    if (currentTask.stack[currentTask.stackPos]._bytes == GR_NULL)
                        currentTask.stack[currentTask.stackPos] =
                            currentTask.stack[currentTask.stackPos + 1];
                    currentTask.pc++;
                    break;
                case optionalCall:
                    if (currentTask.stack[currentTask.stackPos]._bytes == GR_NULL)
                        currentTask.pc += grGetInstructionSignedValue(opcode);
                    else
                        currentTask.pc++;
                    break;
                case optionalCall2:
                    if (currentTask.stack[currentTask.stackPos]._bytes == GR_NULL) {
                        currentTask.pc += grGetInstructionSignedValue(opcode);
                        currentTask.stackPos--;
                    }
                    else
                        currentTask.pc++;
                    break;
                case and_int:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._intValue &&
                        currentTask.stack[currentTask.stackPos + 1]._intValue;
                    currentTask.pc++;
                    break;
                case or_int:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue =
                        currentTask.stack[currentTask.stackPos]._intValue ||
                        currentTask.stack[currentTask.stackPos + 1]._intValue;
                    currentTask.pc++;
                    break;
                case not_int:
                    currentTask.stack[currentTask.stackPos]._intValue =
                        !currentTask.stack[currentTask.stackPos]._intValue;
                    currentTask.pc++;
                    break;
                case add_int:
                    currentTask.stackPos--;
                    const long r = cast(long) currentTask.stack[currentTask.stackPos]._intValue + cast(
                        long) currentTask.stack[currentTask.stackPos + 1]._intValue;
                    if (r < int.min || r > int.max) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    currentTask.stack[currentTask.stackPos]._intValue = cast(int) r;
                    currentTask.pc++;
                    break;
                case add_uint:
                    currentTask.stackPos--;
                    const GrUInt r = currentTask.stack[currentTask.stackPos + 1]._uintValue;
                    const GrUInt r2 = currentTask.stack[currentTask.stackPos]._uintValue += r;
                    if (r2 < r) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    currentTask.pc++;
                    break;
                case add_byte:
                    currentTask.stackPos--;
                    const GrByte r = currentTask.stack[currentTask.stackPos + 1]._byteValue;
                    const GrByte r2 = currentTask.stack[currentTask.stackPos]._byteValue += r;
                    if (r2 < r) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    currentTask.pc++;
                    break;
                case add_float:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._floatValue +=
                        currentTask.stack[currentTask.stackPos + 1]._floatValue;
                    currentTask.pc++;
                    break;
                case add_double:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._doubleValue +=
                        currentTask.stack[currentTask.stackPos + 1]._doubleValue;
                    currentTask.pc++;
                    break;
                case concatenate_string:
                    currentTask.stackPos--;
                    GrString str = cast(GrString) currentTask.stack[currentTask.stackPos]._ptrValue;
                    str = new GrString(str);
                    str.pushBack(
                        (cast(GrString) currentTask.stack[currentTask.stackPos + 1]._ptrValue));
                    currentTask.stack[currentTask.stackPos]._ptrValue = cast(void*) str;
                    currentTask.pc++;
                    break;
                case substract_int:
                    currentTask.stackPos--;
                    const long r = cast(long) currentTask.stack[currentTask.stackPos]._intValue - cast(
                        long) currentTask.stack[currentTask.stackPos + 1]._intValue;
                    if (r < int.min || r > int.max) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    currentTask.stack[currentTask.stackPos]._intValue = cast(int) r;
                    currentTask.pc++;
                    break;
                case substract_float:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._floatValue -=
                        currentTask.stack[currentTask.stackPos + 1]._floatValue;
                    currentTask.pc++;
                    break;
                case substract_double:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._doubleValue -=
                        currentTask.stack[currentTask.stackPos + 1]._doubleValue;
                    currentTask.pc++;
                    break;
                case substract_uint:
                    currentTask.stackPos--;
                    GrUInt* v1 = &currentTask.stack[currentTask.stackPos]._uintValue;
                    const GrUInt v2 = currentTask.stack[currentTask.stackPos + 1]._uintValue;
                    if (v2 > *v1) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    *v1 -= v2;
                    currentTask.pc++;
                    break;
                case substract_byte:
                    currentTask.stackPos--;
                    GrByte* v1 = &currentTask.stack[currentTask.stackPos]._byteValue;
                    const GrByte v2 = currentTask.stack[currentTask.stackPos + 1]._byteValue;
                    if (v2 > *v1) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    *v1 -= v2;
                    currentTask.pc++;
                    break;
                case multiply_int:
                    currentTask.stackPos--;
                    const long r = cast(long) currentTask.stack[currentTask.stackPos]._intValue * cast(
                        long) currentTask.stack[currentTask.stackPos + 1]._intValue;
                    if (r < int.min || r > int.max) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    currentTask.stack[currentTask.stackPos]._intValue = cast(int) r;
                    currentTask.pc++;
                    break;
                case multiply_uint:
                    currentTask.stackPos--;
                    const ulong r = ulong(currentTask.stack[currentTask.stackPos]._uintValue) * ulong(
                        currentTask.stack[currentTask.stackPos + 1]._uintValue);
                    if (r >> 32) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    currentTask.stack[currentTask.stackPos]._uintValue = cast(GrUInt) r;
                    currentTask.pc++;
                    break;
                case multiply_byte:
                    currentTask.stackPos--;
                    const uint r = uint(currentTask.stack[currentTask.stackPos]._byteValue) * uint(
                        currentTask.stack[currentTask.stackPos + 1]._byteValue);
                    if (r >> 8) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    currentTask.stack[currentTask.stackPos]._byteValue = cast(GrByte) r;
                    currentTask.pc++;
                    break;
                case multiply_float:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._floatValue *=
                        currentTask.stack[currentTask.stackPos + 1]._floatValue;
                    currentTask.pc++;
                    break;
                case multiply_double:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._doubleValue *=
                        currentTask.stack[currentTask.stackPos + 1]._doubleValue;
                    currentTask.pc++;
                    break;
                case divide_int:
                    if (currentTask.stack[currentTask.stackPos]._intValue == 0) {
                        raise(currentTask, "ZeroDivisionError");
                        break;
                    }
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue /=
                        currentTask.stack[currentTask.stackPos + 1]._intValue;
                    currentTask.pc++;
                    break;
                case divide_uint:
                    if (currentTask.stack[currentTask.stackPos]._uintValue == 0) {
                        raise(currentTask, "ZeroDivisionError");
                        break;
                    }
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._uintValue /=
                        currentTask.stack[currentTask.stackPos + 1]._uintValue;
                    currentTask.pc++;
                    break;
                case divide_byte:
                    if (currentTask.stack[currentTask.stackPos]._byteValue == 0) {
                        raise(currentTask, "ZeroDivisionError");
                        break;
                    }
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._byteValue /=
                        currentTask.stack[currentTask.stackPos + 1]._byteValue;
                    currentTask.pc++;
                    break;
                case divide_float:
                    if (currentTask.stack[currentTask.stackPos]._floatValue == 0f) {
                        raise(currentTask, "ZeroDivisionError");
                        break;
                    }
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._floatValue /=
                        currentTask.stack[currentTask.stackPos + 1]._floatValue;
                    currentTask.pc++;
                    break;
                case divide_double:
                    if (currentTask.stack[currentTask.stackPos]._doubleValue == 0.0) {
                        raise(currentTask, "ZeroDivisionError");
                        break;
                    }
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._doubleValue /=
                        currentTask.stack[currentTask.stackPos + 1]._doubleValue;
                    currentTask.pc++;
                    break;
                case remainder_int:
                    if (currentTask.stack[currentTask.stackPos]._intValue == 0) {
                        raise(currentTask, "ZeroDivisionError");
                        break;
                    }
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue %=
                        currentTask.stack[currentTask.stackPos + 1]._intValue;
                    currentTask.pc++;
                    break;
                case remainder_uint:
                    if (currentTask.stack[currentTask.stackPos]._uintValue == 0) {
                        raise(currentTask, "ZeroDivisionError");
                        break;
                    }
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._uintValue %=
                        currentTask.stack[currentTask.stackPos + 1]._uintValue;
                    currentTask.pc++;
                    break;
                case remainder_byte:
                    if (currentTask.stack[currentTask.stackPos]._byteValue == 0) {
                        raise(currentTask, "ZeroDivisionError");
                        break;
                    }
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._byteValue %=
                        currentTask.stack[currentTask.stackPos + 1]._byteValue;
                    currentTask.pc++;
                    break;
                case remainder_float:
                    if (currentTask.stack[currentTask.stackPos]._floatValue == 0f) {
                        raise(currentTask, "ZeroDivisionError");
                        break;
                    }
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._floatValue %=
                        currentTask.stack[currentTask.stackPos + 1]._floatValue;
                    currentTask.pc++;
                    break;
                case remainder_double:
                    if (currentTask.stack[currentTask.stackPos]._doubleValue == 0.0) {
                        raise(currentTask, "ZeroDivisionError");
                        break;
                    }
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._doubleValue %=
                        currentTask.stack[currentTask.stackPos + 1]._doubleValue;
                    currentTask.pc++;
                    break;
                case negative_int:
                    currentTask.stack[currentTask.stackPos]._intValue = -currentTask
                        .stack[currentTask.stackPos]._intValue;
                    currentTask.pc++;
                    break;
                case negative_float:
                    currentTask.stack[currentTask.stackPos]._floatValue = -currentTask
                        .stack[currentTask.stackPos]._floatValue;
                    currentTask.pc++;
                    break;
                case negative_double:
                    currentTask.stack[currentTask.stackPos]._doubleValue = -currentTask
                        .stack[currentTask.stackPos]._doubleValue;
                    currentTask.pc++;
                    break;
                case increment_int:
                    auto r = &currentTask.stack[currentTask.stackPos]._intValue;
                    if (*r == GrInt.max) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    (*r)++;
                    currentTask.pc++;
                    break;
                case increment_uint:
                    auto r = &currentTask.stack[currentTask.stackPos]._uintValue;
                    if (*r == GrUInt.max) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    (*r)++;
                    currentTask.pc++;
                    break;
                case increment_byte:
                    auto r = &currentTask.stack[currentTask.stackPos]._byteValue;
                    if (*r == GrByte.max) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    (*r)++;
                    currentTask.pc++;
                    break;
                case increment_float:
                    currentTask.stack[currentTask.stackPos]._floatValue += 1f;
                    currentTask.pc++;
                    break;
                case increment_double:
                    currentTask.stack[currentTask.stackPos]._doubleValue += 1.0;
                    currentTask.pc++;
                    break;
                case decrement_int:
                    auto r = &currentTask.stack[currentTask.stackPos]._intValue;
                    if (*r == GrInt.min) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    (*r)--;
                    currentTask.pc++;
                    break;
                case decrement_uint:
                    auto r = &currentTask.stack[currentTask.stackPos]._uintValue;
                    if (*r == GrUInt.min) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    (*r)--;
                    currentTask.pc++;
                    break;
                case decrement_byte:
                    auto r = &currentTask.stack[currentTask.stackPos]._byteValue;
                    if (*r == GrByte.min) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    (*r)--;
                    currentTask.pc++;
                    break;
                case decrement_float:
                    currentTask.stack[currentTask.stackPos]._floatValue -= 1f;
                    currentTask.pc++;
                    break;
                case decrement_double:
                    currentTask.stack[currentTask.stackPos]._doubleValue -= 1.0;
                    currentTask.pc++;
                    break;
                case copy:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos] =
                        currentTask.stack[currentTask.stackPos - 1];
                    currentTask.pc++;
                    break;
                case swap:
                    swapAt(currentTask.stack,
                        currentTask.stackPos - cast(int) grGetInstructionUnsignedValue(opcode),
                        currentTask.stackPos);
                    currentTask.pc++;
                    break;
                case setupIterator:
                    if (currentTask.stack[currentTask.stackPos]._intValue < 0)
                        currentTask.stack[currentTask.stackPos]._intValue = 0;
                    currentTask.stack[currentTask.stackPos]._intValue++;
                    currentTask.pc++;
                    break;
                case return_:
                    // On peut se trouver là si la tâche vient d’être créée
                    // et qu’une autre tâche a été tué par une exception
                    if (currentTask.stackFramePos < 0 && currentTask.isKilled) {
                        _tasks = _tasks.remove(index);
                        continue tasksLabel;
                    } // On vérifie les appel différés
                    else if (currentTask.callStack[currentTask.stackFramePos].deferStack.length) {
                        // Dépile le dernier `defer` et l’exécute
                        currentTask.pc =
                            currentTask.callStack[currentTask.stackFramePos].deferStack[$ - 1];
                        currentTask.callStack[currentTask.stackFramePos].deferStack.length--;
                    }
                    else {
                        // Puis on retourne vers la fonction précédente
                        currentTask.stackFramePos--;
                        currentTask.pc =
                            currentTask.callStack[currentTask.stackFramePos].retPosition;
                        currentTask.localsPos -=
                            currentTask.callStack[currentTask.stackFramePos].localStackSize;
                    }
                    break;
                case unwind:
                    // On peut se trouver là si la tâche vient d’être créée
                    // et qu’une autre tâche a été tué par une exception
                    if (currentTask.stackFramePos < 0) {
                        _tasks = _tasks.remove(index);
                        continue tasksLabel;
                    } // On vérifie les appel différés
                    else if (currentTask.callStack[currentTask.stackFramePos].deferStack.length) {
                        // Dépile le dernier `defer` et l’exécute
                        currentTask.pc =
                            currentTask.callStack[currentTask.stackFramePos].deferStack[$ - 1];
                        currentTask.callStack[currentTask.stackFramePos].deferStack.length--;
                    }
                    else if (currentTask.isKilled) {
                        if (currentTask.stackFramePos) {
                            // Puis on retourne vers la fonction précédente sans modifier le pointeur d’instruction
                            currentTask.stackFramePos--;
                            currentTask.localsPos -=
                                currentTask.callStack[currentTask.stackFramePos].localStackSize;

                            if (_isDebug)
                                _debugProfileEnd();
                        }
                        else {
                            // Tous les appels différés ont été exécuté, on tue la tâche
                            _tasks = _tasks.remove(index);
                            continue tasksLabel;
                        }
                    }
                    else if (currentTask.isPanicking) {
                        //An exception has been raised without any try/catch inside the function.
                        //So all deferred code is run here before searching in the parent function.
                        if (currentTask.stackFramePos) {
                            // On retourne vers la fonction précédente sans modifier le pointeur d’instruction
                            currentTask.stackFramePos--;
                            currentTask.localsPos -=
                                currentTask.callStack[currentTask.stackFramePos].localStackSize;

                            if (_isDebug)
                                _debugProfileEnd();

                            // Un gestionnaire d’erreur a été trouvé dans la fonction, on y va
                            if (
                                currentTask.callStack[currentTask.stackFramePos]
                                .exceptionHandlers.length) {
                                currentTask.pc =
                                    currentTask.callStack[currentTask.stackFramePos].exceptionHandlers[$ -
                                        1];
                            }
                        }
                        else {
                            // On tue les autres tâches
                            foreach (otherTask; _tasks) {
                                otherTask.pc = cast(uint)(cast(int) _bytecode.opcodes.length - 1);
                                otherTask.isKilled = true;
                            }

                            // La machine virtuelle est en panique
                            _isPanicking = true;
                            _panicMessage = (cast(GrString) _globalStack[$ - 1]._ptrValue).str;
                            _globalStack.length--;

                            // Tous les appels différés ont été exécuté, on tue la tâche
                            _tasks = _tasks.remove(index);
                            continue tasksLabel;
                        }
                    }
                    else {
                        // Puis on quitte vers la fonction précédente
                        currentTask.stackFramePos--;
                        currentTask.pc =
                            currentTask.callStack[currentTask.stackFramePos].retPosition;
                        currentTask.localsPos -=
                            currentTask.callStack[currentTask.stackFramePos].localStackSize;

                        if (_isDebug)
                            _debugProfileEnd();
                    }
                    break;
                case defer:
                    currentTask.callStack[currentTask.stackFramePos].deferStack ~=
                        currentTask.pc + grGetInstructionSignedValue(opcode);
                    currentTask.pc++;
                    break;
                case localStack:
                    const auto stackSize = grGetInstructionUnsignedValue(opcode);
                    currentTask.callStack[currentTask.stackFramePos].localStackSize = stackSize;
                    if ((currentTask.localsPos + stackSize) >= currentTask.localsLimit)
                        currentTask.doubleLocalsStackSize(currentTask.localsPos + stackSize);
                    currentTask.pc++;

                    if (currentTask.closure) {
                        currentTask.locals[currentTask.localsPos .. currentTask.localsPos +
                            currentTask.closure.locals.length] = currentTask.closure.locals;
                        currentTask.closure = null;
                    }
                    break;
                case call:
                    if ((currentTask.stackFramePos + 1) >= currentTask.callStackLimit)
                        currentTask.doubleCallStackSize();
                    currentTask.localsPos +=
                        currentTask.callStack[currentTask.stackFramePos].localStackSize;
                    currentTask.callStack[currentTask.stackFramePos].retPosition =
                        currentTask.pc + 1u;
                    currentTask.stackFramePos++;
                    currentTask.pc = grGetInstructionUnsignedValue(opcode);
                    break;
                case address:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    GrClosure closure = new GrClosure(null,
                        _bytecode.uintConsts[grGetInstructionUnsignedValue(opcode)]);
                    currentTask.stack[currentTask.stackPos]._ptrValue = cast(GrPointer) closure;
                    currentTask.pc++;
                    break;
                case closure:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;

                    const uint pc = _bytecode.uintConsts[grGetInstructionUnsignedValue(opcode)];

                    // Cet opcode est forcément suivi de extend
                    const uint size = grGetInstructionUnsignedValue(
                        _bytecode.opcodes[currentTask.pc + 1]);

                    GrClosure closure = new GrClosure(currentTask, pc, size);
                    currentTask.stack[currentTask.stackPos]._ptrValue = cast(GrPointer) closure;

                    currentTask.pc += 2;
                    break;
                case anonymousCall:
                    if ((currentTask.stackFramePos + 1) >= currentTask.callStackLimit)
                        currentTask.doubleCallStackSize();
                    currentTask.localsPos +=
                        currentTask.callStack[currentTask.stackFramePos].localStackSize;
                    currentTask.callStack[currentTask.stackFramePos].retPosition =
                        currentTask.pc + 1u;
                    currentTask.stackFramePos++;
                    uint pos = currentTask.stackPos - cast(int) grGetInstructionUnsignedValue(
                        opcode);
                    GrClosure closure = cast(GrClosure) currentTask.stack[pos]._ptrValue;
                    currentTask.pc = closure.pc;

                    if (closure.caller) {
                        currentTask.closure = closure;
                    }

                    // On décale toute la signature
                    while (pos != currentTask.stackPos) {
                        currentTask.stack[pos] = currentTask.stack[pos + 1];
                        pos++;
                    }

                    currentTask.stackPos--;
                    break;
                case primitiveCall:
                    _calls[grGetInstructionUnsignedValue(opcode)].call(currentTask);
                    currentTask.pc++;
                    if (currentTask.blocker) {
                        index++;
                        continue tasksLabel;
                    }
                    break;
                case safePrimitiveCall:
                    _calls[grGetInstructionUnsignedValue(opcode)].call!(true)(currentTask);
                    currentTask.pc++;
                    if (currentTask.blocker) {
                        index++;
                        continue tasksLabel;
                    }
                    break;
                case jump:
                    currentTask.pc += grGetInstructionSignedValue(opcode);
                    break;
                case jumpEqual:
                    if (currentTask.stack[currentTask.stackPos]._intValue)
                        currentTask.pc++;
                    else
                        currentTask.pc += grGetInstructionSignedValue(opcode);
                    currentTask.stackPos--;
                    break;
                case jumpNotEqual:
                    if (currentTask.stack[currentTask.stackPos]._intValue)
                        currentTask.pc += grGetInstructionSignedValue(opcode);
                    else
                        currentTask.pc++;
                    currentTask.stackPos--;
                    break;
                case list:
                    const GrInt listSize = grGetInstructionUnsignedValue(opcode);
                    GrList list = new GrList(listSize);
                    for (GrInt i = listSize - 1; i >= 0; i--)
                        list.pushBack(currentTask.stack[currentTask.stackPos - i]);
                    currentTask.stackPos -= listSize - 1;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos]._ptrValue = cast(GrPointer) list;
                    currentTask.pc++;
                    break;
                case index_list:
                    GrList list = cast(GrList) currentTask.stack[currentTask.stackPos - 1]
                        ._ptrValue;
                    GrInt idx = currentTask.stack[currentTask.stackPos]._intValue;
                    if (idx < 0) {
                        idx = list.size + idx;
                    }
                    if (idx >= list.size) {
                        raise(currentTask, "IndexError");
                        break;
                    }
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ptrValue = &list._data[idx];
                    currentTask.pc++;
                    break;
                case index2_list:
                    GrList list = cast(GrList) currentTask.stack[currentTask.stackPos - 1]
                        ._ptrValue;
                    GrInt idx = currentTask.stack[currentTask.stackPos]._intValue;
                    if (idx < 0) {
                        idx = list.size + idx;
                    }
                    if (idx >= list.size) {
                        raise(currentTask, "IndexError");
                        break;
                    }
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos] = list[idx];
                    currentTask.pc++;
                    break;
                case index3_list:
                    GrList list = cast(GrList) currentTask.stack[currentTask.stackPos - 1]
                        ._ptrValue;
                    GrInt idx = currentTask.stack[currentTask.stackPos]._intValue;
                    if (idx < 0) {
                        idx = list.size + idx;
                    }
                    if (idx >= list.size) {
                        raise(currentTask, "IndexError");
                        break;
                    }
                    currentTask.stack[currentTask.stackPos - 1]._ptrValue = &list._data[idx];
                    currentTask.stack[currentTask.stackPos] = list[idx];
                    currentTask.pc++;
                    break;
                case length_list:
                    currentTask.stack[currentTask.stackPos]._intValue = (cast(
                            GrList) currentTask.stack[currentTask.stackPos]._ptrValue).size;
                    currentTask.pc++;
                    break;
                case concatenate_list:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ptrValue = cast(GrPointer) new GrList(
                        (cast(GrList) currentTask.stack[currentTask.stackPos]._ptrValue).getValues() ~ (
                            cast(GrList) currentTask.stack[currentTask.stackPos + 1]._ptrValue).getValues());
                    currentTask.pc++;
                    break;
                case append_list:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ptrValue = cast(GrPointer) new GrList(
                        (cast(GrList) currentTask.stack[currentTask.stackPos]._ptrValue).getValues() ~
                            currentTask.stack[currentTask.stackPos + 1]);
                    currentTask.pc++;
                    break;
                case prepend_list:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ptrValue = cast(GrPointer) new GrList(
                        currentTask.stack[currentTask.stackPos] ~ (cast(
                            GrList) currentTask.stack[currentTask.stackPos + 1]._ptrValue).getValues());
                    currentTask.pc++;
                    break;
                case equal_list:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue = (cast(
                            GrList) currentTask.stack[currentTask.stackPos]._ptrValue).getValues() == (
                        cast(GrList) currentTask.stack[currentTask.stackPos + 1]._ptrValue).getValues();
                    currentTask.pc++;
                    break;
                case notEqual_list:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._intValue = (cast(
                            GrList) currentTask.stack[currentTask.stackPos]._ptrValue).getValues() != (
                        cast(GrList) currentTask.stack[currentTask.stackPos + 1]._ptrValue).getValues();
                    currentTask.pc++;
                    break;
                case debugProfileBegin:
                    _debugProfileBegin(opcode, currentTask.pc);
                    currentTask.pc++;
                    break;
                case debugProfileEnd:
                    _debugProfileEnd();
                    currentTask.pc++;
                    break;
                }
            }
            index++;
        }
    }

    /// Instancie un nouvel objet
    GrObject createObject(string name) {
        GrClassBuilder* builder = (name in _classBuilders);
        if (builder) {
            enforce!GrRuntimeException(!builder.inheritFromNative,
                "this class inherits from a native parent, use `createObject(T)(string name, T nativeParent)` instead");
            GrObject obj = new GrObject(*builder);
            return obj;
        }
        return null;
    }

    /// Ditto
    GrObject createObject(T)(string name, T nativeParent) if (is(T == class)) {
        GrClassBuilder* builder = (name in _classBuilders);
        if (builder) {
            enforce!GrRuntimeException(!builder.inheritFromNative,
                "this class doesn't inherit from a native parent, use `createObject(T)(string name)` instead");
            enforce!GrRuntimeException(nativeParent, "the `nativeParent` attribute can't be null");
            GrObject obj = new GrObject(*builder);
            obj._nativeParent = *(cast(GrPointer*)&nativeParent);
            return obj;
        }
        return null;
    }

    /// Récupère le nom du champ de l’énumération correspondant à une valeur donnée
    string getEnumFieldName(string enumName, int fieldValue) {
        foreach (enum_; _bytecode.enums) {
            if (enum_.name == enumName) {
                foreach (ref field; enum_.fields) {
                    if (field.value == fieldValue) {
                        return field.name;
                    }
                }

                return to!string(fieldValue);
            }
        }

        return to!string(fieldValue);
    }

    /// Récupère la valeur du champ de l’énumération correspondant à un nom donné
    int getEnumFieldValue(string enumName, string fieldName) {
        foreach (enum_; _bytecode.enums) {
            if (enum_.name == enumName) {
                foreach (ref field; enum_.fields) {
                    if (field.name == fieldName) {
                        return field.value;
                    }
                }

                return 0;
            }
        }

        return 0;
    }

    /// Vérifie l’existance d’une valeur d’un champ de l’énumération
    bool hasEnumFieldValue(string enumName, int fieldValue) {
        foreach (enum_; _bytecode.enums) {
            if (enum_.name == enumName) {
                foreach (ref field; enum_.fields) {
                    if (field.value == fieldValue) {
                        return true;
                    }
                }

                return false;
            }
        }

        return false;
    }

    /// Vérifie l’existance du nom d’un champ de l’énumération
    bool hasEnumFieldName(string enumName, string fieldName) {
        foreach (enum_; _bytecode.enums) {
            if (enum_.name == enumName) {
                foreach (ref field; enum_.fields) {
                    if (field.name == fieldName) {
                        return true;
                    }
                }

                return false;
            }
        }

        return false;
    }

    /// Change la fonction de la sortie standard
    void setPrintOutput(void function(string) callback) {
        if (!callback) {
            _stdOut = &_defaultOutput;
            return;
        }
        _stdOut = callback;
    }

    /// Récupère la fonction de la sortie standard
    void function(string) getPrintOutput() {
        return _stdOut;
    }

    /// Affiche un message dans la sortie standard
    void print(string message) {
        _stdOut(message);
    }

    import core.time : MonoTime, Duration;

    private {
        bool _isDebug;
        DebugFunction[int] _debugFunctions;
        DebugFunction[] _debugFunctionsStack;
    }

    /// Informations de profilage pour chaque fonction appelée
    DebugFunction[int] dumpProfiling() {
        return _debugFunctions;
    }

    /// Enjolive le résultat obtenu par `dumpProfiling`
    string prettifyProfiling() {
        import std.algorithm.comparison : max;
        import std.conv : to;

        string report;
        size_t functionNameLength = 10;
        size_t countLength = 10;
        size_t totalLength = 10;
        size_t averageLength = 10;
        foreach (func; dumpProfiling()) {
            functionNameLength = max(func.name.length, functionNameLength);
            countLength = max(to!string(func.count).length, countLength);
            totalLength = max(to!string(func.total.total!"msecs").length, totalLength);
            Duration average = func.count ? (func.total / func.count) : Duration.zero;
            averageLength = max(to!string(average.total!"msecs").length, averageLength);
        }
        string header = "| " ~ leftJustify("Function", functionNameLength) ~ " | " ~ leftJustify("Count",
            countLength) ~ " | " ~ leftJustify("Total",
            totalLength) ~ " | " ~ leftJustify("Average", averageLength) ~ " |";

        string separator = "+" ~ leftJustify("", functionNameLength + 2,
            '-') ~ "+" ~ leftJustify("", countLength + 2, '-') ~ "+" ~ leftJustify("",
            totalLength + 2, '-') ~ "+" ~ leftJustify("", averageLength + 2, '-') ~ "+";
        report ~= separator ~ "\n" ~ header ~ "\n" ~ separator ~ "\n";
        foreach (func; dumpProfiling()) {
            Duration average = func.count ? (func.total / func.count) : Duration.zero;
            report ~= "| " ~ leftJustify(func.name, functionNameLength) ~ " | " ~ leftJustify(
                to!string(func.count), countLength) ~ " | " ~ leftJustify(to!string(func.total.total!"msecs"),
                totalLength) ~ " | " ~ leftJustify(to!string(average.total!"msecs"),
                averageLength) ~ " |\n";
        }
        report ~= separator ~ "\n";
        return report;
    }

    /// Information de profilage d’une fonction appelée
    final class DebugFunction {
        private {
            MonoTime _start;
            Duration _total;
            ulong _count;
            int _pc;
            string _name;
        }

        @property {
            /// Temps total d’exécution passé dans cette fonction
            Duration total() const {
                return _total;
            }
            /// Nombre de fois que cette fonction a été appelé
            ulong count() const {
                return _count;
            }
            /// Nom enjolivé de la fonction
            string name() const {
                return _name;
            }
        }
    }

    private void _debugProfileEnd() {
        if (!_debugFunctionsStack.length)
            return;
        auto p = _debugFunctionsStack[$ - 1];
        _debugFunctionsStack.length--;
        p._total += MonoTime.currTime() - p._start;
        p._count++;
    }

    private void _debugProfileBegin(uint opcode, int pc) {
        _isDebug = true;
        auto p = (pc in _debugFunctions);
        if (p) {
            p._start = MonoTime.currTime();
            _debugFunctionsStack ~= *p;
        }
        else {
            auto debugFunc = new DebugFunction;
            debugFunc._pc = pc;
            debugFunc._name = _bytecode.strConsts[grGetInstructionUnsignedValue(opcode)];
            debugFunc._start = MonoTime.currTime();
            _debugFunctions[pc] = debugFunc;
            _debugFunctionsStack ~= debugFunc;
        }
    }
}

private void _defaultOutput(string message) {
    import std.stdio : writeln;

    writeln(message);
}
