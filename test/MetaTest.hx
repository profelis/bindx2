package ;

import bindx.Bind;
import bindx.IBindable;
import buddy.BuddySuite;

using buddy.Should;

class MetaTest extends BuddySuite {
    
    public function new() {
        
        describe("Using @bindable meta inheritance", function () {
            
            var b:BindableMeta;
            var callNum:Int;

            beforeEach(function () {
                b = new BindableMeta();
                callNum = 0;
            });
            
            it("bindx inherit metadata bindable for public fields", function () {
                b.str = "a";
                Bind.bind(b.str, function(_, _) callNum++);
                
                b.str = "b";
                callNum.should.be(1);
            });
            
            it("bindx inherit metadata bindable for public fields", function () {
                b.str2 = "a";
                Bind.bind(b.str2, function(_, _) callNum++);
                
                b.str2 = "b";
                callNum.should.be(1);
            });
            
            it("bindx inherit metadata params", function () {
                @:privateAccess b.strChanged.should.not.be(null);
                @:privateAccess b.str2Changed.should.not.be(null);
            });
            
        });
    }
}

@:bindable(lazySignal=false)
class BindableMeta implements IBindable {
    
    public var str:String;
    
    public var str2(get, set):String;
    
    function get_str2() return "";
    function set_str2(value) return value;
    
    public function new() {}
}