/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.error;

import std.exception;

/// Décrit une erreur de grimoire
class GrException : Exception {
    mixin basicExceptionCtors;
}
