module grimoire.compiler.doc;

import std.conv : to;
import std.algorithm : min, sort;

import grimoire.runtime;
import grimoire.compiler.library;
import grimoire.compiler.primitive;
import grimoire.compiler.type;
import grimoire.compiler.constraint;
import grimoire.compiler.mangle;
import grimoire.compiler.pretty;
import grimoire.compiler.util;

/// Contient les informations de types et les primitives de façon à générer une documentation
final class GrDoc : GrLibDefinition {
    private {
        string[] _module;
        string[GrLocale] _moduleInfo, _moduleDescription, _comments;
        string[][GrLocale] _parameters;

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
            string[][GrLocale] parameters;
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
            string[][GrLocale] parameters;
        }

        struct Static {
            GrType type;
            string name;
            GrType[] inSignature, outSignature;
            GrConstraint[] constraints;
            string[GrLocale] comments;
            string[][GrLocale] parameters;
        }

        struct Property {
            string name;
            GrType nativeType, propertyType;
            GrConstraint[] constraints;
            bool hasGet, hasSet;
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
    }

    this(string[] moduleName)
    in (moduleName.length) {
        _module = moduleName;
    }

    override void setModule(string[] name) {
        _module = name;
    }

    string[] getModule() {
        return _module;
    }

    override void setModuleInfo(GrLocale locale, string msg) {
        _moduleInfo[locale] = msg;
    }

    override void setModuleDescription(GrLocale locale, string msg) {
        _moduleDescription[locale] = msg;
    }

    override void setDescription(GrLocale locale, string message = "") {
        _comments[locale] = message;
    }

