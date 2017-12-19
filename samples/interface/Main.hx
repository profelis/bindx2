import bindx.BindSignal.FieldSignal;
import bindx.IBindable;
import bindx.Bind;

@:bindable interface IRick extends IBindable {
    var a(get, set):Int;

    private var aChanged(default, null):bindx.FieldSignal<Int>;
}

@:bindable private class Rick implements IRick {
    public var a(get, set):Int;
    private var _a:Int = 0;

    public function new() {
    }

    private function get_a():Int {
        return _a;
    }

    private function set_a(value:Int):Int {
        _a = value;
        return value;
    }
}

private class View {
    public var b:Int = 0;

    public function new() {
    }
}

class Main {
    static public function main():Void {
        var r:IRick = new Rick();
        var v = new View();
        Bind.bindTo(r.a, v.b);
        r.a = 8;
        trace("v.b = " + v.b);
    }
}