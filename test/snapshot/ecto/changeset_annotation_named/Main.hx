typedef ProductParams = {
	?title:String,
	?description:String,
	?price:Float,
	?stockCount:Int,
	?categoryId:Int
}

/**
 * Test: @:changeset named config extraction
 *
 * Validates named config form:
 * @:changeset(cast([...]), validate([...]))
 *
 * Expected behavior is equivalent to legacy positional form.
 */
@:native("TestApp.ProductNamed")
@:schema("products")
@:timestamps
@:changeset(cast(["title", "description", "price", "stockCount", "categoryId"]), validate(["title", "price"]))
class ProductNamed {
	@:primary_key
	public var id:Int;

	public var title:String;
	public var description:String;
	public var price:Float;
	public var stockCount:Int;
	public var categoryId:Int;

	extern public static function changeset(product:ProductNamed, attrs:Dynamic):Dynamic;
}

class Main {
	public static function main() {
		var attrs:ProductParams = {
			title: "Widget",
			description: "Useful",
			price: 9.99,
			stockCount: 5,
			categoryId: 1
		};
		var changeset:Dynamic = ProductNamed.changeset(cast null, attrs);
		trace(changeset);
		trace("Product schema with named changeset annotation compiled successfully");
	}
}
