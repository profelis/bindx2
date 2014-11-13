package ;

import bindx.Bind;
import bindx.IBindable;
import buddy.BuddySuite;

using buddy.Should;

class MetaTest extends BuddySuite {
    
    public function new() {
        
        describe("Using @bindable meta inheritance", {
            
            var b:BindableMeta;
            var callNum:Int;
            
            before({
                b = new BindableMeta();
                callNum = 0;
            });
            
            it("bindx inherit metadata bindable for public fields", {
                b.str = "a";
                Bind.bind(b.str, function(_, _) callNum++);
                
                b.str = "b";
                callNum.should.be(1);
            });
            
            it("bindx inherit metadata bindable for public fields", {
                b.str2 = "a";
                Bind.bind(b.str2, function(_, _) callNum++);
                
                b.str2 = "b";
                callNum.should.be(1);
            });
            
            it("bindx inherit metadata params", {
                Reflect.hasField(b, "strChanged").should.be(true); // lazySignal=false
                Reflect.hasField(b, "str2Changed").should.be(true); // lazySignal=false
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