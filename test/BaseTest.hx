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
			
			it ("bindx should bind/unbind properties", {
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
			
			it("bindx should bind/unbind 'null' values", {
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
			
			it("bindx should bind and notify methods", {
				var listener = function () callNum++;
				bind(b.bind, listener);
				Bind.notify(b.bind);
				
				callNum.should.be(1);
				
				Bind.unbind(b.bind, listener);
				Bind.notify(b.bind);
				
				callNum.should.be(1);
			});
			
			it("bindx should notify properties manual", {
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
			
			it("bindx should unbind all properties listeners", {
				bind(b.str, function (from, to) callNum++);
				bind(b.str, function (from, to) callNum++);
				
				Bind.unbind(b.str);
				b.str = b.str + "1";
				
				callNum.should.be(0);
			});
			
			it("bindx should unbind all method listeners");
			
			it("bindx should unbind all bindings (signal exists)", {
				bind(b.str, function (_, _) callNum++); // create binding signal
				bind(b.bind, function () callNum++);
				
				Bind.unbindAll(b);
				
				b.str = b.str + "1";
				b.bind();
				callNum.should.be(0);
			});
			
			it("bindx should unbind all bindings (signal expected)", {
				Bind.unbindAll(b);
				
				b.str = b.str + "1";
				Bind.notify(b.bind);
				callNum.should.be(0);
			});
		});
	}
}

@:bindable
class Bindable1 implements bindx.IBindable {

	@:bindable(lazySignal=true)
	public var str:String;

	@:bindable(lazySignal=false)
	public var str2:String;
	
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