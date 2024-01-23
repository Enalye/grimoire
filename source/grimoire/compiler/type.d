/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.compiler.type;

import std.conv : to;
import std.exception : enforce;

import grimoire.assembly;
import grimoire.runtime;
import grimoire.compiler.constraint;
import grimoire.compiler.data;
import grimoire.compiler.error;
import grimoire.compiler.mangle;

/// Représente un type pour le compilateur de grimoire
struct GrType {
    /// Catégorie du type. \
    /// Les types composés utilisent `mangledType` voire `mangledReturnType` en plus.
    enum Base {
        void_,
        null_,
        int_,
        uint_,
        byte_,
        char_,
        float_,
        double_,
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

    @property {
        /// Définit-il un type numérique ?
        bool isNumeric() const {
            return isIntegral() || isFloating();
        }

        /// Définit-il un type intégral ?
        bool isIntegral() const {
            switch (base) with (Base) {
            case int_:
            case uint_:
            case byte_:
                return true;
            default:
                return false;
            }
        }

        /// Définit-il un type à virgule flottante ?
        bool isFloating() const {
            switch (base) with (Base) {
            case float_:
            case double_:
                return true;
            default:
                return false;
            }
        }

        /// Priorité en fonction du type de nombre 
        uint numericPriority() const {
            switch (base) with (Base) {
            case byte_:
                return 1;
            case uint_:
                return 2;
            case int_:
                return 3;
            case float_:
                return 4;
            case double_:
                return 5;
            default:
                return 0;
            }
        }

        /// Est-il utilisable ?
        bool isValid() const {
            switch (base) with (Base) {
            case void_:
            case null_:
            case internalTuple:
                return false;
            default:
                return true;
            }
        }

        /// Est-il reservé au compilateur ?
        bool isInternal() const {
            switch (base) with (Base) {
            case void_:
            case null_:
            case internalTuple:
            case reference:
                return true;
            default:
                return false;
            }
        }

        /// Peut-il ne rien valoir ?
        bool isNullable() const {
            switch (base) with (Base) {
            case optional:
            case null_:
                return true;
            default:
                return false;
            }
        }
    }

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
/// Nombre flottant double précision
const GrType grDouble = GrType(GrType.Base.double_);
/// Type booléen
const GrType grBool = GrType(GrType.Base.bool_);
/// Type caractère
const GrType grChar = GrType(GrType.Base.char_);
/// Type octet
const GrType grByte = GrType(GrType.Base.byte_);
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
GrType grFunction(GrType[] inSignature = [], GrType[] outSignature = []) {
    GrType type = GrType.Base.func;
    type.mangledType = grMangleSignature(inSignature);
    type.mangledReturnType = grMangleSignature(outSignature);
    return type;
}

/// Renvoie une tâche avec sa signature
GrType grTask(GrType[] signature = []) {
    return GrType(GrType.Base.task, grMangleSignature(signature));
}

/// Renvoie un événement avec sa signature
GrType grEvent(GrType[] signature = []) {
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
    enforce!GrCompilerException(type.base == GrType.Base.internalTuple,
        "the packed value is not a tuple");
    return grUnmangleSignature(type.mangledType);
}

/// Représente une variable en grimoire
package final class GrVariable {
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
    size_t fileId;
    /// Sa position en cas d’erreurs
    uint lexPosition;
    /// Ditto
    bool hasLexPosition;
    /// La variable peut-elle ne rien valoir ?
    bool isOptional;
    /// Position de l’instruction optionnelle
    uint optionalPosition;

    /// Init
    this() {
    }

    /// Copie
    this(GrVariable other) {
        type = other.type;
        register = other.register;
        isGlobal = other.isGlobal;
        isField = other.isField;
        isInitialized = other.isInitialized;
        isAuto = other.isAuto;
        isConst = other.isConst;
        name = other.name;
        isExport = other.isExport;
        fileId = other.fileId;
        lexPosition = other.lexPosition;
        hasLexPosition = other.hasLexPosition;
        isOptional = other.isOptional;
        optionalPosition = other.optionalPosition;
    }
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
    size_t fileId;
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
    size_t fileId;

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
    /// S’il hérite d’un natif, sa référence
    GrNativeDefinition nativeParent;
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
            size_t fileId;
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
    size_t fileId;
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

    /// Valeurs d’initialisation
    union {
        /// Valeur entière
        GrInt intValue;
        /// Valeur entière non-signée
        GrUInt uintValue;
        /// Valeur sur 1 octet
        GrByte byteValue;
        /// Valeur flottante
        GrFloat floatValue;
        /// Valeur flottante double précision
        GrDouble doubleValue;
        /// Valeur textuelle
        string strValue;
    }

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
    size_t fileId;

    uint lexPosition, nameLexPosition;

    struct DebugPositionSymbol {
        size_t line, column;
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

    void makeClosure() {
        if (!anonParent || anonParent.name == "@global")
            return;

        registerAvailables = anonParent.registerAvailables.dup;
        scopes.length = 0;
        foreach (ref scope_; anonParent.scopes) {
            Scope nScope;
            foreach (string name, GrVariable var; scope_.localVariables) {
                nScope.localVariables[name] = new GrVariable(var);
            }
            scopes ~= nScope;
        }
        openScope();
        localsCount = anonParent.localsCount;
    }

    private void freeRegister(const GrVariable variable) {
        final switch (variable.type.base) with (GrType.Base) {
        case int_:
        case uint_:
        case byte_:
        case char_:
        case bool_:
        case func:
        case task:
        case event:
        case enum_:
        case float_:
        case double_:
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
    size_t fileId;

    string[] templateVariables;

    GrConstraint[] constraints;

    uint lexPosition, nameLexPosition;
}

package class GrFunctionCall {
    string name;
    GrType[] signature;
    uint position;
    GrFunction caller, functionToCall;
    GrType expectedType;
    bool isAddress;
    size_t fileId;
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
