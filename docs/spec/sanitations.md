# Sanitations for the twilio AsyncAPI specification

Migrated from `asyncapi-triggers/asyncapi/twilio/asyncapi.yml` (AsyncAPI 2.1.0) to AsyncAPI 3.0.0.

## Changes

1. Upgraded the document to AsyncAPI 3.0.0: each `subscribe` channel became a channel with named messages plus an `operations` entry with `action: receive`, and each `oneOf` entry became a named message carrying its `x-ballerina-event-type`.
2. `info.externalDocs` moved under `info`; the default content type is declared.
3. Message names are the channel plus the status (e.g. `callStatusInProgress`); the event types are unchanged.

4. Checked against Twilio docs on 2026-10-05: added the documented message statuses `scheduled`, `read` and `canceled`. Call statuses already matched.

5. Checked against Twilio docs again on 2026-10-27:
   - Added the call status `initiated` (https://www.twilio.com/docs/voice/api/call-resource) and the message status `partially_delivered` (https://www.twilio.com/docs/messaging/api/message-resource).
   - Added the documented call status callback parameters `Duration`, `SipResponseCode`, `Timestamp`, `CallbackSource`, `SequenceNumber`, `StirStatus`, `ParentCallSid`, `ForwardedFrom` and `CallerName`, and the message status callback parameters `ErrorCode`, `RawDlrDoneDate`, `ChannelInstallSid`, `ChannelStatusMessage`, `ChannelPrefix` and `EventType` (https://www.twilio.com/docs/messaging/guides/track-outbound-message-status). All stay optional strings, as Twilio sends every parameter as a string and adds new ones without notice.
6. Each channel identifies its events with its own parameter: `CallStatus` for `callStatus`, `MessageStatus` for `smsStatus`. The document-level `MessageStatus` identifier is removed: call status callbacks carry `CallStatus`, so they never matched it, and `queued`, `failed` and `canceled` are both call and message statuses. With channel identifiers the listener serves each channel at its own path, `/callStatus` and `/smsStatus`.
7. The default content type is `application/x-www-form-urlencoded`, which is how Twilio posts status callbacks.
8. Declared the signature in `x-ballerina-auth`. Twilio computes `X-Twilio-Signature` as the Base64 HMAC-SHA1, keyed by the account's Auth Token, of the full URL it posts to followed by the form parameters sorted by name (https://www.twilio.com/docs/usage/webhooks/webhooks-security). Because each channel has its own path, the input is the configured public base URL (`$config('webhookBaseUrl')`, for example `https://abc.ngrok.app`) followed by the request path (`$uri`) and the sorted parameters (`$formParams`).

## Verification

The generated listener was checked with Twilio's own helper library (`twilio` 5.13.1, `getExpectedTwilioSignature`), which computes the signature exactly as Twilio does: callbacks signed by it were accepted and dispatched on both `/callStatus` and `/smsStatus`, including one with an undeclared extra parameter; a changed parameter, a signature for the other path and a wrong Auth Token were rejected with 401.

## Test payloads

The 22 files under `ballerina/tests/resources/trigger_payloads/<channel>/` use the parameters Twilio documents for each callback, with the status set per file and the parameters Twilio sends only for some statuses: `CallDuration` and `SipResponseCode` on terminal call statuses, `Duration` on `completed`, `ErrorCode` on `failed` and `undelivered` messages, and `RawDlrDoneDate` on `delivered` and `undelivered` messages.

Author: Dinuka Wickramasinghe
