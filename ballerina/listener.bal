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

import ballerina/http;

@display {label: "Twilio Events API", iconPath: "icon.png"}
public class Listener {
    private http:Listener httpListener;
    private ListenerConfig listenerConfig;
    private map<DispatcherService> dispatchers = {};
    private [string, GenericServiceType][] attachments = [];

    public function init(ListenerConfig listenerConfig = {}, int|http:Listener listenOn = 8090) returns error? {
        if listenOn is http:Listener {
            self.httpListener = listenOn;
        } else {
            self.httpListener = check new (listenOn);
        }
        self.listenerConfig = listenerConfig;
    }

    public isolated function attach(GenericServiceType serviceRef, string[]|string? attachPoint) returns error? {
        string serviceTypeStr = check self.getServiceTypeStr(serviceRef);
        string path = self.pathKey(attachPoint);
        DispatcherService dispatcher;
        DispatcherService? existing = self.dispatchers[path];
        if existing is DispatcherService {
            dispatcher = existing;
            check dispatcher.addServiceRef(serviceTypeStr, serviceRef);
        } else {
            dispatcher = new (self.listenerConfig.webhookSecret, self.listenerConfig.webhookBaseUrl);
            check dispatcher.addServiceRef(serviceTypeStr, serviceRef);
            check self.httpListener.attach(dispatcher, path == "" ? () : path);
            self.dispatchers[path] = dispatcher;
        }
        self.attachments.push([path, serviceRef]);
    }

    public isolated function detach(GenericServiceType serviceRef) returns error? {
        string serviceTypeStr = check self.getServiceTypeStr(serviceRef);
        boolean detached = false;
        int i = 0;
        while i < self.attachments.length() {
            if self.attachments[i][1] !== serviceRef {
                i += 1;
                continue;
            }
            string path = self.attachments[i][0];
            DispatcherService dispatcher = self.dispatchers.get(path);
            check dispatcher.removeServiceRef(serviceTypeStr);
            _ = self.attachments.remove(i);
            detached = true;
            boolean pathInUse = false;
            foreach [string, GenericServiceType] attachment in self.attachments {
                if attachment[0] == path {
                    pathInUse = true;
                }
            }
            if !pathInUse {
                check self.httpListener.detach(dispatcher);
                _ = self.dispatchers.remove(path);
            }
        }
        if !detached {
            return error(string `Cannot detach the service of type ${serviceTypeStr}. Service has not been attached to the listener before`);
        }
    }

    public isolated function 'start() returns error? {
        return self.httpListener.'start();
    }

    public isolated function gracefulStop() returns error? {
        return self.httpListener.gracefulStop();
    }

    public isolated function immediateStop() returns error? {
        return self.httpListener.immediateStop();
    }

    private isolated function getServiceTypeStr(GenericServiceType serviceRef) returns string|error {
        match serviceRef {
            var v if v is CallStatusService => {
                return "CallStatusService";
            }
            var v if v is SmsStatusService => {
                return "SmsStatusService";
            }
            var _ => {
                return error("Unrecognized service type attached to the listener");
            }
        }
    }

    private isolated function pathKey(string[]|string? attachPoint) returns string {
        if attachPoint is () {
            return "";
        }
        string path = attachPoint is string ? attachPoint : string:'join("/", ...attachPoint);
        while path.startsWith("/") {
            path = path.substring(1);
        }
        while path.endsWith("/") {
            path = path.substring(0, path.length() - 1);
        }
        return path;
    }
}
