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

This version of the script uses the object "hierarchy" extension of LibObj to
manage multiple user sessions. When a new session is requested, the script
checks whether an object with the name "listen" exists. If not, it is created,
the listen is started and its handle is stored in the listen object. The name of
the session object is set to the user's UUID. The new user session is added as a
child to the listen object. Each time a session is destroyed, a check is performed
whether the listen object has any children left. If not, the listen is stopped
and the listen object is deleted.

Warning: Dialog input is not checked very well and the script uses a hard-coded
listen channel, but it should suffice for the purpose of this demo script.
*/

// Constants

string ENGLISH = "Please enter a number.\n\nCurrent number: ";
string GERMAN  = "Bitte gebe eine Zahl ein.\n\nAktuelle Zahl: ";
list   BUTTONS = ["Lang./Sprache", "0", "OK", "1", "2", "3", "4", "5", "6", "7", "8", "9"];

// Functions

dialog(integer sessionObj) {
    key id = objGetName(sessionObj);
    integer inMainMenu = (integer)objGetProp(sessionObj, "main");
    
    if (inMainMenu) {
        string lang = objGetProp(sessionObj, "lang");
        integer number = (integer)objGetProp(sessionObj, "number");
        string msg = ENGLISH; if (lang == "Deutsch") msg = GERMAN;
        llDialog(id, msg + (string)number, BUTTONS, -234);
    } else { // In language menu.
        llDialog(id, "Please choose a language.\nBitte wähle eine Sprache.", ["English", "Deutsch"], -234);
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
        integer sessionObj = objByName(id);
        
        // If there exists no session for this user, create one.
        if (!sessionObj) {
            // If there are no sessions yet, start listen.
            integer listenObj = objByName("listen");
            if (!listenObj) {
                llWhisper(0, "No sessions yet, starting listen.");
                
                // Create and initialize listen object.
                listenObj = objNew();
                integer listenHandle = llListen(-234, "", NULL_KEY, "");
                objSetProp(listenObj, "handle", (string)listenHandle);
            }
            
            llWhisper(0, "Creating new session for " + llKey2Name(id) + ".");
            
            // Create and initialize session object.
            sessionObj = objNew();
            objSetName(sessionObj, id);
            objSetProp(sessionObj, "number", (string)0);
            objSetProp(sessionObj, "lang", "English");
            objSetProp(sessionObj, "main", (string)TRUE);
            
            objSetParent(sessionObj, listenObj);
        }
        
        dialog(sessionObj);
    }
    
    listen(integer channel, string name, key id, string message) {
        // Try to get the session object for this user.
        integer sessionObj = objByName(id);
        
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
            llWhisper(0, "Destroying session for " + llKey2Name(objGetName(sessionObj)) + ".");
            
            // Get listen object (parent of session).
            integer listenObj = objGetParent(sessionObj);
            
            // Delete the session object and associated data.
            objDelete(sessionObj);
            
            // If no session objects (i.e. children of the listen object) are left, stop listen.
            if (!objGetChild(listenObj)) {
                llWhisper(0, "No sessions left, removing listen.");
                integer listenHandle = (integer)objGetProp(listenObj, "handle");
                llListenRemove(listenHandle);
                objDelete(listenObj);
            }
        }
    }
}
