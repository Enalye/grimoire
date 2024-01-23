/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.runtime.error;

import std.exception;

import grimoire.error;

/// Décrit une erreur survenue lors de l’exécution
class GrRuntimeException : GrException {
    mixin basicExceptionCtors;
}
