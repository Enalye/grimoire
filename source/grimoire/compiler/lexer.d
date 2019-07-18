/**
    Scan a file and produce a list of tokens.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.compiler.lexer;

import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.math;
import std.file;
import std.algorithm: canFind;

/**
    Kinds of valid token.
*/
enum GrLexemeType {
	LeftBracket, RightBracket, LeftParenthesis, RightParenthesis, LeftCurlyBrace, RightCurlyBrace,
	Period, Semicolon, Colon, Comma, At, Pointer, As, Is, Try, Catch, Raise, Defer,
	Assign,
	AddAssign, SubstractAssign, MultiplyAssign, DivideAssign, ConcatenateAssign, RemainderAssign, PowerAssign,
	Plus, Minus,
	Add, Substract, Multiply, Divide, Concatenate, Remainder, Power,
	Equal, NotEqual, GreaterOrEqual, Greater, LesserOrEqual, Lesser,
	And, Or, Xor, Not,
	Increment, Decrement,
	Identifier, Integer, Float, Boolean, String,
	Main, Event, Def, Tuple, New, Copy, Send, Receive,
	VoidType, IntType, FloatType, BoolType, StringType, ArrayType, VariantType, FunctionType, TaskType, ChanType, AutoType,
	If, Unless, Else, Switch, Select, Case, While, Do, For, Loop, Return,
	Kill, KillAll, Yield, Break, Continue,
}

/**
    Describe the smallest element found in a source file.
*/
struct GrLexeme {
    /// Default.
	this(GrLexer _lexer) {
		line = _lexer.line;
		column = _lexer.current - _lexer.positionOfLine;
		lexer = _lexer;
	}

    /// Parent lexer.
	GrLexer lexer;

    /// Position information in case of errors.
	uint line, column, textLength = 1;

	GrLexemeType type;

    /// Whether the lexeme is a constant value.
	bool isLiteral;

    /// Whether the lexeme is an operator.
	bool isOperator;

    /// Is this a reserved grimoire word ?
	bool isKeyword;

    /// Only describe first class type such as `int`, `string` or `func`.
    /// Structure or other custom type are not.
	bool isType;

    /// Integral value of the constant.
    /// isLiteral will be true and type set to Integer.
	int ivalue;

    /// Floating point value of the constant.
    /// isLiteral will be true and type set to Float.
	float fvalue;

    /// Boolean value of the constant.
    /// isLiteral will be true and type set to Boolean.
	bool bvalue;

    /// Can either describe a literal value like `"myString"` or an identifier.
	dstring svalue;

    /// Returns the entire line from where the token is located.
	dstring getLine() {
		return lexer.lines[line];
	}
}

/**
    The lexer scans the entire file and all the imported files it references.
*/
class GrLexer {
	dstring[] filesToImport, filesImported;
	dstring[] lines;
	dstring file, text;
	uint line, current, positionOfLine;
	GrLexeme[] lexemes;

	dchar get(int offset = 0) {
		uint position = to!int(current) + offset;
		if(position < 0 || position >= text.length)
			throw new Exception("Unexpected end of script.");
		return text[position];
	}

	bool advance(bool startFromCurrent = false) {
        if(!startFromCurrent)
		    current ++;

		if(current >= text.length)
			return false;

		dchar symbol = text[current];

		whileLoop: while(symbol <= 0x20 || symbol == '/' || symbol == '#') {
			if(current >= text.length)
				return false;

			symbol = text[current];

			if(symbol == '\n') {
				positionOfLine = current;
				line ++;
			}
            else if(symbol == '#') {
                do {
                    if((current + 1) >= text.length)
                        return false;
                    current ++;
                }
                while(text[current] != '\n');
                positionOfLine = current;
                line ++;
            }
			else if(symbol == '/') {
				if((current + 1) >= text.length)
					return false;

				switch(text[current + 1]) {
					case '/':
						do {
							if((current + 1) >= text.length)
								return false;
							current ++;
						}
						while(text[current] != '\n');
						positionOfLine = current;
						line ++;
						break;
					case '*':
						for(;;) {
							if((current + 2) >= text.length)
								return false;

							if(text[current] == '\n') {
								positionOfLine = current;
								line ++;
							}

							if(text[current] == '*' && text[current + 1] == '/') {
								current ++;
								break;
							}

							current ++;
						}
						
						break;
					default:
						break whileLoop;
				}
			}
			current ++;

			if(current >= text.length)
				return false;

			symbol = text[current];
		}
		return true;
	}

