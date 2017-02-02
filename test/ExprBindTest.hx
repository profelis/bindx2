package ;

import bindx.Bind;
import bindx.BindExt;
import bindx.IBindable;
import buddy.BuddySuite;

using buddy.Should;

class ExprBindTest extends BuddySuite {
    
    public function new() {
        
        describe("Using BindExt.expr", function () {
            
            var callNum:Int;
            var from:String;
            var target:{a:String};
            beforeEach(function () {
                target = {a:null};
                from = null;
                callNum = 0;
            });
            
            it("BindExt.chain should bind simple expr", function () {
                var a = new BaseTest.Bindable1();
                var b = new BaseTest.Bindable1();
                a.str = "a1";
                b.str = "b1";
                inline function val() return b.str + '${"ab".charAt(a.str.length - 2)}${Std.string(1)}';
                
                BindExt.exprTo(b.str + '${"ab".charAt(a.str.length - 2)}${Std.string(1)}', target.a);
                BindExt.expr(b.str + '${"ab".charAt(a.str.length - 2)}${Std.string(1)}', function (f, to:String) {
                    f.should.be(from);
                    from = to;
                    to.should.be(val());
                    callNum ++;
                });
                
                target.a.should.be(val());
                callNum.should.be(1);
                
                a.str = "a2";
                
                target.a.should.be(val());
                callNum.should.be(2);
                
                b.str = "b2";
                
                target.a.should.be(val());
                callNum.should.be(3);
            });
            
            it("BindExt.chain should bind complex expresions", function () {
                var a = new BaseTest.Bindable1();
                var b = new BaseTest.Bindable1();
                var c = new BaseTest.Bindable1();
                a.str = "a1";
                b.str = "";
                c.str = "1";
                var target:{a:Null<Int>} = {a:null};
                inline function val() return if (a.str.charAt(b.str.length) == Std.string(c.str)) 1 else 0;
                var from:Null<Int> = null;
                
                BindExt.exprTo(if (a.str.charAt(b.str.length) == Std.string(c.str)) 1 else 0, target.a);
                BindExt.expr(if (a.str.charAt(b.str.length) == Std.string(c.str)) 1 else 0, function (f:Null<Int>, to:Null<Int>) {
                    (f == from).should.be(true); // f.should.be(from); cast f to Int
                    from = to;
                    to.should.be(val());
                    callNum ++;
                });
                
                target.a.should.be(val());
                callNum.should.be(1);
                
                b.str = "1";
                
                target.a.should.be(val());
                callNum.should.be(2);
                
                b.str = "";
                
                target.a.should.be(val());
                callNum.should.be(3);
                
                a.str = "b2";
                
                target.a.should.be(val());
                callNum.should.be(4);
                
                c.str = "b";
                
                target.a.should.be(val());
                callNum.should.be(5);
            });
            
        });
    }
}