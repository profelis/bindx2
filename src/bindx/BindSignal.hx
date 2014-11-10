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

    @:expose static inline function signalName(fieldName:String) return fieldName + SIGNAL_POSTFIX;
    @:expose static inline function signalGetterName(fieldName:String) return "get_" + signalName(fieldName);
    @:expose static inline function signalPrivateName(fieldName:String) return "_" + signalName(fieldName);

    public function getFieldDispatcher(field:Field, res:Array<Field>) {
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
        return macro $expr.$signalName.add($listener);
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
                macro {
                    var listener = function (from, to) $target = to;
                    $expr.$signalName.add(listener);
                    function __unbind__() $expr.$signalName.remove(listener);
                }
            }
    }

    public function getClassFieldUnbindExpr(expr:Expr, field:ClassField, listener:Expr):Expr {
        var signalName = signalName(field.name);
        return if (!listener.expr.match(EConst(CIdent("null"))))
            macro $expr.$signalName.remove($listener);
        else
            macro $expr.$signalName.removeAll();
    }

    public function getClassFieldChangedExpr(expr:Expr, field:ClassField, oldValue:Expr, newValue:Expr):Expr {
        var args = switch (field.kind) {
            case FMethod(_): [];
           case FVar(_, _): [oldValue, newValue];
        }
        return dispatchSignal(expr, field.name, args, hasLazy(field.bindableMeta()));
    }
    
    public function getDisposeBindingsExpr(expr:ExprOf<IBindable>, type:Type):Expr {
        return macro {
            var meta = haxe.rtti.Meta.getFields($p{type.toString().split(".")});
            if (meta != null) for (m in std.Reflect.fields(meta)) {
                var data:Dynamic<String> = std.Reflect.field(meta, m);
                if (std.Reflect.hasField(data, $v{BIND_SIGNAL_META})) {
                    var signal:bindx.BindSignal.Signal<Dynamic> = cast Reflect.field($expr, m);
                    if (signal != null) signal.dispose();
                }
            }
        }
    }

    function generateSignal(field:Field, type:ComplexType, builder:Expr, res:Array<Field>) {
        var signalName = signalName(field.name);
        var meta = field.bindableMeta();
        var inlineSignalGetter = meta.findParam(INLINE_SIGNAL_GETTER);

        if (hasLazy(meta)) {
            var signalPrivateName = signalPrivateName(field.name);
            res.push({
                name: signalPrivateName,
                kind: FVar(type, null),
                pos: field.pos,
                meta: [ { name:BIND_SIGNAL_META, pos:field.pos } ]
            });

            res.push({
                name: signalName,
                kind: FProp("get", "never", type, null),
                pos: field.pos,
                access: [APrivate],
            });

            var getter = macro function foo() {
                if (this.$signalPrivateName == null) {
                    this.$signalPrivateName = ${builder}
                }
                return $i{signalPrivateName};
            };
            var getterAccess = [];
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

    inline function dispatchSignal(expr:Expr, fieldName:String, args:Array<Expr>, lazy:Bool) {
        return 
            if (lazy) {
                var signalPrivateName = signalPrivateName(fieldName);
                macro if ($expr.$signalPrivateName != null) {
                    $expr.$signalPrivateName.dispatch($a{args});
               }
            } else {
                var signalName = signalName(fieldName);
                macro $expr.$signalName.dispatch($a{args});
            }
    }

    @:expose inline function hasLazy(meta:MetadataEntry) {
        return meta.findParam(LAZY_SIGNAL).isNullOrTrue();
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
        for (l in listeners) l(oldValue, newValue);
        if (lock > 0) lock --;
    }
}

class Signal<T> {

    var listeners:Array<T>;

    var lock = 0;

    public function new() {
        removeAll();
    }

    public inline function removeAll() {
        listeners = [];
    }

    public inline function dispose() {
        listeners = null;
    }

    public function add(listener:T):Void {
        var pos = listeners.indexOf(listener);
        if (pos == -1) checkLock(); else listeners.splice(pos, 1);
        listeners.push(listener);
    }

    public function remove(listener:T):Void {
        var pos = listeners.indexOf(listener);
        if (pos > -1) {
            checkLock();
            listeners.splice(pos, 1);
        }
    }

    @:expose inline function checkLock() {
        if (lock > 0) {
            listeners = listeners.copy();
            lock = 0;
        }
    }
}