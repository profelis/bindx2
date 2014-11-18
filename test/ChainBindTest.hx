package ;

import bindx.Bind;
import bindx.BindxExt;
import bindx.IBindable;
import buddy.BuddySuite;

using buddy.Should;

//@exclude
class ChainBindTest extends BuddySuite {
    
    public function new() {
        
        describe("Using BindExt.chain", {
            
            var b:BindableChain;
            var callNum:Int;
            
            before({
                b = new BindableChain();
                b.c = new BindableChain();
                callNum = 0;
            });
            
            it("BindExt.chain should bind chain changes", {
                b.c.f("tada").d = "a";
                BindExt.chain(b.c.f("tada").d, function (_, _) callNum++);
                
                b.c.f("tada").d = "b";
                callNum.should.be(1);
            });
            
        });
    }
}


class BindableChain implements bindx.IBindable {

    @:bindable
    public var d:String;
    
    public var nd:String;
    
    public var c:BindableChain;
    
    @:bindable
    public function f(s:String):BindableChain {
        return c;
    }
    
    public function new() {
    }
}