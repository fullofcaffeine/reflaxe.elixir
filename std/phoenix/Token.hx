package phoenix;

/**
 * Phoenix.Token extern definitions for secure token generation and verification
 * 
 * Tokens are used for authentication, API access, password resets, and other
 * security-sensitive operations in Phoenix applications.
 * 
 * @see https://hexdocs.pm/phoenix/Phoenix.Token.html
 */

/**
 * Token options for signing and verification
 */
typedef TokenOptions = {
    /**
     * Number of iterations for key derivation (default: 1000)
     */
    var ?key_iterations: Int;
    
    /**
     * Length of derived key in bytes (default: 32)
     */
    var ?key_length: Int;
    
    /**
     * Digest algorithm for key derivation (default: :sha256)
     */
    var ?key_digest: String;
    
    /**
     * Custom timestamp for token signing (default: current time)
     */
    var ?signed_at: Int;
    
    /**
     * Maximum age in seconds before token expires (default: 86400 = 1 day)
     */
    var ?max_age: Int;
};

/**
 * Token context - can be endpoint, connection, socket, or secret key base
 */
typedef TokenContext = Dynamic;

/**
 * Salt for token generation - should be unique per use case
 */
typedef TokenSalt = String;

/**
 * Phoenix.Token functions for secure token operations
 */
@:native("Phoenix.Token")
extern class Token {
    /**
     * Sign data into a token using HMAC
     * Returns a URL-safe base64 encoded token
     * 
     * @param context Phoenix endpoint, Plug.Conn, Phoenix.Socket, or secret key base
     * @param salt Unique salt for this token type
     * @param data Data to encode in the token
     * @param opts Token options (key_iterations, max_age, etc.)
     */
    @:native("Phoenix.Token.sign")
    public static function sign(context: TokenContext, salt: TokenSalt, data: Dynamic, ?opts: TokenOptions): String;
    
    /**
     * Verify and decode a signed token
     * Returns {:ok, data} on success or {:error, reason} on failure
     * 
     * @param context Phoenix endpoint, Plug.Conn, Phoenix.Socket, or secret key base
     * @param salt Salt used when signing the token
     * @param token Token to verify and decode
     * @param opts Token options (must match signing options)
     */
    @:native("Phoenix.Token.verify")
    public static function verify(context: TokenContext, salt: TokenSalt, token: String, ?opts: TokenOptions): Dynamic;
    
    /**
     * Encrypt data into a token using AES-GCM
     * Returns a URL-safe base64 encoded encrypted token
     * More secure than sign/4 but slower
     * 
     * @param context Phoenix endpoint, Plug.Conn, Phoenix.Socket, or secret key base
     * @param secret Secret key for encryption (should be different from salt)
     * @param data Data to encrypt in the token
     * @param opts Token options
     */
    @:native("Phoenix.Token.encrypt")
    public static function encrypt(context: TokenContext, secret: String, data: Dynamic, ?opts: TokenOptions): String;
    
    /**
     * Decrypt and verify an encrypted token
     * Returns {:ok, data} on success or {:error, reason} on failure
     * 
     * @param context Phoenix endpoint, Plug.Conn, Phoenix.Socket, or secret key base
     * @param secret Secret key used for encryption
     * @param token Encrypted token to decrypt
     * @param opts Token options (must match encryption options)
     */
    @:native("Phoenix.Token.decrypt")
    public static function decrypt(context: TokenContext, secret: String, token: String, ?opts: TokenOptions): Dynamic;
}

/**
 * Common salt values used in Phoenix applications
 * These should be unique per use case for security
 */
class TokenSalts {
    /**
     * Salt for user authentication tokens
     */
    public static inline var USER_AUTH = "user auth";
    
    /**
     * Salt for password reset tokens
     */
    public static inline var PASSWORD_RESET = "password reset";
    
    /**
     * Salt for email verification tokens
     */
    public static inline var EMAIL_VERIFICATION = "email verification";
    
    /**
     * Salt for API access tokens
     */
    public static inline var API_ACCESS = "api access";
    
    /**
     * Salt for channel join tokens
     */
    public static inline var CHANNEL_JOIN = "channel join";
}