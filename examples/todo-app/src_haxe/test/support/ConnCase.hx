package test.support;

import haxe.test.phoenix.ConnCase as BaseConnCase;
import test.support.DataCase;

/**
 * ConnCase provides the foundation for Phoenix controller and LiveView tests.
 * 
 * Following Phoenix patterns, this module extends the standard library ConnCase
 * with todo-app specific helpers for integration testing.
 */
@:exunit
class ConnCase extends BaseConnCase {
    
    /**
     * Override endpoint for todo-app
     */
    override public static var endpoint(default, null): String = "TodoAppWeb.Endpoint";
    
    // Todo-app specific test helpers can be added here
    // The base ConnCase already provides all the standard functionality
}