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
import ballerina/io;
import ballerina/lang.runtime;
import ballerina/test;
import ballerina/url;

const TRIGGER_TEST_SECRET = "trigger-test-secret";
const TRIGGER_TEST_PORT = 9091;
const TRIGGER_PAYLOAD_DIR = "tests/resources/trigger_payloads";
const TRIGGER_TEST_WEBHOOK_BASE_URL = "test-webhookBaseUrl-value";

isolated map<boolean> triggerFired = {};
isolated map<json> boundPayloads = {};

listener Listener triggerTestListener = check new ({webhookSecret: TRIGGER_TEST_SECRET, webhookBaseUrl: TRIGGER_TEST_WEBHOOK_BASE_URL}, TRIGGER_TEST_PORT);

final http:Client triggerClient = check new (string `http://localhost:${TRIGGER_TEST_PORT}`);

service CallStatusService on triggerTestListener {
    isolated remote function onInitiated(CallStatusEventWrapper payload) returns error? {
        lock {
            triggerFired["CallStatusService.onInitiated"] = true;
        }
    }

    isolated remote function onQueued(CallStatusEventWrapper payload) returns error? {
        lock {
            triggerFired["CallStatusService.onQueued"] = true;
        }
    }

    isolated remote function onRinging(CallStatusEventWrapper payload) returns error? {
        lock {
            triggerFired["CallStatusService.onRinging"] = true;
        }
    }

    isolated remote function onInProgress(CallStatusEventWrapper payload) returns error? {
        lock {
            triggerFired["CallStatusService.onInProgress"] = true;
        }
    }

    isolated remote function onCompleted(CallStatusEventWrapper payload) returns error? {
        lock {
            triggerFired["CallStatusService.onCompleted"] = true;
        }
    }

    isolated remote function onBusy(CallStatusEventWrapper payload) returns error? {
        lock {
            triggerFired["CallStatusService.onBusy"] = true;
        }
    }

    isolated remote function onFailed(CallStatusEventWrapper payload) returns error? {
        lock {
            triggerFired["CallStatusService.onFailed"] = true;
        }
    }

    isolated remote function onNoAnswer(CallStatusEventWrapper payload) returns error? {
        lock {
            triggerFired["CallStatusService.onNoAnswer"] = true;
        }
    }

    isolated remote function onCanceled(CallStatusEventWrapper payload) returns error? {
        lock {
            triggerFired["CallStatusService.onCanceled"] = true;
        }
    }
}

service SmsStatusService on triggerTestListener {
    isolated remote function onAccepted(SmsStatusChangeEventWrapper payload) returns error? {
        lock {
            triggerFired["SmsStatusService.onAccepted"] = true;
        }
    }

    isolated remote function onQueued(SmsStatusChangeEventWrapper payload) returns error? {
        lock {
            triggerFired["SmsStatusService.onQueued"] = true;
        }
    }

    isolated remote function onSending(SmsStatusChangeEventWrapper payload) returns error? {
        lock {
            triggerFired["SmsStatusService.onSending"] = true;
        }
    }

    isolated remote function onSent(SmsStatusChangeEventWrapper payload) returns error? {
        lock {
            triggerFired["SmsStatusService.onSent"] = true;
        }
    }

    isolated remote function onFailed(SmsStatusChangeEventWrapper payload) returns error? {
        lock {
            triggerFired["SmsStatusService.onFailed"] = true;
        }
    }

    isolated remote function onDelivered(SmsStatusChangeEventWrapper payload) returns error? {
        lock {
            triggerFired["SmsStatusService.onDelivered"] = true;
        }
    }

    isolated remote function onUndelivered(SmsStatusChangeEventWrapper payload) returns error? {
        lock {
            triggerFired["SmsStatusService.onUndelivered"] = true;
        }
    }

    isolated remote function onReceiving(SmsStatusChangeEventWrapper payload) returns error? {
        lock {
            triggerFired["SmsStatusService.onReceiving"] = true;
        }
    }

    isolated remote function onReceived(SmsStatusChangeEventWrapper payload) returns error? {
        lock {
            triggerFired["SmsStatusService.onReceived"] = true;
        }
    }

    isolated remote function onScheduled(SmsStatusChangeEventWrapper payload) returns error? {
        lock {
            triggerFired["SmsStatusService.onScheduled"] = true;
        }
    }

    isolated remote function onRead(SmsStatusChangeEventWrapper payload) returns error? {
        lock {
            triggerFired["SmsStatusService.onRead"] = true;
        }
    }

    isolated remote function onCanceled(SmsStatusChangeEventWrapper payload) returns error? {
        lock {
            triggerFired["SmsStatusService.onCanceled"] = true;
        }
    }

    isolated remote function onPartiallyDelivered(SmsStatusChangeEventWrapper payload) returns error? {
        lock {
            triggerFired["SmsStatusService.onPartiallyDelivered"] = true;
        }
    }
}

