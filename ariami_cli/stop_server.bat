@echo off
cd /d "%~dp0"
set PATH=%PATH%;C:\Users\codecarter\Downloads\flutter_windows_3.38.5-stable\flutter\bin
dart run bin/ariami_cli.dart stop
pause