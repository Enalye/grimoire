/**
Grimoire
Copyright (c) 2017 Enalye

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising
from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product documentation would be appreciated but
	   is not required.

	2. Altered source versions must be plainly marked as such,
	   and must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source distribution.
*/

module script.lexer;

import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.math;
import std.file;
import std.algorithm: canFind;

enum LexemeType {
	LeftBracket, RightBracket, LeftParenthesis, RightParenthesis, LeftCurlyBrace, RightCurlyBrace,
	Period, Semicolon, Colon, Comma, Pointer, As, Is,
	Assign,
	AddAssign, SubstractAssign, MultiplyAssign, DivideAssign, ConcatenateAssign, RemainderAssign, PowerAssign,
	Plus, Minus,
	Add, Substract, Multiply, Divide, Concatenate, Remainder, Power,
	Equal, NotEqual, GreaterOrEqual, Greater, LesserOrEqual, Lesser,
	And, Or, Xor, Not,
	Increment, Decrement,
	Identifier, Integer, Float, Boolean, String,
	Main, Struct,
	VoidType, IntType, FloatType, BoolType, StringType, ArrayType, ObjectType, AnyType, FunctionType, TaskType, AutoType,
	If, Else, While, Do, For, Loop, Return, Yield, Break, Continue
}

struct Lexeme {
	this(Lexer _lexer) {
		line = _lexer.line;
		column = _lexer.current - _lexer.positionOfLine;
		lexer = _lexer;
	}

	Lexer lexer;

	uint line, column, textLength = 1;

	LexemeType type;

	bool isLiteral;
	bool isOperator;
	bool isKeyword;
	bool isType;

	int ivalue;
	float fvalue;
	bool bvalue;
	dstring svalue;

	dstring getLine() {
		return lexer.lines[line];
	}
}

class Lexer {
	dstring[] filesToImport, filesImported;
	dstring[] lines;
	dstring file, text;
	uint line, current, positionOfLine;
	Lexeme[] lexemes;

	dchar get(int offset = 0) {
		uint position = to!int(current) + offset;
		if(position < 0 || position >= text.length)
			throw new Exception("Unexpected end of script.");
		return text[position];
	}

	bool advance() {
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
			text = to!dstring(readText(filesToImport[$-1]));
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
		dchar symbol = get();
		if(symbol <= 0x20 || symbol == '/') {
			if(symbol == '\n') {
				positionOfLine = 1;
				line ++;
			}
			else if(get(1) == '*') {
				current += 2;
				for(;;) {
					if((current + 2) >= text.length)
						break;

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
			}
			advance();
		}

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
		Lexeme lex = Lexeme(this);
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
			lex.type = LexemeType.Float;
			lex.fvalue = to!float(buffer);
		}
		else {
			lex.type = LexemeType.Integer;
			lex.ivalue = to!int(buffer);
		}
		lexemes ~= lex;
	}

	void scanString() {
		Lexeme lex = Lexeme(this);
		lex.type = LexemeType.String;
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
		Lexeme lex = Lexeme(this);
		lex.isOperator = true;

		switch(get()) {
			case '{':
				lex.type = LexemeType.LeftCurlyBrace;
				break;
			case '}':
				lex.type = LexemeType.RightCurlyBrace;
				break;
			case '(':
				lex.type = LexemeType.LeftParenthesis;
				break;
			case ')':
				lex.type = LexemeType.RightParenthesis;
				break;
			case '[':
				lex.type = LexemeType.LeftBracket;
				break;
			case ']':
				lex.type = LexemeType.RightBracket;
				break;
			case '.':
				lex.type = LexemeType.Period;
				break;
			case ';':
				lex.type = LexemeType.Semicolon;
				break;
			case ':':
				lex.type = LexemeType.Colon;
				break;
			case ',':
				lex.type = LexemeType.Comma;
				break;
            case '&':
                lex.type = LexemeType.Pointer;
                break;
			case '~':
				lex.type = LexemeType.Concatenate;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = LexemeType.ConcatenateAssign;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '+':
				lex.type = LexemeType.Add;
				if(current + 1 >= text.length)
					break;
				switch(get(1)) {
					case '=':
						lex.type = LexemeType.AddAssign;
						lex.textLength = 2;
						current ++;
						break;
					case '+':
						lex.type = LexemeType.Increment;
						lex.textLength = 2;
						current ++;
						break;
					default:
						break;
				}
				break;
			case '-':
				lex.type = LexemeType.Substract;
				if(current + 1 >= text.length)
					break;
				switch(get(1)) {
					case '=':
						lex.type = LexemeType.SubstractAssign;
						lex.textLength = 2;
						current ++;
						break;
					case '-':
						lex.type = LexemeType.Decrement;
						lex.textLength = 2;
						current ++;
						break;
					default:
						break;
				}
				break;
			case '*':
				lex.type = LexemeType.Multiply;
				if(current + 1 >= text.length)
					break;
				switch(get(1)) {
					case '=':
						lex.type = LexemeType.MultiplyAssign;
						lex.textLength = 2;
						current ++;
						break;
					case '*':
						lex.type = LexemeType.Power;
						lex.textLength = 2;
						current ++;
						if(current + 1 >= text.length)
							break;
						if(get(1) == '=') {
							lex.type = LexemeType.PowerAssign;
							lex.textLength = 3;
							current ++;
						}
						break;
					default:
						break;
				}
				break;
			case '/':
				lex.type = LexemeType.Divide;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = LexemeType.DivideAssign;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '%':
				lex.type = LexemeType.Remainder;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = LexemeType.RemainderAssign;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '=':
				lex.type = LexemeType.Assign;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = LexemeType.Equal;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '<':
				lex.type = LexemeType.Lesser;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = LexemeType.LesserOrEqual;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '>':
				lex.type = LexemeType.Greater;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = LexemeType.GreaterOrEqual;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '!':
				lex.type = LexemeType.Not;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = LexemeType.NotEqual;
					lex.textLength = 2;
					current ++;
				}
				break;
			default:
				throw new Exception("Lexer: Invalid operator.");
		}

