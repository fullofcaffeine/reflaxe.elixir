package test.fixtures;

#if (macro || reflaxe_runtime)

/**
 * Sample HXX templates for testing various transformation scenarios
 * Demonstrates different LiveView features and syntax patterns
 */
class TestTemplates {
    
    /**
     * Basic element with LiveView directive
     */
    public static var BASIC_CONDITIONAL = '<div lv:if="show_content" class="container">{message}</div>';
    
    /**
     * Loop rendering with LiveView directive
     */
    public static var BASIC_LOOP = '<li lv:for="user <- users" class="user-item">{user.name}</li>';
    
    /**
     * Component with props
     */
    public static var BASIC_COMPONENT = '<UserCard user={current_user} active={is_active} />';
    
    /**
     * Component with slots
     */
    public static var COMPONENT_WITH_SLOTS = '<Modal title={modal_title}>
        <lv:slot name="header">
            <h2>{header_text}</h2>
        </lv:slot>
        <lv:slot name="footer">
            <button phx-click="close_modal">Close</button>
        </lv:slot>
    </Modal>';
    
    /**
     * Complex nested template with multiple features
     */
    public static var COMPLEX_TEMPLATE = '<div class="dashboard" lv:if="user_authenticated">
        <Header title={page_title} user={current_user} />
        
        <div class="content">
            <UserList lv:if="show_users">
                <li lv:for="user <- filtered_users" class="user-row">
                    <UserCard user={user} />
                </li>
            </UserList>
            
            <EmptyState lv:unless="has_users" message="No users found" />
        </div>
        
        <Footer>
            <lv:slot name="actions">
                <button phx-click="refresh" class="btn-primary">Refresh</button>
                <button phx-click="add_user" class="btn-secondary">Add User</button>
            </lv:slot>
        </Footer>
    </div>';
    
    /**
     * Form template with event handlers
     */
    public static var FORM_TEMPLATE = '<form onSubmit="save_user" class="user-form">
        <input 
            type="text" 
            name="name" 
            value={user.name} 
            onChange="validate_name"
            placeholder="Enter name"
        />
        <input 
            type="email" 
            name="email" 
            value={user.email}
            onChange="validate_email" 
            placeholder="Enter email"
        />
        <button type="submit" disabled={!form_valid}>Save User</button>
    </form>';
    
    /**
     * Navigation template with LiveView directives
     */
    public static var NAVIGATION_TEMPLATE = '<nav class="main-nav">
        <a lv:patch="/dashboard" class="nav-link">Dashboard</a>
        <a lv:patch="/users" class="nav-link">Users</a>
        <a lv:navigate="/profile" class="nav-link">Profile</a>
        <button phx-click="logout" class="logout-btn">Logout</button>
    </nav>';
    
    /**
     * Stream template for real-time updates
     */
    public static var STREAM_TEMPLATE = '<div class="messages" lv:stream="messages">
        <MessageCard 
            lv:for="message <- messages" 
            message={message}
            user={message.user}
        />
    </div>';
    
    /**
     * Conditional rendering with complex expressions
     */
    public static var CONDITIONAL_TEMPLATE = '<div class="user-profile">
        <Avatar lv:if="user.avatar_url" src={user.avatar_url} />
        <DefaultAvatar lv:unless="user.avatar_url" />
        
        <div lv:if="user.is_premium" class="premium-badge">
            Premium Member
        </div>
        
        <AdminPanel lv:if="user.role == \\"admin\\"" user={user} />
    </div>';
    
    /**
     * Expected HEEx outputs for testing
     */
    public static var EXPECTED_BASIC_CONDITIONAL = '<div :if={@show_content} class="container"><%= @message %></div>';
    
    public static var EXPECTED_BASIC_LOOP = '<li :for={@user <- users} class="user-item"><%= @user.name %></li>';
    
    public static var EXPECTED_BASIC_COMPONENT = '<.usercard user={@current_user} active={@is_active} />';
    
    public static var EXPECTED_FORM_FRAGMENT = 'phx-submit="save_user"';
    
    /**
     * Test cases with expected results
     */
    public static var TEST_CASES = [
        {
            name: "Basic Conditional",
            input: BASIC_CONDITIONAL,
            expectedContains: [":if={@show_content}", "class=\"container\"", "<%= @message %>"]
        },
        {
            name: "Basic Loop", 
            input: BASIC_LOOP,
            expectedContains: [":for={@user <- users}", "class=\"user-item\"", "<%= @user.name %>"]
        },
        {
            name: "Basic Component",
            input: BASIC_COMPONENT, 
            expectedContains: ["<.usercard", "user={@current_user}", "active={@is_active}"]
        }
    ];
    
    /**
     * Performance test templates of varying complexity
     */
    public static function generatePerformanceTemplate(complexity: Int): String {
        var template = '<div class="test-${complexity}">';
        
        for (i in 0...complexity) {
            template += '<div lv:if="condition_${i}">
                <Component_${i} prop={value_${i}} />
                <span>{text_${i}}</span>
            </div>';
        }
        
        template += '</div>';
        return template;
    }
    
    /**
     * Malformed templates for error testing
     */
    public static var MALFORMED_TEMPLATES = [
        '<div><span>Unclosed span', // Missing closing tag
        '<div lv:unknown="value">Content</div>', // Unknown directive
        '<Component user_id="not_numeric" />', // Invalid prop type
        '<lv:slot>Missing name attribute</lv:slot>' // Invalid slot
    ];
}

#end