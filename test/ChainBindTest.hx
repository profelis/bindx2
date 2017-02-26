package ;

import bindx.Bind;
import bindx.BindExt;
import bindx.IBindable;
import buddy.BuddySuite;

using buddy.Should;

class ChainBindTest extends BuddySuite {
    
    public function new() {
        
        describe("Using BindExt.chain", function () {
            
            var from:String;
            var val:String;
            var b:BindableChain;
            var callNum:Int;
            var target:{a:String};

            beforeEach(function () {
                from = null;
                val = "a";
                b = new BindableChain(4);
                target = { a: null };
                callNum = 0;
            });
            
            it("BindExt.chain should bind chain changes (unset links)", function () {
                b.c.c.d = val;
                
                var listener = function (f:String, t:String) {
                    callNum++;
                    f.should.be(from);
                    from = val;
                    t.should.be(val);
                };
                var unbind = BindExt.chain(b.c.c.d, listener);
                BindExt.chainTo(b.c.c.d, target.a);
                
                callNum.should.be(1);
                
                val = null;
                b.c = null;
                
                target.a.should.be(val);
                callNum.should.be(2);
                
                b.c = new BindableChain(2);
                target.a.should.be(val);
                callNum.should.be(3); // d null value change to null value
                
                b.c.c.d = val = "b";
                callNum.should.be(4);
                
                val = null;
                b.c.c = null;
                
                target.a.should.be(val);
                callNum.should.be(5);

                unbind();
            });
            
            it("BindExt.chain should bind chain changes (null links)", function () {
                b.c = null;
                val = null;
                
                var unbind = BindExt.chain(b.c.c.d, function (f:String, t:String) {
                    callNum++;
                    f.should.be(from);
                    from = val;
                    t.should.be(val);
                });
                BindExt.chainTo(b.c.c.d, target.a);
                target.a.should.be(val);
                callNum.should.be(1);
                
                b.c = new BindableChain(2);
                target.a.should.be(val);
                callNum.should.be(2);
                
                b.c.c.d = val = "b";
                target.a.should.be(val);
                callNum.should.be(3);

                unbind();
            });
            
            it("BindExt.chain should bind chain changes (0 gap)", function () {
                var b2 = new BindableChain(4);
                b.c.c.f("tada").d = val;
                b2.c.c.f("tada").d = val;
                
                var unbind = BindExt.chain(b.c.c.f("tada").d, function (f:String, t:String) {
                    f.should.be(from);
                    from = val;
                    t.should.be(val);
                    callNum++;
                });
                var unbind2 = BindExt.chainTo(b.c.c.f("tada").d, target.a);
                callNum.should.be(1); // first auto call
                
                b.c.c.f("tada").d = val = "b";
                target.a.should.be(val);
                callNum.should.be(2); // bind
                
                val = b2.c.c.f("tada").d;
                b.c = b2.c;
                target.a.should.be(val);
                callNum.should.be(3);
                
                b.c.c = b2.c.c;
                callNum.should.be(3);
                
                Bind.notify(b.c.c.f);
                target.a.should.be(val);
                callNum.should.be(4);
                
                unbind();
                unbind2();
                b.c.c.f("tada").d = "c";
                target.a.should.be(val);
                callNum.should.be(4);
            });
            
            it("BindExt.chain should bind chain changes (1 gap)", function () {
                b.c.nc.c.f("tada").d = "a";
                var unbind = BindExt.chain(b.c.nc.c.f("tada").d, function (f:String, t:String) {
                    f.should.be(from);
                    from = val;
                    t.should.be(val);
                    callNum++;
                });
                var unbind2 = BindExt.chainTo(b.c.nc.c.f("tada").d, target.a);
                
                target.a.should.be(val);
                callNum.should.be(1);
                
                b.c.nc.c.f("tada").d = val = "b"; // nc gap
                from = val;
                target.a.should.not.be(val);
                callNum.should.be(1);
                
                var b2 = new BindableChain(4);
                b2.c.nc.c.f("tada").d = val = "c";
                var t = b.c;
                b.c = b2.c; // bind works
                
                target.a.should.be(val);
                callNum.should.be(2);
                
                val = t.nc.c.f("tada").d;
                b.c = t; // bind works
                
                target.a.should.be(val);
                callNum.should.be(3);
                
                b2.c.nc.c.f("tada").d = val = "d";
                
                b.c.nc.c = b2.c.nc.c; // nc gap
                target.a.should.not.be(val);
                callNum.should.be(3);
                
                unbind();
                unbind2();
                b.c.nc.c.f("tada").d = "c"; // nc gap
                target.a.should.not.be(val);
                callNum.should.be(3);
            });
            
            it("BindExt.chain should bind chain changes (double gap)", function () {
                b.c.nc.nc.d = "a";
                
                BindExt.chain(b.c.nc.nc.d, function (f, t:String) {
                    f.should.be(from);
                    from = val;
                    t.should.be(val);
                    callNum++;
                });
                
                callNum.should.be(1);
                
                var b2 = new BindableChain(2);
                b2.d = "b";
                b.c.nc.nc = b2;
                
                callNum.should.be(1);
                
                b2 = new BindableChain(3);
                b2.nc.d = "c";
                b.c.nc = b2;
                
                callNum.should.be(1);
                
                b.c.nc.nc.d = val = "d";
                from = val;
                callNum.should.be(1);
                
                b2 = new BindableChain(3);
                b2.nc.nc.d = val = "e";
                b.c = b2;
                
                callNum.should.be(2);
                
                Bind.notify(b.c.nc.nc.d, val, val = "f");
                
                callNum.should.be(2);
            });
            
            it("BindExt.chain should bind default fields", function () {
                b.d = val = "a";
                
                var unbind = BindExt.chain(b.d, function (f:String, t:String) {
                    f.should.be(from);
                    from = val;
                    t.should.be(val);
                    callNum ++;
                });
                var unbind2 = BindExt.chainTo(b.d, target.a);
                
                b.d = val = "b";
                
                target.a.should.be(val);
                callNum.should.be(2);
                
                unbind();
                unbind2();
                
                b.d = "c";
                target.a.should.be(val);
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
        return s == "tada" ? c : null;
    }
    
    public function nf(s:String):BindableChain {
        return s == "tada" ? nc : null;
    }
    
    public function new(depth:Int) {
        if (depth > 0) {
            c = new BindableChain(depth - 1);
            nc = new BindableChain(depth - 1);
        }
    }
}