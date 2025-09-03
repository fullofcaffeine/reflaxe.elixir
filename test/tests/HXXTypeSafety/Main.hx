import reflaxe.elixir.macro.HXX;
import phoenix.types.HXXTypes;
import phoenix.types.HXXComponentRegistry;

/**
 * HXX Type Safety Test Suite
 * 
 * Tests the comprehensive type safety system for HXX templates including:
 * - Attribute name conversion (camelCase to kebab-case)
 * - Type validation at compile time
 * - Error messages with helpful suggestions
 * - Phoenix LiveView directive support
 * - HTML5 element coverage
 */
class Main {
    static function main() {
        testAttributeConversion();
        testSnakeCaseSupport();
        testTypeValidation();
        testPhoenixDirectives();
        testComplexTemplates();
        testErrorMessages();
    }
    
    /**
     * Test camelCase to kebab-case attribute conversion
     */
    static function testAttributeConversion() {
        // Test className -> class conversion
        var div1 = HXX.hxx('<div className="container">Content</div>');
        
        // Test htmlFor -> for conversion
        var label1 = HXX.hxx('<label htmlFor="email">Email:</label>');
        
        // Test data attributes (dataTestId -> data-test-id)
        var div2 = HXX.hxx('<div dataTestId="main-content">Test</div>');
        
        // Test ARIA attributes (ariaLabel -> aria-label)
        var button1 = HXX.hxx('<button ariaLabel="Submit form">Submit</button>');
        
        // Test Phoenix directives (phxClick -> phx-click)
        var button2 = HXX.hxx('<button phxClick="handle_click">Click me</button>');
        
        // Test multiple conversions in one element
        var complex = HXX.hxx('<div className="card" dataUserId="123" phxHook="ScrollLock">Card</div>');
    }
    
