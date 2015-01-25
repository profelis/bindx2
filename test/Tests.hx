package ;

import buddy.BuddySuite;
import buddy.SuitesRunner;

@:build(buddy.GenerateMain.withSuites([
    new BaseTest(),
    new InheritanceTest(),
    new InlineTest(),
    new MetaTest(),
    new SignalTest(),
    new TestProperty(),
    new ChainBindTest(),
    new ExprBindTest(),
]))
class Tests extends BuddySuite {}