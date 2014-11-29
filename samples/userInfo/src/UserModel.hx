package ;

import bindx.IBindable;

@:bindable
class UserModel implements IBindable
{
    public var name:String;
    public var coins:Int;
    
    public var health:Float = 1;
    
    public function new(name:String, coins:Int) {
        this.name = name;
        this.coins = coins;
    }
}