package bindx;

#if macro

import bindx.Error;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.macro.Printer;

using Lambda;
using haxe.macro.Tools;

typedef FieldExpr = {
    var field:ClassField;
    var bindable:Bool;
    var e:Expr;
    @:optional var params:Array<Expr>;
}

typedef Chain = {
    var init:Array<Expr>;
    var bind:Array<Expr>;
    var unbind:Array<Expr>;
}

#end
@:access(bindx.BindMacros)
class BindExt {
    
    @:noUsing macro static public function expr(expr:Expr, listener:Expr):Expr {
        return internalBindExpr(expr, listener);
    }
    
    @:noUsing macro static public function chain(expr:Expr, listener:Expr):Expr {
        return internalBindChain(expr, listener);
    }
    
    #if macro
    
    public static function internalBindChain(expr:Expr, listener:Expr):Expr {
        var zeroListener = listenerName(0, "");
        var chain = null;
        try { chain = warnPrepareChain(expr, macro $i{ zeroListener }); } catch (e:bindx.Error) e.contextError();
        
        var res = macro (function ($zeroListener):Void->Void
            $b { chain.bind.concat(chain.init).concat([macro return function ():Void $b { chain.unbind }]) }
        )($listener);
        //trace(new Printer().printExpr(res));
        return res;
    }
    
    public static function internalBindExpr(expr:Expr, listener:Expr):Expr {
        var type = Context.typeof(expr).toComplexType();
        var listenerNameExpr = macro listener;
        var fieldListenerName = "fieldListener";
        var fieldListenerNameExpr = macro $i{fieldListenerName};
        var methodListenerName = "methodListener";
        var methodListenerNameExpr = macro $i{methodListenerName};
        var chain:Chain = { init:[], bind:[], unbind:[] };
        
        var prefix = 0;
        function findChain(expr:Expr) {
            var ch = [];
            var isChain;
            var e = expr;
            var start = expr;
            var ecall = false;
            do {
                isChain = false;
                switch (e.expr) {
                    case EField(le, _): 
                        isChain = true;
                        e = le;
                    case ECall(le, params):
                        for (p in params) findChain(p);
                        isChain = true;
                        ecall = true;
                        e = le;
                    case _:
                }
                
            } while (isChain);
            if (e != start) {
                var pre = '_${prefix++}';
                var zeroListener = listenerName(0, pre);

                var c = null;
                try { c = warnPrepareChain(start, macro $i{zeroListener}, pre); } catch (e:bindx.Error) { e.contextWarning(); }
                if (c != null) {
                    chain.init.push(macro var $zeroListener = ${ecall ? methodListenerNameExpr : fieldListenerNameExpr});
                    chain.init = chain.init.concat(c.init);
                    chain.bind = chain.bind.concat(c.bind);
                    chain.unbind = chain.unbind.concat(c.unbind);
                }
            }
            e.iter(findChain);
        }
        findChain(expr);
        
        var zeroListener = listenerName(0, "");
        
        var callListener = switch (type) {
            case macro : Void: macro if (!init) $i{zeroListener}();
            case _: macro if (!init) { var v = null; try { v = $expr; } catch (e:Dynamic) { }; $i{zeroListener}(null, v); }; 
        }
        
        var fieldListener = macro function $fieldListenerName(?from:Dynamic, ?to:Dynamic) $callListener;
        var methodListener = macro function $methodListenerName() $callListener;
        
        var base = [(macro var init = true), fieldListener, methodListener];
        
        var res = macro (function ($zeroListener):Void->Void
            $b { base.concat(chain.bind).concat(chain.init).concat([macro init = false, macro $i{methodListenerName}(), macro return function ():Void $b { chain.unbind }]) }
        )($listener);
        
        trace(new Printer().printExpr(res));
        return res;
    }
    
    static function checkFields(expr:Expr):Array<FieldExpr> {
        var first = Bind.checkField(expr);
        if (first.field == null || first.error != null)
            throw new FatalError('${expr.toString()} is not bindable', expr.pos);
        
        var prevField = {e:first.e, field:first.field, error:null};
        var fields:Array<FieldExpr> = [ { field:first.field, bindable:true, e:first.e } ];
        
        while (true) {
            var field = Bind.checkField(prevField.e);
            if (field.field != null) {
                fields.push( { field:field.field, bindable:field.error == null, e:field.e } );
            } else if (field.error != null) {
                var end = true;
                switch (prevField.e.expr) {
                    case ECall(e, params):
                        field = Bind.checkField(e);
                        if (field.field == null) throw new FatalError('${e.toString()} is not bindable.', expr.pos);
                        else fields.push( { e:field.e, field:field.field, params:params, bindable:field.error == null } );
                        end = false;
                    case _:
                }
                if (end) break;
            }
            else if (field.e == null) {
                throw new FatalError('${prevField.e.toString()} is not bindable.', expr.pos);
            }
            prevField = field;
        }
        
        return fields;
    }
    
