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
            
            var val:String;
            var b:BindableChain;
            var b2:BindableChain;
            var callNum:Int;
            
            before({
                val = "a";
                b = new BindableChain(4);
                b2 = new BindableChain(4);
                callNum = 0;
            });
            
            it("BindExt.chain should bind chain changes (0 gap)", {
                b.c.c.f("tada").d = val;
                b2.c.c.f("tada").d = val;
                var unbind = BindExt.chain(b.c.c.f("tada").d, function (_, t:String) {
                    callNum++;
                    t.should.be(val);
                });
                
                callNum.should.be(1); // first auto call
                
                b.c.c.f("tada").d = val = "b";
                callNum.should.be(2); // bind
                
                val = b2.c.c.f("tada").d;
                b.c = b2.c;
                callNum.should.be(3);
                
                b.c.c = b2.c.c;
                callNum.should.be(3);
                
                unbind();
                b.c.c.f("tada").d = "c";
                callNum.should.be(3);
            });
            
            it("BindExt.chain should bind chain changes (1 gap)", {
                b.c.nc.c.f("tada").d = "a";
                var unbind = BindExt.chain(b.c.nc.c.f("tada").d, function (_, t:String) {
                    callNum++;
                    t.should.be(val);
                });
                
                callNum.should.be(1);
                
                b.c.nc.c.f("tada").d = val = "b";
                callNum.should.be(2);
                
                unbind();
                b.c.nc.c.f("tada").d = "c";
                callNum.should.be(2);
            });
            
            it("BindExt.chain should bind chain changes (double gap)", {
                b.c.d = "a";
                
                BindExt.chain(b.c.d, function (_, _) callNum++);
                
                callNum.should.be(1);
                
                b2.d = "b";
                b.c = b2;
                
                callNum.should.be(2);
            });
            
            it("BindExt.chain should bind default fields", {
                b.d = "a";
                
                var unbind = BindExt.chain(b.d, function (f:String, t:String) {
                    callNum ++;
                });
                
                b.d = "b";
                callNum.should.be(2);
                
                unbind();
                
                b.d = "c";
                callNum.should.be(2);
            });
            
        });
    }
}


class BindableChain implements bindx.IBindable {

    @:bindable
    public var d:String;
    
    public var nd:String;
    
    @:bindable
    public var c:BindableChain;
    
    public var nc:BindableChain;
    
    @:bindable
    public function f(s:String):BindableChain {
        return c;
    }
    
    public function new(depth:Int) {
        if (depth > 0) {
            c = new BindableChain(depth - 1);
            nc = new BindableChain(depth - 1);
        }
    }
}