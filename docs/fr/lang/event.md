# Événement

Contrairement à la plupart des langages, Grimoire ne dispose pas de `main`, mais des événements appelés `event`.

Les événements sont les points d’entrée d’un programme écrit en Grimoire.
```grimoire
event main(arg: string) {
	print(arg);
}
```
Un événement ne peut être appelé que depuis le programme hôte.

```d
GrTask task = vm.callEvent("main", [grString], [GrValue("Bonjour !")]);
```