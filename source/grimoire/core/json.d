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

module grimoire.core.json;

public import std.json;
import std.conv;

bool hasJson(JSONValue json, string tag) {
	return ((tag in json.object) !is null);
}

JSONValue getJson(JSONValue json, string tag) {
	if((tag in json.object) is null)
		throw new Exception("JSON: \'" ~ tag ~ "\'' does not exist in JSON.");
	return json.object[tag];
}

JSONValue[] getJsonArray(JSONValue json, string tag) {
	if((tag in json.object) is null)
		throw new Exception("JSON: \'" ~ tag ~ "\'' does not exist in JSON.");
	return json.object[tag].array;
}

string[] getJsonArrayStr(JSONValue json, string tag) {
	if((tag in json.object) is null)
		throw new Exception("JSON: \'" ~ tag ~ "\'' does not exist in JSON.");
	string[] array;
	foreach(JSONValue value; json.object[tag].array)
		array ~= value.str;
	return array;
}

string[] getJsonArrayStr(JSONValue json, string tag, string[] defValue) {
	if((tag in json.object) is null)
		return defValue;
	string[] array;
	foreach(JSONValue value; json.object[tag].array)
		array ~= value.str;
	return array;
}

int[] getJsonArrayInt(JSONValue json, string tag) {
	if((tag in json.object) is null)
		throw new Exception("JSON: \'" ~ tag ~ "\'' does not exist in JSON.");
	int[] array;
	foreach(JSONValue value; json.object[tag].array) {
		if(value.type() == JSONType.integer)
			array ~= cast(int)value.integer;
		else
			array ~= to!int(value.str);
	}
	return array;
}

int[] getJsonArrayInt(JSONValue json, string tag, int[] defValue) {
	if((tag in json.object) is null)
		return defValue;
	int[] array;
	foreach(JSONValue value; json.object[tag].array) {
		if(value.type() == JSONType.integer)
			array ~= cast(int)value.integer;
		else
			array ~= to!int(value.str);
	}
	return array;
}

float[] getJsonArrayFloat(JSONValue json, string tag) {
	if((tag in json.object) is null)
		throw new Exception("JSON: \'" ~ tag ~ "\'' does not exist in JSON.");
	float[] array;
	foreach(JSONValue value; json.object[tag].array) {
		if(value.type() == JSONType.float_)
			array ~= value.floating;
		else
			array ~= to!float(value.str);
	}
	return array;
}

float[] getJsonArrayFloat(JSONValue json, string tag, float[] defValue) {
	if((tag in json.object) is null)
		return defValue;
	float[] array;
	foreach(JSONValue value; json.object[tag].array) {
		if(value.type() == JSONType.float_)
			array ~= value.floating;
		else
			array ~= to!float(value.str);
	}
	return array;
}

string getJsonStr(JSONValue json, string tag) {
	if((tag in json.object) is null)
		throw new Exception("JSON: \'" ~ tag ~ "\'' does not exist in JSON.");
	return json.object[tag].str;
}

string getJsonStr(JSONValue json, string tag, string defValue) {
	if((tag in json.object) is null)
		return defValue;
	return json.object[tag].str;
}

int getJsonInt(JSONValue json, string tag) {
	if((tag in json.object) is null)
		throw new Exception("JSON: \'" ~ tag ~ "\'' does not exist in JSON.");
	JSONValue value = json.object[tag];
	switch(value.type()) with(JSONType) {
	case integer:
		return cast(int)value.integer;
	case uinteger:
		return cast(int)value.uinteger;
	case float_:
		return cast(int)value.floating;
	case string:
		return to!int(value.str);
	default:
		throw new Exception("JSON: No integer value in \'" ~ tag ~ "\'.");
	}
}

int getJsonInt(JSONValue json, string tag, int defValue) {
	if((tag in json.object) is null)
		return defValue;
	JSONValue value = json.object[tag];

	switch(value.type()) with(JSONType) {
	case integer:
		return cast(int)value.integer;
	case uinteger:
		return cast(int)value.uinteger;
	case float_:
		return cast(int)value.floating;
	case string:
		return to!int(value.str);
	default:
		throw new Exception("JSON: No integer value in \'" ~ tag ~ "\'.");
	}
}

float getJsonFloat(JSONValue json, string tag) {
	if((tag in json.object) is null)
		throw new Exception("JSON: \'" ~ tag ~ "\'' does not exist in JSON.");
	JSONValue value = json.object[tag];
	switch(value.type()) with(JSONType) {
	case integer:
		return cast(float)value.integer;
	case uinteger:
		return cast(float)value.uinteger;
	case float_:
		return value.floating;
	case string:
		return to!float(value.str);
	default:
		throw new Exception("JSON: No floating value in \'" ~ tag ~ "\'.");
	}
}

float getJsonFloat(JSONValue json, string tag, float defValue) {
	if((tag in json.object) is null)
		return defValue;
	JSONValue value = json.object[tag];
	switch(value.type()) with(JSONType) {
	case integer:
		return cast(float)value.integer;
	case uinteger:
		return cast(float)value.uinteger;
	case float_:
		return value.floating;
	case string:
		return to!float(value.str);
	default:
		throw new Exception("JSON: No floating value in \'" ~ tag ~ "\'.");
	}
}

bool getJsonBool(JSONValue json, string tag) {
	if((tag in json.object) is null)
		throw new Exception("JSON: \'" ~ tag ~ "\'' does not exist in JSON.");
	JSONValue value = json.object[tag];
	if(value.type() == JSONType.true_)
		return true;
	else if(value.type() == JSONType.false_)
		return false;
	else
		throw new Exception("JSON: \'" ~ tag ~ "\' is not a boolean value.");
}

bool getJsonBool(JSONValue json, string tag, bool defValue) {
	if((tag in json.object) is null)
		return defValue;
	JSONValue value = json.object[tag];
	if(value.type() == JSONType.true_)
		return true;
	else if(value.type() == JSONType.false_)
		return false;
	else
		throw new Exception("JSON: \'" ~ tag ~ "\' is not a boolean value.");
}