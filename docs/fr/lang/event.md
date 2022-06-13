# Événements

Les événements sont comme des tâches qui sont appelées depuis D.

Ils se déclarent comme des tâches et sont automatiquement public:
```grimoire
event foo(string msg) {
	print(msg);
}
```

Pour l’appeler depuis D:
```d
auto mangledName = grMangleComposite("foo", [grString]);
if(vm.hasEvent(mangledName)) {
    GrTask task = vm.callEvent(mangledName);
	task.setString("Hello World!");
}
```
Ici, le processus est un peu spécial.
D’abord, on doit connaître le nom formatté (nom + signature) de l’évenement avec `grMangleComposite`.
Puis on l’appelle.
Si l’évenement a des paramètres, on doit ***absolument*** ajouter des valeurs au nouveau contexte, sinon la machine virtuelle plantera.