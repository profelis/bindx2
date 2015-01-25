package bindx.macro;

#if macro
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.Tools;

class MetaUtils {

	static public inline var BINDABLE_META = ":bindable";

	static public inline function findParam(meta:MetadataEntry, name:String):Expr {
        var res = null;

        if (meta.params != null) for (p in meta.params) {
            switch (p) {
                case macro $e1 = $e2:
                    if (e1.toString() == name) res = { expr:e2.expr, pos:p.pos };
                case {expr:EConst(CIdent(s))}:
                    if (s == name) res = { expr:(macro true).expr , pos: p.pos };
                case _:
                    Context.warning('Bindable arguments syntax error. Supported syntax: (flag1=true, flag2=false, flag3)', p.pos);
            }
            if (res != null) break;
        }
        return res;
    }

    static public inline function bindableMeta(meta:Metadata):MetadataEntry {
        var res = null;
        for (m in meta) if (m.name == BINDABLE_META) {
            res = m;
            break;
        }
        return res;
    }
}

class FieldMetaUtils {
	static public inline function bindableMeta(field:Field):MetadataEntry
        return MetaUtils.bindableMeta(field.meta);

    static public inline function hasBindableMeta(field:Field):Bool
    	return bindableMeta(field) != null;
}

class ClassFieldMetaUtils {
	static public inline function bindableMeta(field:ClassField):MetadataEntry
        return MetaUtils.bindableMeta(field.meta.get());

    static public inline function hasBindableMeta(field:ClassField):Bool
    	return bindableMeta(field) != null;
}

class ClassTypeMetaUtils {
	static public inline function bindableMeta(classType:ClassType):MetadataEntry
        return MetaUtils.bindableMeta(classType.meta.get());

    static public inline function hasBindableMeta(classType:ClassType):Bool
    	return bindableMeta(classType) != null;
}

class ExprUtils {
	static public inline function isTrue(expr:Expr):Bool
		return expr.expr.match(EConst(CIdent("true")));

	static public inline function isFalse(expr:Expr):Bool
		return expr.expr.match(EConst(CIdent("false")));

    static public inline function isNullOrEmpty(expr:Expr):Bool {
        return expr == null || expr.expr.match(EConst(CIdent("null")));
    }
    
	static public inline function isNotNullAndTrue(expr:Expr):Bool
		return expr != null && isTrue(expr);

	static public inline function isNullOrTrue(expr:Expr):Bool
		return expr == null || isTrue(expr);
        
    static public inline function getComplexType(expr:Expr):ComplexType {
        return deepTypeof(expr).toComplexType();
    }
    
    static public inline function deepTypeof(expr:Expr):haxe.macro.Type {
        return Context.typeof(expr).follow();
    }
}
#end