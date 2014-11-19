package bindx;
import haxe.macro.Context;
import haxe.macro.Printer;

#if macro


import bindx.Error;
import haxe.macro.Expr;
import haxe.macro.Type;

using Lambda;
using haxe.macro.Tools;

typedef FieldExpr = {
    var field:ClassField;
    var bindable:Bool;
    var e:Expr;
    @:optional var params:Array<Expr>;
}

#end
@:access(bindx.BindMacros)
class BindExt {
    
    @:noUsing macro static public function chain(expr:Expr, listener:Expr):Expr {
        return internalBindChain(expr, listener);
    }
    
    #if macro
    static function checkFields(expr:Expr):Array<FieldExpr> {
        var first = Bind.checkField(expr);
        var prevField = {e:first.e, field:first.field, error:null};
        var fields:Array<FieldExpr> = [ { field:first.field, bindable:true, e:first.e } ];
        
        inline function tryCheck(e:Expr) {
            var field = null;
            try {
                field = Bind.tryCheckField(e);
            } catch (e:FatalError) e.contextFatal();
            return field;
        }
        
        while (true) {
            var field = tryCheck(prevField.e);
            if (field.field != null) {
                fields.push( { field:field.field, bindable:field.error == null, e:field.e } );
            } else if (field.error != null) {
                var end = true;
                switch (prevField.e.expr) {
                    case ECall(e, params):
                        field = tryCheck(e);
                        // TODO: test
                        if (field.error != null) field.error.contextError();
                        if (field.field == null)
                            Context.fatalError('error parse fields ${e.toString()}', e.pos);
                        fields.push( { e:field.e, field:field.field, params:params, bindable:field.error == null } );
                        end = false;
                    case _:
                }
                if (end) break;
            }
            prevField = field;
        }
        //for (it in fields) trace(printer.printExpr(it.e) + " -> " + it.field.name + (it.params != null ? '(${printer.printExprs(it.params, ",")})' : "") + "   bind:" + it.bindable);
        return fields;
    }
    
    public static function internalBindChain(expr:Expr, listener:Expr):Expr {
        var fields = checkFields(expr);
        var chain = prepareBindChain(fields, listener, expr.pos);
        
        var res = macro
            $b { chain.bind.concat(chain.init).concat([macro function __unbind__():Void { $b { chain.unbind } }]) };
        //trace(new Printer().printExpr(res));
        return res;
    }
    
    static var ZERO_LISTENER = "listener0";
    
    public static function prepareBindChain(fields:Array<FieldExpr>, listener:Expr, pos:Position):{init:Array<Expr>, bind:Array<Expr>, unbind:Array<Expr>} {
        var res = { init:[], bind:[], unbind:[] };

        res.bind.push(macro var $ZERO_LISTENER = $ { listener } );
        
        var prevListenerName = ZERO_LISTENER;
        var prevListenerNameExpr = macro $i { prevListenerName };
        var zeroListener = { f:fields[0], l:prevListenerNameExpr };
        var i = -1;
        while (++i < fields.length - 1) {
            var field = fields[i + 1];
            var prev = fields[i];
            var listenerName = 'listener${i+1}';
            var listenerNameExpr = macro $i { listenerName };
            
            var value = 'value${i+1}';
            var valueExpr = macro $i { value };
            
            var fieldName = prev.field.name;
            var e = prev.e;
            
            var fieldListenerBody = [];
            var fieldListener:Expr;
            if (field.bindable) zeroListener = { f:field, l:listenerNameExpr };
            
            if (field.bindable) {
                var type = Context.typeof(field.e).toComplexType();
                res.bind.push(macro var $value:Null<$type> = null );
                var unbind = BindMacros.bindingSignalProvider.getClassFieldUnbindExpr(valueExpr, prev.field, prevListenerNameExpr );
                fieldListenerBody.push(macro 
                    if (n != null) {
                        $ { BindMacros.bindingSignalProvider.getClassFieldBindExpr(macro n, prev.field, prevListenerNameExpr ) }
                        $prevListenerNameExpr($a { prev.params != null ? [] : [macro n.$fieldName, macro n.$fieldName] } );
                    }
                );
                if (field.params != null) {
                    fieldListenerBody.unshift(macro var n:Null<$type> = $valueExpr = $e );
                    fieldListenerBody.unshift(macro if ($valueExpr != null) $unbind );
                    
                    fieldListener = macro function $listenerName ():Void {
                        $b { fieldListenerBody };
                    };
                }
                else {
                    fieldListenerBody.unshift(macro $valueExpr = n );
                    fieldListenerBody.unshift(macro if ($valueExpr != null) $unbind );
                    fieldListenerBody.unshift(macro if (o != null) ${BindMacros.bindingSignalProvider.getClassFieldUnbindExpr(macro o, prev.field, prevListenerNameExpr )} );
                    
                    fieldListener = macro function $listenerName (o:Null<$type>, n:Null<$type>):Void {
                        $b { fieldListenerBody };
                    };
                }
                res.bind.push(fieldListener);
                
                res.unbind.push(macro if ($valueExpr != null) { $unbind; $valueExpr = null; } );
            }
            else {
                //trace(printer.printExpr(field.e) + " . " + field.field.name);
                /*if (field.params != null) {
                    fieldListenerBody.unshift(macro var n = $e );
                    
                    fieldListener = macro function $listenerName () {
                        $b { fieldListenerBody };
                    };
                }
                else {
                    fieldListener = macro function $listenerName (o, n) {
                        $b { fieldListenerBody };
                    };
                }*/
            }
            prevListenerName = listenerName;
            prevListenerNameExpr = listenerNameExpr;
        }
        
        if (zeroListener == null) {
            Context.error("Chain is not bindable", pos);
        }
        
        var bind = BindMacros.bindingSignalProvider.getClassFieldBindExpr(zeroListener.f.e, zeroListener.f.field, zeroListener.l );
        var unbind = BindMacros.bindingSignalProvider.getClassFieldUnbindExpr(zeroListener.f.e, zeroListener.f.field, zeroListener.l );
        res.init.push(bind);
        res.unbind.push(unbind);
        if (zeroListener.f.params != null) {
            res.init.push(macro ${zeroListener.l}());
        }
        else {
            var fieldName = zeroListener.f.field.name;
            res.init.push(macro $ { zeroListener.l } (null, $ { zeroListener.f.e } .$fieldName ));
        }
        return res;
    }
    #end
    
}