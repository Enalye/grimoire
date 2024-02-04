# channel

Built-in type.
## Description
A channel is a messaging and synchronization tool between tasks.
## Functions
|Function|Input|Output|
|-|-|-|
|[capacity](#func_0)|*chan*: **pure channel\<T>**|**int**|
|[isEmpty](#func_1)|*chan*: **pure channel\<T>**|**bool**|
|[isFull](#func_2)|*chan*: **pure channel\<T>**|**bool**|
|[size](#func_3)|*chan*: **pure channel\<T>**|**int**|


***
## Function descriptions

<a id="func_0"></a>
> capacity(*chan*: **pure channel\<T>**) (**int**)

Returns the channel's capacity.

<a id="func_1"></a>
> isEmpty(*chan*: **pure channel\<T>**) (**bool**)

Returns `true` if the channel contains nothing.

<a id="func_2"></a>
> isFull(*chan*: **pure channel\<T>**) (**bool**)

Returns `true` if the channel has reached its maximum capacity.

<a id="func_3"></a>
> size(*chan*: **pure channel\<T>**) (**int**)

Returns the channel's size.

