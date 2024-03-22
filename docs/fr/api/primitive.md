# Primitive

Les primitives ajoutées dans `GrModuleDef` se présentent sous la forme `void function(GrCall)`.

```grimoire
void maPrimitive(GrCall call) {

}
```

## Paramètres d’entrée

Une primitive récupère ses paramètres avec les fonctions `get` de `GrCall`, l’index correspond à l’ordre des paramètres.

```grimoire
void maPrimitive(GrCall call) {
    call.getInt(0) + call.getInt(1);
}
```

## Paramètres de sortie

Comme les fonctions `get`, on retourne des valeurs avec les fonctions `set` de `GrCall`.
Ces derniers sont à appeler dans l’ordre des paramètres de sortie.

```grimoire
void maPrimitive(GrCall call) {
    call.setInt(12);
}
```

## Types des paramètres

Il est possible de connaître dynamiquement le type des paramètres grâce à `getInType` et `getOutType`.
Ces paramètres sont sous la forme décoré (utilisez `grUnmangle` pour obtenir un `GrType`).

```grimoire
void maPrimitive(GrCall call) {
    call.getInType(0);
    call.getOutType(0);
}
```

## Gestion d’erreur

En cas d’erreur, on appelle `raise`. Il est recommandé de quitter la primitive et de ne plus faire d’opération après `raise`.

```grimoire
void maPrimitive(GrCall call) {
    if(call.isNull(0)) {
        call.raise("Erreur");
        return;
    }
}
```