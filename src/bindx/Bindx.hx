package bindx;

#if macro

import bindx.Error;
import haxe.macro.Expr;

#end
class Bindx {
    
    @:noUsing macro static public function bindChain(expr:Expr, listener:Expr):Expr {
        return internalBindChain(expr, listener);
    }
    
    #if macro
    static function internalBindChain(expr:Expr, listener:Expr):Expr {
        var prevField = Bind.checkField(expr);
        var field = prevField;
        var fields = [];
        var rest:Expr;
        while (field != null) {
            try {
                field = Bind.tryCheckField(prevField.expr);
                fields.push(field.field);
                rest = field.expr;
            } 
            catch (e:FatalError) {
                e.contextFatal();
            }
            catch (e:Error) {
                switch (prevField.expr) {
                    case EField(e, field):
                        var classType = Context.typeof(e).follow().getClass();
                        var field:ClassField = classType.findField(field, null);
                        fields.push(field);
                        rest = e;
                    case EConst(CIdent(_)):
                        rest = prevField.expr;
                    case _:
                        rest = prevField.expr;
                    }
            }
            prevField = field;
        }
    }
    #end
    
}