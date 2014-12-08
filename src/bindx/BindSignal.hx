package bindx;

#if macro

import bindx.BindSignal.BindSignalProvider;
import bindx.BindSignal.Signal;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.rtti.Meta;

using bindx.MetaUtils;
using haxe.macro.Tools;
using Lambda;

class BindSignalProvider implements IBindingSignalProvider {

    static inline var SIGNAL_POSTFIX = "Changed";

    /**
     * default value: true
     */
    static inline var LAZY_SIGNAL = "lazySignal";
    /**
     * default value: false
     */
    static inline var INLINE_SIGNAL_GETTER = "inlineSignalGetter";
    
    static inline var BIND_SIGNAL_META = "BindSignal";

    public function new() {}

    @:extern static inline function signalName(fieldName:String):String return fieldName + SIGNAL_POSTFIX;
    @:extern static inline function signalGetterName(fieldName:String):String return "get_" + signalName(fieldName);
    @:extern static inline function signalPrivateName(fieldName:String):String return "_" + signalName(fieldName);

    public function getFieldDispatcher(field:Field, res:Array<Field>):Void {
        switch (field.kind) {
            case FFun(_):
                generateSignal(field, macro : bindx.BindSignal.MethodSignal, macro new bindx.BindSignal.MethodSignal(), res);
            case FProp(_, _, type, _) | FVar(type, _):
                generateSignal(field, macro : bindx.BindSignal.FieldSignal<$type>, macro new bindx.BindSignal.FieldSignal<$type>(), res);
        }
    }

    public function getFieldChangedExpr(field:Field, oldValue:Expr, newValue:Expr):Expr {
        var args = switch (field.kind) { case FFun(_): []; case _: [oldValue, newValue]; }
        return dispatchSignal(macro this, field.name, args, hasLazy(field.bindableMeta()));
    }

    public function getClassFieldBindExpr(expr:Expr, field:ClassField, listener:Expr):Expr {
        var signalName = signalName(field.name);
        return macro @:privateAccess $expr.$signalName.add($listener);
    }

    public function getClassFieldBindToExpr(expr:Expr, field:ClassField, target:Expr):Expr {
        var signalName = signalName(field.name);
        return switch (field.kind) {
            case FMethod(_):
                var fieldName = field.name;
                macro {
                    var listener = function () $target = $expr.$fieldName();
                    $expr.$signalName.add(listener);
                    function __unbind__() $expr.$signalName.remove(listener);
                }
            case FVar(_, _):
                var type = field.type.follow().toComplexType();
                macro {
                    var listener = function (from:$type, to:$type) $target = to;
                    $expr.$signalName.add(listener);
                    function __unbind__() $expr.$signalName.remove(listener);
                }
            }
    }

    public function getClassFieldUnbindExpr(expr:Expr, field:ClassField, listener:Expr):Expr {
        var signalName = signalName(field.name);
        return if (!isNull(listener))
            macro @:privateAccess $expr.$signalName.remove($listener);
        else
            macro @:privateAccess $expr.$signalName.removeAll();
    }

    public function getClassFieldChangedExpr(expr:Expr, field:ClassField, oldValue:Expr, newValue:Expr):Expr {
        var args = switch (field.kind) {
            case FMethod(_): 
                if (!isNull(oldValue))
                    Context.error("method notify doesn't require oldValue", oldValue.pos);
                if (!isNull(newValue))
                    Context.error("method notify doesn't require newValue", newValue.pos);
                [];
            case FVar(_, _):
                [oldValue, newValue];
        }
        return dispatchSignal(expr, field.name, args, hasLazy(field.bindableMeta()));
    }
    
    public function getUnbindAllExpr(expr:ExprOf<IBindable>, type:Type):Expr {
        return macro {
            var meta = haxe.rtti.Meta.getFields(std.Type.getClass($expr));
            if (meta != null) for (m in std.Reflect.fields(meta)) {
                var data:Dynamic<String> = std.Reflect.field(meta, m);
                if (std.Reflect.hasField(data, $v{BIND_SIGNAL_META})) {
                    var signal:bindx.BindSignal.Signal<Dynamic> = cast Reflect.field($expr, m);
                    if (signal != null)
                        signal.removeAll();
                }
            }
        }
    }

