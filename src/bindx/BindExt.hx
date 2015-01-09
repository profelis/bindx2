package bindx;

import haxe.macro.Expr;
import haxe.macro.Context;
import bindx.macro.BindExtMacros;

using haxe.macro.Tools;
using bindx.macro.MacroUtils;

@:access(bindx.macro.BindxExtMacro)
class BindExt {
    
    @:noUsing macro static public function expr<T>(expr:ExprOf<T>, listener:ExprOf<Null<T>->Null<T>->Void>):ExprOf<Void->Void> {
        return BindxExtMacro.bindExpr(expr, listener);
    }
    
    @:noUsing macro static public function exprTo<T>(expr:ExprOf<T>, target:ExprOf<T>):ExprOf<Void->Void> {
        var type = expr.getComplexType();
        return BindxExtMacro.bindExpr(expr, macro function (_, to:Null<$type>) $target = to);
    }
    
    @:noUsing macro static public function chain<T>(expr:ExprOf<T>, listener:Expr):ExprOf<Void->Void> {
        return BindxExtMacro.bindChain(expr, listener);
    }
    
    @:noUsing macro static public function chainTo<T>(expr:ExprOf<T>, target:ExprOf<T>):ExprOf<Void->Void> {
        var type = expr.getComplexType();
        return BindxExtMacro.bindChain(expr, macro function (_, to:Null<$type>) $target = to);
    }
}