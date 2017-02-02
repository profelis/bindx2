package bindx;

class SignalTools {
    static public inline var BIND_SIGNAL_META = "BindSignal";

    static public inline var SIGNAL_POSTFIX = "Changed";
    
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

    static public function bindAll(bindable:bindx.IBindable, callback:String -> Dynamic -> Dynamic -> Void, force = true):Void -> Void {
        var listeners = new Map<bindx.BindSignal.Signal<Dynamic>, Dynamic>();

        var signals = getSignals(bindable, force);
        for (name in signals.keys()) {
            var signal = signals.get(name);
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
                if (Std.is(signal, bindx.BindSignal.FieldSignal)) signal.remove(listener);
                else signal.remove(listener);
            }
        }
    }

    static function getSignals(bindable:bindx.IBindable, force = true):Map<String, bindx.BindSignal.Signal<Dynamic>> {
        var signals = new Map<String, bindx.BindSignal.Signal<Dynamic>>();
        var meta = haxe.rtti.Meta.getFields(std.Type.getClass(bindable));
        if (meta != null) for (m in std.Reflect.fields(meta)) {
            var data = std.Reflect.field(meta, m);
            if (std.Reflect.hasField(data, BIND_SIGNAL_META)) {
                var args:Array<Dynamic> = std.Reflect.field(data, BIND_SIGNAL_META);
                var signal:bindx.BindSignal.Signal<Dynamic> = cast std.Reflect.field(bindable, m);
                if (signal == null && force) {
                    var lazy:Bool = args[1];
                    if (lazy) signal = cast std.Reflect.getProperty(bindable, m.substr(1));
                }
                if (signal != null) {
                    var name = args[0];
                    signals.set(name, signal);
                }
            }
        }
        return signals;
    }
}