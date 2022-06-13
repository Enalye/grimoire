# Le langage Grimoire

Grimoire est un langage intégré pour des applications en D.

Le langage dispose d’un typage statique, d’un système concurrentiel et d’une interface de programmation facile d’utilisation permettant l’utilisation de types, fonctions et variables directement depuis D.

Pour la compilation d’un script en Grimoire et son exécution il suffit d’un code minimal comme suit:
```d
import std.stdio: writeln;

// Certaines fonctions et types basiques sont fourni par la bibliothèque par défaut.
GrLibrary stdlib = grLoadStdLibrary(); 

GrCompiler compiler = new GrCompiler;

// On ajoute la bibliothèque par défaut.
compiler.addLibrary(stdlib);

// On compile le fichier.
GrBytecode bytecode = compiler.compileFile("script.gr");

if(bytecode) {
    // Compilation réussie, on crée la machine virtuelle
	GrEngine engine = new GrEngine;

	// Ajout de la bibliothèque par défaut à la machine virtuelle
	engine.addLibrary(stdlib);

	// Chargement du bytecode généré
	engine.load(bytecode);

	// On appel un événement `onLoad`
	if(engine.hasEvent("onLoad"))
		engine.callEvent("onLoad");

	// La machine virtuelle va tourner jusqu’à ce que toutes les tâches aient fini
	while(engine.hasTasks)
    	engine.process();

	// Déclenché si une erreur irrécupérable est survenue
	if(engine.isPanicking)
    	writeln("unhandled error: " ~ engine.panicMessage);
}
else {
    // Si on a une erreur de compilation
    writeln(compiler.getError().prettify());
}
```