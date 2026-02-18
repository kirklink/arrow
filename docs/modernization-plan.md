# Arrow Framework Modernization Plan

**Goal:** Bring Arrow to feature parity with modern web frameworks (Express, Hono, Gin, Echo)

**Timeline:** 12 weeks (3 months)

**Current Status:** Phase 2 in progress. ~70-75% feature-complete compared to modern frameworks

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

## Phase 2: Production Features (Weeks 4-6)

### 2.1 File Upload Support
**Duration:** 5 days
**Task:** Handle multipart/form-data file uploads

**Implementation:**
1. Multipart form data parser middleware
2. File size and type validation
3. Temporary file management
4. Streaming support for large files
5. Multiple file upload handling
6. Form field extraction alongside files
7. Write file upload tests
8. Document with practical examples

**Why:** Common requirement for real-world applications

---

### 2.2 Static File Serving ✅
`Router.serveStaticFiles()` method checked before route matching in `_serve()`. `StaticFilesConfig` with `index` (default `index.html`), `maxAge`, `etag`, custom `headers`. `MimeType` class with 30+ type-safe static constants and `fromPath()` lookup. `Responder.sendFile()` for streaming file responses (reusable by any handler). ETag via `"mtime-size"` with `If-None-Match` → 304. Cache-Control headers. Path traversal protection (canonical path verification). GET and HEAD support. 29 tests.

---

### 2.3 Rate Limiting ✅
Fixed-window IP-based rate limiter. `RateLimitConfig` with `maxRequests`, `window`, `keyExtractor` (custom key function for API-key/header-based limiting), `includeHeaders`. `RateLimitStore` abstract interface with `MemoryRateLimitStore` (lazy cleanup). Standard headers: `X-RateLimit-Limit/Remaining/Reset`, `Retry-After`. Added `TooManyRequestsException` and `Responder.tooManyRequests()`. 33 tests.

---

### 2.4 Security Headers ✅
Helmet-style `securityHeaders()` middleware with `SecurityHeadersConfig` (const constructor, all fields nullable). 7 default headers: X-Content-Type-Options, X-Frame-Options, HSTS, Referrer-Policy, X-XSS-Protection, CSP, CORP. Built as `RequestMiddleware` so headers persist through HttpException error paths. Set null to disable a header. Header map built once at registration, not per-request. 11 tests.

---

### 2.5 Response Compression ✅
Exposed `HttpServer.autoCompress` via `Server` constructor `compress` parameter (defaults `true`). Dart's autoCompress handles Accept-Encoding negotiation and Content-Encoding headers automatically. No middleware needed — Responder writes body inline via `srcResponse.write()`, so a compression middleware would require rearchitecting. 6 tests.

---

## Phase 3: Advanced Features (Weeks 7-10)

### 3.1 Flexible Response System
**Duration:** 5 days
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
**Duration:** 5 days
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
**Duration:** 5 days
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

### 3.4 Request Timeouts
**Duration:** 2 days
**Task:** Prevent hanging requests

**Implementation:**
1. Configurable timeout middleware
2. Per-route timeout configuration
3. Graceful timeout handling
4. Custom timeout error responses
5. Write timeout tests
6. Document timeout strategies

**Why:** Prevent resource exhaustion from slow requests

---

### 3.5 Graceful Shutdown
**Duration:** 3 days
**Task:** Zero-downtime deployments

**Implementation:**
1. Signal handling (SIGTERM, SIGINT)
2. In-flight request tracking
3. Configurable drain period
4. Health check endpoint that becomes unhealthy during shutdown
5. Write shutdown tests
6. Document deployment strategies

**Why:** Professional production deployments

---

## Phase 4: Polish & Examples (Weeks 11-12)

### 4.1 Comprehensive Test Suite (INTEGRATED)
**Approach:** Tests are written alongside each feature (not as separate phase)

**Additional Testing Tasks:**
1. Fix HTTP server test timeout issue (integration tests)
2. Set up test coverage reporting
3. Achieve 100+ total tests across all features
4. Performance benchmarks
5. Load testing scenarios
6. Document testing patterns

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
**Duration:** 5 days
**Task:** Real-world usage examples

**Examples to Build:**
1. **Complete CRUD API** - Full REST API with all features
2. **Authentication API** - JWT auth, refresh tokens, password reset
3. **File Upload Service** - Image upload with validation and storage
4. **WebSocket Chat** - Real-time chat application
5. **API Gateway** - Rate limiting, proxy, aggregation

**Why:** Help developers learn and adopt Arrow

