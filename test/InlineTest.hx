package ;

import bindx.Bind;
import bindx.IBindable;
import buddy.BuddySuite;

using buddy.Should;

class InlineTest extends BuddySuite {
    
    public function new() {
        
        describe("Using @:bindable(inlineSetter=true/false, inlineSignalGetter=true/false)", {
            
            it("bindx should generate inline setter");
            it("bindx should generate inline signal getter");
            
        });
    }
}