package ;

class Main {
    static function main() {
        var user = new UserModel("deep", 100);
        var view = new UserView();
        view.user = user; 
        //> TextField::text changed to: Hello deep. You have 100 coins
        //> user health changed from null to 1
        
        user.coins = 200; //> TextField::text changed to: Hello deep. You have 200 coins
        
        //user.health = 0.5; //> user health changed from 1 to 0.5
        
        view.user = null;
        
        user.name = "profelis";
        
        view.user = user;
        //> TextField::text changed to: Hello profelis. You have 200 coins
        //> user health changed from null to 1
        
        view.user.coins = 300; //> TextField::text changed to: Hello profelis. You have 300 coins
        
        user.health = 0.75; //> user health changed from 1 to 0.75
    }
}