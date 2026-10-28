# Call outcome logger

Log how each call ended: completed calls with their duration, and calls that were busy, not
answered, canceled or failed.

## Run

```bash
bal run
```

Then follow the [Setup guide](../../ballerina/README.md#setup-guide) in the package README to
expose this listener, set **Call status changes** on your Twilio number to
`<your public URL>/callStatus`, and call the number. To also see the call being answered, create
calls through the REST API with `StatusCallbackEvent` including `answered`.
