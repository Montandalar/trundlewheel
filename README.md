# Configurable trundle wheel mod for Minetest

## Introduction - What's a trundle wheel and why would I want one?

A trundle wheel is a useful tool in real life for measuring distances by
measuring how many rotations a circle has gone through wheel being pushed
(trundling) along the ground. It is particularly good for measuring curves
rather than straight lines because you can turn it.

In Minetest, you may also want to measure the distance as you travel along a
complex path. For example, as you walk between two places or along a curving
road. The trundle wheel will let you do this easily while recording your
distance travelled.

If you want to measure the distance between fixed, well-specified points, you
will want to use the `distancer` CSM instead.

## Using the trundle wheel

The trundle wheel is always counting your travelled distance unless it is
paused. It will audibly click at a configurable interval and send a chat
message. Your current trundle wheel is automatically resumed every time you load
a world or connect to a server. You can also save and reload different named
trundle wheels to keep different numbers for different servers. The trundle
wheel will also track your vertical movement by default - this will be discussed
further in the reference.

An note on teleportation: You should probably pause your trundlewheel before
teleporting, or it's going to start clicking very quickly until it accounts for
your entire teleportation distance. The trundle wheel cannot distinguish
footsteps from teleportation or travelling in vehicles.

### Quantities of the trundle wheel

The trundle wheel has four main quantities:
* Whether it is paused or active.
* How long each rotation of the trundle wheel will be.
* How far the trundle wheel has gone in the current rotation.
* The grand total of distance travelled by the trundle wheel.

Each of the quantities is saved to your current trundle wheel when you close
the world. If your game crashes, trundle wheel progress may be lost. An
autosave feature may come later. The quantities can also be saved and loaded
with some of commands below.

### Command reference

`.wheel_conf get ([] | rotationdist | vertical | paused)`
`.wheel_conf set ([] | rotationdist <float> | vertical <bool> | paused <bool>)`

Get and set configuration options. With no argument, will show all options. The
options are:
* rotationdist - The distance of one complete rotation of the trundle wheel,
  analogous to a real trundle wheel's circumference. Defaults to 10.
* vertical - Whether the trundle wheel will track your vertical movements.
Defaults to true. This has the side effect of tracking extra vertical movement
if you need to jump to get up blocks - prefer slabs and other smooth sloping
shapes where possible to get the most accurate measurement. Turn it off if you
want to measure distance only on the x and z axes.
* paused - Whether the trundle wheel is actively counting. You may want to pause
and save your trundle wheel each time you leave or join a server or singleplayer
world. You may also want to make a temporary diversion from your route that you
don't want to be counted. Pause status is saved with the trundle wheel.

`.wheel_delete [name]`

Delete the saved wheel with `[name]` (may include spaces). Will delete the
trundle wheel with no name if it exists.  Technical note: If no wheels are
left the mod storage key for wheels is cleared.

`.wheel_info`

Prints the trundle wheel pause/active status, rotation distance, total distance
this rotation and grand total distance (the four quantities).

`.wheel_load [name]`

Loads the trundle wheel with `[name]`. Save your current wheel first if you
don't want to lose it. Will load the trundle wheel with no name if it exists.

`.wheel_reset [<val>] [grand]`
`.wheel_reset [grand] [<val>]`

Reset the statistics on your wheel: either its distance on the current rotation,
or grand total distance. Sets the wheel to a specified value if one is provided.
Applies to the grand total distance if "grand" is supplied as one of the
arguments.

`.wheel_save [name]`

Saves the current wheel: its distance per rotation, its distance, its grand
total distance and whether it is paused. Saves it with the name provided, or as
the 'wheel with no name' if no name is given. There can only be one wheel with
no name.

`.wheels`

Lists all of the saved wheels, including the wheel with no name if it exists.

## Licence
The MIT License (MIT)

Copyright © 2022 Blockhead <jbis1337@hotmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

