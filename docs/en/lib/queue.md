# queue

A queue is a collection that can be manipulated on both ends.
## Natives
### Queue\<T>
A queue is a collection that can be manipulated on both ends.
### QueueIterator\<T>
Iterate on the elements of a queue.
## Constructors
|Function|Input|Description|
|-|-|-|
|[@**Queue\<T>**](#ctor_0)||Iterate on the elements of a queue.|
## Functions
|Function|Input|Output|
|-|-|-|
|[back](#func_0)|*queue*: **pure Queue\<T>**|**T?**|
|[front](#func_1)|*queue*: **pure Queue\<T>**|**T?**|
|[isEmpty](#func_2)|*queue*: **pure Queue\<T>**|**bool**|
|[popBack](#func_3)|*queue*: **Queue\<T>**|**T?**|
|[pushBack](#func_4)|*queue*: **Queue\<T>**, *value*: **T**||


***
## Function descriptions

<a id="func_0"></a>
> back(*queue*: **pure Queue\<T>**) (**T?**)

Returns the last element of the queue.

If the queue is empty, returns `null<T>`.

<a id="func_1"></a>
> front(*queue*: **pure Queue\<T>**) (**T?**)

Returns the first element of the queue.

If the queue is empty, returns `null<T>`.

<a id="func_2"></a>
> isEmpty(*queue*: **pure Queue\<T>**) (**bool**)

Returns `true` if the queue is empty.

<a id="func_3"></a>
> popBack(*queue*: **Queue\<T>**) (**T?**)

Removes the last element of the queue and returns it.

If the queue is empty, returns `null<T>`.

<a id="func_4"></a>
> pushBack(*queue*: **Queue\<T>**, *value*: **T**)

Appends `value` to the back of the queue.

