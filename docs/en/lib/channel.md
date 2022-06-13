# channel

Built-in type.

## Description

A channel is a way of communication and synchronization between tasks.

## Functions

|Function|Input|Output|
|-|-|-|
|[size](#size)|[channel](#channel)(T) this|int|
|[capacity](#capacity)|[channel](#channel)(T) this|int|
|[empty?](#empty)|[channel](#channel)(T) this|bool|
|[full?](#full)|[channel](#channel)(T) this|bool|

## Function Descriptions

<a id="size"></a>
- size ( [channel](#channel)(T) this ) ( int )

Returns the current size of the channel.
___

<a id="capacity"></a>
- capacity ( [channel](#channel)(T) this ) ( int )

Returns the maximum capacity of the channel.
___

<a id="empty"></a>
- empty? ( [channel](#channel)(T) this ) ( bool )

Returns `true` when the channel holds no value.
___

<a id="full"></a>
- full? ( [channel](#channel)(T) this ) ( bool )

Returns `true` when the channel has reach its maximum capacity.
___