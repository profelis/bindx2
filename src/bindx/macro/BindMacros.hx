package bindx.macro;

#if macro

import bindx.macro.GenericError;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.Tools;
using bindx.macro.MetaUtils;
using Lambda;

@:access(bindx.macro.BindableMacros)
class BindMacros {

    static inline function internalBind(field:Expr, listener:Expr, doBind:Bool):Expr {
        var fieldData = warnCheckField(field);
        return if (doBind) BindableMacros.bindingSignalProvider.getClassFieldBindExpr(fieldData.e, fieldData.field, listener);
        else BindableMacros.bindingSignalProvider.getClassFieldUnbindExpr(fieldData.e, fieldData.field, listener);
    }

    static inline function internalBindTo(field:Expr, target:Expr):Expr {
        var fieldData = warnCheckField(field);
        return BindableMacros.bindingSignalProvider.getClassFieldBindToExpr(fieldData.e, fieldData.field, target);
    }

    static inline function internalNotify(field:Expr, ?oldValue:Expr, ?newValue:Expr):Expr {
        var fieldData = warnCheckField(field);
        return BindableMacros.bindingSignalProvider.getClassFieldChangedExpr(fieldData.e, fieldData.field, oldValue, newValue);
    }

    static inline function internalUnbindAll(object:ExprOf<IBindable>):Expr {
        var type = Context.typeof(object).follow();
        if (!isBindable(type.getClass())) {
            Context.error('\'${object.toString()}\' must be bindx.IBindable', object.pos);
        }
        return BindableMacros.bindingSignalProvider.getUnbindAllExpr(object, type);
    }

    static inline function warnCheckField(field:Expr):{e:Expr, field:ClassField} {
        var res = null;
        try {
            res = checkField(field);
            if (res.error != null) res.error.contextError();
        } catch (e:FatalError) {
            e.contextFatal();
        } catch (e:GenericError) { 
            e.contextError();
        };
        return res;
    }
    
    static function checkField(f:Expr):{e:Expr, field:ClassField, error:GenericError} {
        var error:GenericError = null;
        switch (f.expr) {
            case EField(e, field):
                var type = Context.typeof(e);
                var classType = switch (type) { case TInst(c, _): c.get(); case _: null; };
                if (classType == null) {
                    error = new FatalError('Type \'${e.toString()}\' is unknown', e.pos);
                    return {e:f, field:null, error:error};
                }
                if (!isBindable(classType)) {
                    error = new GenericError('\'${e.toString()}\' must be bindx.IBindable', e.pos);
                }
                
                var field = classType.findField(field, null);
                if (field == null) {
                    throw new FatalError('\'${e.toString()}.${field.name}\' expected', field.pos);
                    return null;
                }

                if (!field.hasBindableMeta()) {
                    error = new GenericError('\'${e.toString()}.${field.name}\' is not bindable', field.pos);
                }

                return {e:e, field:field, error:error};

            case EConst(CIdent(_)):
                return {e:f, field:null, error:new GenericError('Can\'t bind \'${f.toString()}\'. Please use \'this.${f.toString()}\'', f.pos)};

            case _:
        }
        return {e:f, field:null, error:new GenericError('\'${f.toString()}\' is not bindable', f.pos)};
    }
    
    static inline function isBindable(classType:ClassType):Bool {
        var check = [classType];
        var res = false;
        while (check.length > 0 && !res) {
            var t = check.shift();
            while (t != null) {
                if (t.module == "bindx.IBindable" && t.name == "IBindable") {
                    res = true;
                    break;
                }
                for (it in t.interfaces)
                    check.push(it.t.get());
                t = t.superClass != null ? t.superClass.t.get() : null;
            }
        }
        return res;
    }
}
#end