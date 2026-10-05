# Sanitations for the twilio AsyncAPI specification

Migrated from `asyncapi-triggers/asyncapi/twilio/asyncapi.yml` (AsyncAPI 2.1.0) to AsyncAPI 3.0.0.

## Changes

1. Upgraded the document to AsyncAPI 3.0.0: each `subscribe` channel became a channel with named messages plus an `operations` entry with `action: receive`, and each `oneOf` entry became a named message carrying its `x-ballerina-event-type`.
2. `info.externalDocs` moved under `info`; the default content type is declared.
3. Message names are the channel plus the status (e.g. `callStatusInProgress`); the event types are unchanged.

## Open questions (not changed)

- The event identifier is the body field `MessageStatus`, but voice call events carry `CallStatus` instead, so call events would not match any handler. Needs a decision (a second identifier path or a split).
- Twilio posts webhooks as `application/x-www-form-urlencoded`, not JSON. Confirm how the generated listener should parse the body.
- Request signature verification (`X-Twilio-Signature`) is not declared yet.

Author: Dinuka Wickramasinghe
