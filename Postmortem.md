**Postmortem: Into My Arms**

Ever since I started developing games, I wanted to participate in game jams. At the time, however, I was still in school -- and, let's be honest, a crappy developer -- so I never found the right time to join a game jam.

Until last November. I joined the GitHub Game Off, spent two weeks on developing a cute idea that popped into my head, and submitted it. No expectations, nothing special.

And then I won 11^th^ place. For me, that's huge. And a huge surprise. Seeing my simple, very quickly made game in the highlight trailer for the jam was a moment of joy I just cannot describe :)

I was determined to complete the game, turn it into a full-featured puzzle game (with more than 13 levels and three mechanics), and that's what I did.

In this postmortem, I want to describe the process of creating the game, the final state in which I'm publishing it, and why I'm happy and sad about it at the same time.

Here's the trailer to get an idea about how the game looks and plays:

\<TRAILER HERE>

**The First Idea**

I like to make local multiplayer games. Even better if they're cooperative. And even better if they have some cute theme with practical implications. That's my thing.

When I saw the jam theme -- "Leaps and Bounds" -- I immediately jumped to the association with "Leap of Faith".

Many years ago, I wrote down a puzzle game idea that revolved around two players being in love, but not being able to get together because they were "tied" to certain things in life, holding them back. Well, that idea never saw the light of day, but I could take the core of it and apply it to this game.

I thought: what if we make a puzzle game in which you can only win by making a leap of faith? If you *cannot see each other*, and you must *fall backwards from a height* (a "trust fall" kind of thing), well, then you must surely have faith :p

I immediately jumped on that idea and started working it out. Creating the mechanic was relatively easy, as were the first few puzzles and a bit of the story around them.

Creating a pseudo-3D isometric game world in 2D was a nightmare, though.

**Isometric Issues**

I have an old, crappy, cheap smartphone. It can barely run anything 3D.

When I develop a game, I think it's not weird to require that my own smartphone can run it (otherwise I can't even test it myself), so I immediately turned to 2D. (This was also, however, the first game I made for mobile. So more mistakes were made along the way.)

However, the game takes place on a 3D grid (you can move along x, y and z-axis). Which creates an issue with *depth sorting*: which sprites must be in front of which other sprites?

This is quite easy to solve for static sprites: just say "depth = x + y + z"

IMAGE (small level, overlaid with X/Y/Z axes, and depth calculation)

But when the sprites are moving and changing, like the player characters, this formula creates all sorts of glitches.

In the end, I settled on a sort of "brute force"-algorithm, which basically runs through all sprites twice and checks them against each other to determine their final ordering. Why am I telling you this? Because it's a *sloooow algorithm*, and that will become important later.

When I implemented it, however, it was fast enough (and the levels small enough), and looked very convincing.

**Mysterious by accident**

I designed 13 levels for the game jam entry, for two reasons: I didn't have more time, and I also didn't have more interesting ideas.

The most common feedback from players (both from the jam and my own personal group of testers, aka friends and family) was that it's sometimes really hard to see where you are or what the 3D world looks like.

Because it's 2D, you cannot rotate the camera, which means that a tile somewhere in the front of the level could be obscuring a large part of the backside.

IMAGE HERE (take screenshot of that level at the start with tile above your head)

I noticed it was very hard to design levels where nothing was obscured. If I managed to do it, the levels were usually way too easy.

So, for the final game, I settled on the following solutions to this problem:

-   When the player is behind something, all tiles in front become transparent ("see-through"). This was also in the game jam version, but poorly implemented and therefore quite useless.

-   I turn this problem into a feature! From the start of the game, I make clear that you also need some "faith" in the levels. For some of them, you can only find the solution if you walk around a bit and discover some hidden area.

-   I created highlighters that show which moves a player can take. In most cases, this solves any issue with players not knowing where they are or where they can move.

-   I created an undo-system with infinite UNDOs. (You can turn it off, if you find it too easy.)

IMAGE HERE (show GIF with move indicators and transparency stuff?)

I also had other ideas for solutions, but they all turned out to be too resource intensive, or too unclear.

