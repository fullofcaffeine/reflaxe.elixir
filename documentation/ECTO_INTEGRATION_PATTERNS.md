# Ecto Integration Patterns and Escape Hatches

This guide covers strategies for working with Ecto from Haxe, including handling complex queries that go beyond basic extern definitions.

## Table of Contents

- [Overview](#overview)
- [Basic Ecto Operations](#basic-ecto-operations)
- [Complex Query Escape Hatches](#complex-query-escape-hatches)
- [Recommended Architecture Patterns](#recommended-architecture-patterns)
- [Performance Considerations](#performance-considerations)
- [Migration Strategies](#migration-strategies)

## Overview

**The Challenge**: Ecto's query DSL is heavily macro-based and doesn't translate well to Haxe's type system.

**The Solution**: Use a **hybrid approach** - keep complex queries in Elixir, expose them through clean APIs, and call them from Haxe with full type safety.

## Basic Ecto Operations

These work well with simple extern definitions:

```haxe
// Basic CRUD operations via externs
@:native("MyApp.Repo")  
extern class Repo {
    @:native("get")
    public static function get(schema: Class<Dynamic>, id: Int): Dynamic;
    
    @:native("insert")
    public static function insert(changeset: Dynamic): Dynamic;
    
    @:native("all")
    public static function all(queryable: Dynamic): Array<Dynamic>;
}

@:native("User")
extern class User {
    @:native("changeset")
    public static function changeset(user: Dynamic, attrs: Dynamic): Dynamic;
}

// Usage - Simple operations work great
@:module
class UserService {
    function getUser(id: Int): Dynamic {
        return Repo.get(User, id);
    }
    
    function createUser(userData: Dynamic): Dynamic {
        var changeset = User.changeset({}, userData);
        return Repo.insert(changeset);
    }
}
```

## Complex Query Escape Hatches

For complex queries, use these patterns:

### Pattern 1: Elixir Query Modules ⭐ Recommended

**Create dedicated Elixir modules for complex queries:**

```elixir
# lib/my_app/queries/user_queries.ex
defmodule MyApp.Queries.UserQueries do
  import Ecto.Query
  alias MyApp.{Repo, User, Post, Comment}

  @doc "Find active users with post count and latest activity"
  def active_users_with_stats(since_date \\ Date.utc_today()) do
    from u in User,
      left_join: p in Post, on: p.user_id == u.id,
      left_join: c in Comment, on: c.user_id == u.id,
      where: u.active == true,
      where: u.last_login >= ^since_date,
      group_by: [u.id, u.name, u.email],
      select: %{
        id: u.id,
        name: u.name,
        email: u.email,
        post_count: count(p.id),
        comment_count: count(c.id),
        last_login: u.last_login
      },
      order_by: [desc: u.last_login]
  end

  @doc "Complex search with full-text and filters"
  def search_users(query_params) do
    base_query = from(u in User)
    
    base_query
    |> maybe_filter_by_name(query_params[:name])
    |> maybe_filter_by_role(query_params[:role])
    |> maybe_filter_by_date_range(query_params[:date_from], query_params[:date_to])
    |> maybe_search_content(query_params[:search])
    |> paginate(query_params[:page] || 1, query_params[:per_page] || 20)
  end

  @doc "Users with complex aggregations and subqueries"
  def top_contributors(limit \\ 10) do
    post_counts = from p in Post,
      group_by: p.user_id,
      select: %{user_id: p.user_id, post_count: count(p.id)}
    
    comment_counts = from c in Comment,
      group_by: c.user_id, 
      select: %{user_id: c.user_id, comment_count: count(c.id)}
    
    from u in User,
      join: pc in subquery(post_counts), on: pc.user_id == u.id,
      left_join: cc in subquery(comment_counts), on: cc.user_id == u.id,
      select: %{
        user: u,
        total_contributions: pc.post_count + coalesce(cc.comment_count, 0)
      },
      order_by: [desc: pc.post_count + coalesce(cc.comment_count, 0)],
      limit: ^limit
  end

  # Private helper functions for dynamic queries
  defp maybe_filter_by_name(query, nil), do: query
  defp maybe_filter_by_name(query, name) when is_binary(name) do
    from u in query, where: ilike(u.name, ^"%#{name}%")
  end

  defp maybe_filter_by_role(query, nil), do: query
  defp maybe_filter_by_role(query, role) do
    from u in query, where: u.role == ^role
  end

  defp maybe_search_content(query, nil), do: query
  defp maybe_search_content(query, search_term) do
    # Full-text search example
    from u in query,
      where: fragment("? @@ plainto_tsquery(?)", u.search_vector, ^search_term)
  end

  defp paginate(query, page, per_page) do
    offset = (page - 1) * per_page
    from q in query, limit: ^per_page, offset: ^offset
  end
end
```

**Expose through clean Haxe externs:**

```haxe
// Haxe extern for the query module
typedef UserStats = {
    var id: Int;
    var name: String;
    var email: String;
    var post_count: Int;
    var comment_count: Int;
    var last_login: String;
}

typedef SearchParams = {
    var ?name: String;
    var ?role: String;
    var ?search: String;
    var ?date_from: String;
    var ?date_to: String;
    var ?page: Int;
    var ?per_page: Int;
}

typedef TopContributor = {
    var user: Dynamic;
    var total_contributions: Int;
}

@:native("MyApp.Queries.UserQueries")
extern class UserQueries {
    @:native("active_users_with_stats")
    public static function activeUsersWithStats(?sinceDate: String): Array<UserStats>;
    
    @:native("search_users")
    public static function searchUsers(params: SearchParams): Array<Dynamic>;
    
    @:native("top_contributors")
    public static function topContributors(?limit: Int): Array<TopContributor>;
}

// Usage from Haxe - Clean and type-safe!
@:module
class UserAnalytics {
    function getActiveUserStats(): Array<UserStats> {
        var oneWeekAgo = DateTools.format(Date.now().getTime() - 7 * 24 * 60 * 60 * 1000);
        return UserQueries.activeUsersWithStats(oneWeekAgo);
    }
    
    function searchUsers(searchTerm: String, role: String): Array<Dynamic> {
        var params: SearchParams = {
            search: searchTerm,
            role: role,
            page: 1,
            per_page: 50
        };
        return UserQueries.searchUsers(params);
    }
    
    function getLeaderboard(): Array<TopContributor> {
        return UserQueries.topContributors(25);
    }
}
```

### Pattern 2: Raw SQL Escape Hatch

For ultimate flexibility, use raw SQL:

```elixir
# lib/my_app/queries/raw_queries.ex
defmodule MyApp.Queries.RawQueries do
  alias MyApp.Repo

  @doc "Execute raw SQL with parameters"
  def execute_raw(sql, params \\ []) do
    Ecto.Adapters.SQL.query!(Repo, sql, params)
  end

  @doc "Complex analytical query that's easier in raw SQL"
  def user_engagement_report(start_date, end_date) do
    sql = """
    WITH user_activity AS (
      SELECT 
        u.id,
        u.name,
        COUNT(DISTINCT p.id) as post_count,
        COUNT(DISTINCT c.id) as comment_count,
        COUNT(DISTINCT l.id) as like_count,
        AVG(p.view_count) as avg_post_views
      FROM users u
      LEFT JOIN posts p ON p.user_id = u.id 
        AND p.created_at BETWEEN $1 AND $2
      LEFT JOIN comments c ON c.user_id = u.id 
        AND c.created_at BETWEEN $1 AND $2  
      LEFT JOIN likes l ON l.user_id = u.id 
        AND l.created_at BETWEEN $1 AND $2
      GROUP BY u.id, u.name
    )
    SELECT 
      *,
      (post_count * 3 + comment_count * 2 + like_count) as engagement_score
    FROM user_activity 
    WHERE post_count > 0 OR comment_count > 0 OR like_count > 0
    ORDER BY engagement_score DESC
    LIMIT 100
    """
    
    execute_raw(sql, [start_date, end_date])
  end

  @doc "Database-specific optimized query"
  def complex_analytics_postgres do
    sql = """
    SELECT 
      date_trunc('day', created_at) as day,
      COUNT(*) as total_posts,
      COUNT(DISTINCT user_id) as unique_users,
      AVG(view_count) as avg_views,
      PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY view_count) as median_views
    FROM posts 
    WHERE created_at >= NOW() - INTERVAL '30 days'
    GROUP BY date_trunc('day', created_at)
    ORDER BY day DESC
    """
    
    execute_raw(sql)
  end
end
```

**Haxe integration:**

```haxe
typedef EngagementReport = {
    var id: Int;
    var name: String;
    var post_count: Int;
    var comment_count: Int;
    var like_count: Int;
    var avg_post_views: Float;
    var engagement_score: Int;
}

typedef AnalyticsRow = {
    var day: String;
    var total_posts: Int;
    var unique_users: Int;
    var avg_views: Float;
    var median_views: Float;
}

@:native("MyApp.Queries.RawQueries")
extern class RawQueries {
    @:native("user_engagement_report") 
    public static function userEngagementReport(startDate: String, endDate: String): {rows: Array<EngagementReport>};
    
    @:native("complex_analytics_postgres")
    public static function complexAnalyticsPostgres(): {rows: Array<AnalyticsRow>};
    
    @:native("execute_raw")
    public static function executeRaw(sql: String, ?params: Array<Dynamic>): {rows: Array<Dynamic>};
}

// Usage
@:module
class Analytics {
    function generateEngagementReport(days: Int): Array<EngagementReport> {
        var endDate = Date.now();
        var startDate = DateTools.delta(endDate, -days * 24 * 60 * 60 * 1000);
        
        var result = RawQueries.userEngagementReport(
            DateTools.format(startDate, "%Y-%m-%d"),
            DateTools.format(endDate, "%Y-%m-%d")
        );
        
        return result.rows;
    }
    
    function customQuery(sql: String, params: Array<Dynamic>): Array<Dynamic> {
        var result = RawQueries.executeRaw(sql, params);
        return result.rows;
    }
}
```

### Pattern 3: Dynamic Query Builder

Build queries programmatically in Elixir, control from Haxe:

```elixir
# lib/my_app/queries/dynamic_queries.ex
defmodule MyApp.Queries.DynamicQueries do
  import Ecto.Query
  alias MyApp.Repo

  @doc "Build query dynamically based on criteria map"
  def build_user_query(criteria) do
    from(u in User)
    |> apply_filters(criteria)
    |> apply_sorting(criteria[:sort] || %{})
    |> apply_pagination(criteria[:page] || 1, criteria[:per_page] || 20)
  end

  def execute_dynamic_query(criteria) do
    criteria
    |> build_user_query()
    |> Repo.all()
  end

  defp apply_filters(query, criteria) do
    Enum.reduce(criteria, query, fn {key, value}, acc ->
      apply_filter(acc, key, value)
    end)
  end

  defp apply_filter(query, :name_contains, value) do
    from u in query, where: ilike(u.name, ^"%#{value}%")
  end

  defp apply_filter(query, :age_range, %{min: min, max: max}) do
    from u in query, where: u.age >= ^min and u.age <= ^max
  end

  defp apply_filter(query, :created_after, date) do
    from u in query, where: u.inserted_at >= ^date
  end

  defp apply_filter(query, :has_posts, true) do
    from u in query,
      join: p in assoc(u, :posts),
      distinct: true
  end

  defp apply_filter(query, :role_in, roles) when is_list(roles) do
    from u in query, where: u.role in ^roles
  end

  defp apply_filter(query, _key, _value), do: query

  defp apply_sorting(query, %{field: field, direction: direction}) do
    case {field, direction} do
      {"name", "asc"} -> from u in query, order_by: [asc: u.name]
      {"name", "desc"} -> from u in query, order_by: [desc: u.name]
      {"created_at", "asc"} -> from u in query, order_by: [asc: u.inserted_at]
      {"created_at", "desc"} -> from u in query, order_by: [desc: u.inserted_at]
      _ -> query
    end
  end

  defp apply_sorting(query, _), do: query

  defp apply_pagination(query, page, per_page) do
    offset = (page - 1) * per_page
    from q in query, limit: ^per_page, offset: ^offset
  end
end
```

**Haxe integration with type-safe criteria:**

```haxe
typedef QueryCriteria = {
    var ?name_contains: String;
    var ?age_range: {min: Int, max: Int};
    var ?created_after: String;
    var ?has_posts: Bool;
    var ?role_in: Array<String>;
    var ?sort: {field: String, direction: String};
    var ?page: Int;
    var ?per_page: Int;
}

@:native("MyApp.Queries.DynamicQueries")
extern class DynamicQueries {
    @:native("execute_dynamic_query")
    public static function executeDynamicQuery(criteria: QueryCriteria): Array<Dynamic>;
}

// Usage - Build complex queries with type safety
@:module
class AdvancedUserSearch {
    function searchActiveAdults(nameFilter: String): Array<Dynamic> {
        var criteria: QueryCriteria = {
            name_contains: nameFilter,
            age_range: {min: 18, max: 65},
            has_posts: true,
            role_in: ["user", "moderator"],
            sort: {field: "created_at", direction: "desc"},
            page: 1,
            per_page: 50
        };
        
        return DynamicQueries.executeDynamicQuery(criteria);
    }
    
    function searchNewUsers(daysBack: Int): Array<Dynamic> {
        var cutoffDate = DateTools.format(
            DateTools.delta(Date.now(), -daysBack * 24 * 60 * 60 * 1000),
            "%Y-%m-%d"
        );
        
        var criteria: QueryCriteria = {
            created_after: cutoffDate,
            sort: {field: "name", direction: "asc"}
        };
        
        return DynamicQueries.executeDynamicQuery(criteria);
    }
}
```

## Recommended Architecture Patterns

### Pattern A: Repository + Query Layer (Best for Most Apps)

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Haxe Business │    │ Elixir Query     │    │ Database        │
│   Logic         │───▶│ Layer            │───▶│                 │
│                 │    │ (Complex Queries)│    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

**Haxe**: Business logic, validation, orchestration  
**Elixir**: Complex queries, database operations, schema management

### Pattern B: CQRS with Elixir Queries

```
┌─────────────┐    ┌─────────────┐    ┌─────────────────┐
│ Haxe        │    │ Elixir      │    │ Database        │
│ Commands    │───▶│ Write Ops   │───▶│                 │
└─────────────┘    └─────────────┘    │                 │
┌─────────────┐    ┌─────────────┐    │                 │
│ Haxe        │    │ Elixir      │    │                 │
│ Queries     │───▶│ Read Ops    │───▶│                 │
└─────────────┘    └─────────────┘    └─────────────────┘
```

**Haxe**: Command validation, query coordination  
**Elixir**: All database operations, complex read models

## Performance Considerations

### Query Performance ✅ Native Elixir Speed
- Elixir query modules run at full native speed
- No overhead from Haxe compilation
- Full access to Ecto's query optimization

### Development Speed ✅ Best of Both Worlds  
- Complex queries written in Elixir (faster development)
- Business logic in Haxe (better type safety)
- Clear separation of concerns

### Maintenance ✅ Clean Architecture
- Database experts can optimize queries in Elixir
- Application developers get type-safe APIs in Haxe
- Changes to query internals don't affect Haxe code

## Migration Strategies

### For Existing Phoenix Apps

**Phase 1: Extract Query Modules**
```elixir
# Before: Queries scattered throughout controllers/contexts
def index(conn, params) do
  users = from(u in User, where: u.active == true) |> Repo.all()
  # ...
end

# After: Centralized query modules  
def index(conn, params) do
  users = UserQueries.active_users()
  # ...
end
```

**Phase 2: Add Haxe Business Logic**
```haxe
// New business logic in Haxe
@:module
class UserController {
    function index(conn: Dynamic, params: Dynamic): Dynamic {
        var users = UserQueries.activeUsers();
        var processedUsers = processUsersForDisplay(users);
        return Phoenix.Controller.render(conn, "index.html", {users: processedUsers});
    }
}
```

**Phase 3: Gradual Migration**
- Move controller logic to Haxe
- Keep complex queries in Elixir
- Add type safety incrementally

### For New Projects

**Start with Hybrid Architecture:**
1. **Schema & Migrations**: Pure Elixir
2. **Complex Queries**: Elixir query modules  
3. **Business Logic**: Haxe with type safety
4. **Controllers/LiveView**: Mix based on complexity

## Example: Real-World E-commerce Query

```elixir
# Complex e-commerce query in Elixir
defmodule Shop.Queries.ProductQueries do
  def featured_products_with_inventory(category_id, limit \\ 12) do
    from p in Product,
      join: c in Category, on: c.id == p.category_id,
      join: i in Inventory, on: i.product_id == p.id,
      left_join: d in Discount, on: d.product_id == p.id and d.active == true,
      left_join: r in Review, on: r.product_id == p.id,
      where: p.featured == true,
      where: i.quantity > 0,
      where: c.id == ^category_id or is_nil(^category_id),
      group_by: [p.id, p.name, p.price, p.image_url, i.quantity],
      select: %{
        id: p.id,
        name: p.name,
        price: p.price,
        discounted_price: coalesce(d.discounted_price, p.price),
        image_url: p.image_url,
        in_stock: i.quantity,
        avg_rating: avg(r.rating),
        review_count: count(r.id)
      },
      order_by: [desc: :avg_rating, desc: p.featured_at],
      limit: ^limit
  end
end
```

```haxe
// Clean, typed interface in Haxe
typedef FeaturedProduct = {
    var id: Int;
    var name: String;
    var price: Float;
    var discounted_price: Float;
    var image_url: String;
    var in_stock: Int;
    var avg_rating: Null<Float>;
    var review_count: Int;
}

@:native("Shop.Queries.ProductQueries")
extern class ProductQueries {
    @:native("featured_products_with_inventory")
    public static function featuredProductsWithInventory(?categoryId: Int, ?limit: Int): Array<FeaturedProduct>;
}

// Business logic with full type safety
@:module
class ProductService {
    function getFeaturedProducts(categoryId: Null<Int> = null): Array<FeaturedProduct> {
        var products = ProductQueries.featuredProductsWithInventory(categoryId, 12);
        
        return products.map(function(product) {
            return {
                id: product.id,
                name: product.name,
                price: product.price,
                discounted_price: product.discounted_price,
                image_url: product.image_url,
                in_stock: product.in_stock,
                avg_rating: product.avg_rating,
                review_count: product.review_count,
                // Add computed fields with type safety
                has_discount: product.discounted_price < product.price,
                stock_status: product.in_stock > 10 ? "in_stock" : "limited",
                display_rating: product.avg_rating != null ? Math.round(product.avg_rating * 10) / 10 : 0.0
            };
        });
    }
}
```

## Conclusion

Complex Ecto queries don't have to be a limitation. The hybrid approach gives you:

- ✅ **Full Ecto Power**: Use every Ecto feature in dedicated Elixir modules
- ✅ **Type Safety**: Clean, typed APIs consumed from Haxe  
- ✅ **Performance**: Native Elixir query execution speed
- ✅ **Maintainability**: Clear separation between data access and business logic
- ✅ **Flexibility**: Raw SQL escape hatch for ultimate control

**Recommendation**: Start with Pattern 1 (Elixir Query Modules) for most applications. It provides the best balance of power, maintainability, and type safety.