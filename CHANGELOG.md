# Changelog
## [1.1.1] - 2026-05-28
### Updated
* Upgraded `flutter_lints` to ^6.0.0 for improved code analysis.

## [1.1.0] - 2026-05-22

### Added
- Added full Web platform support using `package:web`
- Cross-platform WebSocket client architecture (IO + Web)
- Unified abstract interface `WsClient` for all platforms

### Improved
- Optimized project structure for multi-platform publishing
- Enhanced connection state management across all platforms
- Updated documentation with web support notes

## [1.0.1] - 2026-05-20

### Fixed
- Fixed demo code and example usage
- Minor documentation improvements

## [1.0.0] - 2026-05-20

### Added
- Full support for TLS connections via `SecureSocket`
- Complete WebSocket frame parsing and building (including masking)
- Fragmentation (continuation frames) support
- Automatic Ping/Pong heartbeat (every 10 seconds)
- Pong timeout detection with automatic reconnection
- Exponential backoff reconnect strategy (up to 10 retries)
- Cross-platform support (IO + Web)

### Improved
- Strict `Sec-WebSocket-Accept` validation during handshake
- Fixed residual frame loss after successful handshake
- Optimized `_parseFrames()` using offset instead of frequent `sublist`
- Thorough resource cleanup on reconnect
- More robust handshake response parsing

### Fixed
- Bug where the first WebSocket frame after handshake could be lost
- Buffer management issues leading to parsing errors
- Resource leaks during reconnection

### Changed
- Introduced `_cleanup()` method for consistent resource management
- Enhanced internal state management