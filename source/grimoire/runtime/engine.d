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

import grimoire.compiler, grimoire.assembly;

import grimoire.runtime.task;
import grimoire.runtime.event;
import grimoire.runtime.value;
import grimoire.runtime.object;
import grimoire.runtime.string;
import grimoire.runtime.list;
import grimoire.runtime.channel;
import grimoire.runtime.call;

/// La machine virtuelle de grimoire
class GrEngine {
    private {
        /// Le bytecode
        GrBytecode _bytecode;

        /// Les variables globales
        GrValue[] _globals;

        /// La pile globale
        GrValue[] _globalStackIn, _globalStackOut;

        /// Liste des tâche en exécution
        GrTask[] _tasks, _createdTasks;

        /// État de panique global
        /// Signifie que la tâche impliquée n’a pas correctement géré son exception
        bool _isPanicking;
        /// Message de panique non-géré
        GrStringValue _panicMessage;
        /// Les traces d’appel sont générés chaque fois qu’une erreur est lancé
        GrStackTrace[] _stackTraces;

        /// Informations supplémentaires de type du compilateur
        GrStringValue _meta;

        /// Primitives
        GrCallback[] _callbacks;
        /// Ditto
        GrCall[] _calls;

        /// Version
        uint _userVersion;

        /// Classes
        GrClassBuilder[string] _classBuilders;
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
            return (_tasks.length + _createdTasks.length) > 0uL;
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
        GrStringValue panicMessage() const {
            return _panicMessage;
        }

        /// Informations supplémentaires de type du compilateur
        GrStringValue meta() const {
            return _meta;
        }
        /// Ditto
        GrStringValue meta(GrStringValue meta_) {
            return _meta = meta_;
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
        _callbacks ~= library._callbacks;
    }

    /// Charge le bytecode.
    final bool load(GrBytecode bytecode) {
        isRunning = false;

        if (!bytecode.checkVersion(_userVersion)) {
            _bytecode = null;
            return false;
        }

        _bytecode = bytecode;
        _globals = new GrValue[_bytecode.globalsCount];
        _tasks ~= new GrTask(this);

        // Prépare les primitives
        for (uint i; i < _bytecode.primitives.length; ++i) {
            if (_bytecode.primitives[i].index > _callbacks.length)
                throw new Exception("callback index out of bounds");
            _calls ~= new GrCall(_callbacks[_bytecode.primitives[i].index],
                _bytecode.primitives[i].name, _bytecode.primitives[i]);
        }

        foreach (ref globalRef; _bytecode.variables) {
            const uint typeMask = globalRef.typeMask;
            const uint index = globalRef.index;
            if (typeMask & 0x1)
                _globals[index]._ivalue = globalRef.ivalue;
            else if (typeMask & 0x2)
                _globals[index]._fvalue = globalRef.rvalue;
            else if (typeMask & 0x4)
                _globals[index]._ovalue = cast(GrPointer) new GrString(globalRef.svalue);
            else if (typeMask & 0x8)
                _globals[index]._ovalue = null;
        }

        // Indexe les classes
        for (size_t index; index < _bytecode.classes.length; index++) {
            GrClassBuilder classBuilder = _bytecode.classes[index];
            _classBuilders[classBuilder.name] = classBuilder;
        }

        isRunning = true;
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
    GrEvent getEvent(GrInt address_) const {
        foreach (string name, uint address; _bytecode.events) {
            if (address == address_)
                return new GrEvent(name, address);
        }
        return null;
    }

    /// Récupère l’événement correspondant au nom indiqué.
    GrEvent getEvent(const string name_, const GrType[] signature = []) const {
        const string mangledName = grMangleComposite(name_, signature);
        foreach (string name, uint address; _bytecode.events) {
            if (mangledName == name)
                return new GrEvent(name, address);
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
    GrTask callEvent(const string name, const GrType[] signature = [],
        GrValue[] parameters = [], Priority priority = Priority.normal) {

        if (!isRunning)
            return null;

        const string mangledName = grMangleComposite(name, signature);
        const auto event = mangledName in _bytecode.events;
        if (event is null)
            return null;
        if (signature.length != parameters.length)
            throw new Exception("the number of parameters (" ~ to!string(
                    parameters.length) ~ ") of `" ~ grGetPrettyFunctionCall(
                    mangledName) ~ "` mismatch its definition");
        GrTask task = new GrTask(this);
        task.pc = *event;

        if (parameters.length > task.stack.length)
            task.stack.length = parameters.length;

        for (size_t i; i < parameters.length; ++i)
            task.stack[i] = parameters[i];
        task.stackPos = (cast(int) parameters.length) - 1;

        final switch (priority) with (Priority) {
        case immediate:
            _tasks ~= task;
            break;
        case normal:
            _createdTasks ~= task;
            break;
        }
        return task;
    }

    /// Ditto
    GrTask callEvent(const GrEvent event, GrValue[] parameters = [],
        Priority priority = Priority.normal) {
        if (!isRunning || event is null)
            return null;

        if (event.signature.length != parameters.length)
            throw new Exception("the number of parameters (" ~ to!string(
                    parameters.length) ~ ") of `" ~ grGetPrettyFunctionCall(event.name,
                    event.signature) ~ "` mismatch its definition");

        GrTask task = new GrTask(this);
        task.pc = event.address;

        if (parameters.length > task.stack.length)
            task.stack.length = parameters.length;

        for (size_t i; i < parameters.length; ++i)
            task.stack[i] = parameters[i];
        task.stackPos = (cast(int) parameters.length) - 1;

        final switch (priority) with (Priority) {
        case immediate:
            _tasks ~= task;
            break;
        case normal:
            _createdTasks ~= task;
            break;
        }
        return task;
    }

    package(grimoire) void pushTask(GrTask task) {
        _createdTasks ~= task;
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
    void raise(GrTask task, GrStringValue message) {
        if (task.isPanicking)
            return;

        // Message d’erreur
        _globalStackIn ~= GrValue(message);

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
        _createdTasks.length = 0;
    }

    alias getBoolVariable = getVariable!bool;
    alias getIntVariable = getVariable!GrInt;
    alias getFloatVariable = getVariable!GrFloat;
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
        if (variable is null)
            throw new Exception("no global variable `" ~ name ~ "` defined");
        static if (is(T == GrInt)) {
            return _globals[variable.index]._ivalue;
        }
        else static if (is(T == GrBool)) {
            return _globals[variable.index]._ivalue > 0;
        }
        else static if (is(T == GrFloat)) {
            return _globals[variable.index]._fvalue;
        }
        else static if (is(T == GrPointer)) {
            return cast(GrPointer) _globals[variable.index]._ovalue;
        }
    }

    alias setBoolVariable = setVariable!GrBool;
    alias setIntVariable = setVariable!GrInt;
    alias setFloatVariable = setVariable!GrFloat;
    alias setPointerVariable = setVariable!GrPointer;

    pragma(inline) void setEnumVariable(T)(string name, T value) {
        setVariable!GrInt(name, cast(GrInt) value);
    }

    pragma(inline) void setStringVariable(string name, GrStringValue value) {
        setVariable!GrPointer(name, cast(GrPointer) new GrString(value));
    }

    pragma(inline) void setListVariable(string name, GrList value) {
        setVariable!GrPointer(name, cast(GrPointer) value);
    }

    pragma(inline) void setListVariable(string name, GrValue[] value) {
        setVariable!GrPointer(name, cast(GrPointer) new GrList(value));
    }

    pragma(inline) void setChannelVariable(string name, GrChannel value) {
        setVariable!GrPointer(name, cast(GrPointer) value);
    }

    pragma(inline) void setObjectVariable(string name, GrObject value) {
        setVariable!GrPointer(name, cast(GrPointer) value);
    }

    pragma(inline) void setNativeVariable(T)(string name, T value) {
        setVariable!GrPointer(name, cast(GrPointer) value);
    }

    pragma(inline) private void setVariable(T)(string name, T value) {
        const auto variable = name in _bytecode.variables;
        if (variable is null)
            throw new Exception("no global variable `" ~ name ~ "` defined");
        static if (is(T == GrInt) || is(T == GrBool)) {
            _globals[variable.index]._ivalue = value;
        }
        else static if (is(T == GrFloat)) {
            _globals[variable.index]._fvalue = value;
        }
        else static if (is(T == GrPointer)) {
            _globals[variable.index]._ovalue = value;
        }
    }

    /// Exécute la machine virtuelle jusqu’à ce que toutes les tâches finissent ou soient suspendues
    void process() {
        import std.algorithm.mutation : remove, swap;

        if (_createdTasks.length) {
            foreach_reverse (task; _createdTasks)
                _tasks ~= task;
            _createdTasks.length = 0;

            swap(_globalStackIn, _globalStackOut);
        }

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
                case throw_:
                    if (!currentTask.isPanicking) {
                        // Message d’erreur
                        _globalStackIn ~= currentTask.stack[currentTask.stackPos];
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
                    }
                    // Aucun gestionnaire d’erreur de trouvé dans la fonction,
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
                        _panicMessage = (cast(GrString) _globalStackIn[$ - 1]._ovalue).data;
                        _globalStackIn.length--;

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
                    GrTask nTask = new GrTask(this);
                    nTask.pc = grGetInstructionUnsignedValue(opcode);
                    _createdTasks ~= nTask;
                    currentTask.pc++;
                    break;
                case anonymousTask:
                    GrTask nTask = new GrTask(this);
                    nTask.pc = cast(uint) currentTask.stack[currentTask.stackPos]._ivalue;
                    currentTask.stackPos--;
                    _createdTasks ~= nTask;
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
                    currentTask.stack[currentTask.stackPos]._ovalue = cast(GrPointer) new GrObject(
                        _bytecode.classes[grGetInstructionUnsignedValue(opcode)]);
                    currentTask.pc++;
                    break;
                case channel:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos]._ovalue = cast(
                        GrPointer) new GrChannel(grGetInstructionUnsignedValue(opcode));
                    currentTask.pc++;
                    break;
                case send:
                    GrChannel chan = cast(GrChannel) currentTask
                        .stack[currentTask.stackPos - 1]._ovalue;
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
                        .stack[currentTask.stackPos]._ovalue;
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
                    *(cast(GrValue*) currentTask.stack[currentTask.stackPos - 1]._ovalue) = currentTask
                        .stack[currentTask.stackPos];
                    currentTask.stackPos -= 2;
                    currentTask.pc++;
                    break;
                case refStore2:
                    *(cast(GrValue*) currentTask.stack[currentTask.stackPos - 1]._ovalue) = currentTask
                        .stack[currentTask.stackPos];
                    currentTask.stack[currentTask.stackPos - 1] =
                        currentTask.stack[currentTask.stackPos];
                    currentTask.stackPos--;
                    currentTask.pc++;
                    break;
                case fieldRefStore:
                    currentTask.stackPos--;
                    (cast(GrField) currentTask.stack[currentTask.stackPos]._ovalue).value =
                        currentTask.stack[currentTask.stackPos + 1];
                    currentTask.stack[currentTask.stackPos] =
                        currentTask.stack[currentTask.stackPos + 1];
                    currentTask.stackPos += grGetInstructionSignedValue(opcode);
                    currentTask.pc++;
                    break;
                case fieldRefLoad:
                    if (!currentTask.stack[currentTask.stackPos]._ovalue) {
                        raise(currentTask, "NullError");
                        break;
                    }
                    currentTask.stack[currentTask.stackPos]._ovalue = cast(GrPointer)(
                        (cast(GrObject) currentTask.stack[currentTask.stackPos]._ovalue)
                            ._fields[grGetInstructionUnsignedValue(opcode)]);
                    currentTask.pc++;
                    break;
                case fieldRefLoad2:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos]._ovalue = cast(GrPointer)(
                        (cast(GrObject) currentTask.stack[currentTask.stackPos - 1]._ovalue)
                            ._fields[grGetInstructionUnsignedValue(opcode)]);
                    currentTask.pc++;
                    break;
                case fieldLoad:
                    if (!currentTask.stack[currentTask.stackPos]._ovalue) {
                        raise(currentTask, "NullError");
                        break;
                    }
                    currentTask.stack[currentTask.stackPos] = (cast(
                            GrObject) currentTask.stack[currentTask.stackPos]._ovalue)
                        ._fields[grGetInstructionUnsignedValue(opcode)].value;
                    currentTask.pc++;
                    break;
                case fieldLoad2:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    GrField field = (cast(
                            GrObject) currentTask.stack[currentTask.stackPos - 1]._ovalue)
                        ._fields[grGetInstructionUnsignedValue(opcode)];
                    currentTask.stack[currentTask.stackPos] = field.value;
                    currentTask.stack[currentTask.stackPos - 1]._ovalue = cast(GrPointer) field;
                    currentTask.pc++;
                    break;
                case const_int:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos]._ivalue = _bytecode.iconsts[grGetInstructionUnsignedValue(
                            opcode)];
                    currentTask.pc++;
                    break;
                case const_float:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos]._fvalue = _bytecode.fconsts[grGetInstructionUnsignedValue(
                            opcode)];
                    currentTask.pc++;
                    break;
                case const_bool:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos]._ivalue = grGetInstructionUnsignedValue(
                        opcode);
                    currentTask.pc++;
                    break;
                case const_string:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos]._ovalue = cast(GrPointer) new GrString(
                        _bytecode.sconsts[grGetInstructionUnsignedValue(opcode)]);
                    currentTask.pc++;
                    break;
                case const_meta:
                    _meta = _bytecode.sconsts[grGetInstructionUnsignedValue(opcode)];
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
                        _globalStackOut ~= currentTask.stack[(currentTask.stackPos - nbParams) + i];
                    currentTask.stackPos -= nbParams;
                    currentTask.pc++;
                    break;
                case globalPop:
                    currentTask.stackPos++;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos] = _globalStackIn[$ - 1];
                    _globalStackIn.length--;
                    currentTask.pc++;
                    break;
                case equal_int:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue =
                        currentTask.stack[currentTask.stackPos]._ivalue ==
                        currentTask.stack[currentTask.stackPos + 1]._ivalue;
                    currentTask.pc++;
                    break;
                case equal_float:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue =
                        currentTask.stack[currentTask.stackPos]._fvalue ==
                        currentTask.stack[currentTask.stackPos + 1]._fvalue;
                    currentTask.pc++;
                    break;
                case equal_string:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue = (cast(
                            GrString) currentTask.stack[currentTask.stackPos]._ovalue).data == (
                        cast(GrString) currentTask.stack[currentTask.stackPos + 1]._ovalue).data;
                    currentTask.pc++;
                    break;
                case notEqual_int:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue =
                        currentTask.stack[currentTask.stackPos]._ivalue !=
                        currentTask.stack[currentTask.stackPos + 1]._ivalue;
                    currentTask.pc++;
                    break;
                case notEqual_float:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue =
                        currentTask.stack[currentTask.stackPos]._fvalue !=
                        currentTask.stack[currentTask.stackPos + 1]._fvalue;
                    currentTask.pc++;
                    break;
                case notEqual_string:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue = (cast(
                            GrString) currentTask.stack[currentTask.stackPos]._ovalue).data != (
                        cast(GrString) currentTask.stack[currentTask.stackPos + 1]._ovalue).data;
                    currentTask.pc++;
                    break;
                case greaterOrEqual_int:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue =
                        currentTask.stack[currentTask.stackPos]._ivalue >=
                        currentTask.stack[currentTask.stackPos + 1]._ivalue;
                    currentTask.pc++;
                    break;
                case greaterOrEqual_float:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue =
                        currentTask.stack[currentTask.stackPos]._fvalue >=
                        currentTask.stack[currentTask.stackPos + 1]._fvalue;
                    currentTask.pc++;
                    break;
                case lesserOrEqual_int:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue =
                        currentTask.stack[currentTask.stackPos]._ivalue <=
                        currentTask.stack[currentTask.stackPos + 1]._ivalue;
                    currentTask.pc++;
                    break;
                case lesserOrEqual_float:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue =
                        currentTask.stack[currentTask.stackPos]._fvalue <=
                        currentTask.stack[currentTask.stackPos + 1]._fvalue;
                    currentTask.pc++;
                    break;
                case greater_int:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue =
                        currentTask.stack[currentTask.stackPos]._ivalue >
                        currentTask.stack[currentTask.stackPos + 1]._ivalue;
                    currentTask.pc++;
                    break;
                case greater_float:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue =
                        currentTask.stack[currentTask.stackPos]._fvalue >
                        currentTask.stack[currentTask.stackPos + 1]._fvalue;
                    currentTask.pc++;
                    break;
                case lesser_int:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue =
                        currentTask.stack[currentTask.stackPos]._ivalue <
                        currentTask.stack[currentTask.stackPos + 1]._ivalue;
                    currentTask.pc++;
                    break;
                case lesser_float:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue =
                        currentTask.stack[currentTask.stackPos]._fvalue <
                        currentTask.stack[currentTask.stackPos + 1]._fvalue;
                    currentTask.pc++;
                    break;
                case checkNull:
                    currentTask.stack[currentTask.stackPos]._ivalue =
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
                    currentTask.stack[currentTask.stackPos]._ivalue = currentTask.stack[currentTask.stackPos]._ivalue &&
                        currentTask.stack[currentTask.stackPos + 1]._ivalue;
                    currentTask.pc++;
                    break;
                case or_int:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue = currentTask.stack[currentTask.stackPos]._ivalue ||
                        currentTask.stack[currentTask.stackPos + 1]._ivalue;
                    currentTask.pc++;
                    break;
                case not_int:
                    currentTask.stack[currentTask.stackPos]._ivalue =
                        !currentTask.stack[currentTask.stackPos]._ivalue;
                    currentTask.pc++;
                    break;
                case add_int:
                    currentTask.stackPos--;
                    const long r = cast(long) currentTask.stack[currentTask.stackPos]._ivalue + cast(
                        long) currentTask.stack[currentTask.stackPos + 1]._ivalue;
                    if (r < int.min || r > int.max) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    currentTask.stack[currentTask.stackPos]._ivalue = cast(int) r;
                    currentTask.pc++;
                    break;
                case add_float:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._fvalue +=
                        currentTask.stack[currentTask.stackPos + 1]._fvalue;
                    currentTask.pc++;
                    break;
                case concatenate_string:
                    currentTask.stackPos--;
                    (cast(GrString) currentTask.stack[currentTask.stackPos]._ovalue).push(
                        (cast(GrString) currentTask.stack[currentTask.stackPos + 1]._ovalue).data);
                    currentTask.pc++;
                    break;
                case substract_int:
                    currentTask.stackPos--;
                    const long r = cast(long) currentTask.stack[currentTask.stackPos]._ivalue - cast(
                        long) currentTask.stack[currentTask.stackPos + 1]._ivalue;
                    if (r < int.min || r > int.max) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    currentTask.stack[currentTask.stackPos]._ivalue = cast(int) r;
                    currentTask.pc++;
                    break;
                case substract_float:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._fvalue -=
                        currentTask.stack[currentTask.stackPos + 1]._fvalue;
                    currentTask.pc++;
                    break;
                case multiply_int:
                    currentTask.stackPos--;
                    const long r = cast(long) currentTask.stack[currentTask.stackPos]._ivalue * cast(
                        long) currentTask.stack[currentTask.stackPos + 1]._ivalue;
                    if (r < int.min || r > int.max) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    currentTask.stack[currentTask.stackPos]._ivalue = cast(int) r;
                    currentTask.pc++;
                    break;
                case multiply_float:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._fvalue *=
                        currentTask.stack[currentTask.stackPos + 1]._fvalue;
                    currentTask.pc++;
                    break;
                case divide_int:
                    if (currentTask.stack[currentTask.stackPos]._ivalue == 0) {
                        raise(currentTask, "ZeroDivisionError");
                        break;
                    }
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue /=
                        currentTask.stack[currentTask.stackPos + 1]._ivalue;
                    currentTask.pc++;
                    break;
                case divide_float:
                    if (currentTask.stack[currentTask.stackPos]._fvalue == 0f) {
                        raise(currentTask, "ZeroDivisionError");
                        break;
                    }
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._fvalue /=
                        currentTask.stack[currentTask.stackPos + 1]._fvalue;
                    currentTask.pc++;
                    break;
                case remainder_int:
                    if (currentTask.stack[currentTask.stackPos]._ivalue == 0) {
                        raise(currentTask, "ZeroDivisionError");
                        break;
                    }
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue %=
                        currentTask.stack[currentTask.stackPos + 1]._ivalue;
                    currentTask.pc++;
                    break;
                case remainder_float:
                    if (currentTask.stack[currentTask.stackPos]._fvalue == 0f) {
                        raise(currentTask, "ZeroDivisionError");
                        break;
                    }
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._fvalue %=
                        currentTask.stack[currentTask.stackPos + 1]._fvalue;
                    currentTask.pc++;
                    break;
                case negative_int:
                    currentTask.stack[currentTask.stackPos]._ivalue = -currentTask
                        .stack[currentTask.stackPos]._ivalue;
                    currentTask.pc++;
                    break;
                case negative_float:
                    currentTask.stack[currentTask.stackPos]._fvalue = -currentTask
                        .stack[currentTask.stackPos]._fvalue;
                    currentTask.pc++;
                    break;
                case increment_int:
                    auto r = &currentTask.stack[currentTask.stackPos]._ivalue;
                    if (*r == int.max) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    (*r) ++;
                    currentTask.pc++;
                    break;
                case increment_float:
                    currentTask.stack[currentTask.stackPos]._fvalue += 1f;
                    currentTask.pc++;
                    break;
                case decrement_int:
                    auto r = &currentTask.stack[currentTask.stackPos]._ivalue;
                    if (*r == int.min) {
                        raise(currentTask, "OverflowError");
                        break;
                    }
                    (*r) --;
                    currentTask.pc++;
                    break;
                case decrement_float:
                    currentTask.stack[currentTask.stackPos]._fvalue -= 1f;
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
                    swapAt(currentTask.stack, currentTask.stackPos - 1, currentTask.stackPos);
                    currentTask.pc++;
                    break;
                case setupIterator:
                    if (currentTask.stack[currentTask.stackPos]._ivalue < 0)
                        currentTask.stack[currentTask.stackPos]._ivalue = 0;
                    currentTask.stack[currentTask.stackPos]._ivalue++;
                    currentTask.pc++;
                    break;
                case return_:
                    // On peut se trouver là si la tâche vient d’être créée
                    // et qu’une autre tâche a été tué par une exception
                    if (currentTask.stackFramePos < 0 && currentTask.isKilled) {
                        _tasks = _tasks.remove(index);
                        continue tasksLabel;
                    }
                    // On vérifie les appel différés
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
                    }
                    // On vérifie les appel différés
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
                            _createdTasks.length = 0;

                            // La machine virtuelle est en panique
                            _isPanicking = true;
                            _panicMessage = (cast(GrString) _globalStackIn[$ - 1]._ovalue).data;
                            _globalStackIn.length--;

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
                    currentTask.pc = cast(uint) currentTask.stack[pos]._ivalue;

                    // On décale toute la signature
                    while (pos != currentTask.stackPos)
                        currentTask.stack[pos] = currentTask.stack[++pos];

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
                    if (currentTask.stack[currentTask.stackPos]._ivalue)
                        currentTask.pc++;
                    else
                        currentTask.pc += grGetInstructionSignedValue(opcode);
                    currentTask.stackPos--;
                    break;
                case jumpNotEqual:
                    if (currentTask.stack[currentTask.stackPos]._ivalue)
                        currentTask.pc += grGetInstructionSignedValue(opcode);
                    else
                        currentTask.pc++;
                    currentTask.stackPos--;
                    break;
                case list:
                    const GrInt listSize = grGetInstructionUnsignedValue(opcode);
                    GrList list = new GrList(listSize);
                    for (GrInt i = listSize - 1; i >= 0; i--)
                        list.push(currentTask.stack[currentTask.stackPos - i]);
                    currentTask.stackPos -= listSize - 1;
                    if (currentTask.stackPos == currentTask.stack.length)
                        currentTask.stack.length *= 2;
                    currentTask.stack[currentTask.stackPos]._ovalue = cast(GrPointer) list;
                    currentTask.pc++;
                    break;
                case index_list:
                    GrList list = cast(GrList) currentTask.stack[currentTask.stackPos - 1]._ovalue;
                    GrInt idx = currentTask.stack[currentTask.stackPos]._ivalue;
                    if (idx < 0) {
                        idx = list.size + idx;
                    }
                    if (idx >= list.size) {
                        raise(currentTask, "IndexError");
                        break;
                    }
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ovalue = &list._data[idx];
                    currentTask.pc++;
                    break;
                case index2_list:
                    GrList list = cast(GrList) currentTask.stack[currentTask.stackPos - 1]._ovalue;
                    GrInt idx = currentTask.stack[currentTask.stackPos]._ivalue;
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
                    GrList list = cast(GrList) currentTask.stack[currentTask.stackPos - 1]._ovalue;
                    GrInt idx = currentTask.stack[currentTask.stackPos]._ivalue;
                    if (idx < 0) {
                        idx = list.size + idx;
                    }
                    if (idx >= list.size) {
                        raise(currentTask, "IndexError");
                        break;
                    }
                    currentTask.stack[currentTask.stackPos - 1]._ovalue = &list._data[idx];
                    currentTask.stack[currentTask.stackPos] = list[idx];
                    currentTask.pc++;
                    break;
                case length_list:
                    currentTask.stack[currentTask.stackPos]._ivalue = (cast(
                            GrList) currentTask.stack[currentTask.stackPos]._ovalue).size;
                    currentTask.pc++;
                    break;
                case concatenate_list:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ovalue = cast(GrPointer) new GrList(
                        (cast(GrList) currentTask.stack[currentTask.stackPos]._ovalue).getValues() ~ (
                            cast(GrList) currentTask.stack[currentTask.stackPos + 1]._ovalue).getValues());
                    currentTask.pc++;
                    break;
                case append_list:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ovalue = cast(GrPointer) new GrList(
                        (cast(GrList) currentTask.stack[currentTask.stackPos]._ovalue).getValues() ~
                            currentTask.stack[currentTask.stackPos + 1]);
                    currentTask.pc++;
                    break;
                case prepend_list:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ovalue = cast(GrPointer) new GrList(
                        currentTask.stack[currentTask.stackPos] ~ (cast(
                            GrList) currentTask.stack[currentTask.stackPos + 1]._ovalue).getValues());
                    currentTask.pc++;
                    break;
                case equal_list:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue = (cast(
                            GrList) currentTask.stack[currentTask.stackPos]._ovalue).getValues() == (
                        cast(GrList) currentTask.stack[currentTask.stackPos + 1]._ovalue).getValues();
                    currentTask.pc++;
                    break;
                case notEqual_list:
                    currentTask.stackPos--;
                    currentTask.stack[currentTask.stackPos]._ivalue = (cast(
                            GrList) currentTask.stack[currentTask.stackPos]._ovalue).getValues() != (
                        cast(GrList) currentTask.stack[currentTask.stackPos + 1]._ovalue).getValues();
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
        if (builder)
            return new GrObject(*builder);
        return null;
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
        ulong functionNameLength = 10;
        ulong countLength = 10;
        ulong totalLength = 10;
        ulong averageLength = 10;
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
            debugFunc._name = _bytecode.sconsts[grGetInstructionUnsignedValue(opcode)];
            debugFunc._start = MonoTime.currTime();
            _debugFunctions[pc] = debugFunc;
            _debugFunctionsStack ~= debugFunc;
        }
    }
}
