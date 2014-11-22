package ;

import bindx.Bind;
import bindx.BindxExt;
import bindx.IBindable;
import buddy.BuddySuite;

using buddy.Should;

//@exclude
class ExprBindTest extends BuddySuite {
    
    public function new() {
        
        describe("Using BindExt.expr", {
            
            var callNum:Int;
            before({
                callNum = 0;
            });
            
            it("BindExt.chain should bind simple expr", {
                var a = new BaseTest.Bindable1();
                var b = new BaseTest.Bindable1();
                a.str = "a1";
                b.str = "b1";
                inline function val() return a.str + b.str + a.str.charAt(0) + "ab".charAt(0) + Std.string(1);
                
                BindExt.expr(a.str + b.str + a.str.charAt(0) + "ab".charAt(0) + Std.string(1), function (from, to:String) {
                    to.should.be(val());
                    callNum ++;
                });
                
                callNum.should.be(1);
                
                a.str = "a2";
                
                callNum.should.be(2);
                
                b.str = "b2";
                
                callNum.should.be(3);
            });
            
        });
    }
}