# Arrow MCP Code Generation — Session Instructions

## What This Is

Add annotation-driven MCP (Model Context Protocol) endpoint generation to Arrow,
following the same pattern as Endorse (annotations → build_runner → generated code).

This work is foundational for the Envoy agent framework (Phase 6), but is Arrow's
responsibility to own. Build it here; Envoy will consume it.

---

## Existing Sketch

[arrow_example/lib/mcp_example.dart](../arrow_example/lib/mcp_example.dart) has a
commented-out annotation design that shows the intended API. Use it as the starting
point — the shape is right.

Key annotations already sketched:
- `@McpServer(name, description)` — marks a router config class as an MCP server
- `@McpTool(description, parameters)` — marks a route handler as an MCP-exposed tool
- `@RouteHandler.get/post/...` — already pairs routes to handlers

---

## What To Build Now

### 1. Annotations (runtime, no codegen yet)
Define the annotation classes in `arrow/lib/src/mcp/`:
```dart
class McpServer {
  final String name;
  final String description;
  const McpServer(this.name, {required this.description});
}

class McpTool {
  final String description;
  final Map<String, String> parameters;
  const McpTool({required this.description, this.parameters = const {}});
}
```

### 2. build_runner builder scaffold
Create the builder structure in `arrow_builder/` (new package, following
`stanza_builder` pattern) or inside `arrow/` if preferred:
- Builder class that reads `@McpServer` + `@McpTool` annotations
- Generates a `*.mcp.dart` file alongside the annotated config class
- Register in `build.yaml`

### 3. Generated output — stub the format
The generated file should produce a valid MCP server definition. For now, generate
a minimal valid structure and leave a `TODO` comment where the full MCP JSON-RPC
handler would go. **Do not finalize the generated HTTP handler yet** — the exact
shape Envoy needs isn't known until Phase 5.

What the generated file should contain at minimum:
- A list of tool definitions (name, description, input schema) in MCP format
- A stub `handleRequest(McpRequest)` dispatcher that routes by tool name
- Clear extension points for the HTTP transport layer

---

## What To Leave As Stubs (Do Not Finalize Yet)

- **The HTTP transport**: how MCP JSON-RPC is served over Arrow routes. Envoy's
  Phase 5 will define what endpoints it needs. Design the extension point, not the
  implementation.
- **Input schema generation**: for now, accept `Map<String, String>` parameter
  descriptions. Full JSON Schema generation from Dart types is Phase 6+ work.
- **Authentication/authorization**: out of scope for the generator itself.

---

## The Known Consumer (Envoy)

When Envoy reaches Phase 6, it will need to expose:
1. **Tools** from its tool registry as MCP tools — each with name, description,
   and JSON Schema input spec
2. **Sessions** potentially as MCP resources (to be determined)

The Arrow MCP generator's output needs to be composable enough that Envoy can
feed it a dynamic list of tool definitions (not just statically annotated handlers).
This is the key design constraint: the generator handles the static case, but the
runtime needs to support a dynamic tool list as well.

---

## Relationship to Envoy Plan

- Envoy `agent_plan.md` — Phase 6 (MCP): "Arrow `@McpTool` annotation + code
  generation; Envoy exposes capabilities as MCP server"
- This work unblocks Phase 6 but is not on the critical path until then
- Treat as exploratory/foundational — get the annotation design and builder
  scaffolding in place, validate the pattern works, leave generated format flexible
