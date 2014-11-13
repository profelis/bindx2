package ;

import bindx.BindSignal;
import buddy.*;

using buddy.Should;

class SignalTest extends BuddySuite {

    public function new() {
        super();
    
        describe("FieldSignal functionality tests", {
            
            var fs:FieldSignal<String>;
            var callNum:Int;
            
            before({
                fs = new FieldSignal<String>();
                callNum = 0;
            });
            
            it("signal listeners should listen signal", {
                var f = "1";
                var t = "2";
                function listener(from:String, to:String) {
                    from.should.be(f);
                    to.should.be(t);
                    callNum ++;
                    fs.remove(listener);
                };
                var listener2 = function (from:String, to:String) {
                    from.should.be(f);
                    to.should.be(t);
                    callNum ++;
                };
                fs.add(listener);
                fs.add(listener);
                fs.add(listener2);
                
                fs.dispatch(f, t); // listener self-remove
                callNum.should.be(2);
                
                fs.dispatch(f, t);
                callNum.should.be(3);
                
                fs.removeAll();
                fs.dispatch(t, f);
                callNum.should.be(3);
            });
            
        });

        describe("MethodSignal functionality tests", {
            
            var ms:MethodSignal;
            var callNum:Int;
            
            before({
                ms = new MethodSignal();
                callNum = 0;
            });
            
            it("signal listeners should listen signal", {
                function listener() {
                    callNum ++;
                    ms.remove(listener);
                };
                var listener2 = function () {
                    callNum ++;
                };
                ms.add(listener);
                ms.add(listener);
                ms.add(listener2);
                
                ms.dispatch(); // listener self-remove
                callNum.should.be(2);
                
                ms.dispatch();
                callNum.should.be(3);
                
                ms.removeAll();
                ms.dispatch();
                callNum.should.be(3);
            });
            
        });
    }
}