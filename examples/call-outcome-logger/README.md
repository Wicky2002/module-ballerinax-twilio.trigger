# Call outcome logger

Log how each call ended: completed calls with their duration, and calls that were busy, not
answered, canceled or failed.

## Run

```bash
bal run
```

Then follow the [Setup guide](../../ballerina/README.md#setup-guide) in the package README to
expose this listener, then create a call with `StatusCallback` set to
`<your public URL>/callStatus`. Include `answered` in `StatusCallbackEvent` to also see the call
being answered.
