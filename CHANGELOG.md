# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
## [1.1.2] - 2026-06-03
### Fixed
- Fixed empty "fixed" section in changelog (meta fix)
- Minor documentation and formatting improvements

### Changed
- Updated changelog format and structure for better readability
    
## [1.1.1] - 2026-06-03

### Added
- **Comprehensive English documentation** for all Dart source files
  - Complete API documentation for `WsClient` abstract class
  - Detailed documentation for `RxWs` core implementation with RFC 6455 frame format
  - Platform-specific guides for `WsClientIO` (native) and `WsClientWeb` (web)
  - Factory pattern documentation in `ws_client_factory.dart`
  - Library-level documentation in main `rxws.dart` export file with real-world examples

- **Enhanced README.md** with extensive guides and examples
  - Complete API reference with comprehensive code examples
  - Advanced usage patterns (error handling, reconnection, custom headers, binary data)
  - Platform-specific implementation details for all supported platforms
  - Troubleshooting guide for common issues
  - Performance optimization tips
  - WebSocket close codes reference (1000-1011)
  - Browser developer tools debugging guide

- **Improved inline code documentation**
  - RFC 6455 WebSocket frame format explanation with ASCII ASCII diagram
  - Detailed parameter documentation with examples
  - Exception and error handling information
  - Platform compatibility notes
  - Resource cleanup best practices

- **Real-world usage examples**
  - Chat application example with login/message handling
  - Stock price updates example with subscriptions
  - IoT device communication example with timestamp tracking

### Improved
- Documentation quality across all platform implementations
- Error handling documentation with practical examples
- Connection state management explanations
- Heartbeat and ping/pong mechanism documentation
- Backpressure and message queuing explanations
- CORS and security considerations for web platform
- Binary message handling documentation
- TLS/SSL certificate validation documentation
- Automatic reconnection exponential backoff explanation

### Changed
- Removed Chinese comments and replaced with English documentation
- Enhanced code example quality and clarity

## [1.1.0] - 2026-05-22

### Added
- Full Web platform support using `package:web`
- Cross-platform WebSocket client architecture (IO + Web)
- Unified abstract interface `WsClient` for all platforms
- `WsClientWeb` implementation for browser environments
- `WsClientIO` implementation for native platforms
- Conditional imports for platform-specific code selection

### Improved
- Optimized project structure for multi-platform publishing
- Enhanced connection state management across all platforms
- Updated documentation with web support notes
- Stream-based API consistency across platforms

### Features
- **Native Platforms** (Android, iOS, macOS, Windows, Linux)
  - Uses `dart:io` Socket and SecureSocket
  - Full TLS/SSL support for `wss://` connections
  - Automatic certificate validation
  - Manual control over auto-reconnection via configuration
  - Custom HTTP headers support for handshake

- **Web Platform** (Browsers)
  - Uses browser native WebSocket API via `package:web`
  - Automatic CORS handling by browser
  - Standards-compliant RFC 6455 implementation
  - Identical API across all platforms

### Event Streams
- `onOpen` - Connection successfully established
- `onClose` - Connection closed or lost
- `onMessage` - Incoming messages (text or binary)
- `onError` - Error events during connection lifecycle
- `onState` - Connection state changes (connecting, open, closing, closed)

### Message Types
- Text messages via `send(String)`
- JSON messages via `sendJson(Map<String, dynamic>)`
- Binary data support on native platforms
- Automatic message fragmentation handling

### Auto-Reconnection Features
- Exponential backoff strategy (1s, 2s, 4s, 8s, 16s, ...)
- Configurable maximum retry attempts (default: 10)
- Automatic retry after unexpected connection loss
- Manual control via `autoReconnect` parameter

### Heartbeat Mechanism
- Automatic ping every 10 seconds
- 5-second pong response timeout
- Dead connection detection and reconnection
- Configurable via low-level `RxWs` class

### Connection States
- `WSState.closed` - Initial and final state (no connection)
- `WSState.connecting` - Connection attempt in progress (handshake)
- `WSState.open` - Connected and ready for communication
- `WSState.closing` - Graceful close in progress

## [1.0.1] - 2026-05-20

