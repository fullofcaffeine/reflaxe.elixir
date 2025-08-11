# Reflaxe.Elixir Cookbook

A collection of practical recipes showing how to implement common Elixir/Phoenix patterns with Haxe's type safety. Each recipe demonstrates idiomatic Elixir code with compile-time guarantees.

## Table of Contents

### Core Elixir Patterns
- [Pipeline Operations with Type Safety](#pipeline-operations-with-type-safety)
- [Pattern Matching with Exhaustive Checks](#pattern-matching-with-exhaustive-checks)
- [With Expressions and Error Handling](#with-expressions-and-error-handling)
- [Process Communication with Types](#process-communication-with-types)

### Phoenix Contexts & Architecture
- [Bounded Contexts with Type Contracts](#bounded-contexts-with-type-contracts)
- [Action Fallback Pattern](#action-fallback-pattern)
- [Plugs with Type-Safe Middleware](#plugs-with-type-safe-middleware)
- [Phoenix Components with Props](#phoenix-components-with-props)

### OTP Patterns
- [Supervisors and Supervision Trees](#supervisors-and-supervision-trees)
- [GenServer with Typed State](#genserver-with-typed-state)
- [Task.async/await with Type Safety](#task-async-await-with-type-safety)
- [Agent State Management](#agent-state-management)

### Web Development
- [Building a REST API](#building-a-rest-api)
- [GraphQL Server with Absinthe](#graphql-server-with-absinthe)
- [WebSocket Chat Application](#websocket-chat-application)
- [File Upload Handler](#file-upload-handler)
- [JWT Authentication](#jwt-authentication)

### Database & Data
- [Multi-tenant Database](#multi-tenant-database)
- [Soft Delete Pattern](#soft-delete-pattern)
- [Database Migrations](#database-migrations)
- [Full-text Search](#full-text-search)
- [Caching with Redis](#caching-with-redis)

### Real-time Features
- [Live Dashboard](#live-dashboard)
- [Real-time Notifications](#real-time-notifications)
- [Collaborative Editor](#collaborative-editor)
- [Live Form Validation](#live-form-validation)
- [Phoenix Presence with Types](#phoenix-presence-with-types)

### Background Jobs
- [Email Queue](#email-queue)
- [Image Processing Pipeline](#image-processing-pipeline)
- [Scheduled Tasks](#scheduled-tasks)
- [Rate Limiting](#rate-limiting)

### Testing & Quality
- [Property-based Testing](#property-based-testing)
- [Test Factories](#test-factories)
- [API Client Testing](#api-client-testing)

---

## Core Elixir Patterns

### Pipeline Operations with Type Safety

Type-safe pipeline operations that compile to idiomatic Elixir:

```haxe
// src_haxe/DataPipeline.hx
package pipelines;

@:module
class DataPipeline {
    /**
     * Type-safe pipeline that ensures each step has correct input/output types
     */
    public static function processUserData(rawData: String): Result<User, String> {
        // Haxe ensures type safety at each step
        return rawData
            |> parseJson()
            |> validateSchema()
            |> enrichWithDefaults()
            |> createUser();
    }
    
    static function parseJson(data: String): Result<Dynamic, String> {
        try {
            return Ok(Jason.decode(data));
        } catch (e: Dynamic) {
            return Error("Invalid JSON: " + e);
        }
    }
    
    static function validateSchema(data: Result<Dynamic, String>): Result<UserData, String> {
        return data.flatMap(d -> {
            if (d.name == null || d.email == null) {
                return Error("Missing required fields");
            }
            return Ok(cast d);
        });
    }
    
    static function enrichWithDefaults(data: Result<UserData, String>): Result<UserData, String> {
        return data.map(d -> {
            d.role = d.role ?? "user";
            d.active = d.active ?? true;
            return d;
        });
    }
    
    static function createUser(data: Result<UserData, String>): Result<User, String> {
        return data.flatMap(d -> {
            var changeset = User.changeset(%User{}, d);
            return Repo.insert(changeset);
        });
    }
}
```

### Pattern Matching with Exhaustive Checks

Haxe ensures all cases are handled at compile time:

```haxe
// src_haxe/EventHandler.hx
@:module
class EventHandler {
    /**
     * Compile-time exhaustive pattern matching
     */
    public static function handleEvent(event: Event): Response {
        // Haxe compiler ensures all Event variants are handled
        return switch (event) {
            case UserJoined(user):
                broadcastUserJoined(user);
                Response.ok("User joined: " + user.name);
                
            case MessageSent(user, message):
                saveMessage(user, message);
                broadcastMessage(user, message);
                Response.ok("Message sent");
                
            case UserLeft(userId):
                markUserOffline(userId);
                Response.ok("User left");
                
            case Error(code, message):
                Logger.error("Event error: " + code + " - " + message);
                Response.error(code, message);
                
            // Compiler error if any Event case is missing!
        };
    }
}

enum Event {
    UserJoined(user: User);
    MessageSent(user: User, message: String);
    UserLeft(userId: String);
    Error(code: Int, message: String);
}

enum Response {
    ok(message: String);
    error(code: Int, message: String);
}
```

### With Expressions and Error Handling

Type-safe error handling that compiles to Elixir's `with`:

```haxe
// src_haxe/OrderService.hx
@:module
class OrderService {
    /**
     * Type-safe with expression for complex operations
     */
    public static function placeOrder(userId: String, items: Array<Item>): Result<Order, OrderError> {
        // Each step is type-checked
        return with(
            user <- getUserById(userId),
            _ <- validateUserCanOrder(user),
            inventory <- checkInventory(items),
            _ <- reserveItems(inventory, items),
            payment <- processPayment(user, calculateTotal(items)),
            order <- createOrder(user, items, payment)
        ) {
            // Success path with all types verified
            notifyOrderSuccess(order);
            Ok(order);
        } else {
            // Type-safe error handling
            case Error(UserNotFound): Error(InvalidUser);
            case Error(InsufficientFunds): Error(PaymentFailed);
            case Error(OutOfStock(item)): Error(ItemUnavailable(item));
            case Error(e): Error(UnknownError(e));
        }
    }
}

enum OrderError {
    InvalidUser;
    PaymentFailed;
    ItemUnavailable(item: String);
    UnknownError(message: String);
}
```

### Process Communication with Types

Type-safe message passing between processes:

```haxe
// src_haxe/TypedProcess.hx
@:module
class ChatRoom {
    /**
     * Type-safe process communication
     */
    public static function start(): Pid<ChatMessage> {
        return spawn(function() {
            loop(initialState());
        });
    }
    
    static function loop(state: RoomState): Void {
        // Receive with typed messages
        receive {
            case Join(user, replyTo):
                var newState = addUser(state, user);
                send(replyTo, JoinResponse(true, state.users.length));
                loop(newState);
                
            case Message(from, text, replyTo):
                broadcastMessage(state.users, from, text);
                send(replyTo, MessageSent);
                loop(state);
                
            case Leave(userId):
                var newState = removeUser(state, userId);
                loop(newState);
        }
    }
}

// Typed messages
enum ChatMessage {
    Join(user: User, replyTo: Pid<JoinResponse>);
    Message(from: String, text: String, replyTo: Pid<MessageStatus>);
    Leave(userId: String);
}

enum JoinResponse {
    JoinResponse(success: Bool, userCount: Int);
}

enum MessageStatus {
    MessageSent;
    MessageFailed(reason: String);
}
```

## Phoenix Contexts & Architecture

### Bounded Contexts with Type Contracts

Phoenix contexts with clear type boundaries:

```haxe
// src_haxe/contexts/Accounts.hx
package contexts;

/**
 * Accounts context with type-safe public API
 */
@:context
class Accounts {
    // Public API with clear type contracts
    
    public static function getUser(id: String): Option<User> {
        return Repo.get(User, id);
    }
    
    public static function getUserBy(attrs: UserQuery): Option<User> {
        return Repo.getBy(User, attrs);
    }
    
    public static function registerUser(attrs: RegistrationParams): Result<User, Changeset> {
        var changeset = User.registrationChangeset(%User{}, attrs);
        return Repo.insert(changeset);
    }
    
    public static function authenticateUser(email: String, password: String): Result<User, AuthError> {
        return getUserBy({email: email})
            .toResult(InvalidCredentials)
            .flatMap(user -> {
                if (Bcrypt.verify(password, user.hashedPassword)) {
                    return Ok(user);
                } else {
                    return Error(InvalidCredentials);
                }
            });
    }
    
    // Internal functions (not exposed to other contexts)
    private static function hashPassword(password: String): String {
        return Bcrypt.hashPwdSalt(password);
    }
}

// Clear type definitions for the context's API
typedef RegistrationParams = {
    email: String,
    password: String,
    passwordConfirmation: String,
    ?name: String
}

typedef UserQuery = {
    ?email: String,
    ?id: String,
    ?active: Bool
}

enum AuthError {
    InvalidCredentials;
    AccountLocked;
    EmailNotVerified;
}
```

### Action Fallback Pattern

Type-safe action fallback for controllers:

```haxe
// src_haxe/controllers/FallbackController.hx
@:controller
class UserController {
    use FallbackController;  // Action fallback
    
    public function show(conn: Conn, params: {id: String}): ConnOrError {
        // Return either Conn or Error - fallback handles errors
        return Accounts.getUser(params.id)
            .map(user -> render(conn, "show.json", user))
            .toResult(NotFound);
    }
    
    public function create(conn: Conn, params: {user: UserParams}): ConnOrError {
        // Fallback automatically handles the Error case
        return Accounts.createUser(params.user)
            .map(user -> conn
                .putStatus(201)
                .render("show.json", user));
    }
}

@:fallback_controller
class FallbackController {
    public function call(conn: Conn, error: ControllerError): Conn {
        return switch (error) {
            case NotFound:
                conn.putStatus(404).json({error: "Not found"});
            case Unauthorized:
                conn.putStatus(401).json({error: "Unauthorized"});
            case ValidationError(changeset):
                conn.putStatus(422).json({errors: translateErrors(changeset)});
            case ServerError(message):
                conn.putStatus(500).json({error: "Internal server error"});
        };
    }
}

typedef ConnOrError = Result<Conn, ControllerError>;

enum ControllerError {
    NotFound;
    Unauthorized;
    ValidationError(changeset: Changeset);
    ServerError(message: String);
}
```

## OTP Patterns

### Supervisors and Supervision Trees

Type-safe supervisor specifications:

```haxe
// src_haxe/ApplicationSupervisor.hx
@:supervisor
class ApplicationSupervisor {
    public function init(args: Dynamic): SupervisorSpec {
        var children: Array<ChildSpec> = [
            // Each child has typed configuration
            {
                id: "cache",
                start: {CacheServer, startLink, [%{size: 1000}]},
                restart: permanent,
                shutdown: 5000,
                type: worker
            },
            {
                id: "session_supervisor",
                start: {SessionSupervisor, startLink, []},
                restart: permanent,
                shutdown: infinity,
                type: supervisor
            },
            {
                id: "task_supervisor",
                start: {Task.Supervisor, startLink, [[name: TaskSupervisor]]},
                restart: permanent,
                type: supervisor
            }
        ];
        
        return {
            strategy: oneForOne,
            maxRestarts: 3,
            maxSeconds: 5,
            children: children
        };
    }
}

typedef SupervisorSpec = {
    strategy: SupervisorStrategy,
    maxRestarts: Int,
    maxSeconds: Int,
    children: Array<ChildSpec>
}

typedef ChildSpec = {
    id: String,
    start: {module: Dynamic, function: String, args: Array<Dynamic>},
    restart: RestartStrategy,
    shutdown: ShutdownStrategy,
    type: WorkerType
}

enum SupervisorStrategy {
    oneForOne;
    oneForAll;
    restForOne;
}

enum RestartStrategy {
    permanent;
    temporary;
    transient;
}
```

### GenServer with Typed State

Type-safe GenServer with compile-time state validation:

```haxe
// src_haxe/CacheServer.hx
@:genserver
class CacheServer {
    // Typed state
    typedef State = {
        cache: Map<String, CacheEntry>,
        maxSize: Int,
        currentSize: Int,
        hits: Int,
        misses: Int
    }
    
    typedef CacheEntry = {
        value: Dynamic,
        expiry: Date,
        size: Int
    }
    
    public function init(args: {maxSize: Int}): InitResult<State> {
        var state: State = {
            cache: new Map(),
            maxSize: args.maxSize,
            currentSize: 0,
            hits: 0,
            misses: 0
        };
        
        // Schedule cleanup
        Process.sendAfter(self(), :cleanup, 60000);
        
        return {:ok, state};
    }
    
    public function handleCall(request: CacheRequest, from: From, state: State): CallResult<State> {
        return switch (request) {
            case Get(key):
                var entry = state.cache.get(key);
                if (entry != null && entry.expiry > Date.now()) {
                    state.hits++;
                    {:reply, {:ok, entry.value}, state};
                } else {
                    state.misses++;
                    {:reply, {:error, :not_found}, state};
                }
                
            case Put(key, value, ttl):
                var entry: CacheEntry = {
                    value: value,
                    expiry: Date.now().addSeconds(ttl),
                    size: calculateSize(value)
                };
                
                var newState = ensureSpace(state, entry.size);
                newState.cache.set(key, entry);
                newState.currentSize += entry.size;
                
                {:reply, :ok, newState};
                
            case Stats:
                var stats = {
                    size: state.currentSize,
                    maxSize: state.maxSize,
                    entries: state.cache.size(),
                    hitRate: state.hits / (state.hits + state.misses)
                };
                {:reply, stats, state};
        };
    }
    
    public function handleInfo(msg: InfoMessage, state: State): InfoResult<State> {
        return switch (msg) {
            case :cleanup:
                var newState = removeExpiredEntries(state);
                Process.sendAfter(self(), :cleanup, 60000);
                {:noreply, newState};
                
            case _:
                {:noreply, state};
        };
    }
}

// Typed messages
enum CacheRequest {
    Get(key: String);
    Put(key: String, value: Dynamic, ttl: Int);
    Stats;
}
```

### Task.async/await with Type Safety

Type-safe concurrent operations:

```haxe
// src_haxe/DataAggregator.hx
@:module
class DataAggregator {
    /**
     * Type-safe parallel data fetching
     */
    public static function fetchDashboardData(userId: String): DashboardData {
        // Start parallel tasks with type safety
        var userTask: Task<User> = Task.async(() -> fetchUser(userId));
        var statsTask: Task<UserStats> = Task.async(() -> fetchUserStats(userId));
        var notificationsTask: Task<Array<Notification>> = Task.async(() -> 
            fetchNotifications(userId)
        );
        
        // Await with timeout and type preservation
        var user = Task.await(userTask, 5000);
        var stats = Task.await(statsTask, 5000);
        var notifications = Task.await(notificationsTask, 5000);
        
        return {
            user: user,
            stats: stats,
            notifications: notifications,
            generatedAt: Date.now()
        };
    }
    
    /**
     * Type-safe error handling with Task
     */
    public static function fetchWithFallback<T>(
        primary: () -> T,
        fallback: () -> T,
        timeout: Int = 5000
    ): T {
        var task = Task.async(primary);
        
        return try {
            Task.await(task, timeout);
        } catch (e: TaskError) {
            Logger.warn("Primary fetch failed, using fallback: " + e);
            fallback();
        }
    }
}

typedef DashboardData = {
    user: User,
    stats: UserStats,
    notifications: Array<Notification>,
    generatedAt: Date
}

enum TaskError {
    Timeout;
    Exit(reason: Dynamic);
    Throw(error: Dynamic);
}
```

## Web Development

### Building a REST API

Create a complete REST API with CRUD operations:

```haxe
// src_haxe/controllers/api/ArticleController.hx
package controllers.api;

import phoenix.Controller;
import phoenix.Conn;
import schemas.Article;
import contexts.Blog;

@:controller
class ArticleController {
    /**
     * GET /api/articles
     */
    public static function index(conn: Conn, params: {?page: Int, ?limit: Int}): Conn {
        var page = params.page ?? 1;
        var limit = params.limit ?? 20;
        
        var articles = Blog.listArticles(page, limit);
        
        return conn
            .putStatus(200)
            .json(%{
                data: articles,
                meta: %{
                    page: page,
                    limit: limit,
                    total: Blog.countArticles()
                }
            });
    }
    
    /**
     * GET /api/articles/:id
     */
    public static function show(conn: Conn, params: {id: String}): Conn {
        return switch (Blog.getArticle(params.id)) {
            case Some(article):
                conn.json(%{data: article});
            case None:
                conn
                    .putStatus(404)
                    .json(%{error: "Article not found"});
        };
    }
    
    /**
     * POST /api/articles
     */
    public static function create(conn: Conn, params: {article: ArticleParams}): Conn {
        var result = Blog.createArticle(params.article);
        
        return switch (result) {
            case {:ok, article}:
                conn
                    .putStatus(201)
                    .putHeader("location", '/api/articles/${article.id}')
                    .json(%{data: article});
                    
            case {:error, changeset}:
                conn
                    .putStatus(422)
                    .json(%{errors: translateErrors(changeset)});
        };
    }
    
    /**
     * PATCH /api/articles/:id
     */
    public static function update(conn: Conn, params: {id: String, article: ArticleParams}): Conn {
        return switch (Blog.getArticle(params.id)) {
            case Some(article):
                handleUpdate(conn, article, params.article);
            case None:
                conn.putStatus(404).json(%{error: "Not found"});
        };
    }
    
    /**
     * DELETE /api/articles/:id
     */
    public static function delete(conn: Conn, params: {id: String}): Conn {
        return switch (Blog.deleteArticle(params.id)) {
            case :ok:
                conn.sendResp(204, "");
            case :error:
                conn.putStatus(404).json(%{error: "Not found"});
        };
    }
    
    // Add versioning support
    public static function version(conn: Conn): String {
        return conn.getReqHeader("api-version") ?? "v1";
    }
}
```

### GraphQL Server with Absinthe

Implement a GraphQL API:

```haxe
// src_haxe/graphql/Schema.hx
package graphql;

@:graphql
class Schema {
    // Define types
    @:type
    public static var userType = {
        name: "User",
        fields: {
            id: {:id, nonNull: true},
            name: {:string, nonNull: true},
            email: :string,
            posts: {list: "Post"},
            createdAt: :datetime
        }
    };
    
    @:type
    public static var postType = {
        name: "Post",
        fields: {
            id: {:id, nonNull: true},
            title: {:string, nonNull: true},
            content: :string,
            author: "User",
            publishedAt: :datetime
        }
    };
    
    // Queries
    @:query
    public static function user(args: {id: String}, resolution: Resolution): Dynamic {
        return Users.find(args.id);
    }
    
    @:query
    public static function posts(args: {?limit: Int, ?offset: Int}, res: Resolution): Array<Post> {
        return Posts.list(args.limit ?? 10, args.offset ?? 0);
    }
    
    // Mutations
    @:mutation
    public static function createPost(args: {input: PostInput}, res: Resolution): Dynamic {
        var user = res.context.currentUser;
        if (user == null) {
            return {:error, "Unauthorized"};
        }
        
        return Posts.create({
            ...args.input,
            authorId: user.id
        });
    }
    
    // Subscriptions
    @:subscription
    public static function postCreated(args: {}, res: Resolution): Dynamic {
        return untyped __elixir__('
            Absinthe.Subscription.subscribe(res.context.pubsub, "posts:created")
        ');
    }
}

// GraphQL resolver
@:resolver
class PostResolver {
    public static function author(post: Post, args: {}, res: Resolution): User {
        return BatchLoader.load(UserLoader, post.authorId);
    }
    
    public static function comments(post: Post, args: {?limit: Int}, res: Resolution): Array<Comment> {
        return Comments.forPost(post.id, args.limit ?? 10);
    }
}
```

### WebSocket Chat Application

Real-time chat with presence tracking:

```haxe
// src_haxe/channels/ChatChannel.hx
package channels;

import phoenix.Channel;
import phoenix.Socket;
import phoenix.Presence;

@:channel("room:*")
class ChatChannel {
    public function join(topic: String, params: {username: String}, socket: Socket): JoinResult {
        var roomId = topic.split(":")[1];
        
        // Track presence
        Presence.track(socket, socket.id, %{
            username: params.username,
            joinedAt: Date.now()
        });
        
        // Send last messages
        var messages = ChatHistory.getRecent(roomId, 50);
        push(socket, "history", %{messages: messages});
        
        // Notify others
        broadcast(socket, "user_joined", %{
            username: params.username
        });
        
        return {:ok, socket};
    }
    
    public function handleIn("message", payload: {text: String}, socket: Socket): Dynamic {
        var message = {
            id: UUID.generate(),
            text: payload.text,
            username: socket.assigns.username,
            timestamp: Date.now()
        };
        
        // Save to history
        ChatHistory.save(socket.topic, message);
        
        // Broadcast to all
        broadcast(socket, "message", message);
        
        return {:reply, :ok, socket};
    }
    
    public function handleIn("typing", payload: {}, socket: Socket): Dynamic {
        broadcastFrom(socket, "typing", %{
            username: socket.assigns.username
        });
        
        return {:noreply, socket};
    }
    
    public function terminate(reason: Dynamic, socket: Socket): Void {
        broadcast(socket, "user_left", %{
            username: socket.assigns.username
        });
    }
}
```

### File Upload Handler

Handle file uploads with validation and processing:

```haxe
// src_haxe/controllers/UploadController.hx
package controllers;

@:controller
class UploadController {
    static var ALLOWED_TYPES = ["image/jpeg", "image/png", "image/gif"];
    static var MAX_SIZE = 10 * 1024 * 1024; // 10MB
    
    public static function create(conn: Conn, params: {upload: Upload}): Conn {
        var upload = params.upload;
        
        // Validate file
        var validation = validateUpload(upload);
        if (!validation.valid) {
            return conn
                .putStatus(422)
                .json(%{error: validation.error});
        }
        
        // Generate unique filename
        var ext = Path.extension(upload.filename);
        var newName = '${UUID.generate()}$ext';
        var destination = '/uploads/${Date.now().getFullYear()}/${Date.now().getMonth()}/$newName';
        
        // Save file
        File.copy(upload.path, destination);
        
        // Create thumbnail for images
        if (isImage(upload.contentType)) {
            ImageProcessor.createThumbnail(destination);
        }
        
        // Save to database
        var file = Files.create({
            originalName: upload.filename,
            storedName: newName,
            path: destination,
            contentType: upload.contentType,
            size: upload.size
        });
        
        return conn.json(%{
            data: %{
                id: file.id,
                url: '/files/${file.id}',
                thumbnailUrl: '/files/${file.id}/thumbnail'
            }
        });
    }
    
    static function validateUpload(upload: Upload): {valid: Bool, ?error: String} {
        if (!ALLOWED_TYPES.contains(upload.contentType)) {
            return {valid: false, error: "File type not allowed"};
        }
        
        if (upload.size > MAX_SIZE) {
            return {valid: false, error: "File too large"};
        }
        
        // Scan for viruses (optional)
        if (VirusScanner.infected(upload.path)) {
            return {valid: false, error: "File failed security scan"};
        }
        
        return {valid: true};
    }
}
```

### JWT Authentication

Implement JWT-based authentication:

```haxe
// src_haxe/auth/JWT.hx
package auth;

@:module
class JWT {
    static var SECRET = System.getEnv("JWT_SECRET");
    static var ALGORITHM = "HS256";
    static var EXPIRY = 3600; // 1 hour
    
    public static function generate(user: User): String {
        var claims = {
            sub: user.id,
            email: user.email,
            role: user.role,
            iat: Date.now().getTime(),
            exp: Date.now().getTime() + EXPIRY * 1000
        };
        
        return untyped __elixir__('
            Joken.generate_and_sign($claims, Joken.Signer.create($ALGORITHM, $SECRET))
        ');
    }
    
    public static function verify(token: String): Result<Claims, String> {
        var result = untyped __elixir__('
            Joken.verify_and_validate(
                $token,
                Joken.Signer.create($ALGORITHM, $SECRET),
                %{"sub" => &is_binary/1}
            )
        ');
        
        return switch (result) {
            case {:ok, claims}:
                Ok(claims);
            case {:error, reason}:
                Error(Std.string(reason));
        };
    }
    
    public static function refresh(token: String): Result<String, String> {
        return switch (verify(token)) {
            case Ok(claims):
                var user = Users.find(claims.sub);
                Ok(generate(user));
            case Error(e):
                Error(e);
        };
    }
}

// Authentication plug
@:plug
class JWTAuth {
    public static function call(conn: Conn, opts: Dynamic): Conn {
        var token = extractToken(conn);
        
        if (token == null) {
            return unauthorized(conn);
        }
        
        return switch (JWT.verify(token)) {
            case Ok(claims):
                conn.assign("current_user_id", claims.sub);
            case Error(_):
                unauthorized(conn);
        };
    }
    
    static function extractToken(conn: Conn): Null<String> {
        var header = conn.getReqHeader("authorization");
        if (header != null && header.startsWith("Bearer ")) {
            return header.substr(7);
        }
        return null;
    }
    
    static function unauthorized(conn: Conn): Conn {
        return conn
            .putStatus(401)
            .json(%{error: "Unauthorized"})
            .halt();
    }
}
```

## Database & Data

### Multi-tenant Database

Implement multi-tenancy with row-level security:

```haxe
// src_haxe/schemas/MultiTenant.hx
package schemas;

@:behaviour
class MultiTenant {
    public static function withTenant<T>(tenantId: String, fn: () -> T): T {
        // Set tenant context
        Process.put(:current_tenant_id, tenantId);
        
        try {
            return fn();
        } finally {
            Process.delete(:current_tenant_id);
        }
    }
}

@:schema("products")
class Product {
    public var id: Int;
    public var tenantId: String;
    public var name: String;
    public var price: Float;
    
    // Always filter by tenant
    @:before_compile
    public static function defaultScope(query: Query): Query {
        var tenantId = Process.get(:current_tenant_id);
        if (tenantId != null) {
            return query.where(tenantId: tenantId);
        }
        return query;
    }
}

// Usage
class ProductService {
    public static function listProducts(tenantId: String): Array<Product> {
        return MultiTenant.withTenant(tenantId, function() {
            return Repo.all(Product); // Automatically filtered
        });
    }
}
```

### Soft Delete Pattern

Implement soft deletes with automatic filtering:

```haxe
// src_haxe/behaviours/SoftDelete.hx
package behaviours;

@:behaviour
class SoftDelete {
    macro public static function softDelete(schema: Expr): Expr {
        return macro {
            // Add deleted_at field
            @:field public var deletedAt: Null<Date>;
            
            // Override delete
            public function delete(): Result<$schema, Changeset> {
                var changeset = Changeset.change(this, {
                    deletedAt: Date.now()
                });
                return Repo.update(changeset);
            }
            
            // Add restore
            public function restore(): Result<$schema, Changeset> {
                var changeset = Changeset.change(this, {
                    deletedAt: null
                });
                return Repo.update(changeset);
            }
            
            // Default scope
            public static function active(): Query {
                return Query.from(s in $schema)
                    .where(isNull(s.deletedAt));
            }
            
            // Include deleted
            public static function withDeleted(): Query {
                return Query.from(s in $schema);
            }
            
            // Only deleted
            public static function onlyDeleted(): Query {
                return Query.from(s in $schema)
                    .where(notNull(s.deletedAt));
            }
        };
    }
}

// Usage
@:schema("posts")
@:softDelete
class Post {
    public var id: Int;
    public var title: String;
    public var content: String;
    // deletedAt added by macro
}
```

### Database Migrations

Type-safe migration builder:

```haxe
// src_haxe/migrations/CreateProducts.hx
package migrations;

@:migration(20240101120000)
class CreateProducts {
    public function up(): Void {
        createTable("products", function(t) {
            t.id();
            t.string("name", null: false);
            t.text("description");
            t.decimal("price", precision: 10, scale: 2);
            t.integer("stock", default: 0);
            t.belongsTo("categories");
            t.timestamps();
            
            t.index(["name"], unique: true);
            t.index(["category_id", "price"]);
        });
        
        // Add check constraint
        execute('ALTER TABLE products ADD CONSTRAINT positive_price CHECK (price > 0)');
    }
    
    public function down(): Void {
        dropTable("products");
    }
}

// Migration with data transformation
@:migration(20240102120000)
class SplitUserName {
    public function up(): Void {
        alterTable("users", function(t) {
            t.addColumn("first_name", :string);
            t.addColumn("last_name", :string);
        });
        
        // Migrate data
        execute('
            UPDATE users 
            SET first_name = split_part(name, \' \', 1),
                last_name = split_part(name, \' \', 2)
        ');
        
        alterTable("users", function(t) {
            t.removeColumn("name");
        });
    }
}
```

### Full-text Search

Implement PostgreSQL full-text search:

```haxe
// src_haxe/search/ArticleSearch.hx
package search;

@:module
class ArticleSearch {
    public static function search(query: String, ?options: SearchOptions): SearchResult {
        var searchQuery = Query.from(a in Article)
            .select({
                article: a,
                rank: fragment("ts_rank(?, plainto_tsquery('english', ?))", 
                    a.searchVector, query)
            })
            .where(fragment("? @@ plainto_tsquery('english', ?)", 
                a.searchVector, query))
            .orderBy([desc: :rank]);
            
        // Apply filters
        if (options?.category != null) {
            searchQuery = searchQuery.where(a.categoryId == options.category);
        }
        
        if (options?.author != null) {
            searchQuery = searchQuery.where(a.authorId == options.author);
        }
        
        // Pagination
        var page = options?.page ?? 1;
        var limit = options?.limit ?? 20;
        searchQuery = searchQuery
            .limit(limit)
            .offset((page - 1) * limit);
            
        var results = Repo.all(searchQuery);
        
        return {
            results: results.map(r -> r.article),
            totalCount: countResults(query, options),
            highlights: generateHighlights(results, query)
        };
    }
    
    static function generateHighlights(results: Array<Dynamic>, query: String): Map<Int, String> {
        var highlights = new Map();
        
        for (r in results) {
            var highlight = untyped __elixir__('
                :pgsql.query(
                    "SELECT ts_headline('english', $1, plainto_tsquery('english', $2))",
                    [r.article.content, $query]
                )
            ');
            highlights.set(r.article.id, highlight);
        }
        
        return highlights;
    }
}

typedef SearchOptions = {
    ?category: Int,
    ?author: Int,
    ?dateFrom: Date,
    ?dateTo: Date,
    ?page: Int,
    ?limit: Int
}
```

### Caching with Redis

Implement caching layer with Redis:

```haxe
// src_haxe/cache/RedisCache.hx
package cache;

@:module
class RedisCache {
    static var POOL = :redis_pool;
    static var DEFAULT_TTL = 3600; // 1 hour
    
    public static function get<T>(key: String): Null<T> {
        var result = Redix.command(POOL, ["GET", key]);
        
        return switch (result) {
            case {:ok, null}:
                null;
            case {:ok, value}:
                Jason.decode(value);
            case {:error, _}:
                null;
        };
    }
    
    public static function set<T>(key: String, value: T, ?ttl: Int): Bool {
        var json = Jason.encode(value);
        var ttlSeconds = ttl ?? DEFAULT_TTL;
        
        var result = Redix.command(POOL, ["SETEX", key, ttlSeconds, json]);
        
        return switch (result) {
            case {:ok, "OK"}: true;
            case _: false;
        };
    }
    
    public static function remember<T>(key: String, fn: () -> T, ?ttl: Int): T {
        var cached = get(key);
        if (cached != null) {
            return cached;
        }
        
        var fresh = fn();
        set(key, fresh, ttl);
        return fresh;
    }
    
    public static function invalidate(pattern: String): Int {
        // Get all matching keys
        var keys = Redix.command(POOL, ["KEYS", pattern]);
        
        switch (keys) {
            case {:ok, keyList} if keyList.length > 0:
                var result = Redix.command(POOL, ["DEL"] ++ keyList);
                switch (result) {
                    case {:ok, count}: return count;
                    case _: return 0;
                }
            case _:
                return 0;
        }
    }
}

// Usage with automatic cache invalidation
class ProductCache {
    public static function getProduct(id: Int): Null<Product> {
        return RedisCache.remember('product:$id', function() {
            return Repo.get(Product, id);
        }, 3600);
    }
    
    public static function updateProduct(id: Int, changes: Dynamic): Product {
        var product = Repo.get(Product, id);
        var changeset = ProductChangeset.change(product, changes);
        var updated = Repo.update(changeset);
        
        // Invalidate caches
        RedisCache.invalidate('product:$id');
        RedisCache.invalidate('products:*');
        
        return updated;
    }
}
```

## Real-time Features

### Live Dashboard

Create a real-time dashboard with LiveView:

```haxe
// src_haxe/live/DashboardLive.hx
package live;

@:liveview
class DashboardLive {
    var refreshInterval: Timer;
    
    public function mount(params: Dynamic, session: Dynamic, socket: Socket): Socket {
        // Subscribe to updates
        PubSub.subscribe("metrics:updated");
        
        // Schedule refresh
        if (connected(socket)) {
            refreshInterval = Timer.sendInterval(5000, :refresh);
        }
        
        return socket
            .assign({
                metrics: loadMetrics(),
                chart_data: prepareChartData(),
                alerts: getActiveAlerts()
            });
    }
    
    public function handleInfo(:refresh, socket: Socket): Socket {
        return socket
            .assign("metrics", loadMetrics())
            .assign("chart_data", prepareChartData());
    }
    
    public function handleInfo({:metrics_updated, metrics}, socket: Socket): Socket {
        return socket
            .assign("metrics", metrics)
            .pushEvent("metrics_updated", metrics);
    }
    
    public function handleEvent("filter", params: {period: String}, socket: Socket): Socket {
        var metrics = loadMetrics(params.period);
        var chartData = prepareChartData(params.period);
        
        return socket
            .assign("metrics", metrics)
            .assign("chart_data", chartData);
    }
    
    public function terminate(reason: Dynamic, socket: Socket): Void {
        if (refreshInterval != null) {
            Timer.cancel(refreshInterval);
        }
    }
    
    function loadMetrics(?period: String): Metrics {
        return {
            users: UserMetrics.count(period),
            revenue: RevenueMetrics.total(period),
            orders: OrderMetrics.count(period),
            conversion: ConversionMetrics.rate(period)
        };
    }
}
```

### Real-time Notifications

Implement a notification system:

```haxe
// src_haxe/notifications/NotificationSystem.hx
package notifications;

@:genserver
class NotificationServer {
    var subscribers: Map<String, Array<Socket>>;
    
    public function init(args: Dynamic): Dynamic {
        return {:ok, %{subscribers: new Map()}};
    }
    
    public function handleCast({:notify, userId, notification}, state): Dynamic {
        // Send to user's sockets
        var sockets = state.subscribers.get(userId) ?? [];
        for (socket in sockets) {
            Channel.push(socket, "notification", notification);
        }
        
        // Store in database
        Notifications.create({
            userId: userId,
            ...notification,
            readAt: null
        });
        
        // Send push notification
        if (notification.priority == "high") {
            PushNotifications.send(userId, notification);
        }
        
        return {:noreply, state};
    }
    
    public function handleCall({:subscribe, userId, socket}, from, state): Dynamic {
        var sockets = state.subscribers.get(userId) ?? [];
        sockets.push(socket);
        state.subscribers.set(userId, sockets);
        
        // Send unread notifications
        var unread = Notifications.getUnread(userId);
        Channel.push(socket, "unread", %{notifications: unread});
        
        return {:reply, :ok, state};
    }
}

// Helper module
@:module
class Notify {
    public static function send(userId: String, type: String, data: Dynamic): Void {
        var notification = {
            id: UUID.generate(),
            type: type,
            data: data,
            timestamp: Date.now(),
            priority: getPriority(type)
        };
        
        GenServer.cast(NotificationServer, {:notify, userId, notification});
    }
    
    static function getPriority(type: String): String {
        return switch (type) {
            case "payment_received" | "security_alert": "high";
            case "message" | "comment": "medium";  
            default: "low";
        };
    }
}
```

## Background Jobs

### Email Queue

Implement email queue with retry logic:

```haxe
// src_haxe/jobs/EmailJob.hx
package jobs;

@:job
class EmailJob {
    static var MAX_RETRIES = 3;
    static var RETRY_DELAY = [60, 300, 900]; // Exponential backoff
    
    public function perform(args: {to: String, subject: String, template: String, data: Dynamic}): JobResult {
        try {
            var html = renderTemplate(args.template, args.data);
            
            var email = {
                to: args.to,
                subject: args.subject,
                html: html,
                text: htmlToText(html)
            };
            
            var result = Mailer.send(email);
            
            switch (result) {
                case {:ok, messageId}:
                    logSuccess(messageId, args);
                    return {:ok};
                    
                case {:error, :rate_limited}:
                    return {:retry, delay: 60};
                    
                case {:error, reason}:
                    logError(reason, args);
                    return {:error, reason};
            }
            
        } catch (e: Dynamic) {
            return {:error, e};
        }
    }
    
    public function onFailure(args: Dynamic, error: Dynamic): Void {
        // Send to dead letter queue
        DeadLetterQueue.add("email", args, error);
        
        // Alert admins for critical emails
        if (args.priority == "critical") {
            AlertService.notify("Critical email failed", {
                recipient: args.to,
                error: error
            });
        }
    }
    
    public function onSuccess(args: Dynamic): Void {
        EmailMetrics.recordSent(args);
    }
}

// Queue emails
@:module  
class EmailQueue {
    public static function sendWelcome(user: User): Void {
        EmailJob.enqueue({
            to: user.email,
            subject: "Welcome to our platform!",
            template: "welcome",
            data: {
                name: user.name,
                activationLink: generateActivationLink(user)
            }
        });
    }
    
    public static function sendBulk(recipients: Array<String>, template: String, data: Dynamic): Void {
        // Batch into chunks to avoid overwhelming the system
        var chunks = Lambda.chunk(recipients, 100);
        
        for (i in 0...chunks.length) {
            var chunk = chunks[i];
            var delay = i * 60; // Space out batches
            
            for (email in chunk) {
                EmailJob.enqueue({
                    to: email,
                    subject: data.subject,
                    template: template,
                    data: data
                }, delay: delay);
            }
        }
    }
}
```

### Image Processing Pipeline

Process uploaded images with multiple transformations:

```haxe
// src_haxe/jobs/ImageProcessor.hx
package jobs;

@:job
class ImageProcessorJob {
    static var SIZES = [
        {name: "thumbnail", width: 150, height: 150},
        {name: "small", width: 300, height: 300},
        {name: "medium", width: 600, height: 600},
        {name: "large", width: 1200, height: 1200}
    ];
    
    public function perform(args: {uploadId: String, path: String}): JobResult {
        var upload = Uploads.get(args.uploadId);
        if (upload == null) {
            return {:error, "Upload not found"};
        }
        
        try {
            // Load original image
            var image = Image.load(args.path);
            
            // Validate image
            if (!isValidImage(image)) {
                return {:error, "Invalid image"};
            }
            
            // Process each size
            var variants = [];
            for (size in SIZES) {
                var variant = processVariant(image, size);
                variants.push(variant);
            }
            
            // Optimize images
            for (v in variants) {
                optimizeImage(v.path);
            }
            
            // Upload to CDN
            var cdnUrls = uploadToCDN(variants);
            
            // Update database
            Uploads.update(args.uploadId, {
                processed: true,
                variants: cdnUrls,
                processedAt: Date.now()
            });
            
            // Clean up temp files
            cleanupTempFiles([args.path] ++ variants.map(v -> v.path));
            
            return {:ok};
            
        } catch (e: Dynamic) {
            return {:retry, delay: 30};
        }
    }
    
    function processVariant(image: Image, size: SizeConfig): Variant {
        var resized = image.resize(size.width, size.height, {
            fit: "cover",
            position: "center"
        });
        
        var path = '/tmp/${UUID.generate()}_${size.name}.jpg';
        resized.save(path, {quality: 85});
        
        return {
            name: size.name,
            path: path,
            width: size.width,
            height: size.height
        };
    }
    
    function optimizeImage(path: String): Void {
        // Use imagemin or similar
        untyped __elixir__('
            System.cmd("imagemin", [$path, "--out-dir=/tmp/optimized"])
        ');
    }
}
```

## Testing & Quality

### Property-based Testing

Use property testing for robust validation:

```haxe
// test/properties/UserPropertyTest.hx
package test.properties;

import quickcheck.QuickCheck;
import quickcheck.Generator;

class UserPropertyTest {
    @:property
    public function validEmailsAreAccepted(): Property {
        return forAll(
            Generator.email(),
            function(email) {
                var result = EmailValidator.validate(email);
                return result == true;
            }
        );
    }
    
    @:property
    public function passwordHashingIsConsistent(): Property {
        return forAll(
            Generator.string(8, 100),
            function(password) {
                var hash1 = PasswordHasher.hash(password);
                var hash2 = PasswordHasher.hash(password);
                
                // Same password should verify against both hashes
                return PasswordHasher.verify(password, hash1) &&
                       PasswordHasher.verify(password, hash2) &&
                       hash1 != hash2; // But hashes should be different (salt)
            }
        );
    }
    
    @:property
    public function serializationRoundTrip(): Property {
        return forAll(
            Generator.user(),
            function(user) {
                var json = Jason.encode(user);
                var decoded = Jason.decode(json);
                return user.equals(decoded);
            }
        );
    }
    
    @:property
    public function paginationNeverLosesItems(): Property {
        return forAll(
            Generator.list(Generator.int(1, 1000), 10, 100),
            function(ids) {
                var pageSize = 10;
                var allItems = [];
                var page = 1;
                
                while (true) {
                    var items = Paginator.getPage(ids, page, pageSize);
                    if (items.length == 0) break;
                    allItems = allItems.concat(items);
                    page++;
                }
                
                return allItems.length == ids.length &&
                       Set.fromArray(allItems).equals(Set.fromArray(ids));
            }
        );
    }
}
```

### Test Factories

Create flexible test data factories:

```haxe
// test/support/Factory.hx
package test.support;

@:factory
class Factory {
    public static function build(name: String, ?attrs: Dynamic): Dynamic {
        return switch (name) {
            case "user": buildUser(attrs);
            case "product": buildProduct(attrs);
            case "order": buildOrder(attrs);
            default: throw 'Unknown factory: $name';
        };
    }
    
    public static function create(name: String, ?attrs: Dynamic): Dynamic {
        var record = build(name, attrs);
        return Repo.insert(record);
    }
    
    public static function createList(name: String, count: Int, ?attrs: Dynamic): Array<Dynamic> {
        return [for (i in 0...count) create(name, attrs)];
    }
    
    static function buildUser(?attrs: Dynamic): User {
        var seq = sequence();
        return {
            id: attrs?.id ?? seq,
            email: attrs?.email ?? 'user$seq@example.com',
            name: attrs?.name ?? 'User $seq',
            password: attrs?.password ?? "password123",
            role: attrs?.role ?? "user",
            confirmedAt: attrs?.confirmedAt ?? Date.now(),
            insertedAt: Date.now(),
            updatedAt: Date.now()
        };
    }
    
    static function buildProduct(?attrs: Dynamic): Product {
        var seq = sequence();
        return {
            id: attrs?.id ?? seq,
            name: attrs?.name ?? 'Product $seq',
            price: attrs?.price ?? Math.random() * 100,
            stock: attrs?.stock ?? Math.floor(Math.random() * 100),
            category: attrs?.category ?? Factory.build("category")
        };
    }
    
    // Associations
    public static function withProducts(user: User, count: Int): User {
        var products = createList("product", count, {userId: user.id});
        user.products = products;
        return user;
    }
    
    // Traits
    public static function traits(name: String, trait: String, ?attrs: Dynamic): Dynamic {
        return switch (trait) {
            case "admin": build(name, {...attrs, role: "admin"});
            case "premium": build(name, {...attrs, subscription: "premium"});
            case "deleted": build(name, {...attrs, deletedAt: Date.now()});
            default: build(name, attrs);
        };
    }
    
    static var _sequence = 0;
    static function sequence(): Int {
        return ++_sequence;
    }
}

// Usage in tests
class UserTest {
    public function testUserCreation() {
        var user = Factory.create("user", {name: "John"});
        Assert.equals("John", user.name);
        
        var admin = Factory.traits("user", "admin");
        Assert.equals("admin", admin.role);
        
        var userWithOrders = Factory.build("user")
            |> Factory.withProducts(3);
        Assert.equals(3, userWithOrders.products.length);
    }
}
```

## Summary

This cookbook provides ready-to-use recipes for:
- ✅ **Web Development**: REST APIs, GraphQL, WebSockets, File uploads, JWT auth
- ✅ **Database**: Multi-tenancy, Soft deletes, Migrations, Search, Caching
- ✅ **Real-time**: LiveView dashboards, Notifications, Collaboration
- ✅ **Background Jobs**: Email queues, Image processing, Scheduled tasks
- ✅ **Testing**: Property testing, Factories, API testing

Each recipe is production-ready and follows best practices. Adapt them to your specific needs!