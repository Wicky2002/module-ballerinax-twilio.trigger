# Ballerina Twilio.trigger connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-twilio.trigger/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-twilio.trigger/actions/workflows/ci.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-twilio.trigger.svg)](https://github.com/ballerina-platform/module-ballerinax-twilio.trigger/commits/main)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/twilio.trigger.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%2Ftwilio.trigger)

## Overview

The Twilio Trigger module allows you to listen to Twilio status callbacks:
- Call status changes: `initiated`, `queued`, `ringing`, `in-progress`, `completed`, `busy`,
  `failed`, `no-answer` and `canceled`
- Message status changes: `accepted`, `scheduled`, `queued`, `sending`, `sent`, `delivered`,
  `undelivered`, `failed`, `read`, `canceled`, `receiving`, `received` and `partially_delivered`

This module receives Twilio's status callbacks directly - it does not call Twilio's REST API on
your behalf. Use the [`ballerinax/twilio`](https://central.ballerina.io/ballerinax/twilio/latest)
connector for that, for example to send a message.

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
   reject requests that did not come from Twilio.

   <img src="https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-twilio.trigger/main/docs/setup/resources/auth-token.png" alt="Twilio Console Account Info with the Account SID and Auth Token" width="600">

2. Expose port `8090` with ngrok:

   ```bash
   ngrok http 8090
   ```

   Copy the `Forwarding` URL ngrok prints out - this is your temporary public base URL.

   <img src="https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-twilio.trigger/main/docs/setup/resources/ngrok-forwarding.png" alt="ngrok forwarding a public URL to localhost:8090" width="600">

3. Write your service (see [Quickstart](#quickstart) below) with the Auth Token as
   `webhookSecret` and the ngrok URL as `webhookBaseUrl`, and run it with `bal run`.
   `webhookBaseUrl` must be exactly the scheme and host Twilio calls, without a trailing slash,
   because Twilio signs the full URL.

4. To receive call status callbacks for calls to your Twilio number, go to **Phone Numbers >
   Manage > Active numbers**, select your number and open its **Configure** tab.

   <img src="https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-twilio.trigger/main/docs/setup/resources/webhook-settings-page.png" alt="Twilio phone number Configure tab with the Voice Configuration section" width="600">

5. Under **Voice Configuration**, set **Call status changes** to `<ngrok URL>/callStatus` with
   method `HTTP POST`, and click **Save configuration**.

   <img src="https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-twilio.trigger/main/docs/setup/resources/webhook-form-filled.png" alt="Twilio Voice Configuration with Call status changes set to the ngrok callStatus URL" width="600">

6. Call your Twilio number from your phone. When the call ends, Twilio posts its final status to
   `/callStatus`.

7. To receive message status callbacks, send a message with `StatusCallback` set to
   `<ngrok URL>/smsStatus`. On a trial account, `To` must be a number you have verified.

   ```bash
   curl -X POST "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/Messages.json" \
     --data-urlencode "From=<your Twilio number>" \
     --data-urlencode "To=<your phone number>" \
     --data-urlencode "Body=Hello from Ballerina" \
     --data-urlencode "StatusCallback=<ngrok URL>/smsStatus" \
     -u "$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN"
   ```

   Twilio posts each status the message goes through (`queued`, `sent`, `delivered`, ...). Each
   delivery shows up in the ngrok console with `200 OK`, and your handler runs.

   <img src="https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-twilio.trigger/main/docs/setup/resources/webhook-confirmed.png" alt="ngrok console showing Twilio status callbacks answered with 200 OK" width="600">

Twilio sends only the final call status (`completed`, `busy`, `failed`, `no-answer` or `canceled`)
unless you ask for more. To also get `initiated`, `ringing` and `in-progress`, set
`StatusCallbackEvent` (`initiated ringing answered completed`) when you create a call through the
REST API. For all messages sent through a Messaging Service, set the service's **Delivery Status
Callback** under **Integration** instead of passing `StatusCallback` each time.

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

Then use your production URL in place of the ngrok URL in the callback URLs above. If you rotate
the Auth Token in the Twilio Console, update `webhookSecret` too, or every callback is rejected.

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
to verify incoming callbacks actually came from Twilio. Omitting it disables that verification, so
it isn't shown here as a normal setup option. `webhookBaseUrl` is the public base URL Twilio calls,
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

See [Setup guide](#setup-guide) above for the full walkthrough (with screenshots) of exposing your
service and setting the callback URLs, for both local testing and production use.

## Examples

The `twilio.trigger` module provides practical examples illustrating usage in various scenarios.
Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-twilio.trigger/tree/main/examples/),
covering common status callback handling use cases.

## Build from the source

### Setting up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 21. You can download it from either of the following sources:

    * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
    * [OpenJDK](https://adoptium.net/)

   > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/), **2201.13.0 or later**.

3. Download and install [Docker](https://www.docker.com/get-started).

   > **Note**: Ensure that the Docker daemon is running before executing any tests.

4. Export Github Personal access token with read package permissions as follows,

    ```bash
    export packageUser=<Username>
    export packagePAT=<Personal access token>
    ```

### Build options

Execute the commands below to build from the source.

1. To build the package:

   ```bash
   ./gradlew clean build
   ```

2. To run the tests:

   ```bash
   ./gradlew clean test
   ```

3. To build the without the tests:

   ```bash
   ./gradlew clean build -x test
   ```

4. To run tests against different environments:

   ```bash
   ./gradlew clean test -Pgroups=<Comma separated groups/test cases>
   ```

5. To debug the package with a remote debugger:

   ```bash
   ./gradlew clean build -Pdebug=<port>
   ```

6. To debug with the Ballerina language:

   ```bash
   ./gradlew clean build -PbalJavaDebug=<port>
   ```

7. Publish the generated artifacts to the local Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

8. Publish the generated artifacts to the Ballerina Central repository:

   ```bash
   ./gradlew clean build -PpublishToCentral=true
   ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`twilio.trigger` package](https://central.ballerina.io/ballerinax/twilio.trigger/latest).
* If you're moving from the older `trigger.twilio` package, see the [migration notes](docs/migration-notes.md).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.