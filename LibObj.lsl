/*
LibObj - A library to manage state in LSL using an object-oriented approach.
Library Version 1.0, Tests Version 1.0

MIT License

Copyright (c) 2015 Ochi Wolfe

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

// ===== LibObj Base =====

list _objectIds;

integer objNew() {
    integer id;
    do {id = 1 + llFloor(llFrand(0x10000));}
    while (~llListFindList(_objectIds, [id]));
    _objectIds += [id];
    return id;
}

objDelete(integer id) {
    integer idx = llListFindList(_objectIds, [id]);
    if (!~idx) return;
    _objectIds = llDeleteSubList(_objectIds, idx, idx);
    
    // Extensions
    objSetName(id, ""); // Name extension
    objSetPath(id, []); // Path extension
    objSetData(id, ""); // Data extension
    objSetProp(id, "", ""); // Properties extension
    objSetParent(id, 0); // Hierarchy extension
    while (idx = objGetChild(id)) objSetParent(idx, 0); // Hierarchy extension
    objSetTimeout(id, 0); // Timeout extension
}

// ===== LibObj Names Extension =====

list _objectNames;

integer objSetName(integer id, string name) {
    integer idx = llListFindList(_objectNames, [id]);
    if (~idx) _objectNames = llDeleteSubList(_objectNames, idx, idx+1);
    if (id > 0 && name != "") _objectNames += [id, name];
    return id;
}

string objGetName(integer id) {
    integer idx = llListFindList(_objectNames, [id]);
    if (~idx) return llList2String(_objectNames, idx+1);
    return "";
}

integer objByName(string name) {
    integer idx = llListFindList(_objectNames, [name]);
    if (~idx) return llList2Integer(_objectNames, idx-1);
    return 0;
}

// ===== LibObj Paths Extension =====

list _objectPaths;

integer objSetPath(integer id, list path) {
    integer idx = llListFindList(_objectPaths, [id]);
    if (~idx) _objectPaths = llDeleteSubList(_objectPaths, idx, idx+2-llList2Integer(_objectPaths, idx+1));
    if (id > 0 && path != []) {
        path = llParseStringKeepNulls(llDumpList2String(path, "\n"), ["\n"], []);
        _objectPaths += [id, -llGetListLength(path), 0.0 /*path begin marker*/] + path;
    }
    return id;
}

list objGetPath(integer id) {
    integer idx = llListFindList(_objectPaths, [id]);
    if (~idx) return llList2List(_objectPaths, idx+3, idx+3-llList2Integer(_objectPaths, idx+1));
    return [];
}

string objGetPathItem(integer id, integer item) {
    integer idx = llListFindList(_objectPaths, [id]);
    if (~idx) return llList2String(_objectPaths, idx+3+item);
    return "";
}

integer objByPath(list path) {
    path = llParseStringKeepNulls(llDumpList2String(path, "\n"), ["\n"], []);
    integer idx = llListFindList(_objectPaths, [0.0] + path);
    if (~idx) return llList2Integer(_objectPaths, idx-2);
    return 0;
}

// ===== LibObj Data Extension =====

list _objectData;

integer objSetData(integer id, string data) {
    integer idx = llListFindList(_objectData, [id]);
    if (~idx) _objectData = llDeleteSubList(_objectData, idx, idx+1);
    if (id > 0 && data != "") _objectData += [id, data];
    return id;
}

string objGetData(integer id) {
    integer idx = llListFindList(_objectData, [id]);
    if (~idx) return llList2String(_objectData, idx+1);
    return "";
}

// ===== LibObj Properties Extension =====

list _objectProperties;

integer objSetProp(integer id, string prop, string data) {
    list search = [id]; if (prop != "") search += [prop];
    integer idx;
    while (~(idx = llListFindList(_objectProperties, search)))
        _objectProperties = llDeleteSubList(_objectProperties, idx, idx+2);
    if (id > 0 && data != "") _objectProperties += [id, prop, data];
    return id;
}

string objGetProp(integer id, string prop) {
    integer idx = llListFindList(_objectProperties, [id, prop]);
    if (~idx) return llList2String(_objectProperties, idx+2);
    return "";
}

// ===== LibObj Hierarchy Extension =====

list _objectHierarchy;

integer objSetParent(integer id, integer parent) {
    integer idx = llListFindList(_objectHierarchy, [id]);
    if (~idx) _objectHierarchy = llDeleteSubList(_objectHierarchy, idx, idx+1);
    if (id > 0 && parent > 0) _objectHierarchy += [id, -parent];
    return id;
}

integer objGetParent(integer id) {
    integer idx = llListFindList(_objectHierarchy, [id]);
    if (~idx) return -llList2Integer(_objectHierarchy, idx+1);
    return 0;
}

integer objGetChild(integer id) {
    integer idx = llListFindList(_objectHierarchy, [-id]);
    if (~idx) return llList2Integer(_objectHierarchy, idx-1);
    return 0;
}

list objGetChildren(integer id) {
    list children;
    integer len = llGetListLength(_objectHierarchy);
    integer i;
    for (i = 0; i < len; i += 2)
        if (-llList2Integer(_objectHierarchy, i+1) == id)
            children += [llList2Integer(_objectHierarchy, i)];
    return children;
}

// ===== LibObj Timeout Extension =====

list _objectTimeouts;
integer _timeoutDue;

