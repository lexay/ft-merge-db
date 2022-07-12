### About this project
I use the FreeTube app for watching YouTube videos frequently. FreeTube works
like YouTube, but without spying stuff from Google, e.g.: you can subscribe to
channels without creating a Google account.

I use multiple instances of it across several operating systems.  My
subscriptions may shift from time to time on those different OSes. I try to
backup those subscriptions, keeping track of the recent ones.

So I end up with multiple backups and at some point in time I need a way to
merge them into one ultimate updated version of those subscriptions. Then I can
use it later for every instance of FreeTube on every OS of mine.

Git fits rather well for this task, but it is more fun to implement something of
my own for practice in Ruby and fun.

One other reason, which I've just made up, is that you can merge, let's say,
your friends' shared backups into one MEGA backup if you need one.

##### Features:
App can have as many backups as you like for input. The increasing complexity
takes its toll though, don't be too greedy, it looks like O(n).

App takes in and spits out your backups in the default `.db` format, which I
find more reliable and customizable and it is a kind of json, delimited by new
lines.

### Changelog:
2022-07-10 Stable v1 released.

### TODO:
It's a simple file merger. Why should it be something more?
All right, changeable color and names for categories in future versions one day
:-)
