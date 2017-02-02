package bindx;

import haxe.Constraints.Function;

class SignalTools {
    static public inline var BIND_SIGNAL_META = "BindSignal";

    static public inline var SIGNAL_POSTFIX = "Changed";
    
    /**
     *  Remove all subscriptions from target, useful for release object (use reflection api)
     *  @param bindable - target object
     */
    static public function unbindAll(bindable:bindx.IBindable):Void {
        var meta = haxe.rtti.Meta.getFields(std.Type.getClass(bindable));
        if (meta != null) for (m in std.Reflect.fields(meta)) {
            var data = std.Reflect.field(meta, m);
            if (std.Reflect.hasField(data, BIND_SIGNAL_META)) {
                var signal:bindx.BindSignal.Signal<Dynamic> = cast std.Reflect.field(bindable, m);
                if (signal != null) {
                    signal.removeAll();
                    var args:Array<Dynamic> = std.Reflect.field(data, BIND_SIGNAL_META);
                    var lazy:Bool = args[1];
                    if (lazy) std.Reflect.setField(bindable, m, null);
                }
            }
        }
    }

    /**
     *  Bind all bindable fields/methods (use reflection api)
     *  @param bindable - target object
     *  @param callback - 
     *  @param force = true - force instantiate all lazy signals
     *  @return Void -> Void
     */
    static public function bindAll(bindable:bindx.IBindable, callback:String -> Dynamic -> Dynamic -> Void, force = true):Void -> Void {
        var listeners = new Map<bindx.BindSignal.Signal<Function>, Function>();

        var signals = getSignals(bindable, force);
        for (name in signals.keys()) {
            var signal = signals.get(name);
            if (signal == null) continue;
            if (std.Std.is(signal, bindx.BindSignal.FieldSignal)) {
                var listener = function (from:Dynamic, to:Dynamic) callback(name, from, to);
                listeners.set(signal, listener);
                signal.add(listener);
            } else {
                var listener = function () callback(name, null, null);
                listeners.set(signal, listener);
                signal.add(listener);
            }
        }

        return function () {
            for (signal in listeners.keys()) {
                var listener = listeners.get(signal);
                signal.remove(listener);
            }
        }
    }

    /**
     *  Get all binding signals (use reflection api)
     *  @param bindable - target object
     *  @param force = true - force instantiate all lazy signals
     *  @return Map<String, bindx.BindSignal.Signal<Dynamic>>
     */
    static public function getSignals(bindable:bindx.IBindable, force = true):Map<String, bindx.BindSignal.Signal<Function>> {
        var signals = new Map<String, bindx.BindSignal.Signal<Function>>();
        var meta = haxe.rtti.Meta.getFields(std.Type.getClass(bindable));
        if (meta != null) for (m in std.Reflect.fields(meta)) {
            var data = std.Reflect.field(meta, m);
            if (std.Reflect.hasField(data, BIND_SIGNAL_META)) {
                var args:Array<Dynamic> = std.Reflect.field(data, BIND_SIGNAL_META);
                var signal:bindx.BindSignal.Signal<Function> = cast std.Reflect.field(bindable, m);
                if (signal == null && force) {
                    var lazy:Bool = args[1];
                    if (lazy) signal = cast std.Reflect.getProperty(bindable, m.substr(1));
                }
                var name = args[0];
                signals.set(name, signal);
            }
        }
        return signals;
    }
}