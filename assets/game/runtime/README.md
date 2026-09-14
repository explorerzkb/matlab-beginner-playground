# Bundled runtime helpers

This folder contains platform-specific binaries used by the game at runtime.
They are kept with the model and image assets so the offline validation bundle
can include every non-MATLAB dependency from one `assets/game` tree.

`windows/MatlabHiTiming.dll` is built from
`tools/windows/HighResolutionWaiter.cs`. It provides a process-local
high-resolution frame wait on Windows. macOS and other platforms do not load
this assembly and use MATLAB's JVM wait path instead.
