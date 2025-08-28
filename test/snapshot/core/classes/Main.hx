package;

/**
 * Classes test case
 * Tests class compilation, inheritance, and interfaces
 */

// Interface definition
interface Drawable {
	function draw(): String;
	function getPosition(): Point;
}

// Another interface
interface Updatable {
	function update(dt: Float): Void;
}

// Simple class
class Point {
	public var x: Float;
	public var y: Float;
	
	public function new(x: Float = 0, y: Float = 0) {
		this.x = x;
		this.y = y;
	}
	
	public function distance(other: Point): Float {
		var dx = x - other.x;
		var dy = y - other.y;
		return Math.sqrt(dx * dx + dy * dy);
	}
	
	public function toString(): String {
		return 'Point($x, $y)';
	}
}

// Base class
class Shape implements Drawable {
	private var position: Point;
	private var name: String; // Changed from protected to private since Haxe doesn't have protected
	
	public function new(x: Float, y: Float, name: String) {
		this.position = new Point(x, y);
		this.name = name;
	}
	
	public function draw(): String {
		return '$name at ${position.toString()}';
	}
	
	public function getPosition(): Point {
		return position;
	}
	
	public function move(dx: Float, dy: Float): Void {
		position.x += dx;
		position.y += dy;
	}
}

// Derived class with multiple interfaces
class Circle extends Shape implements Updatable {
	public var radius: Float;
	private var velocity: Point;
	
	public function new(x: Float, y: Float, radius: Float) {
		super(x, y, "Circle");
		this.radius = radius;
		this.velocity = new Point(0, 0);
	}
	
	// Override parent method
	override public function draw(): String {
		return '${super.draw()} with radius $radius';
	}
	
	// Implement Updatable
	public function update(dt: Float): Void {
		move(velocity.x * dt, velocity.y * dt);
	}
	
	public function setVelocity(vx: Float, vy: Float): Void {
		velocity.x = vx;
		velocity.y = vy;
	}
	
	// Static method
	public static function createUnit(): Circle {
		return new Circle(0, 0, 1);
	}
}

// Abstract class (using @:abstract metadata in Haxe)
@:abstract
class Vehicle {
	public var speed: Float = 0;
	
	public function new() {}
	
	// Abstract method (must be overridden)
	public function accelerate(): Void {
		throw "Abstract method";
	}
}

// Generic class
class Container<T> {
	private var items: Array<T>;
	
	public function new() {
		items = [];
	}
	
	public function add(item: T): Void {
		items.push(item);
	}
	
	public function get(index: Int): T {
		return items[index];
	}
	
	public function size(): Int {
		return items.length;
	}
	
	public function map<U>(fn: T -> U): Container<U> {
		var result = new Container<U>();
		for (item in items) {
			result.add(fn(item));
		}
		return result;
	}
}

class Main {
	public static function main() {
		// Test Point class
		var p1 = new Point(3, 4);
		var p2 = new Point(0, 0);
		trace(p1.distance(p2)); // Should be 5
		
		// Test Shape and inheritance
		var shape = new Shape(10, 20, "Rectangle");
		trace(shape.draw());
		shape.move(5, 5);
		trace(shape.draw());
		
		// Test Circle with override and interfaces
		var circle = new Circle(0, 0, 10);
		trace(circle.draw());
		circle.setVelocity(1, 2);
		circle.update(1.5);
		trace(circle.draw());
		
		// Test static method
		var unitCircle = Circle.createUnit();
		trace(unitCircle.draw());
		
		// Test generics
		var container = new Container<String>();
		container.add("Hello");
		container.add("World");
		trace(container.get(0));
		trace(container.size());
		
		// Test generic method
		var lengths = container.map(s -> s.length);
		trace(lengths.get(0));
	}
}