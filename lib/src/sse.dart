/// A Server-Sent Event to be written to an SSE stream.
///
/// Encodes to the [SSE wire format](https://html.spec.whatwg.org/multipage/server-sent-events.html):
///
/// ```
/// event: update
/// id: 42
/// data: {"status": "running"}
///
/// ```
///
/// Multi-line [data] is split into multiple `data:` lines per the spec.
class SseEvent {
  /// The event type. Maps to the `event:` field in SSE.
  ///
  /// If null, the browser dispatches it as a generic `message` event.
  final String? event;

  /// The event payload. Maps to the `data:` field in SSE.
  ///
  /// Multi-line strings are automatically split into multiple `data:` lines.
  final String data;

  /// Optional event ID. Maps to the `id:` field in SSE.
  ///
  /// The browser stores this and sends it as `Last-Event-ID` on reconnect.
  final String? id;

  /// Optional retry interval in milliseconds. Maps to the `retry:` field.
  ///
  /// Tells the browser how long to wait before reconnecting after a drop.
  final int? retry;

  const SseEvent({this.event, required this.data, this.id, this.retry});

  /// Encodes to the SSE wire format.
  String encode() {
    final buffer = StringBuffer();
    if (event != null) buffer.writeln('event: $event');
    if (id != null) buffer.writeln('id: $id');
    if (retry != null) buffer.writeln('retry: $retry');
    for (final line in data.split('\n')) {
      buffer.writeln('data: $line');
    }
    buffer.writeln(); // blank line terminates the event
    return buffer.toString();
  }
}
