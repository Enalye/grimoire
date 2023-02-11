# std.queue

A queue is a collection that can be manipulated on both ends.
## Natifs
### Queue\<T>
A queue is a collection that can be manipulated on both ends.
### QueueIterator\<T>
Iterate on a queue.
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
|[push](#func_4)|*queue*: **Queue\<T>**, *value*: **T**||


***
## Description des fonctions

<a id="func_0"></a>
> back (*queue*: **pure Queue\<T>**) (**T?**)

Returns the last element of `queue`.
If it doesn't exist, returns `null<T>`.

<a id="func_1"></a>
> front (*queue*: **pure Queue\<T>**) (**T?**)

Returns the first element of `queue`.
If it doesn't exist, returns `null<T>`.

<a id="func_2"></a>
> isEmpty (*queue*: **pure Queue\<T>**) (**bool**)

Returns `true` if `queue` contains nothing.

<a id="func_3"></a>
> pop (*queue*: **Queue\<T>**) (**T?**)

Removes the last element of `queue` and returns it.
If it doesn't exist, returns `null<T>`.

<a id="func_4"></a>
> push (*queue*: **Queue\<T>**, *value*: **T**)

Appends `value` to the back of `queue`.

