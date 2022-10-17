# Erreurs

Grimoire permet la gestion d’erreurs.
```grimoire
throw "Erreur";
```

Les blocs `try`/`catch` permettent la capture d’erreurs.
```grimoire
try {
    throw "Erreur";
}
catch(e) {
    print("J’ai attrapé: " ~ e);
}
```
Une erreur non capturée mettra en panique la machine virtuelle et interrompera les autres tâches.