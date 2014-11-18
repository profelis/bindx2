package bindx;

#if macro


import bindx.Error;
import haxe.macro.Expr;
import haxe.macro.Type;

using Lambda;

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
                    fields.unshift({field:field.field, bindable:field.error == null, e:field.e});
                else if (field.error != null) {
                    var end = true;
                    switch (prevField.e.expr) {
                        case ECall(e, params):
                            field = Bind.tryCheckField(e);
                            fields.unshift({e:field.e, field:field.field, params:params, bindable:field.error == null});
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
        fields.iter(function (it) trace(printer.printExpr(it.e) + " -> " + it.field.name + (it.params != null ? '(${printer.printExprs(it.params, ",")})' : "") + "   bind:" + it.bindable));
        var i = 0;
        
        
        var res = [];
        for (field in fields) {
            var listenerName = 'listener$i';
            if (field.bindable) {
                var listener = switch (field.field.kind) {
                    case FVar(_, _):
                        macro function (from, to) {
                            $listener($a{[from, to]});
                        }
                    case FMethod(_):
                        macro function() {
                            
                        }
                }
                res.push(macro var $listenerName = $listener);
                var expr = BindMacros.bindingSignalProvider.getClassFieldBindExpr(field.e, field.field, listener = macro $i{listenerName});
                trace(printer.printExpr(expr));
            }
            else {
                trace(printer.printExpr(field.e) + " . " + field.field.name);
            }
            i++;
        }
        
        return macro {};
    }
    #end
    
}