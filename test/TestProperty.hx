package ;

import bindx.Bind;
import bindx.Bind.bind in bind;
import buddy.*;

using buddy.Should;

class TestProperty extends BuddySuite {
	public function new() {
		super();
		
		describe("Bindx modify field setter", {
			
			var p:BindableProperty;
			
			before({
				p = new BindableProperty();
			});
			
			it("bindx should bind/unbind fields with setter (lazySignal=true)");
			it("bindx should bind/unbind fields with setter (lazySignal=false)");
			it("bindx should bind 2 objects (custom setter) (lazySignal=true)");
			it("bindx should bind 2 objects (custom setter) (lazySignal=false)");
		});
	}

	/*function test1() {
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
	
	function test2() {
		var p = new BindableProperty();
		var t = {a:""};
		Bind.bindTo(p.s, t.a);
		
		p.s = "123";
		assertEquals(t.a, p.s);
	}
	*/
}

class BindableProperty implements bindx.IBindable {
	public function new() {
	}

	@:bindable(lazySignal=true)
	public var str(default, set):String;

	function set_str(v) {
		if (v == null) {
			return str = "";
		}
		str = v;
		return v;
	}
	
	@:bindable(lazySignal=false)
	public var str2(default, set):String;

	function set_str2(v) {
		if (v == null) {
			return str2 = "";
		}
		str2 = v;
		return v;
	}
}