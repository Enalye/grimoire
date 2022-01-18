/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.lexer;

import std.stdio, std.string, std.array, std.math, std.file;
import std.conv : to;
import std.algorithm : canFind;
import grimoire.assembly;
import grimoire.compiler.data, grimoire.compiler.error, grimoire.compiler.util;

/**
Kinds of valid token.
*/
enum GrLexemeType {
    leftBracket,
    rightBracket,
    leftParenthesis,
    rightParenthesis,
    leftCurlyBrace,
    rightCurlyBrace,
    period,
    semicolon,
    colon,
    doubleColon,
    comma,
    at,
    pointer,
    as,
    isolate,
    capture,
    error,
    defer,
    assign,
    bitwiseAndAssign,
    bitwiseOrAssign,
    bitwiseXorAssign,
    andAssign,
    orAssign,
    addAssign,
    substractAssign,
    multiplyAssign,
    divideAssign,
    concatenateAssign,
    remainderAssign,
    powerAssign,
    plus,
    minus,
    bitwiseAnd,
    bitwiseOr,
    bitwiseXor,
    and,
    or,
    add,
    substract,
    multiply,
    divide,
    concatenate,
    remainder,
    power,
    equal,
    doubleEqual,
    threeWayComparison,
    notEqual,
    greaterOrEqual,
    greater,
    lesserOrEqual,
    lesser,
    leftShift,
    rightShift,
    interval,
    arrow,
    bitwiseNot,
    not,
    increment,
    decrement,
    identifier,
    integer,
    real_,
    boolean,
    string_,
    null_,
    public_,
    type_,
    action,
    class_,
    enumeration,
    instance,
    new_,
    copy,
    send,
    receive,
    integerType,
    realType,
    booleanType,
    stringType,
    listType,
    chanType,
    functionType,
    taskType,
    autoType,
    if_,
    unless,
    else_,
    switch_,
    select,
    case_,
    while_,
    do_,
    until,
    for_,
    loop,
    return_,
    self,
    die,
    quit,
    suspend,
    break_,
    continue_,
}

/**
Describe the smallest element found in a source _file.
*/
struct GrLexeme {
    /// Default.
    this(GrLexer _lexer) {
        _line = _lexer._line;
        _column = _lexer._current - _lexer._positionOfLine;
        _fileId = _lexer._fileId;
        lexer = _lexer;
    }

    private {
        /// Parent lexer.
        GrLexer lexer;

        /// Id of the file the token is in.
        uint _fileId;

        /// Position information in case of errors.
        uint _line, _column, _textLength = 1;
    }

    @property {
        /// Line position
        uint line() const {
            return _line;
        }
        /// Column position
        uint column() const {
            return _column;
        }
        /// Text length
        uint textLength() const {
            return _textLength;
        }
        /// File id
        uint fileId() const {
            return _fileId;
        }
    }

    /// Kind of token.
    GrLexemeType type;

    /// Whether the lexeme is a constant value.
    bool isLiteral;

    /// Whether the lexeme is an operator.
    bool isOperator;

    /// is this a reserved grimoire word ?
    bool isKeyword;

    /// Only describe first class type such as `int`, `string` or `function`.
    /// Structure or other custom type are not.
    bool isType;

    /// Integral value of the constant.
    /// isLiteral will be true and type set to int.
    GrInt ivalue;

    /// Floating point value of the constant.
    /// isLiteral will be true and type set to float.
    GrReal fvalue;

    /// Boolean value of the constant.
    /// isLiteral will be true and type set to bool.
    GrBool bvalue;

    /// Can either describe a literal value like `"myString"` or an identifier.
    GrString svalue;

    /// Returns the entire _line from where the token is located.
    string getLine() {
        return lexer.getLine(this);
    }

    string getFile() {
        return lexer.getFile(this);
    }

    /// Can we define a custom function with this operator
    bool isOverridableOperator() const {
        return type >= GrLexemeType.add && type <= GrLexemeType.not;
    }
}

