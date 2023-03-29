/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.runtime.call;

import std.conv : to;
import std.exception : enforce;

import grimoire.assembly;
import grimoire.compiler;

import grimoire.runtime.channel;
import grimoire.runtime.closure;
import grimoire.runtime.event;
import grimoire.runtime.list;
import grimoire.runtime.object;
import grimoire.runtime.string;
import grimoire.runtime.task;
import grimoire.runtime.value;

/// Type des fonctions de rappel des primitives
alias GrCallback = void function(GrCall);
private GrValue[128] _outputs;

/// Contient les informations liées à l’exécution d’une primitive
final class GrCall {
    private {
        GrTask _task;
        GrCallback _callback;

        uint[] _parameters;
        int _params;
        int _results;
        bool _isInitialized;
        string _name;
        string[] _inSignature, _outSignature;
        GrValue[] _inputs;
    }

    @property {
        /// La tâche actuelle exécutant la primitive
        GrTask task() {
            return _task;
        }

        /// Informations supplémentaires de type du compilateur
        string meta() const {
            return _task.engine.meta;
        }
    }

    package(grimoire) this(GrCallback callback, string name,
        const ref GrBytecode.PrimitiveReference primRef) {
        _callback = callback;
        _name = name;

        _parameters = primRef.parameters.dup;

        _params = cast(int) primRef.params;

        _inSignature = primRef.inSignature.dup;
        _outSignature = primRef.outSignature.dup;
    }

    /// Exécution de la primitive
    void call(bool isSafe = false)(GrTask task) {
        _results = 0;
        _hasError = false;
        _task = task;

        const int stackIndex = (_task.stackPos + 1) - _params;

        static if (isSafe) {
            enforce(stackIndex >= 0,
                "stack corrupted before the call of the primitive `" ~ prettify() ~ "`");
        }

        _inputs = _task.stack[stackIndex .. _task.stackPos + 1];
        _callback(this);

        static if (isSafe) {
            enforce(_results == _outSignature.length || _hasError,
                "the primitive `" ~ prettify() ~ "` returned " ~ to!string(
                    _results) ~ " value(s) instead of " ~ to!string(_outSignature.length));
        }

        _task.stack.length = stackIndex + _results + 1;
        _task.stack[stackIndex .. stackIndex + _results] = _outputs[0 .. _results];
        _task.stackPos -= (_params - _results);

        if (_hasError)
            dispatchError();
    }

    string getInType(uint index) {
        return _inSignature[index];
    }

    string getOutType(uint index) {
        return _outSignature[index];
    }

    alias getValue = getParameter!GrValue;
    alias getBool = getParameter!GrBool;
    alias getInt = getParameter!GrInt;
    alias getUInt = getParameter!GrUInt;
    alias getChar = getParameter!GrChar;
    alias getByte = getParameter!GrByte;
    alias getFloat = getParameter!GrFloat;
    alias getDouble = getParameter!GrDouble;
    alias getPointer = getParameter!GrPointer;

    pragma(inline) GrBool isNull(uint index)
    in (index < _parameters.length,
        "parameter index `" ~ to!string(index) ~ "` exceeds the number of parameters") {
        return _inputs[index].isNull();
    }

    pragma(inline) T getEnum(T)(uint index) const {
        return cast(T) getParameter!GrInt(index);
    }

    pragma(inline) GrObject getObject(uint index) const {
        return cast(GrObject) getParameter!GrPointer(index);
    }

    pragma(inline) GrString getString(uint index) const {
        return cast(GrString) getParameter!GrPointer(index);
    }

    pragma(inline) GrList getList(uint index) const {
        return cast(GrList) getParameter!GrPointer(index);
    }

    pragma(inline) GrChannel getChannel(uint index) const {
        return cast(GrChannel) getParameter!GrPointer(index);
    }

    pragma(inline) GrEvent getEvent(uint index) const {
        return _task.engine.getEvent(cast(GrClosure) getParameter!GrPointer(index));
    }

    pragma(inline) T getNative(T)(uint index) const {
        // On change en objet d’abord pour éviter un plantage en changeant pour une classe mère
        return cast(T) cast(Object) getParameter!GrPointer(index);
    }

