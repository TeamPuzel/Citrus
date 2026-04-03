# Citrus

A work in progress Swift framework and template for use with the DevkitPro 3DS homebrew toolchain.

## Dependencies

You need the following dependencies:
- The absolute latest Swift development toolchain to be visible in your PATH.
- Make to build the program and run utility commands.
- DevkitPro and the proper environment variables (DEVKITPRO) for the makefile to find the tools and libraries.
- Makerom to create installable app bundles.
- 3dsxtool to make raw executable files.
- Bannertool to compile bundle assets like app icon.
- 3dslink (optional) for an instant push-based iteration cycle on real hardware integrated with the homebrew launcher.
- Caddy (optional) to serve the build directory for 3DS FBI to install your app over the network.
- Azahar (optional) to install run or debug games locally on the emulator.
- A 3DS (optional) to install run or debug games remotely on real hardware.

## Commands

Some useful make commands include:
- `configure` to prepare the build folder.
- `commands` to generate compile_commands.json and get sourcekit-lsp working.
- `clean` to remove build state.
- `install` to install the game in the Azahar emulator.
- `run` to run the game with the Azahar emulator.
- `link` to push and run the game to the homebrew menu (press Y in the homebrew menu).
- `serve` to serve the build directory for FBI installation.
- `push` to push to the served app bundle URL to FBI (the remote install URL feature).
- `debug-remote` to run and try attach the DevkitPro gdb to the 3DS, this requires enabling the debugger in Rosalina.
