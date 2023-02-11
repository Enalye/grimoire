# std.queue

Une queue est une collection pouvant être manipulé par les deux bouts.
## Natifs
### Queue\<T>
Une queue est une collection pouvant être manipulé par les deux bouts.
### QueueIterator\<T>
Itère sur une queue.
## Constructeurs
|Fonction|Entrée|
|-|-|
|[@**Queue\<T>**](#ctor_0)||
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[back](#func_0)|*queue*: **pure Queue\<T>**|**T?**|
|[front](#func_1)|*queue*: **pure Queue\<T>**|**T?**|
|[isEmpty](#func_2)|*queue*: **pure Queue\<T>**|**bool**|
|[pop](#func_3)|*queue*: **Queue\<T>**|**T?**|
|[push](#func_4)|*queue*: **Queue\<T>**, *valeur*: **T**||


***
## Description des fonctions

<a id="func_0"></a>
> back (*queue*: **pure Queue\<T>**) (**T?**)

Returne le dernier élément de `queue`.
S’il n’existe pas, retourne `null<T>`.

<a id="func_1"></a>
> front (*queue*: **pure Queue\<T>**) (**T?**)

Retourne le premier élément de `queue`.
S’il n’existe pas, retourne `null<T>`.

<a id="func_2"></a>
> isEmpty (*queue*: **pure Queue\<T>**) (**bool**)

Renvoie `true` si la `queue` ne contient rien.

<a id="func_3"></a>
> pop (*queue*: **Queue\<T>**) (**T?**)

Retire le dernier élément de `queue` et le retourne.
S’il n’existe pas, retourne `null<T>`.

<a id="func_4"></a>
> push (*queue*: **Queue\<T>**, *valeur*: **T**)

Ajoute `valeur` en fin de `queue`.

