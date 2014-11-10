package ;

import bindx.Bind;

class TestProperty extends haxe.unit.TestCase {
	public function new() {
		super();
	}

	function test1() {
		var p = new BindableProperty();
		p.s = "1";
		var callNum = 0;

		Bind.bind(p.s, function (from, to) {
			assertEquals(from, "1");
			assertEquals(to, "");
			callNum ++;
		});

		p.s = null;

        Bind.unbind(p.s);

		Bind.bind(p.s, function (from, to) {
			assertEquals(from, "");
			assertEquals(to, "1");
			callNum ++;
		});
		p.s = "1";

		assertEquals(callNum, 2);
	}
}

class BindableProperty implements bindx.IBindable {
	public function new() {
	}

	@:bindable
	public var s(default, set):String;

	function set_s(v) {
		if (v == null) {
			return s = "";
		}
		s = v;
		return v;
	}
}