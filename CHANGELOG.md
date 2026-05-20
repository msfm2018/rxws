# Changelog

## [Unreleased]

### Added
- Full support for TLS connections via `SecureSocket`
- Complete WebSocket frame parsing and building (including masking)
- Fragmentation (continuation frames) support
- Automatic Ping/Pong heartbeat (every 10 seconds)
- Pong timeout detection with automatic reconnection
- Exponential backoff reconnect strategy (up to 10 retries)

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
- Enhanced logging for better debugging

---

## [1.0.1] - 2026-05-20
* fixed demo

## [1.0.0] - 2026-05-20
* Initial release of `RxWs`