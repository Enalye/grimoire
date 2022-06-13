# Code différé

Un bloc de code mis à l’intérieur d’un `defer` est *garantit* de s’exécuter à la fin d’une fonction ou tâche, et ce même si une erreur est survenu avant la fin.

```grimoire
event onLoad() {
	defer { print("Dans le defer !"); }
	print("Avant le defer");
	throw "Erreur";
}
```
Dans cet exemple, « Avant le defer » s’affichera puis « Dans le defer ! », même si on lance une erreur avant la fin de la fonction.
Cette instruction est utile pour garantir la libération des ressources.