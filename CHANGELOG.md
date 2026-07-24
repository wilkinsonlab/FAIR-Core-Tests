# Changelog

## [0.5.5] - 2026-07-24

### Fixed

- `config.ru` ran `Sinatra::Application` instead of `ApplicationController`. All routes are registered via `set_routes` inside `class ApplicationController < Sinatra::Application`, which — because each Sinatra::Base subclass keeps its own independent route table — registers them on `ApplicationController`, not on the parent `Sinatra::Application` class. `config.ru` had carried the wrong class since it was written, but the bug was invisible because the container always booted via `run.rb` (`ApplicationController.run!`), never through `config.ru`; switching to `bundle exec puma -C config/puma.rb` in 0.5.0 made Puma load `config.ru` for the first time and exposed it as a 404 on every route. Verified by loading the app and comparing route tables: `Sinatra::Application.routes` was empty; `ApplicationController.routes['POST']` correctly listed `/tests/assess/test/:id`, etc.

## [0.5.4] - 2026-07-24

### Fixed

- `config/puma.rb` crash-looped on startup (`undefined method 'backlog'`): Puma has never had a standalone `backlog` DSL method — it's only settable as a query parameter on the `bind` URL. Also removed the redundant `port` directive, which combined with the explicit `bind` call to register the same address twice (`config.options[:binds]` showed `["tcp://0.0.0.0:8282", "tcp://0.0.0.0:8282"]`). Verified by loading the config directly through `Puma::Configuration` — single bind, correct worker/thread/timeout values.

## [0.5.3] - 2026-07-24

### Changed

- Renamed the `RAILS_MAX_THREADS` env var (introduced in 0.5.0) to `PUMA_MAX_THREADS` in `config/puma.rb` and `docker-compose.yml`. This is a plain Sinatra app with no Rails involved; the old name was copied from common Puma/Heroku boilerplate and was misleading about what actually reads it.

## [0.5.2] - 2026-07-24

### Changed

- Removed `startpage` from the SearXNG engine list (`searxng-config/settings.yml`): under real traffic it was the most frequent offender, getting fully CAPTCHA'd (locking it out for a full hour per SearXNG's own `suspended_time`) rather than just briefly rate-limited.
- `fc_searchable` and `test_FM_F4_M_MetaIndexed` now track which phrases they've already searched within a single test run and skip re-querying SearXNG for a duplicate (each query fans out to every configured engine, so a resource whose title/keywords/graph-title/graph-name/graph-keywords clauses overlap was generating several redundant outbound searches per single `assess/test` call). Both tests keep their own independent copy of this logic, consistent with their existing separate SearXNG clients/error classes.

## [0.5.1] - 2026-07-24

### Changed

- Tuned the resource limits and Puma concurrency added in 0.5.0 to the production host's actual capacity (4 cores / 7.8GB RAM, no swap): `tests` now gets `cpus: 2.0` / `mem_limit: 3g` with `WEB_CONCURRENCY: 3`, `tika` gets `cpus: 0.75`. Combined container limits leave roughly 0.75 core and 3.3GB for the host, `searxng`, and OS overhead so the host stays responsive under peak load.

## [0.5.0] - 2026-07-24

### Changed

- The container now runs `bundle exec puma -C config/puma.rb` instead of `ruby run.rb`, with worker/thread counts and a bounded connection backlog set explicitly (`config/puma.rb`). Previously concurrency was whatever Sinatra's/Puma's untuned defaults happened to be, with no cap on how many test executions could run at once.
- `docker-compose.yml` now sets `mem_limit`/`cpus` on `tests`, `searxng`, and `tika` (overridable via env vars) and `restart: unless-stopped` on `tests`. Under heavy legitimate load the container was able to consume all host CPU/memory, taking down the Docker host itself (including SSH access) rather than just failing its own requests.

## [0.4.1] - 2026-07-24

### Changed

- 'fc_data_identifier_in_metadat' changed to point to the correct metric (FM_F3_M_DataIdent)


## [0.4.0] - 2026-07-23

### Changed

- `fc_searchable` and `test_FM_F4_M_MetaIndexed` now query a self-hosted SearXNG metasearch instance instead of the paid Microsoft Bing Web Search API, removing per-query billing and the `BING_API` key requirement. `docker-compose.yml` now runs a `searxng` service alongside `tests`.
- Both tests now build the list of candidate resource URIs (`target_uris`) once from the harvested metadata plus the tested GUID, fixing a latent bug where an unassigned `finalURI` local variable would raise `NoMethodError` as soon as a search engine returned results.
- SearXNG request failures (unreachable service, non-2xx response, unparseable JSON) are now raised as `SearxngError` and caught around the whole search flow, so a backend outage now yields an `indeterminate` result instead of an unhandled 500.

### Removed

- The `BING_API` environment variable and the Bing-calling code paths (`callBing`/`callBing2`) are gone; `BING_API` is no longer read anywhere.

## [0.3.6] - 2026-06-30

### Changed

- Updated `fair_champion_harvester` dependency to `~> 0.1.14`, which fixes a critical cache collision bug: `Cache.checkRDFCache` was matching on byte-count instead of MD5 hash, causing wrong RDF graphs to be returned for unrelated resources after days of accumulated cache files. Symptom was completely incorrect metadata (from a different dataset) being returned, disappearing on service restart. Fixed by keying the cache lookup directly on `MD5(body)`, consistent with the write path.

## [0.3.5] - 2026-06-30

### Changed

- Updated `fair_champion_harvester` dependency to `~> 0.1.13`, which fixes JSON-LD context expansion: remote `@context` URLs (e.g. `http://schema.org`) are now resolved during parsing so that `@type: @id` coercions are applied correctly. Properties like `schema:license` now produce IRI resources rather than string literals, allowing FAIR license assessment tests to pass for datasets such as ESRF DOIs.

## [0.3.4] - 2026-05-27

- Previous release.
