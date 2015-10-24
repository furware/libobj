/*
INSERT THE LibObj CODE HERE.
*/

/*
Dialog handling example for LibObj.
This script is in the public domain.

This script demonstrates how to manage multiple dialog users simultaneously.
Each user may enter a number using a dialog in a digit-by-digit manner.
Once a user chooses "OK", the script says the user's name and entered number.
Additionally, a user may choose between different languages in a separate dialog.
This preference is kept until the session for a user times out due to inactivity.

This version of the script uses the "path" extension of LibObj to manage user
sessions by objects with the common prefix ["session"]. This is used as an
indicator when to start and stop the listen: If a new session is created and
there exists no object with the common prefix, the listen is started. When a
session is destroyed and no object with the prefix is left, the listen is stopped.

Warning: Dialog input is not checked very well and the script uses a hard-coded
listen channel, but it should suffice for the purpose of this demo script.
*/

// Constants

string ENGLISH = "Please enter a number.\n\nCurrent number: ";
string GERMAN  = "Bitte gebe eine Zahl ein.\n\nAktuelle Zahl: ";
list   BUTTONS = ["Lang./Sprache", "0", "OK", "1", "2", "3", "4", "5", "6", "7", "8", "9"];

// Variables

integer listenHandle;

// Functions

dialog(integer sessionObj) {
    key id = objGetPathItem(sessionObj, 1);
    integer inMainMenu = (integer)objGetProp(sessionObj, "main");
    
    if (inMainMenu) {
        string lang = objGetProp(sessionObj, "lang");
        integer number = (integer)objGetProp(sessionObj, "number");
        string msg = ENGLISH; if (lang == "Deutsch") msg = GERMAN;
        llDialog(id, msg + (string)number, BUTTONS, -123);
    } else { // In language menu.
        llDialog(id, "Please choose a language.\nBitte wähle eine Sprache.", ["English", "Deutsch"], -123);
    }
    
    // Set or prolong timeout for this session.
    objSetTimeout(sessionObj, 60);
}

// States

default {
    state_entry() {
        llSetText("Touch me to enter a number.\nKlicke um eine Zahl einzugeben.", <1,1,1>, 1);
        llOwnerSay("Started.");
    }
    
    touch_start(integer n) {
        // UUID of the agent who is touching.
        key id = llDetectedKey(0);
        
        // Try to get the session object for this user.
        integer sessionObj = objByPath(["session", id]);
        
        // If there exists no session for this user, create one.
        if (!sessionObj) {
            // If there are no sessions yet, start listen.
            if (!objByPath(["session"])) {
                llWhisper(0, "No sessions yet, starting listen.");
                
                listenHandle = llListen(-123, "", NULL_KEY, "");
            }
            
            llWhisper(0, "Creating new session for " + llKey2Name(id) + ".");
            
            // Create and initialize session object.
            sessionObj = objNew();
            objSetPath(sessionObj, ["session", id]);
            objSetProp(sessionObj, "number", (string)0);
            objSetProp(sessionObj, "lang", "English");
            objSetProp(sessionObj, "main", (string)TRUE);
        }
        
        dialog(sessionObj);
    }
    
    listen(integer channel, string name, key id, string message) {
        // Try to get the session object for this user.
        integer sessionObj = objByPath(["session", id]);
        
        // If there is no such session, ignore.
        if (!sessionObj) return;
        
        integer inMainMenu = (integer)objGetProp(sessionObj, "main");
        
        if (inMainMenu) {
            if (message == "Lang./Sprache") {
                // Switch to language dialog.
                objSetProp(sessionObj, "main", (string)FALSE);
            } else if (message == "OK") {
                llSay(0, llKey2Name(id) + " entered number " + objGetProp(sessionObj, "number") + ".");
                
                // Reset number and postpone timeout.
                objSetProp(sessionObj, "number", (string)0);
                objSetTimeout(sessionObj, 60);
                
                return;
            } else { // Message is assumed to be a digit.
                // Append digit to number.
                integer number = (integer)objGetProp(sessionObj, "number");
                objSetProp(sessionObj, "number", (string)(10 * number + (integer)message));
            }
        } else { // In language menu.
            // Set language preference and switch back to main menu.
            objSetProp(sessionObj, "lang", message);
            objSetProp(sessionObj, "main", (string)TRUE);
        }
        
        dialog(sessionObj);
    }
    
    timer() {
        integer sessionObj;
        while (sessionObj = objCheckTimeout()) {
            llWhisper(0, "Destroying session for " + llKey2Name(objGetPathItem(sessionObj, 1)) + ".");
            
            // Delete the session object and associated data.
            objDelete(sessionObj);
            
            // If no session objects (i.e. objects with prefix ["session"]) are left, stop listen.
            if (!objByPath(["session"])) {
                llWhisper(0, "No sessions left, removing listen.");
                llListenRemove(listenHandle);
            }
        }
    }
}
