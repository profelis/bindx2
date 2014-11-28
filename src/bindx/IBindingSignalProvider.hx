package bindx;

#if macro

import haxe.macro.Expr;
import haxe.macro.Type;

interface IBindingSignalProvider {
	
    function getFieldDispatcher(field:Field, result:Array<Field>):Void;
    function getFieldChangedExpr(field:Field, oldValue:Expr, newValue:Expr):Expr;

    function getClassFieldBindExpr(expr:Expr, field:ClassField, listener:Expr):Expr;
    function getClassFieldBindToExpr(expr:Expr, field:ClassField, target:Expr):Expr;
    function getClassFieldUnbindExpr(expr:Expr, field:ClassField, listener:Expr):Expr;
    function getClassFieldChangedExpr(expr:Expr, field:ClassField, oldValue:Expr, newValue:Expr):Expr;
    function getUnbindAllExpr(expr:ExprOf<IBindable>, type:Type):Expr;

}

#end