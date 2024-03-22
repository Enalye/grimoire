# queue

Une queue est une collection pouvant être manipulé par les deux bouts.
## Natifs
### Queue\<T>
Une queue est une collection pouvant être manipulé par les deux bouts.
### QueueIterator\<T>
Itère sur les éléments d’une queue.
## Constructeurs
|Fonction|Entrée|Description|
|-|-|-|
|[@**Queue\<T>**](#ctor_0)||Itère sur les éléments d’une queue.|
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[back](#func_0)|*queue*: **pure Queue\<T>**|**T?**|
|[front](#func_1)|*queue*: **pure Queue\<T>**|**T?**|
|[isEmpty](#func_2)|*queue*: **pure Queue\<T>**|**bool**|
|[popBack](#func_3)|*queue*: **Queue\<T>**|**T?**|
|[pushBack](#func_4)|*queue*: **Queue\<T>**, *value*: **T**||


***
## Description des fonctions

<a id="func_0"></a>
> back(*queue*: **pure Queue\<T>**) (**T?**)

Returne le dernier élément de la queue.

Si la queue est vide, retourne `null<T>`.

<a id="func_1"></a>
> front(*queue*: **pure Queue\<T>**) (**T?**)

Retourne le premier élément de la queue.

Si la queue est vide, retourne `null<T>`.

<a id="func_2"></a>
> isEmpty(*queue*: **pure Queue\<T>**) (**bool**)

Renvoie `true` si la queue est vide.

<a id="func_3"></a>
> popBack(*queue*: **Queue\<T>**) (**T?**)

Retire le dernier élément de la queue et le retourne.

Si la queue est vide, retourne `null<T>`.

<a id="func_4"></a>
> pushBack(*queue*: **Queue\<T>**, *value*: **T**)

Ajoute `value` à la fin de la queue.