isolated function sendSignedTriggerWebhook(string path, string fixtureName, map<string> identifierHeaders) returns http:Response|error {
    json fixture = check io:fileReadJson(string `${TRIGGER_PAYLOAD_DIR}/${fixtureName}.json`);
    map<json> fields = check fixture.ensureType();
    map<string> params = {};
    foreach var [name, value] in fields.entries() {
        params[name] = value.toString();
    }
    string[] encodedPairs = [];
    foreach var [name, value] in params.entries() {
        encodedPairs.push(check url:encode(name, "UTF-8") + "=" + check url:encode(value, "UTF-8"));
    }
    string bodyText = string:'join("&", ...encodedPairs);
    byte[] body = bodyText.toBytes();
    string formParamsText = "";
    foreach string name in params.keys().sort() {
        formParamsText += name + params.get(name);
    }
    string payloadToHash = string `${TRIGGER_TEST_WEBHOOK_BASE_URL}${path}${formParamsText}`;
    byte[] computedDigest = check crypto:hmacSha1(payloadToHash.toBytes(), TRIGGER_TEST_SECRET.toBytes());
    string computedSignature = computedDigest.toBase64();
    map<string> headers = {
        "X-Twilio-Signature": string `${computedSignature}`
    };
    foreach var [name, value] in identifierHeaders.entries() {
        headers[name] = value;
    }
    return triggerClient->post(path, body, headers, "application/x-www-form-urlencoded");
}

function waitForDispatch(string trackerKey) returns boolean {
    foreach int i in 0 ..< 20 {
        lock {
            if triggerFired[trackerKey] ?: false {
                return true;
            }
        }
        runtime:sleep(0.05);
    }
    return false;
}

@test:Config {}
function testCallStatusServiceInitiatedDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/callStatus", "callStatus/initiated", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("CallStatusService.onInitiated"), "CallStatusService.onInitiated should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["CallStatusService.onInitiated"], "Only CallStatusService.onInitiated should have fired");
    }
}

@test:Config {}
function testCallStatusServiceQueuedDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/callStatus", "callStatus/queued", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("CallStatusService.onQueued"), "CallStatusService.onQueued should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["CallStatusService.onQueued"], "Only CallStatusService.onQueued should have fired");
    }
}

@test:Config {}
function testCallStatusServiceRingingDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/callStatus", "callStatus/ringing", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("CallStatusService.onRinging"), "CallStatusService.onRinging should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["CallStatusService.onRinging"], "Only CallStatusService.onRinging should have fired");
    }
}

@test:Config {}
function testCallStatusServiceInProgressDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/callStatus", "callStatus/in-progress", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("CallStatusService.onInProgress"), "CallStatusService.onInProgress should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["CallStatusService.onInProgress"], "Only CallStatusService.onInProgress should have fired");
    }
}

@test:Config {}
function testCallStatusServiceCompletedDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/callStatus", "callStatus/completed", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("CallStatusService.onCompleted"), "CallStatusService.onCompleted should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["CallStatusService.onCompleted"], "Only CallStatusService.onCompleted should have fired");
    }
}

@test:Config {}
function testCallStatusServiceBusyDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/callStatus", "callStatus/busy", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("CallStatusService.onBusy"), "CallStatusService.onBusy should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["CallStatusService.onBusy"], "Only CallStatusService.onBusy should have fired");
    }
}

@test:Config {}
function testCallStatusServiceFailedDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/callStatus", "callStatus/failed", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("CallStatusService.onFailed"), "CallStatusService.onFailed should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["CallStatusService.onFailed"], "Only CallStatusService.onFailed should have fired");
    }
}

@test:Config {}
function testCallStatusServiceNoAnswerDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/callStatus", "callStatus/no-answer", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("CallStatusService.onNoAnswer"), "CallStatusService.onNoAnswer should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["CallStatusService.onNoAnswer"], "Only CallStatusService.onNoAnswer should have fired");
    }
}

