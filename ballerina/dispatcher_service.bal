// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/crypto;
import ballerina/http;
import ballerina/log;
import ballerinax/asyncapi.native.handler;

service class DispatcherService {
    *http:Service;
    private map<GenericServiceType> services = {};
    private handler:NativeHandler nativeHandler = new ();
    private string? webhookSecret;
    private string webhookBaseUrl;

    isolated function init(string? webhookSecret, string webhookBaseUrl) {
        self.webhookSecret = webhookSecret;
        self.webhookBaseUrl = webhookBaseUrl;
    }

    isolated function addServiceRef(string serviceType, GenericServiceType genericService) returns error? {
        if (self.services.hasKey(serviceType)) {
            return error(string `Service of type ${serviceType} has already been attached`);
        }
        self.services[serviceType] = genericService;
    }

    isolated function removeServiceRef(string serviceType) returns error? {
        if (!self.services.hasKey(serviceType)) {
            return error(string `Cannot detach the service of type ${serviceType}. Service has not been attached to the listener before`);
        }
        _ = self.services.remove(serviceType);
    }

    resource function post callStatus(http:Caller caller, http:Request request) returns error? {
        error? verifyResult = self.verifyWebhookSignature(request, self.webhookSecret);
        if verifyResult is error {
            http:Response r = new;
            r.statusCode = http:STATUS_UNAUTHORIZED;
            check caller->respond(r);
            return;
        }
        map<string> formParams = check request.getFormParams();
        map<json> formPayload = {};
        foreach var [name, value] in formParams.entries() {
            formPayload[name] = value;
        }
        json payload = formPayload;
        string eventType = (check payload.CallStatus).toString();
        http:Response ackResponse = new;
        ackResponse.statusCode = http:STATUS_OK;
        check caller->respond(ackResponse);
        boolean|error dispatchResult = self.matchRemoteFuncForCallStatus(payload, eventType);
        if dispatchResult is error {
            log:printError("DISPATCH_FAILED", dispatchResult);
        } else if !dispatchResult {
            log:printWarn("NO_HANDLER_FOR_EVENT", eventIdentifier = eventType);
        }
    }

    resource function post smsStatus(http:Caller caller, http:Request request) returns error? {
        error? verifyResult = self.verifyWebhookSignature(request, self.webhookSecret);
        if verifyResult is error {
            http:Response r = new;
            r.statusCode = http:STATUS_UNAUTHORIZED;
            check caller->respond(r);
            return;
        }
        map<string> formParams = check request.getFormParams();
        map<json> formPayload = {};
        foreach var [name, value] in formParams.entries() {
            formPayload[name] = value;
        }
        json payload = formPayload;
        string eventType = (check payload.MessageStatus).toString();
        http:Response ackResponse = new;
        ackResponse.statusCode = http:STATUS_OK;
        check caller->respond(ackResponse);
        boolean|error dispatchResult = self.matchRemoteFuncForSmsStatus(payload, eventType);
        if dispatchResult is error {
            log:printError("DISPATCH_FAILED", dispatchResult);
        } else if !dispatchResult {
            log:printWarn("NO_HANDLER_FOR_EVENT", eventIdentifier = eventType);
        }
    }

    private isolated function verifyWebhookSignature(http:Request request, string? webhookSecret) returns error? {
        if webhookSecret is () {
            return error("Unauthorized: Webhook Secret Not Configured");
        }
        if !request.hasHeader("X-Twilio-Signature") {
            return error("Unauthorized: Missing Signature Header");
        }
        string receivedHeader = check request.getHeader("X-Twilio-Signature");
        map<string> extractedHeaderValues = {};
        int headerCursor = 0;
        extractedHeaderValues["signature"] = receivedHeader.substring(headerCursor);
        headerCursor = receivedHeader.length();
        if !extractedHeaderValues.hasKey("signature") {
            return error("Unauthorized: Missing Header Component: signature");
        }
        string payloadToHash = string `${self.webhookBaseUrl}${request.rawPath}${self.sortedFormParams(check request.getFormParams())}`;
        byte[] computedDigest = check crypto:hmacSha1(payloadToHash.toBytes(), webhookSecret.toBytes());
        string computedSignature = computedDigest.toBase64();
        string expectedHeader = string `${computedSignature}`;
        if !crypto:equalConstantTime(receivedHeader.toBytes(), expectedHeader.toBytes()) {
            return error("Unauthorized: Signature Mismatch");
        }
    }

    private isolated function sortedFormParams(map<string> params) returns string {
        string[] names = params.keys().sort();
        string sorted = "";
        foreach string name in names {
            sorted += name + params.get(name);
        }
        return sorted;
    }

    private isolated function matchRemoteFuncForCallStatus(json payload, string eventIdentifier) returns boolean|error {
        match eventIdentifier {
            "initiated" => {
                check self.executeRemoteFunc(payload, "initiated", "CallStatusService", "onInitiated");
                return true;
            }
            "queued" => {
                check self.executeRemoteFunc(payload, "queued", "CallStatusService", "onQueued");
                return true;
            }
            "ringing" => {
                check self.executeRemoteFunc(payload, "ringing", "CallStatusService", "onRinging");
                return true;
            }
            "in-progress" => {
                check self.executeRemoteFunc(payload, "in-progress", "CallStatusService", "onInProgress");
                return true;
            }
            "completed" => {
                check self.executeRemoteFunc(payload, "completed", "CallStatusService", "onCompleted");
                return true;
            }
            "busy" => {
                check self.executeRemoteFunc(payload, "busy", "CallStatusService", "onBusy");
                return true;
            }
            "failed" => {
                check self.executeRemoteFunc(payload, "failed", "CallStatusService", "onFailed");
                return true;
            }
            "no-answer" => {
                check self.executeRemoteFunc(payload, "no-answer", "CallStatusService", "onNoAnswer");
                return true;
            }
            "canceled" => {
                check self.executeRemoteFunc(payload, "canceled", "CallStatusService", "onCanceled");
                return true;
            }
        }
        return false;
    }

    private isolated function matchRemoteFuncForSmsStatus(json payload, string eventIdentifier) returns boolean|error {
        match eventIdentifier {
            "accepted" => {
                check self.executeRemoteFunc(payload, "accepted", "SmsStatusService", "onAccepted");
                return true;
            }
            "queued" => {
                check self.executeRemoteFunc(payload, "queued", "SmsStatusService", "onQueued");
                return true;
            }
            "sending" => {
                check self.executeRemoteFunc(payload, "sending", "SmsStatusService", "onSending");
                return true;
            }
            "sent" => {
                check self.executeRemoteFunc(payload, "sent", "SmsStatusService", "onSent");
                return true;
            }
            "failed" => {
                check self.executeRemoteFunc(payload, "failed", "SmsStatusService", "onFailed");
                return true;
            }
            "delivered" => {
                check self.executeRemoteFunc(payload, "delivered", "SmsStatusService", "onDelivered");
                return true;
            }
            "undelivered" => {
                check self.executeRemoteFunc(payload, "undelivered", "SmsStatusService", "onUndelivered");
                return true;
            }
            "receiving" => {
                check self.executeRemoteFunc(payload, "receiving", "SmsStatusService", "onReceiving");
                return true;
            }
            "received" => {
                check self.executeRemoteFunc(payload, "received", "SmsStatusService", "onReceived");
                return true;
            }
            "scheduled" => {
                check self.executeRemoteFunc(payload, "scheduled", "SmsStatusService", "onScheduled");
                return true;
            }
            "read" => {
                check self.executeRemoteFunc(payload, "read", "SmsStatusService", "onRead");
                return true;
            }
            "canceled" => {
                check self.executeRemoteFunc(payload, "canceled", "SmsStatusService", "onCanceled");
                return true;
            }
            "partially_delivered" => {
                check self.executeRemoteFunc(payload, "partially_delivered", "SmsStatusService", "onPartiallyDelivered");
                return true;
            }
        }
        return false;
    }

    private isolated function executeRemoteFunc(json payload, string eventName, string serviceTypeStr, string eventFunction) returns error? {
        GenericServiceType? genericService = self.services[serviceTypeStr];
        if genericService is GenericServiceType {
            any boundEvent = check self.nativeHandler.bindEventPayload(genericService, eventFunction, payload);
            check self.nativeHandler.invokeRemoteFunction(boundEvent, eventName, eventFunction, genericService);
        } else {
            log:printDebug("SERVICE_NOT_ATTACHED", serviceType = serviceTypeStr, eventName = eventName);
        }
    }
}