(For example, I thought about using colors to show where a tile was in the 3D world. Red gradient = x-axis, Green gradient = y-axis, Blue gradient = z-axis. However, there were already many colors in the game, so this was just confusing and didn't clear up anything.)

**Story stuff**

The other neglected area in the game jam version was the *story*. Yes, the game had a nice intro and some texts on the levels, but you couldn't really call it a (well worked-out) story.

And I don't like that.

I often come across those abstract puzzle games (mainly for mobile), and even though they look very slick and clean, it just doesn't draw me. I want story, theme, some practical connections in a game.

In the final version, I made sure to include a text on each level, and made those texts rhyme as well! (You could see it as one long poem, if you wanted.)

The story is about two lovers who really want to be together, but don't dare take that step, don't dare take that "leap of faith". During the story, all sorts of reasons fly by: fears, doubts, insecurities, and more.

I tried to turn those story beats into game mechanics.

For example, when they start talking about "fears", I introduce a new tile. When you step on it, your player becomes frozen by fear.

IMAGE HERE (one level with the fear skeleton)

Doing this solved many problems in the game:

-   I suddenly had many more ideas and mechanics to use in the puzzles.

-   The game as a whole felt more coherent and more varied.

-   I could actually discuss a (practical) theme: love and relationships. (Sure, it's not an in-depth discussion, but hey, it's still just a puzzle game. In a sense, I'm struggling myself with these themes and found it freeing to be able to create a game around it.)

This is what pulled the game together, I think. The story's not amazing, the mechanics are not amazing, but everything combined the game feels like a whole.

**Visual fatigue**

When I showed the game to the wonderful folks at Reddit, they mainly talked about one thing: how the look of the game didn't quite attract them. (Some of them were very positive about the look, some were neutral "it's simple, but it works well", some were very negative.)

I tried to fix that, because I'm a perfectionist who can't just let go of something :p

As I was creating/debugging the game, I also noticed that I was getting some visual fatigue from the game, because there wasn't much variety in how things looked. And you don't want that to happen!

I tried *so many things*, but most of them didn't quite work out, unfortunately.

These things worked out:

-   The background gradient in each level can now have one out of 6 possible color schemes.

-   All buttons / UI in the game had their look upgraded. (Still figuring out how Godot handles GUI skinning, though, as I keep running into weird issues.)

-   I created an "ice world", which allowed me to turn all tiles into different ones (with snow, and ice, and all that).

-   I created many more grass and ground tile variations. (At the start of a level, all grass tiles are randomly swapped with another, so each time you start the level it looks different. By adding more variations to the pool, the probability of encountering many identical tiles in a level is much smaller.)

-   I added clouds underneath the level, otherwise it was just "floating in space". (I still don't like the look of the clouds on some levels, but I'll also discuss that later.)

These things did NOT work out:

-   I tried to add *shadows* and *texture* to the tiles. It just looked ugly -- as if I had purposely made the tiles "dirty". I don't know if it's just my lack of skill, or that the style doesn't fit the game.

-   I tried to add variation to the players (the two *cubitos*). Also made them look out of place.

-   I tried some more particle effects (butterflies flying around) and animations (grass sweeping in the wind). They also made the game look messy and ate up performance.

In the end, all levels just look somewhat like this:

IMAGE HERE (... just pick a random level that looks kinda good?)

**Now comes the hard part**

There I was: I had created 40 levels for the game, complete with a fitting story running through them. The tileset had 72 tiles. The game had 8 unique mechanics, introduced gradually.

But it still felt like I hadn't reached the full potential of the game.

I had many more ideas but couldn't fit them in the current game for several reasons. (Performance issues, codebase did not support it, or they clashed with other mechanisms.)

I wanted to create more puzzles but couldn't find anything new.

Even more troubling: the existing puzzles felt too easy, and there wasn't much I could do about that.

You see, the main mechanic of the game ("fall on top of each other to win the level") is extremely broad. You only need to find a height somewhere and you're basically done. It's *very* hard to create puzzles where the solution isn't immediately obvious, and even harder to create puzzles where there's only one solution -- the one I intended.

When I let others test the game, they almost always find solutions that are quicker and extremely easy to execute. Simply because it's so easy to win a puzzle. Get the cubito on a height, get the other next to it, and fall down.

IMAGE HERE (of one of those first levels with multiple solutions)

After trying many things and thinking hard about it for a long time ... I decided a major change was needed. So major, in fact, that it might not even resemble the original game anymore :p

*Remark:* on a related note, people pointed out that the game does not have a very strong *hook*. And I totally agree with that. Sure, the winning mechanic is very unique and everything fits together quite nicely, but that's basically it. The visual style is nothing new or amazing, the story has been done before in other variations (themes like love, depression, fears, relationships, etc. seem common in puzzle games). If I want this game to stand out, to really become something special and worthwhile, I need to rethink the whole game.

**Into My Arms, Again?**

I decided to leave all these future ideas for a possible sequel or expansion to the game.

*Why?* As I explained above, the current game's possibilities are exhausted, as far as I can tell. Even though I made the game 2D, the overhead from pretending it's 3D (such as depth sorting all the time) still makes performance lag on my own smartphone, unless I turn off some of the effects.

My own code is partly to blame for this. (Game Jam code isn't very robust or performant.) The rest of the blame falls on the engine (performance still isn't amazing on Godot, to be frank) and my own crappy smartphone.

But I think I know how to fix this.

It will require rewriting almost all the code, a possible switch to 3D, and changing some of the original rules and game mechanics. But if I do that, I can open a whole new repertoire of mechanics, story beats and great visuals.

(To give a concrete and technical example: fences would solve many issues. If I add a fence to a block, you can't fall down from that side anymore. However, my current system is exactly the opposite of what you need to implement fences. And even if I implemented a whole new system, the fences would need to be uniquely depth sorted as well, which creates performance and technical issues.)

Because yes, the fact that the game isn't visually stunning bugs me. And yes, the fact that puzzles aren't as hard or interesting as they could be, bugs me. And yes, the fact that I didn't get more out of this theme, story and unique mechanic -- guess what, it bugs me.

(To give another example: I tried to add decoration to the game. To add some stones, trees, shrubs, ruins, etc. throughout levels. But it just wouldn't work with the current setup. Everything is walkable, which means players could just walk over shrubs like it's nothing. Which looks weird, to say the least. And performance also didn't like it. I once added 10-20 clouds to the game as tiles, which means they are included in depth sorting, and immediately crashed the whole thing.)

**Conclusion**

Despite all the negative thoughts I spewed above, I am very happy and proud of the way the game turned out! The people that tested it for me, found it very cool and engaging, and found most puzzles to be just the right amount of challenging. And the fact that this two-week-monstrosity got 11^th^ place in a game jam with 237 participants, means I must have done many things right.

So I hope you all enjoy this "final" version of the game! It's still free to download. It's even available on the Play Store now.

But I don't think this is the end of the saga. It will take some time, but an upgraded version will come, sooner or later. I hope you understand why I did things the way I did them. I wanted to release this version as soon as possible, to give you something to play and to gather feedback, instead of staying silent for a year and then suddenly dropping a game that only vaguely resembles the original.

In summary:

-   Test your puzzle mechanic before you start creating your whole game. Make sure you can get a lot of mileage out of it.

-   Turning 2D doesn't mean all performance issues are fixed :p Of course, I didn't really expect that, but I also didn't expect performance to be *so bad* on my smartphone for such simple levels.

-   Sometimes you need to try many different things before you find something that works for your game, visually speaking. And sometimes you don't, because simple graphics can be fine.

-   Make story and mechanics work hand-in-hand. It leads to a more coherent and compelling game and makes coming up with new mechanics much easier (in my opinion). (Similarly, if you're stuck on the story part, take hints from your mechanics to overcome writer's block.)

-   Listen to the song that inspired the title of this game: "Into My Arms" by "Nick Cave"

-   Don't be afraid of love. Take that leap of faith! (But be wary of witches ... )

Hope you all have fun playing the game! And maybe see you next game jam.

**P.S.** On a more personal note, I am happy I finished this game. Probably the hardest part of game development, is actually finishing, polishing, and properly releasing a game. I read a quote a few weeks ago that said "releasing your game is like showing all your vulnerabilities", and I wholeheartedly agree. Releasing a game like this, means I have to show the world I'm not an amazing artist, and that I don't always create perfect puzzles, and that I write code that might have bugs, and stuff like that.

But with every release, it gets a little easier. Every mistake I make, means my next game (and release) will be better. At least, that's how I try to look at it.
