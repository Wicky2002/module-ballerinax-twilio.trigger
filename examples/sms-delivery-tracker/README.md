# SMS delivery tracker

The minimal, canonical `twilio.trigger` use case: follow each outbound message to its final
state, logging deliveries and flagging undelivered or failed messages with Twilio's error code.

## Run

```bash
bal run
```

Then follow the [Setup guide](../../ballerina/README.md#setup-guide) in the package README to
expose this listener, and send a message with `StatusCallback` set to `<your public URL>/smsStatus`.
