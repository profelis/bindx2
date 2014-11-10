package bindx;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.Tools;
using bindx.MetaUtils;
using Lambda;
#end


@:access(bindx.BindMacros)
class Bind {

	@:noUsing macro static public function bind(field:Expr, listener:Expr):Expr {
		return _bind(field, listener, true);
	}

	@:noUsing macro static public function bindTo(field:Expr, target:Expr):Expr {
		return _bindTo(field, target);
	}

	@:noUsing macro static public function unbind(field:Expr, ?listener:Expr):Expr {
		return _bind(field, listener, false);
	}

	@:noUsing macro static public function notify(field:Expr, ?oldValue:Expr, ?newValue:Expr):Expr {
		return _notify(field, oldValue, newValue);
	}
    
    @:noUsing macro static public function disposeBindings(object:ExprOf<IBindable>):Expr {
        return _disposeBindings(object);
	}

	#if macro

	static function _bind(field:Expr, listener:Expr, doBind:Bool):Expr {
		var fieldData = checkField(field);
		return if (fieldData != null) {
			if (doBind) BindMacros.bindingSignalProvider.getClassFieldBindExpr(fieldData.e, fieldData.field, listener);
			else BindMacros.bindingSignalProvider.getClassFieldUnbindExpr(fieldData.e, fieldData.field, listener);
		} else macro {};
	}

	static function _bindTo(field:Expr, target:Expr):Expr {
		var fieldData = checkField(field);
		return BindMacros.bindingSignalProvider.getClassFieldBindToExpr(fieldData.e, fieldData.field, target);
	}

	static function _notify(field:Expr, ?oldValue:Expr, ?newValue:Expr):Expr {
		var fieldData = checkField(field);
		return BindMacros.bindingSignalProvider.getClassFieldChangedExpr(fieldData.e, fieldData.field, oldValue, newValue);
	}

	static function _disposeBindings(object:ExprOf<IBindable>):Expr {
        var type = Context.typeof(object).follow();
        if (!isBindable(type.getClass())) {
            Context.error('\'${object.toString()}\' must be bindx.IBindable', object.pos);
        }
		return BindMacros.bindingSignalProvider.getDisposeBindingsExpr(object, type);
	}

	static function checkField(field:Expr):{e:Expr, field:ClassField} {
		switch (field.expr) {
			case EField(e, field):
				var classType = Context.typeof(e).getClass();
				if (classType == null || !isBindable(classType)) {
					Context.error('\'${e.toString()}\' must be bindx.IBindable', e.pos);
					return null;
				}
				
				var field:ClassField = classType.findField(field, null);
				if (field == null) {
					Context.error('\'${e.toString()}.$field\' expected', field.pos);
					return null;
				}

				if (!field.hasBindableMeta()) {
					Context.error('\'${e.toString()}.$field\' is not bindable', field.pos);
					return null;
				}

				return {e:e, field:field};

            case EConst(CIdent(_)):
            	Context.error('can\'t bind \'${field.toString()}\'. Please use \'this.${field.toString()}\'', field.pos);

			case _:
				Context.error('can\'t bind field \'${field.toString()}\'', field.pos);
		}
		return null;
	}

	static var IBindableType = macro : bindx.IBindable;

	static function isBindable(classType:ClassType) {

		var t = classType;
		while (t != null) {
			for (it in t.interfaces) {
				var t = it.t.get();
				if (t.module == "bindx.IBindable" && t.name == "IBindable")
					return true;
			}
			t = t.superClass != null ? t.superClass.t.get() : null;
		}
		return false;
	}
	#end
}