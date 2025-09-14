import phoenix.types.HXXTypes;

/**
 * HXX Type Safety Error Tests
 * 
 * This file intentionally contains TYPE ERRORS to verify that the
 * type safety system properly rejects invalid code at compile time.
 * 
 * EXPECTED: This file should FAIL to compile with specific error messages
 * about unknown attributes, type mismatches, etc.
 */
class Main {
    static function main() {
        testInvalidAttributes();
        testTypeMismatches();
        testUnknownElements();
    }
    
    /**
     * Test that invalid attributes are caught at compile time
     */
    static function testInvalidAttributes() {
        // ERROR: InputAttributes doesn't have 'invalidAttr' field
        var input1: InputAttributes = {
            type: Email,
            name: "email",
            invalidAttr: "test",  // ❌ SHOULD CAUSE COMPILE ERROR
            placeholder: "Email"
        };
        
        // ERROR: ButtonAttributes doesn't have 'href' field (that's for anchors)
        var button1: ButtonAttributes = {
            type: Submit,
            href: "/path",  // ❌ SHOULD CAUSE COMPILE ERROR - href is for <a> not <button>
            phxClick: "submit"
        };
        
        // ERROR: FormAttributes doesn't have 'src' field (that's for images)
        var form1: FormAttributes = {
            action: "/users",
            method: "post",
            src: "image.jpg"  // ❌ SHOULD CAUSE COMPILE ERROR
        };
    }
    
    /**
     * Test that type mismatches are caught
     */
    static function testTypeMismatches() {
        // ERROR: 'required' should be Bool, not String
        var input2: InputAttributes = {
            type: Text,
            required: "yes"  // ❌ SHOULD CAUSE COMPILE ERROR - String not assignable to Bool
        };
        
        // ERROR: 'type' should be InputType enum, not arbitrary string
        var input3: InputAttributes = {
            type: "not_a_valid_type",  // ❌ SHOULD CAUSE COMPILE ERROR - not a valid InputType
            name: "test"
        };
        
        // ERROR: 'disabled' should be Bool, not Int
        var button2: ButtonAttributes = {
            disabled: 1  // ❌ SHOULD CAUSE COMPILE ERROR - Int not assignable to Bool
        };
        
        // ERROR: 'tabIndex' should be Int, not String
        var div1: DivAttributes = {
            tabIndex: "first"  // ❌ SHOULD CAUSE COMPILE ERROR - String not assignable to Int
        };
    }
    
    /**
     * Test that misspelled attributes are caught
     */
    static function testUnknownElements() {
        // ERROR: Typo in attribute name
        var input4: InputAttributes = {
            placeHolder: "text"  // ❌ SHOULD CAUSE ERROR - capital H (should be placeholder)
        };
        
        // ERROR: Using React attribute instead of Phoenix
        var button3: ButtonAttributes = {
            onClick: "handler"  // ❌ SHOULD CAUSE ERROR - should be phxClick
        };
        
        // ERROR: Wrong case for aria attribute
        var div2: DivAttributes = {
            arialabel: "test"  // ❌ SHOULD CAUSE ERROR - should be ariaLabel
        };
    }
}

/**
 * This test file is EXPECTED TO FAIL compilation.
 * 
 * Success criteria:
 * - Compilation fails with clear error messages
 * - Each invalid attribute is identified
 * - Each type mismatch is explained
 * - Helpful suggestions are provided where possible
 * 
 * Example expected errors:
 * - "InputAttributes has no field invalidAttr"
 * - "String should be Bool"
 * - "not_a_valid_type should be phoenix.types.HXXTypes.InputType"
 * - "ButtonAttributes has no field onClick. Did you mean phxClick?"
 */