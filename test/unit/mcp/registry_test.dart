import 'package:test/test.dart';
import 'package:arrow/mcp.dart';

class _TestDispatcher extends McpDispatcher {
  @override
  final List<McpToolDefinition> tools;

  _TestDispatcher(this.tools);

  @override
  Future<McpToolResult?> dispatch(McpRequest request) async {
    if (request.toolName == 'dispatcherTool') {
      return McpToolResult.text('from dispatcher');
    }
    return null;
  }
}

void main() {
  group('McpToolRegistry', () {
    late McpToolRegistry registry;

    setUp(() {
      registry = McpToolRegistry();
    });

    test('starts empty', () {
      expect(registry.tools, isEmpty);
    });

    test('register adds tool and handler', () {
      const tool = McpToolDefinition(
        name: 'myTool',
        description: 'A tool',
        inputSchema: {},
      );
      registry.register(tool, (args) async => McpToolResult.text('ok'));
      expect(registry.tools, hasLength(1));
      expect(registry.tools.first.name, equals('myTool'));
    });

    test('findTool returns tool by name', () {
      const tool = McpToolDefinition(
        name: 'findMe',
        description: 'Find me',
        inputSchema: {},
      );
      registry.register(tool, (args) async => McpToolResult.text('ok'));
      expect(registry.findTool('findMe'), isNotNull);
      expect(registry.findTool('findMe')!.name, equals('findMe'));
    });

    test('findTool returns null for unknown name', () {
      expect(registry.findTool('nonexistent'), isNull);
    });

    test('dispatch calls correct handler', () async {
      const tool = McpToolDefinition(
        name: 'echo',
        description: 'Echo args',
        inputSchema: {},
      );
      registry.register(
        tool,
        (args) async => McpToolResult.text('got: ${args['msg']}'),
      );

      final result = await registry.dispatch(
        McpRequest(toolName: 'echo', arguments: {'msg': 'hello'}),
      );
      expect(result, isNotNull);
      expect((result!.content.first as McpTextContent).text,
          equals('got: hello'));
    });

    test('dispatch returns null for unknown tool', () async {
      final result = await registry.dispatch(
        McpRequest(toolName: 'nonexistent'),
      );
      expect(result, isNull);
    });

    test('registerDispatcher merges tools', () {
      final dispatcher = _TestDispatcher([
        McpToolDefinition(
          name: 'dispatcherTool',
          description: 'From dispatcher',
          inputSchema: {},
        ),
      ]);
      registry.registerDispatcher(dispatcher);
      expect(registry.tools, hasLength(1));
      expect(registry.findTool('dispatcherTool'), isNotNull);
    });

    test('dispatch routes to dispatcher for dispatcher tools', () async {
      final dispatcher = _TestDispatcher([
        McpToolDefinition(
          name: 'dispatcherTool',
          description: 'From dispatcher',
          inputSchema: {},
        ),
      ]);
      registry.registerDispatcher(dispatcher);

      final result = await registry.dispatch(
        McpRequest(toolName: 'dispatcherTool'),
      );
      expect(result, isNotNull);
      expect((result!.content.first as McpTextContent).text,
          equals('from dispatcher'));
    });

    test('direct handler takes priority over dispatcher', () async {
      const tool = McpToolDefinition(
        name: 'dispatcherTool',
        description: 'Override',
        inputSchema: {},
      );
      registry.register(
        tool,
        (args) async => McpToolResult.text('from direct'),
      );

      final dispatcher = _TestDispatcher([tool]);
      registry.registerDispatcher(dispatcher);

      final result = await registry.dispatch(
        McpRequest(toolName: 'dispatcherTool'),
      );
      expect((result!.content.first as McpTextContent).text,
          equals('from direct'));
    });
  });
}
