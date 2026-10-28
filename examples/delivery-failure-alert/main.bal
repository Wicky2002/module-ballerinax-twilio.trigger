import ballerina/log;
import ballerinax/twilio.trigger as twilio;

configurable twilio:ListenerConfig config = {
    webhookSecret: "xxxxxx",
    webhookBaseUrl: "https://xxxx.ngrok-free.app"
};

// One listener serves both callbacks, at /callStatus and /smsStatus.
listener twilio:Listener twilioListener = new (config, 8090);

// Raises one alert format for anything that failed to reach the customer, call or message.
service twilio:SmsStatusService on twilioListener {

    remote function onFailed(twilio:SmsStatusChangeEventWrapper payload) returns error? {
        alert("sms", payload.MessageSid, payload.To, "failed", payload.ErrorCode);
    }

    remote function onUndelivered(twilio:SmsStatusChangeEventWrapper payload) returns error? {
        alert("sms", payload.MessageSid, payload.To, "undelivered", payload.ErrorCode);
    }

    remote function onAccepted(twilio:SmsStatusChangeEventWrapper payload) returns error? {
    }

    remote function onQueued(twilio:SmsStatusChangeEventWrapper payload) returns error? {
    }

    remote function onSending(twilio:SmsStatusChangeEventWrapper payload) returns error? {
    }

    remote function onSent(twilio:SmsStatusChangeEventWrapper payload) returns error? {
    }

    remote function onDelivered(twilio:SmsStatusChangeEventWrapper payload) returns error? {
    }

    remote function onReceiving(twilio:SmsStatusChangeEventWrapper payload) returns error? {
    }

    remote function onReceived(twilio:SmsStatusChangeEventWrapper payload) returns error? {
    }

    remote function onScheduled(twilio:SmsStatusChangeEventWrapper payload) returns error? {
    }

    remote function onRead(twilio:SmsStatusChangeEventWrapper payload) returns error? {
    }

    remote function onCanceled(twilio:SmsStatusChangeEventWrapper payload) returns error? {
    }

    remote function onPartiallyDelivered(twilio:SmsStatusChangeEventWrapper payload) returns error? {
    }
}

service twilio:CallStatusService on twilioListener {

    remote function onFailed(twilio:CallStatusEventWrapper payload) returns error? {
        alert("call", payload.CallSid, payload.To, "failed", payload.SipResponseCode);
    }

    remote function onBusy(twilio:CallStatusEventWrapper payload) returns error? {
        alert("call", payload.CallSid, payload.To, "busy", payload.SipResponseCode);
    }

    remote function onNoAnswer(twilio:CallStatusEventWrapper payload) returns error? {
        alert("call", payload.CallSid, payload.To, "no answer", payload.SipResponseCode);
    }

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

    remote function onCanceled(twilio:CallStatusEventWrapper payload) returns error? {
    }
}

function alert(string channel, string? sid, string? to, string outcome, string? code) {
    log:printWarn("Delivery problem", channel = channel, sid = sid, to = to, outcome = outcome, code = code);
}
