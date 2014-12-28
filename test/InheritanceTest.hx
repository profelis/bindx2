package ;

import bindx.Bind;
import bindx.IBindable;
import buddy.BuddySuite;

using buddy.Should;

class InheritanceTest extends BuddySuite {
	public function new() {
		super();

        describe("Using classes inheritance", {
            var b:BindableChild;
            var bp:BindableParent;
            var callNum:Int;
            
            before({
                b = new BindableChild();
                bp = new BindableParent();
                callNum = 0;
            });
            
            it("bindx should support class/interface inheritance", {
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
        });
    }
}

interface IIBindable extends IBindable {
    @:bindable
    var i(default, set):Int;
}

class BindableParent implements IIBindable {
	public function new() {}
    
    @:bindable
	public var i:Int;
}

@:bindable
class BindableChild extends BindableParent {
	
	public var s:String;
}