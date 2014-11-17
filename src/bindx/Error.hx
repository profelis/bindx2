package bindx;

import haxe.macro.Context;
import haxe.macro.Expr.Position;

class FatalError extends Error {}

class Error {
    
    public var pos(default, null):Position;
    public var message(default, null):String;
    
    public function new(message:String, pos:Position) {
        this.message = message;
        this.pos = pos;
    }
    
    public function contextError():Void {
        Context.error(message, pos);
    }
    
    public function contextWarning():Void {
        Context.warning(message, pos);
    }
    
    public function contextFatal():Void {
        Context.fatalError(message, pos);
    }
}