/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.compiler.type;

import std.conv : to;
import std.exception : enforce;

import grimoire.runtime;
import grimoire.assembly;
import grimoire.compiler.mangle;
import grimoire.compiler.data;
import grimoire.compiler.constraint;

/// Représente un type pour le compilateur de grimoire
struct GrType {
    /// Catégorie du type. \
    /// Les types composés utilisent `mangledType` voire `mangledReturnType` en plus.
    enum Base {
        void_,
        null_,
        int_,
        uint_,
        char_,
        float_,
        bool_,
        string_,
        optional,
        list,
        func,
        task,
        event,
        class_,
        native,
        channel,
        enum_,
        internalTuple,
        reference
    }

    /// Ditto
    Base base;
    /// Utilisés pour les types composés comme les listes, les fonctions, etc
    string mangledType, mangledReturnType;
    /// Est-ce un champ d’une classe ?
    bool isField;
    /// Est-ce un type générique ?
    bool isAny;
    /// Le type est-il abstrait ?
    /// Un type abstrait ne peut être utilisé dans une signature.
    bool isAbstract;
    /// Le type est-il mutable ?
    bool isPure;

    /// Type simple
    this(Base base_) {
        base = base_;
    }

    /// Type composé
    this(Base base_, string mangledType_) {
        base = base_;
        mangledType = mangledType_;
    }

    /// Assigne simplement un type basique
    GrType opOpAssign(string op)(GrType.Base t) {
        mixin("base = base" ~ op ~ "t;");
        return this;
    }

    /// Vérifie l’égalité avec le type de base
    bool opEquals(const GrType.Base v) const {
        return (base == v);
    }

    /// Vérifie l’égalité complète entre les types
    bool opEquals(const GrType v) const {
        if (base != v.base)
            return false;
        if (base == GrType.Base.func)
            return mangledType == v.mangledType && mangledReturnType == v.mangledReturnType;
        if (base == GrType.Base.task || base == GrType.Base.event)
            return mangledType == v.mangledType;
        if (base == GrType.Base.native || base == GrType.Base.class_ ||
            base == GrType.Base.enum_ || base == GrType.Base.list)
            return mangledType == v.mangledType;
        return true;
    }

    /// Juste pour désactiver les avertissement à cause de `opEquals`
    size_t toHash() const @safe pure nothrow {
        return 0;
    }
}

/// Aucun type
const GrType grVoid = GrType(GrType.Base.void_);
/// Nombre entier
const GrType grInt = GrType(GrType.Base.int_);
/// Nombre entier non-signé
const GrType grUInt = GrType(GrType.Base.uint_);
/// Nombre flottant
const GrType grFloat = GrType(GrType.Base.float_);
/// Type booléen
const GrType grBool = GrType(GrType.Base.bool_);
/// Type caractère
const GrType grChar = GrType(GrType.Base.char_);
/// Chaîne de caractères
const GrType grString = GrType(GrType.Base.string_);

/// Crée une version optionnel du type
GrType grOptional(GrType subType) {
    GrType type = GrType(GrType.Base.optional, grMangleSignature([subType]));
    type.isPure = subType.isPure;
    return type;
}

/// Renvoie un `GrType` liste avec en sous-type `subType`
GrType grList(GrType subType) {
    return GrType(GrType.Base.list, grMangleSignature([subType]));
}

/// Renvoie un `GrType` canal avec en sous-type `subType`
GrType grChannel(GrType subType) {
    return GrType(GrType.Base.channel, grMangleSignature([subType]));
}

/// Renvoie une fonction avec sa signature
GrType grFunction(GrType[] inSignature, GrType[] outSignature = []) {
    GrType type = GrType.Base.func;
    type.mangledType = grMangleSignature(inSignature);
    type.mangledReturnType = grMangleSignature(outSignature);
    return type;
}

/// Renvoie une tâche avec sa signature
GrType grTask(GrType[] signature) {
    return GrType(GrType.Base.task, grMangleSignature(signature));
}

