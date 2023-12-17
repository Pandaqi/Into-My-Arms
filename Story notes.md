**Story notes**

**PRE-GAME:**

Text fades in/out, slowly moves across screen.

Images above it.

-   Once upon a time, two cubitos were in love ... (Get it? Cubito => cube + cupido)

-   They wanted to hug, they wanted to dance, yet ...

-   They never got the chance

-   Or, as that witch liked to say, "you never TOOK your chance"

-   The witch came out of nowhere, like a silent stranger

-   She took one look, spoke magic words from a magic book, and everything started changing

-   Suddenly the two lovers could not look each other in the eye

-   Instead, the witch proclaimed, you must take a leap of faith

-   The only way to pass each stage, is stepping backwards from a great height ...

-   Falling into your lovers arms, that's how love will bloom tonight ...

**OUTRO**

-   And on that final day, the witch returned

-   You did well my darlings, but remember the lessons you have learned

-   Don't fill your heart with anger, distrust or hate

-   You'll live happily ever after ... with just a leap of faith

**LEVEL 0 ("Tutorial"):**

Controls are explained "in the background":

**PC/MAC/LINUX:** Above the players, some text and buttons to explain how players move/rotate

**ANDROID/iOS:** Clearly link interface buttons with players and explain with pointers what they do

Two rules are floating in the air:

**Rule #1:** Players can NEVER look at each other.

**Rule #2:** To win the stage, one player must step backwards from a height, and fall on top of the other player ("into their arms")

**Links/info/remarks**

**LINKS** (mostly on isometric calculations/conversion/depth sorting):

<https://gamedev.stackexchange.com/questions/8151/how-do-i-sort-isometric-sprites-into-the-correct-order> (link to pigeonhole algorithm was also useful)

<https://gamedev.stackexchange.com/questions/8151/how-do-i-sort-isometric-sprites-into-the-correct-order/8181#8181>

<https://gamedev.stackexchange.com/questions/14070/tile-based-isometric-depth-sorting-on-different-size-objects?rq=1>

**\
**

**INTERESTING VIDEO:** 8 common game architecture/code mistakes

> **URL:** <https://www.youtube.com/watch?v=8Hy4JvtfUb8>

**Mistake #1**: Having game logic inside the UI

-   Don't store/modify actual game data within the UI

-   Don't calculate/evaluate game logic within the UI

-   Instead, let the game logic call the UI manager whenever something changes/is needed

-   Also: if the menu has many different states, create a *state manager* for it. The state manager ensures the current state is always correct => once this state is determined, that's when it calls the UI to update it

**Mistake #2:** Having giant, monolithic, single classes

-   Don't put different functionality into the same class => 1000 lines is already a bit too much, more than that is most likely a problem

-   Why does it happen? At first, it's very easy: only a single file, don't need to connect/reference anything. It usually happens as a side-effect (it just grows over time)

-   Solution? Clean things as you're working. Split things into parts that make sense as you go.

-   If you see your class getting 200-300 lines long => investigate it! Is the class doing too many things?

**Mistake #3:** Having everything public

-   (This was mostly relevant for Unity3D. Too many things are exposed to the inspector => which means too many things become interconnected or data is lost. For example: you can't get the original value for something without referencing back to the original prefab.)

-   You only want things to be public if they are *intended to be used by another class*.

**Mistake #4:** Having setters with side-effects

-   If a setter isn't just *setting the value*, but doing other stuff as well, there will be problems in many ways.

-   Within that side-effect, something else might be happening. Thus, you get a chain reaction. (Or, that side-effect might take a lot of time, causing the whole setter to become slow/grind to a halt.)

-   It's NOT necessarily a problem to have a setter with side-effects, it's a problem to HIDE it.

-   Solution? Make setters extremely simple: just set/get something. If you want extra functionality, wrap a function around it that calls both the setter and the extra functionality.

**Mistake #5:** Giant Prefabs

-   Connected to the "large monolithic classes" problem => hard to re-use functionality, hard to maintain, hard to co-operate with others in a team.

-   Solution? Split prefabs into multiple smaller prefabs. Instead of making a UI a single prefab, make the prefab a collection of smaller scenes, each of which contains part of the UI. (*Nested prefabs*.)

-   Solution 2? Use prefab variants (Unity3D specific)

**Mistake #6:** Not using Interfaces (Unity3D specific). Using them too much is bad, using them too little is also bad.

-   Possible use case: A system that needs to interact with two different objects, but in the same (kind of) way

    -   You *could* put the same script/node/component on both objects, or just copy code. But you run into problems: e.g. a take damage function on a player and a crate, but the player needs to react *differently* to damage than the crate.

    -   Instead, find a common interface (like an "I take damage" or "I have health"). Give it a (public) method like take_damage(). Then you make both health components implement that interface -- but in different ways.

-   Another benefit: unit testing your code becomes dramatically easier.

-   **What are interfaces?** Kind of the same as class inheritance or extensions. Any class that shares an interface, must have all the methods/properties from that interface implemented. (The actual implementation, of course, can vary/be modified.)

    -   Unity introduction Interfaces: <https://www.youtube.com/watch?v=50_qBoKGKxs>

    -   INHERITENCE: Class B **is a** Class A

    -   INTERFACES: Class B **implements** Class A

**Mistake #7:** Completely ignoring garbage collection and performance issues.

-   Of course, in tiny games, or Game Jam/Hackathon games, or the prototyping stage, it doesn't matter and nobody's going to notice.

-   Solution? Everytime you make a (significant) change, go in there and profile it. Every time.

-   Little things like a small/tiny performance decrease, don't sweat it. But when you see big problems (in architecture), or know there's a better way to solve something -- do it!

**Mistake #8:** Not sharing what you're doing (code/architecture) and not getting feedback.

This includes NOT looking at other people's architecture. If you only look at your own code, you'll never learn and you never grow.

Solution? Find source code for other games and inspect it!
