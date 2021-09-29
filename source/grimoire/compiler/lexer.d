/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.lexer;

import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.math;
import std.file;
import std.algorithm : canFind;
import grimoire.assembly;
import grimoire.compiler.error;

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
    try_,
    catch_,
    raise_,
    defer,
    assign,
    addAssign,
    substractAssign,
    multiplyAssign,
    divideAssign,
    concatenateAssign,
    remainderAssign,
    powerAssign,
    plus,
    minus,
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
    and,
    or,
    xor,
    not,
    increment,
    decrement,
    identifier,
    integer,
    float_,
    boolean,
    string_,
    null_,
    public_,
    main_,
    type_,
    event_,
    class_,
    enum_,
    template_,
    new_,
    copy,
    send,
    receive,
    intType,
    floatType,
    boolType,
    stringType,
    arrayType,
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
    kill,
    killAll,
    yield,
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

    /// Only describe first class type such as `int`, `string` or `func`.
    /// Structure or other custom type are not.
    bool isType;

    /// Integral value of the constant.
    /// isLiteral will be true and type set to integer.
    GrInt ivalue;

    /// Floating point value of the constant.
    /// isLiteral will be true and type set to float_.
    GrFloat fvalue;

    /// boolean value of the constant.
    /// isLiteral will be true and type set to boolean.
    bool bvalue;

    /// Can either describe a literal value like `"myString"` or an identifier.
    GrString svalue;

    /// Returns the entire _line from where the token is located.
    string getLine() {
        return lexer.getLine(this);
    }

    string getFile() {
        return lexer.getFile(this);
    }
}

