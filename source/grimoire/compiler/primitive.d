/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.compiler.primitive;

import std.exception;
import std.conv;
import std.stdio;

import grimoire.runtime;
import grimoire.compiler.parser;
import grimoire.compiler.type;
import grimoire.compiler.constraint;
import grimoire.compiler.mangle;
import grimoire.compiler.data;

/// Fonction en D appelable en grimoire
class GrPrimitive {
    /// L’id de la fonction à rappeler
    int callbackId;
    /// Paramètres de la fonction
    GrType[] inSignature;
    /// Les types de retour
    GrType[] outSignature;
    /// Le nom de base de la fonction
    string name;
    /// Le nom décoré de la fonction
    string mangledName;
    /// L’id de la fonction
    uint index;
    /// Pour les convertions: est-ce qu’elle peut être appelé sans `as` ?
    bool isExplicit;
    /// Si un des paramètres est générique, la primitive devient abstraite
    bool isAbstract;
    /// Contraintes de fonction
    GrConstraint[] constraints;

    this() {
    }

    this(const GrPrimitive primitive) {
        callbackId = primitive.callbackId;
        inSignature = primitive.inSignature.dup;
        outSignature = primitive.outSignature.dup;
        name = primitive.name;
        mangledName = primitive.mangledName;
        index = primitive.index;
        isExplicit = primitive.isExplicit;
        isAbstract = primitive.isAbstract;
        foreach (const ref GrConstraint constraint; primitive.constraints) {
            constraints ~= GrConstraint(constraint);
        }
    }
}
