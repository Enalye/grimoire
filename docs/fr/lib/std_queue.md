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
|[back](#func_0)|**pure Queue\<T>** *queue*|**T?**|
|[front](#func_1)|**pure Queue\<T>** *queue*|**T?**|
|[isEmpty](#func_2)|**pure Queue\<T>** *queue*|**bool**|
|[pop](#func_3)|**Queue\<T>** *queue*|**T?**|
|[push](#func_4)|**Queue\<T>** *queue*, **T** *valeur*||


***
## Description des fonctions

<a id="func_0"></a>
> back (**pure Queue\<T>** *queue*) (**T?**)

Returne le dernier élément de `queue`.
S’il n’existe pas, retourne `null(T)`.

<a id="func_1"></a>
> front (**pure Queue\<T>** *queue*) (**T?**)

Retourne le premier élément de `queue`.
S’il n’existe pas, retourne `null(T)`.

<a id="func_2"></a>
> isEmpty (**pure Queue\<T>** *queue*) (**bool**)

Renvoie `true` si la `queue` ne contient rien.

<a id="func_3"></a>
> pop (**Queue\<T>** *queue*) (**T?**)

Retire le dernier élément de `queue` et le retourne.
S’il n’existe pas, retourne `null(T)`.

<a id="func_4"></a>
> push (**Queue\<T>** *queue*, **T** *valeur*)

Ajoute `valeur` en fin de `queue`.

