# channel

Type de base.

## Description

Un canal est un moyen de communication et de synchronisation entre tâches.

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[size](#size)|[channel](#channel)(T) this|int|
|[capacity](#capacity)|[channel](#channel)(T) this|int|
|[empty?](#empty)|[channel](#channel)(T) this|bool|
|[full?](#full)|[channel](#channel)(T) this|bool|

## Description des fonctions

<a id="size"></a>
- size ( [channel](#channel)(T) this ) ( int )

Retourne la taille actuelle du canal.
___

<a id="capacity"></a>
- capacity ( [channel](#channel)(T) this ) ( int )

Retourne la capacité maximal du canal.
___

<a id="empty"></a>
- empty? ( [channel](#channel)(T) this ) ( bool )

Returne `true` si le canal ne contient rien.
___

<a id="full"></a>
- full? ( [channel](#channel)(T) this ) ( bool )

Returne `true` si le canal a atteint sa capacité maximale.
___