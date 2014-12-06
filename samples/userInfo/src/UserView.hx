package ;

import bindx.Bind;
import bindx.BindExt;

class UserView {
    
    @:isVar public var user(default, set):UserModel;
    
    var textField = new TextField();
    
    var unbindOldUser:Void->Void;
    
    function set_user(value) {
        if (user != null) {
            Bind.unbind(user.health, onHealthChange);
        }
        if (unbindOldUser != null) {
            unbindOldUser();
            unbindOldUser = null;
        }
        
        user = value;
        if (user != null) {
            // BindExt.exprTo auto dispatch first time
            unbindOldUser = BindExt.exprTo('Hello ${user.name}. You have ' + user.coins + " coins", this.textField.text);
            
            Bind.bind(user.health, onHealthChange);
            // manual dispatch
            onHealthChange(null, user.health);
        }
        return value;
    }
    
    function onHealthChange(from:Null<Float>, to:Null<Float>) {
        trace('user health changed from $from to $to');
    }
    
    public function new() {}
}


class TextField {
    @:isVar public var text(default, set):String;
    
    function set_text(value) {
        trace("TextField::text changed to: " + value);
        return text = value;
    }
    
    public function new() {}
}