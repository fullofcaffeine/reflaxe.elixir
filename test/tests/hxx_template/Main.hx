/**
 * HXX Template Compilation Test
 * Tests HTML-like template syntax compilation to Elixir/Phoenix templates
 * Converted from framework-based HXX template tests to snapshot test
 */

@:template
class UserProfileTemplate {
    
    /**
     * Basic HXX template with interpolation
     */
    public static function renderProfile(user: {name: String, age: Int}): String {
        return '
        <div class="user-profile">
            <h1>{user.name}</h1>
            <p>Age: {user.age}</p>
        </div>
        ';
    }

    /**
     * Template with conditional rendering
     */
    public static function renderWithCondition(user: {name: String, isAdmin: Bool}): String {
        return '
        <div class="user-info">
            <h2>{user.name}</h2>
            {if (user.isAdmin) 
                '<span class="admin-badge">Admin</span>'
            else
                '<span class="user-badge">User</span>'
            }
        </div>
        ';
    }

    /**
     * Template with loops
     */
    public static function renderUserList(users: Array<{name: String, email: String}>): String {
        return '
        <ul class="user-list">
            {for (user in users) 
                '<li><strong>{user.name}</strong> - {user.email}</li>'
            }
        </ul>
        ';
    }

    /**
     * Nested template with components
     */
    public static function renderComplexLayout(title: String, content: String): String {
        return '
        <!DOCTYPE html>
        <html>
            <head>
                <title>{title}</title>
                <meta charset="utf-8">
            </head>
            <body>
                <header class="main-header">
                    <h1>{title}</h1>
                </header>
                <main class="content">
                    {content}
                </main>
                <footer>
                    <p>&copy; 2024 My App</p>
                </footer>
            </body>
        </html>
        ';
    }
}

@:template
class FormTemplate {
    
    /**
     * Phoenix form template with CSRF protection
     */
    public static function renderForm(action: String, method: String): String {
        return '
        <form action="{action}" method="{method}">
            <input type="hidden" name="_csrf_token" value="{getCsrfToken()}">
            <div class="form-group">
                <label for="name">Name:</label>
                <input type="text" id="name" name="name" required>
            </div>
            <div class="form-group">
                <label for="email">Email:</label>
                <input type="email" id="email" name="email" required>
            </div>
            <button type="submit">Submit</button>
        </form>
        ';
    }

    /**
     * Template with Phoenix helper functions
     */
    public static function renderWithHelpers(errors: Array<String>): String {
        return '
        <div class="form-errors">
            {if (errors.length > 0)
                '<ul class="error-list">
                    {for (error in errors)
                        '<li class="error-item">{error}</li>'
                    }
                </ul>'
            }
        </div>
        ';
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
        return '
        <div class="counter">
            <h3>Count: {count}</h3>
            <button phx-click="increment">+</button>
            <button phx-click="decrement">-</button>
            <button phx-click="reset">Reset</button>
        </div>
        ';
    }

    /**
     * Real-time updating template
     */
    public static function renderLiveData(data: {temperature: Float, humidity: Float}): String {
        return '
        <div class="sensor-data" phx-update="replace">
            <div class="temperature">
                <span class="label">Temperature:</span>
                <span class="value">{data.temperature}°C</span>
            </div>
            <div class="humidity">
                <span class="label">Humidity:</span>
                <span class="value">{data.humidity}%</span>
            </div>
        </div>
        ';
    }
}

class Main {
    public static function main() {
        trace("HXX template compilation test");
    }
}