# std.channel

Built-in type.
## Description
A channel is a messaging and synchronization tool between tasks.
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[capacity](#func_0)|**pure channel\<T>** *chan*|**int**|
|[isEmpty](#func_1)|**pure channel\<T>** *chan*|**bool**|
|[isFull](#func_2)|**pure channel\<T>** *chan*|**bool**|
|[size](#func_3)|**pure channel\<T>** *chan*|**int**|


***
## Description des fonctions

<a id="func_0"></a>
> capacity (**pure channel\<T>** *chan*) (**int**)

Returns the channel's capacity.

<a id="func_1"></a>
> isEmpty (**pure channel\<T>** *chan*) (**bool**)

Returns `true` if the channel contains nothing.

<a id="func_2"></a>
> isFull (**pure channel\<T>** *chan*) (**bool**)

Returns `true` if the channel has reached its maximum capacity.

<a id="func_3"></a>
> size (**pure channel\<T>** *chan*) (**int**)

Returns the channel's size.

