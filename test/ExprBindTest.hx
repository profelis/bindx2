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
                inline function val() return a.str + b.str;
                
                BindExt.expr(a.str + b.str, function (from, to:String) {
                    //trace(from);
                    to.should.be(val());
                    callNum ++;
                });
                
                callNum.should.be(1);
                
                a.str = "a2";
                
                callNum.should.be(2);
            });
            
        });
    }
}