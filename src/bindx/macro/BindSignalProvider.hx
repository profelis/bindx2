package bindx.macro;

import bindx.BindSignal.Signal;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
import bindx.BindSignal;

using bindx.macro.MacroUtils;
using haxe.macro.Tools;

class BindSignalProvider implements IBindingSignalProvider {

    /**
     * default value: true
     */
    static inline var LAZY_SIGNAL = "lazySignal";
    /**
     * default value: false
     */
    static inline var INLINE_SIGNAL_GETTER = "inlineSignalGetter";
    
    public function new() {}

    @:extern static inline function signalName(fieldName:String):String return fieldName + SignalTools.SIGNAL_POSTFIX;
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
                macro @:privateAccess {
                    var listener = function () $target = $expr.$fieldName();
                    $expr.$signalName.add(listener);
                    function __unbind__() $expr.$signalName.remove(listener);
                }
            case FVar(_, _):
                var type = field.type.follow().toComplexType();
                macro @:privateAccess {
                    var listener = function (from:$type, to:$type) $target = to;
                    $expr.$signalName.add(listener);
                    function __unbind__() $expr.$signalName.remove(listener);
                }
            }
    }

    public function getClassFieldUnbindExpr(expr:Expr, field:ClassField, listener:Expr):Expr {
        var signalName = signalName(field.name);
        return if (!listener.isNullOrEmpty())
            macro @:privateAccess $expr.$signalName.remove($listener);
        else
            macro @:privateAccess $expr.$signalName.removeAll();
    }

    public function getClassFieldChangedExpr(expr:Expr, field:ClassField, oldValue:Expr, newValue:Expr):Expr {
        var args = switch (field.kind) {
            case FMethod(_): 
                if (!oldValue.isNullOrEmpty())
                    Context.error("method notify doesn't require oldValue", oldValue.pos);
                if (!newValue.isNullOrEmpty())
                    Context.error("method notify doesn't require newValue", newValue.pos);
                [];
            case FVar(_, _):
                [oldValue, newValue];
        }
        return dispatchSignal(expr, field.name, args, hasLazy(field.bindableMeta()));
    }
    
    public function getUnbindAllExpr(expr:ExprOf<IBindable>, type:Type):Expr {
        return macro bindx.BindSignal.SignalTools.unbindAll($expr);
    }

    public function getBindAllExpr(expr:ExprOf<IBindable>, type:Type, listener:Expr, force:Bool = true):Expr {
        return macro bindx.BindSignal.SignalTools.bindAll($expr, $listener, $v{force});
    }

    function generateSignal(field:Field, type:ComplexType, builder:Expr, res:Array<Field>):Void {
        var fieldName = field.name;
        var signalName = signalName(fieldName);
        var meta = field.bindableMeta();
        var inlineSignalGetter = meta.findParam(INLINE_SIGNAL_GETTER);

        if (hasLazy(meta)) {
            var signalPrivateName = signalPrivateName(field.name);
            res.push({
                name: signalPrivateName,
                kind: FVar(type, null),
                pos: field.pos,
                meta: [ { name:SignalTools.BIND_SIGNAL_META, pos:field.pos, params: [macro $v{fieldName}, macro true] } ],
                access: [APrivate]
            });

            res.push({
                name: signalName,
                kind: FProp("get", "never", type, null),
                pos: field.pos,
                access: [APrivate]
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
                meta: [ { name:SignalTools.BIND_SIGNAL_META, pos:field.pos, params: [macro $v{fieldName}, macro false] } ]
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
}