package ;

import haxe.unit.TestRunner;

class Tests {

	static function main() {
		var runner = new TestRunner();
		runner.add(new BaseTest());
		runner.add(new InheritanceTest());
		runner.add(new TestProperty());
		runner.run();
	}
}