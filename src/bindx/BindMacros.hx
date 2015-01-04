package bindx;

import bindx.GenericError;
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.TypeTools;

using haxe.macro.Tools;
using Lambda;
using StringTools;
using bindx.MetaUtils;
using haxe.macro.Tools;

class BindMacros {
    #if macro
    static inline var OLD_VALUE = "__oldValue__";
    static inline var NEW_VALUE = "__newValue__";

    /**
     * default value: false
     */
    static public inline var INLINE_SETTER = "inlineSetter";
    /**
     * default value: false
     */
    static public inline var FORCE = "force";
    
    static public inline var BINDABLE_FIELDS = ":bindableFields";

	static var processed:Array<String> = [];

    static var bindingSignalProvider:IBindingSignalProvider;
    
    macro static public function buildIBindable():Array<Field> {
        var type = Context.getLocalType();
        var tName = type.toComplexType().toString();
        if (processed.indexOf(tName) > -1) {
            return null;
        }
        processed.push(tName);

        var classType = type.getClass();
        
        Context.onMacroContextReused(function () {
            processed = [];
            return true;
        });
        
        if (bindingSignalProvider == null) {
            bindingSignalProvider = new bindx.BindSignal.BindSignalProvider();
        }
        
        var fields = Context.getBuildFields();
        
        var meta = classType.bindableMeta();
        if (meta != null) injectBindableMeta(fields, meta);
        
        if (classType.isInterface) {
            var a = [];
            for (f in fields) {
                for (m in f.meta) if (m.name == MetaUtils.BINDABLE_META) {
                    a.push(macro $v { f.name } );
                    if (m.params.length > 0)
                        Context.warning('Interface doesn\'t support @:bindable meta params', m.pos);
                }
            }
            var classMeta = classType.meta;
            if (classMeta.has(BINDABLE_FIELDS))
                classMeta.remove(BINDABLE_FIELDS);
            classMeta.add(BINDABLE_FIELDS, a, classType.pos);
            return fields;
        }
        
        var interfaceFields = getBindableFieldsFromInterfaces(classType);
        
        var res = [];
        for (f in fields)
        	if (f.hasBindableMeta()) {
        		if (!isFieldBindable(f, fields)) Context.error('can\'t bind field \'${f.name}\'', f.pos);

        		bindField(f, fields, res);
        	} else {
                if (interfaceFields.exists(f.name))
                    Context.fatalError('Interface "${typeName(interfaceFields.get(f.name))}" expects @:bindable metadata', f.pos);
                res.push(f);
            }

        return res;
    }
    
    inline static function typeName(t: { module:String, name:String } ) {
        return t.module + (t.module.length > 0 ? "." + t.name : t.name);
    }
    
    static function getBindableFieldsFromInterfaces(classType:ClassType):Map<String, ClassType> {
        var interfaceFields = new Map();
        
        function iter(t:ClassType) {
            var meta = t.meta.get();
            for (m in meta) if (m.name == BINDABLE_FIELDS) {
                for (a in m.params) {
                    var value = switch a.expr { case EConst(CString(s)): s; case _: null; };
                    interfaceFields.set(value, t);
                }
                break;
            }
            for (it in t.interfaces) iter(it.t.get());
        }
        
        for (i in classType.interfaces) iter(i.t.get());
        return interfaceFields;
    }