    /**
     * Test snake_case attribute support alongside camelCase
     */
    static function testSnakeCaseSupport() {
        // Test snake_case Phoenix directives (phx_click -> phx-click)
        var button1 = HXX.hxx('<button phx_click="handle_click">Click me</button>');
        
        // Test snake_case data attributes (data_test_id -> data-test-id)
        var div1 = HXX.hxx('<div data_test_id="main-content">Test</div>');
        
        // Test snake_case ARIA attributes (aria_label -> aria-label)
        var button2 = HXX.hxx('<button aria_label="Submit form">Submit</button>');
        
        // Test mixing camelCase and snake_case in same template
        var mixed = HXX.hxx('
            <div className="container" data_user_id="123">
                <button phxClick="save" aria_label="Save button">Save</button>
                <button phx_change="validate" ariaHidden="true">Validate</button>
            </div>
        ');
        
        // Test already kebab-case attributes (should be preserved)
        var kebab = HXX.hxx('<div data-test-id="test" phx-hook="MyHook">Kebab</div>');
        
        // Test complex snake_case scenarios
        var complex = HXX.hxx('
            <input phx_change="validate_email"
                   phx_debounce="300"
                   data_field_name="user_email"
                   aria_describedby="email_help" />
        ');
    }
    
    /**
     * Test type validation for HTML elements
     */
    static function testTypeValidation() {
        // Valid input attributes
        var input1: InputAttributes = {
            type: Text,
            name: "email",
            placeholder: "Enter email",
            required: true,
            phxChange: "validate_email"
        };
        var inputElem = HXX.hxx('<input type="text" name="email" placeholder="Enter email" required phxChange="validate_email" />');
        
        // Valid button attributes
        var button1: ButtonAttributes = {
            type: Submit,
            disabled: false,
            phxClick: "submit_form"
        };
        var buttonElem = HXX.hxx('<button type="submit" phxClick="submit_form">Submit</button>');
        
        // Valid form attributes
        var form1: FormAttributes = {
            action: "/users",
            method: "post",
            phxSubmit: "save_user",
            phxChange: "validate"
        };
        var formElem = HXX.hxx('<form action="/users" method="post" phxSubmit="save_user" phxChange="validate"></form>');
        
        // Valid select with options
        var selectElem = HXX.hxx('
            <select name="country" required>
                <option value="us">United States</option>
                <option value="ca">Canada</option>
                <option value="mx">Mexico</option>
            </select>
        ');
    }
    
    /**
     * Test Phoenix LiveView directives
     */
    static function testPhoenixDirectives() {
        // Test all Phoenix LiveView events
        var liveDiv = HXX.hxx('
            <div phxClick="clicked"
                 phxChange="changed"
                 phxSubmit="submitted"
                 phxFocus="focused"
                 phxBlur="blurred"
                 phxKeydown="key_pressed"
                 phxKeyup="key_released"
                 phxMouseenter="mouse_entered"
                 phxMouseleave="mouse_left"
                 phxHook="MyHook"
                 phxDebounce="300"
                 phxThrottle="500"
                 phxUpdate="stream"
                 phxTrackStatic="true">
                Interactive element
            </div>
        ');
        
        // Test Phoenix-specific link attributes
        var liveLink = HXX.hxx('
            <a href="/users" phxLink="patch" phxLinkState="push">
                View Users
            </a>
        ');
    }
    
    /**
     * Test complex real-world templates
     */
    static function testComplexTemplates() {
        // Define test data
        var todo: Todo = {id: 1, title: "Test Todo", completed: false};
        var user: User = {id: 1, name: "John", email: "john@example.com", active: true};
        var users: Array<User> = [
            {id: 1, name: "Alice", email: "alice@example.com", active: true},
            {id: 2, name: "Bob", email: "bob@example.com", active: false}
        ];
        var errors: FormErrors = {name: null, email: null};
        var valid = true;
        
        // Todo item template with nested elements
        var todoItem = HXX.hxx('
            <div className="todo-item" dataItemId="${todo.id}">
                <input type="checkbox" 
                       checked="${todo.completed}"
                       phxClick="toggle_todo"
                       phxValue="${todo.id}" />
                <span className="${todo.completed ? "completed" : ""}">${todo.title}</span>
                <button className="delete-btn" 
                        phxClick="delete_todo"
                        phxValue="${todo.id}"
                        ariaLabel="Delete todo">
                    ×
                </button>
            </div>
        ');
        
        // Form with validation
        var userForm = HXX.hxx('
            <form phxSubmit="save_user" phxChange="validate">
                <div className="form-group">
                    <label htmlFor="name">Name:</label>
                    <input type="text" 
                           id="name"
                           name="user[name]"
                           value="${user.name}"
                           placeholder="Enter your name"
                           required />
                    <span className="error">${errors.name}</span>
                </div>
                
                <div className="form-group">
                    <label htmlFor="email">Email:</label>
                    <input type="email"
                           id="email"
                           name="user[email]"
                           value="${user.email}"
                           placeholder="user@example.com"
                           required />
                    <span className="error">${errors.email}</span>
                </div>
                
                <button type="submit" disabled="${!valid}">
                    Save User
                </button>
            </form>
        ');
        
        // Table with dynamic rows
        var dataTable = HXX.hxx('
            <table className="data-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Name</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    ${users.map(user -> HXX.hxx('
                        <tr key="${user.id}">
                            <td>${user.id}</td>
                            <td>${user.name}</td>
                            <td className="${user.active ? "active" : "inactive"}">
                                ${user.active ? "Active" : "Inactive"}
                            </td>
                            <td>
                                <button phxClick="edit_user" phxValue="${user.id}">Edit</button>
                                <button phxClick="delete_user" phxValue="${user.id}">Delete</button>
                            </td>
                        </tr>
                    ')).join("")}
                </tbody>
            </table>
        ');
    }
    
    /**
     * Test error messages and validation
     * These would normally cause compile-time errors with helpful messages
     */
    static function testErrorMessages() {
        // This section documents what WOULD cause errors
        // In actual usage, these would be caught at compile time
        
        // Example of invalid attribute (would show error):
        // HXX.hxx('<input invalidAttr="test" />');
        // Error: Unknown attribute "invalidAttr" for <input>. Did you mean: disabled, invalid?
        
        // Example of unknown element (would show error):
        // HXX.hxx('<customElement>Content</customElement>');
        // Error: Unknown HTML element: <customElement>. If this is a custom component, register it first.
        
        // Valid Phoenix component syntax (dot prefix)
        var phoenixComponent = HXX.hxx('<.button type="primary">Click me</.button>');
        
        // Multiple attributes with proper conversion
        var complexElement = HXX.hxx('
            <div id="main"
                 className="container mx-auto"
                 style="padding: 20px;"
                 role="main"
                 ariaLabel="Main content"
                 tabIndex="0"
                 dataTestId="main-container"
                 phxClick="container_clicked"
                 phxHook="ScrollTracker">
                Complex element with many attributes
            </div>
        ');
    }
}

// Type definitions for testing
typedef Todo = {
    id: Int,
    title: String,
    completed: Bool
}

typedef User = {
    id: Int,
    name: String,
    email: String,
    active: Bool
}

typedef FormErrors = {
    ?name: String,
    ?email: String
}