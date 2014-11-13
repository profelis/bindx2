package ;

import bindx.Bind;
import bindx.IBindable;
import buddy.BuddySuite;

using buddy.Should;

class InheritanceTest extends BuddySuite {
	public function new() {
		super();
	
        describe("Using classes inheritance", {
            it("bindx should support class inheritance");
        });
    }
        /*
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
    }*/
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