/// Renvoie un événement avec sa signature
GrType grEvent(GrType[] signature) {
    return GrType(GrType.Base.event, grMangleSignature(signature));
}

/// Type générique
GrType grAny(string name) {
    GrType type;
    type.base = GrType.Base.void_;
    type.mangledType = name;
    type.isAny = true;
    return type;
}

/// Rend le type pur
GrType grPure(GrType type) {
    type.isPure = true;
    return type;
}

/// Est-ce que le type est considéré comme un entier par la machine virtuelle ?
bool grIsKindOfInt(GrType.Base type) {
    return type == GrType.Base.int_ || type == GrType.Base.bool_ ||
        type == GrType.Base.func || type == GrType.Base.task ||
        type == GrType.Base.event || type == GrType.Base.enum_;
}

/// Est-ce que le type est considéré comme un flottant par la machine virtuelle ?
bool grIsKindOfFloat(GrType.Base type) {
    return type == GrType.Base.float_;
}

/// Est-ce que le type est considéré comme une chaîne de caractères par la machine virtuelle ?
bool grIsKindOfString(GrType.Base type) {
    return type == GrType.Base.string_;
}

/// Est-ce que le type est considéré comme un pointeur par la machine virtuelle ?
bool grIsKindOfObject(GrType.Base type) {
    return type == GrType.Base.class_ || type == GrType.Base.list ||
        type == GrType.Base.native || type == GrType.Base.channel ||
        type == GrType.Base.reference || type == GrType.Base.null_;
}

/// Contexte pour la validation des types génériques
final class GrAnyData {
    private {
        GrType[string] _types;
    }

    /// Nettoie toutes les définitions de type
    void clear() {
        _types.clear;
    }

    /// Definit un nouveau type
    void set(const string key, GrType type) {
        _types[key] = type;
    }

    /// Rècupère un type défini
    GrType get(const string key) const {
        return _types.get(key, grVoid);
    }
}

/// Emballe plusieurs types en un seul
package GrType grPackTuple(const GrType[] types) {
    const string mangledName = grMangleSignature(types);
    GrType type = GrType.Base.internalTuple;
    type.mangledType = mangledName;
    return type;
}

/// Déballe plusieurs types depuis un seul
package GrType[] grUnpackTuple(GrType type) {
    enforce(type.base == GrType.Base.internalTuple, "the packed value is not a tuple");
    return grUnmangleSignature(type.mangledType);
}

/// Représente une variable en grimoire
package class GrVariable {
    /// Type de la variable
    GrType type;
    /// Son registre
    uint register = uint.max;
    /// Est-ce une variable globale ?
    bool isGlobal;
    /// Est-ce un champ d’une classe ?
    bool isField;
    /// Est-ce qu’elle a une valeur initiale ?
    bool isInitialized;
    /// Le type doit-il être inféré automatiquement ?
    bool isAuto;
    /// La variable est-elle réassignable ?
    bool isConst;
    /// Son nom unique dans la portée
    string name;
    /// Est-elle visible depuis les autres fichiers ?
    bool isExport;
    /// Le fichier d’où elle est déclarée
    uint fileId;
    /// Sa position en cas d’erreurs
    uint lexPosition;
    /// La variable peut-elle ne rien valoir ?
    bool isOptional;
    /// Position de l’instruction optionnelle
    uint optionalPosition;
}

/// Représente un type opaque
final class GrNativeDefinition {
    /// Identificateur
    string name;
    /// Sa classe mère
    string parent;
}

/// Ditto
final class GrAbstractNativeDefinition {
    /// Identificateur
    string name;
    /// Sa classe mère
    string parent;
    /// Nom des types génériques
    string[] templateVariables;
    /// La signature générique de sa classe mère
    GrType[] parentTemplateSignature;
}

