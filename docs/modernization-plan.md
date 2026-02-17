# Arrow Framework Modernization Plan

**Goal:** Bring Arrow to feature parity with modern web frameworks (Express, Hono, Gin, Echo)

**Timeline:** 12 weeks (3 months)

**Current Status:** Phase 1 complete. ~55-60% feature-complete compared to modern frameworks

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

**Phase 1 total: 192 passing tests.**

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

### 2.2 Static File Serving
**Duration:** 2 days
**Task:** Middleware for serving static files

**Implementation:**
1. Static file serving middleware
2. Directory path configuration
3. ETag support for caching
4. Range request support (partial content)
5. Content-Type detection
6. Cache-Control headers
7. Write static file tests
8. Document usage patterns

**Why:** Serve frontend assets, images, downloads

---

### 2.3 Rate Limiting
**Duration:** 3 days
**Task:** Prevent abuse with rate limiting

**Implementation:**
1. IP-based rate limiter middleware
2. Configurable limits (requests per window)
3. Per-route rate limit configuration
4. Sliding window algorithm
5. Custom rate limit exceeded responses
6. Memory-based storage (consider Redis later)
7. Write rate limiting tests
8. Document with security best practices

**Why:** Prevent abuse, DoS attacks, ensure fair usage

---

### 2.4 Security Middleware
**Duration:** 3 days
**Task:** Add comprehensive security headers

**Implementation:**
1. Security headers middleware (Helmet-style):
   - X-Content-Type-Options
   - X-Frame-Options
   - X-XSS-Protection
   - Strict-Transport-Security
   - Content-Security-Policy
   - Referrer-Policy
2. CSRF protection middleware
3. XSS prevention helpers
4. Configurable security profiles
5. Write security tests
6. Document security best practices

**Why:** Security is non-negotiable for production apps

---

### 2.5 Response Compression
**Duration:** 2 days
**Task:** Compress responses for performance

**Implementation:**
1. Gzip compression middleware
2. Configurable compression levels
3. Content-Type filtering (only compress text-based)
4. Minimum response size threshold
5. Accept-Encoding header checking
6. Write compression tests
7. Document performance impact

**Why:** Reduce bandwidth and improve response times

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
- ⬜ File uploads
- ⬜ Static file serving
- ⬜ Rate limiting
- ⬜ Security headers
- ⬜ Compression
- ⬜ Streaming responses
- ⬜ WebSocket support
- ⬜ Flexible response types
- ⬜ Request timeouts
- ⬜ Graceful shutdown

### Quality Metrics
- **Tests:** 192 passing tests (target: 250+)
- **Coverage:** TBD (target: >80%)
- **Documentation:** Dart docs on all new public APIs
- **Examples:** arrow_example demonstrates all Phase 1 features

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
2. Begin Phase 2 implementation (file uploads, static files, rate limiting, security, compression)
3. Merge `dev` → `main` for stable Phase 1 release

---

**Last Updated:** 2026-02-17
**Status:** Phase 1 complete, Phase 2 ready to start
