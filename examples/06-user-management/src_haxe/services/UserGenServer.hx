package services;

import contexts.Users;
import contexts.Users.User;
import contexts.Users.UserStats;
import elixir.types.Term;

private enum UserCallRequest {
    GetUser(userId: Int);
    GetStats;
    CacheUser(user: User);
    ClearCache;
}

private enum UserCastMessage {
    RefreshStats;
    InvalidateUserCache;
    PreloadActiveUsers;
}

private enum UserInfoMessage {
    StatsRefreshTimer;
    CleanupCache;
}

private typedef UserGenServerState = {
    userCache: Map<Int, User>,
    statsCache: Null<UserStats>,
    lastStatsUpdate: Float
}

private typedef UserGenServerCallResponse = {
    status: String,
    response: Term,
    state: UserGenServerState
}

private typedef UserGenServerCastResponse = {
    status: String,
    state: UserGenServerState
}

/**
 * OTP GenServer for user-related background processes
 * Demonstrates caching, background jobs, and user analytics
 */
@:genserver
class UserGenServer {
    private static inline function makeState(userCache: Map<Int, User>, statsCache: Null<UserStats>, lastStatsUpdate: Float): UserGenServerState {
        return {userCache: userCache, statsCache: statsCache, lastStatsUpdate: lastStatsUpdate};
    }

    function init(_initialState: Term): {status: String, state: UserGenServerState} {
        trace("UserGenServer starting...");
        scheduleStatsRefresh();

        var userCache: Map<Int, User> = new Map();
        return {status: "ok", state: makeState(userCache, null, 0)};
    }

    function handle_call(request: UserCallRequest, _from: Term, state: UserGenServerState): UserGenServerCallResponse {
        return switch (request) {
            case GetUser(userId):
                handleGetUser(userId, state);
            case GetStats:
                handleGetStats(state);
            case CacheUser(user):
                handleCacheUser(user, state);
            case ClearCache:
                handleClearCache();
        }
    }

    function handle_cast(message: UserCastMessage, state: UserGenServerState): UserGenServerCastResponse {
        return switch (message) {
            case RefreshStats:
                handleRefreshStats(state);
            case InvalidateUserCache:
                handleInvalidateUserCache(state);
            case PreloadActiveUsers:
                handlePreloadActiveUsers(state);
        }
    }

    function handle_info(message: UserInfoMessage, state: UserGenServerState): UserGenServerCastResponse {
        return switch (message) {
            case StatsRefreshTimer:
                var refreshed = refreshUserStats(state);
                scheduleStatsRefresh();
                {status: "noreply", state: refreshed};
            case CleanupCache:
                var cleaned = cleanupOldCacheEntries(state);
                {status: "noreply", state: cleaned};
        }
    }

    // Call handlers
    private function handleGetUser(userId: Int, state: UserGenServerState): UserGenServerCallResponse {
        if (state.userCache.exists(userId)) {
            var user = state.userCache.get(userId);
            return {status: "reply", response: {user: user}, state: state};
        }

        var loaded = Users.get_user_safe(userId);
        if (loaded != null) {
            state.userCache.set(userId, loaded);
            return {status: "reply", response: {user: loaded}, state: state};
        }

        return {status: "reply", response: "user_not_found", state: state};
    }

    private function handleGetStats(state: UserGenServerState): UserGenServerCallResponse {
        var now = Date.now().getTime();
        var cacheAge = now - state.lastStatsUpdate;

        if (state.statsCache != null && cacheAge < 300000) {
            return {status: "reply", response: state.statsCache, state: state};
        }

        var stats = Users.user_stats();
        var updated = makeState(state.userCache, stats, now);
        return {status: "reply", response: stats, state: updated};
    }

    private function handleCacheUser(user: User, state: UserGenServerState): UserGenServerCallResponse {
        state.userCache.set(user.id, user);
        return {status: "reply", response: "cached", state: state};
    }

    private function handleClearCache(): UserGenServerCallResponse {
        var cleared = makeState(new Map(), null, 0);
        return {status: "reply", response: "cache_cleared", state: cleared};
    }

    // Cast handlers
    private function handleRefreshStats(state: UserGenServerState): UserGenServerCastResponse {
        var stats = Users.user_stats();
        var updatedAt = Date.now().getTime();
        var updated = makeState(state.userCache, stats, updatedAt);
        return {status: "noreply", state: updated};
    }

    private function handleInvalidateUserCache(state: UserGenServerState): UserGenServerCastResponse {
        var updated = makeState(new Map(), state.statsCache, state.lastStatsUpdate);
        return {status: "noreply", state: updated};
    }

    private function handlePreloadActiveUsers(state: UserGenServerState): UserGenServerCastResponse {
        var activeUsers = Users.list_users({active: true});
        var updatedCache: Map<Int, User> = new Map();

        for (user in activeUsers) {
            updatedCache.set(user.id, user);
        }

        trace('Preloaded ${activeUsers.length} active users into cache');
        var updated = makeState(updatedCache, state.statsCache, state.lastStatsUpdate);
        return {status: "noreply", state: updated};
    }

    // Helpers
    private function refreshUserStats(state: UserGenServerState): UserGenServerState {
        var stats = Users.user_stats();
        return makeState(state.userCache, stats, Date.now().getTime());
    }

    private function cleanupOldCacheEntries(state: UserGenServerState): UserGenServerState {
        var keyArray = [for (key in state.userCache.keys()) key];
        trace('User cache contains ${keyArray.length} entries');
        return state;
    }

    private function scheduleStatsRefresh(): Void {
        trace("Scheduling stats refresh in 5 minutes");
    }

    public static function main(): Void {
        trace("UserGenServer with @:genserver annotation compiled successfully!");
    }
}

/**
 * Public API for interacting with UserGenServer
 */
class UserService {
    static var serverName = "UserGenServer";

    public static function getCachedUser(userId: Int): User {
        // Would call GenServer.call(serverName, {:get_user, userId})
        return null;
    }

    public static function getUserStats(): UserStats {
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

    public static function main(): Void {
        trace("UserService compiled successfully!");
    }
}