/// Renvoie un type natif
GrType grGetNativeType(string name, const GrType[] signature = []) {
    GrType type = GrType.Base.native;
    type.mangledType = grMangleComposite(name, signature);
    return type;
}

/**
Definit un alias de type.
---
alias NouveauType: AutreType;
---
*/
final class GrTypeAliasDefinition {
    /// Identificateur
    string name;
    /// The type aliased.
    GrType type;
    /// Is the type visible from other files ?
    bool isExport;
    /// The file where the type is declared.
    uint fileId;
}

/**
Definit une énumération.
---
enum MonÉnum {
    champ1;
    champ2;
}
---
*/
final class GrEnumDefinition {
    /// Champ de l’énumération
    struct Field {
        /// Noms du champs
        string name;
        /// Valeur du champs
        int value;
    }
    /// Identificateur
    string name;
    /// Les différents champs de l’énumération
    Field[] fields;
    /// L’id de l’énumération
    size_t index;
    /// Est-il visible depuis les autres fichiers ?
    bool isExport;
    /// Le fichier d’où il a été déclaré
    uint fileId;

    /// Est-ce qu’il a ce champ ?
    bool hasField(const string name_) const {
        foreach (field; fields) {
            if (field.name == name_)
                return true;
        }
        return false;
    }

    /// Renvoie l’index du champ
    int getField(const string name_) const {
        import std.conv : to;

        int fieldIndex = 0;
        foreach (field; fields) {
            if (field.name == name_)
                return field.value;
            fieldIndex++;
        }
        assert(false, "enum `" ~ name ~ "` has no field called `" ~ name_ ~ "`");
    }
}

/// Renvoie une énumération
GrType grGetEnumType(const string name) {
    GrType stType = GrType.Base.enum_;
    stType.mangledType = name;
    return stType;
}

/**
Definit une classe.
---
class MaClasse<T> : Parent<T> {
    // Fields
}
---
*/
final class GrClassDefinition {
    /// Identificateur
    string name;
    /// Sa classe mère
    string parent;
    /// Types des champs
    GrType[] signature;
    /// Noms des champs
    string[] fields;
    /// Est-ce que les champs sont constants ?
    bool[] fieldConsts;
    /// Les variables de type génériques
    string[] templateVariables;
    /// Liste des types génériques
    GrType[] templateTypes, parentTemplateSignature;

    package {
        struct FieldInfo {
            bool isExport;
            uint fileId;
            uint position;
        }

        FieldInfo[] fieldsInfo;

        /// Le lexème qui l’a déclaré
        uint position;
    }
    /// L’id de la classe
    size_t index;
    /// Est-elle visible depuis d’autres fichiers ?
    bool isExport;
    /// Le fichier dans lequel elle est déclarée
    uint fileId;
    /// A-t’elle déjà été analysé ?
    bool isParsed;
}

/// Renvoie une classe
GrType grGetClassType(const string name, const GrType[] signature = []) {
    GrType type = GrType.Base.class_;
    type.mangledType = grMangleComposite(name, signature);
    return type;
}

/// Definit une variable depuis une bibliothèque
final class GrVariableDefinition {
    /// Identificateur
    string name;
    /// Son type
    GrType type;
    /// Le type est-il assignable ?
    bool isConst;
    /// A-t’elle une valeur d’initialisation ?
    bool isInitialized;
    /// Valeur entière d’initialisation
    GrInt ivalue;
    /// Valeur entière non-signée d’initialisation
    GrInt uvalue;
    /// Valeur flottante d’initialisation
    GrFloat fvalue;
    /// Valeur textuelle d’initialisation
    string svalue;
    /// Registre
    uint register;
}

/// Instruction utilisé par la machine virtuelle
struct GrInstruction {
    /// Le type d’opération a effectuer
    GrOpcode opcode;
    /// Valeur optionnelle, dépend du type d’opcode
    uint value;
}

