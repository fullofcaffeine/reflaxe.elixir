## Unreleased

### Changed

* **reflaxe:** align stdlib override sources with the Reflaxe `_std` layout; source-tree and GitHub/Lix builds now load `std/elixir/_std` before target-owned `std` APIs so PhoenixHx/examples keep using the Elixir stdlib overrides in dev mode.
* **reflaxe:** move remaining upstream-colliding `std/haxe/**` replacement modules into `std/elixir/_std`, leaving plain `std/haxe/**` for target-owned support surfaces.
* **reflaxe:** align package entrypoint HXML files with Reflaxe-generated targets by applying package-scoped `nullSafety("reflaxe.elixir")` before bootstrap/init macros.
* **reflaxe:** enforce the source-tree `.cross.hx` convention so the only checked-in `src/**/*.cross.hx` file remains the documented early `haxe.Exception` override.
* **reflaxe:** audit vendored framework patches against upstream Reflaxe and document which local fixes remain required before they can be removed or upstreamed.
* **reflaxe:** remove debug-only vendored framework drift while preserving required local Reflaxe patches.
* **docs:** clarify the remaining early `src/haxe/**` overrides, including why `src/haxe/Exception.cross.hx` intentionally remains the lone source-tree `.cross.hx` file.
* **docs:** update stdlib parity task templates to use the current `_std` / target-owned `std/**` / early `src/haxe/**` ownership model.

## [0.14.20](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.19...v0.14.20) (2026-07-09)


### Bug Fixes

