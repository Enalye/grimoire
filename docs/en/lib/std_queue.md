# std.queue

A queue is a collection that can be manipulated on both ends.
## Natives
### Queue\<T>
A queue is a collection that can be manipulated on both ends.
### QueueIterator\<T>
Iterate on the elements of a queue.
## Constructors
|Function|Input|
|-|-|
|[@**Queue\<T>**](#ctor_0)||
## Functions
|Function|Input|Output|
|-|-|-|
|[back](#func_0)|*self*: **pure Queue\<T>**|**T?**|
|[front](#func_1)|*self*: **pure Queue\<T>**|**T?**|
|[isEmpty](#func_2)|*self*: **pure Queue\<T>**|**bool**|
|[popBack](#func_3)|*self*: **Queue\<T>**|**T?**|
|[pushBack](#func_4)|*self*: **Queue\<T>**, *value*: **T**||


***
## Function descriptions

<a id="func_0"></a>
> back (*self*: **pure Queue\<T>**) (**T?**)

Returns the last element of the queue.

If the queue is empty, returns `null<T>`.

<a id="func_1"></a>
> front (*self*: **pure Queue\<T>**) (**T?**)

Returns the first element of the queue.

If the queue is empty, returns `null<T>`.

<a id="func_2"></a>
> isEmpty (*self*: **pure Queue\<T>**) (**bool**)

Returns `true` if the queue is empty.

<a id="func_3"></a>
> popBack (*self*: **Queue\<T>**) (**T?**)

Removes the last element of the queue and returns it.

If the queue is empty, returns `null<T>`.

<a id="func_4"></a>
> pushBack (*self*: **Queue\<T>**, *value*: **T**)

Appends `value` to the back of the queue.

