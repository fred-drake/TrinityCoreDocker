# Trinity Core
This image will allow you to run your own complete dockerized WoW Wrath of the Lich King private server, using the Trinity Core open source MMO framework.

## Ways To Run Your WoW Server
There are two ways you can implement this: with an all-in-one approach, or manually managing your auth server, world server, and database.

The all-in-one approach is much more of a turn-key solution: you kick off the container with minimal environment settings and a single volume, and the container startup takes care of the rest.  The tradeoff for this convenience is that everything runs on exactly one container so it will not scale very well.

Which to use?  If you are merely playing this for yourself or a group of friends, the all-in-one is probably easier.  If you want to scale it up to the level of a public server, then the all-in-one would probably not be for you.  If in doubt, I'd suggest starting with the all-in-one approach because you could easily transfer your client data and MySQL data off to a more distributed system later on.

## Setup
Click through to your preferred way of running your container:

* [All In One](All-In-One-Setup.md)
* [Manually](Manual-Setup.md)
