module grimoire.compiler.doc;

import std.conv : to;
import std.algorithm : min, sort;

import grimoire.runtime;
import grimoire.compiler.constraint;
import grimoire.compiler.library;
import grimoire.compiler.mangle;
import grimoire.compiler.pretty;
import grimoire.compiler.primitive;
import grimoire.compiler.type;
import grimoire.compiler.util;

/// Contient les informations de types et les primitives de façon à générer une documentation
final class GrDoc : GrLibDefinition {
    private {
        string _module;
        string[GrLocale] _moduleInfo, _moduleDescription, _moduleExample, _comments, _examples;
        string[] _parameters;

        struct Variable {
            GrType type;
            string name;
            bool hasValue, isConst;
            GrValue value;
            string[GrLocale] comments;
        }

        struct Enum {
            string name;
            string[] fields;
            string[GrLocale] comments;
        }

        struct Alias {
            string name;
            GrType type;
            string[GrLocale] comments;
        }

        struct Field {
            string name;
            GrType type;
            string[GrLocale] comments;
        }

        struct Class {
            string name, parent;
            Field[] fields;
            string[] templates;
            GrType[] parentTemplates;
            string[GrLocale] comments;
        }

        struct Native {
            string name, parent;
            string[] templates;
            GrType[] parentTemplates;
            string[GrLocale] comments;
        }

        struct Function {
            string name;
            GrType[] inSignature, outSignature;
            GrConstraint[] constraints;
            string[GrLocale] comments;
            string[GrLocale] examples;
            string[] parameters;
        }

        struct OperatorFunction {
            string name;
            GrType[] inSignature;
            GrType outType;
            GrConstraint[] constraints;
            string[GrLocale] comments;
        }

        struct Cast {
            GrType srcType, dstType;
            GrConstraint[] constraints;
            bool isExplicit;
            string[GrLocale] comments;
        }

        struct Constructor {
            GrType type;
            GrType[] inSignature;
            GrConstraint[] constraints;
            string[GrLocale] comments;
            string[] parameters;
        }

        struct Static {
            GrType type;
            string name;
            GrType[] inSignature, outSignature;
            GrConstraint[] constraints;
            string[GrLocale] comments;
            string[GrLocale] examples;
            string[] parameters;
        }

        struct Property {
            string name;
            GrType nativeType, propertyType;
            GrConstraint[] constraints;
            bool hasGet, hasSet;
            string[GrLocale] comments;
        }

        struct Constraint {
            string name;
            uint arity;
            string[GrLocale] comments;
        }

        Variable[] _variables;
        Enum[] _enums;
        Class[] _classes;
        Native[] _natives;
        Alias[] _aliases;
        OperatorFunction[] _operators;
        Constructor[] _constructors;
        Static[] _statics;
        Cast[] _casts;
        Function[] _functions;
        Property[] _properties;
        Constraint[] _constraints;
    }

    this(string moduleName)
    in (moduleName.length) {
        _module = moduleName;
    }

    override void setModule(string name) {
        _module = name;
    }

    string getModule() {
        return _module;
    }

    override void setModuleInfo(GrLocale locale, string msg) {
        _moduleInfo[locale] = msg;
    }

    override void setModuleDescription(GrLocale locale, string msg) {
        _moduleDescription[locale] = msg;
    }

    override void setModuleExample(GrLocale locale, string msg) {
        _moduleExample[locale] = msg;
    }

    override void setDescription(GrLocale locale, string message = "") {
        import std.array : replace;

        _comments[locale] = message.replace("\n", "\n\n");
    }

    override void setExample(GrLocale locale, string message = "") {
        import std.array : replace;

        _examples[locale] = message.replace("\n", "\n\n");
    }

    override void setParameters(string[] parameters = []) {
        _parameters = parameters;
    }

    override GrType addVariable(string name, GrType type) {
        Variable var;
        var.name = name;
        var.type = type;
        var.comments = _comments.dup;
        _variables ~= var;
        return type;
    }

    override GrType addVariable(string name, GrType type, GrValue value, bool isConst = false) {
        Variable var;
        var.name = name;
        var.type = type;
        var.hasValue = true;
        var.value = value;
        var.isConst = isConst;
        var.comments = _comments.dup;
        _variables ~= var;
        return type;
    }

