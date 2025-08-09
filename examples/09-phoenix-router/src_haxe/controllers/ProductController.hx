package controllers;

/**
 * Product controller with resource routing
 * Demonstrates @:resources annotation and nested routes
 */
@:controller
@:resources("products")
class ProductController {
    
    public function index(): String {
        return "List all products";
    }
    
    public function show(id: Int): String {
        return "Show product " + id;
    }
    
    @:route({method: "GET", path: "/products/:product_id/reviews", as: "product_reviews"})
    public function reviews(product_id: Int): String {
        return "Reviews for product " + product_id;
    }
    
    @:route({method: "POST", path: "/products/:product_id/reviews"})
    public function create_review(product_id: Int, review: Dynamic): String {
        return "Create review for product " + product_id;
    }
    
    public function create(product: Dynamic): String {
        return "Create new product";
    }
    
    public function update(id: Int, product: Dynamic): String {
        return "Update product " + id;
    }
    
    public function delete(id: Int): String {
        return "Delete product " + id;
    }
}