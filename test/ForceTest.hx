package ;

import bindx.Bind;
import bindx.IBindable;
import buddy.BuddySuite;

using buddy.Should;

class ForceTest extends BuddySuite {
    
    public function new() {
        
        describe("Using @:bindable(force=true)", {
            
            var b:BindableForce;
            var callNum:Int;
            
            before({
                b = new BindableForce();
                callNum = 0;
            });
            
            it("bindx should correct work with 'force' fields", {
                Bind.bind(b.str, function (_, _) callNum++);
                Bind.bind(b.str2, function (_, _) callNum++);
                Bind.bind(b.str3, function (_, _) callNum++);
                Bind.bind(b.str4, function (_, _) callNum++);
                Bind.bind(b.str5, function (_, _) callNum++);
                
                Bind.notify(b.str, "1", "2");
                Bind.notify(b.str2, "1", "2");
                Bind.notify(b.str3, "1", "2");
                Bind.notify(b.str4, "1", "2");
                Bind.notify(b.str5, "1", "2");
                
                callNum.should.be(5);
            });
            
        });
    }
}

@:bindable(force=true)
class BindableForce implements bindx.IBindable {

    public var str(default, never):String;
    
    public var str2(default, null):String;
    
    public var str3(default, dynamic):String;
    
    public var str4(null, never):String;
    
    public var str5(dynamic, null):String;
    
    public function new() {
    }
}