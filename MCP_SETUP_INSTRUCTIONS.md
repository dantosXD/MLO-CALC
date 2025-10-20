# Dart MCP Server Setup for Claude Code

## Prerequisites
1. **Dart SDK 3.9.0-163.0.dev or later** must be installed
2. **Flutter SDK** (includes Dart) - Download from https://flutter.dev/docs/get-started/install

## Step 1: Install Flutter/Dart SDK
If you haven't already, download and install Flutter:
- Windows: https://docs.flutter.dev/get-started/install/windows
- After installation, verify with: `flutter doctor`

## Step 2: Configure Dart MCP Server for Claude Code

Claude Code uses MCP configuration files. Add the Dart MCP server by creating/editing the configuration:

### Configuration File Location
Claude Code typically uses one of these locations:
- `~/.config/claude-code/mcp.json` (Linux/Mac)
- `%APPDATA%\claude-code\mcp.json` (Windows)
- Project-specific: `.claude-code/mcp.json`

### Configuration Content
Add this to your MCP configuration file:

```json
{
  "mcpServers": {
    "dart": {
      "command": "dart",
      "args": [
        "mcp-server",
        "--experimental-mcp-server"
      ],
      "env": {}
    }
  }
}
```

### For Windows with Flutter Installation
If Flutter is installed, you can also use:

```json
{
  "mcpServers": {
    "dart": {
      "command": "C:\\path\\to\\flutter\\bin\\cache\\dart-sdk\\bin\\dart.exe",
      "args": [
        "mcp-server",
        "--experimental-mcp-server"
      ]
    }
  }
}
```

Replace `C:\\path\\to\\flutter` with your actual Flutter installation path (usually `C:\\Users\\YourName\\flutter`).

## Step 3: Restart Claude Code
After configuration, restart Claude Code to load the new MCP server.

## Step 4: Verify Installation
The Dart MCP server provides these tools:
- **Project Analysis**: Code analysis and diagnostics
- **Code Formatting**: Dart code formatting
- **Flutter App Launching**: Run Flutter apps
- **Hot Reload/Restart**: Fast development iteration
- **Widget Inspection**: Flutter widget tree analysis
- **Test Execution**: Run Dart/Flutter tests

## Troubleshooting
- If Dart is not found, add Flutter's `bin` directory to your PATH
- Use `--force-roots-fallback` flag if your MCP client has Roots support issues
- Check Claude Code logs for MCP server connection errors
