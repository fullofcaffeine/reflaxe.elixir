typedef ProductParams = {
	?title:String,
	?description:String,
	?price:Float,
	?stockCount:Int,
	?categoryId:Int
}

/**
 * Test: @:changeset annotation parameter extraction
 *
 * This test validates that @:changeset([castFields], [requiredFields])
 * properly generates an Ecto changeset function with:
 * - cast/3 with the specified fields (converted to snake_case atoms)
 * - validate_required/2 with the specified required fields
 *
 * The @:changeset annotation format is:
 * @:changeset(["field1", "field2"], ["required1"])
 *   - First array: fields to cast
 *   - Second array: fields that are required
 *
 * Compatibility note:
 * - `@:schema` now auto-injects a typed `changeset/2` declaration when missing.
 * - This test keeps an explicit declaration to prove the manual path still works.
 */
@:native("TestApp.Product")
@:schema("products")
@:timestamps
@:changeset(["title", "description", "price", "stockCount", "categoryId"], ["title", "price"])
class Product {
	@:primary_key
	public var id:Int;

	public var title:String;
	public var description:String;
	public var price:Float;
	public var stockCount:Int;
	public var categoryId:Int;

	extern public static function changeset(product:Product, attrs:Dynamic):Dynamic;
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
		var changeset:Dynamic = Product.changeset(cast null, attrs);
		trace(changeset);
		trace("Product schema with changeset annotation compiled successfully");
	}
}
