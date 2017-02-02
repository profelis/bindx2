package bindx.macro;

import haxe.macro.Context;
import haxe.macro.Expr.Position;

@:enum abstract WarnPriority(Int) to Int from Int {
    var ALL = 2;
    var INFO = 1;
    var LOW = 0;

    @:op(a >= b) static function ge(a:WarnPriority, b:WarnPriority) return (a: Int) >= (b: Int);
    @:op(a > b) static function g(a:WarnPriority, b:WarnPriority) return (a: Int) > (b: Int);
    @:op(a < b) static function l(a:WarnPriority, b:WarnPriority) return (a: Int) < (b: Int);
    @:op(a <= b) static function le(a:WarnPriority, b:WarnPriority) return (a: Int) <= (b: Int);
}

class Warn {
    @:isVar static var level(get, null):WarnPriority = null;
    
    static function get_level():WarnPriority {
        if (Warn.level == null) {
            Warn.level = Context.defined("bindx_log") ? Std.parseInt(Context.definedValue("bindx_log")) : LOW;
        }
        return Warn.level;
    }
    
    public static function w(msg:String, pos:Position, level:WarnPriority) {
        if (Warn.level >= level)
            Context.warning(msg, pos);
    }
}

class FatalError extends GenericError {}

class GenericError {
    
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