	void scanFile(dstring fileName) {
		filesImported ~= fileName;
		filesToImport ~= fileName;

		while(filesToImport.length) {
			text = to!dstring(readText(to!string(filesToImport[$-1])));
			file = filesToImport[$-1];
			filesToImport.length --;

			line = 0u;
			current = 0u;
			lines = split(text, "\n");

			scanScript();
		}
	}

	void scanScript() {
		//Skip the first escape characters.
		advance(true);
    
		do {
			switch(get()) {
				case '0': .. case '9':
					scanNumber();
					break;
                case '.':
                    if(get(1) >= '0' && get(1) <= '9')
                        scanNumber();
                    else
                        goto case '!';
                    break;
				case '!':
				case '#': .. case '&':
				case '(': .. case '-':
				case '/':
				case ':': .. case '@':
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
        while(advance());
	}

	void debugShowScan() {
		writeln("Scan:");

		foreach(lexeme; lexemes) {
			writeln(lexeme);
		}
	}

	void scanNumber() {
		GrLexeme lex = GrLexeme(this);
		lex.isLiteral = true;

		bool isFloat;
		dstring buffer;
		for(;;) {
			dchar symbol = get();

			if(symbol >= '0' && symbol <= '9')
				buffer ~= symbol;
			else if(symbol == '.') {
				if(isFloat)
					break;
				isFloat = true;
				buffer ~= symbol;
			}
			else if(symbol == 'f') {
				isFloat = true;
				break;
			}
			else {
				if(current)
					current --;
				break;
			}

			current ++;

			if(current >= text.length)
				break;
		}

		lex.textLength = cast(uint)buffer.length;

		if(isFloat) {
			lex.type = GrLexemeType.Float;
			lex.fvalue = to!float(buffer);
		}
		else {
			lex.type = GrLexemeType.Integer;
			lex.ivalue = to!int(buffer);
		}
		lexemes ~= lex;
	}

	void scanString() {
		GrLexeme lex = GrLexeme(this);
		lex.type = GrLexemeType.String;
		lex.isLiteral = true;

		if(get() != '\"')
			throw new Exception("Expected \'\"\' at the beginning of the string.");
		current ++;

		dstring buffer;
		for(;;) {
			if(current >= text.length)
				throw new Exception("Missing \'\"\' character.");
			dchar symbol = get();
			if(symbol == '\n') {
				positionOfLine = current;
				line ++;
			}
			else if(symbol == '\"')
				break;

			buffer ~= symbol;
			current ++;
		}

		lex.textLength = cast(uint)buffer.length;
		lex.svalue = buffer;
		lexemes ~= lex;
	}

	void scanOperator() {
		GrLexeme lex = GrLexeme(this);
		lex.isOperator = true;

		switch(get()) {
			case '{':
				lex.type = GrLexemeType.LeftCurlyBrace;
				break;
			case '}':
				lex.type = GrLexemeType.RightCurlyBrace;
				break;
			case '(':
				lex.type = GrLexemeType.LeftParenthesis;
				break;
			case ')':
				lex.type = GrLexemeType.RightParenthesis;
				break;
			case '[':
				lex.type = GrLexemeType.LeftBracket;
				break;
			case ']':
				lex.type = GrLexemeType.RightBracket;
				break;
			case '.':
				lex.type = GrLexemeType.Period;
				break;
			case ';':
				lex.type = GrLexemeType.Semicolon;
				break;
			case ':':
				lex.type = GrLexemeType.Colon;
				break;
			case ',':
				lex.type = GrLexemeType.Comma;
				break;
            case '@':
                lex.type = GrLexemeType.New;
                break;
			case '^':
				lex.type = GrLexemeType.Copy;
				break;
            case '&':
                lex.type = GrLexemeType.Pointer;
                break;
			case '~':
				lex.type = GrLexemeType.Concatenate;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.ConcatenateAssign;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '+':
				lex.type = GrLexemeType.Add;
				if(current + 1 >= text.length)
					break;
				switch(get(1)) {
					case '=':
						lex.type = GrLexemeType.AddAssign;
						lex.textLength = 2;
						current ++;
						break;
					case '+':
						lex.type = GrLexemeType.Increment;
						lex.textLength = 2;
						current ++;
						break;
					default:
						break;
				}
				break;
			case '-':
				lex.type = GrLexemeType.Substract;
				if(current + 1 >= text.length)
					break;
				switch(get(1)) {
					case '=':
						lex.type = GrLexemeType.SubstractAssign;
						lex.textLength = 2;
						current ++;
						break;
					case '-':
						lex.type = GrLexemeType.Decrement;
						lex.textLength = 2;
						current ++;
						break;
					default:
						break;
				}
				break;
			case '*':
				lex.type = GrLexemeType.Multiply;
				if(current + 1 >= text.length)
					break;
				switch(get(1)) {
					case '=':
						lex.type = GrLexemeType.MultiplyAssign;
						lex.textLength = 2;
						current ++;
						break;
					case '*':
						lex.type = GrLexemeType.Power;
						lex.textLength = 2;
						current ++;
						if(current + 1 >= text.length)
							break;
						if(get(1) == '=') {
							lex.type = GrLexemeType.PowerAssign;
							lex.textLength = 3;
							current ++;
						}
						break;
					default:
						break;
				}
				break;
			case '/':
				lex.type = GrLexemeType.Divide;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.DivideAssign;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '%':
				lex.type = GrLexemeType.Remainder;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.RemainderAssign;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '=':
				lex.type = GrLexemeType.Assign;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.Equal;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '<':
				lex.type = GrLexemeType.Lesser;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.LesserOrEqual;
					lex.textLength = 2;
					current ++;
				}
				else if(get(1) == '-') {
					lex.type = GrLexemeType.Send;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '>':
				lex.type = GrLexemeType.Greater;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.GreaterOrEqual;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '!':
				lex.type = GrLexemeType.Not;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.NotEqual;
					lex.textLength = 2;
					current ++;
				}
				break;
			default:
				throw new Exception("GrLexer: Invalid operator.");
		}

		lexemes ~= lex;
	}

	void scanWord() {
		GrLexeme lex = GrLexeme(this);
		lex.isKeyword = true;

		dstring buffer;
		for(;;) {
			if(current >= text.length)
				break;

			dchar symbol = get();
			if(symbol <= '&' || (symbol >= '(' && symbol <= '/') || (symbol >= ':' && symbol <= '@') || (symbol >= '[' && symbol <= '^') || (symbol >= '{' && symbol <= 0x7F))
				break;

			buffer ~= symbol;
			current ++;
		}
		current --;

		lex.textLength = cast(uint)buffer.length;

		switch(buffer) {
			case "import":
				scanImport();
				return;
			case "main":
				lex.type = GrLexemeType.Main;
				break;
            case "event":
				lex.type = GrLexemeType.Event;
				break;
            case "def":
				lex.type = GrLexemeType.Def;
				break;
            case "tuple":
				lex.type = GrLexemeType.Tuple;
				break;
			case "if":
				lex.type = GrLexemeType.If;
				break;
            case "unless":
                lex.type = GrLexemeType.Unless;
                break;
			case "else":
				lex.type = GrLexemeType.Else;
				break;
			case "switch":
				lex.type = GrLexemeType.Switch;
				break;
			case "select":
				lex.type = GrLexemeType.Select;
				break;
			case "case":
				lex.type = GrLexemeType.Case;
				break;
			case "while":
				lex.type = GrLexemeType.While;
				break;
			case "do":
				lex.type = GrLexemeType.Do;
				break;
			case "for":
				lex.type = GrLexemeType.For;
				break;
			case "loop":
				lex.type = GrLexemeType.Loop;
				break;
			case "return":
				lex.type = GrLexemeType.Return;
				break;
            case "kill":
				lex.type = GrLexemeType.Kill;
				break;
			case "killall":
				lex.type = GrLexemeType.KillAll;
				break;
			case "yield":
				lex.type = GrLexemeType.Yield;
				break;
			case "break":
				lex.type = GrLexemeType.Break;
				break;
			case "continue":
				lex.type = GrLexemeType.Continue;
				break;
            case "as":
                lex.type = GrLexemeType.As;
                break;
            case "is":
                lex.type = GrLexemeType.Is;
                break;
            case "try":
                lex.type = GrLexemeType.Try;
                break;
            case "catch":
                lex.type = GrLexemeType.Catch;
                break;
            case "raise":
                lex.type = GrLexemeType.Raise;
                break;
            case "defer":
                lex.type = GrLexemeType.Defer;
                break;
			case "void":
				lex.type = GrLexemeType.VoidType;
				lex.isType = true;
				break;
			case "task":
				lex.type = GrLexemeType.TaskType;
				lex.isType = true;
				break;
			case "func":
				lex.type = GrLexemeType.FunctionType;
				lex.isType = true;
				break;
			case "int":
				lex.type = GrLexemeType.IntType;
				lex.isType = true;
				break;
			case "float":
				lex.type = GrLexemeType.FloatType;
				lex.isType = true;
				break;
			case "bool":
				lex.type = GrLexemeType.BoolType;
				lex.isType = true;
				break;
			case "string":
				lex.type = GrLexemeType.StringType;
				lex.isType = true;
				break;
			case "array":
				lex.type = GrLexemeType.ArrayType;
				lex.isType = true;
				break;
			case "chan":
				lex.type = GrLexemeType.ChanType;
				lex.isType = true;
				break;
			case "var":
				lex.type = GrLexemeType.VariantType;
				lex.isType = true;
				break;
            case "let":
                lex.type = GrLexemeType.AutoType;
                lex.isType = false;
                break;
			case "true":
				lex.type = GrLexemeType.Boolean;
				lex.isKeyword = false;
				lex.isLiteral = true;
				lex.bvalue = true;
				break;
			case "false":
				lex.type = GrLexemeType.Boolean;
				lex.isKeyword = false;
				lex.isLiteral = true;
				lex.bvalue = false;
				break;
			case "not":
				lex.type = GrLexemeType.Not;
				lex.isKeyword = false;
				lex.isOperator = true;
				break;
			case "and":
				lex.type = GrLexemeType.And;
				lex.isKeyword = false;
				lex.isOperator = true;
				break;
			case "or":
				lex.type = GrLexemeType.Or;
				lex.isKeyword = false;
				lex.isOperator = true;
				break;
			case "xor":
				lex.type = GrLexemeType.Xor;
				lex.isKeyword = false;
				lex.isOperator = true;
				break;
			default:
				lex.isKeyword = false;
				lex.type = GrLexemeType.Identifier;
				lex.svalue = buffer;
				break;
		}

		lexemes ~= lex;
	}

	void scanImport() {
		advance();

		if(get() != '\"')
			throw new Exception("Expected \'\"\' at the beginning of the import.");
		current ++;

		dstring buffer;
		for(;;) {
			if(current >= text.length)
				throw new Exception("Missing \'\"\' character.");
			dchar symbol = get();
			if(symbol == '\n') {
				positionOfLine = current;
				line ++;
			}
			else if(symbol == '\"')
				break;

			buffer ~= symbol;
			current ++;
		}

		if(filesImported.canFind(buffer))
			return;

		filesToImport ~= buffer;
	}
}

dstring grGetPrettyLexemeType(GrLexemeType operator) {
    dstring[] lexemeTypeStrTable = [
        "[", "]", "(", ")", "{", "}",
        ".", ";", ":", ",", "@", "&", "as", "is", "try", "catch", "raise", "defer",
        "=",
        "+=", "-=", "*=", "/=", "~=", "%=", "**=",
        "+", "-",
        "+", "-", "*", "/", "~", "%", "**",
        "==", "!=", ">=", ">", "<=", "<",
        "and", "or", "xor", "not",
        "++", "--",
        "identifier", "const_int", "const_float", "const_bool", "const_str",
        "main", "event", "def", "tuple", "new", "copy", "send", "receive",
        "void", "int", "float", "bool", "string", "array", "var", "func", "task", "chan", "let",
        "if", "unless", "else", "switch", "select", "case", "while", "do", "for", "loop", "return",
		"kill", "killall", "yield", "break", "continue"
    ];
    return lexemeTypeStrTable[operator];
}