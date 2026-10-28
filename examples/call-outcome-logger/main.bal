import ballerina/log;
import ballerinax/twilio.trigger as twilio;

configurable twilio:ListenerConfig config = {
    webhookSecret: "xxxxxx",
    webhookBaseUrl: "https://xxxx.ngrok-free.app"
};

listener twilio:Listener twilioListener = new (config, 8090);

// Logs how each call ended: answered and how long it lasted, or why it didn't connect.
service twilio:CallStatusService on twilioListener {

    remote function onCompleted(twilio:CallStatusEventWrapper payload) returns error? {
        log:printInfo("Call completed", callSid = payload.CallSid, 'from = payload.From, to = payload.To,
                direction = payload.Direction, durationSeconds = payload.CallDuration);
    }

    remote function onBusy(twilio:CallStatusEventWrapper payload) returns error? {
        logMissed(payload, "busy");
    }

    remote function onNoAnswer(twilio:CallStatusEventWrapper payload) returns error? {
        logMissed(payload, "no answer");
    }

    remote function onFailed(twilio:CallStatusEventWrapper payload) returns error? {
        log:printError("Call failed", callSid = payload.CallSid, to = payload.To,
                sipResponseCode = payload.SipResponseCode);
    }

    remote function onCanceled(twilio:CallStatusEventWrapper payload) returns error? {
        logMissed(payload, "canceled");
    }

    remote function onInitiated(twilio:CallStatusEventWrapper payload) returns error? {
    }

    remote function onQueued(twilio:CallStatusEventWrapper payload) returns error? {
    }

    remote function onRinging(twilio:CallStatusEventWrapper payload) returns error? {
    }

    remote function onInProgress(twilio:CallStatusEventWrapper payload) returns error? {
        log:printInfo("Call answered", callSid = payload.CallSid);
    }
}

function logMissed(twilio:CallStatusEventWrapper payload, string reason) {
    log:printWarn("Call not connected", callSid = payload.CallSid, to = payload.To, reason = reason);
}
