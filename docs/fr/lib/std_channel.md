# channel

Type de base.

## Description

Un canal est un moyen de communication et de synchronisation entre tâches.

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[size](#size)|**pure channel(T)** *canal*|**int**|
|[capacity](#capacity)|**pure channel(T)** *canal*|**int**|
|[isEmpty](#isEmpty)|**pure channel(T)** *canal*|**bool**|
|[isFull](#isFull)|**pure channel(T)** *canal*|**bool**|

---

## Description des fonctions

<a id="size"></a>
- size (**pure channel(T)** *canal*) (**int**)

Retourne la taille actuelle du canal.
___

<a id="capacity"></a>
- capacity (**pure channel(T)** *canal*) (**int**)

Retourne la capacité maximal du canal.
___

<a id="isEmpty"></a>
- isEmpty (**pure channel(T)** *canal*) (**bool**)

Renvoie `true` si le canal ne contient rien.
___

<a id="isFull"></a>
- isFull (**pure channel(T)** *canal*) (**bool**)

Renvoie `true` si le canal a atteint sa capacité maximale.
___