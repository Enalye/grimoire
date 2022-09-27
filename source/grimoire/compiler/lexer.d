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
Describe the smallest element found in a source _file.
*/
struct GrLexeme {
    /**
    Kinds of valid token.
    */
    enum Type {
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
        throw_,
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
        optional,
        optionalOr,
        identifier,
        int_,
        real_,
        bool_,
        string_,
        null_,
        public_,
        const_,
        pure_,
        alias_,
        event,
        class_,
        enum_,
        where,
        new_,
        copy,
        send,
        receive,
        integerType,
        realType,
        booleanType,
        stringType,
        arrayType,
        channelType,
        functionType,
        taskType,
        let,
        if_,
        unless,
        else_,
        switch_,
        select,
        case_,
        default_,
        while_,
        do_,
        until,
        for_,
        loop,
        return_,
        self,
        die,
        quit,
        yield,
        break_,
        continue_,
    }

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
    Type type;

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
    GrReal rvalue;

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
        return type >= Type.add && type <= Type.not;
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
            if (lexeme.type == GrLexeme.Type.identifier) {
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
            lex.type = GrLexeme.Type.real_;
            lex.rvalue = to!GrReal(buffer);
        }
        else {
            lex.type = GrLexeme.Type.int_;
            lex.ivalue = to!GrInt(buffer);
        }
        _lexemes ~= lex;
    }

    /**
    Scan a `"` delimited string.
    */
    void scanString() {
        GrLexeme lex = GrLexeme(this);
        lex.type = GrLexeme.Type.string_;
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
            lex.type = GrLexeme.Type.leftCurlyBrace;
            break;
        case '}':
            lex.type = GrLexeme.Type.rightCurlyBrace;
            break;
        case '(':
            lex.type = GrLexeme.Type.leftParenthesis;
            break;
        case ')':
            lex.type = GrLexeme.Type.rightParenthesis;
            break;
        case '[':
            lex.type = GrLexeme.Type.leftBracket;
            break;
        case ']':
            lex.type = GrLexeme.Type.rightBracket;
            break;
        case '.':
            lex.type = GrLexeme.Type.period;
            break;
        case ';':
            lex.type = GrLexeme.Type.semicolon;
            break;
        case ':':
            lex.type = GrLexeme.Type.colon;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == ':') {
                lex.type = GrLexeme.Type.doubleColon;
                lex._textLength = 2;
                _current++;
            }
            break;
        case ',':
            lex.type = GrLexeme.Type.comma;
            break;
        case '@':
            lex.type = GrLexeme.Type.pointer;
            break;
        case '&':
            lex.type = GrLexeme.Type.bitwiseAnd;
            if (_current + 1 >= _text.length)
                break;
            switch (get(1)) {
            case '=':
                lex.type = GrLexeme.Type.bitwiseAndAssign;
                lex._textLength = 2;
                _current++;
                break;
            case '&':
                lex.type = GrLexeme.Type.and;
                lex._textLength = 2;
                _current++;
                if (_current + 1 >= _text.length)
                    break;
                if (get(1) == '&') {
                    lex.type = GrLexeme.Type.andAssign;
                    lex._textLength = 3;
                    _current++;
                }
                break;
            default:
                break;
            }
            break;
        case '|':
            lex.type = GrLexeme.Type.bitwiseOr;
            if (_current + 1 >= _text.length)
                break;
            switch (get(1)) {
            case '=':
                lex.type = GrLexeme.Type.bitwiseOrAssign;
                lex._textLength = 2;
                _current++;
                break;
            case '|':
                lex.type = GrLexeme.Type.or;
                lex._textLength = 2;
                _current++;
                if (_current + 1 >= _text.length)
                    break;
                if (get(1) == '|') {
                    lex.type = GrLexeme.Type.orAssign;
                    lex._textLength = 3;
                    _current++;
                }
                break;
            default:
                break;
            }
            break;
        case '^':
            lex.type = GrLexeme.Type.bitwiseXor;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexeme.Type.bitwiseXorAssign;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '~':
            lex.type = GrLexeme.Type.concatenate;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexeme.Type.concatenateAssign;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '+':
            lex.type = GrLexeme.Type.add;
            if (_current + 1 >= _text.length)
                break;
            switch (get(1)) {
            case '=':
                lex.type = GrLexeme.Type.addAssign;
                lex._textLength = 2;
                _current++;
                break;
            case '+':
                lex.type = GrLexeme.Type.increment;
                lex._textLength = 2;
                _current++;
                break;
            default:
                break;
            }
            break;
        case '-':
            lex.type = GrLexeme.Type.substract;
            if (_current + 1 >= _text.length)
                break;
            switch (get(1)) {
            case '=':
                lex.type = GrLexeme.Type.substractAssign;
                lex._textLength = 2;
                _current++;
                break;
            case '-':
                lex.type = GrLexeme.Type.decrement;
                lex._textLength = 2;
                _current++;
                break;
            case '>':
                lex.type = GrLexeme.Type.interval;
                lex._textLength = 2;
                _current++;
                break;
            default:
                break;
            }
            break;
        case '*':
            lex.type = GrLexeme.Type.multiply;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexeme.Type.multiplyAssign;
                lex._textLength = 2;
                _current++;
            }
            else if (get(1) == '*') {
                lex.type = GrLexeme.Type.power;
                lex._textLength = 2;
                _current++;
                if (_current + 1 >= _text.length)
                    break;
                if (get(1) == '=') {
                    lex.type = GrLexeme.Type.powerAssign;
                    lex._textLength = 3;
                    _current++;
                }
            }
            break;
        case '/':
            lex.type = GrLexeme.Type.divide;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexeme.Type.divideAssign;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '%':
            lex.type = GrLexeme.Type.remainder;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexeme.Type.remainderAssign;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '=':
            lex.type = GrLexeme.Type.assign;
            if (_current + 1 >= _text.length)
                break;
            switch (get(1)) {
            case '=':
                lex.type = GrLexeme.Type.equal;
                lex._textLength = 2;
                _current++;
                if (_current + 1 >= _text.length)
                    break;
                if (get(1) == '=') {
                    lex.type = GrLexeme.Type.doubleEqual;
                    lex._textLength = 3;
                    _current++;
                }
                break;
            case '>':
                lex.type = GrLexeme.Type.arrow;
                lex._textLength = 2;
                _current++;
                break;
            default:
                break;
            }
            break;
        case '<':
            lex.type = GrLexeme.Type.lesser;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexeme.Type.lesserOrEqual;
                lex._textLength = 2;
                _current++;
                if (_current + 1 >= _text.length)
                    break;
                if (get(1) == '>') {
                    lex.type = GrLexeme.Type.threeWayComparison;
                    lex._textLength = 3;
                    _current++;
                }
            }
            else if (get(1) == '-') {
                lex.type = GrLexeme.Type.send;
                lex._textLength = 2;
                _current++;
            }
            else if (get(1) == '<') {
                lex.type = GrLexeme.Type.leftShift;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '>':
            lex.type = GrLexeme.Type.greater;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexeme.Type.greaterOrEqual;
                lex._textLength = 2;
                _current++;
            }
            else if (get(1) == '>') {
                lex.type = GrLexeme.Type.rightShift;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '!':
            lex.type = GrLexeme.Type.not;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexeme.Type.notEqual;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '?':
            lex.type = GrLexeme.Type.optional;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '?') {
                lex.type = GrLexeme.Type.optionalOr;
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
            /*if (symbol == '?') {
                buffer ~= symbol;
                _current++;
                break;
            }*/
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
        case "import":
            scanUse();
            return;
        case "public":
            lex.type = GrLexeme.Type.public_;
            break;
        case "const":
            lex.type = GrLexeme.Type.const_;
            break;
        case "pure":
            lex.type = GrLexeme.Type.pure_;
            break;
        case "alias":
            lex.type = GrLexeme.Type.alias_;
            break;
        case "event":
            lex.type = GrLexeme.Type.event;
            break;
        case "class":
            lex.type = GrLexeme.Type.class_;
            break;
        case "enum":
            lex.type = GrLexeme.Type.enum_;
            break;
        case "where":
            lex.type = GrLexeme.Type.where;
            break;
        case "if":
            lex.type = GrLexeme.Type.if_;
            break;
        case "unless":
            lex.type = GrLexeme.Type.unless;
            break;
        case "else":
            lex.type = GrLexeme.Type.else_;
            break;
        case "switch":
            lex.type = GrLexeme.Type.switch_;
            break;
        case "select":
            lex.type = GrLexeme.Type.select;
            break;
        case "case":
            lex.type = GrLexeme.Type.case_;
            break;
        case "default":
            lex.type = GrLexeme.Type.default_;
            break;
        case "while":
            lex.type = GrLexeme.Type.while_;
            break;
        case "do":
            lex.type = GrLexeme.Type.do_;
            break;
        case "until":
            lex.type = GrLexeme.Type.until;
            break;
        case "for":
            lex.type = GrLexeme.Type.for_;
            break;
        case "loop":
            lex.type = GrLexeme.Type.loop;
            break;
        case "return":
            lex.type = GrLexeme.Type.return_;
            break;
        case "self":
            lex.type = GrLexeme.Type.self;
            break;
        case "die":
            lex.type = GrLexeme.Type.die;
            break;
        case "exit":
            lex.type = GrLexeme.Type.quit;
            break;
        case "yield":
            lex.type = GrLexeme.Type.yield;
            break;
        case "break":
            lex.type = GrLexeme.Type.break_;
            break;
        case "continue":
            lex.type = GrLexeme.Type.continue_;
            break;
        case "as":
            lex.type = GrLexeme.Type.as;
            break;
        case "try":
            lex.type = GrLexeme.Type.try_;
            break;
        case "catch":
            lex.type = GrLexeme.Type.catch_;
            break;
        case "throw":
            lex.type = GrLexeme.Type.throw_;
            break;
        case "defer":
            lex.type = GrLexeme.Type.defer;
            break;
        case "task":
            lex.type = GrLexeme.Type.taskType;
            lex.isType = true;
            break;
        case "function":
            lex.type = GrLexeme.Type.functionType;
            lex.isType = true;
            break;
        case "int":
            lex.type = GrLexeme.Type.integerType;
            lex.isType = true;
            break;
        case "real":
            lex.type = GrLexeme.Type.realType;
            lex.isType = true;
            break;
        case "bool":
            lex.type = GrLexeme.Type.booleanType;
            lex.isType = true;
            break;
        case "string":
            lex.type = GrLexeme.Type.stringType;
            lex.isType = true;
            break;
        case "array":
            lex.type = GrLexeme.Type.arrayType;
            lex.isType = true;
            break;
        case "channel":
            lex.type = GrLexeme.Type.channelType;
            lex.isType = true;
            break;
        case "new":
            lex.type = GrLexeme.Type.new_;
            lex.isType = false;
            break;
        case "let":
            lex.type = GrLexeme.Type.let;
            lex.isType = false;
            break;
        case "true":
            lex.type = GrLexeme.Type.bool_;
            lex.isKeyword = false;
            lex.isLiteral = true;
            lex.bvalue = true;
            break;
        case "false":
            lex.type = GrLexeme.Type.bool_;
            lex.isKeyword = false;
            lex.isLiteral = true;
            lex.bvalue = false;
            break;
        case "null":
            lex.type = GrLexeme.Type.null_;
            lex.isKeyword = false;
            lex.isLiteral = true;
            break;
        case "to":
            lex.type = GrLexeme.Type.interval;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "and":
            lex.type = GrLexeme.Type.and;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "or":
            lex.type = GrLexeme.Type.or;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "not":
            lex.type = GrLexeme.Type.not;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "bit_and":
            lex.type = GrLexeme.Type.bitwiseAnd;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "bit_or":
            lex.type = GrLexeme.Type.bitwiseOr;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "bit_xor":
            lex.type = GrLexeme.Type.bitwiseXor;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "bit_not":
            lex.type = GrLexeme.Type.bitwiseNot;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        default:
            lex.isKeyword = false;
            lex.type = GrLexeme.Type.identifier;
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

    /// add a single file path delimited by `"` to the import list.
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
                Error.invalidOp: "opérateur invalide",
                Error.missingRightCurlyBraceAfterUsedFilesList: "`}` manquant après la liste des fichiers utilisés"
            ]
        ];
        return messages[locale][error];
    }
}

private immutable string[] _prettyLexemeTypeTable = [
    "[", "]", "(", ")", "{", "}", ".", ";", ":", "::", ",", "@", "&",
    "as", "try", "catch", "error", "defer", "=", "&=", "|=", "^=",
    "&&=", "||=", "+=", "-=", "*=", "/=", "~=", "%=", "**=", "+", "-",
    "&", "|", "^", "&&", "||", "+", "-", "*", "/", "~", "%", "**",
    "==", "===", "<=>", "!=", ">=", ">", "<=", "<", "<<", ">>", "->",
    "=>", "~", "!", "++", "--", "?", "??", "identifier", "const_int",
    "const_float", "const_bool", "const_string", "null", "public", "const",
    "pure", "alias", "event", "class", "enum", "where", "new", "copy",
    "send", "receive", "int", "real", "bool", "string", "array",
    "channel", "function", "task", "let", "if", "unless", "else",
    "switch", "select", "case", "default", "while", "do", "until", "for",
    "loop", "return", "self", "die", "exit", "yield", "break", "continue"
];

/// Returns a displayable version of a token type.
string grGetPrettyLexemeType(GrLexeme.Type operator) {
    return _prettyLexemeTypeTable[operator];
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
