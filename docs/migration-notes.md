# Migration notes: from `trigger.twilio` to `twilio.trigger`

`ballerinax/twilio.trigger` replaces `ballerinax/trigger.twilio` (last released as 0.10.1 from the
`asyncapi-triggers` monorepo). The `ballerina/` source is generated from `docs/spec/asyncapi.yaml`
with the `asyncapi-tools` generator; changes go through the spec and a regeneration, not hand edits
to `ballerina/*.bal`. Every spec change and its source is listed in
[`docs/spec/sanitations.md`](spec/sanitations.md).

## Breaking change: package name and import

```ballerina
// before
import ballerinax/trigger.twilio;

// after
import ballerinax/twilio.trigger as twilio;
```

## Breaking change: the listener takes a config and verifies signatures

`trigger.twilio` accepted every request without checking where it came from, and its listener took
only a port. The listener now takes a `ListenerConfig` first and checks the `X-Twilio-Signature`
header against your account's Auth Token:

```ballerina
// before
listener twilio:Listener twilioListener = new (8090);

// after
listener twilio:Listener twilioListener = new ({
    webhookSecret: "<Auth Token>",
    webhookBaseUrl: "https://<your public host>"
}, 8090);
```

Twilio signs the full URL it calls, so `webhookBaseUrl` must be the public scheme and host Twilio
uses, without a trailing slash.

## Breaking change: callback URLs

Both callbacks used to arrive at `/`. Each now has its own path:

| Callback | Old URL | New URL |
|----------|---------|---------|
| Call status | `<base>/` | `<base>/callStatus` |
| Message status | `<base>/` | `<base>/smsStatus` |

Update the **Call status changes** URL on your phone numbers, the **Delivery Status Callback** on
your Messaging Services, and any `StatusCallback` you pass when creating calls or messages.

This also fixes call status callbacks: `trigger.twilio` routed both callbacks by `MessageStatus`,
which call status callbacks don't carry, so `CallStatusService` was never called.

## New handlers

All 17 remote functions of `trigger.twilio` keep their names and service types. Five statuses that
Twilio documents are added:

- `CallStatusService`: `onInitiated`
- `SmsStatusService`: `onScheduled`, `onRead`, `onCanceled`, `onPartiallyDelivered`

A service has to implement every function its type declares, so services written against
`trigger.twilio` must add these.

## Other changes

- The payload records declare the extra callback parameters Twilio documents, for example
  `Duration`, `SipResponseCode` and `ParentCallSid` for calls and `ErrorCode` and `RawDlrDoneDate`
  for messages. Field names still match Twilio's parameter names.
- The listener acknowledges a callback before it runs your handler, so a slow or failing handler no
  longer makes Twilio retry. Handler errors are logged.

## Test suite

`ballerina/tests` sends each of the 22 statuses, using the parameters Twilio documents for that
callback, as a signed form-encoded request to its path on a test listener, and checks the right
remote function runs. `bal test`: 22/22 passing.
