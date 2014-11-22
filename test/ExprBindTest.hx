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
                inline function val() return b.str + "ab".charAt(a.str.length - 2) + Std.string(1);
                
                BindExt.expr(b.str + "ab".charAt(a.str.length - 2) + Std.string(1), function (from, to:String) {
                    to.should.be(val());
                    callNum ++;
                });
                
                callNum.should.be(1);
                
                a.str = "a2";
                
                callNum.should.be(2);
                
                b.str = "b2";
                
                callNum.should.be(3);
            });
            
            it("BindExt.chain should bind complex expresions", {
                var a = new BaseTest.Bindable1();
                var b = new BaseTest.Bindable1();
                var c = new BaseTest.Bindable1();
                a.str = "a1";
                b.str = "";
                c.str = "1";
                inline function val() return if (a.str.charAt(b.str.length) == Std.string(c.str)) 1 else 0;
                
                BindExt.expr(if (a.str.charAt(b.str.length) == Std.string(c.str)) 1 else 0, function (from, to:Null<Int>) {
                    to.should.be(val());
                    callNum ++;
                });
                
                callNum.should.be(1);
                
                b.str = "1";
                
                callNum.should.be(2);
                
                b.str = "";
                
                callNum.should.be(3);
                
                a.str = "b2";
                
                callNum.should.be(4);
                
                c.str = "b";
                
                callNum.should.be(5);
            });
            
        });
    }
}