    override void setParameters(GrLocale locale, string[] parameters = []) {
        _parameters[locale] = parameters;
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

    override GrType addEnum(string name, string[] fields) {
        Enum enum_;
        enum_.name = name;
        enum_.fields = fields;
        enum_.comments = _comments.dup;
        _enums ~= enum_;

        GrType type = GrType.Base.enum_;
        type.mangledType = name;
        return type;
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

        MarkDownGenerator md = new MarkDownGenerator;

        string asLink(const string txt, const string target) {
            return "[" ~ txt ~ "](#" ~ target ~ ")";
        }

        // En-tête
        string moduleName;
        foreach (part; _module) {
            if (moduleName.length)
                moduleName ~= ".";
            moduleName ~= part;
        }
        md.addHeader(moduleName);
        md.skipLine();

        const auto moduleInfo = locale in _moduleInfo;
        if (moduleInfo) {
            md.addText(*moduleInfo);
        }

        const auto description = locale in _moduleDescription;
        if (description) {
            md.addHeader("Description", 2);
            md.addText(*description);
        }

        if (_variables.length) {
            md.addHeader("Variables", 2);

            md.addTableHeader(["Variable", "Type", "Valeur", "Description"]);
            foreach (var; _variables) {
                string value;
                switch (var.type.base) with (GrType.Base) {
                case bool_:
                    value = to!string(var.value.getBool());
                    break;
                case int_:
                    value = to!string(var.value.getInt());
                    break;
                case float_:
                    value = to!string(var.value.getFloat());
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
            md.addHeader("Énumérations", 2);

            md.addTableHeader(["Énumération", "Valeurs", "Description"]);
            foreach (enum_; _enums) {
                string fields = "{";
                foreach (field; enum_.fields) {
                    if (fields.length)
                        fields ~= ", ";
                    fields ~= field;
                }
                fields ~= "}";
                auto comment = locale in enum_.comments;
                md.addTable([enum_.name, fields, comment ? *comment: ""]);
            }
        }

        if (_classes.length) {
            md.addHeader("Classes", 2);

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
                    md.addText("Hérite de " ~ parentName);
                }

                auto comment = locale in class_.comments;
                if (comment) {
                    md.addText(*comment);
                }
                md.addTableHeader(["Champ", "Type", "Description"]);
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
            md.addHeader("Natifs", 2);

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
                    md.addText("Hérite de " ~ parentName);
                }

                auto comment = locale in native.comments;
                if (comment) {
                    md.addText(*comment);
                }
            }
        }

        if (_aliases.length) {
            md.addHeader("Alias", 2);

            md.addTableHeader(["Alias", "Type", "Commentaire"]);
            foreach (alias_; _aliases) {
                auto comment = locale in alias_.comments;
                md.addTable([
                    alias_.name, _getPrettyType(alias_.type),
                    comment ? *comment: ""
                ]);
            }
        }

        if (_operators.length) {
            md.addHeader("Opérateurs", 2);

            md.addTableHeader(["Opérateur", "Entrée", "Sortie"]);
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
            md.addHeader("Conversions", 2);

            md.addTableHeader(["Source", "Destination"]);
            foreach (conv; _casts) {
                md.addTable([
                    _getPrettyType(conv.srcType), _getPrettyType(conv.dstType)
                ]);
            }
        }

        if (_constructors.length) {
            md.addHeader("Constructeurs", 2);

            md.addTableHeader(["Fonction", "Entrée"]);
            int i;
            foreach (ctor; _constructors) {
                string funcName = "@" ~ _getPrettyType(ctor.type);
                string inSignature;
                string[] parametersName;
                auto parameters = locale in ctor.parameters;
                if (parameters) {
                    parametersName = *parameters;
                }

                int paramIdx;
                foreach (type; ctor.inSignature) {
                    if (inSignature.length)
                        inSignature ~= ", ";
                    inSignature ~= _getPrettyType(type);

                    if (parametersName.length) {
                        inSignature ~= " *" ~ parametersName[0] ~ "*";
                        parametersName = parametersName[1 .. $];
                    }
                    else {
                        inSignature ~= " *param" ~ to!string(paramIdx) ~ "*";
                    }
                    paramIdx++;
                }

                md.addTable([
                    asLink(funcName, "ctor_" ~ to!string(i)), inSignature
                ]);
                i++;
            }
        }

        if (_properties.length) {
            md.addHeader("Propriétés", 2);

            md.addTableHeader([
                "Propriété", "Natif", "Type", "Accesseur", "Modifieur"
            ]);
            foreach (property_; _properties) {
                md.addTable([
                    property_.name, _getPrettyType(property_.nativeType),
                    _getPrettyType(property_.propertyType),
                    property_.hasGet ? "oui": "non",
                    property_.hasSet ? "oui": "non"
                ]);
            }
        }

        if (_statics.length) {
            md.addHeader("Fonctions Statiques", 2);

            md.addTableHeader(["Fonction", "Entrée", "Sortie"]);
            int i;
            foreach (static_; _statics) {
                string funcName = "@" ~ _getPrettyType(static_.type) ~ "." ~ static_.name;
                string inSignature, outSignature;
                string[] parametersName;
                auto parameters = locale in static_.parameters;
                if (parameters) {
                    parametersName = *parameters;
                }

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
            md.addHeader("Fonctions", 2);

            md.addTableHeader(["Fonction", "Entrée", "Sortie"]);
            int i;
            foreach (func; _functions) {
                string inSignature, outSignature;
                string[] parametersName;
                auto parameters = locale in func.parameters;
                if (parameters) {
                    parametersName = *parameters;
                }

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

        if (_functions.length) {
            md.addHeader("Description des fonctions", 2);
            md.skipLine();
            int i;
            foreach (func; _functions) {
                md.addLink("func_" ~ to!string(i));
                string name = "> " ~ func.name;

                string[] parametersName;
                auto parameters = locale in func.parameters;
                if (parameters) {
                    parametersName = *parameters;
                }

                if (func.inSignature.length) {
                    string inSignature;
                    name ~= " (";
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
                if (comment) {
                    md.addText(*comment);
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
