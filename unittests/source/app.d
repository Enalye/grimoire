/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
import std.stdio: writeln, write;
import std.datetime;
import std.conv: to;

import grimoire;

import tester;

void main() {
	try {
        testAll(GrLocale.fr_FR);
    }
	catch(Exception e) {
		writeln(e.msg);
	}
}
