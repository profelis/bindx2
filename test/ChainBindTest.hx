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
                b.c.c = new BindableChain();
                callNum = 0;
            });
            
            it("BindExt.chain should bind chain changes (1 gap)", {
                b.c.f("tada").d = "a";
                var unbind = BindExt.chain(b.c.f("tada").d, function (_, t:String) {
                    callNum++;
                    t.should.be(b.c.f("tada").d);
                });
                
                callNum.should.be(1);
                
                b.c.f("tada").d = "b";
                callNum.should.be(2);
                
                unbind();
                b.c.f("tada").d = "c";
                callNum.should.be(2);
            });
            
            it("BindExt.chain should bind chain changes (double gap)", {
                b.c.c.d = "a";
                
                BindExt.chain(b.c.c.d, function (_, _) callNum++);
                
                callNum.should.be(1);
                
                BindExt.chain(b.c.c.c.d, function (_, _) callNum++ );
                
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