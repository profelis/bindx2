package ;

import buddy.BuddySuite;

@:build(buddy.GenerateMain.build(null, ["test"]))
class Tests extends BuddySuite {}