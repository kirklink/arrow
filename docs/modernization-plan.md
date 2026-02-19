# Arrow Framework Modernization Plan

**Goal:** Bring Arrow to feature parity with modern web frameworks (Express, Hono, Gin, Echo)

**Current Status:** Phases 1-2 complete, JWT auth complete, Phase 3 mostly complete. ~95% feature-complete. 380 passing tests.

---

## Key Principles

1. **Test as we develop** - Write tests alongside features, not after
2. **Document as we develop** - Add Dart docs and guides with each feature
3. **Build on existing code** - Extend and improve rather than replace
4. **Stay opinionated** - Maintain Arrow's 80-90% use case focus

---

## Phase 1: Critical REST API Features ✅

### 1.1 Complete HTTP Method Support ✅
Added PATCH and HEAD methods to Router with constants, Dart docs, and 15 tests.

### 1.2 Query Parameter Helpers ✅
Added `queryParam()`, `queryParams()`, `queryInt()`, `queryBool()` on Request. Also fixed `Parameters.get()` to return null instead of empty string for missing params. 27 tests.

### 1.3 Endorse Validation Integration ✅
Added endorse as workspace submodule. No validation middleware — validation stays in the handler as a one-liner (`Model.$endorse.validate(req.content!.map)`), which is naturally typed. HttpException is the integration point: `throw BadRequestException('Validation failed', endorse.errors)`.

### 1.4 Enhanced Error Handling ✅
Created HttpException hierarchy (BadRequest 400, Unauthorized 401, Forbidden 403, NotFound 404, Conflict 409, InternalServer 500). Router.serve() auto-catches and converts to standard JSON error response. Widened Responder errors from `Map<String, String>` to `Map<String, Object>` for nested structures. Added generic `Responder.error()` method. 23 tests.

### 1.5 Cookie Support ✅
`req.cookies` getter (cached `Map<String, String>`) and `req.cookie(name)` for reading. `req.respond.setCookie()` with full options (httpOnly, secure, maxAge, expires, path, domain, sameSite) and `clearCookie()` for writing. No middleware needed — dart:io handles parsing/serialization. httpOnly defaults true. Signed cookies deferred (REST APIs use JWT). 27 tests.

**Phase 1 total: 192 tests.**

---

## Phase 2: Production Features ✅

### 2.1 File Upload Support ✅
`readMultipartContent()` middleware parses multipart/form-data bodies using the `mime` package's `MimeMultipartTransformer`. `MultipartFormData` stored on `req.context` with static `MultipartFormData.of(req)` accessor. `UploadedFile` value class with `fieldName`, `filename`, `contentType`, `bytes`. `MultipartConfig` with `maxFileSize` (10MB default), `maxTotalSize` (50MB), `maxFiles` (10), `allowedMimeTypes` (empty = all). In-memory buffering via `BytesBuilder`. Pass-through for non-multipart requests. 28 tests.

### 2.2 Static File Serving ✅
`Router.serveStaticFiles()` method checked before route matching in `_serve()`. `StaticFilesConfig` with `index` (default `index.html`), `maxAge`, `etag`, custom `headers`. `MimeType` class with 30+ type-safe static constants and `fromPath()` lookup. `Responder.sendFile()` for streaming file responses (reusable by any handler). ETag via `"mtime-size"` with `If-None-Match` → 304. Cache-Control headers. Path traversal protection (canonical path verification). GET and HEAD support. 29 tests.

### 2.3 Rate Limiting ✅
Fixed-window IP-based rate limiter. `RateLimitConfig` with `maxRequests`, `window`, `keyExtractor` (custom key function for API-key/header-based limiting), `includeHeaders`. `RateLimitStore` abstract interface with `MemoryRateLimitStore` (lazy cleanup). Standard headers: `X-RateLimit-Limit/Remaining/Reset`, `Retry-After`. Added `TooManyRequestsException` and `Responder.tooManyRequests()`. 33 tests.

### 2.4 Security Headers ✅
Helmet-style `securityHeaders()` middleware with `SecurityHeadersConfig` (const constructor, all fields nullable). 7 default headers: X-Content-Type-Options, X-Frame-Options, HSTS, Referrer-Policy, X-XSS-Protection, CSP, CORP. Built as `RequestMiddleware` so headers persist through HttpException error paths. Set null to disable a header. Header map built once at registration, not per-request. 11 tests.

### 2.5 Response Compression ✅
Exposed `HttpServer.autoCompress` via `Server` constructor `compress` parameter (defaults `true`). Dart's autoCompress handles Accept-Encoding negotiation and Content-Encoding headers automatically. No middleware needed — Responder writes body inline via `srcResponse.write()`, so a compression middleware would require rearchitecting. 6 tests.

**Phase 2 total: 107 tests.**

---

## Architecture Cleanup ✅ (completed between Phase 2 and Phase 3)

