/**
 * Template Compilation Test
 * Tests template string generation and basic interpolation
 * Converted from framework-based template tests to snapshot test
 */

@:template
class UserProfileTemplate {
    
    /**
     * Basic template with string interpolation
     */
    public static function renderProfile(user: {name: String, age: Int}): String {
        return "<div class='user-profile'><h1>" + user.name + "</h1><p>Age: " + user.age + "</p></div>";
    }

    /**
     * Template with conditional rendering
     */
    public static function renderWithCondition(user: {name: String, isAdmin: Bool}): String {
        var badge = user.isAdmin ? "Admin" : "User";
        return "<div class='user-info'><h2>" + user.name + "</h2><span class='badge'>" + badge + "</span></div>";
    }

    /**
     * Template with iteration
     */
    public static function renderUserList(users: Array<{name: String, email: String}>): String {
        var items = [];
        for (user in users) {
            items.push("<li><strong>" + user.name + "</strong> - " + user.email + "</li>");
        }
        return "<ul class='user-list'>" + items.join("") + "</ul>";
    }

    /**
     * Complex template composition
     */
    public static function renderComplexLayout(title: String, content: String): String {
        return "<!DOCTYPE html><html><head><title>" + title + "</title></head><body><h1>" + title + "</h1><main>" + content + "</main></body></html>";
    }
}

@:template
class FormTemplate {
    
    /**
     * Phoenix form template with CSRF protection
     */
    public static function renderForm(action: String, method: String): String {
        var csrf = getCsrfToken();
        return "<form action='" + action + "' method='" + method + "'>" +
               "<input type='hidden' name='_csrf_token' value='" + csrf + "'>" +
               "<div class='form-group'>" +
               "<label for='name'>Name:</label>" +
               "<input type='text' id='name' name='name' required>" +
               "</div>" +
               "<button type='submit'>Submit</button>" +
               "</form>";
    }

    /**
     * Template with error handling
     */
    public static function renderWithHelpers(errors: Array<String>): String {
        if (errors.length == 0) {
            return "<div class='no-errors'></div>";
        }
        
        var errorItems = [];
        for (error in errors) {
            errorItems.push("<li class='error-item'>" + error + "</li>");
        }
        return "<div class='form-errors'><ul class='error-list'>" + errorItems.join("") + "</ul></div>";
    }

    private static function getCsrfToken(): String {
        return "csrf_token_placeholder";
    }
}

/**
 * LiveView component template
 */
@:template 
class LiveViewComponents {
    
    /**
     * Interactive component with events
     */
    public static function renderCounter(count: Int): String {
        return "<div class='counter'>" +
               "<h3>Count: " + count + "</h3>" +
               "<button phx-click='increment'>+</button>" +
               "<button phx-click='decrement'>-</button>" +
               "<button phx-click='reset'>Reset</button>" +
               "</div>";
    }

    /**
     * Real-time updating template
     */
    public static function renderLiveData(data: {temperature: Float, humidity: Float}): String {
        return "<div class='sensor-data' phx-update='replace'>" +
               "<div class='temperature'>" +
               "<span class='label'>Temperature:</span>" +
               "<span class='value'>" + data.temperature + "°C</span>" +
               "</div>" +
               "<div class='humidity'>" +
               "<span class='label'>Humidity:</span>" +
               "<span class='value'>" + data.humidity + "%</span>" +
               "</div>" +
               "</div>";
    }
}

class Main {
    public static function main() {
        trace("Template compilation test");
    }
}