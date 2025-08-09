package services;

import contexts.Users;
import contexts.Users.User;

/**
 * OTP GenServer for user-related background processes
 * Demonstrates caching, background jobs, and user analytics
 */
@:genserver
class UserGenServer {
    var userCache: Map<Int, User> = new Map();
    var statsCache: Dynamic = null;
    var lastStatsUpdate: Float = 0;
    
    function init(initialState: Dynamic): {status: String, state: Dynamic} {
        // Initialize the GenServer with empty cache
        trace("UserGenServer starting...");
        
        // Schedule periodic stats refresh
        scheduleStatsRefresh();
        
        return {
            status: "ok",
            state: {
                userCache: userCache,
                statsCache: null,
                lastStatsUpdate: 0
            }
        };
    }
    
    function handle_call(request: String, from: Dynamic, state: Dynamic): CallResponse {
        return switch(request) {
            case "get_user":
                handleGetUser(from, state);
                
            case "get_stats":
                handleGetStats(from, state);
                
            case "cache_user":
                handleCacheUser(from, state);
                
            case "clear_cache":
                handleClearCache(from, state);
                
            default:
                {status: "reply", response: "unknown_request", state: state};
        }
    }
    
    function handle_cast(message: String, state: Dynamic): {status: String, state: Dynamic} {
        return switch(message) {
            case "refresh_stats":
                handleRefreshStats(state);
                
            case "invalidate_user_cache":
                handleInvalidateUserCache(state);
                
            case "preload_active_users":
                handlePreloadActiveUsers(state);
                
            default:
                {status: "noreply", state: state};
        }
    }
    
    function handle_info(message: String, state: Dynamic): {status: String, state: Dynamic} {
        return switch(message) {
            case "stats_refresh_timer":
                // Periodic stats refresh
                var newState = refreshUserStats(state);
                scheduleStatsRefresh(); // Reschedule
                {status: "noreply", state: newState};
                
            case "cleanup_cache":
                // Periodic cache cleanup
                var newState = cleanupOldCacheEntries(state);
                {status: "noreply", state: newState};
                
            default:
                {status: "noreply", state: state};
        }
    }
    
    // Call handlers
    function handleGetUser(from: Dynamic, state: Dynamic): CallResponse {
        var userId = from.userId; // Would extract from proper message format
        
        if (userCache.exists(userId)) {
            var user = userCache.get(userId);
            return {status: "reply", response: {user: user}, state: state};
        } else {
            // Load from database and cache
            var user = Users.get_user_safe(userId);
            if (user != null) {
                userCache.set(userId, user);
                return {status: "reply", response: {user: user}, state: updateState(state, "userCache", userCache)};
            } else {
                return {status: "reply", response: "user_not_found", state: state};
            }
        }
    }
    
    function handleGetStats(from: Dynamic, state: Dynamic): CallResponse {
        var now = Date.now().getTime();
        var cacheAge = now - lastStatsUpdate;
        
        // Return cached stats if less than 5 minutes old
        if (statsCache != null && cacheAge < 300000) {
            return {status: "reply", response: statsCache, state: state};
        } else {
            // Refresh stats and cache
            var stats = Users.user_stats();
            statsCache = stats;
            lastStatsUpdate = now;
            
            return {
                status: "reply", 
                response: stats, 
                state: updateStateMultiple(state, {
                    statsCache: stats,
                    lastStatsUpdate: now
                })
            };
        }
    }
    
    function handleCacheUser(from: Dynamic, state: Dynamic): CallResponse {
        var user = from.user; // Would extract from proper message format
        userCache.set(user.id, user);
        
        return {
            status: "reply",
            response: "cached",
            state: updateState(state, "userCache", userCache)
        };
    }
    
    function handleClearCache(from: Dynamic, state: Dynamic): CallResponse {
        userCache = new Map();
        statsCache = null;
        lastStatsUpdate = 0;
        
        return {
            status: "reply",
            response: "cache_cleared",
            state: {
                userCache: userCache,
                statsCache: null,
                lastStatsUpdate: 0
            }
        };
    }
    
    // Cast handlers
    function handleRefreshStats(state: Dynamic): {status: String, state: Dynamic} {
        var stats = Users.user_stats();
        statsCache = stats;
        lastStatsUpdate = Date.now().getTime();
        
        return {
            status: "noreply",
            state: updateStateMultiple(state, {
                statsCache: stats,
                lastStatsUpdate: lastStatsUpdate
            })
        };
    }
    
    function handleInvalidateUserCache(state: Dynamic): {status: String, state: Dynamic} {
        userCache = new Map();
        
        return {
            status: "noreply",
            state: updateState(state, "userCache", userCache)
        };
    }
    
    function handlePreloadActiveUsers(state: Dynamic): {status: String, state: Dynamic} {
        var activeUsers = Users.list_users({active: true});
        
        for (user in activeUsers) {
            userCache.set(user.id, user);
        }
        
        trace('Preloaded ${activeUsers.length} active users into cache');
        
        return {
            status: "noreply",
            state: updateState(state, "userCache", userCache)
        };
    }
    
    // Helper functions
    function refreshUserStats(state: Dynamic): Dynamic {
        var stats = Users.user_stats();
        return updateStateMultiple(state, {
            statsCache: stats,
            lastStatsUpdate: Date.now().getTime()
        });
    }
    
    function cleanupOldCacheEntries(state: Dynamic): Dynamic {
        // In a real implementation, would remove entries older than X time
        // For demo, just log cache size
        var keyArray = [for (key in userCache.keys()) key];
        trace('User cache contains ${keyArray.length} entries');
        return state;
    }
    
    function scheduleStatsRefresh(): Void {
        // Would schedule timer message - implementation varies by platform
        trace("Scheduling stats refresh in 5 minutes");
    }
    
    function updateState(state: Dynamic, key: String, value: Dynamic): Dynamic {
        // Helper to update state
        return state;
    }
    
    function updateStateMultiple(state: Dynamic, updates: Dynamic): Dynamic {
        // Helper to update multiple state fields
        return state;
    }
    
    // Main function for compilation testing
    public static function main(): Void {
        trace("UserGenServer with @:genserver annotation compiled successfully!");
    }
}

// Public API for interacting with UserGenServer
class UserService {
    static var serverName = "UserGenServer";
    
    public static function getCachedUser(userId: Int): User {
        // Would call GenServer.call(serverName, {:get_user, userId})
        return null;
    }
    
    public static function getUserStats(): Dynamic {
        // Would call GenServer.call(serverName, :get_stats)
        return null;
    }
    
    public static function cacheUser(user: User): Void {
        // Would call GenServer.cast(serverName, {:cache_user, user})
    }
    
    public static function refreshStats(): Void {
        // Would call GenServer.cast(serverName, :refresh_stats)
    }
    
    public static function clearCache(): Void {
        // Would call GenServer.call(serverName, :clear_cache)
    }
    
    // Main function for compilation testing
    public static function main(): Void {
        trace("UserGenServer with @:genserver annotation compiled successfully!");
    }
}

// Type definitions
typedef CallResponse = {
    status: String,
    response: Dynamic,
    state: Dynamic
}