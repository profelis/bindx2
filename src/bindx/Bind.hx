package bindx;

#if macro
import bindx.Error;
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
		return internalBind(field, listener, true);
	}

	@:noUsing macro static public function bindTo(field:Expr, target:Expr):Expr {
		return internalBindTo(field, target);
	}

	@:noUsing macro static public function unbind(field:Expr, ?listener:Expr):Expr {
		return internalBind(field, listener, false);
	}

	@:noUsing macro static public function notify(field:Expr, ?oldValue:Expr, ?newValue:Expr):Expr {
		return internalNotify(field, oldValue, newValue);
	}
    
    @:noUsing macro static public function unbindAll(object:ExprOf<IBindable>):Expr {
        return internalUnbindAll(object);
    }

	#if macro

	static function internalBind(field:Expr, listener:Expr, doBind:Bool):Expr {
		var fieldData = warnCheckField(field);
		return if (doBind) BindMacros.bindingSignalProvider.getClassFieldBindExpr(fieldData.e, fieldData.field, listener);
		else BindMacros.bindingSignalProvider.getClassFieldUnbindExpr(fieldData.e, fieldData.field, listener);
	}

	static function internalBindTo(field:Expr, target:Expr):Expr {
		var fieldData = warnCheckField(field);
		return BindMacros.bindingSignalProvider.getClassFieldBindToExpr(fieldData.e, fieldData.field, target);
	}

	static function internalNotify(field:Expr, ?oldValue:Expr, ?newValue:Expr):Expr {
		var fieldData = warnCheckField(field);
		return BindMacros.bindingSignalProvider.getClassFieldChangedExpr(fieldData.e, fieldData.field, oldValue, newValue);
	}

	static function internalUnbindAll(object:ExprOf<IBindable>):Expr {
        var type = Context.typeof(object).follow();
        if (!isBindable(type.getClass())) {
            Context.error('\'${object.toString()}\' must be bindx.IBindable', object.pos);
        }
		return BindMacros.bindingSignalProvider.getUnbindAllExpr(object, type);
	}

	static function warnCheckField(field:Expr):{e:Expr, field:ClassField} {
		var res = null;
		try {
			res = checkField(field);
			if (res.error != null) throw res.error;
		} catch (e:FatalError) {
			e.contextFatal();
		} catch (e:bindx.Error) { 
			e.contextError();
		};
		return res;
	}
	
	static function checkField(f:Expr):{e:Expr, field:ClassField, error:bindx.Error} {
		var error:bindx.Error;
		switch (f.expr) {
			case EField(e, field):
				var type = Context.typeof(e);
				var classType = switch (type) { case TInst(c, _): c.get(); case _: null; };
				if (classType == null) {
					error = new FatalError('Type \'${e.toString()}\' is unknown', e.pos);
					return {e:f, field:null, error:error};
				}
				if (!isBindable(classType)) {
					error = new bindx.Error('\'${e.toString()}\' must be bindx.IBindable', e.pos);
				}
				
				var field:ClassField = classType.findField(field, null);
				if (field == null) {
					throw new FatalError('\'${e.toString()}.${field.name}\' expected', field.pos);
					return null;
				}

				if (!field.hasBindableMeta()) {
					error = new bindx.Error('\'${e.toString()}.${field.name}\' is not bindable', field.pos);
				}

				return {e:e, field:field, error:error};

            case EConst(CIdent(_)):
            	return {e:f, field:null, error:new bindx.Error('Can\'t bind \'${f.toString()}\'. Please use \'this.${f.toString()}\'', f.pos)};

			case _:
		}
		return {e:f, field:null, error:new bindx.Error('\'${f.toString()}\' is not bindable', f.pos)};
	}
	
	static function isBindable(classType:ClassType):Bool {
		var check = [classType];
		while (check.length > 0) {
			var t = check.shift();
			while (t != null) {
				if (t.module == "bindx.IBindable" && t.name == "IBindable")
            		return true;
				for (it in t.interfaces)
	                check.push(it.t.get());
				t = t.superClass != null ? t.superClass.t.get() : null;
			}
		}
		return false;
	}
	#end
}