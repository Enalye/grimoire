# Gestion d’erreur

La gestion d’erreur se fait par l’envoi et la réception d’erreurs.

Pour lancer une erreur, on notera:
```grimoire
throw "Erreur";
```
Si l’on ne fait rien, la machine virtuelle paniquera car l’erreur se propagera sans jamais être attrapée.

On entoure donc l’erreur d’un bloc `try` suivi d’un `catch` optionnel pour gérer l’erreur:
```grimoire
event onLoad() {
	try {
		throw "Erreur";
	}
	catch(e) {
		print("J’ai attrapé: " ~ e);
	}
}
```
Et l’exécution de la tâche peut se poursuivre normalement.