# Advanced Ecto Guide for Reflaxe.Elixir

This comprehensive guide covers all advanced Ecto features available in Reflaxe.Elixir, with working examples and best practices for production applications.

## Table of Contents
- [Overview](#overview)
- [Schema Definitions](#schema-definitions)
- [Associations](#associations)
- [Changesets and Validations](#changesets-and-validations)
- [Advanced Queries](#advanced-queries)
- [Migrations](#migrations)
- [Repository Patterns](#repository-patterns)
- [Context Modules](#context-modules)
- [LiveView Integration](#liveview-integration)
- [Performance Optimization](#performance-optimization)
- [Best Practices](#best-practices)

## Overview

Reflaxe.Elixir provides comprehensive Ecto support through annotations and compilation helpers, enabling you to leverage Haxe's type safety while working with Elixir's powerful database layer.

### Key Features
- Full schema definition with all field types
- Complete association support (belongs_to, has_many, has_one, many_to_many)
- Changeset validation pipelines
- Advanced query capabilities (subqueries, CTEs, window functions)
- Migration DSL with table operations
- Repository pattern implementation
- Phoenix context integration
- LiveView real-time updates

## Schema Definitions

### Basic Schema

```haxe
@:schema("users")
class User {
    public var id: Int;
    public var name: String;
    public var email: String;
    public var age: Int;
    public var active: Bool = true;
    
    @:timestamps
    public var inserted_at: Dynamic;
    public var updated_at: Dynamic;
}
```

Compiles to:
```elixir
defmodule User do
  use Ecto.Schema
  
  schema "users" do
    field :name, :string
    field :email, :string
    field :age, :integer
    field :active, :boolean, default: true
    timestamps()
  end
end
```

### Advanced Field Types

**Note**: Haxe metadata supports complex object syntax with named parameters. However, avoid reserved keywords like `default`. Use `defaultValue` instead.

```haxe
@:schema("products")
class Product {
    @:primary_key
    public var id: Int;
    
    @:field({type: "string", nullable: false})
    public var name: String;
    
    @:field({type: "decimal", precision: 10, scale: 2})
    public var price: Float;
    
    @:field({type: "text"})
    public var description: String;
    
    @:field({type: "map"})
    public var metadata: Dynamic;
    
    @:field({type: "array", of: "string"})
    public var tags: Array<String>;
    
    @:field({type: "datetime"})
    public var published_at: Date;
    
    @:field({type: "uuid"})
    public var external_id: String;
    
    @:field({type: "boolean", defaultValue: true})  // Note: use defaultValue, not default
    public var active: Bool;
}
```

### Embedded Schemas

```haxe
@:embedded_schema
class Address {
    public var street: String;
    public var city: String;
    public var state: String;
    public var zip: String;
    public var country: String = "USA";
}

@:schema("companies")
class Company {
    public var id: Int;
    public var name: String;
    
    @:embeds_one("address", "Address")
    public var address: Address;
    
    @:embeds_many("locations", "Address")
    public var locations: Array<Address>;
}
```

## Associations

### One-to-Many Relationship

```haxe
@:schema("authors")
class Author {
    public var id: Int;
    public var name: String;
    
    @:has_many("books", "Book")
    public var books: Array<Book>;
}

@:schema("books")
class Book {
    public var id: Int;
    public var title: String;
    
    @:belongs_to("author", "Author")
    public var author: Author;
    public var author_id: Int;
}
```

### Many-to-Many Relationship

```haxe
@:schema("posts")
class Post {
    public var id: Int;
    public var title: String;
    
    @:many_to_many("tags", "Tag", through: "posts_tags")
    public var tags: Array<Tag>;
}

@:schema("tags")
class Tag {
    public var id: Int;
    public var name: String;
    
    @:many_to_many("posts", "Post", through: "posts_tags")
    public var posts: Array<Post>;
}

@:schema("posts_tags")
class PostTag {
    @:belongs_to("post", "Post")
    public var post: Post;
    public var post_id: Int;
    
    @:belongs_to("tag", "Tag")
    public var tag: Tag;
    public var tag_id: Int;
}
```

### Polymorphic Associations

```haxe
@:schema("comments")
class Comment {
    public var id: Int;
    public var body: String;
    
    // Polymorphic association
    public var commentable_id: Int;
    public var commentable_type: String;
}

// Usage in different schemas
@:schema("posts")
class Post {
    @:has_many("comments", "Comment", 
        foreign_key: "commentable_id", 
        where: {commentable_type: "Post"})
    public var comments: Array<Comment>;
}

@:schema("videos")
class Video {
    @:has_many("comments", "Comment",
        foreign_key: "commentable_id",
        where: {commentable_type: "Video"})
    public var comments: Array<Comment>;
}
```

## Changesets and Validations

### Basic Changeset

```haxe
@:changeset
class UserChangeset {
    public static function changeset(user: User, params: Dynamic): Dynamic {
        return user
            |> cast(params, ["name", "email", "age"])
            |> validateRequired(["name", "email"])
            |> validateFormat("email", ~r/@/)
            |> uniqueConstraint("email");
    }
}
```

### Advanced Validations

```haxe
@:changeset
class ProductChangeset {
    public static function changeset(product: Product, params: Dynamic): Dynamic {
        return product
            |> cast(params, ["name", "price", "description", "tags"])
            |> validateRequired(["name", "price"])
            |> validateNumber("price", greaterThan: 0, lessThanOrEqualTo: 99999.99)
            |> validateLength("name", min: 3, max: 100)
            |> validateLength("description", max: 5000)
            |> validateInclusion("status", ["draft", "published", "archived"])
            |> validateExclusion("name", ["admin", "root", "system"])
            |> validateChange("tags", validateTags)
            |> uniqueConstraint("name", name: "products_name_index")
            |> checkConstraint("price", name: "price_must_be_positive")
            |> optimisticLock("version");
    }
    
    private static function validateTags(changeset: Dynamic, field: String, tags: Array<String>): Dynamic {
        if (tags.length > 10) {
            return addError(changeset, field, "cannot have more than 10 tags");
        }
        for (tag in tags) {
            if (tag.length > 50) {
                return addError(changeset, field, "tag '${tag}' is too long");
            }
        }
        return changeset;
    }
    
    public static function registrationChangeset(product: Product, params: Dynamic): Dynamic {
        return product
            |> changeset(params)
            |> castAssoc("category", required: true)
            |> castEmbed("specifications", required: true)
            |> putChange("status", "draft")
            |> prepareChanges(setSlug);
    }
    
    private static function setSlug(changeset: Dynamic): Dynamic {
        if (changeset.valid && getChange(changeset, "name") != null) {
            var slug = slugify(getChange(changeset, "name"));
            return putChange(changeset, "slug", slug);
        }
        return changeset;
    }
}
```

### Multi-Step Changesets

```haxe
@:changeset
class RegistrationChangeset {
    // Step 1: Basic info
    public static function step1Changeset(user: User, params: Dynamic): Dynamic {
        return user
            |> cast(params, ["email", "password"])
            |> validateRequired(["email", "password"])
            |> validateFormat("email", ~r/@/)
            |> validateLength("password", min: 8)
            |> uniqueConstraint("email");
    }
    
    // Step 2: Profile info
    public static function step2Changeset(user: User, params: Dynamic): Dynamic {
        return user
            |> cast(params, ["name", "age", "bio"])
            |> validateRequired(["name"])
            |> validateNumber("age", greaterThanOrEqualTo: 18)
            |> validateLength("bio", max: 500);
    }
    
    // Step 3: Preferences
    public static function step3Changeset(user: User, params: Dynamic): Dynamic {
        return user
            |> cast(params, ["newsletter", "notifications", "theme"])
            |> castEmbed("preferences", withFunction: preferencesChangeset);
    }
    
    // Complete registration
    public static function completeRegistration(user: User, allParams: Dynamic): Dynamic {
        return user
            |> step1Changeset(allParams.step1)
            |> step2Changeset(allParams.step2)
            |> step3Changeset(allParams.step3)
            |> putChange("registered_at", DateTime.utcNow())
            |> putChange("status", "active");
    }
}
```

## Advanced Queries

### Subqueries

```haxe
class AdvancedQueries {
    // Subquery for top posts
    public static function topPostsByUser(): Dynamic {
        var topPosts = from(p in Post)
            |> where(p.published == true)
            |> groupBy(p.user_id)
            |> having(count(p.id) > 5)
            |> select({user_id: p.user_id, post_count: count(p.id)});
            
        return from(u in User)
            |> join(tp in subquery(topPosts), on: tp.user_id == u.id)
            |> where(u.active == true)
            |> select({user: u, post_count: tp.post_count});
    }
    
    // Lateral join subquery
    public static function latestPostsPerUser(limit: Int): Dynamic {
        var latestPosts = from(p in Post)
            |> where(p.user_id == parent_as(:user).id)
            |> orderBy([desc: p.inserted_at])
            |> limit(^limit);
            
        return from(u in User, as: :user)
            |> joinLateral(lp in subquery(latestPosts), on: true)
            |> select({user: u, latest_post: lp});
    }
}
```

### Common Table Expressions (CTEs)

```haxe
class CTEQueries {
    // Recursive CTE for hierarchical data
    public static function organizationHierarchy(rootId: Int): Dynamic {
        return withRecursive("org_tree",
            // Initial query (anchor)
            from(o in Organization)
                |> where(o.id == ^rootId)
                |> select([o.id, o.name, o.parent_id, 0]),
            
            // Recursive query
            from(o in Organization)
                |> join(ot in "org_tree", on: o.parent_id == ot.id)
                |> select([o.id, o.name, o.parent_id, ot.level + 1])
        )
        |> from(ot in "org_tree")
        |> orderBy(ot.level)
        |> select(ot);
    }
    
    // Multiple CTEs
    public static function salesReport(): Dynamic {
        return with("monthly_sales",
            from(o in Order)
                |> where(o.status == "completed")
                |> groupBy([fragment("date_trunc('month', ?)", o.completed_at)])
                |> select({
                    month: fragment("date_trunc('month', ?)", o.completed_at),
                    total: sum(o.total),
                    count: count(o.id)
                })
        )
        |> with("quarterly_sales",
            from(ms in "monthly_sales")
                |> groupBy([fragment("date_trunc('quarter', ?)", ms.month)])
                |> select({
                    quarter: fragment("date_trunc('quarter', ?)", ms.month),
                    total: sum(ms.total),
                    avg: avg(ms.total)
                })
        )
        |> from(qs in "quarterly_sales")
        |> select(qs);
    }
}
```

### Window Functions

```haxe
class WindowFunctionQueries {
    // Ranking functions
    public static function rankPostsByViews(): Dynamic {
        return from(p in Post)
            |> windowsAs(:w, partitionBy: p.category_id, orderBy: [desc: p.view_count])
            |> select({
                post: p,
                rank: rank() |> over(:w),
                dense_rank: denseRank() |> over(:w),
                row_number: rowNumber() |> over(:w),
                percent_rank: percentRank() |> over(:w)
            });
    }
    
    // Aggregate window functions
    public static function runningTotals(): Dynamic {
        return from(o in Order)
            |> windowsAs(:w, orderBy: o.created_at, frame: ["unbounded preceding", "current row"])
            |> select({
                order: o,
                running_total: sum(o.amount) |> over(:w),
                running_avg: avg(o.amount) |> over(:w),
                running_count: count() |> over(:w)
            });
    }
    
    // Lead/Lag functions
    public static function compareWithPrevious(): Dynamic {
        return from(s in Sale)
            |> windowsAs(:w, orderBy: s.date)
            |> select({
                sale: s,
                previous_amount: lag(s.amount, 1) |> over(:w),
                next_amount: lead(s.amount, 1) |> over(:w),
                change: s.amount - lag(s.amount, 1, 0) |> over(:w)
            });
    }
}
```

### Complex Joins and Aggregations

```haxe
class ComplexQueries {
    // Multiple joins with aggregations
    public static function userStatistics(): Dynamic {
        return from(u in User)
            |> leftJoin(p in Post, on: p.user_id == u.id)
            |> leftJoin(c in Comment, on: c.user_id == u.id)
            |> leftJoin(l in Like, on: l.user_id == u.id)
            |> groupBy(u.id)
            |> select({
                user: u,
                post_count: count(p.id, :distinct),
                comment_count: count(c.id, :distinct),
                like_count: count(l.id, :distinct),
                total_views: sum(p.view_count) || 0,
                avg_post_views: avg(p.view_count) || 0
            });
    }
    
    // Union queries
    public static function allActivities(): Dynamic {
        var posts = from(p in Post)
            |> select({
                type: "post",
                id: p.id,
                title: p.title,
                created_at: p.inserted_at,
                user_id: p.user_id
            });
            
        var comments = from(c in Comment)
            |> select({
                type: "comment",
                id: c.id,
                title: fragment("substring(?, 1, 50)", c.body),
                created_at: c.inserted_at,
                user_id: c.user_id
            });
            
        return union(posts, ^comments)
            |> orderBy([desc: :created_at])
            |> limit(100);
    }
    
    // Exists subquery
    public static function usersWithRecentActivity(): Dynamic {
        return from(u in User)
            |> where(
                exists(
                    from(p in Post)
                    |> where(p.user_id == parent_as(:user).id)
                    |> where(p.inserted_at > ago(7, "day"))
                )
            )
            |> select(u);
    }
}
```

## Migrations

### Basic Migration

```haxe
@:migration("create_users")
class CreateUsersTable {
    public static function up(): Void {
        createTable("users", function(t) {
            t.addColumn("id", "serial", {primary_key: true});
            t.addColumn("name", "string", {nullable: false});
            t.addColumn("email", "string", {nullable: false});
            t.addColumn("age", "integer");
            t.addColumn("active", "boolean", {default: true});
            t.addTimestamps();
            
            t.addIndex(["email"], {unique: true});
        });
    }
    
    public static function down(): Void {
        dropTable("users");
    }
}
```

### Complex Migration

```haxe
@:migration("add_user_features")
class AddUserFeatures {
    public static function up(): Void {
        // Alter existing table
        alterTable("users", function(t) {
            t.addColumn("bio", "text");
            t.addColumn("avatar_url", "string");
            t.addColumn("last_login_at", "datetime");
            t.modifyColumn("email", "citext");  // Case-insensitive text
            t.removeColumn("deprecated_field");
        });
        
        // Create new table with references
        createTable("user_settings", function(t) {
            t.addColumn("id", "uuid", {primary_key: true});
            t.addColumn("user_id", "references", {
                table: "users",
                on_delete: "cascade",
                on_update: "cascade"
            });
            t.addColumn("theme", "string", {default: "light"});
            t.addColumn("notifications", "map", {default: {}});
            t.addColumn("privacy", "jsonb");
            t.addTimestamps();
        });
        
        // Add composite index
        createIndex("users", ["last_login_at", "active"], {
            name: "users_activity_index",
            where: "active = true",
            concurrently: true
        });
        
        // Add check constraint
        createConstraint("users", :check, {
            name: "age_must_be_positive",
            check: "age > 0"
        });
        
        // Execute raw SQL
        execute("CREATE EXTENSION IF NOT EXISTS pg_trgm");
        execute("CREATE INDEX users_name_gin_idx ON users USING gin(name gin_trgm_ops)");
    }
    
    public static function down(): Void {
        dropConstraint("users", "age_must_be_positive");
        dropIndex("users", "users_activity_index");
        dropTable("user_settings");
        
        alterTable("users", function(t) {
            t.removeColumn("bio");
            t.removeColumn("avatar_url");
            t.removeColumn("last_login_at");
            t.modifyColumn("email", "string");
        });
    }
}
```

### Data Migration

```haxe
@:migration("populate_user_slugs")
class PopulateUserSlugs {
    public static function up(): Void {
        // Add column
        alterTable("users", function(t) {
            t.addColumn("slug", "string");
        });
        
        // Populate data
        flush();  // Ensure schema changes are applied
        
        Repo.all(User)
            |> Enum.each(function(user) {
                var slug = slugify(user.name);
                from(u in User)
                    |> where(u.id == ^user.id)
                    |> update(set: [slug: ^slug])
                    |> Repo.update_all();
            });
        
        // Add unique constraint
        createUniqueIndex("users", ["slug"]);
    }
    
    public static function down(): Void {
        dropIndex("users", "users_slug_index");
        alterTable("users", function(t) {
            t.removeColumn("slug");
        });
    }
}
```

## Repository Patterns

### Basic Repository

```haxe
@:repository
class Repo {
    // Basic CRUD operations
    public static function all<T>(schema: Class<T>): Array<T> {
        return Ecto.Repo.all(schema);
    }
    
    public static function get<T>(schema: Class<T>, id: Dynamic): Null<T> {
        return Ecto.Repo.get(schema, id);
    }
    
    public static function get!<T>(schema: Class<T>, id: Dynamic): T {
        return Ecto.Repo.get!(schema, id);
    }
    
    public static function getBy<T>(schema: Class<T>, clauses: Dynamic): Null<T> {
        return Ecto.Repo.get_by(schema, clauses);
    }
    
    public static function insert<T>(changeset: Dynamic): {ok: T} | {error: Dynamic} {
        return Ecto.Repo.insert(changeset);
    }
    
    public static function update<T>(changeset: Dynamic): {ok: T} | {error: Dynamic} {
        return Ecto.Repo.update(changeset);
    }
    
    public static function delete<T>(struct: T): {ok: T} | {error: Dynamic} {
        return Ecto.Repo.delete(struct);
    }
}
```

### Advanced Repository Operations

```haxe
@:repository
class AdvancedRepo extends Repo {
    // Preloading associations
    public static function preload<T>(struct: T, associations: Dynamic): T {
        return Ecto.Repo.preload(struct, associations);
    }
    
    // Aggregations
    public static function aggregate<T>(schema: Class<T>, aggregate: String, field: String): Dynamic {
        return Ecto.Repo.aggregate(schema, aggregate, field);
    }
    
    public static function count<T>(schema: Class<T>): Int {
        return aggregate(schema, :count, :id);
    }
    
    // Transactions
    public static function transaction(fun: Function): Dynamic {
        return Ecto.Repo.transaction(fun);
    }
    
    public static function rollback(value: Dynamic): Void {
        Ecto.Repo.rollback(value);
    }
    
    // Batch operations
    public static function insertAll<T>(schema: Class<T>, entries: Array<Dynamic>): {Int, Array<T>} {
        return Ecto.Repo.insert_all(schema, entries);
    }
    
    public static function updateAll(query: Dynamic, updates: Dynamic): {Int, Array<Dynamic>} {
        return Ecto.Repo.update_all(query, updates);
    }
    
    public static function deleteAll(query: Dynamic): {Int, Array<Dynamic>} {
        return Ecto.Repo.delete_all(query);
    }
    
    // Stream operations
    public static function stream(query: Dynamic): Stream<Dynamic> {
        return Ecto.Repo.stream(query);
    }
    
    // Custom queries
    public static function query(sql: String, params: Array<Dynamic> = []): {ok: Dynamic} | {error: Dynamic} {
        return Ecto.Adapters.SQL.query(Repo, sql, params);
    }
}
```

### Repository with Caching

```haxe
@:repository
class CachedRepo extends AdvancedRepo {
    private static var cache: Map<String, Dynamic> = new Map();
    private static var cacheTTL: Int = 300; // 5 minutes
    
    public static function getCached<T>(schema: Class<T>, id: Dynamic): Null<T> {
        var key = '${Type.getClassName(schema)}:${id}';
        
        if (cache.exists(key)) {
            var cached = cache.get(key);
            if (cached.expires > Date.now().getTime()) {
                return cached.data;
            }
            cache.remove(key);
        }
        
        var result = get(schema, id);
        if (result != null) {
            cache.set(key, {
                data: result,
                expires: Date.now().getTime() + cacheTTL * 1000
            });
        }
        
        return result;
    }
    
    public static function invalidateCache<T>(schema: Class<T>, id: Dynamic = null): Void {
        if (id != null) {
            var key = '${Type.getClassName(schema)}:${id}';
            cache.remove(key);
        } else {
            // Clear all entries for this schema
            var prefix = Type.getClassName(schema);
            for (key in cache.keys()) {
                if (key.startsWith(prefix)) {
                    cache.remove(key);
                }
            }
        }
    }
}
```

## Context Modules

### Basic Context

```haxe
@:context
class Accounts {
    // User management
    public static function listUsers(opts: Dynamic = {}): Array<User> {
        var query = from(u in User);
        
        if (opts.active != null) {
            query = where(query, u.active == ^opts.active);
        }
        
        if (opts.search != null) {
            var search = "%${opts.search}%";
            query = where(query, like(u.name, ^search) or like(u.email, ^search));
        }
        
        if (opts.order_by != null) {
            query = orderBy(query, ^opts.order_by);
        }
        
        return Repo.all(query);
    }
    
    public static function getUser!(id: Int): User {
        return Repo.get!(User, id);
    }
    
    public static function createUser(attrs: Dynamic): {ok: User} | {error: Dynamic} {
        return %User{}
            |> UserChangeset.changeset(attrs)
            |> Repo.insert();
    }
    
    public static function updateUser(user: User, attrs: Dynamic): {ok: User} | {error: Dynamic} {
        return user
            |> UserChangeset.changeset(attrs)
            |> Repo.update();
    }
    
    public static function deleteUser(user: User): {ok: User} | {error: Dynamic} {
        return Repo.delete(user);
    }
}
```

### Advanced Context with Business Logic

```haxe
@:context
class Blog {
    // Complex business operations
    public static function publishPost(post: Post): {ok: Post} | {error: String} {
        if (!post.draft) {
            return {error: "Post is already published"};
        }
        
        return Repo.transaction(function() {
            // Update post
            var result = post
                |> Ecto.Changeset.change(%{
                    published: true,
                    published_at: DateTime.utcNow()
                })
                |> Repo.update();
                
            switch(result) {
                case {ok: updatedPost}:
                    // Send notifications
                    NotificationService.notifyFollowers(updatedPost.author_id, {
                        type: "new_post",
                        post_id: updatedPost.id
                    });
                    
                    // Update statistics
                    updateAuthorStats(updatedPost.author_id);
                    
                    // Index for search
                    SearchService.indexPost(updatedPost);
                    
                    return {ok: updatedPost};
                    
                case {error: changeset}:
                    Repo.rollback(changeset);
            }
        });
    }
    
    public static function getPostWithComments(id: Int): Null<Post> {
        return Repo.get(Post, id)
            |> Repo.preload([
                :author,
                comments: from(c in Comment, order_by: [desc: c.inserted_at])
            ]);
    }
    
    public static function searchPosts(term: String, opts: Dynamic = {}): Array<Post> {
        var query = from(p in Post)
            |> where(p.published == true)
            |> where(
                fragment("? @@ plainto_tsquery('english', ?)", p.search_vector, ^term)
            );
            
        if (opts.category_id != null) {
            query = where(query, p.category_id == ^opts.category_id);
        }
        
        if (opts.author_id != null) {
            query = where(query, p.author_id == ^opts.author_id);
        }
        
        return query
            |> orderBy(fragment("ts_rank(?, plainto_tsquery('english', ?))", p.search_vector, ^term))
            |> limit(^(opts.limit || 20))
            |> Repo.all()
            |> Repo.preload([:author, :category]);
    }
    
    private static function updateAuthorStats(authorId: Int): Void {
        from(s in AuthorStats)
            |> where(s.author_id == ^authorId)
            |> update(inc: [post_count: 1, total_posts_published: 1])
            |> Repo.update_all();
    }
}
```

## LiveView Integration

### Basic LiveView with Ecto

```haxe
@:liveview
class PostLive {
    var posts: Array<Post> = [];
    var selectedPost: Null<Post> = null;
    var changeset: Dynamic = null;
    var searchTerm: String = "";
    
    function mount(_params: Dynamic, _session: Dynamic, socket: Dynamic): {ok: Dynamic} {
        if (connected?(socket)) {
            Phoenix.PubSub.subscribe(MyApp.PubSub, "posts");
        }
        
        posts = Blog.listPosts();
        
        return {
            ok: assign(socket, {
                posts: posts,
                selectedPost: null,
                changeset: Blog.changePost(%Post{}),
                searchTerm: ""
            })
        };
    }
    
    function handleEvent(event: String, params: Dynamic, socket: Dynamic): {noreply: Dynamic} {
        return switch(event) {
            case "search":
                var posts = Blog.searchPosts(params.search);
                {noreply: assign(socket, {posts: posts, searchTerm: params.search})};
                
            case "edit":
                var post = Blog.getPost!(params.id);
                var changeset = Blog.changePost(post);
                {noreply: assign(socket, {selectedPost: post, changeset: changeset})};
                
            case "save":
                savePost(socket, params);
                
            case "delete":
                deletePost(socket, params.id);
                
            default:
                {noreply: socket};
        };
    }
    
    function handleInfo(msg: Dynamic, socket: Dynamic): {noreply: Dynamic} {
        return switch(msg) {
            case {:post_created, post}:
                var posts = [post].concat(socket.assigns.posts);
                {noreply: assign(socket, posts: posts)};
                
            case {:post_updated, post}:
                var posts = updatePostInList(socket.assigns.posts, post);
                {noreply: assign(socket, posts: posts)};
                
            case {:post_deleted, id}:
                var posts = socket.assigns.posts.filter(p -> p.id != id);
                {noreply: assign(socket, posts: posts)};
                
            default:
                {noreply: socket};
        };
    }
    
    private function savePost(socket: Dynamic, params: Dynamic): {noreply: Dynamic} {
        var result = if (socket.assigns.selectedPost != null) {
            Blog.updatePost(socket.assigns.selectedPost, params.post);
        } else {
            Blog.createPost(params.post);
        }
        
        return switch(result) {
            case {ok: post}:
                Phoenix.PubSub.broadcast(MyApp.PubSub, "posts", 
                    socket.assigns.selectedPost != null ? 
                        {:post_updated, post} : 
                        {:post_created, post}
                );
                
                {noreply: 
                    socket
                    |> putFlash(:info, "Post saved successfully")
                    |> assign(selectedPost: null, changeset: Blog.changePost(%Post{}))
                };
                
            case {error: changeset}:
                {noreply: assign(socket, changeset: changeset)};
        };
    }
}
```

### Real-time Collaborative Editing

```haxe
@:liveview
class EditorLive {
    var document: Document;
    var users: Map<String, User> = new Map();
    var cursors: Map<String, Cursor> = new Map();
    var presence: Dynamic;
    
    function mount(params: Dynamic, session: Dynamic, socket: Dynamic): {ok: Dynamic} {
        var documentId = params.id;
        document = Documents.getDocument!(documentId);
        
        if (connected?(socket)) {
            // Subscribe to document updates
            Phoenix.PubSub.subscribe(MyApp.PubSub, "document:${documentId}");
            
            // Track presence
            presence = Presence.track(
                self(),
                "document:${documentId}:users",
                session.user_id,
                %{
                    user: session.current_user,
                    cursor: %{line: 0, column: 0},
                    selection: null
                }
            );
            
            // Get current users
            updatePresence(socket);
        }
        
        return {
            ok: assign(socket, {
                document: document,
                users: users,
                cursors: cursors,
                canEdit: Permissions.canEdit?(session.current_user, document)
            })
        };
    }
    
    function handleEvent("update_content", params: Dynamic, socket: Dynamic): {noreply: Dynamic} {
        if (!socket.assigns.canEdit) {
            return {noreply: socket};
        }
        
        // Apply operational transform for conflict resolution
        var operation = OperationalTransform.create(params.delta);
        var transformedOp = OperationalTransform.transform(operation, document.version);
        
        return Documents.applyOperation(document, transformedOp) switch {
            case {ok: updatedDoc}:
                // Broadcast to other users
                Phoenix.PubSub.broadcast_from(
                    self(),
                    MyApp.PubSub,
                    "document:${document.id}",
                    {:content_updated, transformedOp}
                );
                
                {noreply: assign(socket, document: updatedDoc)};
                
            case {error: reason}:
                {noreply: 
                    socket
                    |> putFlash(:error, "Failed to update: ${reason}")
                };
        };
    }
    
    function handleEvent("cursor_move", params: Dynamic, socket: Dynamic): {noreply: Dynamic} {
        // Update presence with cursor position
        Presence.update(
            self(),
            "document:${socket.assigns.document.id}:users",
            socket.assigns.current_user.id,
            fn(meta) -> Map.put(meta, :cursor, params.cursor)
        );
        
        return {noreply: socket};
    }
    
    function handleInfo({:content_updated, operation}: Dynamic, socket: Dynamic): {noreply: Dynamic} {
        // Apply remote operation
        var updatedDoc = OperationalTransform.apply(socket.assigns.document, operation);
        return {noreply: assign(socket, document: updatedDoc)};
    }
    
    function handleInfo({:presence_diff, diff}: Dynamic, socket: Dynamic): {noreply: Dynamic} {
        updatePresence(socket);
        return {noreply: socket};
    }
    
    private function updatePresence(socket: Dynamic): Void {
        var presences = Presence.list("document:${socket.assigns.document.id}:users");
        
        var users = new Map();
        var cursors = new Map();
        
        for (userId => meta in presences) {
            users.set(userId, meta.user);
            cursors.set(userId, meta.cursor);
        }
        
        assign(socket, {users: users, cursors: cursors});
    }
}
```

## Performance Optimization

### Query Optimization

```haxe
class QueryOptimization {
    // Preload associations efficiently
    public static function efficientPreload(): Array<Post> {
        // Bad: N+1 queries
        var posts = Repo.all(Post);
        for (post in posts) {
            post.author = Repo.get(User, post.author_id);  // N queries!
        }
        
        // Good: 2 queries total
        return Repo.all(Post)
            |> Repo.preload(:author);
        
        // Better: Custom preload query
        return Repo.all(Post)
            |> Repo.preload([
                author: from(u in User, where: u.active == true)
            ]);
    }
    
    // Use select to load only needed fields
    public static function selectiveLoading(): Array<Dynamic> {
        return from(u in User)
            |> join(p in assoc(u, :posts))
            |> where(p.published == true)
            |> select({u.id, u.name, count(p.id)})
            |> groupBy(u.id)
            |> Repo.all();
    }
    
    // Batch loading
    public static function batchLoad(ids: Array<Int>): Map<Int, User> {
        var users = from(u in User)
            |> where(u.id in ^ids)
            |> Repo.all();
            
        var map = new Map();
        for (user in users) {
            map.set(user.id, user);
        }
        return map;
    }
}
```

### Database Indexing

```haxe
@:migration("add_performance_indexes")
class AddPerformanceIndexes {
    public static function up(): Void {
        // Covering index for common query
        createIndex("posts", ["user_id", "published", "inserted_at"], {
            name: "posts_user_published_date_idx",
            where: "published = true",
            include: ["title", "view_count"]  // PostgreSQL covering index
        });
        
        // Partial index for active records
        createIndex("users", ["email"], {
            name: "users_active_email_idx",
            where: "active = true and deleted_at is null"
        });
        
        // GIN index for full-text search
        execute("""
            CREATE INDEX posts_search_idx ON posts 
            USING gin(to_tsvector('english', title || ' ' || content))
        """);
        
        // BRIN index for time-series data
        createIndex("events", ["created_at"], {
            using: "brin",
            name: "events_created_at_brin_idx"
        });
    }
}
```

### Caching Strategies

```haxe
class CachingStrategies {
    // Query result caching
    public static function getCachedPopularPosts(): Array<Post> {
        return Cache.fetch("popular_posts", fn() -> {
            from(p in Post)
                |> where(p.published == true)
                |> orderBy([desc: p.view_count])
                |> limit(10)
                |> Repo.all()
                |> Repo.preload([:author, :category])
        }, ttl: 3600);  // Cache for 1 hour
    }
    
    // Fragment caching in templates
    public static function renderCachedUserCard(user: User): String {
        return Cache.fetch("user_card:${user.id}:${user.updated_at}", fn() -> {
            Phoenix.View.render(UserView, "card.html", user: user)
        }, ttl: 86400);  // Cache for 24 hours
    }
    
    // Cache invalidation
    public static function updatePostWithCacheInvalidation(post: Post, attrs: Dynamic): Dynamic {
        return Repo.transaction(fn() -> {
            var result = Blog.updatePost(post, attrs);
            
            switch(result) {
                case {ok: updatedPost}:
                    // Invalidate related caches
                    Cache.delete("popular_posts");
                    Cache.delete("user_posts:${updatedPost.author_id}");
                    Cache.delete("category_posts:${updatedPost.category_id}");
                    
                    {ok: updatedPost};
                    
                case error:
                    error;
            }
        });
    }
}
```

## Best Practices

### 1. Schema Design
- Use database constraints to enforce data integrity
- Add indexes for frequently queried fields
- Use appropriate field types (citext for case-insensitive email)
- Implement soft deletes with deleted_at timestamps
- Version your schemas for API compatibility

### 2. Changeset Validation
- Validate at the edge (in changesets, not in business logic)
- Use database constraints as the last line of defense
- Create specific changesets for different operations
- Document validation rules clearly
- Test edge cases thoroughly

### 3. Query Optimization
- Always preload associations to avoid N+1 queries
- Use select to load only needed fields
- Paginate large result sets
- Use database views for complex queries
- Monitor slow queries with explain analyze

### 4. Transaction Management
- Keep transactions as short as possible
- Use Ecto.Multi for complex multi-step operations
- Handle rollback scenarios gracefully
- Avoid external API calls inside transactions
- Use optimistic locking for concurrent updates

### 5. Testing
- Test changesets with invalid data
- Verify database constraints work
- Test concurrent operations
- Use sandbox mode for test isolation
- Benchmark critical queries

### 6. Security
- Always use parameterized queries (never string concatenation)
- Validate and sanitize all user input
- Use allow-lists for changeset casting
- Implement row-level security where needed
- Audit sensitive operations

## Migration Commands

```bash
# Generate a new migration
mix haxe.gen.migration CreateProducts

# Run pending migrations
mix ecto.migrate

# Rollback last migration
mix ecto.rollback

# Reset database
mix ecto.reset

# Create database
mix ecto.create

# Drop database
mix ecto.drop
```

## Troubleshooting

### Common Issues

1. **Compilation Errors**
   - Ensure @:schema annotation is properly formatted
   - Check that all associations have corresponding fields (e.g., user_id for belongs_to)
   - Verify field types match Ecto expectations

2. **Query Errors**
   - Use `from` macro properly with correct bindings
   - Ensure preload syntax matches association names
   - Check that dynamic queries are properly escaped with ^

3. **Migration Failures**
   - Verify foreign key references exist
   - Check for naming conflicts
   - Ensure proper rollback implementations
   - Use `flush()` between DDL and DML operations

4. **Performance Issues**
   - Profile queries with `explain analyze`
   - Add missing indexes
   - Optimize preload strategies
   - Consider query result caching

## Conclusion

Reflaxe.Elixir provides comprehensive Ecto support that leverages Haxe's type safety while maintaining full compatibility with Elixir's database layer. This guide covered advanced features from complex queries to performance optimization, providing you with the tools to build robust, scalable applications.

For more information, see:
- [Ecto Documentation](https://hexdocs.pm/ecto)
- [Phoenix Framework Guide](https://hexdocs.pm/phoenix)
- [Reflaxe.Elixir README](../../README.md)