    pragma(inline) private T getParameter(T)(uint index) const
    in (index < _parameters.length,
        "parameter index `" ~ to!string(index) ~ "` exceeds the number of parameters") {
        static if (is(T == GrValue)) {
            return _inputs[index];
        }
        else static if (is(T == GrInt)) {
            return _inputs[index].getInt();
        }
        else static if (is(T == GrUInt)) {
            return _inputs[index].getUInt();
        }
        else static if (is(T == GrChar)) {
            return _inputs[index].getChar();
        }
        else static if (is(T == GrByte)) {
            return _inputs[index].getByte();
        }
        else static if (is(T == GrBool)) {
            return _inputs[index].getInt() > 0;
        }
        else static if (is(T == GrFloat)) {
            return _inputs[index].getFloat();
        }
        else static if (is(T == GrDouble)) {
            return _inputs[index].getDouble();
        }
        else static if (is(T == GrPointer)) {
            return _inputs[index].getPointer();
        }
    }

    alias setValue = setResult!GrValue;
    alias setBool = setResult!GrBool;
    alias setInt = setResult!GrInt;
    alias setUInt = setResult!GrUInt;
    alias setChar = setResult!GrChar;
    alias setByte = setResult!GrByte;
    alias setFloat = setResult!GrFloat;
    alias setDouble = setResult!GrDouble;
    alias setPointer = setResult!GrPointer;

    pragma(inline) void setNull() {
        _outputs[_results].setNull();
        _results++;
    }

    pragma(inline) void setEnum(T)(T value) {
        setResult!GrInt(cast(GrInt) value);
    }

    pragma(inline) void setString(GrString value) {
        setResult!GrPointer(cast(GrPointer) value);
    }

    pragma(inline) void setString(string value) {
        setResult!GrPointer(cast(GrPointer) new GrString(value));
    }

    pragma(inline) void setString(dstring value) {
        setResult!GrPointer(cast(GrPointer) new GrString(value));
    }

    pragma(inline) void setString(GrChar[] value) {
        setResult!GrPointer(cast(GrPointer) new GrString(value));
    }

    pragma(inline) void setList(GrList value) {
        setResult!GrPointer(cast(GrPointer) value);
    }

    pragma(inline) void setList(GrValue[] value) {
        setResult!GrPointer(cast(GrPointer) new GrList(value));
    }

    pragma(inline) void setChannel(GrChannel value) {
        setResult!GrPointer(cast(GrPointer) value);
    }

    pragma(inline) void setObject(GrObject value) {
        setResult!GrPointer(cast(GrPointer) value);
    }

    pragma(inline) void setEvent(GrEvent value) {
        enforce(value.closure, "event has no closure");
        setResult!GrPointer(cast(GrPointer) value.closure);
    }

    pragma(inline) void setNative(T)(T value) {
        setResult!GrPointer(*cast(GrPointer*)&value);
    }

    pragma(inline) private void setResult(T)(T value) {
        static if (is(T == GrValue)) {
            _outputs[_results] = value;
        }
        else static if (is(T == GrInt)) {
            _outputs[_results].setInt(value);
        }
        else static if (is(T == GrUInt)) {
            _outputs[_results].setUInt(value);
        }
        else static if (is(T == GrChar)) {
            _outputs[_results].setChar(value);
        }
        else static if (is(T == GrByte)) {
            _outputs[_results].setByte(value);
        }
        else static if (is(T == GrBool)) {
            _outputs[_results].setInt(cast(GrInt) value);
        }
        else static if (is(T == GrFloat)) {
            _outputs[_results].setFloat(value);
        }
        else static if (is(T == GrDouble)) {
            _outputs[_results].setDouble(value);
        }
        else static if (is(T == GrString)) {
            _outputs[_results].setString(value);
        }
        else static if (is(T == GrPointer)) {
            _outputs[_results].setPointer(value);
        }
        _results++;
    }

    GrBool getBoolVariable(string name) const {
        return _task.engine.getBoolVariable(name);
    }

    GrInt getIntVariable(string name) const {
        return _task.engine.getIntVariable(name);
    }

    GrUInt getUIntVariable(string name) const {
        return _task.engine.getUIntVariable(name);
    }

    GrChar getCharVariable(string name) const {
        return _task.engine.getCharVariable(name);
    }

    GrByte getByteVariable(string name) const {
        return _task.engine.getByteVariable(name);
    }

    T getEnumVariable(T)(string name) const {
        return cast(T) _task.engine.getEnumVariable(T)(name);
    }