    function generateSignal(field:Field, type:ComplexType, builder:Expr, res:Array<Field>):Void {
        var signalName = signalName(field.name);
        var meta = field.bindableMeta();
        var inlineSignalGetter = meta.findParam(INLINE_SIGNAL_GETTER);

        if (hasLazy(meta)) {
            var signalPrivateName = signalPrivateName(field.name);
            res.push({
                name: signalPrivateName,
                kind: FVar(type, null),
                pos: field.pos,
                meta: [ { name:BIND_SIGNAL_META, pos:field.pos } ],
                access: [APrivate]
            });

            res.push({
                name: signalName,
                kind: FProp("get", "never", type, null),
                pos: field.pos,
                access: [APrivate],
            });

            var getter = macro function foo() {
                if (this.$signalPrivateName == null)
                    this.$signalPrivateName = ${builder};
                return $i{signalPrivateName};
            };
            var getterAccess = [APrivate];
            if (inlineSignalGetter.isNotNullAndTrue()) getterAccess.push(AInline);

            res.push({
                name: signalGetterName(field.name),
                kind: FFun(switch (getter.expr) { case EFunction (_, func): func; case _: throw false; }),
                pos: field.pos,
                access: getterAccess
            });
        } else {
            if (inlineSignalGetter != null)
                Context.warning('$INLINE_SIGNAL_GETTER works only with lazy signals', inlineSignalGetter.pos);

            res.push({
                name: signalName,
                kind: FProp("default", "null", type, builder),
                pos: field.pos,
                access: [APrivate],
                meta: [ { name:BIND_SIGNAL_META, pos:field.pos } ]
            });
        }
    }

    inline function dispatchSignal(expr:Expr, fieldName:String, args:Array<Expr>, lazy:Bool):Expr {
        return 
            if (lazy) {
                var signalPrivateName = signalPrivateName(fieldName);
                macro @:privateAccess {
                    if ($expr.$signalPrivateName != null)
                        $expr.$signalPrivateName.dispatch($a { args } );
                }
            } else {
                var signalName = signalName(fieldName);
                macro @:privateAccess $expr.$signalName.dispatch($a { args } );
            }
    }

    @:extern inline function hasLazy(meta:MetadataEntry):Bool {
        return meta.findParam(LAZY_SIGNAL).isNullOrTrue();
    }
    
    @:extern inline function isNull(expr:Expr):Bool {
        return expr == null || expr.expr.match(EConst(CIdent("null")));
    }
}

#end

class MethodSignal extends Signal<Void -> Void> {

    public function dispatch():Void {
        lock ++;
        for (l in listeners) l();
        if (lock > 0) lock --;
    }
}

class FieldSignal<T> extends Signal<T -> T -> Void> {

    public function dispatch(oldValue:T = null, newValue:T = null):Void {
        lock ++;
        var ls = listeners;
        for (l in ls) l(oldValue, newValue);
        if (lock > 0) lock --;
    }
}

class Signal<T> {

    var listeners:Array<T>;

    var lock:Int = 0;

    public function new() {
        removeAll();
    }

    public inline function removeAll():Void {
        listeners = [];
        lock = 0;
    }
    
    inline function indexOf(listener:T):Int {
        #if (neko || bindx_compareMethods)
            var res = -1;
            var i = 0;
            for (l in listeners) {
                if (Reflect.compareMethods(listener, l)) {
                    res = i;
                    break;
                }
                i++;
            }
            return res;
        #else
            return listeners.indexOf(listener);
        #end
    }

    public function add(listener:T):Void {
        var pos = indexOf(listener);
        checkLock();
        if (pos > -1) listeners.splice(pos, 1);
        listeners.push(listener);
    }

    public function remove(listener:T):Void {
        var pos = indexOf(listener);
        if (pos > -1) {
            checkLock();
            listeners.splice(pos, 1);
        }
    }

    inline function checkLock():Void {
        if (lock > 0) {
            listeners = listeners.copy();
            lock = 0;
        }
    }
}