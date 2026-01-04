# Ariami CLI Server Management

This guide covers how to start, stop, and manage your Ariami music server on Windows.


cd to D:\workshop\New folder\Ariami\ariami_cli

 **`start_server.bat`** - Double-click to start the server
- **`stop_server.bat`** - Double-click to stop the server  
- **`check_status.bat`** - Double-click to check server status

## Important Setup Note

If you get "dart is not recognized" errors when running commands, you need to set up Flutter/Dart in your PATH first. See the [Flutter PATH Setup](#flutter-path-setup) section below.

## Quick Commands

### Start Server
```powershell
dart run bin/ariami_cli.dart start
```
### Start server (add fluffer to path)
$env:PATH += ";C:\Users\codecarter\Downloads\flutter_windows_3.38.5-stable\flutter\bin"; dart run bin/ariami_cli.dart start


### Stop Server
```powershell
dart run bin/ariami_cli.dart stop
```

### Check Status
```powershell
dart run bin/ariami_cli.dart status
```

## Detailed Instructions

### Starting the Server

**First Time Setup:**
- Server runs in foreground mode for initial configuration
- Web browser opens automatically at http://localhost:8080
- Complete setup by selecting your music folder
- Server automatically transitions to background mode after setup

**Subsequent Starts:**
- Server runs in background mode immediately
- No browser window opens
- Access web interface manually at http://localhost:8080

### Stopping the Server

**Method 1: CLI Command (Recommended)**
```powershell
cd ariami_cli
dart run bin/ariami_cli.dart stop
```
This is the cleanest method as it allows graceful shutdown.

**Method 2: Using Compiled Executable**
```powershell
cd ariami_cli
.\ariami_cli.exe stop
```

**Method 3: Task Manager**
1. Open Task Manager (Ctrl+Shift+Esc)
2. Find the Ariami/Dart process
3. Right-click → End Task

**Method 4: PowerShell Kill Command**
```powershell
# First get the PID from status command
dart run bin/ariami_cli.dart status

# Then kill by PID (replace XXXX with actual PID)
Stop-Process -Id XXXX -Force
```

### Checking Server Status

```powershell
dart run bin/ariami_cli.dart status
```

This shows:
- Server running status
- Process ID (PID)
- Port number
- Setup completion status
- Music library path
- Configuration directory

### Custom Port

To run on a different port:
```powershell
dart run bin/ariami_cli.dart start --port 9000
```

## Server Access

- **Local Access**: http://localhost:8080
- **Network Access**: http://YOUR_IP:8080
- **Tailscale Access**: http://TAILSCALE_IP:8080 (if Tailscale is installed)

## Troubleshooting

### Server Won't Start
1. Check if already running: `dart run bin/ariami_cli.dart status`
2. Ensure web UI is built: `flutter build web -t lib/web/main.dart`
3. Check port availability: Try different port with `--port` flag

### Server Won't Stop
1. Use Task Manager to force-kill the process
2. Check status to confirm it's stopped
3. If PID file is stuck, delete `~/.ariami_cli/ariami.pid`

### Port Already in Use
```powershell
# Check what's using port 8080
netstat -ano | findstr :8080

# Start on different port
dart run bin/ariami_cli.dart start --port 8081
```

## Configuration Files

Server configuration is stored in:
- **Windows**: `C:\Users\USERNAME\.ariami_cli\`
- **Files**: `config.json`, `ariami.pid`

## Mobile App Connection

1. Ensure server is running
2. Open web interface at http://localhost:8080
3. Scan QR code with Ariami mobile app
4. Mobile app connects automatically

## Background Operation

- Server runs as background process after initial setup
- No console window remains open
- Server continues running even after closing terminal
- Use `status` command to verify it's still running
- Server survives system sleep/wake cycles

---

**Note**: This server management guide is specific to the Windows version with the signal handling fix applied.

## Flutter PATH Setup

If you get "dart is not recognized" errors, you need to add Flutter to your system PATH. Here are three solutions:

### Option 1: Add Flutter to System PATH (Permanent Fix - Recommended)

1. **Open System Environment Variables:**
   - Press `Win + R`, type `sysdm.cpl`, press Enter
   - Click "Environment Variables" button
   - In "System Variables" section, find and select "Path"
   - Click "Edit"
   - Click "New"
   - Add: `C:\Users\codecarter\Downloads\flutter_windows_3.38.5-stable\flutter\bin`
   - Click "OK" on all dialogs

2. **Restart PowerShell/Command Prompt** and then you can use normal commands:
   ```powershell
   cd ariami_cli
   dart run bin/ariami_cli.dart start
   ```

### Option 2: Use Batch Files (Quick Fix)

Three batch files have been created for easy server management:

- **`start_server.bat`** - Double-click to start the server
- **`stop_server.bat`** - Double-click to stop the server  
- **`check_status.bat`** - Double-click to check server status

These files automatically handle the PATH setup and work without any additional configuration.

### Option 3: PowerShell Profile Setup

Add Flutter to your PowerShell profile so it's available in every PowerShell session:

```powershell
# Check if profile exists
Test-Path $PROFILE

# Create profile if it doesn't exist
if (!(Test-Path $PROFILE)) { New-Item -Path $PROFILE -Type File -Force }

# Add Flutter to PATH in profile
Add-Content $PROFILE '$env:PATH += ";C:\Users\codecarter\Downloads\flutter_windows_3.38.5-stable\flutter\bin"'
```

After setting up the profile, restart PowerShell and the dart commands will work.

### Option 4: Use Compiled Executable

If you've compiled the executable, you can use it directly without PATH setup:

```powershell
cd ariami_cli
.\ariami_cli.exe start
.\ariami_cli.exe stop
.\ariami_cli.exe status
```

## Troubleshooting PATH Issues

**Problem**: "dart is not recognized as the name of a cmdlet"
**Solutions**:
1. Use Option 1 above (add to system PATH) - most reliable
2. Use the provided batch files - easiest
3. Use the compiled executable - no PATH needed
4. Temporarily set PATH in each PowerShell session:
   ```powershell
   $env:PATH += ";C:\Users\codecarter\Downloads\flutter_windows_3.38.5-stable\flutter\bin"
   ```