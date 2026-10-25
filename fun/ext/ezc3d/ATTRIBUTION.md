# ezc3d Attribution

Source: https://github.com/pyomeca/ezc3d
Authors: pyomeca contributors
License: MIT (see LICENSE file)
Version: Release 1.7.2 (tag `Release_1.7.2`, published 2026-08-08)
Release page: https://github.com/pyomeca/ezc3d/releases/tag/Release_1.7.2
Vendored: 2026-10-25

Only the MATLAB reader `ezc3dRead` is included, as the official
unmodified binaries from the release. `ezc3dWrite`, the `.lib` import
libraries and the helper `.m` files are left out because labTools never
writes C3D files. Do not edit these files. All four are self-contained:
they link only MATLAB's own libraries and the system C++ runtime, so
this one flat folder is enough.

## Archives downloaded

| Archive | SHA-256 |
|---|---|
| ezc3d_matlab_win-64.zip | d28eea86d3c91b5e459df77b05e11248d62599edd88519c2eda0213904793e5d |
| ezc3d_matlab_osx-arm64.zip | 1c4fa33caf4ba2c8d0380cfacabe1443a33518d04d681c9bc66abd421dc509af |
| ezc3d_matlab_osx-intel.zip | 6f44c1a2da5e73a4df91887082c83e5b7c85cef1dbacaad3d4ec95e865dbf377 |
| ezc3d_matlab_linux-64.zip | 2aa7483594b768caab4d22dfd1bb41183ba545e2ae4844ffa6d3f41d9c7614d6 |

Download URL pattern:
`https://github.com/pyomeca/ezc3d/releases/download/Release_1.7.2/<archive>`.
Each hash matches the digest GitHub reports for the release asset.

## Files in this folder

| File | Platform (`mexext`) | SHA-256 |
|---|---|---|
| ezc3dRead.mexw64 | Windows 64-bit (`mexw64`) | 5ac13b66b7fb4ea700b13b6ef651ef30b63bc08273c56172f0a1f0ba17c4b51a |
| ezc3dRead.mexmaci64 | macOS Intel (`mexmaci64`) | b358785292f36ada41d61217f807548d4651eb5df80adc099bb3a54a6a05b856 |
| ezc3dRead.mexmaca64 | macOS Apple silicon (`mexmaca64`) | 9057ded8251bb4ea83d23dcfa495c636c0292a0886ed522f778c5a896ebbfaa8 |
| ezc3dRead.mexa64 | Linux 64-bit (`mexa64`) | f554b1279f42b1e110af1f2473a55dfac428ee61e11616257e6f483ef456d95f |
| LICENSE | all | MIT text from the `Release_1.7.2` tag |

Check on Windows with `Get-FileHash -Algorithm SHA256`, or on macOS and
Linux with `shasum -a 256`.

## Verification status

The Windows binary was tested with MATLAB R2024a against BTK 0.3.0 on
21 of 22 lab C3D files (the 22nd, 1 GB, was read without a BTK baseline).
It matches BTK exactly except for the PC2 analog rate (2000 Hz here,
1999.999992 Hz from BTK). The macOS and Linux binaries are the official ones,
untested here until `testing/c3dReader/checkC3DReader.m` is run on those
platforms. MATLAB R2021a was not tested. The Windows binary
imports `VCRUNTIME140_1.dll`, which R2024a ships; older MATLAB releases
may need the current Microsoft Visual C++ Redistributable.

macOS may refuse to load a downloaded MEX file. If so, clear the
quarantine flag: `xattr -dr com.apple.quarantine fun/ext/ezc3d`.

## Rebuild recipe

To rebuild from source, for example for a MATLAB release or platform
without an official binary:

1. `git clone --branch Release_1.7.2 --recursive
   https://github.com/pyomeca/ezc3d.git`
2. Configure with CMake: `-DBINDER_MATLAB=ON -DBUILD_SHARED_LIBS=OFF`
   (`BINDER_MATLAB` is off by default; the shipped MEX files need no
   separate `libezc3d`, which implies a static build). The MATLAB
   discovery options are in the `binding` folder, and the release's CI
   workflow shows the exact flags used for the official binaries.
3. Build with `cmake --build . --config Release`. Use MSVC on Windows,
   Xcode command line tools on macOS (one build per architecture) and
   GCC on Linux.
4. Copy `ezc3dRead.<mexext>` from the build's MATLAB folder into this
   folder and update the hashes above.