### API Simplification ✅
- Chainable cookies: `req.respond.setCookie(...).ok(data: {...})`
- Added `req.respond.created()` for 201 responses
- Consistent middleware naming: all lowercase functions — `cors(CorsConfig(...))`, `rateLimit(RateLimitConfig(...))`, `securityHeaders(SecurityHeadersConfig(...))`
- Removed legacy class-based middleware wrappers

### Request Timeouts ✅
Configurable global request timeout via `Arrow().run(..., requestTimeout: Duration(seconds: 30))`. Server-level enforcement — when a handler exceeds the timeout, responds with 408 Request Timeout and standard JSON error envelope. 4 tests.

### Graceful Shutdown ✅
SIGINT and SIGTERM signal handling with configurable drain period via `shutdownTimeout` parameter (default 30s). New requests during shutdown receive 503 Service Unavailable. In-flight requests allowed to complete within the drain window. 3 tests.

### Request ID Correlation ✅
`requestId()` middleware generates UUID v4 or echoes client-provided `X-Request-ID` header. ID stored in request context and set on response header. 7 tests.

**Architecture cleanup total: 14 tests (plus existing tests updated for API changes).**

---

## JWT Authentication ✅

### Provider-Agnostic JWT Auth Middleware ✅
Replaced the half-baked Guard system and tightly-coupled Firebase auth with `jwtAuth()` middleware built on `dart_jsonwebtoken` (353 likes, 160/160 pub points, 14 algorithms). `JwtAuthConfig` with required `key` (any `JWTKey`: HMAC, RSA, ECDSA, EdDSA), optional `issuer`, `audience`, custom `tokenExtractor`, customizable error messages. Verified JWT stored in request context via `jwtKey`/`getJwt(req)`. Barrel export `lib/jwt.dart` re-exports `dart_jsonwebtoken` types so users don't need a separate dependency. 29 tests.

### Guard System Removal ✅
Deleted `Guard` typedef and all references. Guard was half-baked: single guard per route (overwrites), hardcoded 403, no customization, zero tests, zero usage. JWT middleware via `addOnRequest` is strictly superior.

### Firebase Auth Removal ✅
Deleted `lib/src/middlewares/firebase_authentication/` (4 files). Hand-rolled JWT parser tightly coupled to Firebase, used old context API, no tests. Users needing Firebase auth can use `dart_firebase_admin` separately.

**JWT auth total: 29 tests.**

---

## MCP Code Generation ✅

### Runtime Types ✅
MCP annotations (`@McpServer`, `@McpTool`) and runtime types (`McpToolDefinition`, `McpRequest`, `McpToolResult`, `McpDispatcher`, `McpToolRegistry`) in `lib/src/mcp/`. Zero additional dependencies. Barrel export via `lib/mcp.dart`. 24 unit tests.

### Code Generator ✅
`arrow_mcp_builder/` package using `source_gen` / `build_runner`. `LibraryBuilder` produces standalone `.mcp.dart` files (not part files). Scans for `@McpServer` annotated classes, reads `@McpTool` from fields, auto-detects path params from `{param}` syntax. 14 unit tests.

### HTTP Transport ✅
Generated dispatcher classes make real HTTP proxy calls to the Arrow server instead of returning stubs. Supports GET, POST, PUT, PATCH, DELETE with path param interpolation via `Uri.encodeComponent`. Non-path params sent as JSON body for POST/PUT/PATCH. Injectable `http.Client` for testing. Response status checking (2xx = success, else error with status code).

### E2E Validation ✅
`arrow_example/` includes annotated MCP config class with 5 tools, generated `.mcp.dart` file, and 17 E2E tests verifying tool definitions, HTTP dispatch via MockClient, path param exclusion from body, URL encoding, and error handling.

---

## Phase 3: Advanced Features (remaining)

### 3.1 Flexible Response System
**Task:** Support non-JSON responses

**Implementation:**
1. Make JSON-only format optional/configurable
2. Support multiple content types:
   - JSON (existing)
   - HTML
   - XML
   - Plain text
   - Binary data
3. File download responses with proper headers
4. Full redirect support (all status codes)
5. Content-Type negotiation (Accept header)
6. Write tests for all response types
7. Document response flexibility

**Why:** Current limitation blocks many use cases

---

### 3.2 Streaming Responses
**Task:** Stream large responses efficiently

**Implementation:**
1. Stream API for chunked responses
2. File streaming for large downloads
3. Server-Sent Events (SSE) support
4. Proper Transfer-Encoding headers
5. Backpressure handling
6. Write streaming tests
7. Document streaming patterns

**Why:** Essential for large files and real-time data

---

### 3.3 WebSocket Support
**Task:** Enable real-time bidirectional communication

**Implementation:**
1. WebSocket upgrade handling
2. Message routing to handlers
3. Broadcasting to multiple clients
4. Connection lifecycle management
5. Ping/pong for connection health
6. Binary and text message support
7. Write WebSocket tests
8. Document with chat example

**Why:** Required for real-time features (chat, notifications, live updates)

---

## Phase 4: Polish & Examples

### 4.1 Comprehensive Test Suite (INTEGRATED)
**Approach:** Tests are written alongside each feature (not as separate phase)

