package bindx;
import haxe.macro.Context;

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
    static function internalBindChain(expr:Expr, listener:Expr):Expr {
        var printer = new haxe.macro.Printer();
        var first = Bind.checkField(expr);
        var prevField = {e:first.e, field:first.field, error:null};
        var fields:Array<FieldExpr> = [{field:first.field, bindable:true, e:first.e}];
        while (true) {
            var field = null;
            try {
                field = Bind.tryCheckField(prevField.e);
                if (field.field != null)
                    fields.push({field:field.field, bindable:field.error == null, e:field.e});
                else if (field.error != null) {
                    var end = true;
                    switch (prevField.e.expr) {
                        case ECall(e, params):
                            field = Bind.tryCheckField(e);
                            fields.push({e:field.e, field:field.field, params:params, bindable:field.error == null});
                            end = false;
                        case _:
                    }
                    if (end) break;
                }
            } 
            catch (e:FatalError) {
                e.contextFatal();
            }
            prevField = field;
        }
        for (it in fields)
            trace(printer.printExpr(it.e) + " -> " + it.field.name + (it.params != null ? '(${printer.printExprs(it.params, ",")})' : "") + "   bind:" + it.bindable);

        var i = -1;
        var res = [];
        var unbindRes = [];
        res.push(macro var listener0 = $ { listener } );
        var zeroListener = null;
        while (++i < fields.length - 1) {
            var field = fields[i + 1];
            var next = fields[i];
            var listenerName = 'listener${i+1}';
            var listenerNameExpr = macro $i { listenerName };
            var nextListenerName = i == 0 ? 'listener0' : 'listener${i}';
            var nextListenerNameExpr = macro $i { nextListenerName };
            var value = 'value${i+1}';
            var valueExpr = macro $i { value };
            
            var fieldName = next.field.name;
            var e = next.e;
            
            var fieldListenerBody = [];
            var fieldListener:Expr;
            if (next.bindable) zeroListener = { f:next, l:nextListenerNameExpr };
            if (field.bindable) zeroListener = { f:field, l:listenerNameExpr };
            
            
            if (field.bindable) {
                var type = Context.typeof(field.e).toComplexType();
                res.push(macro var $value:Null<$type> = null );
                var bind = BindMacros.bindingSignalProvider.getClassFieldBindExpr(macro n, next.field, nextListenerNameExpr );
                var unbind = BindMacros.bindingSignalProvider.getClassFieldUnbindExpr(valueExpr, next.field, nextListenerNameExpr );
                fieldListenerBody.push(macro 
                    if (n != null) {
                        $ { bind }
                        $nextListenerNameExpr($a { next.params != null ? [] : [macro n.$fieldName, macro n.$fieldName] } );
                    }
                );
                if (field.params != null) {
                    fieldListenerBody.unshift(macro $valueExpr = n );
                    fieldListenerBody.unshift(macro var n = $e );
                    fieldListenerBody.unshift(macro if ($valueExpr != null) $unbind );
                    
                    fieldListener = macro function $listenerName () {
                        $b { fieldListenerBody };
                    };
                }
                else {
                    fieldListenerBody.unshift(macro $valueExpr = n );
                    fieldListenerBody.unshift(macro if ($valueExpr != null) $unbind );
                    
                    fieldListener = macro function $listenerName (o:Null<$type>, n:Null<$type>) {
                        $b { fieldListenerBody };
                    };
                }
                
                unbindRes.push(macro if ($valueExpr != null) $unbind);
                unbindRes.push(macro $valueExpr = null );

                //trace(printer.printExpr(unbind));
            }
            else {
                trace(printer.printExpr(field.e) + " . " + field.field.name);
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
            if (fieldListener != null) {
                res.push(fieldListener);
            }
        }
        
        if (zeroListener == null) {
            Context.error("Chain is not bindable ", expr.pos);
        }
        
        var bind = BindMacros.bindingSignalProvider.getClassFieldBindExpr(zeroListener.f.e, zeroListener.f.field, zeroListener.l );
        var unbind = BindMacros.bindingSignalProvider.getClassFieldUnbindExpr(zeroListener.f.e, zeroListener.f.field, zeroListener.l );
        res.push(macro try { $bind; } catch (e:Dynamic) {
            trace("Warning: Can't initialize chain binding " + Std.string(e));
        });
        unbindRes.push(macro try { $unbind; } catch (e:Dynamic) {
            trace("Warning: Unbind chain problem " + Std.string(e));
        });
        if (zeroListener.f.params != null) {
            res.push(macro ${zeroListener.l}());
        }
        else {
            var fieldName = zeroListener.f.field.name;
            res.push(macro try { $ { zeroListener.l } (null, $ { zeroListener.f.e } .$fieldName ); } catch (e:Dynamic) {
                trace("Warning: Can't initialize chain binding " + Std.string(e));
                });
        }
        res.push(macro function unbind() { $b { unbindRes } } );
        
        var res = macro $b { res };
        trace(printer.printExpr(res));
        return res;
    }
    #end
    
}