/// Fonction, tâche ou événement
package class GrFunction {
    /// Portée locale
    struct Scope {
        /// Toutes les variables déclarées dans cette portée
        GrVariable[string] localVariables;
    }
    /// Ditto
    Scope[] scopes;

    uint[] registerAvailables;

    /// Les instructions appartenant à la fonction
    GrInstruction[] instructions;
    uint stackSize, index, offset;

    /// Nom de base de la fonction
    string name;
    /// Nom décoré de la fonction
    string mangledName;
    /// Noms des paramètres de la fonction
    string[] inputVariables, templateVariables;
    /// Types des paramètres de la fonction
    GrType[] inSignature, outSignature, templateSignature;
    bool isTask, isAnonymous, isEvent;

    /// Les appels de fonction effectués depuis cette fonction
    GrFunctionCall[] functionCalls;
    GrFunction anonParent;
    uint position, anonReference;

    uint nbParameters;
    uint localsCount;

    GrDeferrableSection[] deferrableSections;
    GrDeferBlock[] registeredDeferBlocks;
    bool[] isDeferrableSectionLocked = [false];

    /// Est-elle visible depuis d’autres fichiers ?
    bool isExport;
    /// Le fichier d’où cette fonction est déclarée
    uint fileId;

    uint lexPosition;

    struct DebugPositionSymbol {
        uint line, column;
    }

    DebugPositionSymbol[] debugSymbol;

    this() {
        scopes.length = 1;
    }

    GrVariable getLocal(string name) {
        foreach_reverse (ref Scope scope_; scopes) {
            // On vérifie si elle est déclarée localement
            GrVariable* variable = (name in scope_.localVariables);
            if (variable !is null)
                return *variable;
        }
        return null;
    }

    void setLocal(GrVariable variable_) {
        GrVariable* oldVariable = (variable_.name in scopes[$ - 1].localVariables);
        if (oldVariable !is null) {
            freeRegister(*oldVariable);
        }
        scopes[$ - 1].localVariables[variable_.name] = variable_;
    }

    void openScope() {
        scopes.length++;
    }

    void closeScope() {
        foreach (GrVariable variable; scopes[$ - 1].localVariables) {
            freeRegister(variable);
        }
        scopes.length--;
    }

    private void freeRegister(const GrVariable variable) {
        final switch (variable.type.base) with (GrType.Base) {
        case int_:
        case uint_:
        case char_:
        case bool_:
        case func:
        case task:
        case event:
        case enum_:
        case float_:
        case string_:
        case list:
        case optional:
        case class_:
        case native:
        case channel:
            registerAvailables ~= variable.register;
            break;
        case internalTuple:
        case reference:
        case null_:
        case void_:
            break;
        }
    }
}

/// Renvoie la fonction en tant que type
GrType grGetFunctionAsType(const GrFunction func) {
    GrType type = func.isEvent ? GrType.Base.event : (func.isTask ?
            GrType.Base.task : GrType.Base.func);
    type.mangledType = grMangleSignature(func.inSignature);
    type.mangledReturnType = grMangleSignature(func.outSignature);
    return type;
}

package class GrTemplateFunction {
    /// Unmangled function name.
    string name;
    /// Function input parameters' name.
    string[] inputVariables;
    /// Function parameters' type.
    GrType[] inSignature, outSignature;
    bool isTask;
    bool isConversion;
    /// Is the function visible from other files ?
    bool isExport;
    /// The file where the template is declared.
    uint fileId;

    string[] templateVariables;

    GrConstraint[] constraints;

    uint lexPosition;
}

package class GrFunctionCall {
    string name;
    GrType[] signature;
    uint position;
    GrFunction caller, functionToCall;
    GrType expectedType;
    bool isAddress;
    uint fileId;
}

package class GrDeferrableSection {
    GrDeferBlock[] deferredBlocks;
    uint deferInitPositions;
    uint[] deferredCalls;
}

package class GrDeferBlock {
    uint position;
    uint parsePosition;
    uint scopeLevel;
}
