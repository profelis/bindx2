package ;

import bindx.IBindable;
import bindx.Bind;

class InheritanceTest extends haxe.unit.TestCase {
	public function new() {
		super();
	}

	function testChild() {
		var c = new BindableChild();
		c.i = 0;
		c.s = "0";
		var iChanged = 0;
		Bind.bind(c.i, function (from, to) {
			assertEquals(from, 0);
			assertEquals(to, 1);
			iChanged ++;
		});
		c.i = 1;
		assertEquals(iChanged, 1);

		var sChanged = 0;
		Bind.bind(c.s, function (from, to) {
			assertEquals(from, "0");
			assertEquals(to, "1");
			sChanged ++;
		});
		c.s = "1";
		assertEquals(sChanged, 1);
	}


}

@:bindable
class BindableParent implements IBindable {
	public function new() {}

	public var i:Int;
}

@:bindable
class BindableChild extends BindableParent {
	
	public var s:String;
}