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

# Attachable service type exposing the CallStatusService family of webhook events.
public type CallStatusService service object {
    # Triggered on Initiated.
    # + payload - the CallStatusEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onInitiated(CallStatusEventWrapper payload) returns error?;

    # Triggered on Queued.
    # + payload - the CallStatusEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onQueued(CallStatusEventWrapper payload) returns error?;

    # Triggered on Ringing.
    # + payload - the CallStatusEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onRinging(CallStatusEventWrapper payload) returns error?;

    # Triggered on In progress.
    # + payload - the CallStatusEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onInProgress(CallStatusEventWrapper payload) returns error?;

    # Triggered on Completed.
    # + payload - the CallStatusEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onCompleted(CallStatusEventWrapper payload) returns error?;

    # Triggered on Busy.
    # + payload - the CallStatusEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onBusy(CallStatusEventWrapper payload) returns error?;

    # Triggered on Failed.
    # + payload - the CallStatusEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onFailed(CallStatusEventWrapper payload) returns error?;

    # Triggered on No answer.
    # + payload - the CallStatusEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onNoAnswer(CallStatusEventWrapper payload) returns error?;

    # Triggered on Canceled.
    # + payload - the CallStatusEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onCanceled(CallStatusEventWrapper payload) returns error?;
};

# Attachable service type exposing the SmsStatusService family of webhook events.
public type SmsStatusService service object {
    # Triggered on Accepted.
    # + payload - the SmsStatusChangeEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onAccepted(SmsStatusChangeEventWrapper payload) returns error?;

    # Triggered on Queued.
    # + payload - the SmsStatusChangeEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onQueued(SmsStatusChangeEventWrapper payload) returns error?;

    # Triggered on Sending.
    # + payload - the SmsStatusChangeEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onSending(SmsStatusChangeEventWrapper payload) returns error?;

    # Triggered on Sent.
    # + payload - the SmsStatusChangeEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onSent(SmsStatusChangeEventWrapper payload) returns error?;

    # Triggered on Failed.
    # + payload - the SmsStatusChangeEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onFailed(SmsStatusChangeEventWrapper payload) returns error?;

    # Triggered on Delivered.
    # + payload - the SmsStatusChangeEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onDelivered(SmsStatusChangeEventWrapper payload) returns error?;

    # Triggered on Undelivered.
    # + payload - the SmsStatusChangeEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onUndelivered(SmsStatusChangeEventWrapper payload) returns error?;

    # Triggered on Receiving.
    # + payload - the SmsStatusChangeEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onReceiving(SmsStatusChangeEventWrapper payload) returns error?;

    # Triggered on Received.
    # + payload - the SmsStatusChangeEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onReceived(SmsStatusChangeEventWrapper payload) returns error?;

    # Triggered on Scheduled.
    # + payload - the SmsStatusChangeEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onScheduled(SmsStatusChangeEventWrapper payload) returns error?;

    # Triggered on Read.
    # + payload - the SmsStatusChangeEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onRead(SmsStatusChangeEventWrapper payload) returns error?;

    # Triggered on Canceled.
    # + payload - the SmsStatusChangeEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onCanceled(SmsStatusChangeEventWrapper payload) returns error?;

    # Triggered on Partially delivered.
    # + payload - the SmsStatusChangeEventWrapper webhook payload
    # + return - an error if handling the event fails
    remote function onPartiallyDelivered(SmsStatusChangeEventWrapper payload) returns error?;
};

# The union of every service type that can be attached to this listener.
public type GenericServiceType CallStatusService|SmsStatusService;

