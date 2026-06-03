# Contributing to rxws

Thank you for your interest in contributing to rxws! We welcome contributions from the community. This document provides guidelines and instructions for contributing.

## Code of Conduct

We are committed to providing a welcoming and inspiring community for all. Please read and follow our code of conduct:

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on what is best for the community
- Show empathy towards other community members

## How to Contribute

### Reporting Bugs

Before creating a bug report, please check the [issue tracker](https://github.com/msfm2018/rxws/issues) as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

1. **Use a clear and descriptive title**
2. **Describe the exact steps which reproduce the problem**
3. **Provide specific examples to demonstrate the steps**
4. **Describe the behavior you observed after following the steps**
5. **Explain which behavior you expected to see instead and why**
6. **Include screenshots and animated GIFs if possible**
7. **Include your environment details**:
   - Operating System and version
   - Dart version (`dart --version`)
   - Flutter version (`flutter --version`)
   - Platform(s) affected (Android, iOS, macOS, Windows, Linux, Web)

### Requesting Features

Feature requests are welcome! Please include:

1. **Clear and descriptive title**
2. **Detailed description of the requested feature**
3. **Use case and motivation**
4. **Possible implementation approaches (if any)**
5. **Examples of how the feature would be used**

### Pull Requests

When submitting a pull request:

1. **Fork the repository** and create your branch from `main`
2. **Follow the code style** used in the project
3. **Write clear, descriptive commit messages**
4. **Include comments in your code** where appropriate
5. **Update documentation** if you're changing functionality
6. **Add tests** for new functionality
7. **Ensure all tests pass** before submitting

#### Pull Request Process

1. Update the CHANGELOG.md with notes on your changes
2. Ensure your code follows the project's code style
3. Test thoroughly on all supported platforms if possible
4. Request review from maintainers
5. Address any feedback or requested changes

## Development Setup

### Prerequisites

- Dart SDK 3.0.6 or higher
- Flutter SDK 1.17.0 or higher (for Flutter development)
- Git

### Local Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/msfm2018/rxws.git
   cd rxws
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run tests**
   ```bash
   flutter test
   ```

4. **Analyze code**
   ```bash
   flutter analyze
   ```

### Project Structure

```
rxws/
├── lib/
│   ├── rxws.dart                 # Main export file
│   └── src/
│       ├── ws_client.dart        # Abstract interface
│       ├── ws_client_factory.dart # Platform detection
│       ├── ws_client_io.dart     # Native implementation
│       ├── ws_client_web.dart    # Web implementation
│       ├── ws_client_stub.dart   # Fallback stub
│       └── rx_ws.dart            # Core implementation
├── example/                       # Example applications
├── test/                         # Unit and integration tests
├── pubspec.yaml                  # Project configuration
├── CHANGELOG.md                  # Version history
├── README.md                     # Documentation
└── LICENSE                       # License file
```

## Code Style

### Dart Style Guide

We follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style). Key points:

1. **Use 2-space indentation**
2. **Use `camelCase` for variables and methods**
3. **Use `PascalCase` for classes**
4. **Use `snake_case` for filenames**
5. **Keep lines under 80 characters** where practical
6. **Use meaningful variable and function names**

### Documentation

1. **Document all public classes and methods** with `///` comments
2. **Include examples** in documentation where helpful
3. **Explain the purpose and usage** of complex algorithms
4. **Document parameters, return values, and exceptions**

Example:
```dart
/// Sends a text message to the WebSocket server.
/// 
/// The message must be a valid UTF-8 string. This method should only be called
/// after a successful connection ([onOpen] has been emitted).
/// 
/// Example:
/// ```dart
/// client.send('Hello Server');
/// ```
void send(String data) {
  _ws.sendText(data);
}
```

## Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/ws_client_test.dart

# Run with coverage
flutter test --coverage
```

### Writing Tests

