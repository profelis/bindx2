package ;

import bindx.Bind;
import bindx.Bind.bind in bind;
import buddy.*;

using buddy.Should;

class BaseTest extends BuddySuite {

	public function new() {
		super();
	
		describe("Base bindx functionality", {
			
			var b:Bindable1;
			var callNum:Int;
			
			before({
				b = new Bindable1();
				callNum = 0;
			});
			
			it ("bindx should bind/unbind fields (lazySignal=true)", {
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
			
			it ("bindx should bind/unbind fields (lazySignal=false)", {
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
			
			it("bindx should bind/unbind 'null' values (lazySignal=true)", {
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
			
			it("bindx should bind/unbind 'null' values (lazySignal=false)", {
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
			
			it("bindx should bind 2 objects (lazySignal=true)", {
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
			
			it("bindx should bind 2 objects (lazySignal=false)", {
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
			
			it("bindx should bind and notify methods (lazySignal=true)", {
				var listener = function () callNum++;
				bind(b.bind, listener);
				Bind.notify(b.bind);
				
				callNum.should.be(1);
				
				Bind.unbind(b.bind, listener);
				Bind.notify(b.bind);
				
				callNum.should.be(1);
			});
			
			it("bindx should bind and notify methods (lazySignal=false)", {
				var listener = function () callNum++;
				bind(b.bind2, listener);
				Bind.notify(b.bind2);
				
				callNum.should.be(1);
				
				Bind.unbind(b.bind2, listener);
				Bind.notify(b.bind2);
				
				callNum.should.be(1);
			});
			
			it("bindx should notify properties manual (lazySignal=true)", {
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
			
			it("bindx should notify properties manual (lazySignal=false)", {
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
			
			it("bindx should unbind all properties listeners (lazySignal=true)", {
				bind(b.str, function (from, to) callNum++);
				bind(b.str, function (from, to) callNum++);
				
				Bind.unbind(b.str);
				b.str = b.str + "1";
				
				callNum.should.be(0);
			});
			
			it("bindx should unbind all properties listeners (lazySignal=false)", {
				bind(b.str2, function (from, to) callNum++);
				bind(b.str2, function (from, to) callNum++);
				
				Bind.unbind(b.str2);
				b.str2 = b.str2 + "1";
				
				callNum.should.be(0);
			});
			
			it("bindx should unbind all method listeners");
			
			it("bindx should unbind all bindings (signal exists) (lazySignal=true/false)", {
				bind(b.str, function (_, _) callNum++); // create binding signal
				bind(b.str2, function (_, _) callNum++);
				bind(b.bind, function () callNum++);
				bind(b.bind2, function () callNum++);
				
				Bind.unbindAll(b);
				
				try {
					b.str = b.str + "1";
					b.str2 = b.str2 + "1";
					Bind.notify(b.bind);
					Bind.notify(b.bind2);
				}
				catch (e:Dynamic) {
					fail();
				}
				
				callNum.should.be(0);
			});
			
			it("bindx should unbind all bindings (signal expected) (lazySignal=true/false)", {
				Bind.unbindAll(b);
				
				try {
					b.str = b.str + "1";
					b.str2 = b.str2 + "1";
					Bind.notify(b.bind);
					Bind.notify(b.bind2);
				}
				catch (e:Dynamic) {
					fail();
				}
				
				true.should.be(true);
			});
		});
	}
}


class Bindable1 implements bindx.IBindable {

	@:bindable(lazySignal=true)
	public var str:String;

	@:bindable(lazySignal=false)
	public var str2:String;

	@:bindable(lazySignal=true)
	public function bind() {
	}
	
	@:bindable(lazySignal=false)
	public function bind2() {
	}
	
	public function new() {
	}
}