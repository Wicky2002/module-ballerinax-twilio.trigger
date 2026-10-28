import ballerina/log;
import ballerinax/twilio.trigger as twilio;

configurable twilio:ListenerConfig config = {
    webhookSecret: "xxxxxx",
    webhookBaseUrl: "https://xxxx.ngrok-free.app"
};

listener twilio:Listener twilioListener = new (config, 8090);

// Follows each outbound message to its final state: delivered, undelivered or failed.
service twilio:SmsStatusService on twilioListener {

    remote function onAccepted(twilio:SmsStatusChangeEventWrapper payload) returns error? {
        logProgress(payload);
    }

    remote function onQueued(twilio:SmsStatusChangeEventWrapper payload) returns error? {
        logProgress(payload);
    }

    remote function onSending(twilio:SmsStatusChangeEventWrapper payload) returns error? {
        logProgress(payload);
    }

    remote function onSent(twilio:SmsStatusChangeEventWrapper payload) returns error? {
        logProgress(payload);
    }

    remote function onDelivered(twilio:SmsStatusChangeEventWrapper payload) returns error? {
        log:printInfo("Message delivered", messageSid = payload.MessageSid, to = payload.To);
    }

    remote function onUndelivered(twilio:SmsStatusChangeEventWrapper payload) returns error? {
        log:printWarn("Message undelivered", messageSid = payload.MessageSid, to = payload.To,
                errorCode = payload.ErrorCode);
    }

    remote function onFailed(twilio:SmsStatusChangeEventWrapper payload) returns error? {
        log:printError("Message failed", messageSid = payload.MessageSid, to = payload.To,
                errorCode = payload.ErrorCode);
    }

    remote function onPartiallyDelivered(twilio:SmsStatusChangeEventWrapper payload) returns error? {
        log:printWarn("Message partially delivered", messageSid = payload.MessageSid, to = payload.To);
    }

    remote function onRead(twilio:SmsStatusChangeEventWrapper payload) returns error? {
        log:printInfo("Message read", messageSid = payload.MessageSid, to = payload.To);
    }

    remote function onScheduled(twilio:SmsStatusChangeEventWrapper payload) returns error? {
        logProgress(payload);
    }

    remote function onCanceled(twilio:SmsStatusChangeEventWrapper payload) returns error? {
        log:printInfo("Scheduled message canceled", messageSid = payload.MessageSid);
    }

    remote function onReceiving(twilio:SmsStatusChangeEventWrapper payload) returns error? {
    }

    remote function onReceived(twilio:SmsStatusChangeEventWrapper payload) returns error? {
    }
}

function logProgress(twilio:SmsStatusChangeEventWrapper payload) {
    log:printDebug("Message progress", messageSid = payload.MessageSid, status = payload.MessageStatus);
}
