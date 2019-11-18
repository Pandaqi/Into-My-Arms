# Into My Arms

This project is my submission for the Github Game Off Jam. It's a 2D isometric puzzle game for 1-2 players, with two unique elements:
*  You control two cute players ("cubitos") who are NEVER allowed to see each other.
*  To win a level, you must make a leap of faith: one of your cubitos must step backwards, fall from a height, into the arms of the other. (Hence the title of the game.)

It's made in **Godot Game Engine v3.2** (beta version, at the time of writing). It's completely 2D, but uses some clever (though computationally expensive) techniques to sort everything to look like it's 3D. It also uses lots of trickery with recursive functions to determine what a player can see (even when mirrors, lights, and other things are thrown into the mix).

I also made sure the game would work on both **desktop** (Windows/Mac/Linux) and **mobile** (Android/iOS). The main issue was performance and rescaling/resizing the interface and level area for all different sizes and resolutions. I think I succeeded quite well, but I obviously don't have every single device in the world to test the game on.

This project is available under the **GNU General Public License v3** This means you can:
*  View, read, use, and distribute the source code any way you want (even commercially)
*  If you do so, however, you must also make your project available under the same open source license, give credit to the original project, and highlight any (significant) changes

You're more than free to look at the project, learn from it, use parts of it for your own project. Please don't blindly copy the assets/systems/code and release it as your own. You won't learn anything from it, and I would be very, very mad. (Well, disappointed might be a better word.) 

Another reason I have for saying this, is the fact that I am thinking of developing the project into a full game, which I would like to release as a paid version in the future. If you want to see more of these games, or more of these open source projects for you to study, please support me by donating/buying my work on itch.io: http://pandaqi.itch.io

The project was made in approximately two weeks for the game jam, with making it open source always in the back of my mind. I am very proud of it and think it looks/works great, but there are always some warnings:
*  Code is messy or unoptimized in places
*  The art assets are fine, but nothing special (many inaccuracies and lack of detail)
*  This is not necessarily an example on good practices, clean code architecture, or how to use Godot. I think I did quite well and it's not *horrible* by any means - just don't take the way I did things as gospel. It's very likely I will have learned some better or cleaner workflow in two months.

With all that negativity out of the way - have fun with this game and this project!
