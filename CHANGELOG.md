## [0.3.3](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.3.2...v0.3.3) (2026-06-10)


### Bug Fixes

* **stdlib:** preserve Map abstract conversions ([6883568](https://github.com/fullofcaffeine/reflaxe.elixir/commit/6883568f1b1a340dae86611d59fee204529e802d))

## [0.3.2](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.3.1...v0.3.2) (2026-06-10)


### Bug Fixes

* **stdlib:** reject ObjectMap identity semantics ([fd8ae53](https://github.com/fullofcaffeine/reflaxe.elixir/commit/fd8ae53a763428e6ad0d3214edd622846b93b54f))

## [0.3.1](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.3.0...v0.3.1) (2026-06-10)


### Bug Fixes

* **stdlib:** lock native map iterator semantics ([017d229](https://github.com/fullofcaffeine/reflaxe.elixir/commit/017d229083211282c73ab0cc48b9d43c4f32b823))

# [0.3.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.2.1...v0.3.0) (2026-06-10)


### Features

* **stdlib:** add canonical IMap unwrap runtime ([67ab169](https://github.com/fullofcaffeine/reflaxe.elixir/commit/67ab169f73cbda56c6b8190c4764d50589eb4443))

## [0.2.1](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.2.0...v0.2.1) (2026-03-07)


### Bug Fixes

* **ci:** harden mix runtime deps and generator smoke ([4562d10](https://github.com/fullofcaffeine/reflaxe.elixir/commit/4562d1036404e61d43879a2a3e3be62c5faebdf7))

# [0.2.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.1.0...v0.2.0) (2026-02-19)


### Bug Fixes

* **ci:** repair release workflow parsing and gating ([948d69e](https://github.com/fullofcaffeine/reflaxe.elixir/commit/948d69e68dc547c1453dcc13095d52ca85923dc2))
* **dogfood:** handle single-tag baselines after reset ([efb503f](https://github.com/fullofcaffeine/reflaxe.elixir/commit/efb503f5e0d0eafdfbb7f7224175e2870bded02b))
* **examples:** add ex13 handwritten Elixir interop sample ([f63f07a](https://github.com/fullofcaffeine/reflaxe.elixir/commit/f63f07aeca7919d43003ef1ea6a98a3533187c8c))
* **examples:** track scoped haxe_libraries for CI compile-check ([2b9ebc1](https://github.com/fullofcaffeine/reflaxe.elixir/commit/2b9ebc11ced59205e36def22653a8a90b74433b3))
* **guards:** support --next HXX mode in example build alias ([f34d355](https://github.com/fullofcaffeine/reflaxe.elixir/commit/f34d355c148ff7e737c5054a4f9391b3d863f30c))
* **release:** add conventionalcommits preset dependency ([e10107a](https://github.com/fullofcaffeine/reflaxe.elixir/commit/e10107a081648be457caf9b7782539a538919474))


### Features

* **phoenix:** add socket-first assign helpers ([1ce6508](https://github.com/fullofcaffeine/reflaxe.elixir/commit/1ce65085e11083ae48ff7837acc1e2601d8f880b))
* **router:** optional live route action + haxe-first chat guide/example ([90c15bf](https://github.com/fullofcaffeine/reflaxe.elixir/commit/90c15bfcad17ffa9a1234c8373e6c9c4a6c9cd0c))
* tighten typed Phoenix DSL APIs and refresh docs/examples ([14d8e23](https://github.com/fullofcaffeine/reflaxe.elixir/commit/14d8e2323c68d3e0c0340fba0f42420da9d6f50b))

# Changelog

All notable changes to Reflaxe.Elixir are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-18

### Baseline Release

- Reset release history after repository history cleanup.
- Established `v0.1.0` as the new semantic-release baseline tag on current `main`.
- Future release notes continue from this baseline.

[0.1.0]: https://github.com/fullofcaffeine/reflaxe.elixir/releases/tag/v0.1.0
