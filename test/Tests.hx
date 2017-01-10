package ;

import buddy.BuddySuite;
import buddy.SuitesRunner;

// In buddy 1.0, GenerateMain moved to buddy.internal
#if (buddy < "0.99")
  #error "Please use buddy 1.0 or later"
#end

@:build(buddy.internal.GenerateMain.withSuites([
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
