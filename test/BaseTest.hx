package ;

import bindx.Bind;
import bindx.Bind.bind in bind;
import buddy.*;

using buddy.Should;

class BaseTest extends BuddySuite {

	public function new() {
		super();
	
		describe("Using base functionality", function () {
			
			var b:Bindable1;
			var callNum:Int;

			before(function () {
				b = new Bindable1();
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
			
			it("bindx should bind 2 objects (lazySignal=true)", function() {
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
			
			it("bindx should bind and notify methods (lazySignal=true)", function () {
				var listener = function () callNum++;
				bind(b.bind, listener);
				Bind.notify(b.bind);
				
				callNum.should.be(1);
				
				Bind.unbind(b.bind, listener);
				Bind.notify(b.bind);
				
				callNum.should.be(1);
			});
			
			it("bindx should bind and notify methods (lazySignal=false)", function () {
				var listener = function () callNum++;
				bind(b.bind2, listener);
				Bind.notify(b.bind2);
				
				callNum.should.be(1);
				
				Bind.unbind(b.bind2, listener);
				Bind.notify(b.bind2);
				
				callNum.should.be(1);
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
			
			it("bindx should unbind all bindings (signal expected) (lazySignal=true/false)", function () {
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

			it("bindx should bind all bindings (force mode)", function () {
				var fieldName = "";
				var unbind = Bind.bindAll(b, function (name) { name.should.be(fieldName); callNum ++; }, true);

				fieldName = "str";
				b.str = "123";
				fieldName = "str2";
				b.str2 = "123";
				fieldName = "bind";
				Bind.notify(b.bind);
				fieldName = "bind2";
				Bind.notify(b.bind2);

				callNum.should.be(4);

				unbind();

				b.str = "234";
				b.str2 = "234";
				Bind.notify(b.bind);
				Bind.notify(b.bind2);

				callNum.should.be(4);
			});

			it("bindx should bind all bindings (simple mode)", function () {
				var fieldName = "";
				var unbind = Bind.bindAll(b, function (name) { name.should.be(fieldName); callNum ++; }, false);

				b.str = "123";
				fieldName = "str2";
				b.str2 = "123";
				Bind.notify(b.bind);
				fieldName = "bind2";
				Bind.notify(b.bind2);

				callNum.should.be(2); // ignore lazy signals

				unbind();

				b.str = "234";
				b.str2 = "234";
				Bind.notify(b.bind);
				Bind.notify(b.bind2);

				callNum.should.be(2);
			});
			
			it("bindx should resolve typedefs", function () {
				var a:TypeBindable1 = new TypeBindable1();
				Bind.bind(a.str, function (_, _) {
					callNum ++;
				});
				
				a.str = "123";
				callNum.should.be(1);
			});
			
			it("bindx should resolve parametric types", function () {
				var b = new GenericBindable<TypeBindable1>();
				b.a = new TypeBindable1();
				Bind.bind(b.a.str, function (_, _) {
					callNum ++;
				});
				
				b.a.str = "123";
				callNum.should.be(1);
			});
		});
	}
}

//@:generic
class GenericBindable<A> {
	public var a:A;
	
	public function new() {}
}

typedef TypeBindable1 = Bindable1;

class Bindable1 implements bindx.IBindable {

	@:bindable(lazySignal=true)
	public var str:String;

	@:bindable(lazySignal=false)
	public var str2:String;

	@:bindable(lazySignal)
	public function bind() {
	}
	
	@:bindable(lazySignal=false)
	public function bind2() {
	}
	
	public function new() {
	}
}