		lexemes ~= lex;
	}

	void scanWord() {
		Lexeme lex = Lexeme(this);
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
				lex.type = LexemeType.Main;
				break;
            case "def":
				lex.type = LexemeType.Struct;
				break;
			case "if":
				lex.type = LexemeType.If;
				break;
			case "else":
				lex.type = LexemeType.Else;
				break;
			case "while":
				lex.type = LexemeType.While;
				break;
			case "do":
				lex.type = LexemeType.Do;
				break;
			case "for":
				lex.type = LexemeType.For;
				break;
			case "loop":
				lex.type = LexemeType.Loop;
				break;
			case "return":
				lex.type = LexemeType.Return;
				break;
			case "yield":
				lex.type = LexemeType.Yield;
				break;
			case "break":
				lex.type = LexemeType.Break;
				break;
			case "continue":
				lex.type = LexemeType.Continue;
				break;
            case "as":
                lex.type = LexemeType.As;
                break;
            case "is":
                lex.type = LexemeType.Is;
                break;
			case "void":
				lex.type = LexemeType.VoidType;
				lex.isType = true;
				break;
			case "task":
				lex.type = LexemeType.TaskType;
				lex.isType = true;
				break;
			case "func":
				lex.type = LexemeType.FunctionType;
				lex.isType = true;
				break;
			case "int":
				lex.type = LexemeType.IntType;
				lex.isType = true;
				break;
			case "float":
				lex.type = LexemeType.FloatType;
				lex.isType = true;
				break;
			case "bool":
				lex.type = LexemeType.BoolType;
				lex.isType = true;
				break;
			case "string":
				lex.type = LexemeType.StringType;
				lex.isType = true;
				break;
			case "array":
				lex.type = LexemeType.ArrayType;
				lex.isType = true;
				break;
			case "object":
				lex.type = LexemeType.ObjectType;
				lex.isType = true;
				break;
			case "var":
				lex.type = LexemeType.AnyType;
				lex.isType = true;
				break;
            case "let":
                lex.type = LexemeType.AutoType;
                lex.isType = false;
                break;
			case "true":
				lex.type = LexemeType.Boolean;
				lex.isKeyword = false;
				lex.isLiteral = true;
				lex.bvalue = true;
				break;
			case "false":
				lex.type = LexemeType.Boolean;
				lex.isKeyword = false;
				lex.isLiteral = true;
				lex.bvalue = false;
				break;
			case "not":
				lex.type = LexemeType.Not;
				lex.isKeyword = false;
				lex.isOperator = true;
				break;
			case "and":
				lex.type = LexemeType.And;
				lex.isKeyword = false;
				lex.isOperator = true;
				break;
			case "or":
				lex.type = LexemeType.Or;
				lex.isKeyword = false;
				lex.isOperator = true;
				break;
			case "xor":
				lex.type = LexemeType.Xor;
				lex.isKeyword = false;
				lex.isOperator = true;
				break;
			default:
				lex.isKeyword = false;
				lex.type = LexemeType.Identifier;
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

dstring getLexemeTypeStr(LexemeType operator) {
    dstring[] lexemeTypeStrTable = [
        "[", "]", "(", ")", "{", "}",
        ".", ";", ":", ",", "&",
        "=",
        "+=", "-=", "*=", "/=", "~=", "%=", "**=",
        "+", "-",
        "+", "-", "*", "/", "~", "%", "**",
        "==", "!=", ">=", ">", "<=", "<",
        "and", "or", "xor", "not",
        "++", "--",
        "identifier", "const_int", "const_float", "const_bool", "const_str",
        "main", "def",
        "void", "int", "float", "bool", "string", "array", "object", "var", "func", "task", "let",
        "if", "else", "while", "do", "for", "loop", "return", "yield", "break", "continue"
    ];
    return lexemeTypeStrTable[operator];
}