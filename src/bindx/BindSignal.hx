package bindx;

class MethodSignal extends Signal<Void -> Void> {

    public function dispatch():Void {
        lock ++;
        for (l in listeners) l();
        if (lock > 0) lock --;
    }
}

class FieldSignal<T> extends Signal<T -> T -> Void> {

    public function dispatch(oldValue:T = null, newValue:T = null):Void {
        lock ++;
        var ls = listeners;
        for (l in ls) l(oldValue, newValue);
        if (lock > 0) lock --;
    }
}

class Signal<T> {

    var listeners:Array<T>;

    var lock:Int = 0;

    public function new() {
        removeAll();
    }

    public inline function removeAll():Void {
        listeners = [];
        lock = 0;
    }
    
    inline function indexOf(listener:T):Int {
        #if (neko || bindx_compareMethods)
            var res = -1;
            var i = 0;
            for (l in listeners) {
                if (Reflect.compareMethods(listener, l)) {
                    res = i;
                    break;
                }
                i++;
            }
            return res;
        #else
            return listeners.indexOf(listener);
        #end
    }

    public function add(listener:T):Void {
        var pos = indexOf(listener);
        checkLock();
        if (pos > -1) listeners.splice(pos, 1);
        listeners.push(listener);
    }

    public function remove(listener:T):Void {
        var pos = indexOf(listener);
        if (pos > -1) {
            checkLock();
            listeners.splice(pos, 1);
        }
    }

    inline function checkLock():Void {
        if (lock > 0) {
            listeners = listeners.copy();
            lock = 0;
        }
    }
}

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

    static public function bindAll(bindable:bindx.IBindable, callback:String -> Void, force = true):Void -> Void {
        var listeners = new Map<bindx.BindSignal.Signal<Dynamic>, Dynamic>();

        var signals = getSignals(bindable, force);
        for (name in signals.keys()) {
            var signal = signals.get(name);
            if (std.Std.is(signal, FieldSignal)) {
                var listener = function (_, _) callback(name);
                listeners.set(signal, listener);
                signal.add(listener);
            } else {
                var listener = function () callback(name);
                listeners.set(signal, listener);
                signal.add(listener);
            }
        }

        return function () {
            for (signal in listeners.keys()) {
                var listener = listeners.get(signal);
                if (Std.is(signal, FieldSignal)) signal.remove(listener);
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