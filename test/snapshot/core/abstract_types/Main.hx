/**
 * Test case for Haxe abstract type compilation
 * Tests both simple and complex abstract types with operator overloading
 */

// Simple abstract type wrapping Int (like UInt)
abstract UserId(Int) from Int to Int {
    public function new(id: Int) {
        this = id;
    }
    
    @:op(A + B) public static function add(a: UserId, b: UserId): UserId {
        return new UserId(a.toInt() + b.toInt());
    }
    
    @:op(A > B) public static function greater(a: UserId, b: UserId): Bool {
        return a.toInt() > b.toInt();
    }
    
    public function toInt(): Int {
        return this;
    }
    
    public function toString(): String {
        return "UserId(" + this + ")";
    }
}

// More complex abstract with multiple operators (like UInt)
abstract Money(Int) from Int {
    public function new(cents: Int) {
        this = cents;
    }
    
    @:op(A + B) public static function add(a: Money, b: Money): Money {
        return new Money(a.toInt() + b.toInt());
    }
    
    @:op(A - B) public static function subtract(a: Money, b: Money): Money {
        return new Money(a.toInt() - b.toInt());
    }
    
    @:op(A * B) public static function multiply(a: Money, multiplier: Int): Money {
        return new Money(a.toInt() * multiplier);
    }
    
    @:op(A == B) public static function equal(a: Money, b: Money): Bool {
        return a.toInt() == b.toInt();
    }
    
    public function toInt(): Int {
        return this;
    }
    
    @:to public function toDollars(): Float {
        return this / 100.0;
    }
}

class Main {
    static function main() {
        trace("Testing abstract types...");
        
        // Test UserId abstract
        var user1 = new UserId(100);
        var user2 = new UserId(200);
        var combined = user1 + user2;
        var isGreater = user2 > user1;
        
        trace("User1: " + user1.toString());
        trace("User2: " + user2.toString());  
        trace("Combined: " + combined.toString());
        trace("User2 > User1: " + isGreater);
        
        // Test Money abstract
        var price1 = new Money(1050); // $10.50
        var price2 = new Money(750);  // $7.50
        var total = price1 + price2;
        var discount = price1 - new Money(150);
        var doubled = price1 * 2;
        var isEqual = price1 == price2;
        
        trace("Price1: $" + price1.toDollars());
        trace("Price2: $" + price2.toDollars());
        trace("Total: $" + total.toDollars());
        trace("Discounted: $" + discount.toDollars());
        trace("Doubled: $" + doubled.toDollars());
        trace("Equal: " + isEqual);
        
        // Test implicit casts
        var userFromInt: UserId = 42;  // from Int cast
        var intFromUser: Int = userFromInt;  // to Int cast
        trace("From int: " + userFromInt.toString());
        trace("To int: " + intFromUser);
        
        var moneyFromInt: Money = 500;
        trace("Money from int: $" + moneyFromInt.toDollars());
    }
}