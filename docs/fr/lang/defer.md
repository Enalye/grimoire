# Defer

`defer` assure l’exécution d’un bloc de code à la fin de la fonction actuelle, même en cas d’exception.
```grimoire
event onLoad() {
	defer { print("Dans le defer !"); }
	print("Avant le defer");
	throw "Erreur";
}
```