    override GrType addEnum(string name, string[] fieldNames, int[] values = []) {
        Enum enum_;
        enum_.name = name;
        enum_.fields = fieldNames;
        enum_.comments = _comments.dup;
        _enums ~= enum_;

        GrType type = GrType.Base.enum_;
        type.mangledType = name;
        return type;
    }

    override GrType addEnum(string name, GrNativeEnum loader) {
        return addEnum(name, loader.fields, loader.values);
    }

    override GrType addClass(string name, string[] fields, GrType[] signature,
        string[] templateVariables = [], string parent = "", GrType[] parentTemplateSignature = [
        ]) {
        Class class_;
        class_.name = name;
        const size_t fieldsCount = min(fields.length, signature.length);
        for (size_t i; i < fieldsCount; ++i) {
            Field field;
            field.name = fields[i];
            field.type = signature[i];
            class_.fields ~= field;
        }
        class_.templates = templateVariables;
        class_.parent = parent;
        class_.parentTemplates = parentTemplateSignature;
        class_.comments = _comments.dup;
        _classes ~= class_;

        GrType type = GrType.Base.class_;
        GrType[] anySignature;
        foreach (tmp; templateVariables) {
            anySignature ~= grAny(tmp);
        }
        type.mangledType = grMangleComposite(name, anySignature);
        return type;
    }

    override GrType addAlias(string name, GrType type) {
        Alias alias_;
        alias_.name = name;
        alias_.type = type;
        alias_.comments = _comments.dup;
        _aliases ~= alias_;
        return type;
    }

    override GrType addNative(string name, string[] templateVariables = [],
        string parent = "", GrType[] parentTemplateSignature = []) {
        Native native;
        native.name = name;
        native.templates = templateVariables;
        native.parent = parent;
        native.parentTemplates = parentTemplateSignature;
        native.comments = _comments.dup;
        _natives ~= native;

        GrType type = GrType.Base.native;
        GrType[] anySignature;
        foreach (tmp; templateVariables) {
            anySignature ~= grAny(tmp);
        }
        type.mangledType = grMangleComposite(name, anySignature);
        return type;
    }

    override GrPrimitive addFunction(GrCallback, string name, GrType[] inSignature = [
        ], GrType[] outSignature = [], GrConstraint[] constraints = []) {
        Function func;
        func.name = name;
        func.inSignature = inSignature;
        func.outSignature = outSignature;
        func.constraints = constraints;
        func.comments = _comments.dup;
        func.examples = _examples.dup;
        func.parameters = _parameters.dup;
        _functions ~= func;
        return null;
    }

    override GrPrimitive addOperator(GrCallback, Operator operator,
        GrType[] inSignature, GrType outType, GrConstraint[] constraints = []) {
        string name;
        final switch (operator) with (Operator) {
        case plus:
            name = "+";
            break;
        case minus:
            name = "-";
            break;
        case add:
            name = "+";
            break;
        case substract:
            name = "-";
            break;
        case multiply:
            name = "*";
            break;
        case divide:
            name = "/";
            break;
        case concatenate:
            name = "~";
            break;
        case remainder:
            name = "%";
            break;
        case power:
            name = "**";
            break;
        case equal:
            name = "==";
            break;
        case doubleEqual:
            name = "===";
            break;
        case threeWayComparison:
            name = "<=>";
            break;
        case notEqual:
            name = "!=";
            break;
        case greaterOrEqual:
            name = ">=";
            break;
        case greater:
            name = ">";
            break;
        case lesserOrEqual:
            name = "<=";
            break;
        case lesser:
            name = "<";
            break;
        case leftShift:
            name = "<<";
            break;
        case rightShift:
            name = ">>";
            break;
        case interval:
            name = "->";
            break;
        case arrow:
            name = "=>";
            break;
        case bitwiseAnd:
            name = "&";
            break;
        case bitwiseOr:
            name = "|";
            break;
        case bitwiseXor:
            name = "^";
            break;
        case bitwiseNot:
            name = "~";
            break;
        case and:
            name = "&&";
            break;
        case or:
            name = "||";
            break;
        case not:
            name = "!";
            break;
        }
        return addOperator(null, name, inSignature, outType, constraints);
    }

    override GrPrimitive addOperator(GrCallback, string name,
        GrType[] inSignature, GrType outType, GrConstraint[] constraints = []) {
        OperatorFunction op;
        op.name = name;
        op.inSignature = inSignature;
        op.outType = outType;
        op.constraints = constraints;
        op.comments = _comments.dup;
        _operators ~= op;
        return null;
    }

