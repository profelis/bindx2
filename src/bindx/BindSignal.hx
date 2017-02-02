package bindx;

import haxe.Constraints.Function;

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

class Signal<T:Function> {

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
        var res = -1;
        for (i in 0...listeners.length) {
            if (Reflect.compareMethods(listeners[i], listener)) {
                res = i;
                break;
            }
        }
        return res;
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
