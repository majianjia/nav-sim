# Navigation Simulator

Navigation simulator is base on Processing 3 (Java) programming language to provide a simple world simulation. This project was built for validating the navigation algorithm for [DeepPlankter drone boat project](https://github.com/majianjia/DeepPlankter) before it can be deployed to the boat.

![](doc\nav-sim-loop.gif)

One of the key challenges in the boat navigation is the boat's propulsions system. The boat is propelled by underwater wings (wave) and in air free-rotate wing which are both very weak and unstable. There are chances that the boat being push to the opposite direction in strong wind or tide current. The navigation algorithm for air drone might not be able to handle those situation.

An other challenge is the in air wing, work similarly to a sail but not exactly. If you are familiar with sailing, you already knew that wind there are some bearing zone called dead zone which the sail will not generate lift but drag. For example, when the boat is heading to the wind, the sail only generate drag. The navigation should avoid this situation.

## Features

The simulator provide below features. 

- GPS coordination (latitude, longitude)

- Dynamic wind (guest, direction, drag)

- Dynamic current (direction and drag)

- Boat physical modelling

- Time wrap

- Interactive waypoint

Due to the simplicity, it is far from a real world simulator.

## How to use

I didn't implement any user setting interface, most of the configuration will need to modify the code directly. it is out of my scope. but it is more than enough for me to test the navigation algorithm in extreme situation.

There are some executables allow you to play without touching the code, they are in the [source folder](simulator). 

- Arrow key up and down for time wrap. 

- Left mouse button for adding a new waypoint. 

- Right mouse button for deleting the last waypoint. 

![](nav-sim-waypoint.gif)

> For more details about navigation algorithm, please refer to the [DeepPlankter](https://github.com/majianjia/DeepPlankter) project. 

## Contact

Author: Jianjia Ma

email: majianjia(at)live.com