/**
The lexer scans the entire file and all the imported files it references.
*/
package final class GrLexer {
    private {
        string[] _filesToImport, _filesImported;
        dstring[] _lines;
        string _file;
        dstring _text;
        uint _line, _current, _positionOfLine, _fileId;
        GrLexeme[] _lexemes;
        GrLocale _locale;
        GrData _data;
    }

    @property {
        /// Generated tokens.
        GrLexeme[] lexemes() {
            return _lexemes;
        }
    }

    /// Ctor
    this(GrLocale locale) {
        _locale = locale;
    }

    /// Start scanning the root file and all its dependencies.
    void scanFile(GrData data, string fileName) {
        import std.path : buildNormalizedPath, absolutePath;

        _data = data;

        string filePath = to!string(fileName);
        filePath = buildNormalizedPath(convertPathToImport(filePath));
        filePath = absolutePath(filePath);
        fileName = to!string(filePath);

        _filesToImport ~= fileName;

        while (_filesToImport.length) {
            _file = _filesToImport[$ - 1];
            _filesImported ~= _file;
            _text = to!dstring(readText(_file));
            _filesToImport.length--;

            _line = 0u;
            _current = 0u;
            _positionOfLine = 0u;
            _lines = split(_text, "\n");

            scanScript();

            _fileId++;
        }

        // Translate aliases
        foreach (ref lexeme; _lexemes) {
            if (lexeme.type == GrLexemeType.identifier) {
                string* name = (lexeme.svalue in _data._aliases);
                if (name) {
                    lexeme.svalue = *name;
                }
            }
        }
    }

    /**
	Fetch the entire line where a lexeme is.
	*/
    package string getLine(GrLexeme lex) {
        if (lex._fileId >= _filesImported.length)
            raiseError(Error.lexFileIdOutOfBounds);
        auto _text = to!dstring(readText(_filesImported[lex._fileId]));
        _lines = split(_text, "\n");
        if (lex._line >= _lines.length)
            raiseError(Error.lexLineCountOutOfBounds);
        return to!string(_lines[lex._line]);
    }

    /**
	Fetch the file where a lexeme is.
	*/
    package string getFile(GrLexeme lex) {
        if (lex._fileId >= _filesImported.length)
            raiseError(Error.lexFileIdOutOfBounds);
        return _filesImported[lex._fileId];
    }
    /// Ditto
    package string getFile(size_t lexFileIdOutOfBounds) {
        if (lexFileIdOutOfBounds >= _filesImported.length)
            raiseError(Error.lexFileIdOutOfBounds);
        return _filesImported[lexFileIdOutOfBounds];
    }

    private dchar get(int offset = 0) {
        const uint position = to!int(_current) + offset;
        if (position < 0 || position >= _text.length)
            raiseError(Error.unexpectedEndOfFile);
        return _text[position];
    }

    /// Advance the current character pointer and skips whitespaces and comments.
    private bool advance(bool startFromCurrent = false) {
        if (!startFromCurrent)
            _current++;

        if (_current >= _text.length)
            return false;

        dchar symbol = _text[_current];

        whileLoop: while (symbol <= 0x20 || symbol == '/' || symbol == '#') {
            if (_current >= _text.length)
                return false;

            symbol = _text[_current];

            if (symbol == '\n') {
                _positionOfLine = _current;
                _line++;
            }
            else if (symbol == '#') {
                do {
                    if (_current >= _text.length)
                        return false;
                    _current++;
                }
                while (_text[_current] != '\n');
                _positionOfLine = _current;
                _line++;
            }
            else if (symbol == '/') {
                if ((_current + 1) >= _text.length)
                    return false;

                switch (_text[_current + 1]) {
                case '/':
                    do {
                        if (_current >= _text.length)
                            return false;
                        _current++;
                    }
                    while (_current < _text.length && _text[_current] != '\n');
                    _positionOfLine = _current;
                    _line++;
                    break;
                case '*':
                    advance();
                    advance();
                    int commentScope = 0;
                    for (;;) {
                        if ((_current + 1) >= _text.length) {
                            _current++;
                            return false;
                        }

                        if (_text[_current] == '\n') {
                            _positionOfLine = _current;
                            _line++;
                        }
                        if (_text[_current] == '/' && _text[_current + 1] == '*') {
                            commentScope++;
                        }
                        else if (_text[_current] == '*' && _text[_current + 1] == '/') {
                            if (_current > 0 && _text[_current - 1] == '/') {
                                //Skip
                            }
                            else if (commentScope == 0) {
                                _current++;
                                break;
                            }
                            else {
                                commentScope--;
                            }
                        }
                        _current++;
                    }
                    break;
                default:
                    break whileLoop;
                }
            }
            _current++;

            if (_current >= _text.length)
                return false;

            symbol = _text[_current];
        }
        return true;
    }

    /// Scan the content of a single file.
    private void scanScript() {
        //Skip the first escape characters.
        advance(true);

        do {
            if (_current >= _text.length)
                break;
            switch (get()) {
            case '0': .. case '9':
                scanNumber();
                break;
            case '.':
                if (get(1) >= '0' && get(1) <= '9')
                    scanNumber();
                else
                    goto case '!';
                break;
            case '!':
            case '#': .. case '&':
            case '(': .. case '-':
            case '/':
            case ':':
                    .. case '@':
            case '[': .. case '^':
            case '{': .. case '~':
                scanOperator();
                break;
            case '\"':
                scanString();
                break;
            default:
                scanWord();
                break;
            }
        }
        while (advance());
    }

    /**
	Scan either a integer or a floating point number. \
	Floats can start with a `.` \
	A number finishing with `f` will be scanned as a float. \
	Underscores `_` are ignored inside a number.
	*/
    private void scanNumber() {
        GrLexeme lex = GrLexeme(this);
        lex.isLiteral = true;

        bool isFloat;
        string buffer;
        for (;;) {
            dchar symbol = get();

            if (symbol >= '0' && symbol <= '9')
                buffer ~= symbol;
            else if (symbol == '_') {
                // Do nothing, only cosmetic (e.g. 1_000_000).
            }
            else if (symbol == '.') {
                if (isFloat)
                    break;
                isFloat = true;
                buffer ~= symbol;
            }
            else if (symbol == 'f') {
                isFloat = true;
                break;
            }
            else {
                if (_current)
                    _current--;
                break;
            }

            _current++;

            if (_current >= _text.length)
                break;
        }

        lex._textLength = cast(uint) buffer.length;

        if (isFloat) {
            lex.type = GrLexemeType.real_;
            lex.fvalue = to!GrReal(buffer);
        }
        else {
            lex.type = GrLexemeType.integer;
            lex.ivalue = to!GrInt(buffer);
        }
        _lexemes ~= lex;
    }

    /**
    Scan a `"` delimited string.
    */
    void scanString() {
        GrLexeme lex = GrLexeme(this);
        lex.type = GrLexemeType.string_;
        lex.isLiteral = true;

        if (get() != '\"')
            raiseError(Error.expectedQuotationMarkAtBeginningOfStr);
        _current++;

        string buffer;
        bool escape = false;
        bool wasEscape = false;
        for (;;) {
            if (_current >= _text.length)
                raiseError(Error.missingQuotationMarkAtEndOfStr);
            const dchar symbol = get();

            if (symbol == '\n') {
                _positionOfLine = _current;
                _line++;
            }
            else if (symbol == '\"' && (!wasEscape))
                break;
            else if (symbol == '\\' && (!wasEscape)) {
                escape = true;
            }

            if (!escape) {
                if (!wasEscape) {
                    buffer ~= symbol;
                }
                else {
                    if (symbol == 'n')
                        buffer ~= '\n';
                    else
                        buffer ~= symbol;
                }
            }
            wasEscape = escape;
            escape = false;

            _current++;
        }

        lex._textLength = cast(uint) buffer.length + 2u;
        lex.svalue = buffer;
        _lexemes ~= lex;
    }

    /**
	Scan a symbol-based operator.
	*/
    private void scanOperator() {
        GrLexeme lex = GrLexeme(this);
        lex.isOperator = true;

        switch (get()) {
        case '{':
            lex.type = GrLexemeType.leftCurlyBrace;
            break;
        case '}':
            lex.type = GrLexemeType.rightCurlyBrace;
            break;
        case '(':
            lex.type = GrLexemeType.leftParenthesis;
            break;
        case ')':
            lex.type = GrLexemeType.rightParenthesis;
            break;
        case '[':
            lex.type = GrLexemeType.leftBracket;
            break;
        case ']':
            lex.type = GrLexemeType.rightBracket;
            break;
        case '.':
            lex.type = GrLexemeType.period;
            break;
        case ';':
            lex.type = GrLexemeType.semicolon;
            break;
        case ':':
            lex.type = GrLexemeType.colon;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == ':') {
                lex.type = GrLexemeType.doubleColon;
                lex._textLength = 2;
                _current++;
            }
            break;
        case ',':
            lex.type = GrLexemeType.comma;
            break;
        case '@':
            lex.type = GrLexemeType.pointer;
            break;
        case '&':
            lex.type = GrLexemeType.bitwiseAnd;
            if (_current + 1 >= _text.length)
                break;
            switch (get(1)) {
            case '=':
                lex.type = GrLexemeType.bitwiseAndAssign;
                lex._textLength = 2;
                _current++;
                break;
            case '&':
                lex.type = GrLexemeType.and;
                lex._textLength = 2;
                _current++;
                if (_current + 1 >= _text.length)
                    break;
                if (get(1) == '&') {
                    lex.type = GrLexemeType.andAssign;
                    lex._textLength = 3;
                    _current++;
                }
                break;
            default:
                break;
            }
            break;
        case '|':
            lex.type = GrLexemeType.bitwiseOr;
            if (_current + 1 >= _text.length)
                break;
            switch (get(1)) {
            case '=':
                lex.type = GrLexemeType.bitwiseOrAssign;
                lex._textLength = 2;
                _current++;
                break;
            case '|':
                lex.type = GrLexemeType.or;
                lex._textLength = 2;
                _current++;
                if (_current + 1 >= _text.length)
                    break;
                if (get(1) == '|') {
                    lex.type = GrLexemeType.orAssign;
                    lex._textLength = 3;
                    _current++;
                }
                break;
            default:
                break;
            }
            break;
        case '^':
            lex.type = GrLexemeType.bitwiseXor;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexemeType.bitwiseXorAssign;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '~':
            lex.type = GrLexemeType.concatenate;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexemeType.concatenateAssign;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '+':
            lex.type = GrLexemeType.add;
            if (_current + 1 >= _text.length)
                break;
            switch (get(1)) {
            case '=':
                lex.type = GrLexemeType.addAssign;
                lex._textLength = 2;
                _current++;
                break;
            case '+':
                lex.type = GrLexemeType.increment;
                lex._textLength = 2;
                _current++;
                break;
            default:
                break;
            }
            break;
        case '-':
            lex.type = GrLexemeType.substract;
            if (_current + 1 >= _text.length)
                break;
            switch (get(1)) {
            case '=':
                lex.type = GrLexemeType.substractAssign;
                lex._textLength = 2;
                _current++;
                break;
            case '-':
                lex.type = GrLexemeType.decrement;
                lex._textLength = 2;
                _current++;
                break;
            case '>':
                lex.type = GrLexemeType.interval;
                lex._textLength = 2;
                _current++;
                break;
            default:
                break;
            }
            break;
        case '*':
            lex.type = GrLexemeType.multiply;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexemeType.multiplyAssign;
                lex._textLength = 2;
                _current++;
            }
            else if (get(1) == '*') {
                lex.type = GrLexemeType.power;
                lex._textLength = 2;
                _current++;
                if (_current + 1 >= _text.length)
                    break;
                if (get(1) == '=') {
                    lex.type = GrLexemeType.powerAssign;
                    lex._textLength = 3;
                    _current++;
                }
            }
            break;
        case '/':
            lex.type = GrLexemeType.divide;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexemeType.divideAssign;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '%':
            lex.type = GrLexemeType.remainder;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexemeType.remainderAssign;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '=':
            lex.type = GrLexemeType.assign;
            if (_current + 1 >= _text.length)
                break;
            switch (get(1)) {
            case '=':
                lex.type = GrLexemeType.equal;
                lex._textLength = 2;
                _current++;
                if (_current + 1 >= _text.length)
                    break;
                if (get(1) == '=') {
                    lex.type = GrLexemeType.doubleEqual;
                    lex._textLength = 3;
                    _current++;
                }
                break;
            case '>':
                lex.type = GrLexemeType.arrow;
                lex._textLength = 2;
                _current++;
                break;
            default:
                break;
            }
            break;
        case '<':
            lex.type = GrLexemeType.lesser;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexemeType.lesserOrEqual;
                lex._textLength = 2;
                _current++;
                if (_current + 1 >= _text.length)
                    break;
                if (get(1) == '>') {
                    lex.type = GrLexemeType.threeWayComparison;
                    lex._textLength = 3;
                    _current++;
                }
            }
            else if (get(1) == '-') {
                lex.type = GrLexemeType.send;
                lex._textLength = 2;
                _current++;
            }
            else if (get(1) == '<') {
                lex.type = GrLexemeType.leftShift;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '>':
            lex.type = GrLexemeType.greater;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexemeType.greaterOrEqual;
                lex._textLength = 2;
                _current++;
            }
            else if (get(1) == '>') {
                lex.type = GrLexemeType.rightShift;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '!':
            lex.type = GrLexemeType.not;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexemeType.notEqual;
                lex._textLength = 2;
                _current++;
            }
            break;
        default:
            raiseError(Error.invalidOp);
        }

        _lexemes ~= lex;
    }

    /**
	Scan a known keyword or an identifier otherwise.
	*/
    private void scanWord() {
        GrLexeme lex = GrLexeme(this);
        lex.isKeyword = true;

        dstring buffer;
        for (;;) {
            if (_current >= _text.length)
                break;

            const dchar symbol = get();
            if (symbol == '?') {
                buffer ~= symbol;
                _current++;
                break;
            }
            if (symbol <= '&' || (symbol >= '(' && symbol <= '/') || (symbol >= ':'
                    && symbol <= '@') || (symbol >= '[' && symbol <= '^')
                || (symbol >= '{' && symbol <= 0x7F))
                break;

            buffer ~= symbol;
            _current++;
        }
        _current--;

        lex._textLength = cast(uint) buffer.length;

        switch (buffer) {
        case "inclus":
        case "include":
            scanUse();
            return;
        case "public":
            lex.type = GrLexemeType.public_;
            break;
        case "type":
            lex.type = GrLexemeType.type_;
            break;
        case "action":
            lex.type = GrLexemeType.action;
            break;
        case "classe":
        case "class":
            lex.type = GrLexemeType.class_;
            break;
        case "énumération":
        case "enumeration":
            lex.type = GrLexemeType.enumeration;
            break;
        case "instance":
            lex.type = GrLexemeType.instance;
            break;
        case "si":
        case "if":
            lex.type = GrLexemeType.if_;
            break;
        case "sauf":
        case "unless":
            lex.type = GrLexemeType.unless;
            break;
        case "sinon":
        case "else":
            lex.type = GrLexemeType.else_;
            break;
        case "alternative":
            lex.type = GrLexemeType.switch_;
            break;
        case "sélectionne":
        case "select":
            lex.type = GrLexemeType.select;
            break;
        case "cas":
        case "case":
            lex.type = GrLexemeType.case_;
            break;
        case "tant":
        case "while":
            lex.type = GrLexemeType.while_;
            break;
        case "fais":
        case "do":
            lex.type = GrLexemeType.do_;
            break;
        case "jusque":
        case "until":
            lex.type = GrLexemeType.until;
            break;
        case "pour":
        case "for":
            lex.type = GrLexemeType.for_;
            break;
        case "boucle":
        case "loop":
            lex.type = GrLexemeType.loop;
            break;
        case "retourne":
        case "return":
            lex.type = GrLexemeType.return_;
            break;
        case "soi":
        case "self":
            lex.type = GrLexemeType.self;
            break;
        case "meurt":
        case "die":
            lex.type = GrLexemeType.die;
            break;
        case "quitte":
        case "quit":
            lex.type = GrLexemeType.quit;
            break;
        case "suspends":
        case "suspend":
            lex.type = GrLexemeType.suspend;
            break;
        case "casse":
        case "break":
            lex.type = GrLexemeType.break_;
            break;
        case "continue":
            lex.type = GrLexemeType.continue_;
            break;
        case "en":
        case "as":
            lex.type = GrLexemeType.as;
            break;
        case "isole":
        case "isolate":
            lex.type = GrLexemeType.isolate;
            break;
        case "capture":
            lex.type = GrLexemeType.capture;
            break;
        case "erreur":
        case "error":
            lex.type = GrLexemeType.error;
            break;
        case "décale":
        case "defer":
            lex.type = GrLexemeType.defer;
            break;
        case "tâche":
        case "task":
            lex.type = GrLexemeType.taskType;
            lex.isType = true;
            break;
        case "fonction":
        case "function":
            lex.type = GrLexemeType.functionType;
            lex.isType = true;
            break;
        case "entier":
        case "integer":
            lex.type = GrLexemeType.integerType;
            lex.isType = true;
            break;
        case "réel":
        case "real":
            lex.type = GrLexemeType.realType;
            lex.isType = true;
            break;
        case "booléen":
        case "boolean":
            lex.type = GrLexemeType.booleanType;
            lex.isType = true;
            break;
        case "chaîne":
        case "string":
            lex.type = GrLexemeType.stringType;
            lex.isType = true;
            break;
        case "liste":
        case "list":
            lex.type = GrLexemeType.listType;
            lex.isType = true;
            break;
        case "canal":
        case "channel":
            lex.type = GrLexemeType.chanType;
            lex.isType = true;
            break;
        case "crée":
        case "new":
            lex.type = GrLexemeType.new_;
            lex.isType = false;
            break;
        case "soit":
        case "let":
            lex.type = GrLexemeType.autoType;
            lex.isType = false;
            break;
        case "vrai":
        case "true":
            lex.type = GrLexemeType.boolean;
            lex.isKeyword = false;
            lex.isLiteral = true;
            lex.bvalue = true;
            break;
        case "faux":
        case "false":
            lex.type = GrLexemeType.boolean;
            lex.isKeyword = false;
            lex.isLiteral = true;
            lex.bvalue = false;
            break;
        case "nul":
        case "null":
            lex.type = GrLexemeType.null_;
            lex.isKeyword = false;
            lex.isLiteral = true;
            break;
        case "à":
        case "to":
            lex.type = GrLexemeType.interval;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "et":
        case "and":
            lex.type = GrLexemeType.and;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "ou":
        case "or":
            lex.type = GrLexemeType.or;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "pas":
        case "not":
            lex.type = GrLexemeType.not;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "et_bin":
        case "bit_and":
            lex.type = GrLexemeType.bitwiseAnd;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "ou_bin":
        case "bit_or":
            lex.type = GrLexemeType.bitwiseOr;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "xou_bin":
        case "bit_xor":
            lex.type = GrLexemeType.bitwiseXor;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "non_bin":
        case "bit_not":
            lex.type = GrLexemeType.bitwiseNot;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        default:
            lex.isKeyword = false;
            lex.type = GrLexemeType.identifier;
            lex.svalue = to!string(buffer);
            break;
        }

        _lexemes ~= lex;
    }

    /// Transform the path in your path system.
    private string convertPathToImport(string path) {
        import std.regex : replaceAll, regex;
        import std.path : dirSeparator;

        return replaceAll(path, regex(r"\\/|/|\\"), dirSeparator);
    }

    /// add a single _file path delimited by `" "` to the import list.
    private void scanFilePath() {
        import std.path : dirName, buildNormalizedPath, absolutePath;

        if (get() != '\"')
            raiseError(Error.expectedQuotationMarkAtBeginningOfStr);
        _current++;

        string buffer;
        for (;;) {
            if (_current >= _text.length)
                raiseError(Error.missingQuotationMarkAtEndOfStr);
            const dchar symbol = get();
            if (symbol == '\n') {
                _positionOfLine = _current;
                _line++;
            }
            else if (symbol == '\"')
                break;

            buffer ~= symbol;
            _current++;
        }
        string filePath = to!string(buffer);
        filePath = buildNormalizedPath(dirName(to!string(_file)), convertPathToImport(filePath));
        filePath = absolutePath(filePath);
        buffer = to!string(filePath);
        if (_filesImported.canFind(buffer) || _filesToImport.canFind(buffer))
            return;
        _filesToImport ~= buffer;
    }

    /// Scan a `use` directive.
    /// Syntax:
    /// `use "FILEPATH"` or
    /// `use { "FILEPATH1", "FILEPATH2", "FILEPATH3" }`
    /// ___
    /// add a file to the list of files to import.
    private void scanUse() {
        advance();

        // Multiple files import.
        if (get() == '{') {
            advance();
            bool isFirst = true;
            for (;;) {
                if (isFirst)
                    isFirst = false;
                else if (get() == '\"')
                    advance();
                else
                    raiseError(Error.missingQuotationMarkAtEndOfStr);
                // EOF
                if (_current >= _text.length)
                    raiseError(Error.missingRightCurlyBraceAfterUsedFilesList);
                // End of the import list.
                if (get() == '}')
                    break;
                // Scan
                scanFilePath();
            }
        }
        else {
            scanFilePath();
        }
    }

    /**
	Lexical error
	*/
    private void raiseError(Error error) {
        raiseError(getLexerError(error, _locale));
    }
    /// Ditto
    private void raiseError(string message) {
        GrError error = new GrError;
        error.type = GrError.Type.lexer;

        error.message = message;
        error.info = "";

        if (_lexemes.length) {
            GrLexeme lexeme = _lexemes[$ - 1];
            error.filePath = to!string(lexeme.getFile());
            error.lineText = to!string(lexeme.getLine()).replace("\t", " ");
            error.line = lexeme._line + 1u; // By convention, the first line is 1, not 0.
            error.column = lexeme._column;
            error.textLength = lexeme._textLength;
        }
        else {
            error.filePath = to!string(_file);
            error.lineText = to!string(_lines[_line]);
            error.line = _line + 1u; // By convention, the first line is 1, not 0.
            error.column = _current - _positionOfLine;
            error.textLength = 0u;
        }

        throw new GrLexerException(error);
    }

    private enum Error {
        lexFileIdOutOfBounds,
        lexLineCountOutOfBounds,
        unexpectedEndOfFile,
        expectedQuotationMarkAtBeginningOfStr,
        missingQuotationMarkAtEndOfStr,
        invalidOp,
        missingRightCurlyBraceAfterUsedFilesList
    }

    private string getLexerError(Error error, GrLocale locale) {
        immutable string[Error][GrLocale.max + 1] messages = [
            [
                Error.lexFileIdOutOfBounds: "lexeme file id out of bounds",
                Error.lexLineCountOutOfBounds: "lexeme line count out of bounds",
                Error.unexpectedEndOfFile: "unexpected end of file",
                Error.expectedQuotationMarkAtBeginningOfStr: "expected `\"` at the beginning of the string",
                Error.missingQuotationMarkAtEndOfStr: "missing `\"` at the end of the string",
                Error.invalidOp: "invalid operator",
                Error.missingRightCurlyBraceAfterUsedFilesList: "missing `}` after used files list"
            ],
            [
                Error.lexFileIdOutOfBounds: "l’id de fichier du lexeme excède les limites",
                Error.lexLineCountOutOfBounds: "le numéro de ligne du lexeme excède les limites",
                Error.unexpectedEndOfFile: "fin de fichier inattendue",
                Error.expectedQuotationMarkAtBeginningOfStr: "`\"` attendu au début de la chaîne",
                Error.missingQuotationMarkAtEndOfStr: "`\"` manquant en fin de chaîne",
                Error.invalidOp: "operateur invalide",
                Error.missingRightCurlyBraceAfterUsedFilesList: "`}` manquant après la liste des fichiers utilisés"
            ]
        ];
        return messages[locale][error];
    }
}