    override GrPrimitive addCast(GrCallback, GrType srcType, GrType dstType,
        bool isExplicit = false, GrConstraint[] constraints = []) {
        Cast cast_;
        cast_.srcType = srcType;
        cast_.dstType = dstType;
        cast_.constraints = constraints;
        cast_.isExplicit = isExplicit;
        cast_.comments = _comments.dup;
        _casts ~= cast_;
        return null;
    }

    override GrPrimitive addConstructor(GrCallback, GrType type,
        GrType[] inSignature = [], GrConstraint[] constraints = []) {
        Constructor ctor;
        ctor.type = type;
        ctor.inSignature = inSignature;
        ctor.constraints = constraints;
        ctor.comments = _comments.dup;
        ctor.parameters = _parameters.dup;
        _constructors ~= ctor;
        return null;
    }

    override GrPrimitive addStatic(GrCallback, GrType type, string name,
        GrType[] inSignature = [], GrType[] outSignature = [], GrConstraint[] constraints = [
        ]) {
        Static static_;
        static_.type = type;
        static_.name = name;
        static_.inSignature = inSignature;
        static_.outSignature = outSignature;
        static_.constraints = constraints;
        static_.comments = _comments.dup;
        static_.examples = _examples.dup;
        static_.parameters = _parameters.dup;
        _statics ~= static_;
        return null;
    }

    override GrPrimitive[] addProperty(GrCallback getCallback, GrCallback setCallback,
        string name, GrType nativeType, GrType propertyType, GrConstraint[] constraints = [
        ]) {
        Property property_;
        property_.name = name;
        property_.nativeType = nativeType;
        property_.propertyType = propertyType;
        property_.constraints = constraints;
        property_.hasGet = getCallback !is null;
        property_.hasSet = setCallback !is null;
        property_.comments = _comments.dup;
        _properties ~= property_;
        return null;
    }

    /// Enregistre une nouvelle contrainte
    override void addConstraint(GrConstraint.Predicate, const string name, uint arity = 0) {
        Constraint constraint;
        constraint.name = name;
        constraint.arity = arity;
        constraint.comments = _comments.dup;
        _constraints ~= constraint;
    }

    private final class MarkDownGenerator {
        private string _text;

        void skipLine() {
            _text ~= "\n";
        }

        void addSeparator() {
            _text ~= "\n\n***\n";
        }

        void addText(const string txt) {
            _text ~= txt ~ "\n";
        }

        void addLink(const string name) {
            _text ~= "<a id=\"" ~ name ~ "\"></a>\n";
        }

        void addHeader(const string msg, int lvl = 1) {
            while (lvl--)
                _text ~= "#";
            _text ~= " " ~ msg ~ "\n";
        }

        void addTableHeader(const string[] header) {
            _text ~= "|";
            foreach (txt; header) {
                _text ~= txt ~ "|";
            }
            _text ~= "\n|";
            foreach (txt; header) {
                _text ~= "-|";
            }
            _text ~= "\n";
        }

        void addTable(const string[] line) {
            _text ~= "|";
            foreach (txt; line) {
                _text ~= txt ~ "|";
            }
            _text ~= "\n";
        }
    }