    static function bindField(field:Field, fields:Array<Field>, res:Array<Field>):Void {
        var meta = field.bindableMeta();
        bindingSignalProvider.getFieldDispatcher(field, res);

        var forceParam = meta.findParam(FORCE);
        var inlineSetter = meta.findParam(INLINE_SETTER);
        if (forceParam.isNotNullAndTrue()) {
            if (inlineSetter != null)
                Warn.w('\'$INLINE_SETTER\' ignored. \'$FORCE\' mode', inlineSetter.pos, WarnPriority.INFO);
            res.push(field);
            return;
        }

    	switch (field.kind) {
    		case FVar(type, expr):
                var fieldName = field.name;
    			var setterName = 'set_$fieldName';
    			field.kind = FProp("default", "set", type, expr);
    			res.push(field);
    			var setter = macro function foo(value:$type) {
                    var $OLD_VALUE = this.$fieldName;
                    if ($i{OLD_VALUE} == value) return $i{OLD_VALUE};
                    this.$fieldName = value;
    				${bindingSignalProvider.getFieldChangedExpr(field, macro $i{OLD_VALUE}, macro $i{"value"})}
    				return value;
    			};
                var setterAccess = [APrivate];
                if (inlineSetter.isNotNullAndTrue()) setterAccess.push(AInline);
    			res.push({
    				name: setterName,
    				kind: FFun(switch (setter.expr) { case EFunction (_, func): func; case _: throw false; }),
    				pos: field.pos,
    				access: setterAccess
    			});

    		case FProp(get, set, type, expr):
                if (inlineSetter != null)
                    Warn.w('$INLINE_SETTER ignored. Setter already exist', inlineSetter.pos, WarnPriority.INFO);
                var fieldName = field.name;
                var setter = fields.find(function (it) return it.name == 'set_$fieldName');
                if (setter != null) {
                    switch (setter.kind) {
                        case FFun(func):
                            patchField = field;
                            func.expr = macro {
                                var $OLD_VALUE = this.$fieldName;
                                if ($i{OLD_VALUE} == $i{func.args[0].name}) return $i{OLD_VALUE};
                                $e{patchSetter(func.expr)};
                            };
                            patchField = null;
                        case _:
                    }
                }
                res.push(field);

            case FFun(f):
                if (inlineSetter != null)
                    Warn.w('methods doesn\'t support \'$INLINE_SETTER\'', inlineSetter.pos, WarnPriority.INFO);
                res.push(field);
        }
    }

    static var patchField:Field;

    static function patchSetter(expr:Expr):Expr {
        return switch (expr.expr) {
            case EReturn(res):
                var fieldName = patchField.name;
                
                macro {
                    var $NEW_VALUE = ${res.map(patchSetter)};
                    ${bindingSignalProvider.getFieldChangedExpr(patchField, macro $i{OLD_VALUE}, macro $i{NEW_VALUE})};
                    return $i{NEW_VALUE};
                }
                    
            case _: expr.map(patchSetter);
        }
    }

    static inline function injectBindableMeta(fields:Array<Field>, meta:MetadataEntry):Void {
        for (f in fields) {
            if (f.hasBindableMeta()) continue;
            if (f.access.exists(function (it) return it.equals(APrivate))) continue;

            var forceParam = meta.findParam(FORCE);
            if (isFieldBindable(f, fields, forceParam.isNotNullAndTrue()))
                switch (f.kind) {
                    case FFun(_):
                    case _: f.meta.push({name:MetaUtils.BINDABLE_META, pos:f.pos, params:meta.params});
                }
        }
    }

    static function isFieldBindable(field:Field, fields:Array<Field>, force = false):Bool {
        if (field.name == "new") return false;

        for (a in field.access)
            if (a.equals(AMacro) || a.equals(ADynamic) || a.equals(AStatic))
                return false;

        if (field.name.startsWith("set_") || field.name.startsWith("get_")) {
            var propName = field.name.substr(4);
            for (f in fields) if (f.name == propName) {
                switch (f.kind) {
                    case FVar(_, _): return false;
                    case _:
                }
            }
        }

        if (!force) {
            var meta = field.bindableMeta();
            var forceParam = meta != null ? meta.findParam(FORCE) : null;
            force = forceParam.isNotNullAndTrue();
        }
        
        if (force) return switch (field.kind) {
            case FProp("never", _, _, _): false;
            case _: true;
        }

        return switch (field.kind) {
            case FProp("never", _, _, _) | FProp(_, "never", _, _) | FProp(_, "dynamic", _, _) | FProp(_, "null", _, _): false;
            case _: true;
        }
    }
    #end
}