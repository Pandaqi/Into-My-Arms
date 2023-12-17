# Into My Arms

This is the source code for the **game jam version** of [Into My Arms](https://pandaqi.com/into-my-arms).

This project is my submission for the Github Game Off Jam. It's a 2D isometric puzzle game for 1-2 players, with two unique elements:
*  You control two cute players ("cubitos") who are NEVER allowed to see each other.
*  To win a level, you must make a leap of faith: one of your cubitos must step backwards, fall from a height, into the arms of the other. (Hence the title of the game.)

It's made in **Godot Game Engine v3.2** (beta version, at the time of writing). It's completely 2D, but uses some clever (though computationally expensive) techniques to sort everything to look like it's 3D. It also uses lots of trickery with recursive functions to determine what a player can see (even when mirrors, lights, and other things are thrown into the mix).

I also made sure the game would work on both **desktop** (Windows/Mac/Linux) and **mobile** (Android/iOS). The main issue was performance and rescaling/resizing the interface and level area for all different sizes and resolutions. I think I succeeded quite well, but I obviously don't have every single device in the world to test the game on.

(Oh, and, the title of the game comes from the song *Into My Arms* by *Nick Cave*. A beautiful song.)

## Future of the project

I'm thinking of turning this game into a full game. I think the mechanics and look could work really well for a small, cute, puzzle game (especially on mobile). If you want to see more of these games, or more of these open source projects for you to study, please support me by donating/buying my work on itch.io: http://pandaqi.itch.io

## Warnings

The project was made in approximately two weeks for the game jam, with making it open source always in the back of my mind. I am very proud of it and think it looks/works great, but there are always some warnings:
*  Code is messy or unoptimized in places
*  The art assets are fine, but nothing special (many inaccuracies and lack of detail)
*  This is not necessarily an example on good practices, clean code architecture, or how to use Godot. I think I did quite well and it's not *horrible* by any means - just don't take the way I did things as gospel. It's very likely I will have learned some better or cleaner workflow in two months.

With all that negativity out of the way - have fun with this game and this project!
