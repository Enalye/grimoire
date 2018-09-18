/**
    Include all the standard library.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module lib.all;

import lib.array.all;
import lib.ffi.all;
import lib.io.all;
import lib.math.all;
import lib.string.all;
import lib.type.all;

private bool _isStdLibLoaded;

///Load the standard grimoire library
void grLib_std_load() {
    if(_isStdLibLoaded)
        return;
    _isStdLibLoaded = true;

	grLib_std_array_load();
	grLib_std_ffi_load();
	grLib_std_io_load();
	grLib_std_math_load();
	grLib_std_string_load();
	grLib_std_type_load();
}