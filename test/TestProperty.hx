package ;

import bindx.Bind;
import bindx.Bind.bind in bind;
import buddy.*;

using buddy.Should;

class TestProperty extends BuddySuite {
	public function new() {
		super();
		
		describe("Using bind properties", function () {
			
			var b:BindableProperty;
            var callNum:Int;
			
			before(function () {
				b = new BindableProperty();
                callNum = 0;
			});
			
			it("bindx should bind/unbind fields (lazySignal=true)", function () {
				var strFrom = b.str = "a";
				var callNum2 = 0;
				
		        bind(b.str, function (from, to) {
					from.should.be(strFrom);
					to.should.be(b.str);
					callNum ++;
				});

	        	var listener2 = function (from:String, to:String) {
					from.should.be(strFrom);
					to.should.be(b.str);
					callNum ++;
					callNum2 ++;
				};
				Bind.bind(b.str, listener2);
				
				b.str = "b";
				callNum.should.be(2);
				callNum2.should.be(1);
				
				Bind.unbind(b.str, listener2);
				strFrom = b.str;
				b.str = "c";
				
				callNum.should.be(3);
				callNum2.should.be(1);
			});
			
			it("bindx should bind/unbind fields (lazySignal=false)", function () {
				var strFrom = b.str2 = "a";
				var callNum2 = 0;
				
		        bind(b.str2, function (from, to) {
					from.should.be(strFrom);
					to.should.be(b.str2);
					callNum ++;
				});

	        	var listener2 = function (from:String, to:String) {
					from.should.be(strFrom);
					to.should.be(b.str2);
					callNum ++;
					callNum2 ++;
				};
				Bind.bind(b.str2, listener2);
				
				b.str2 = "b";
				callNum.should.be(2);
				callNum2.should.be(1);
				
				Bind.unbind(b.str2, listener2);
				strFrom = b.str2;
				b.str2 = "c";
				
				callNum.should.be(3);
				callNum2.should.be(1);
			});
			
			it("bindx should bind/unbind 'null' values (lazySignal=true)", function () {
				var strFrom = b.str = null;
				var callNum2 = 0;
				var listener = function (from:String, to:String) {
					from.should.be(strFrom);
					to.should.be(b.str);
					callNum ++;
				}
				var listener2 = function (from:String, to:String) {
					from.should.be(strFrom);
					to.should.be(b.str);
					callNum ++;
					callNum2 ++;
				};
				bind(b.str, listener); //b.str == null now
				bind(b.str, listener2);
				
				b.str = "a";
				callNum.should.be(2);
				callNum2.should.be(1);

				Bind.unbind(b.str, listener2);
				strFrom = b.str;
				b.str = null;         // b.str set null
				callNum.should.be(3);
				callNum2.should.be(1);
			});
			
			it("bindx should bind/unbind 'null' values (lazySignal=false)", function () {
				var strFrom = b.str2 = null;
				var callNum2 = 0;
				var listener = function (from:String, to:String) {
					from.should.be(strFrom);
					to.should.be(b.str2);
					callNum ++;
				}
				var listener2 = function (from:String, to:String) {
					from.should.be(strFrom);
					to.should.be(b.str2);
					callNum ++;
					callNum2 ++;
				};
				bind(b.str2, listener); //b.str2 == null now
				bind(b.str2, listener2);
				
				b.str2 = "a";
				callNum.should.be(2);
				callNum2.should.be(1);

				Bind.unbind(b.str2, listener2);
				strFrom = b.str2;
				b.str2 = null;         // b.str2 set null
				callNum.should.be(3);
				callNum2.should.be(1);
			});
			
			it("bindx should bind 2 objects (lazySignal=true)", function () {
				var callNum2 = 0;
				var target = {a:""};
				var s = "";
				
				var unbindA = Bind.bindTo(b.str, target.a);
				Bind.bindTo(b.str, s);
				
				var prev = b.str = "b";
				target.a.should.be(prev);
				s.should.be(prev);
				
				unbindA();
				Bind.unbindAll(b);
				
				b.str = "c";
				target.a.should.be(prev);
				s.should.be(prev);
			});
			
			it("bindx should bind 2 objects (lazySignal=false)", function () {
				var callNum2 = 0;
				var target = {a:""};
				var s = "";
				
				Bind.bindTo(b.str2, target.a);
				Bind.bindTo(b.str2, s);
				
				var prev = b.str2 = "b";
				target.a.should.be(prev);
				s.should.be(prev);
				
				Bind.unbind(b.str2);
				
				b.str2 = "c";
				target.a.should.be(prev);
				s.should.be(prev);
			});
			
			it("bindx should notify properties manual (lazySignal=true)", function () {
				b.str = "3";
				var f = "1";
				var t = "2";
				var listener = function (from:String, to:String) {
					from.should.be(f);
					to.should.be(t);
					callNum ++;
				};
				bind(b.str, listener);
				
				Bind.notify(b.str, f, t);
				callNum.should.be(1);
			});
			
			it("bindx should notify properties manual (lazySignal=false)", function () {
				b.str2 = "3";
				var f = "1";
				var t = "2";
				var listener = function (from:String, to:String) {
					from.should.be(f);
					to.should.be(t);
					callNum ++;
				};
				bind(b.str2, listener);
				
				Bind.notify(b.str2, f, t);
				callNum.should.be(1);
			});
			
			it("bindx should unbind all properties listeners (lazySignal=true)", function () {
				bind(b.str, function (from, to) callNum++);
				bind(b.str, function (from, to) callNum++);
				
				Bind.unbind(b.str);
				b.str = b.str + "1";
				
				callNum.should.be(0);
			});
			
			it("bindx should unbind all properties listeners (lazySignal=false)", function () {
				bind(b.str2, function (from, to) callNum++);
				bind(b.str2, function (from, to) callNum++);
				
				Bind.unbind(b.str2);
				b.str2 = b.str2 + "1";
				
				callNum.should.be(0);
			});
			
			it("bindx should unbind all bindings (signal exists) (lazySignal=true/false)", function () {
				bind(b.str, function (_, _) callNum++); // create binding signal
				bind(b.str2, function (_, _) callNum++);
				
				Bind.unbindAll(b);
				
				try {
					b.str = b.str + "1";
					b.str2 = b.str2 + "1";
				}
				catch (e:Dynamic) {
					fail();
				}
				
				callNum.should.be(0);
			});
			
			it("bindx should unbind all bindings (signal expected) (lazySignal=true/false)", function () {
				Bind.unbindAll(b);
				
				try {
					b.str = b.str + "1";
					b.str2 = b.str2 + "1";
				}
				catch (e:Dynamic) {
					fail();
				}
				
				true.should.be(true);
			});
		});
	}
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