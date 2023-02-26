/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.runtime.task;

import std.exception : enforce;

import grimoire.assembly;

import grimoire.runtime.engine;
import grimoire.runtime.value;
import grimoire.runtime.string;
import grimoire.runtime.list;
import grimoire.runtime.channel;
import grimoire.runtime.object;

/// Représente un appel de fonction dans la pile d’appels
struct GrStackFrame {
    /// Nombre de variables locales dans la fonction
    uint localStackSize;
    /// Position de retour
    uint retPosition;
    /// Les portions de code différées
    uint[] deferStack;
    /// Les gestionnaires d’exceptions
    uint[] exceptionHandlers;
}

/// Aperçu de l’état de la tâche. \
/// Permet la restauration de la tâche à un état antérieur.
struct GrTaskState {
    /// Position actuelle dans la pile des valeurs
    int stackPos;

    /// Pile d’appel
    GrStackFrame stackFrame;

    /// Position dans la pile d’appel
    uint stackFramePos;

    /// Adresse de début de l’espace locale des variables de la fonction. \
    /// On y accède avec `locals[localsPos + variableIndex]`.
    uint localsPos;
}

/// Met en pause une tâche
abstract class GrBlocker {
    /// Met à jour le bloqueur. \
    /// Retourne `true` tant que la tâche est en pause.
    bool run();
}

/// Tâche représentant un fil d’exécution indépendant et concurrent (coroutine)
final class GrTask {
    this(GrEngine engine_) {
        engine = engine_;
        setupCallStack(4);
        setupStack(8);
        setupLocals(2);
    }

    /// La machine virtuelle
    GrEngine engine;

    /// Pile des variables locales
    GrValue[] locals;

    /// Pile d’appel
    GrStackFrame[] callStack;

    /// Pile d’opérations
    GrValue[] stack;

    /// Pointeur d’instruction
    uint pc;

    /// Adresse de début de l’espace locale des variables de la fonction. \
    /// On y accède avec `locals[localsPos + variableIndex]`.
    uint localsPos;

    /// Position dans la pile d’appel
    uint stackFramePos;

    /// Position dans la pile d’opérations
    int stackPos = -1;

    /// Fin de la tâche, déroule toute la pile d’appel et exécute toutes les instructions différées
    bool isKilled;

    /// Une exception a été lancé et n’est pas capturé
    bool isPanicking;

    /// Quand la tâche est dans un bloc `select/case`. \
    /// Empêche les canaux de bloquer la tâche.
    bool isEvaluatingChannel;

    /// Quand la tâche est préempté par un canal bloquant. \
    /// Relaché quand le canal est prêt.
    bool isLocked;

    /// Durant une évaluation, un saut se fera vers cette position au lieu de bloquer
    uint selectPositionJump;

    /// La tâche est en pause tant que le bloqueur est là
    GrBlocker blocker;

    /// Point de restauration de l’état de la tâche après un `select`
    GrTaskState[] states;

    /// Profondeur maximale de la pile d’appel
    uint callStackLimit;
    /// Taille maximale de la pile des variables locales
    uint localsLimit;

    /// Initialise la pile d’appel
    void setupCallStack(uint size) {
        callStackLimit = size;
        callStack = new GrStackFrame[callStackLimit];
    }

    /// Initialise la pile d’opérations
    void setupStack(uint size) {
        stack = new GrValue[size];
    }

    /// Initialise la pile des variables locales
    void setupLocals(uint size) {
        localsLimit = size;
        locals = new GrValue[localsLimit];
    }

    /// Double la taille de la pile d’appel
    void doubleCallStackSize() {
        callStackLimit <<= 1;
        callStack.length = callStackLimit;
    }

    /// Double la taille de la pile des variables locales
    void doubleLocalsStackSize(uint localsStackSize) {
        while (localsStackSize >= localsLimit)
            localsLimit <<= 1;
        locals.length = localsLimit;
    }

    alias setValue = setParameter!GrValue;
    alias setBool = setParameter!GrBool;
    alias setInt = setParameter!GrInt;
    alias setFloat = setParameter!GrFloat;
    alias setPointer = setParameter!GrPointer;

    pragma(inline) void setObject(GrObject value) {
        setParameter!GrPointer(cast(GrPointer) value);
    }

    pragma(inline) void setString(GrString value) {
        setParameter!GrPointer(cast(GrPointer) value);
    }

    pragma(inline) void setString(string value) {
        setParameter!GrPointer(cast(GrPointer) new GrString(value));
    }

    pragma(inline) void setList(GrList value) {
        setParameter!GrPointer(cast(GrPointer) value);
    }

    pragma(inline) void setList(GrValue[] value) {
        setParameter!GrPointer(cast(GrPointer) new GrList(value));
    }

    pragma(inline) void setChannel(GrChannel value) {
        setParameter!GrPointer(cast(GrPointer) value);
    }

    pragma(inline) void setEnum(T)(T value) {
        setParameter!GrInt(cast(GrInt) value);
    }

    pragma(inline) void setNative(T)(T value) {
        setParameter!GrPointer(cast(GrPointer) value);
    }

    pragma(inline) private void setParameter(T)(T value) {
        static if (is(T == GrInt) || is(T == GrBool)) {
            stackPos++;
            stack[stackPos].setInt(value);
        }
        else static if (is(T == GrFloat)) {
            stackPos++;
            stack[stackPos].setFloat(value);
        }
        else static if (is(T == GrPointer)) {
            stackPos++;
            stack[stackPos].setPointer(value);
        }
    }

    /// Enregistre un aperçu de l’état de la tâche
    void pushState() {
        GrTaskState state;
        state.stackPos = stackPos;
        state.stackFramePos = stackFramePos;
        state.stackFrame = callStack[stackFramePos];
        state.localsPos = localsPos;
        states ~= state;
    }

    /// Récupère un aperçu de l’état de la tâche
    void restoreState() {
        enforce(states.length, "no task state to restore");

        GrTaskState state = states[$ - 1];
        stackPos = state.stackPos;
        stackFramePos = state.stackFramePos;
        localsPos = state.localsPos;
        callStack[stackFramePos] = state.stackFrame;
    }

    /// Retire le dernier aperçu de l’état de la tâche
    void popState() {
        states.length--;
    }

    /// Bloque l’exécution de la tâche tant que le bloqueur est présent
    void block(GrBlocker blocker_) {
        blocker = blocker_;
    }

    /// Débloque la tâche du bloqueur
    void unblock() {
        blocker = null;
    }
}
