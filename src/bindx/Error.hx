package bindx;

import haxe.macro.Context;
import haxe.macro.Expr.Position;

@:enum abstract WarnPriority(Int) to Int from Int {
    var ALL = 2;
    var INFO = 1;
    var LOW = 0;
}

class Warn {
    static var level:WarnPriority = null;
    
    public static function w(msg:String, pos:Position, level:WarnPriority) {
        if (Warn.level == null) {
            Warn.level = Context.defined("bindx_log") ? Std.parseInt(Context.definedValue("bindx_log")) : LOW;
        }
        if ((Warn.level : Int) >= (level : Int))
            Context.warning(msg, pos);
    }
}

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