* **ci:** use pinned Haxe for package smoke ([d5299f4](https://github.com/fullofcaffeine/reflaxe.elixir/commit/d5299f4eb0d86c903aa4e33923886219ba8f65ce))

## [0.14.19](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.18...v0.14.19) (2026-07-09)


### Bug Fixes

* **stdlib:** enable String runtime parity ([ba39d06](https://github.com/fullofcaffeine/reflaxe.elixir/commit/ba39d06687c6e5795e13dba544a7af7eb402167e))

## [0.14.18](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.17...v0.14.18) (2026-07-07)


### Bug Fixes

* **stdlib:** enable Date runtime parity ([3fe835a](https://github.com/fullofcaffeine/reflaxe.elixir/commit/3fe835a2bba03828f8cd622ea9a955e24e848660))

## [0.14.17](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.16...v0.14.17) (2026-07-07)


### Bug Fixes

* **compiler:** preserve returns in reducer loops ([ed55f98](https://github.com/fullofcaffeine/reflaxe.elixir/commit/ed55f98d66b14fbcdcb47ded7fdf11e3eca041e0))

## [0.14.16](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.15...v0.14.16) (2026-07-07)


### Bug Fixes

* **stdlib:** preserve option all none semantics ([30d5d3b](https://github.com/fullofcaffeine/reflaxe.elixir/commit/30d5d3b9a1631258f5b637ef7d6023914a8190e0))

## [0.14.15](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.14...v0.14.15) (2026-07-07)


### Bug Fixes

* **stdlib:** reject haxe main loop on elixir ([8ed620c](https://github.com/fullofcaffeine/reflaxe.elixir/commit/8ed620c5cc5147bafd7da72b96f084776f667872))

## [0.14.14](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.13...v0.14.14) (2026-07-07)


### Bug Fixes

* **compiler:** support typed enum helper reflection ([2cb5d93](https://github.com/fullofcaffeine/reflaxe.elixir/commit/2cb5d93cb589d81a3de05c7ffd51244a3d7cc4e8))

## [0.14.13](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.12...v0.14.13) (2026-07-07)


### Bug Fixes

* **stdlib:** reject haxe entry point on elixir ([37e6191](https://github.com/fullofcaffeine/reflaxe.elixir/commit/37e6191344661785583d04091a62d2f3ae6f99bc))

## [0.14.12](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.11...v0.14.12) (2026-07-07)


### Bug Fixes

* **perf:** watch todo shared contracts ([8c6ef49](https://github.com/fullofcaffeine/reflaxe.elixir/commit/8c6ef49963d6be5de23b4ba80306b3e2a53cfb4c))

## [0.14.11](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.10...v0.14.11) (2026-07-04)


### Bug Fixes

* **stdlib:** support haxe ds vector ([00fc40b](https://github.com/fullofcaffeine/reflaxe.elixir/commit/00fc40b61922236552ff4a08c4a10f9ee2b6e258))

## [0.14.10](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.9...v0.14.10) (2026-07-04)


### Bug Fixes

* **stdlib:** support haxe format json parser ([ad04b38](https://github.com/fullofcaffeine/reflaxe.elixir/commit/ad04b385a676ba9cc6c9fa5911248b1fbc6a1f49))

## [0.14.9](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.8...v0.14.9) (2026-07-04)


### Bug Fixes

* **stdlib:** make timer delay one-shot deterministic ([76619a1](https://github.com/fullofcaffeine/reflaxe.elixir/commit/76619a1e75e16881de3143fae47d5b56af1a91b7))
* **stdlib:** support haxe ds list ([53893c9](https://github.com/fullofcaffeine/reflaxe.elixir/commit/53893c9fa6eae5a5a4ae6643ab009f6aef1ee359))

## [0.14.8](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.7...v0.14.8) (2026-07-04)


### Bug Fixes

* **stdlib:** support string iterators ([5be6482](https://github.com/fullofcaffeine/reflaxe.elixir/commit/5be6482d2084de3262b797c13b66d4364903b717))

## [0.14.7](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.6...v0.14.7) (2026-07-04)


### Bug Fixes

* **stdlib:** support HashMap key value iterator ([5aa9b10](https://github.com/fullofcaffeine/reflaxe.elixir/commit/5aa9b10609e3185e022cdd1a02b1c7d1abb5bcd6))

## [0.14.6](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.5...v0.14.6) (2026-07-04)


### Bug Fixes

* **stdlib:** support haxe.ds HashMap ([0fc1beb](https://github.com/fullofcaffeine/reflaxe.elixir/commit/0fc1beb357211fb1fce4fe515df73c6567c0e198))

## [0.14.5](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.4...v0.14.5) (2026-07-04)


### Bug Fixes

* **stdlib:** support haxe.ds GenericStack ([2d80729](https://github.com/fullofcaffeine/reflaxe.elixir/commit/2d8072920b6f1d9d364d84d797a94367a26ad8ee))

## [0.14.4](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.3...v0.14.4) (2026-07-04)


### Bug Fixes

* **stdlib:** classify haxe.ds sorting helpers ([fd4d960](https://github.com/fullofcaffeine/reflaxe.elixir/commit/fd4d96013c5c6d8e4f91546115e9be0d337a3793))

## [0.14.3](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.2...v0.14.3) (2026-07-04)


### Bug Fixes

* **stdlib:** cover fallback haxe exceptions ([e369fb3](https://github.com/fullofcaffeine/reflaxe.elixir/commit/e369fb3af3e980b5ab31fcd61894f831b76c2c98))

## [0.14.2](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.1...v0.14.2) (2026-07-04)


### Bug Fixes

* **stdlib:** implement haxe Timer runtime ([332ab16](https://github.com/fullofcaffeine/reflaxe.elixir/commit/332ab16f2eccaa73cd84f29fa2a5374ed9599e79))

## [0.14.1](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.0...v0.14.1) (2026-07-03)


### Bug Fixes

* **compiler:** collapse nil-default iife helpers ([4cbcd31](https://github.com/fullofcaffeine/reflaxe.elixir/commit/4cbcd313cfd13cbb40c5103ae78237921beb5a3f))
* **compiler:** simplify embedded nil-default helpers ([15c1d6e](https://github.com/fullofcaffeine/reflaxe.elixir/commit/15c1d6e6bc38182560207f98dff58ae6d59505e7))
* **stdlib:** consolidate target std overrides ([8fc5cb9](https://github.com/fullofcaffeine/reflaxe.elixir/commit/8fc5cb947e6b067ac9cc6f9abcd6f5e0bbedda71))

# [0.14.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.13.0...v0.14.0) (2026-07-02)


### Features

* **stdlib:** add haxe.crypto.Sha224 parity ([d4b0344](https://github.com/fullofcaffeine/reflaxe.elixir/commit/d4b0344b217663540d9edf87cbc7f23a53d81f81))

# [0.13.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.12.2...v0.13.0) (2026-07-02)


### Features

* **stdlib:** add haxe.crypto.Sha256 parity ([eeb24a5](https://github.com/fullofcaffeine/reflaxe.elixir/commit/eeb24a5ee0a77d4744ba4eb703dbcd29aaac136e))

## [0.12.2](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.12.1...v0.12.2) (2026-07-01)


### Bug Fixes

* **codegen:** drop wildcard literal discards ([1a343be](https://github.com/fullofcaffeine/reflaxe.elixir/commit/1a343be0772773fd488748ae940c974d1bedbb57))

## [0.12.1](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.12.0...v0.12.1) (2026-07-01)


### Bug Fixes

* **todo-app:** decode boundary bools without casts ([a767142](https://github.com/fullofcaffeine/reflaxe.elixir/commit/a76714298395bc41bbda88f91f20a826409fe013))

# [0.12.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.11.0...v0.12.0) (2026-06-29)


### Features

* **phoenix:** lower live event protocols natively ([5157af9](https://github.com/fullofcaffeine/reflaxe.elixir/commit/5157af95543a44d7f453213e7a7865a23aab5a4d))

# [0.11.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.10.2...v0.11.0) (2026-06-19)


### Bug Fixes

* lower discarded mutations without stale values ([233a6c8](https://github.com/fullofcaffeine/reflaxe.elixir/commit/233a6c8e0bd75a079d2c33e9cb6ccfcb81aaa983))


### Features

* advance stdlib parity and typed API surfaces ([9c9a5e5](https://github.com/fullofcaffeine/reflaxe.elixir/commit/9c9a5e57a638ae120a85693d05e8013f088f4cd6))

## Unreleased

### Features

* **stdlib:** support Haxe Float NaN/Infinity semantics on BEAM, including
  Math, operators, IEEE bytes, JSON, serialization, templates, and runtime
  boundary diagnostics.

## [0.10.2](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.10.1...v0.10.2) (2026-06-18)


### Bug Fixes

* legalize receiver effects before iife lowering ([6734c8a](https://github.com/fullofcaffeine/reflaxe.elixir/commit/6734c8a7dd90e03c8b912baca7e7e342a6ad8c42))

## [0.10.1](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.10.0...v0.10.1) (2026-06-16)


### Bug Fixes

* thread persistent receiver state ([e8091c4](https://github.com/fullofcaffeine/reflaxe.elixir/commit/e8091c4cc7075c3c3cd7bc7a65cc82f5df9b0f7a))

# [0.10.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.9.5...v0.10.0) (2026-06-15)


### Features

* add haxe io string input ([a6d6136](https://github.com/fullofcaffeine/reflaxe.elixir/commit/a6d6136032b4587f5751fa339151ca1b4dd2619b))

## [0.9.5](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.9.4...v0.9.5) (2026-06-15)


### Performance Improvements

* add example compile benchmark ([54d5283](https://github.com/fullofcaffeine/reflaxe.elixir/commit/54d5283becac3e2f73ef36a7bd4bc2e391257547))

## [0.9.4](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.9.3...v0.9.4) (2026-06-15)


### Performance Improvements

* add todo watch benchmark ([51555ff](https://github.com/fullofcaffeine/reflaxe.elixir/commit/51555ff0deb33c12f38ff6488cda2b9ac3de4215))

## [0.9.3](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.9.2...v0.9.3) (2026-06-15)


### Performance Improvements

* add haxe compile phase timings ([e4e4284](https://github.com/fullofcaffeine/reflaxe.elixir/commit/e4e42842e6a37a7126ac08423695ac1c005e38b1))

## [0.9.2](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.9.1...v0.9.2) (2026-06-15)


### Performance Improvements

* add todo compile benchmark ([808ecac](https://github.com/fullofcaffeine/reflaxe.elixir/commit/808ecac75a5aa5f8b57700d721126cba1302ff8d))

## [0.9.1](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.9.0...v0.9.1) (2026-06-15)


### Bug Fixes

* preserve unrelated list indexing in reducers ([f555878](https://github.com/fullofcaffeine/reflaxe.elixir/commit/f5558781a3bb4d1cfd964fac0037332d5b669186))

# [0.9.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.8.0...v0.9.0) (2026-06-15)


### Features

* **interop:** scaffold app-local extern boundaries ([ed2f4e6](https://github.com/fullofcaffeine/reflaxe.elixir/commit/ed2f4e66f42b72ff10e0269bc9365d03a1895bb0))

# [0.8.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.7.0...v0.8.0) (2026-06-15)


### Features

* **ecto:** add typed changeset field tokens ([cb65945](https://github.com/fullofcaffeine/reflaxe.elixir/commit/cb6594561617b2b52a82d4663af1545734bbdd3d))

# [0.7.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.6.0...v0.7.0) (2026-06-15)


### Features

* normalize LiveView callback names ([a465916](https://github.com/fullofcaffeine/reflaxe.elixir/commit/a465916442727487df561a310c4e3fc309d222e6))

# [0.6.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.5.3...v0.6.0) (2026-06-15)


### Features

* add checked Ecto field selectors ([47fef59](https://github.com/fullofcaffeine/reflaxe.elixir/commit/47fef59fd30216544d568141482ddd7a0af0434b))

## [0.5.3](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.5.2...v0.5.3) (2026-06-13)


### Bug Fixes

* **generator:** guard strict hxx scaffolds ([534d4a5](https://github.com/fullofcaffeine/reflaxe.elixir/commit/534d4a5c9538d311bb435ae0ee15d580831d84e0))

## [0.5.2](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.5.1...v0.5.2) (2026-06-13)


### Bug Fixes

* **ast:** rewrite known string length before printing ([8a9a5d2](https://github.com/fullofcaffeine/reflaxe.elixir/commit/8a9a5d295b96b6788ff5cca2fcb42424120dab03))

## [0.5.1](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.5.0...v0.5.1) (2026-06-12)


### Bug Fixes

* **stdlib:** keep bytes compare out of guards ([692d60d](https://github.com/fullofcaffeine/reflaxe.elixir/commit/692d60d92e8fe9c95acf4f629f01309dac3af3ba))

# [0.5.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.4.0...v0.5.0) (2026-06-12)


### Features

* **stdlib:** implement haxe http on beam ([2a69ffd](https://github.com/fullofcaffeine/reflaxe.elixir/commit/2a69ffd41c076aadb44e02f831557919144e2783))

# [0.4.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.3.3...v0.4.0) (2026-06-11)


### Bug Fixes

* **docs:** refresh stdlib parity counters ([7de7f57](https://github.com/fullofcaffeine/reflaxe.elixir/commit/7de7f570c792b229854da59e85920cd29bc1d951))


### Features

* **std:** implement Xml support ([b81e471](https://github.com/fullofcaffeine/reflaxe.elixir/commit/b81e4719169dcd4e2d6e38f49f658db887d7d8a0))

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
