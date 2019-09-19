# X4D LibStub

A WowAce LibStub-compatible Dependency Library that can be used from other modules to provide run-time dependency resolution.

LibStub solves several problems related to writing library modules in a global state:

1. A library module gets loaded every time it is referenced. LibStub allows a module to detect that it has previously loaded and not perform initialization a second time.
2. A newer version of a module is required, but other module are already loading an older version. LibStub allows a module to detect if a previously loaded version is older and optionally replace it with the newer version.

**X4D LibStub** introduces SEMVER to the mix and separates the module "ID" from the module "Version". Although it is possible to package modules with a SEMVER format using the WowAce flavor of LibStub, the version numbers get reduced down to its major component due to internal conversion and SEMVER constraints between libraries weren't actually possible.

## Features

- Does not depend on any other libraries.
- Backward compatible with with the original [WowAce LibStub](http://www.wowace.com/wiki/LibStub) library.
- Supports [SEMVER](https://semver.org/), both library authors and consumers can optionally specify `major.minor.patch` when registering and resolving libraries.

## Differences from WowAce LibStub

Understanding that these differences do not fundamentally change behavior for the existing LibStub-based modules:

- X4D LibStub understands SEMVER constraints, ie. that "1.36.5" satisfies a demand for a "v1.36" library, but not a "1.36.6" library because the patch level is too low. Under classic LibStub behavior a proper version string was reduced down to a non-fractional "major" version (ie. minor/etc would truncate and not be evaluated.)

- Nomenclature is corrected, where LibStub `major` is not actually a "major version" but is a "library id" instead; thus, `major` becomes `id`, and `minor` becomes `version`.

## Planned Features

- `/x4d deps` to output a non-recursive dependency tree

## Usage

-- TODO


## Support, Assistance, and Bug Reports

You can file a bug at <a href="https://github.com/wilson0x4d/X4DESO/issues">GITHUB.COM</a>.

You can send me **in-game mail** (not a /tell) if you prefer. I can be found on NA 
servers as `@wilson0x4d`. Feel free to say hello if you see me wandering 
about. :)


## Donations

I hope you enjoy using my add-ons as much as I enjoy creating them. If you want to show 
your support and donate :D I can always use in-game gold and items, and they're easy 
things to come by.

I am also a firm believer in Bitcoin, so if you really want to put a smile on my face 
send a Bitcoin donation (of ANY amount!) to <b><a href="bitcoin:1PeRYfrygTEo3VuJCQaZL5A43hrssRTNVH">1PeRYfrygTEo3VuJCQaZL5A43hrssRTNVH</a></b>,
you can use a service like <a href="https://www.coinbase.com">Coinbase</a> to purchase 
and send bitcoin if you don't already have a bitcoin wallet.
