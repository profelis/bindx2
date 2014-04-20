package ;

import haxe.unit.TestCase;

class BaseTest extends TestCase {

	public function new() {
		super();
	}

	function test1() {
		var b = new Bindable1();
		b.str = "a";
		var callNum = 0;
		b.strChanged.add(function (from, to) {
			assertEquals(from, "a");
			assertEquals(to, "b");
			callNum ++;
		});

		bindx.Bind.bindx(b.str, function (from, to) {
			assertEquals(from, "a");
			assertEquals(to, "b");
			callNum ++;
		});
		b.str = "b";
		assertEquals(callNum, 2);
	}

	function test2() {
		var b = new Bindable1();
		b.str = null;
		var callNum = 0;
		var listener = function (from, to) {
			assertEquals(from, null);
			assertEquals(to, "");
			callNum ++;
		}

		b.strChanged.add(listener);
		bindx.Bind.bindx(b.str, listener);
		b.str = "";
		assertEquals(callNum, 1);

		b.strChanged.add(listener);
		bindx.Bind.unbindx(b.str, listener);
		b.str = "1";
		assertEquals(callNum, 1);
	}

	function test3() {
		var b = new Bindable1();
		b.str = null;
		var callNum = 0;

		bindx.Bind.bindx(b.str, function (_, _) callNum++);
		bindx.Bind.bindx(b.str, function (_, _) callNum++);
		b.str = "";
		assertEquals(callNum, 2);

		b.strChanged.removeAll();
		b.str = "1";
		assertEquals(callNum, 2);

		b.strChanged.dispose();
		var addError = false;
		try {
			b.strChanged.add(function (_, _) {});
		} catch (e:Dynamic) {
			addError = true;
		}
		assertTrue(addError);
	}

	function test4() {
		var b = new Bindable1();
		b.str = null;
		var callNum = 0;
		var listener = function (from, to) {
			assertEquals(from, "1");
			assertEquals(to, "2");
			callNum ++;
		}
		b.strChanged.add(listener);
		b.strChanged.dispatch("1", "2");
		assertEquals(callNum, 1);

		bindx.Bind.notify(b.str, "1", "2");
		assertEquals(callNum, 2);
	}

	function test5() {
		var b = new Bindable1();
		b.str = null;
		var callNum = 0;
		b.bindChanged.add(function () callNum++);

		b.i = 10;
		assertEquals(callNum, 1);
		assertFalse(Reflect.hasField(b, "noBindChanged"));

		bindx.Bind.notify(b.bind);
		assertEquals(callNum, 2);
	}
}

@:bindable
class Bindable1 implements bindx.IBindable {

	
	public var str:String;

	@:bindable
	public var i(default, set):Int;

	@:bindable
	private var privateVar:Bool;

	public function new() {
		if (this.privateVarChanged == null)
			throw "no private binding";
	}

	function set_i(v) {
		i = v;
        bindx.Bind.notify(this.bind);
		return v;
	}

	public function noBind() {

	}

	@:bindable
	public function bind() {

	}
}