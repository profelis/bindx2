package ;
class Main {

    static function main() {
        trace("tada");

        bindx.BindSignal.BindSignalProvider.register();

        var v = new Value();
        var s = {t:0};
        
        bindx.Bind.bindx(v.str, function (from, to) {trace('str changed from $from to $to');});
        v.strChanged.add(function (from, to) {trace('str changed from $from to $to');});
        v.str = "12";
        bindx.Bind.bindx(v.int, function (a, b) { trace(b); });
        var unbind = bindx.Bind.bindTo(v.int, s.t);
        v.int = 10;
        trace(s.t);
        unbind();
        v.int = 12;
        trace(s.t);
        trace(v.str);

    }
}

@:bindable
class Value implements bindx.IBindable {

    public function new() {
    }

    @:bindable(lazySignal=true, inlineSignalGetter=false, inlineSetter=true)
    public var str:String;

    @:bindable(force=true, inlineSetter=true)
    public var int(default, set):Int;

    private var noBindPrivate:Int;

    function set_int(v):Int {

    	if (v < 0) {
    		int = 0;
    		toStringChanged.dispatch();
    		intChanged.dispatch(v, int);
    		return int;
    	}
 
    	intChanged.dispatch(int, int = v);
    	toStringChanged.dispatch();
    	return v;
    }

    @:bindable()
    public function toString() {
    	return str + int;
    }
}