    string generate(GrLocale locale) {
        sort!((a, b) => (a.name < b.name))(_variables);
        sort!((a, b) => (a.name < b.name))(_enums);
        sort!((a, b) => (a.name < b.name))(_classes);
        sort!((a, b) => (a.name < b.name))(_natives);
        sort!((a, b) => (a.name < b.name))(_aliases);
        sort!((a, b) => (a.name < b.name))(_operators);
        sort!((a, b) => (a.name < b.name))(_properties);
        sort!((a, b) => (a.name < b.name))(_functions);
        sort!((a, b) => (a.name < b.name))(_constraints);

        MarkDownGenerator md = new MarkDownGenerator;

        string asLink(const string txt, const string target) {
            return "[" ~ txt ~ "](#" ~ target ~ ")";
        }

        // En-tête
        md.addHeader(_module);
        md.skipLine();

        const auto moduleInfo = locale in _moduleInfo;
        if (moduleInfo) {
            md.addText(*moduleInfo);
        }

        const auto description = locale in _moduleDescription;
        const auto moduleExample = locale in _moduleExample;
        if (description || moduleExample) {
            final switch (locale) with (GrLocale) {
            case fr_FR:
                md.addHeader("Description", 2);
                break;
            case en_US:
                md.addHeader("Description", 2);
                break;
            }

            if (description) {
                md.addText(*description);
            }

            if (moduleExample) {
                md.addText("```grimoire\n" ~ *moduleExample ~ "\n```");
            }

            md.skipLine();
        }

        if (_constraints.length) {
            final switch (locale) with (GrLocale) {
            case fr_FR:
                md.addHeader("Contraintes", 2);
                md.addTableHeader(["Contrainte", "Paramètres", "Condition"]);
                break;
            case en_US:
                md.addHeader("Constraints", 2);
                md.addTableHeader(["Constraint", "Parameters", "Condition"]);
                break;
            }

            foreach (constraint_; _constraints) {
                auto comment = locale in constraint_.comments;
                md.addTable([
                    constraint_.name, to!string(constraint_.arity),
                    comment ? *comment: ""
                ]);
            }
        }

        if (_variables.length) {
            final switch (locale) with (GrLocale) {
            case fr_FR:
                md.addHeader("Variables", 2);
                md.addTableHeader(["Variable", "Type", "Valeur", "Description"]);
                break;
            case en_US:
                md.addHeader("Variables", 2);
                md.addTableHeader(["Variable", "Type", "Value", "Description"]);
                break;
            }

            foreach (var; _variables) {
                string value;
                GrType.Base varType = var.type.base;
                if (varType == GrType.Base.optional) {
                    varType = grUnmangle(var.type.mangledType).base;

                    if (var.value.isNull) {
                        value = "null";
                        continue;
                    }
                }
                switch (varType) with (GrType.Base) {
                case bool_:
                    value = to!string(var.value.getBool());
                    break;
                case int_:
                    value = to!string(var.value.getInt());
                    break;
                case uint_:
                    value = to!string(var.value.getUInt());
                    break;
                case byte_:
                    value = to!string(var.value.getByte());
                    break;
                case char_:
                    value = to!string(var.value.getChar());
                    break;
                case float_:
                    value = to!string(var.value.getFloat());
                    break;
                case double_:
                    value = to!string(var.value.getDouble());
                    break;
                case string_:
                    value = to!string(var.value.getString());
                    break;
                default:
                    break;
                }

                auto comment = locale in var.comments;
                md.addTable([
                    var.name, _getPrettyType(var.type), value,
                    comment ? *comment: ""
                ]);
            }
        }

        if (_enums.length) {
            final switch (locale) with (GrLocale) {
            case fr_FR:
                md.addHeader("Énumérations", 2);
                md.addTableHeader(["Énumération", "Valeurs", "Description"]);
                break;
            case en_US:
                md.addHeader("Enumerations", 2);
                md.addTableHeader(["Enumeration", "Values", "Description"]);
                break;
            }

            foreach (enum_; _enums) {
                string fields = "{";
                bool started = false;
                foreach (field; enum_.fields) {
                    if (started) {
                        fields ~= ", ";
                    }
                    started = true;
                    fields ~= field;
                }
                fields ~= "}";
                auto comment = locale in enum_.comments;
                md.addTable([enum_.name, fields, comment ? *comment: ""]);
            }
        }

        if (_classes.length) {
            final switch (locale) with (GrLocale) {
            case fr_FR:
                md.addHeader("Classes", 2);
                break;
            case en_US:
                md.addHeader("Classes", 2);
                break;
            }

            foreach (class_; _classes) {
                sort!((a, b) => (a.name < b.name))(class_.fields);

                string className = class_.name;
                if (class_.templates.length) {
                    className ~= "\\<";
                    string signature;
                    foreach (templateName; class_.templates) {
                        if (signature.length)
                            signature ~= ", ";
                        signature ~= templateName;
                    }
                    className ~= signature ~ ">";
                }
                md.addHeader(className, 3);

                if (class_.parent.length) {
                    string parentName = "**" ~ class_.parent;
                    if (class_.parentTemplates.length) {
                        parentName ~= "\\<";
                        string signature;
                        foreach (type; class_.parentTemplates) {
                            if (signature.length)
                                signature ~= ", ";
                            signature ~= _getPrettyType(type, false);
                        }
                        parentName ~= signature ~ ">";
                    }
                    parentName ~= "**";

                    final switch (locale) with (GrLocale) {
                    case fr_FR:
                        md.addText("Hérite de " ~ parentName);
                        break;
                    case en_US:
                        md.addText("Inherits from " ~ parentName);
                        break;
                    }
                }

                auto comment = locale in class_.comments;
                if (comment) {
                    md.addText(*comment);
                }

                final switch (locale) with (GrLocale) {
                case fr_FR:
                    md.addTableHeader(["Champ", "Type", "Description"]);
                    break;
                case en_US:
                    md.addTableHeader(["Field", "Type", "Description"]);
                    break;
                }

                foreach (field; class_.fields) {
                    auto fieldComment = locale in field.comments;
                    md.addTable([
                        field.name, _getPrettyType(field.type),
                        fieldComment ? *fieldComment: ""
                    ]);
                }
            }
        }

        if (_natives.length) {
            final switch (locale) with (GrLocale) {
            case fr_FR:
                md.addHeader("Natifs", 2);
                break;
            case en_US:
                md.addHeader("Natives", 2);
                break;
            }

            foreach (native; _natives) {
                string nativeName = native.name;
                if (native.templates.length) {
                    nativeName ~= "\\<";
                    string signature;
                    foreach (templateName; native.templates) {
                        if (signature.length)
                            signature ~= ", ";
                        signature ~= templateName;
                    }
                    nativeName ~= signature ~ ">";
                }
                md.addHeader(nativeName, 3);

                if (native.parent.length) {
                    string parentName = "**" ~ native.parent;
                    if (native.parentTemplates.length) {
                        parentName ~= "\\<";
                        string signature;
                        foreach (type; native.parentTemplates) {
                            if (signature.length)
                                signature ~= ", ";
                            signature ~= _getPrettyType(type, false);
                        }
                        parentName ~= signature ~ ">";
                    }
                    parentName ~= "**";

                    final switch (locale) with (GrLocale) {
                    case fr_FR:
                        md.addText("Hérite de " ~ parentName);
                        break;
                    case en_US:
                        md.addText("Inherits from " ~ parentName);
                        break;
                    }
                }

                auto comment = locale in native.comments;
                if (comment) {
                    md.addText(*comment);
                }
            }
        }

        if (_aliases.length) {
            final switch (locale) with (GrLocale) {
            case fr_FR:
                md.addHeader("Alias", 2);
                md.addTableHeader(["Alias", "Type", "Description"]);
                break;
            case en_US:
                md.addHeader("Aliases", 2);
                md.addTableHeader(["Alias", "Type", "Description"]);
                break;
            }

            foreach (alias_; _aliases) {
                auto comment = locale in alias_.comments;
                md.addTable([
                    alias_.name, _getPrettyType(alias_.type),
                    comment ? *comment: ""
                ]);
            }
        }

        if (_operators.length) {
            final switch (locale) with (GrLocale) {
            case fr_FR:
                md.addHeader("Opérateurs", 2);
                md.addTableHeader(["Opérateur", "Entrée", "Sortie"]);
                break;
            case en_US:
                md.addHeader("Opérators", 2);
                md.addTableHeader(["Opérator", "Input", "Output"]);
                break;
            }

            foreach (op; _operators) {
                string name = op.name;
                if (name == "||")
                    name = "\\|\\|";
                else if (name == "|")
                    name = "\\|";

                string inSignature;
                foreach (type; op.inSignature) {
                    if (inSignature.length)
                        inSignature ~= ", ";
                    inSignature ~= _getPrettyType(type);
                }
                md.addTable([name, inSignature, _getPrettyType(op.outType)]);
            }
        }

        if (_casts.length) {
            final switch (locale) with (GrLocale) {
            case fr_FR:
                md.addHeader("Conversions", 2);
                md.addTableHeader(["Source", "Destination"]);
                break;
            case en_US:
                md.addHeader("Conversions", 2);
                md.addTableHeader(["Source", "Destination"]);
                break;
            }

            foreach (conv; _casts) {
                md.addTable([
                    _getPrettyType(conv.srcType), _getPrettyType(conv.dstType)
                ]);
            }
        }

        if (_constructors.length) {
            final switch (locale) with (GrLocale) {
            case fr_FR:
                md.addHeader("Constructeurs", 2);
                md.addTableHeader(["Fonction", "Entrée", "Description"]);
                break;
            case en_US:
                md.addHeader("Constructors", 2);
                md.addTableHeader(["Function", "Input", "Description"]);
                break;
            }

            int i;
            foreach (ctor; _constructors) {
                string funcName = "@" ~ _getPrettyType(ctor.type);
                string inSignature;
                string[] parametersName = ctor.parameters;

                int paramIdx;
                foreach (type; ctor.inSignature) {
                    if (inSignature.length)
                        inSignature ~= ", ";

                    if (parametersName.length) {
                        inSignature ~= " *" ~ parametersName[0] ~ "*";
                        parametersName = parametersName[1 .. $];
                    }
                    else {
                        inSignature ~= " *param" ~ to!string(paramIdx) ~ "*";
                    }
                    inSignature ~= ": " ~ _getPrettyType(type);
                    paramIdx++;
                }

                auto comment = locale in ctor.comments;
                md.addTable([
                    asLink(funcName, "ctor_" ~ to!string(i)), inSignature,
                    comment ? *comment: ""
                ]);
                i++;
            }
        }

        if (_properties.length) {
            string _yes, _no;
            final switch (locale) with (GrLocale) {
            case fr_FR:
                md.addHeader("Propriétés", 2);
                md.addTableHeader([
                    "Propriété", "Natif", "Type", "Accesseur", "Modifieur",
                    "Description"
                ]);
                _yes = "oui";
                _no = "non";
                break;
            case en_US:
                md.addHeader("Properties", 2);
                md.addTableHeader([
                    "Property", "Native", "Type", "Setter", "Getter",
                    "Description"
                ]);
                _yes = "yes";
                _no = "no";
                break;
            }

            foreach (property_; _properties) {
                auto comment = locale in property_.comments;
                md.addTable([
                    property_.name, _getPrettyType(property_.nativeType),
                    _getPrettyType(property_.propertyType),
                    property_.hasGet ? _yes: _no, property_.hasSet ? _yes: _no,
                    comment ? *comment: ""
                ]);
            }
        }

        if (_statics.length) {
            final switch (locale) with (GrLocale) {
            case fr_FR:
                md.addHeader("Fonctions Statiques", 2);
                md.addTableHeader(["Fonction", "Entrée", "Sortie"]);
                break;
            case en_US:
                md.addHeader("Static Functions", 2);
                md.addTableHeader(["Function", "Input", "Output"]);
                break;
            }

            int i;
            foreach (static_; _statics) {
                string funcName = "@" ~ _getPrettyType(static_.type) ~ "." ~ static_.name;
                string inSignature, outSignature;
                string[] parametersName = static_.parameters;

                int paramIdx;
                foreach (type; static_.inSignature) {
                    if (inSignature.length)
                        inSignature ~= ", ";

                    if (parametersName.length) {
                        inSignature ~= "*" ~ parametersName[0] ~ "*";
                        parametersName = parametersName[1 .. $];
                    }
                    else {
                        inSignature ~= "*param" ~ to!string(paramIdx) ~ "*";
                    }
                    inSignature ~= ": " ~ _getPrettyType(type);
                    paramIdx++;
                }

                foreach (type; static_.outSignature) {
                    if (outSignature.length)
                        outSignature ~= ", ";
                    outSignature ~= _getPrettyType(type);
                }
                md.addTable([
                    asLink(funcName, "static_" ~ to!string(i)), inSignature,
                    outSignature
                ]);
                i++;
            }
        }

        if (_functions.length) {
            final switch (locale) with (GrLocale) {
            case fr_FR:
                md.addHeader("Fonctions", 2);
                md.addTableHeader(["Fonction", "Entrée", "Sortie"]);
                break;
            case en_US:
                md.addHeader("Functions", 2);
                md.addTableHeader(["Function", "Input", "Output"]);
                break;
            }

            int i;
            foreach (func; _functions) {
                string inSignature, outSignature;
                string[] parametersName = func.parameters;

                int paramIdx;
                foreach (type; func.inSignature) {
                    if (inSignature.length)
                        inSignature ~= ", ";

                    if (parametersName.length) {
                        inSignature ~= "*" ~ parametersName[0] ~ "*";
                        parametersName = parametersName[1 .. $];
                    }
                    else {
                        inSignature ~= "*param" ~ to!string(paramIdx) ~ "*";
                    }
                    inSignature ~= ": " ~ _getPrettyType(type);
                    paramIdx++;
                }

                foreach (type; func.outSignature) {
                    if (outSignature.length)
                        outSignature ~= ", ";
                    outSignature ~= _getPrettyType(type);
                }
                md.addTable([
                    asLink(func.name, "func_" ~ to!string(i)), inSignature,
                    outSignature
                ]);
                i++;
            }
        }

        md.addSeparator();

        if (_statics.length) {
            final switch (locale) with (GrLocale) {
            case fr_FR:
                md.addHeader("Description des fonctions statiques", 2);
                break;
            case en_US:
                md.addHeader("Static function descriptions", 2);
                break;
            }

            md.skipLine();
            int i;
            foreach (func; _statics) {
                md.addLink("static_" ~ to!string(i));
                string name = "> @" ~ _getPrettyType(func.type) ~ "." ~ func.name;
                string[] parametersName = func.parameters;

                {
                    string inSignature;
                    name ~= "(";
                    int paramIdx;
                    foreach (type; func.inSignature) {
                        if (inSignature.length)
                            inSignature ~= ", ";
                        if (parametersName.length) {
                            inSignature ~= "*" ~ parametersName[0] ~ "*";
                            parametersName = parametersName[1 .. $];
                        }
                        else {
                            inSignature ~= "*param" ~ to!string(paramIdx) ~ "*";
                        }
                        inSignature ~= ": " ~ _getPrettyType(type);
                        paramIdx++;
                    }
                    name ~= inSignature;
                    name ~= ")";
                }

                if (func.outSignature.length) {
                    string outSignature;
                    name ~= " (";
                    foreach (type; func.outSignature) {
                        if (outSignature.length)
                            outSignature ~= ", ";
                        outSignature ~= _getPrettyType(type);
                    }
                    name ~= outSignature;
                    name ~= ")";
                }

                md.addText(name);
                md.skipLine();
                auto comment = locale in func.comments;
                auto example = locale in func.examples;
                if (comment || example) {
                    if (comment) {
                        md.addText(*comment);
                    }
                    if (example) {
                        md.addText("```grimoire\n" ~ *example ~ "\n```");
                    }
                    md.skipLine();
                }
                i++;
            }
        }

        if (_functions.length) {
            final switch (locale) with (GrLocale) {
            case fr_FR:
                md.addHeader("Description des fonctions", 2);
                break;
            case en_US:
                md.addHeader("Function descriptions", 2);
                break;
            }

            md.skipLine();
            int i;
            foreach (func; _functions) {
                md.addLink("func_" ~ to!string(i));
                string name = "> " ~ func.name;
                string[] parametersName = func.parameters;

                {
                    string inSignature;
                    name ~= "(";
                    int paramIdx;
                    foreach (type; func.inSignature) {
                        if (inSignature.length)
                            inSignature ~= ", ";
                        if (parametersName.length) {
                            inSignature ~= "*" ~ parametersName[0] ~ "*";
                            parametersName = parametersName[1 .. $];
                        }
                        else {
                            inSignature ~= "*param" ~ to!string(paramIdx) ~ "*";
                        }
                        inSignature ~= ": " ~ _getPrettyType(type);
                        paramIdx++;
                    }
                    name ~= inSignature;
                    name ~= ")";
                }

                if (func.outSignature.length) {
                    string outSignature;
                    name ~= " (";
                    foreach (type; func.outSignature) {
                        if (outSignature.length)
                            outSignature ~= ", ";
                        outSignature ~= _getPrettyType(type);
                    }
                    name ~= outSignature;
                    name ~= ")";
                }

                md.addText(name);
                md.skipLine();
                auto comment = locale in func.comments;
                auto example = locale in func.examples;
                if (comment || example) {
                    if (comment) {
                        md.addText(*comment);
                    }
                    if (example) {
                        md.addText("```grimoire\n" ~ *example ~ "\n```");
                    }
                    md.skipLine();
                }
                i++;
            }
        }

        return md._text;
    }

    private string _getPrettyType(const GrType type, bool isBold = true) const {
        import std.string;

        string str = grGetPrettyType(type);

        str = str.replace("<", "\\<");
        if (isBold)
            return "**" ~ str ~ "**";
        else
            return str;
    }
}
