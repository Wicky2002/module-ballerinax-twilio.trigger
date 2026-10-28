## Overview

The Twilio Trigger module allows you to listen to Twilio status callbacks:
- Call status changes: `initiated`, `queued`, `ringing`, `in-progress`, `completed`, `busy`,
  `failed`, `no-answer` and `canceled`
- Message status changes: `accepted`, `scheduled`, `queued`, `sending`, `sent`, `delivered`,
  `undelivered`, `failed`, `read`, `canceled`, `receiving`, `received` and `partially_delivered`

This module receives Twilio's status callbacks directly - it does not call Twilio's REST API on
your behalf. Use the [`ballerinax/twilio`](https://central.ballerina.io/ballerinax/twilio/latest)
connector for that, for example to send a message.

### Key features

- Receives Twilio call status (9 statuses) and message status (13 statuses) callbacks
- Verifies every callback with the account's Auth Token (`X-Twilio-Signature`, signed over the full URL and parameters)
- Serves call and message callbacks on their own paths, `/callStatus` and `/smsStatus`
- Acknowledges each delivery before running your handler, so a slow or failing handler doesn't cause retries
- Services can be attached on their own path, so several triggers and HTTP services can share one port
- Trigger services are listed by `bal build --export-endpoints` (Ballerina 2201.13.6 or later)

## Setup guide

Before using this trigger in your Ballerina application, you need a Twilio account with a phone
number, and a Ballerina service that Twilio can reach over the internet to deliver status
callbacks to. The two sections below cover both a quick local test setup and a production
deployment.

The listener serves call status callbacks at `/callStatus` and message status callbacks at
`/smsStatus`, so the URLs you give Twilio are your public base URL followed by one of those paths.

### Try it out locally

Use this flow to test your callback handling logic on your own machine before deploying anywhere,
using [ngrok](https://ngrok.com/) to expose your local listener to the internet.

1. In the [Twilio Console](https://console.twilio.com/), find **Account Info** on the home page and
   copy the **Auth Token**. Twilio signs every callback with it, and the listener uses it to
   reject requests that did not come from Twilio
   ([how Twilio signs requests](https://www.twilio.com/docs/usage/webhooks/webhooks-security)).

2. Expose port `8090` with ngrok:

   ```bash
   ngrok http 8090
   ```

   Copy the `Forwarding` URL ngrok prints out (for example `https://abc123.ngrok-free.app`) - this
   is your temporary public base URL.

3. Write your service (see [Quickstart](#quickstart) below) with the Auth Token as
   `webhookSecret` and the ngrok URL as `webhookBaseUrl`, and run it with `bal run`.
   `webhookBaseUrl` must be exactly the scheme and host Twilio calls, without a trailing slash,
   because Twilio signs the full URL. Use the callback URLs below without query parameters: the
   listener checks the signature against the path only, so a URL with a query string is rejected.

4. To receive call status callbacks, create a call with `StatusCallback` set to
   `<ngrok URL>/callStatus`. Twilio calls `To` and plays the TwiML at `Url`; on a trial account,
   `To` must be a number you have verified.

   ```bash
   curl -X POST "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/Calls.json" \
     --data-urlencode "From=<your Twilio number>" \
     --data-urlencode "To=<your phone number>" \
     --data-urlencode "Url=http://demo.twilio.com/docs/voice.xml" \
     --data-urlencode "StatusCallback=<ngrok URL>/callStatus" \
     --data-urlencode "StatusCallbackEvent=initiated ringing answered completed" \
     -u "$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN"
   ```

   For calls to your Twilio number, set **Call status changes** under **Voice Configuration** on
   the number's **Configure** tab (**Phone Numbers > Manage > Active numbers**) to
   `<ngrok URL>/callStatus` instead. See [Voice webhooks](https://www.twilio.com/docs/usage/webhooks/voice-webhooks)
   and the [Call resource](https://www.twilio.com/docs/voice/api/call-resource) for both options.

5. To receive message status callbacks, send a message with `StatusCallback` set to
   `<ngrok URL>/smsStatus`. On a trial account, `To` must be a number you have verified.

   ```bash
   curl -X POST "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/Messages.json" \
     --data-urlencode "From=<your Twilio number>" \
     --data-urlencode "To=<your phone number>" \
     --data-urlencode "Body=Hello from Ballerina" \
     --data-urlencode "StatusCallback=<ngrok URL>/smsStatus" \
     -u "$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN"
   ```

   See [Track the message status of outbound messages](https://www.twilio.com/docs/messaging/guides/track-outbound-message-status).

6. Twilio posts each status the call or message goes through (`initiated`, `ringing`, `completed`,
   `queued`, `sent`, `delivered`, ...). Each callback shows up in the ngrok console as
   `POST /callStatus` or `POST /smsStatus` with `200 OK`, and your handler runs. To see a
   callback's parameters, open ngrok's request inspector at `http://127.0.0.1:4040`. A `401` means
   the signature check failed: check the Auth Token and that `webhookBaseUrl` matches the ngrok URL.

Without `StatusCallbackEvent`, Twilio sends only the final call status (`completed`, `busy`,
`failed`, `no-answer` or `canceled`), and the **Call status changes** setting on a number works the
same way. `answered` arrives as `in-progress`. For all messages sent through a Messaging Service,
set the service's **Delivery Status Callback** under **Integration** instead of passing
`StatusCallback` each time.

### Production / business integration

For production use, deploy your Ballerina service somewhere with a stable, internet-reachable
HTTPS URL. Ballerina doesn't require any specific hosting platform - containers, a VM, a managed
PaaS, or anything else that gives you a stable HTTPS endpoint all work equally well.

Rather than hardcoding the values shown in the Quickstart, inject them via `Config.toml` (or your
platform's equivalent configuration/secret mechanism), since they are `configurable`:

```toml
[<your_org>.<your_module_name>.userInput]
webhookSecret = "<your Auth Token>"
webhookBaseUrl = "https://<your production host>"
```

Then use your production URL in place of the ngrok URL in the callback URLs above, and set
`webhookBaseUrl` to it. If you rotate the Auth Token in the Twilio Console, update
`webhookSecret` too, or every callback is rejected.

### Compatibility

|                     | Version                       |
|---------------------|-------------------------------|
| Ballerina Language  | Ballerina Swan Lake 2201.13.0 |

## Quickstart

To use the Twilio Trigger in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the Twilio Trigger Ballerina library

```ballerina
import ballerinax/twilio.trigger as twilio;
```

### Step 2: Initialize the Twilio Listener

Initialize the trigger by providing the listener config and a port number/`http:Listener` object.

```ballerina
configurable twilio:ListenerConfig userInput = {
    webhookSecret: "xxxxxx",
    webhookBaseUrl: "https://xxxx.ngrok-free.app"
};
listener twilio:Listener twilioListener = new (userInput, 8090);
```

`webhookSecret` should always be set to your account's Auth Token - this is what the trigger uses
to verify incoming callbacks actually came from Twilio. Without it, the listener rejects every request with `401 Unauthorized`. `webhookBaseUrl` is the public base URL Twilio calls,
which is part of what Twilio signs.

If you don't provide a port it will use the default port, which is 8090.

```ballerina
listener twilio:Listener twilioListener = new (userInput);
```

### Step 3: Use the correct service type to implement the service

Use `CallStatusService` for call status callbacks and `SmsStatusService` for message status
callbacks. Every remote function declared on a service type must be implemented - Ballerina
requires a complete implementation, not just the ones you care about.

```ballerina
service twilio:CallStatusService on twilioListener {

    remote function onInitiated(twilio:CallStatusEventWrapper payload) returns error? {
    }

    remote function onQueued(twilio:CallStatusEventWrapper payload) returns error? {
    }

    remote function onRinging(twilio:CallStatusEventWrapper payload) returns error? {
    }

    remote function onInProgress(twilio:CallStatusEventWrapper payload) returns error? {
    }

    remote function onCompleted(twilio:CallStatusEventWrapper payload) returns error? {
    }

    remote function onBusy(twilio:CallStatusEventWrapper payload) returns error? {
    }

    remote function onFailed(twilio:CallStatusEventWrapper payload) returns error? {
    }

    remote function onNoAnswer(twilio:CallStatusEventWrapper payload) returns error? {
    }

    remote function onCanceled(twilio:CallStatusEventWrapper payload) returns error? {
    }
}
```

### Step 4: Provide remote functions corresponding to the events you're interested in

Each status has its own remote function on the matching service type - for example,
`onCompleted` on `twilio:CallStatusService` when a call ends normally.

```ballerina
import ballerina/log;

service twilio:CallStatusService on twilioListener {

    remote function onCompleted(twilio:CallStatusEventWrapper payload) returns error? {
        log:printInfo("Call completed", callSid = payload.CallSid, 'from = payload.From,
                to = payload.To, durationSeconds = payload.CallDuration);
    }

    // ... the other remote functions of CallStatusService
}
```

### Step 5: Run the service

Use the `bal run` command to compile and run the Ballerina program.

### Step 6: Point Twilio at your service

See [Setup guide](#setup-guide) above for the full walkthrough of exposing your
service and setting the callback URLs, for both local testing and production use.

## Examples

The `twilio.trigger` module provides practical examples illustrating usage in various scenarios.
Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-twilio.trigger/tree/main/examples/),
covering common status callback handling use cases.

## Report issues

To report bugs, request new features, start new discussions, etc., go to the
[Ballerina Library repository](https://github.com/ballerina-platform/ballerina-library).

## Useful links

- For more information go to the [`twilio.trigger` package](https://central.ballerina.io/ballerinax/twilio.trigger/latest).
- If you're moving from the older `trigger.twilio` package, see the [migration notes](https://github.com/ballerina-platform/module-ballerinax-twilio.trigger/blob/main/docs/migration-notes.md).
- For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
- Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
- Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