/**
The lexer scans the entire file and all the imported files it references.
*/
package final class GrLexer {
    private {
        string[] _filesToImport, _filesImported;
        string[] _lines;
        string _file, _text;
        uint _line, _current, _positionOfLine, _fileId;
        GrLexeme[] _lexemes;
    }

    @property {
        /// Generated tokens.
        GrLexeme[] lexemes() {
            return _lexemes;
        }
    }

    /// Start scanning the root file and all its dependencies.
    void scanFile(string fileName) {
        import std.path : buildNormalizedPath, absolutePath;

        string filePath = to!string(fileName);
        filePath = buildNormalizedPath(convertPathToImport(filePath));
        filePath = absolutePath(filePath);
        fileName = to!string(filePath);

        _filesToImport ~= fileName;

        while (_filesToImport.length) {
            _file = _filesToImport[$ - 1];
            _filesImported ~= _file;
            _text = to!string(readText(to!string(_file)));
            _filesToImport.length--;

            _line = 0u;
            _current = 0u;
            _positionOfLine = 0u;
            _lines = split(_text, "\n");

            scanScript();

            _fileId++;
        }
    }

    /**
	Fetch the entire line where a lexeme is.
	*/
    package string getLine(GrLexeme lex) {
        if (lex._fileId >= _filesImported.length)
            raiseError("Lexeme file id out of bounds");
        auto _text = to!string(readText(to!string(_filesImported[lex._fileId])));
        _lines = split(_text, "\n");
        if (lex._line >= _lines.length)
            raiseError("Lexeme line count out of bounds");
        return _lines[lex._line];
    }

    /**
	Fetch the file where a lexeme is.
	*/
    package string getFile(GrLexeme lex) {
        if (lex._fileId >= _filesImported.length)
            raiseError("Lexeme file id out of bounds");
        return _filesImported[lex._fileId];
    }
    /// Ditto
    package string getFile(size_t fileId) {
        if (fileId >= _filesImported.length)
            raiseError("file id out of bounds");
        return _filesImported[fileId];
    }

    private dchar get(int offset = 0) {
        const uint position = to!int(_current) + offset;
        if (position < 0 || position >= _text.length)
            raiseError("Unexpected end of script");
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
                    for (;;) {
                        if ((_current + 1) >= _text.length) {
                            _current++;
                            return false;
                        }

                        if (_text[_current] == '\n') {
                            _positionOfLine = _current;
                            _line++;
                        }

                        if (_text[_current] == '*' && _text[_current + 1] == '/') {
                            _current++;
                            break;
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
            lex.type = GrLexemeType.float_;
            lex.fvalue = to!GrFloat(buffer);
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
            raiseError("Expected \'\"\' at the beginning of the string.");
        _current++;

        string buffer;
        bool escape = false;
        bool wasEscape = false;
        for (;;) {
            if (_current >= _text.length)
                raiseError("Missing \'\"\' character.");
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
        case '^':
            lex.type = GrLexemeType.power;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexemeType.powerAssign;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '@':
            lex.type = GrLexemeType.at;
            break;
        case '&':
            lex.type = GrLexemeType.pointer;
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
            if (get(1) == '=') {
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
            raiseError("GrLexer: invalid operator");
        }

        _lexemes ~= lex;
    }

    /**
	Scan a known keyword or an identifier otherwise.
	*/
    private void scanWord() {
        GrLexeme lex = GrLexeme(this);
        lex.isKeyword = true;

        string buffer;
        for (;;) {
            if (_current >= _text.length)
                break;

            const dchar symbol = get();
            if (symbol == '!' || symbol == '?') {
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
        case "use":
            scanUse();
            return;
        case "pub":
            lex.type = GrLexemeType.public_;
            break;
        case "main":
            lex.type = GrLexemeType.main_;
            break;
        case "type":
            lex.type = GrLexemeType.type_;
            break;
        case "event":
            lex.type = GrLexemeType.event_;
            break;
        case "class":
            lex.type = GrLexemeType.class_;
            break;
        case "enum":
            lex.type = GrLexemeType.enum_;
            break;
        case "template":
            lex.type = GrLexemeType.template_;
            break;
        case "if":
            lex.type = GrLexemeType.if_;
            break;
        case "unless":
            lex.type = GrLexemeType.unless;
            break;
        case "else":
            lex.type = GrLexemeType.else_;
            break;
        case "switch":
            lex.type = GrLexemeType.switch_;
            break;
        case "select":
            lex.type = GrLexemeType.select;
            break;
        case "case":
            lex.type = GrLexemeType.case_;
            break;
        case "while":
            lex.type = GrLexemeType.while_;
            break;
        case "do":
            lex.type = GrLexemeType.do_;
            break;
        case "until":
            lex.type = GrLexemeType.until;
            break;
        case "for":
            lex.type = GrLexemeType.for_;
            break;
        case "loop":
            lex.type = GrLexemeType.loop;
            break;
        case "return":
            lex.type = GrLexemeType.return_;
            break;
        case "self":
            lex.type = GrLexemeType.self;
            break;
        case "kill":
            lex.type = GrLexemeType.kill;
            break;
        case "killall":
            lex.type = GrLexemeType.killAll;
            break;
        case "yield":
            lex.type = GrLexemeType.yield;
            break;
        case "break":
            lex.type = GrLexemeType.break_;
            break;
        case "continue":
            lex.type = GrLexemeType.continue_;
            break;
        case "as":
            lex.type = GrLexemeType.as;
            break;
        case "try":
            lex.type = GrLexemeType.try_;
            break;
        case "catch":
            lex.type = GrLexemeType.catch_;
            break;
        case "raise":
            lex.type = GrLexemeType.raise_;
            break;
        case "defer":
            lex.type = GrLexemeType.defer;
            break;
        case "task":
            lex.type = GrLexemeType.taskType;
            lex.isType = true;
            break;
        case "func":
            lex.type = GrLexemeType.functionType;
            lex.isType = true;
            break;
        case "int":
            lex.type = GrLexemeType.intType;
            lex.isType = true;
            break;
        case "float":
            lex.type = GrLexemeType.floatType;
            lex.isType = true;
            break;
        case "bool":
            lex.type = GrLexemeType.boolType;
            lex.isType = true;
            break;
        case "string":
            lex.type = GrLexemeType.stringType;
            lex.isType = true;
            break;
        case "array":
            lex.type = GrLexemeType.arrayType;
            lex.isType = true;
            break;
        case "chan":
            lex.type = GrLexemeType.chanType;
            lex.isType = true;
            break;
        case "new":
            lex.type = GrLexemeType.new_;
            lex.isType = false;
            break;
        case "let":
            lex.type = GrLexemeType.autoType;
            lex.isType = false;
            break;
        case "true":
            lex.type = GrLexemeType.boolean;
            lex.isKeyword = false;
            lex.isLiteral = true;
            lex.bvalue = true;
            break;
        case "false":
            lex.type = GrLexemeType.boolean;
            lex.isKeyword = false;
            lex.isLiteral = true;
            lex.bvalue = false;
            break;
        case "null":
            lex.type = GrLexemeType.null_;
            lex.isKeyword = false;
            lex.isLiteral = true;
            break;
        case "not":
            lex.type = GrLexemeType.not;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "and":
            lex.type = GrLexemeType.and;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "or":
            lex.type = GrLexemeType.or;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "xor":
            lex.type = GrLexemeType.xor;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        default:
            lex.isKeyword = false;
            lex.type = GrLexemeType.identifier;
            lex.svalue = buffer;
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
            raiseError("Expected \'\"\' at the beginning of the import.");
        _current++;

        string buffer;
        for (;;) {
            if (_current >= _text.length)
                raiseError("Missing \'\"\' character.");
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

    /// Scan a `use` directive. \
    /// Syntax: \
    /// `use "FILEPATH"` or \
    /// `use { "FILEPATH1", "FILEPATH2", "FILEPATH3" }` \
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
                    raiseError("Missing \'\"\' character.");
                // EOF
                if (_current >= _text.length)
                    raiseError("Missing \'}\' after import list.");
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
}

/// Returns a displayable version of a token type.
string grGetPrettyLexemeType(GrLexemeType operator) {
    immutable string[] lexemeTypeStrTable = [
        "[", "]", "(", ")", "{", "}", ".", ";", ":", "::", ",", "@", "&", "as",
        "try", "catch", "raise", "defer", "=", "+=", "-=", "*=", "/=", "~=",
        "%=", "^=", "+", "-", "+", "-", "*", "/", "~", "%", "^", "==", "===",
        "<=>", "!=", ">=", ">", "<=", "<", "<<", ">>", "and", "or", "xor",
        "not", "++", "--", "identifier", "const_int", "const_float", "const_bool",
        "const_str", "null", "pub", "main", "type", "event", "class", "enum",
        "template", "new", "copy", "send", "receive", "int", "float", "bool",
        "string", "array", "chan", "func", "task", "let", "if", "unless",
        "else", "switch", "select", "case", "while", "do", "until", "for", "loop",
        "return", "self", "kill", "killall", "yield", "break", "continue"
    ];
    return lexemeTypeStrTable[operator];
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