    GrFloat getFloatVariable(string name) const {
        return _task.engine.getFloatVariable(name);
    }

    GrFloat getDoubleVariable(string name) const {
        return _task.engine.getDoubleVariable(name);
    }

    GrPointer getPointerVariable(string name) const {
        return cast(GrPointer) _task.engine.getPointerVariable(name);
    }

    GrString getStringVariable(string name) const {
        return cast(GrString) _task.engine.getStringVariable(name);
    }

    GrList getListVariable(string name) const {
        return cast(GrList) _task.engine.getListVariable(name);
    }

    GrChannel getChannelVariable(string name) const {
        return cast(GrChannel) _task.engine.getChannelVariable(name);
    }

    GrObject getObjectVariable(string name) const {
        return cast(GrObject) _task.engine.getObjectVariable(name);
    }

    T getNativeVariable(T)(string name) const {
        return cast(T) _task.engine.getNativeVariable(T)(name);
    }

    void setBoolVariable(string name, GrBool value) {
        _task.engine.setBoolVariable(name, value);
    }

    void setIntVariable(string name, GrInt value) {
        _task.engine.setIntVariable(name, value);
    }

    void setUIntVariable(string name, GrUInt value) {
        _task.engine.setUIntVariable(name, value);
    }

    void setCharVariable(string name, GrChar value) {
        _task.engine.setCharVariable(name, value);
    }

    void setByteVariable(string name, GrByte value) {
        _task.engine.setByteVariable(name, value);
    }

    void setDoubleVariable(string name, GrDouble value) {
        _task.engine.setDoubleVariable(name, value);
    }

    void setStringVariable(string name, string value) {
        _task.engine.setStringVariable(name, value);
    }

    void setListVariable(string name, GrValue[] value) {
        _task.engine.setListVariable(name, value);
    }

    void setPointerVariable(string name, GrPointer value) {
        _task.engine.setPointerVariable(name, value);
    }

    void setObjectVariable(string name, GrObject value) {
        _task.engine.setObjectVariable(name, value);
    }

    void setChannelVariable(string name, GrChannel value) {
        _task.engine.setChannelVariable(name, value);
    }

    void setEnumVariable(T)(string name, T value) {
        _task.engine.setEnumVariable(name, value);
    }

    void setNativeVariable(T)(string name, T value) {
        _task.engine.setNativeVariable(name, value);
    }

    private {
        string _message;
        bool _hasError;
    }

    /// N’envoie pas de suite l’erreur vers la tâche, \
    /// sinon la pile serait dans un état indéfini. \
    /// On attend donc jusqu’à ce que la primitive finisse avant \
    /// d’appeler `dispatchError()`.
    void raise(GrString message) {
        _message = message.str;
        _hasError = true;
    }
    /// Ditto
    void raise(string message) {
        _message = message;
        _hasError = true;
    }

    private void dispatchError() {
        _task.engine.raise(_task, _message);

        // La tâche est toujours dans un appel de primitive
        // et va incrémenter le compteur d’instruction,
        // on évite donc ça.
        _task.pc--;
    }

    /// Instancie un nouvel objet
    GrObject createObject(string name) {
        return _task.engine.createObject(name);
    }

    /// Récupère le nom du champ de l’énumération correspondant à une valeur donnée
    string getEnumFieldName(string enumName, int fieldValue) {
        return _task.engine.getEnumFieldName(enumName, fieldValue);
    }

    /// Récupère la valeur du champ de l’énumération correspondant à un nom donné
    int getEnumFieldValue(string enumName, string fieldName) {
        return _task.engine.getEnumFieldValue(enumName, fieldName);
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
        return _task.engine.callEvent(name, signature, parameters);
    }
    /// Ditto
    GrTask callEvent(GrEvent event, GrValue[] parameters = []) {
        return _task.engine.callEvent(event, parameters);
    }

    /// Met en suspend la tâche actuelle
    void block(GrBlocker blocker) {
        _task.block(blocker);
    }

    /// Formate la primitive pour la rendre affichable
    string prettify() const {
        GrType[] inSig, outSig;
        foreach (string type; _inSignature) {
            inSig ~= grUnmangle(type);
        }
        foreach (string type; _outSignature) {
            outSig ~= grUnmangle(type);
        }

        return grGetPrettyFunction(_name, inSig, outSig);
    }
}
