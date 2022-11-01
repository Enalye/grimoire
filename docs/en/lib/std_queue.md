# std.queue

A queue is a collection that can be manipulated on both ends.
## Natifs
### Queue\<T>
A queue is a collection that can be manipulated on both ends.
### QueueIterator\<T>
Iterate on a queue.
## Constructeurs
|Constructeur|Entrée|
|-|-|
|**Queue\<T>**||
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[back](#func_0)|**pure Queue\<T>** *queue*|**T?**|
|[front](#func_1)|**pure Queue\<T>** *queue*|**T?**|
|[isEmpty](#func_2)|**pure Queue\<T>** *queue*|**bool**|
|[pop](#func_3)|**Queue\<T>** *queue*|**T?**|
|[push](#func_4)|**Queue\<T>** *queue*, **T** *value*||


***
## Description des fonctions

<a id="func_0"></a>
> back (**pure Queue\<T>** *queue*) (**T?**)

Returns the last element of `queue`.
If it doesn't exist, returns `null(T)`.

<a id="func_1"></a>
> front (**pure Queue\<T>** *queue*) (**T?**)

Returns the first element of `queue`.
If it doesn't exist, returns `null(T)`.

<a id="func_2"></a>
> isEmpty (**pure Queue\<T>** *queue*) (**bool**)

Returns `true` if `queue` contains nothing.

<a id="func_3"></a>
> pop (**Queue\<T>** *queue*) (**T?**)

Removes the last element of `queue` and returns it.
If it doesn't exist, returns `null(T)`.

<a id="func_4"></a>
> push (**Queue\<T>** *queue*, **T** *value*)

Appends `value` to the back of `queue`.

