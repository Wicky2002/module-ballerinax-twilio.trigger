# Examples

The `ballerinax/twilio.trigger` connector provides practical examples illustrating usage in various scenarios.

1. [SMS delivery tracker](https://github.com/ballerina-platform/module-ballerinax-twilio.trigger/tree/main/examples/sms-delivery-tracker) - Follow each outbound message to delivered, undelivered or failed.
2. [Call outcome logger](https://github.com/ballerina-platform/module-ballerinax-twilio.trigger/tree/main/examples/call-outcome-logger) - Log how each call ended and how long it lasted.
3. [Delivery failure alert](https://github.com/ballerina-platform/module-ballerinax-twilio.trigger/tree/main/examples/delivery-failure-alert) - One alert for failed calls and messages, from two services on one listener.

## Prerequisites

Copy your Auth Token, expose the running example with a public URL, and set it as both `webhookBaseUrl` and the base of the Twilio callback URLs, as described in the [Setup guide](../ballerina/README.md#setup-guide).

## Running an example

Execute the following commands from an example's directory (for example `cd call-outcome-logger`) to build it from the source:

* To build an example:

    ```bash
    bal build
    ```

* To run an example:

    ```bash
    bal run
    ```

## Building the examples with the local module

**Warning**: Due to the absence of support for reading local repositories for single Ballerina files, the Bala of the module is manually written to the central repository as a workaround. Consequently, the bash script may modify your local Ballerina repositories.

Execute the following commands to build all the examples against the changes you have made to the module locally:

* To build all the examples:

    ```bash
    ./build.sh build
    ```

* To run all the examples:

    ```bash
    ./build.sh run
    ```
