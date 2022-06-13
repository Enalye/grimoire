# time
___
## Description

Time related functions.

## Functions

|Function|Input|Output|
|-|-|-|
|[hours](#hours_i)|int duration|int|
|[hours](#hours_r)|real duration|int|
|[minutes](#minutes_i)|int duration|int|
|[minutes](#minutes_r)|real duration|int|
|[seconds](#seconds_i)|int duration|int|
|[seconds](#seconds_r)|real duration|int|
|[sleep](#sleep)|int duration||
|[time](#time)||int|
|[wait](#wait)|int steps||

## Function Descriptions

<a id="hours_i"></a>
- hours ( int duration ) ( int )

Convert the `duration` in hours to milliseconds.
___

<a id="hours_r"></a>
- hours ( real duration ) ( int )

Convert the `duration` in hours to milliseconds.
___

<a id="minutes_i"></a>
- minutes ( int duration ) ( int )

Convert the `duration` in minutes to milliseconds.
___

<a id="minutes_r"></a>
- minutes ( real duration ) ( int )

Convert the `duration` in minutes to milliseconds.
___

<a id="seconds_i"></a>
- seconds ( int duration ) ( int )

Convert the `duration` in seconds to milliseconds.
___

<a id="seconds_r"></a>
- seconds ( real duration ) ( int )

Convert the `duration` in seconds to milliseconds.
___

<a id="sleep"></a>
- sleep ( int duration ) ( )

Block the task for `duration` milliseconds.
___

<a id="time"></a>
- time ( ) ( int )

Returns the elapsed time since January 1st, 1 A.D. in milliseconds.
___

<a id="wait"></a>
- wait ( int steps ) ( )

Block the task `steps` times.
It is equivalent to the code:
```gr
loop(steps) yield
```
___