/// Returns a displayable version of a token type.
string grGetPrettyLexemeType(GrLexemeType operator, GrLocale locale = GrLocale.en_US) {
    immutable string[][GrLocale.max + 1] lexemeTypeStrTable = [
        [
            "[", "]", "(", ")", "{", "}", ".", ";", ":", "::", ",", "@", "&",
            "as", "isolate", "capture", "error", "defer", "=", "&=", "|=", "^=",
            "&&=", "||=", "+=", "-=", "*=", "/=", "~=", "%=", "**=", "+", "-",
            "&", "|", "^", "&&", "||", "+", "-", "*", "/", "~", "%", "**",
            "==", "===", "<=>", "!=", ">=", ">", "<=", "<", "<<", ">>", "->",
            "=>", "~", "!", "++", "--", "identifier", "const_integer",
            "const_float", "const_bool", "const_string", "null", "public",
            "type", "action", "class", "enumeration", "instance", "new", "copy",
            "send",
            "receive", "integer", "real", "boolean", "string", "list", "channel",
            "function", "task", "let", "if", "unless", "else", "alternative",
            "select",
            "case", "while", "do", "until", "for", "loop", "return", "self",
            "die", "quit", "suspend", "break", "continue"
        ],
        [
            "[", "]", "(", ")", "{", "}", ".", ";", ":", "::", ",", "@", "&",
            "en", "isole", "capture", "erreur", "reporte", "=", "&=", "|=",
            "^=", "&&=", "||=", "+=", "-=", "*=", "/=", "~=", "%=", "**=", "+",
            "-", "&", "|", "^", "&&", "||", "+", "-", "*", "/", "~", "%",
            "**", "==", "===", "<=>", "!=", ">=", ">", "<=", "<", "<<", ">>",
            "->", "=>", "~", "!", "++", "--", "identificateur", "entier_const",
            "réel_const", "bool_const", "chaîne_const", "nul", "public",
            "type", "action", "classe", "énumération", "instance", "crée",
            "copie",
            "envoie", "reçois", "entier", "réel", "booléen", "chaîne", "liste",
            "canal", "fonction", "tâche", "soit", "si", "sauf", "sinon",
            "alternative",
            "sélectionne", "cas", "tant", "fais", "jusque", "pour", "boucle",
            "retourne", "soi", "meurs", "quitte", "suspends", "casse", "continue"
        ]
    ];
    return lexemeTypeStrTable[locale][operator];
}

/**
Lexical error during tokenization
*/
package final class GrLexerException : Exception {
    GrError error;

    /// Ctor
    this(GrError error_, string _file = __FILE__, size_t _line = __LINE__) {
        super(error_.message, _file, _line);
        error = error_;
    }
}
