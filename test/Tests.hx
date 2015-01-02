package ;

import buddy.BuddySuite;
import buddy.SuitesRunner;

class Tests extends BuddySuite {
    
    public static function main() {
        var reporter = new buddy.reporting.TravisHxReporter();

        var runner = new SuitesRunner([
            new BaseTest(),
            new InheritanceTest(),
            new InlineTest(),
            new MetaTest(),
            new SignalTest(),
            new TestProperty(),
            new ChainBindTest(),
            new ExprBindTest(),
        ], reporter);

        runner.run();

        Sys.exit(runner.statusCode());
    }
}