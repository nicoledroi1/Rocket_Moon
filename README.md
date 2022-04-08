# Rocket_Moon
A platform game (with a rocket and meteors) written in MIPS assembly.

Features
Health
Constantly moving platforms
3 different pickups with different effects
Disappearing platforms
Fail condition/fail screen

My own extra features not for grades:
Meteor 'gravity' pull increases every 30 seconds
Rocket 'gravity' pull increases when the meteor 'gravity' pull is less than or equal to .5 s

Demo
Available at https://youtu.be/3wl-69Rw3ek.

Usage
Run this with the MARS simulator. 
Open game.asm in MARS.

These are the display settings:
Unit width in pixels: 8
Unit height in pixels: 8
Display width in pixels: 512
Display height in pixels: 256
Base Address for Display: 0x10010000 (static data)

Use keyboard display window

Assemble and run the game, making sure to keep the simulation speed at maximum.

Controls:
WAD to move
P to restart

This is a CSCB58 project!
