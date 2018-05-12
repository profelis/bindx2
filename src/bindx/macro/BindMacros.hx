package bindx.macro;

#if macro

import bindx.macro.GenericError;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.Tools;
using bindx.macro.MacroUtils;

@:access(bindx.macro.BindableMacros)
class BindMacros {

    static inline function bind(field:Expr, listener:Expr, doBind:Bool):Expr {
        var fieldData = warnCheckField(field);
        var bsp = BindableMacros.bindingSignalProvider;
        return if (doBind) bsp.getClassFieldBindExpr(fieldData.e, fieldData.field, listener);
        else bsp.getClassFieldUnbindExpr(fieldData.e, fieldData.field, listener);
    }

    static inline function bindTo(field:Expr, target:Expr):Expr {
        var fieldData = warnCheckField(field);
        return BindableMacros.bindingSignalProvider.getClassFieldBindToExpr(fieldData.e, fieldData.field, target);
    }

    static inline function notify(field:Expr, ?oldValue:Expr, ?newValue:Expr):Expr {
        var fieldData = warnCheckField(field);
        return BindableMacros.bindingSignalProvider.getClassFieldChangedExpr(fieldData.e, fieldData.field, oldValue, newValue);
    }

    static inline function unbindAll(object:ExprOf<IBindable>):Expr {
        var type = object.deepTypeof();
        if (!isBindable(type.getClass())) {
            Context.error('\'${object.toString()}\' must be bindx.IBindable', object.pos);
        }
        return BindableMacros.bindingSignalProvider.getUnbindAllExpr(object, type);
    }

    static inline function bindAll(object:ExprOf<IBindable>, listener:Expr, force:Bool = true):Expr {
        var type = object.deepTypeof();
        if (!isBindable(type.getClass())) {
            Context.error('\'${object.toString()}\' must be bindx.IBindable', object.pos);
        }
        return BindableMacros.bindingSignalProvider.getBindAllExpr(object, type, listener, force);
    }

    static inline function bindAllWithOrigin(object:ExprOf<IBindable>, listener:Expr, force:Bool = true):Expr {
        var type = object.deepTypeof();
        if (!isBindable(type.getClass())) {
            Context.error('\'${object.toString()}\' must be bindx.IBindable', object.pos);
        }
        return BindableMacros.bindingSignalProvider.getBindAllWithOriginExpr(object, type, listener, force);
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
                var type = e.deepTypeof();
                var classType = switch (type) { case TInst(c, _): c.get(); case _: null; };
                if (classType == null) {
                    error = new FatalError('Type \'${e.toString()}\' is unknown', e.pos);
                    return {e:f, field:null, error:error};
                }
                if (!isBindable(classType)) {
                    error = new GenericError('\'${e.toString()}\' must be bindx.IBindable', e.pos);
                }
                
                var classField = classType.findField(field, null);
                if (classField == null) {
                    throw new FatalError('\'${type.toString()}.${field}\' expected', e.pos);
                    return null;
                }

                if (!classField.hasBindableMeta()) {
                    error = new GenericError('\'${type.toString()}.${classField.name}\' is not bindable', classField.pos);
                }

                return {e:e, field:classField, error:error};

            case EConst(CIdent(_)):
                return {e:f, field:null, error:new GenericError('Can\'t bind \'${f.toString()}\'. Please use \'this.${f.toString()}\'', f.pos)};

            case _:
        }
        return {e:f, field:null, error:new GenericError('\'${f.toString()}\' is not bindable', f.pos)};
    }
    
    static inline function isBindable(classType:ClassType):Bool {
        var check = [classType];
        var res = false;
        while (!res && check.length > 0) {
            var t = check.shift();
            while (!res && t != null) {
                switch t {
                    case {module: "bindx.IBindable", name: "IBindable"}: res = true;
                    case _:
                        for (it in t.interfaces) check.push(it.t.get());
                        t = t.superClass != null ? t.superClass.t.get() : null;
                }
            }
        }
        return res;
    }
}
#end