integer objSetTimeout(integer id, integer time) {
    integer idx = llListFindList(_objectTimeouts, [id]);
    if (~idx) _objectTimeouts = llDeleteSubList(_objectTimeouts, idx-1, idx);
    if (id > 0 && time > 0) _objectTimeouts = llListSort(_objectTimeouts + [-llGetUnixTime()-time, id], 2, FALSE);
    objCheckTimeout();
    return id;
}

integer objCheckTimeout() {
    if (_objectTimeouts == []) {
        llSetTimerEvent(0.0);
        _timeoutDue = FALSE;
        return 0;
    }
    integer diff = -llGetUnixTime()-llList2Integer(_objectTimeouts, 0);
    if (diff > 0) {
        llSetTimerEvent(diff);
        _timeoutDue = FALSE;
        return 0;
    }
    if (!_timeoutDue) {
        llSetTimerEvent(1.0);
        _timeoutDue = TRUE;
    }
    return llList2Integer(_objectTimeouts, 1);
}

// ===== LibObj Debug =====

objDebug() {
    string s = "\n";
    s += "Ids: "  + llDumpList2String(_objectIds,        ", ") + "\n";
    s += "Name: " + llDumpList2String(_objectNames,      ", ") + "\n";
    s += "Path: " + llDumpList2String(_objectPaths,      ", ") + "\n";
    s += "Data: " + llDumpList2String(_objectData,       ", ") + "\n";
    s += "Prop: " + llDumpList2String(_objectProperties, ", ") + "\n";
    s += "Hier: " + llDumpList2String(_objectHierarchy,  ", ") + "\n";
    s += "Time: " + llDumpList2String(_objectTimeouts,   ", ") + "\n";
    s += (string)llGetFreeMemory();
    llSetText(s, <1.0, 1.0, 1.0>, 1.0);
}

// ===== End of LibObj =====

test(string label, integer pred) {
    objDebug();
    if (!pred) llOwnerSay("TEST FAILED: " + label);
}

default {
    state_entry() {
        llOwnerSay("Running tests...");
        
        // Base
        
        integer a = objNew();
        integer b = objNew();
        integer c = objNew();
        
        test("Object IDs positive and unique",
            a > 0 &&
            b > 0 &&
            c > 0 &&
            a != b &&
            b != c &&
            a != c
        );
        
        // Names
        
        test("Set name", objSetName(a, "a") == a);
        test("Set name", objSetName(b, "b") == b);
        test("Set name", objSetName(c, "c") == c);
        
        test("Get name",
            objGetName(a) == "a" &&
            objGetName(b) == "b" &&
            objGetName(c) == "c" &&
            objGetName(0) == "" &&
            objGetName(-1) == ""
        );
        
        test("By name",
            a == objByName("a") &&
            b == objByName("b") &&
            c == objByName("c") &&
            0 == objByName("d") // Nonexisting object should return id 0.
        );
        
        objSetName(b, "");
        test("Un-set name",
            0 == objByName("b")
        );
        objSetName(b, "b");
        
        // Paths
        
        test("Set path", objSetPath(a, [0, "A"]) == a);
        test("Set path", objSetPath(b, [0, "A", "B"]) == b);
        test("Set path", objSetPath(c, [1, "A"]) == c);
        
        test("Get path",
            llList2String(objGetPath(b), 0) == "0" &&
            llList2String(objGetPath(b), 1) == "A" &&
            llList2String(objGetPath(b), 2) == "B"
        );
        
        test("Get path item",
            objGetPathItem(b, 0) == "0" &&
            objGetPathItem(b, 1) == "A" &&
            objGetPathItem(b, 2) == "B"
        );
        
        test("By path",
            a == objByPath([0]) &&
            c == objByPath([1]) &&
            a == objByPath([0, "A"]) &&
            c == objByPath([1, "A"]) &&
            b == objByPath([0, "A", "B"]) &&
            0 == objByPath([]) && // Invalid paths should return id 0.
            0 == objByPath(["A"])
        );
        
        objSetPath(a, []);
        objSetPath(b, []);
        objSetPath(c, []);
        
        // Data
        
        test("Set data", objSetData(b, "TestData") == b);
        test("Get data", objGetData(b) == "TestData");
        objSetData(b, "");
        
        // Properties
        
        test("Set prop", objSetProp(a, "A", "0") == a);
        test("Set prop", objSetProp(b, "B", "1") == b);
        
        test("Get prop",
            objGetProp(a, "A") == "0" &&
            objGetProp(b, "B") == "1"
        );
        
        objSetProp(a, "A", "");
        objSetProp(b, "B", "");
        
        // Hierarchy
        
        test("Set parent", objSetParent(b, a) == b);
        test("Set parent", objSetParent(c, a) == c);
        
        test("Get parent",
            objGetParent(b) == a &&
            objGetParent(c) == a
        );
        
        test("Get child", objGetChild(a) == b);
        
        list children = objGetChildren(a);
        test("Get children",
            llList2Integer(children, 0) == b &&
            llList2Integer(children, 1) == c
        );
        
        objSetParent(b, 0);
        objSetParent(c, 0);
        
        // Timeouts
        
        // Should result in timeouts in the order a, b, c.
        objSetTimeout(b, 1);
        objSetTimeout(a, 2);
        objSetTimeout(c, 3);
        objSetTimeout(b, 4);
        objSetTimeout(c, 6);
        
        objDebug();
        
        llOwnerSay("Tests done.");
    }
    
    timer() {
        integer obj;
        while (obj = objCheckTimeout()) {
            llOwnerSay("Timeout for object " + objGetName(obj));
            objDelete(obj);
        }
        objDebug();
    }
}
