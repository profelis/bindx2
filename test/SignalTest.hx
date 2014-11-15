package ;

import bindx.BindSignal;
import buddy.*;

using buddy.Should;

class SignalTest extends BuddySuite {

    public function new() {
        super();
    
        describe("Using BindSignal", {
            
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
            
            it("signal should correct add/remove listeners", {
                function listener2(_, _) {
                    callNum ++;
                }
                
                function listener(_, _) {
                    fs.add(listener2);
                    callNum++;
                }
                
                fs.add(listener);
                fs.dispatch(null, null);
                
                callNum.should.be(1); // 1 listener only
                
                fs.dispatch(null, null);
                
                callNum.should.be(3); // listener2 added
                
                fs.remove(listener2);
                fs.dispatch(null, null);
                
                callNum.should.be(4); // listener2 removed
                
                fs.removeAll();
                fs.dispatch(null, null);
                
                callNum.should.be(4); // all listeners removed
            });
            
            it("signal should correct dispatch in listener", {
                function listener(_, _) {
                    fs.remove(listener);
                    fs.dispatch(null, null);
                    callNum++;
                }
                var callNum2 = 0;
                function listener2(_, _) callNum2++;
                
                fs.add(listener);
                fs.add(listener2);
                fs.dispatch(null, null);
                
                callNum.should.be(1);
                callNum2.should.be(2);
            });
        });

        describe("Using MethodSignal", {
            
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