1. **Test file naming**: Use `*_test.dart` suffix
2. **Organize tests**: Group related tests using `group()`
3. **Clear test names**: Use descriptive test names
4. **Test both success and failure cases**
5. **Mock dependencies** where appropriate

Example:
```dart
void main() {
  group('WsClient', () {
    test('should connect successfully', () async {
      final client = createWsClient();
      expect(client, isNotNull);
      // Test connection logic
    });

    test('should handle connection errors', () async {
      final client = createWsClient();
      // Test error handling
    });
  });
}
```

## Commit Guidelines

### Commit Message Format

Use clear, descriptive commit messages:

```
<type>: <subject>

<body>

<footer>
```

### Types

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that don't affect code meaning (formatting, etc.)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Code change that improves performance
- `test`: Adding or updating tests
- `chore`: Changes to build process or dependencies

### Examples

```
feat: add support for custom WebSocket headers

This allows users to pass custom HTTP headers during the WebSocket
upgrade handshake, enabling authentication mechanisms.

Closes #123
```

```
fix: prevent frame loss after handshake

The buffer was not properly managed after successful handshake,
causing the first frame to be lost.

Fixes #456
```

## Documentation Contributions

Documentation improvements are always welcome!

1. **Update README.md** for user-facing features
2. **Update CHANGELOG.md** for version changes
3. **Add inline documentation** for complex code
4. **Improve existing documentation** if unclear

## Platform-Specific Development

### Native Platforms (Android, iOS, macOS, Windows, Linux)

When working on native platform code:

1. Test on actual devices when possible
2. Consider platform-specific limitations
3. Use `dart:io` APIs appropriately
4. Document platform-specific behavior

### Web Platform

When working on web platform code:

1. Test in multiple browsers
2. Consider browser security restrictions
3. Test CORS scenarios
4. Document browser-specific behavior

## Performance Considerations

When contributing code:

1. Avoid unnecessary allocations
2. Use efficient data structures
3. Consider memory usage
4. Profile performance-critical code
5. Document performance assumptions

## Security Considerations

- Be cautious with network code
- Validate all inputs
- Use TLS/SSL for secure connections
- Follow cryptography best practices
- Report security issues responsibly

## Release Process

The maintainers follow this process for releases:

1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md`
3. Merge to `main` branch
4. Tag the release: `git tag v1.x.x`
5. Publish to pub.dev: `flutter pub publish`

## Getting Help

- **GitHub Issues**: For bug reports and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Documentation**: Check README.md and inline code docs first

## Community

Join our community:
- [GitHub Issues](https://github.com/msfm2018/rxws/issues)
- [GitHub Discussions](https://github.com/msfm2018/rxws/discussions)

## Attribution

Contributors will be recognized in the CHANGELOG and project documentation.

## Legal

By contributing to rxws, you agree that:

1. Your contributions will be licensed under the MIT License
2. You have the right to grant this license
3. You represent that your contribution is your original creation

## Frequently Asked Questions

### Q: How do I get started?
A: Start with the [Local Setup](#local-setup) section above, then pick an issue labeled `good first issue`.

### Q: How long does PR review take?
A: We aim to review PRs within a few days, but it may take longer depending on complexity.

### Q: Can I work on multiple platforms?
A: Yes! We particularly welcome cross-platform testing and contributions.

### Q: What if my PR is rejected?
A: Don't be discouraged! We provide feedback to help improve your contribution. You're welcome to revise and resubmit.

### Q: How are decisions made?
A: Major decisions are discussed in GitHub issues and discussions. We value community input.

## References

- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Dart Documentation](https://dart.dev/guides)
- [Flutter Documentation](https://flutter.dev/docs)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
- [WebSocket Protocol (RFC 6455)](https://tools.ietf.org/html/rfc6455)

## Questions?

Feel free to ask questions in GitHub Issues or Discussions. We're here to help!

---

Thank you for contributing to rxws! 🎉