---

## Progress

### Feature Coverage
- ✅ All HTTP methods (GET, POST, PUT, PATCH, DELETE, HEAD)
- ✅ Query parameter helpers
- ✅ Request validation framework (endorse integration)
- ✅ Enhanced error handling (HttpException hierarchy)
- ✅ Cookie support
- ✅ Security headers (Helmet-style)
- ✅ Rate limiting (fixed window, configurable)
- ✅ Response compression (gzip via autoCompress)
- ⬜ File uploads
- ✅ Static file serving (ETag, Cache-Control, MimeType, sendFile)
- ⬜ Streaming responses
- ⬜ WebSocket support
- ⬜ Flexible response types
- ⬜ Request timeouts
- ⬜ Graceful shutdown

### Quality Metrics
- **Tests:** 271 passing tests (target: 250+) ✅
- **Coverage:** TBD (target: >80%)
- **Documentation:** Dart docs on all new public APIs
- **Examples:** arrow_example demonstrates Phase 1 features

### Developer Experience
- Clear error messages
- Helpful debug logging
- Hot reload support
- Easy onboarding with examples
- Comprehensive API documentation

---

## Out of Scope

These are intentionally excluded from this plan:

1. **Template rendering** - Arrow is API-focused
2. **Database integrations** - Too opinionated, user choice
3. **ORM/query builders** - User choice
4. **GraphQL support** - Different paradigm, separate package
5. **OpenAPI generation** - Already in separate `arrow_openapi` package
6. **MCP server generation** - Already in separate `arrow_mcp_generator` package

---

## Dependencies & Integration

### External Packages to Add
- Validation framework (git submodule - user provided)
- Consider: cookie signing library
- Consider: compression libraries if not in Dart core

### Integration with Existing Packages
- `arrow_openapi` - Can annotate routes for spec generation
- `arrow_mcp_generator` - Can annotate routes for MCP server generation
- Both work alongside core framework

---

## Breaking Changes

### Breaking Changes Made (Phase 1)
1. `Parameters.get()` returns `null` instead of empty string for missing params
2. Responder error methods accept `Map<String, Object>` instead of `Map<String, String>`

### Anticipated Breaking Changes (Phases 2-4)
1. Response format flexibility (optional breaking change)
2. Additional error handling changes possible

### Migration Strategy
1. Document all breaking changes clearly
2. Provide migration examples
3. Consider deprecation period for major changes
4. Version bump to 0.2.0 after Phase 1

---

## Development Workflow

### For Each Feature:
1. **Design** - Review API, check existing code
2. **Implement** - Write feature code with Dart docs
3. **Test** - Write comprehensive tests
4. **Document** - Update guides and examples
5. **Review** - Code review and feedback
6. **Commit** - Atomic commits with clear messages

### Testing Strategy:
- Unit tests for all new functions/classes
- Integration tests for request/response cycles
- Example projects serve as integration tests
- Manual testing for UI-dependent features (WebSockets, etc.)

### Documentation Strategy:
- Dart docs on all public APIs
- README updates for major features
- Guides in docs/ directory
- Examples in arrow_example/ and separate example projects

---

## Timeline Summary

| Phase | Duration | Key Deliverables |
|-------|----------|-----------------|
| Phase 1 | 3 weeks | HTTP methods, query helpers, validation, errors, cookies |
| Phase 2 | 3 weeks | File uploads, static files, rate limiting, security, compression |
| Phase 3 | 4 weeks | Flexible responses, streaming, WebSockets, timeouts, shutdown |
| Phase 4 | 2 weeks | Examples, polish, documentation completion |
| **Total** | **12 weeks** | **Production-ready framework** |

---

## Risk Management

### Resolved Blockers
1. ~~HTTP server test timeout~~ — Solved with Completer-based test helper (see `docs/http-server-testing-solution.md`)
2. ~~Flaky pipeline tests~~ — Fixed async timing assertions

### Remaining Risks
1. **Dart SDK limitations** — May need workarounds for some features
2. **Performance regressions** — Benchmarking needed before 1.0
3. **Endorse runtime** — ClassResult/ListResult commented out, needs restoration before code gen works

---

## Next Steps

1. ✅ Phase 1 complete
2. Phase 2 in progress — security headers, rate limiting, compression, static files done
3. Remaining Phase 2: file uploads
4. Merge `dev` → `main` for stable release after Phase 2

---

**Last Updated:** 2026-02-18
**Status:** Phase 2 in progress (4/5 tasks complete)
