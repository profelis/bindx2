package ;

import bindx.Bind;
import bindx.IBindable;
import buddy.BuddySuite;

using buddy.Should;

class InheritanceTest extends BuddySuite {
	public function new() {
		super();

        describe("Using classes inheritance", function () {
            var b:BindableChild;
            var bp:BindableParent;
            var callNum:Int;
            
            beforeEach(function () {
                b = new BindableChild();
                bp = new BindableParent();
                callNum = 0;
            });
            
            it("bindx should support class/interface inheritance", function () {
                b.i = 1;
                b.s = "a";
                Bind.bind(b.i, function (_, _) callNum++);
                Bind.bind(b.s, function (_, _) callNum++);
                
                b.i = 2;
                b.s = "b";
                callNum.should.be(2);
                
                bp.i = 1;
                Bind.bind(bp.i, function (_, _) callNum++);
                bp.i = 2;
                callNum.should.be(3);
            });

            it("bindx should support class inheritance for bindAll", function () {
                b.s = "a";
                Bind.bindAll(b, function (_, _, _) callNum++, true);
                b.s = "b";
                callNum.should.be(1);
                b.i = 1;
                callNum.should.be(2);
            });

            it("bindx should support class inheritance for unbindAll", function () {
                b.i = 1;
                b.s = "a";
                Bind.bind(b.i, function (_, _) callNum++);
                Bind.bind(b.s, function (_, _) callNum++);

                b.i = 2;
                b.s = "b";
                callNum.should.be(2);
                Bind.unbindAll(b);

                b.i = 3;
                b.s = "c";
                callNum.should.be(2);
            });
        });
    }
}

@:bindable
interface IIBindable extends IBindable {
    
    var i(default, set):Int;
}

interface IIIBindable extends IIBindable { }

class BindableParent implements IIIBindable {
	public function new() {}
    
    @:bindable
	public var i:Int;
}

@:bindable
class BindableChild extends BindableParent implements IIBindable {
	
	public var s:String;
}