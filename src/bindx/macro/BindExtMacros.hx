package bindx.macro;

#if macro

import bindx.macro.GenericError;
import haxe.macro.Expr;
import haxe.macro.MacroStringTools;
import haxe.macro.Type;
import haxe.macro.Context;
import bindx.macro.BindMacros;

using Lambda;
using StringTools;
using bindx.macro.MacroUtils;
using haxe.macro.Tools;

private typedef FieldExpr = {
    var field:ClassField;
    var bindable:Bool;
    var e:Expr;
    @:optional var params:Array<Expr>;
}

private typedef Chain = {
    var init:Array<Expr>;
    var bind:Array<Expr>;
    var unbind:Array<Expr>;
    var expr:Expr;
}

@:access(bindx.macro.BindableMacros)
@:access(bindx.macro.BindMacros)
class BindxExtMacro {
    
    static inline function bindChain(expr:Expr, listener:Expr):Expr {
        var zeroListener = listenerName(0, "");
        var chain = null;
        try { chain = warnPrepareChain(expr); } catch (e:GenericError) e.contextError();
        
        var res = macro (function ($zeroListener):Void->Void
            $b { chain.init.concat(chain.bind).concat([(macro var res = function ():Void $b { chain.unbind }), macro return res]) }
        )($listener);
        return res;
    }
    
    static function bindExpr(expr:Expr, listener:Expr):Expr {
        var type = expr.getComplexType();
        var fixedType = fixComplexType(type);
        var listenerNameExpr = macro listener;
        var fieldListenerName = "fieldListener";
        var fieldListenerNameExpr = macro $i{fieldListenerName};
        var methodListenerName = "methodListener";
        var methodListenerNameExpr = macro $i{methodListenerName};
        var chain:Chain = { init:[], bind:[], unbind:[], expr:expr };
        var binded:Map<String, {prebind:Expr, c:Chain}> = new Map();
        
        var prefix = 0;
        function findChain(expr:Expr) {
            var isChain;
            expr = unwrapFormatedString(expr);
            var e = expr;
            do switch (e.expr) {
                case EField(le, _) | ECall(le, _): 
                    isChain = true;
                    e = le;
                case _:
                    isChain = false;
            } while (isChain);
            var doBind = e != expr;
            if (doBind) {
                var key = expr.toString();
                for (k in binded.keys()) if (k.startsWith(key)) {
                    doBind = false;
                    break;
                }
            }
            if (doBind) {
                var pre = '_${prefix++}';
                var zeroListener = listenerName(0, pre);
                var c = null;
                try { 
                    c = warnPrepareChain(expr, pre, true); 
                } catch (e:GenericError) {
                    Warn.w('${expr.toString()} is not bindable.', e.pos, WarnPriority.ALL);
                }
                if (c != null) {
                    var key = c.expr.toString();
                    if (!binded.exists(key)) {
                        var ecall = switch (c.expr.expr) {
                            case EField(e, field):
                                var type = e.deepTypeof();
                                var classRef = type.getClass();
                                var field = classRef.findField(field);
                                field.kind.match(FMethod(_));
                            case _: false;
                        }
                        var prebind = macro var $zeroListener = ${ecall ? methodListenerNameExpr : fieldListenerNameExpr};
                        binded.set(key, {prebind:prebind, c:c});
                    }
                }
            }
            expr.iter(findChain);
        }
        findChain(expr);
        
        var keys = [for (k in binded.keys()) k];
        var i = 0;
        while (i < keys.length) {
            var k = keys[i];
            var remove = false;
            var j = i;
            while (!remove && ++j < keys.length) remove = keys[j].startsWith(k);
            if (remove) keys = keys.splice(i, 1); else i++;
        }
        
        var msg = [];
        for (k in keys) {
            var data = binded.get(k);
            msg.push(data.c.expr.toString());
            chain.bind.unshift(data.prebind);
            var c = data.c;
            chain.init = chain.init.concat(c.init);
            chain.bind = chain.bind.concat(c.bind);
            chain.unbind = chain.unbind.concat(c.unbind);
        }
        Warn.w('Bind \'${msg.join("', '")}\'', expr.pos, WarnPriority.INFO);
        
        var zeroListener = listenerName(0, "");
        var zeroValue = 'value0';
        chain.unbind.unshift(macro $i { zeroValue } = null);
        
        var callListener = switch (type) {
            case macro : Void: macro if (!init) $i{zeroListener}();
            case _: 
                macro if (!init) {
                    var v:$fixedType = null;
                    try { v = $expr; } catch (e:Dynamic) { trace(e); };
                    $i { zeroListener } ($i { zeroValue }, v);
                    $i { zeroValue } = v;
                }; 
        }

        var preInit = [
            (macro var init:Bool = true),
            macro var $zeroValue:$fixedType = null
        ];
        
        var postInit = [
            macro function $fieldListenerName(?from:Dynamic, ?to:Dynamic) $callListener,
            macro function $methodListenerName() $callListener
        ];
        
        var result = [
            macro init = false,
            macro $i { methodListenerName } (),
            (macro var res = function ():Void $b { chain.unbind } ),
            macro return res
        ];
        
        var res = macro (function ($zeroListener):Void->Void
            $b { preInit.concat(chain.init).concat(postInit).concat(chain.bind).concat(result) }
        )($listener);
        
        return res;
    }
    
