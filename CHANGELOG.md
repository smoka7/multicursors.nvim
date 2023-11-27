# Changelog

## [0.11.0](https://github.com/smoka7/multicursors.nvim/compare/v0.10.2...v0.11.0) (2023-11-27)


### Features

* replace selections text with register content ([#72](https://github.com/smoka7/multicursors.nvim/issues/72)) ([ebd4e3f](https://github.com/smoka7/multicursors.nvim/commit/ebd4e3f647bf233ee95fa8c5186108aaada2c8e1))


### Bug Fixes

* **insert_mode:** add missing bangs to `normal` commands ([#75](https://github.com/smoka7/multicursors.nvim/issues/75)) ([1d4bf39](https://github.com/smoka7/multicursors.nvim/commit/1d4bf39ac6b7a2c2076eb11def095212ab04a039))

## [0.10.2](https://github.com/smoka7/multicursors.nvim/compare/v0.10.1...v0.10.2) (2023-11-22)


### Bug Fixes

* delete the overlapping selections ([#69](https://github.com/smoka7/multicursors.nvim/issues/69)) ([e9de1fa](https://github.com/smoka7/multicursors.nvim/commit/e9de1fa025284fccc54b8920016ad6ffd8d266b1))

## [0.10.1](https://github.com/smoka7/multicursors.nvim/compare/v0.10.0...v0.10.1) (2023-11-03)


### Bug Fixes

* ignore special characters when searching ([3e9459d](https://github.com/smoka7/multicursors.nvim/commit/3e9459d8e742653bdaf5f5793ce3310b3e66ef93)), closes [#65](https://github.com/smoka7/multicursors.nvim/issues/65)

## [0.10.0](https://github.com/smoka7/multicursors.nvim/compare/v0.9.1...v0.10.0) (2023-10-19)


### Features

* change selections case ([#64](https://github.com/smoka7/multicursors.nvim/issues/64)) ([ce446c8](https://github.com/smoka7/multicursors.nvim/commit/ce446c829a0eb88a8d8dd432c7820a10d9b9a38d))
* **hints:** add width option ([#62](https://github.com/smoka7/multicursors.nvim/issues/62)) ([1e41efd](https://github.com/smoka7/multicursors.nvim/commit/1e41efd5c70b31e1642754457eab7c6f019c4b1c))

## [0.9.1](https://github.com/smoka7/multicursors.nvim/compare/v0.9.0...v0.9.1) (2023-10-15)


### Bug Fixes

* handle nil key descriptions ([#60](https://github.com/smoka7/multicursors.nvim/issues/60)) ([3101b53](https://github.com/smoka7/multicursors.nvim/commit/3101b536deaf536b16e2a974b720517fd3a82f78))

## [0.9.0](https://github.com/smoka7/multicursors.nvim/compare/v0.8.1...v0.9.0) (2023-10-15)


### Features

* **highlights:** allow overriding highlights ([#56](https://github.com/smoka7/multicursors.nvim/issues/56)) ([f12195e](https://github.com/smoka7/multicursors.nvim/commit/f12195e2cc7bf12c76b2ab09ca81a82481ede78d))
* **hints:** add columns option ([#57](https://github.com/smoka7/multicursors.nvim/issues/57)) ([1b7b1e1](https://github.com/smoka7/multicursors.nvim/commit/1b7b1e1fdb231486089d86f6cd431560370a5ce7))
* **hints:** allow functions in generate_hints ([#58](https://github.com/smoka7/multicursors.nvim/issues/58)) ([6af8a8a](https://github.com/smoka7/multicursors.nvim/commit/6af8a8a785cb66b545118641b9c0bbee5b821859))

## [0.8.1](https://github.com/smoka7/multicursors.nvim/compare/v0.8.0...v0.8.1) (2023-10-02)


### Bug Fixes

* make mode bindings configurable ([#46](https://github.com/smoka7/multicursors.nvim/issues/46)) ([2c21968](https://github.com/smoka7/multicursors.nvim/commit/2c21968436d59f7b18628e380b508832feca92cd))

## [0.8.0](https://github.com/smoka7/multicursors.nvim/compare/v0.7.4...v0.8.0) (2023-09-16)


### Features

* auto change anchor in extend mode ([#38](https://github.com/smoka7/multicursors.nvim/issues/38)) ([1c97c10](https://github.com/smoka7/multicursors.nvim/commit/1c97c10778804b9a57465663bc7082b751b5db4f))


### Bug Fixes

* fix ci errors ([#39](https://github.com/smoka7/multicursors.nvim/issues/39)) ([9b2753b](https://github.com/smoka7/multicursors.nvim/commit/9b2753b8501e137b0821d182a11f1131d92a1c86))
* move selections forward when inserting text at the start or end of line ([#43](https://github.com/smoka7/multicursors.nvim/issues/43)) ([1b68c19](https://github.com/smoka7/multicursors.nvim/commit/1b68c19a583e6883c483abcdae0b509219172005))

## [0.7.4](https://github.com/smoka7/multicursors.nvim/compare/v0.7.3...v0.7.4) (2023-08-19)


### Bug Fixes

* move selections by char length ([ce94d39](https://github.com/smoka7/multicursors.nvim/commit/ce94d39cecb62a15b4bfb1b31b401781073d5ae5))
* Remove extra param from byteidx ([#37](https://github.com/smoka7/multicursors.nvim/issues/37)) ([fc50fc9](https://github.com/smoka7/multicursors.nvim/commit/fc50fc930a636fe46c6f859a7aa60ae901108146))

## [0.7.3](https://github.com/smoka7/multicursors.nvim/compare/v0.7.2...v0.7.3) (2023-08-10)


### Bug Fixes

* delete text from end of selections ([8e668a4](https://github.com/smoka7/multicursors.nvim/commit/8e668a45822e757be216755830afdce131ae56fc))
* set nowait value for modes ([6b3b323](https://github.com/smoka7/multicursors.nvim/commit/6b3b32395536b20747480b4d30b8d32ba2db7690))

## [0.7.2](https://github.com/smoka7/multicursors.nvim/compare/v0.7.1...v0.7.2) (2023-08-09)


### Bug Fixes

* don't enter normal mode when we can't find &lt;cword&gt; ([92b77cc](https://github.com/smoka7/multicursors.nvim/commit/92b77cc85ba8b12499d1a2d4834910f30d850c83))

## [0.7.1](https://github.com/smoka7/multicursors.nvim/compare/v0.7.0...v0.7.1) (2023-08-07)


### Bug Fixes

* allow disabling of mappings ([0ee8858](https://github.com/smoka7/multicursors.nvim/commit/0ee88581b1c6668d70247c74a578b826cf4c2f87))

## [0.7.0](https://github.com/smoka7/multicursors.nvim/compare/v0.6.3...v0.7.0) (2023-08-06)


### Features

* create selection for char under cursor ([#24](https://github.com/smoka7/multicursors.nvim/issues/24)) ([331d805](https://github.com/smoka7/multicursors.nvim/commit/331d805312aad79a788d0a6948ef453c09fbb320))


### Bug Fixes

* don't go to end of line from start of line ([8f64012](https://github.com/smoka7/multicursors.nvim/commit/8f64012ae4e2dd41a17d4351d63938defd47d130))
* remove plugin directory ([#21](https://github.com/smoka7/multicursors.nvim/issues/21)) ([8c14d22](https://github.com/smoka7/multicursors.nvim/commit/8c14d223a1b72a89c62060a0b9d4a4a78f19a119))