### Fixed
- Fixed demo code and example usage
- Minor documentation improvements

### Improved
- Code examples clarity

## [1.0.0] - 2026-05-20

### Added
- Full support for TLS connections via `SecureSocket`
- Complete WebSocket frame parsing and building (including masking per RFC 6455)
- Fragmentation (continuation frames) support for large messages
- Automatic Ping/Pong heartbeat mechanism (every 10 seconds)
- Pong timeout detection with automatic reconnection trigger
- Exponential backoff reconnect strategy (up to 10 retries)
- Cross-platform support (IO for native, Web for browsers)
- Stream-based API for async message handling
- Backpressure support for reliable message queuing
- State management with `WSState` enum

### Improved
- Strict `Sec-WebSocket-Accept` validation during handshake
- Fixed residual frame loss after successful handshake completion
- Optimized `_parseFrames()` using offset instead of frequent `sublist`
- Thorough resource cleanup on reconnect to prevent memory leaks
- More robust handshake response parsing

### Fixed
- Bug where the first WebSocket frame after handshake could be lost
- Buffer management issues leading to parsing errors
- Resource leaks during reconnection cycles

### Changed
- Introduced `_cleanup()` method for consistent resource management
- Enhanced internal state management
- Improved socket resource handling

## Upgrade Guide

### From 1.0.x to 1.1.x

No breaking changes. The API remains fully backward compatible.

**New features to leverage:**
- Use the enhanced documentation for better understanding of features
- Refer to README examples for common use cases
- Check platform-specific documentation for optimization opportunities
- Review the new real-world examples (chat, stocks, IoT)

## Known Issues

### None reported

Please report any issues at: https://github.com/msfm2018/rxws/issues

## Deprecated Features

None at this time.

## Security

### Security Considerations

- **TLS/SSL**: Always use `wss://` for secure connections in production
- **Certificate Validation**: Automatic on all native platforms
- **Input Validation**: Validate all received messages in your application
- **Authentication**: Pass authentication tokens via custom headers (native) or message content
- **CORS**: For web platform, ensure proper CORS headers on server

For security vulnerabilities, please email the maintainers directly rather than using the issue tracker.

## Roadmap

### Planned Features
- [ ] Built-in message compression support (RFC 7692)
- [ ] Structured logging system for debugging
- [ ] Performance metrics collection
- [ ] Connection pooling support for multiple servers
- [ ] Middleware/interceptor support for message processing

### Under Consideration
- Support for WebSocket extensions (RFC 7692)
- Built-in reconnection strategies (customizable patterns)
- Message queuing for offline scenarios
- Automatic message batching optimization

## Testing

- Unit tests covering core WebSocket protocol
- Platform-specific integration tests
- Real server connectivity tests

Run tests with: `flutter test` or `dart test`

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Compatibility

### Supported Platforms
- ✅ Android (API level 21+)
- ✅ iOS (11.0+)
- ✅ macOS (10.12+)
- ✅ Windows (10+)
- ✅ Linux (glibc 2.28+)
- ✅ Web (Chrome 43+, Firefox 11+, Safari 7+, Edge 12+)

### Dart Versions
- ✅ Dart 3.0.6 and above
- ✅ Dart 3.1.x
- ✅ Dart 3.2.x (latest stable)

### Flutter Versions
- ✅ Flutter 1.17.0 and above
- ✅ All Flutter stable releases

## License

This project is licensed under the [MIT License](LICENSE).

## Resources

- [GitHub Repository](https://github.com/msfm2018/rxws)
- [Pub.dev Package](https://pub.dev/packages/rxws)
- [Issue Tracker](https://github.com/msfm2018/rxws/issues)
- [WebSocket Protocol (RFC 6455)](https://tools.ietf.org/html/rfc6455)
- [WebSocket Extensions (RFC 7692)](https://tools.ietf.org/html/rfc7692)

## Credits

- Dart/Flutter team for excellent async/await support
- WebSocket protocol (RFC 6455) for the standard specification
- Community contributors and users for valuable feedback and issue reports

---

**Note**: For detailed API documentation, visit the [README.md](README.md) or check inline code documentation via DartDoc.