    static function checkFields(expr:Expr):Array<FieldExpr> {
        var first = BindMacros.checkField(expr);
        var firstParams;
        if (first.field == null) {
            switch (expr.expr) {
                case ECall(e, params):
                    first = BindMacros.checkField(e);
                    firstParams = params;
                case _:
            }
        }
        if (first.field == null) {
            if (first.error != null) throw first.error;
            else throw new FatalError('${expr.toString()} is not bindable.', expr.pos);
        }
        
        var prevField = {e:first.e, field:first.field, error:null};
        var fields:Array<FieldExpr> = [ { field:first.field, bindable:first.error == null, e:first.e, params:firstParams } ];
        
        var end;
        do {
            end = true;
            var field = BindMacros.checkField(prevField.e);
            if (field.field != null) {
                fields.push( { field:field.field, bindable:field.error == null, e:field.e } );
                end = false;
            } else if (field.error != null) switch (prevField.e.expr) {
                case ECall(e, params):
                    field = BindMacros.checkField(e);
                    if (field.field == null) throw new FatalError('${e.toString()} is not bindable.', expr.pos);
                    else fields.push( { e:field.e, field:field.field, params:params, bindable:field.error == null } );
                    end = false;
                case _:
            }
            else if (field.e == null) {
                throw new FatalError('${prevField.e.toString()} is not bindable.', prevField.e.pos);
            }
            prevField = field;
        } while (!end);
        return fields;
    }
    
    static function warnPrepareChain(expr:Expr, prefix = "", skipUnbindable = false):Chain {
        var fields = checkFields(expr);

        if (fields.length == 0)
            throw new FatalError('Can\'t bind empty expression: ${expr.toString()}', expr.pos);

        var i = fields.length;
        var first = null;
        while (i-- > 0) {
            var f = fields[i];
            if (first != null) f.bindable = false;
            else if (!f.bindable && first == null) {
                first = f;
                if (skipUnbindable) {
                    fields = fields.splice(i+1, fields.length - i);
                    break;
                }
            }
        }
        var bindableNum = fields.fold(function (it, n) return n += it.bindable ? 1 : 0, 0);
        if (bindableNum == 0) {
            throw new GenericError('${expr.toString()} is not bindable.', expr.pos);
        }
        if (first != null) {
            Warn.w('${expr.toString()} is not full bindable. Can bind only "${first.e.toString()}".', expr.pos, WarnPriority.INFO);
        }
        return prepareChain(fields, expr, prefix);
    }
    
    inline static function listenerName(idx:Int, prefix) return '${prefix}listener$idx';
    
