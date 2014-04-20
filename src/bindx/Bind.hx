package bindx;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.Tools;
using bindx.MetaUtils;
#end
using Lambda;

class Bind {

	@:noUsing macro static public function bindx(field:Expr, listener:Expr):Expr {
		return bind(field, listener, true);
	}

	@:noUsing macro static public function bindTo(field:Expr, target:Expr):Expr {
		var fieldData = checkField(field);
		return BindMacros.bindingSignalProvider.getClassFieldBindToExpr(fieldData.e, fieldData.field, target);
	}

	@:noUsing macro static public function unbindx(field:Expr, listener:Expr):Expr {
		return bind(field, listener, false);
	}

	@:noUsing macro static public function notify(field:Expr, ?oldValue:Expr, ?newValue:Expr):Expr {
		var fieldData = checkField(field);
		return BindMacros.bindingSignalProvider.getClassFieldChangedExpr(fieldData.e, fieldData.field, oldValue, newValue);
	}

	#if macro
	static function bind(field:Expr, listener:Expr, doBind:Bool):Expr {
		var fieldData = checkField(field);
		return if (fieldData != null) {
			if (doBind) BindMacros.bindingSignalProvider.getClassFieldBindExpr(fieldData.e, fieldData.field, listener);
			else BindMacros.bindingSignalProvider.getClassFieldUnbindExpr(fieldData.e, fieldData.field, listener);
		} else macro {};
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

	static inline function isBindable(classType:ClassType) {
		return classType.interfaces.exists(function (it) {
			var t = it.t.get();
			return t.module == "bindx.IBindable" && t.name == "IBindable";
		});
	}
	#end
}