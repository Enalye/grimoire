# std.channel

Type de base.
## Description
Un canal est un moyen de communication et de synchronisation entre tâches.
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[capacity](#func_0)|**pure channel(T)** *canal*|**int**|
|[isEmpty](#func_1)|**pure channel(T)** *canal*|**bool**|
|[isFull](#func_2)|**pure channel(T)** *canal*|**bool**|
|[size](#func_3)|**pure channel(T)** *canal*|**int**|


***
## Description des fonctions

<a id="func_0"></a>
> capacity (**pure channel(T)** *canal*) (**int**)

Retourne la capacité maximale du canal.

<a id="func_1"></a>
> isEmpty (**pure channel(T)** *canal*) (**bool**)

Renvoie `true` si le canal ne contient rien.

<a id="func_2"></a>
> isFull (**pure channel(T)** *canal*) (**bool**)

Renvoie `true` si le canal a atteint sa capacité maximale.

<a id="func_3"></a>
> size (**pure channel(T)** *canal*) (**int**)

Retourne la taille actuelle du canal.

