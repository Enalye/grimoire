# Operateurs

Tout comme les conversions, on peut définir nos propre opérateurs en appelant la fonction `operator` suivi de l’opérateur à surcharger.
Suivant si on surcharge un opérateur unaire ou binaire, le nombre de paramètres doit correspondre (1 ou 2).

```grimoire
event main() {
    print(3.5 + 2);
}

func operator"+"(a: float, b: int) (float) {
    return a + b as<float>;
}
```

La liste des opérateurs surchargeables est la suivante:

| Operator | Symbol | Note |
| --- | --- | --- |
| `+` | Plus | Opérateur unaire préfixé |
| `-` | Moins | Opérateur unaire préfixé |
| `+` | Addition | Opérateur binaire |
| `-` | Soustraction | Opérateur binaire |
| `*` | Multiplication | Opérateur binaire |
| `/` | Division | Opérateur binaire |
| `~` | Concaténation | Opérateur binaire |
| `%` | Reste | Opérateur binaire |
| `**` | Puissance | Opérateur binaire |
| `==` | Égalité | Opérateur binaire |
| `===` | Double Égalité | Opérateur binaire |
| `<=>` | Comparaison Triple | Opérateur binaire |
| `!=` | Pas Égal | Opérateur binaire |
| `>=` | Plus Grand ou Égal | Opérateur binaire |
| `>` | Plus Grand | Opérateur binaire |
| `<=` | Plus Petit ou Égal | Opérateur binaire |
| `<` | Plus Petit | Opérateur binaire |
| `<<` | Décalage à Gauche | Opérateur binaire |
| `>>` | Décalage à Droite | Opérateur binaire |
| `->` | Intervalle | Opérateur binaire |
| `=>` | Flèche | Opérateur binaire |
| `<-` | Réception | Opérateur unaire préfixé |
| `<-` | Envoi | Opérateur binaire |
| `&`, `bit_and` | Et Binaire | Opérateur binaire |
| `\|`, `bit_or` | Ou Binaire | Opérateur binaire |
| `^`, `bit_xor` | Ou Binaire Exclusif | Opérateur binaire |
| `~`, `bit_not` | Non Binaire | Opérateur unaire préfixé |
| `&&`, `and` | Et Logique | Opérateur binaire |
| `\|\|`, `or` | Ou Logique | Opérateur binaire |
| `!`, `not` | Non Logique | Opérateur unaire préfixé |