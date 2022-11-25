# std.channel

Type de base.
## Description
Un canal est un moyen de communication et de synchronisation entre tâches.
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[capacity](#func_0)|*canal*: **pure channel\<T>**|**int**|
|[isEmpty](#func_1)|*canal*: **pure channel\<T>**|**bool**|
|[isFull](#func_2)|*canal*: **pure channel\<T>**|**bool**|
|[size](#func_3)|*canal*: **pure channel\<T>**|**int**|


***
## Description des fonctions

<a id="func_0"></a>
> capacity (*canal*: **pure channel\<T>**) (**int**)

Retourne la capacité maximale du canal.

<a id="func_1"></a>
> isEmpty (*canal*: **pure channel\<T>**) (**bool**)

Renvoie `true` si le canal ne contient rien.

<a id="func_2"></a>
> isFull (*canal*: **pure channel\<T>**) (**bool**)

Renvoie `true` si le canal a atteint sa capacité maximale.

<a id="func_3"></a>
> size (*canal*: **pure channel\<T>**) (**int**)

Retourne la taille actuelle du canal.

