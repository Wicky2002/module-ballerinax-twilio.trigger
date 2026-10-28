# Changelog
This file contains all the notable changes done to the Ballerina Twilio trigger through the releases.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- The `twilio.trigger` package, replacing `trigger.twilio` from the `asyncapi-triggers` monorepo. It is generated from the AsyncAPI definition in `docs/spec` with the Ballerina AsyncAPI tool. See the [migration notes](docs/migration-notes.md) for what changed from `trigger.twilio`.
- Request signature verification with the account's Auth Token (`X-Twilio-Signature`, HMAC-SHA1 over the full callback URL and the sorted form parameters). `trigger.twilio` accepted unsigned requests.
- Call and message status callbacks each have their own path, `/callStatus` and `/smsStatus`, so call status callbacks now reach `CallStatusService`.
- The `initiated` call status and the `scheduled`, `read`, `canceled` and `partially_delivered` message statuses, plus the extra callback parameters Twilio documents.
- Services on the trigger listener are listed by `bal build --export-endpoints`, through a compiler plugin packaged with the trigger. Endpoint export needs Ballerina 2201.13.6 or later.
- Trigger metadata and icons under `metadata/` for low-code tooling.