    static function prepareChain(fields:Array<FieldExpr>, expr:Expr, prefix = ""):Chain {
        var bsp = BindableMacros.bindingSignalProvider;
        var res:Chain = { init:[], bind:[], unbind:[], expr:null };

        var prevListenerName = listenerName(0, prefix);
        var prevListenerNameExpr = macro $i { prevListenerName };
        var zeroListener = fields[0].bindable ? { f:fields[0], l:prevListenerNameExpr } : null;
        if (zeroListener != null) {
            var fn = zeroListener.f.field.name;
            res.expr = macro @:pos(zeroListener.f.e.pos) ${zeroListener.f.e}.$fn;
        }
        var i = -1;
        while (++i < fields.length - 1) {
            var field = fields[i + 1];
            var prev = fields[i];
            var type = prev.e.getComplexType();
            var fixedType = fixComplexType(type);
            var listenerName = listenerName(i+1, prefix);
            var listenerNameExpr = macro $i { listenerName };
            
            var value = '${prefix}value${i+1}';
            var valueExpr = macro $i { value };
            
            var oldValue = '${prefix}oldValue${i+1}';
            var oldValueExpr = macro $i { oldValue };
            
            var fieldName = prev.field.name;
            var e = prev.e;
            
            var fieldListenerBody = [];
            var fieldListener;
            
            if (field.bindable) zeroListener = { f:field, l:listenerNameExpr };
            
            if (prev.bindable && res.expr == null) {
                var fn = prev.field.name;
                res.expr = macro @:pos(prev.e.pos) ${prev.e}.$fn;
            }

            if (prev.bindable) {
                var unbind = bsp.getClassFieldUnbindExpr(valueExpr, prev.field, prevListenerNameExpr );
                
                res.bind.push(macro var $value:$fixedType = null );
                res.unbind.push(macro if ($valueExpr != null) { $unbind; $valueExpr = null; } );
                
                fieldListenerBody.push(macro if ($valueExpr != null) $unbind );
                fieldListenerBody.push(macro $valueExpr = n );
                fieldListenerBody.push(macro if (n != null)
                    $ { bsp.getClassFieldBindExpr(macro n, prev.field, prevListenerNameExpr ) });
            }
            var callPrevArgs = prev.params != null ? [] : [macro o != null ? o.$fieldName : null, macro n != null ? n.$fieldName : null];
            var callPrev = macro $prevListenerNameExpr($a { callPrevArgs } );
            fieldListenerBody.push(callPrev);
        
            if (field.params != null) {
                fieldListenerBody.unshift(macro $i { oldValue } = n);
                fieldListenerBody.unshift(macro var n:$fixedType = try { $e; } catch (e:Dynamic) { trace(e); null; });
                fieldListenerBody.unshift(macro var o:$fixedType = $i{oldValue} );

                res.init.push(macro var $oldValue:$type = null);
                res.unbind.push(macro $oldValueExpr = null);
                
                fieldListener = macro function $listenerName ():Void $b { fieldListenerBody };
            } else {
                if (prev.bindable) {
                    fieldListenerBody.unshift(macro if (o != null) 
                        ${bsp.getClassFieldUnbindExpr(macro o, prev.field, prevListenerNameExpr )}
                    );
                }
                fieldListener = macro function $listenerName (o:$fixedType, n:$fixedType):Void $b { fieldListenerBody };
            }

            res.bind.push(fieldListener);
            
            prevListenerName = listenerName;
            prevListenerNameExpr = listenerNameExpr;
        }
        
        if (zeroListener == null || !zeroListener.f.bindable)
            throw new GenericError('${expr.toString()} is not bindable.', expr.pos);
            
        var zeroName = zeroListener.f.e.toString().replace(".", "_");
        if (zeroName != "this")
            res.init.unshift(macro var $zeroName = ${zeroListener.f.e});
        
        res.bind.push(bsp.getClassFieldBindExpr(macro $i{zeroName}, zeroListener.f.field, zeroListener.l ));
        res.unbind.push(bsp.getClassFieldUnbindExpr(macro $i{zeroName}, zeroListener.f.field, zeroListener.l ));

        if (zeroListener.f.params != null) {
            res.bind.push(macro ${zeroListener.l}());
        } else {
            var fieldName = zeroListener.f.field.name;
            res.bind.push(macro $ { zeroListener.l } (null, $ { zeroListener.f.e } .$fieldName ));
        }
        return res;
    }
    
    static inline function unwrapFormatedString(expr:Expr):Expr {
        return if (MacroStringTools.isFormatExpr(expr)) {
            var f = switch (expr.expr) {
                case EConst(CString(s)): s;
                case _: null;
            }
            if (f != null) MacroStringTools.formatString(f, expr.pos) else expr;
        } else expr;
    }

    static inline function fixComplexType(type:ComplexType):ComplexType {
        return macro : Null<$type>;
        // TODO: null safety
        // if (isPrimitiveType(type)) return macro : Null<$type>;
        // return type;
    }

    static function isPrimitiveType (type:ComplexType):Bool {
        return switch (type) {
            case TPath({name:"StdTypes"}): true;
            case _: false;
        }
    }
}
#end