    static function warnPrepareChain(expr:Expr, listener:Expr, prefix = ""):Chain {
        var fields = checkFields(expr);

        if (fields.length == 0) {
            throw new FatalError('Can\'t bind empty expression: ${expr.toString()}', expr.pos);
            return null;
        }

        var i = fields.length;
        var first = null;
        while (i-- > 0) {
            var f = fields[i];
            if (first != null) f.bindable = false;
            else if (!f.bindable && first == null) first = f;
        }
        var bindableNum = fields.fold(function (it, n) return n += it.bindable ? 1 : 0, 0);
        if (bindableNum == 0) {
            throw new bindx.Error('${expr.toString()} is not bindable.', expr.pos);
            return null;
        }
        if (first != null)
            Context.warning('${expr.toString()} is not full bindable. Can bind only "${first.e.toString()}".', expr.pos);
        
        //trace(fields);
        return prepareChain(fields, macro listener, expr.pos, prefix);
    }
    
    inline static function listenerName(idx:Int, prefix) return '${prefix}listener$idx';
    
    static function prepareChain(fields:Array<FieldExpr>, listener:Expr, pos:Position, prefix = ""):Chain {
        var res:Chain = { init:[], bind:[], unbind:[] };
        
        var prevListenerName = listenerName(0, prefix);
        var prevListenerNameExpr = macro $i { prevListenerName };
        var zeroListener = fields[0].bindable ? { f:fields[0], l:prevListenerNameExpr } : null;
        var i = -1;
        while (++i < fields.length - 1) {
            var field = fields[i + 1];
            var prev = fields[i];
            var listenerName = listenerName(i+1, prefix);
            var listenerNameExpr = macro $i { listenerName };
            
            var value = '${prefix}value${i}';
            var valueExpr = macro $i { value };
            
            var fieldName = prev.field.name;
            var e = prev.e;
            
            var fieldListenerBody = [];
            var fieldListener;
            if (field.bindable) zeroListener = { f:field, l:listenerNameExpr };
            
            var type = Context.typeof(field.e).toComplexType();
            
            if (prev.bindable) {
                var unbind = BindMacros.bindingSignalProvider.getClassFieldUnbindExpr(valueExpr, prev.field, prevListenerNameExpr );
                
                res.bind.push(macro var $value:Null<$type> = null );
                res.unbind.push(macro if ($valueExpr != null) { $unbind; $valueExpr = null; } );
                
                fieldListenerBody.push(macro if ($valueExpr != null) $unbind );
                fieldListenerBody.push(macro $valueExpr = n );
                fieldListenerBody.push(macro if (n != null)
                    $ { BindMacros.bindingSignalProvider.getClassFieldBindExpr(macro n, prev.field, prevListenerNameExpr ) });
            }
            var callPrev = macro $prevListenerNameExpr($a { prev.params != null ? [] : [macro null, macro n != null ? n.$fieldName : null] } );
            fieldListenerBody.push(callPrev);
        
            if (field.params != null) {
                fieldListenerBody.unshift(macro var n:Null<$type> = try $e catch (e:Dynamic) null );
                
                fieldListener = macro function $listenerName ():Void $b { fieldListenerBody };
            }
            else {
                if (prev.bindable) {
                    fieldListenerBody.unshift(macro if (o != null) 
                        ${BindMacros.bindingSignalProvider.getClassFieldUnbindExpr(macro o, prev.field, prevListenerNameExpr )}
                    );
                }
                
                fieldListener = macro function $listenerName (o:Null<$type>, n:Null<$type>):Void $b { fieldListenerBody };
            }
        
            res.bind.push(fieldListener);
            
            prevListenerName = listenerName;
            prevListenerNameExpr = listenerNameExpr;
        }
        
        if (zeroListener == null || zeroListener.f.bindable == false)
            throw new bindx.Error("Chain is not bindable.", pos);
        
        res.init.push(BindMacros.bindingSignalProvider.getClassFieldBindExpr(zeroListener.f.e, zeroListener.f.field, zeroListener.l ));
        res.unbind.push(BindMacros.bindingSignalProvider.getClassFieldUnbindExpr(zeroListener.f.e, zeroListener.f.field, zeroListener.l ));

        if (zeroListener.f.params != null) {
            res.init.push(macro ${zeroListener.l}());
        }
        else {
            var fieldName = zeroListener.f.field.name;
            res.init.push(macro $ { zeroListener.l } (null, $ { zeroListener.f.e } .$fieldName ));
        }
        return res;
    }
    
    static function traceChain(c:Chain) {
        var p = new Printer();
        function iter(exprs:Array<Expr>, name) {
            trace('::$name::');
            for (e in exprs) trace(p.printExpr(e));
        }
        
        iter(c.init, "init");
        iter(c.bind, "bind");
        iter(c.unbind, "unbind");
    }
    #end
    
}