# Changelog

## [0.5.0](https://github.com/thef4tdaddy/NucleOS/compare/v0.4.0...v0.5.0) (2026-04-23)


### Features

* **calendar:** implement tier 1 features ([f29cd84](https://github.com/thef4tdaddy/NucleOS/commit/f29cd84a6f9df8fbe08c40d95c8a32e441563958))
* **calendar:** implement tier 2 features ([1dec7a7](https://github.com/thef4tdaddy/NucleOS/commit/1dec7a7843ea50596a675e32abd3ac15687ce217))
* **calendar:** implement tier 3 features ([15deac7](https://github.com/thef4tdaddy/NucleOS/commit/15deac768b1b772c4da289ae82c8c8d63476b765))
* **calendar:** implement tier 4 AI integration ([51acb5c](https://github.com/thef4tdaddy/NucleOS/commit/51acb5c3dd19a66432f4f68af79e9202bf9df701))
* **settings:** add calendar mock data toggle ([301dabe](https://github.com/thef4tdaddy/NucleOS/commit/301dabe1c8efcdb921af0ea79002673ad81f449d))
* **ui:** [NUC-25][NUC-26] import and wire custom nucleus section icons and app icon ([09dd72c](https://github.com/thef4tdaddy/NucleOS/commit/09dd72c59c63a522270e6330d98c16a6e518f3f2))


### Bug Fixes

* **ci:** lower macosx deployment target to 15.0 for codeql ([a6e0707](https://github.com/thef4tdaddy/NucleOS/commit/a6e0707cd7e73b2f49db390a3e3cdfe4f6192874))
* **ui:** [NUC-25][NUC-26] resize AppIcon variants and restrict custom icons to section headers ([f231cea](https://github.com/thef4tdaddy/NucleOS/commit/f231cea860537223a43d1e7c7782a01fae7c1ff0))
* **ui:** remove template rendering intent from section icons and crop AppIcon transparency ([0ef93fd](https://github.com/thef4tdaddy/NucleOS/commit/0ef93fd1c1105c9d0a5d6dcbb70f68f11e696237))
* **ui:** remove white backgrounds from section icons and precisely crop AppIcon bounding box ([704ba74](https://github.com/thef4tdaddy/NucleOS/commit/704ba74aba51037a07de5986152cda1518a6268b))

## [0.4.0](https://github.com/thef4tdaddy/NucleOS/compare/v0.3.0...v0.4.0) (2026-04-22)


### Features

* **ai:** 0.4.0-alpha — AI layer and local intelligence foundation NUC-5 ([#70](https://github.com/thef4tdaddy/NucleOS/issues/70)) ([75ce3a6](https://github.com/thef4tdaddy/NucleOS/commit/75ce3a6acefa8950162ceddf99e5106e551ecbff))
* **eventkit:** 0.2.0-alpha — EventKit reminders and calendar integration ([#50](https://github.com/thef4tdaddy/NucleOS/issues/50)) ([91ab281](https://github.com/thef4tdaddy/NucleOS/commit/91ab281a4793faeb524889e10ced6d009409577d))
* **healthkit:** 0.3.0-alpha — HealthKit dashboard integration ([#51](https://github.com/thef4tdaddy/NucleOS/issues/51)) [NUC-17] ([8d8a0cd](https://github.com/thef4tdaddy/NucleOS/commit/8d8a0cd7cf5a78a7b1def4839495f4c53004b4b7))
* **keychain:** add KeychainHelper for secure LLM API key storage ([#9](https://github.com/thef4tdaddy/NucleOS/issues/9)) ([f4ac21c](https://github.com/thef4tdaddy/NucleOS/commit/f4ac21cc3709b0778234bb61585f957f13f782ff))
* **models:** create comprehensive mock data layer ([#23](https://github.com/thef4tdaddy/NucleOS/issues/23)) ([250a093](https://github.com/thef4tdaddy/NucleOS/commit/250a093aa163d06b34786a6826be98d9f7cf20e1))
* **services:** add service protocol layer with real + mock implementations ([#7](https://github.com/thef4tdaddy/NucleOS/issues/7)) ([09c66b6](https://github.com/thef4tdaddy/NucleOS/commit/09c66b6cf069ebd2758db9280b02dda53f965026))


### Bug Fixes

* **ci:** add Node24 env var to fix deprecation warnings ([9105b64](https://github.com/thef4tdaddy/NucleOS/commit/9105b640448aa5f22901fff9ad30effbfdf8af79))
* **lint:** resolve swiftlint violations and fix swiftlint config ([c72be3d](https://github.com/thef4tdaddy/NucleOS/commit/c72be3de1c2da3cf6d55b835cf2e278cd21485b3))
* resolve strict concurrency warnings and EventKit sandbox hang ([4f60d3a](https://github.com/thef4tdaddy/NucleOS/commit/4f60d3ab9b04539e7d112da1b8d5bd32b9579776))
* **testing:** making testing simpler ([da613d3](https://github.com/thef4tdaddy/NucleOS/commit/da613d3c67211e27c8f3888c97b89fd2d13b5717))
* **testing:** still minor adjustments to ci yaml ([846a507](https://github.com/thef4tdaddy/NucleOS/commit/846a507ee259ac2b0c36e395d31b37bc7f1868a4))
* **testing:** still trying to get coverage to upload to codecov ([ba7d970](https://github.com/thef4tdaddy/NucleOS/commit/ba7d970c6e017d4ff4c1d4991e29cf6e49936eff))
