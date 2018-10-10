/**
    Include all the standard library.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.lib;

import grimoire.lib.array;
import grimoire.lib.core;
import grimoire.lib.ffi;
import grimoire.lib.io;
import grimoire.lib.math;
import grimoire.lib.string;
import grimoire.lib.type;

private bool _isStdLibLoaded;

///Load the standard grimoire library
void grLib_std_load() {
    if(_isStdLibLoaded)
        return;
    _isStdLibLoaded = true;

	grLib_std_core_load();
	grLib_std_type_load();
	grLib_std_io_load();
	grLib_std_math_load();
	grLib_std_ffi_load();
	grLib_std_string_load();
	grLib_std_array_load();
}