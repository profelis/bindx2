package bindx;

import haxe.macro.Expr;
import bindx.macro.BindMacros;

@:access(bindx.macro.BindMacros)
class Bind {

	@:noUsing macro static public function bind(field:Expr, listener:Expr):Expr {
		return BindMacros.bind(field, listener, true);
	}

	@:noUsing macro static public function bindTo(field:Expr, target:Expr):Expr {
		return BindMacros.bindTo(field, target);
	}

	@:noUsing macro static public function unbind(field:Expr, ?listener:Expr):Expr {
		return BindMacros.bind(field, listener, false);
	}

	@:noUsing macro static public function notify(field:Expr, ?oldValue:Expr, ?newValue:Expr):Expr {
		return BindMacros.notify(field, oldValue, newValue);
	}
    
    @:noUsing macro static public function unbindAll(object:ExprOf<IBindable>):Expr {
        return BindMacros.unbindAll(object);
    }
}