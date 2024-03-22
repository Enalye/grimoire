/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
version (GrimoireCli)  :  //

import std.stdio : writeln;
import grimoire.cli;

void main(string[] args) {
    version (Windows) {
        import core.sys.windows.windows : DWORD, HANDLE, SetConsoleOutputCP, GetStdHandle, GetConsoleMode,
            SetConsoleMode, STD_OUTPUT_HANDLE, ENABLE_VIRTUAL_TERMINAL_PROCESSING;

        SetConsoleOutputCP(65_001);
        DWORD mode = 0;
        HANDLE handle = GetStdHandle(STD_OUTPUT_HANDLE);
        GetConsoleMode(handle, &mode);
        SetConsoleMode(handle, mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING);
    }
    try {
        parseArgs(args);
    }
    catch (Exception e) {
        writeln(e.msg);
    }
}
