# Delivery failure alert

Raise one kind of alert for anything that didn't reach the customer: messages that failed or were
undelivered, and calls that failed, were busy or weren't answered. Both service types share one
listener, which serves message callbacks at `/smsStatus` and call callbacks at `/callStatus`.

## Run

```bash
bal run
```

Then follow the [Setup guide](../../ballerina/README.md#setup-guide) in the package README to
expose this listener and point both callbacks at it.