@test:Config {}
function testCallStatusServiceCanceledDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/callStatus", "callStatus/canceled", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("CallStatusService.onCanceled"), "CallStatusService.onCanceled should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["CallStatusService.onCanceled"], "Only CallStatusService.onCanceled should have fired");
    }
}

@test:Config {}
function testSmsStatusServiceAcceptedDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/smsStatus", "smsStatus/accepted", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("SmsStatusService.onAccepted"), "SmsStatusService.onAccepted should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["SmsStatusService.onAccepted"], "Only SmsStatusService.onAccepted should have fired");
    }
}

@test:Config {}
function testSmsStatusServiceQueuedDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/smsStatus", "smsStatus/queued", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("SmsStatusService.onQueued"), "SmsStatusService.onQueued should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["SmsStatusService.onQueued"], "Only SmsStatusService.onQueued should have fired");
    }
}

@test:Config {}
function testSmsStatusServiceSendingDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/smsStatus", "smsStatus/sending", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("SmsStatusService.onSending"), "SmsStatusService.onSending should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["SmsStatusService.onSending"], "Only SmsStatusService.onSending should have fired");
    }
}

@test:Config {}
function testSmsStatusServiceSentDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/smsStatus", "smsStatus/sent", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("SmsStatusService.onSent"), "SmsStatusService.onSent should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["SmsStatusService.onSent"], "Only SmsStatusService.onSent should have fired");
    }
}

@test:Config {}
function testSmsStatusServiceFailedDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/smsStatus", "smsStatus/failed", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("SmsStatusService.onFailed"), "SmsStatusService.onFailed should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["SmsStatusService.onFailed"], "Only SmsStatusService.onFailed should have fired");
    }
}

@test:Config {}
function testSmsStatusServiceDeliveredDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/smsStatus", "smsStatus/delivered", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("SmsStatusService.onDelivered"), "SmsStatusService.onDelivered should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["SmsStatusService.onDelivered"], "Only SmsStatusService.onDelivered should have fired");
    }
}

@test:Config {}
function testSmsStatusServiceUndeliveredDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/smsStatus", "smsStatus/undelivered", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("SmsStatusService.onUndelivered"), "SmsStatusService.onUndelivered should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["SmsStatusService.onUndelivered"], "Only SmsStatusService.onUndelivered should have fired");
    }
}

@test:Config {}
function testSmsStatusServiceReceivingDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/smsStatus", "smsStatus/receiving", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("SmsStatusService.onReceiving"), "SmsStatusService.onReceiving should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["SmsStatusService.onReceiving"], "Only SmsStatusService.onReceiving should have fired");
    }
}

@test:Config {}
function testSmsStatusServiceReceivedDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/smsStatus", "smsStatus/received", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("SmsStatusService.onReceived"), "SmsStatusService.onReceived should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["SmsStatusService.onReceived"], "Only SmsStatusService.onReceived should have fired");
    }
}

@test:Config {}
function testSmsStatusServiceScheduledDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/smsStatus", "smsStatus/scheduled", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("SmsStatusService.onScheduled"), "SmsStatusService.onScheduled should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["SmsStatusService.onScheduled"], "Only SmsStatusService.onScheduled should have fired");
    }
}

@test:Config {}
function testSmsStatusServiceReadDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/smsStatus", "smsStatus/read", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("SmsStatusService.onRead"), "SmsStatusService.onRead should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["SmsStatusService.onRead"], "Only SmsStatusService.onRead should have fired");
    }
}

@test:Config {}
function testSmsStatusServiceCanceledDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/smsStatus", "smsStatus/canceled", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("SmsStatusService.onCanceled"), "SmsStatusService.onCanceled should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["SmsStatusService.onCanceled"], "Only SmsStatusService.onCanceled should have fired");
    }
}

@test:Config {}
function testSmsStatusServicePartiallyDeliveredDispatch() returns error? {
    lock {
        triggerFired.removeAll();
    }
    http:Response response = check sendSignedTriggerWebhook("/smsStatus", "smsStatus/partially_delivered", {});
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertTrue(waitForDispatch("SmsStatusService.onPartiallyDelivered"), "SmsStatusService.onPartiallyDelivered should have fired");
    lock {
        test:assertEquals(triggerFired.keys(), ["SmsStatusService.onPartiallyDelivered"], "Only SmsStatusService.onPartiallyDelivered should have fired");
    }
}

