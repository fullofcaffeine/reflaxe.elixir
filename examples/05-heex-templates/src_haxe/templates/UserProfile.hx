package templates;

import HXX.*;

/**
 * HEEx template example using Haxe→Elixir compilation
 * Demonstrates type-safe Phoenix template generation
 */
@:template("user_profile.html.heex")
class UserProfile {
    
    /**
     * Main template render function
     */
    public static function render(assigns: UserAssigns): String {
        return hxx('
        <div class="user-profile">
            <div class="header">
                <h1>Welcome, ${assigns.user.name}!</h1>
                <span class="status ${assigns.user.active ? "online" : "offline"}">
                    ${assigns.user.active ? "Online" : "Offline"}
                </span>
            </div>
            
            <div class="user-info">
                <div class="field">
                    <label>Email:</label>
                    <span>${assigns.user.email}</span>
                </div>
                
                <div class="field">
                    <label>Member since:</label>
                    <span>${formatDate(assigns.user.insertedAt)}</span>
                </div>
                
                ${renderPosts(assigns.posts)}
            </div>
            
            <div class="actions">
                <.button type="primary" phx-click="edit_profile">
                    Edit Profile
                </.button>
                
                <.button type="secondary" phx-click="view_settings">
                    Settings  
                </.button>
            </div>
        </div>
        ');
    }
    
    /**
     * Sub-template for rendering user posts
     */
    static function renderPosts(posts: Array<Post>): String {
        if (posts.length == 0) {
            return hxx('<div class="no-posts">No posts yet!</div>');
        }
        
        return hxx('
        <div class="posts-section">
            <h3>Recent Posts (${posts.length})</h3>
            <div class="posts-list">
                ${posts.map(renderPost).join("")}
            </div>
        </div>
        ');
    }
    
    /**
     * Individual post template
     */
    static function renderPost(post: Post): String {
        return hxx('
        <div class="post">
            <h4>${post.title}</h4>
            <p class="content">${truncate(post.content, 100)}</p>
            <div class="meta">
                <span class="date">${formatDate(post.insertedAt)}</span>
                <span class="views">${post.viewCount} views</span>
            </div>
        </div>
        ');
    }
    
    // Helper functions
    static function formatDate(date: String): String {
        return date; // Would format date properly
    }
    
    static function truncate(text: String, length: Int): String {
        return text.length > length ? text.substr(0, length) + "..." : text;
    }
    
    // Main function for compilation
    public static function main(): Void {
        trace("UserProfile template compiled successfully!");
    }
}

// Type definitions
typedef UserAssigns = {
    user: User,
    posts: Array<Post>
}

typedef User = {
    name: String,
    email: String, 
    active: Bool,
    insertedAt: String
}

typedef Post = {
    title: String,
    content: String,
    viewCount: Int,
    insertedAt: String
}