**Additional Testing Tasks:**
1. Set up test coverage reporting
2. Performance benchmarks
3. Load testing scenarios
4. Document testing patterns

---

### 4.2 Documentation (INTEGRATED)
**Approach:** Documentation written alongside each feature (not as separate phase)

**Additional Documentation Tasks:**
1. Complete API reference from Dart docs
2. Architecture documentation
3. Migration guide for breaking changes
4. Best practices guide
5. Comparison with other frameworks
6. Contribution guide

---

### 4.3 Example Projects
**Task:** Real-world usage examples

**Examples to Build:**
1. **Complete CRUD API** - Full REST API with all features
2. **Authentication API** - JWT auth, refresh tokens, password reset
3. **File Upload Service** - Image upload with validation and storage
4. **WebSocket Chat** - Real-time chat application
5. **MCP-Enabled API** - Arrow API with generated MCP tool definitions

**Why:** Help developers learn and adopt Arrow

---

## Progress

### Feature Coverage
- ✅ All HTTP methods (GET, POST, PUT, PATCH, DELETE, HEAD)
- ✅ Query parameter helpers
- ✅ Request validation framework (endorse integration)
- ✅ Enhanced error handling (HttpException hierarchy)
- ✅ Cookie support (reading and chainable writing)
- ✅ Security headers (Helmet-style)
- ✅ Rate limiting (fixed window, configurable)
- ✅ Response compression (gzip via autoCompress)
- ✅ File uploads (multipart/form-data with validation)
- ✅ Static file serving (ETag, Cache-Control, MimeType, sendFile)
- ✅ Request timeouts (configurable per-server, 408 response)
- ✅ Graceful shutdown (SIGINT/SIGTERM, in-flight drain, 503 during shutdown)
- ✅ Request ID correlation (X-Request-ID, UUID generation)
- ✅ MCP code generation (annotations, runtime types, HTTP transport proxy)
- ✅ JWT authentication (provider-agnostic, dart_jsonwebtoken)
- ⬜ Flexible response types
- ⬜ Streaming responses / SSE
- ⬜ WebSocket support

### Quality Metrics
- **Tests:** 381 passing tests in arrow, 14 in arrow_mcp_builder, 238 in arrow_example (target: 250+) ✅
- **Coverage:** TBD (target: >80%)
- **Documentation:** Dart docs on all new public APIs, CLAUDE.md API reference
- **Examples:** arrow_example demonstrates Phases 1-2, MCP code generation

### Developer Experience
- Clear error messages
- Helpful debug logging
- Hot reload support
- Easy onboarding with examples
- Comprehensive API documentation
- AI-ready with MCP code generation

---

## Out of Scope

These are intentionally excluded from this plan:

1. **Template rendering** - Arrow is API-focused
2. **Database integrations** - Too opinionated, user choice
3. **ORM/query builders** - User choice
4. **GraphQL support** - Different paradigm, separate package
5. **OpenAPI generation** - Separate `arrow_openapi` package

---

## Dependencies & Integration

### External Packages
- `http` - HTTP client (used by generated MCP dispatchers)
- `mime` - MIME type detection (multipart parsing)
- `uuid` - UUID generation (request IDs)
- `recase` - Case conversion (MCP code generation)
- `dart_jsonwebtoken` - JWT verification and signing (14 algorithms)

### Companion Packages
- `arrow_mcp_builder` - MCP code generation (source_gen/build_runner)
- `arrow_openapi` - OpenAPI spec generation (planned)

---

## Breaking Changes

### Breaking Changes Made
1. `Parameters.get()` returns `null` instead of empty string for missing params
2. Responder error methods accept `Map<String, Object>` instead of `Map<String, String>`
3. Middleware renamed: `CorsMiddleware(Cors(...))` → `cors(CorsConfig(...))`
4. `Guard` system removed (use `jwtAuth()` or custom request middleware instead)
5. Firebase authentication middleware removed (use `dart_firebase_admin` or `jwtAuth()` instead)
6. `Parameters.get()` now URL-decodes path parameters (e.g., `hello%20world` → `hello world`). Remove any manual `Uri.decodeComponent()` calls on path params.

### Migration Strategy
1. Document all breaking changes clearly
2. Provide migration examples
3. Consider deprecation period for major changes
4. Version bump to 0.2.0 after stabilization

---

## Next Steps

1. ✅ Phase 1 complete (192 tests)
2. ✅ Phase 2 complete (107 tests)
3. ✅ Architecture cleanup: timeouts, graceful shutdown, request ID, API simplification
4. ✅ MCP code generation with HTTP transport
5. ✅ JWT authentication (Guard + Firebase auth removed)
6. Remaining Phase 3: flexible responses, streaming/SSE, WebSockets
6. Phase 4: examples, polish, documentation completion
7. Merge `dev` → `main` for stable release

---

**Last Updated:** 2026-02-19
**Status:** Phase 3 in progress (3 items remaining: flexible responses, streaming, WebSockets)
