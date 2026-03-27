#import <Foundation/Foundation.h>
#import <objc/message.h>
#include <dlfcn.h>

static id send0(id object, const char *selectorName) {
    return ((id(*)(id, SEL))objc_msgSend)(object, sel_registerName(selectorName));
}

static id send1(id object, const char *selectorName, id arg1) {
    return ((id(*)(id, SEL, id))objc_msgSend)(object, sel_registerName(selectorName), arg1);
}

static id send2(id object, const char *selectorName, id arg1, id arg2) {
    return ((id(*)(id, SEL, id, id))objc_msgSend)(object, sel_registerName(selectorName), arg1, arg2);
}

static void sendVoid1(id object, const char *selectorName, id arg1) {
    ((void(*)(id, SEL, id))objc_msgSend)(object, sel_registerName(selectorName), arg1);
}

static void sendVoidInteger(id object, const char *selectorName, NSInteger value) {
    ((void(*)(id, SEL, NSInteger))objc_msgSend)(object, sel_registerName(selectorName), value);
}

static void sendVoidBool(id object, const char *selectorName, BOOL value) {
    ((void(*)(id, SEL, BOOL))objc_msgSend)(object, sel_registerName(selectorName), value);
}

static BOOL sendBool0(id object, const char *selectorName) {
    return ((BOOL(*)(id, SEL))objc_msgSend)(object, sel_registerName(selectorName));
}

static BOOL sendBoolError(id object, const char *selectorName, NSError **error) {
    return ((BOOL(*)(id, SEL, NSError **))objc_msgSend)(object, sel_registerName(selectorName), error);
}

static id sendReminderFetch(id store, id objectID, NSError **error) {
    return ((id(*)(id, SEL, id, NSError **))objc_msgSend)(store, sel_registerName("fetchReminderWithObjectID:error:"), objectID, error);
}

static void fail(NSString *message) {
    fprintf(stderr, "%s\n", message.UTF8String);
    exit(1);
}

static NSString *stringFromObject(id object) {
    if (!object) return nil;
    if ([object isKindOfClass:[NSString class]]) return object;
    if ([object respondsToSelector:@selector(UUIDString)]) return [object UUIDString];
    return [object description];
}

static void printJSON(id object) {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    if (!data) fail([NSString stringWithFormat:@"Failed to encode JSON: %@", error.localizedDescription]);
    fwrite(data.bytes, 1, data.length, stdout);
}

static id reminderStore(void) {
    Class storeClass = objc_getClass("REMStore");
    if (!storeClass) fail(@"REMStore is unavailable");
    return send0((id)storeClass, "new");
}

static id saveRequestForStore(id store) {
    Class saveRequestClass = objc_getClass("REMSaveRequest");
    if (!saveRequestClass) fail(@"REMSaveRequest is unavailable");
    return send1(send0((id)saveRequestClass, "alloc"), "initWithStore:", store);
}

static id objectIDForUUID(NSString *uuidString, NSString *entityName) {
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    if (!uuid) return nil;

    Class objectIDClass = objc_getClass("REMObjectID");
    if (!objectIDClass) fail(@"REMObjectID is unavailable");
    return send2((id)objectIDClass, "objectIDWithUUID:entityName:", uuid, entityName);
}

static id reminderObjectID(NSString *uuidString) {
    return objectIDForUUID(uuidString, @"REMCDReminder");
}

static id fetchReminderByUUID(id store, NSString *uuidString, NSError **error) {
    id objectID = reminderObjectID(uuidString);
    if (!objectID) return nil;
    return sendReminderFetch(store, objectID, error);
}

static id fetchListByUUID(id store, NSString *uuidString, NSError **error) {
    id objectID = objectIDForUUID(uuidString, @"REMCDList");
    if (!objectID) return nil;
    return ((id(*)(id, SEL, id, NSError **))objc_msgSend)(store, sel_registerName("fetchListWithObjectID:error:"), objectID, error);
}

static id fetchedListByName(id store, NSString *targetName) {
    __block NSString *listUUID = nil;

    void (^block)(id) = ^(id list) {
        if (listUUID) return;

        NSString *name = stringFromObject(send0(list, "name"));
        if ([name isEqualToString:targetName]) {
            listUUID = [stringFromObject(send0(send0(list, "objectID"), "uuid")) copy];
        }
    };

    ((void(*)(id, SEL, id))objc_msgSend)(store, sel_registerName("enumerateAllListsWithBlock:"), block);
    if (!listUUID) return nil;

    NSError *error = nil;
    id fetchedList = fetchListByUUID(store, listUUID, &error);
    if (!fetchedList) fail(error ? error.localizedDescription : [NSString stringWithFormat:@"List does not exist: %@", targetName]);
    return fetchedList;
}

static NSString *uuidStringFromReminderObjectID(id objectID) {
    return stringFromObject(send0(objectID, "uuid"));
}

static NSDictionary *metadataForReminder(id store, NSString *uuidString) {
    NSError *error = nil;
    id reminder = fetchReminderByUUID(store, uuidString, &error);
    if (!reminder) {
        NSString *message = error ? error.localizedDescription : [NSString stringWithFormat:@"Reminder not found: %@", uuidString];
        fail(message);
    }

    id parentObjectID = send0(reminder, "parentReminderID");
    id parentReminder = send0(reminder, "parentReminder");
    if (!parentReminder && parentObjectID) {
        parentReminder = sendReminderFetch(store, parentObjectID, &error);
        if (error) fail(error.localizedDescription);
    }

    NSString *parentID = uuidStringFromReminderObjectID(parentObjectID);
    NSString *parentName = stringFromObject(send0(parentReminder, "titleAsString"));

    return @{
        @"id": uuidString,
        @"flagged": @(sendBool0(reminder, "flagged")),
        @"urgent": @(sendBool0(reminder, "isUrgentStateEnabledForCurrentUser")),
        @"parent_id": parentID ?: [NSNull null],
        @"parent_name": parentName ?: [NSNull null],
    };
}

static NSString *priorityLabel(NSInteger priorityValue) {
    switch (priorityValue) {
        case 1: return @"high";
        case 5: return @"medium";
        case 9: return @"low";
        default: return @"none";
    }
}

static NSString *isoStringFromDateComponents(NSDateComponents *components) {
    if (!components) return nil;

    NSInteger year = components.year;
    NSInteger month = components.month;
    NSInteger day = components.day;
    if (year == NSDateComponentUndefined || month == NSDateComponentUndefined || day == NSDateComponentUndefined) return nil;

    NSInteger hour = components.hour == NSDateComponentUndefined ? 0 : components.hour;
    NSInteger minute = components.minute == NSDateComponentUndefined ? 0 : components.minute;
    NSInteger second = components.second == NSDateComponentUndefined ? 0 : components.second;

    return [NSString stringWithFormat:@"%04ld-%02ld-%02ldT%02ld:%02ld:%02ld",
            (long)year, (long)month, (long)day, (long)hour, (long)minute, (long)second];
}

static NSInteger priorityValueFromInput(NSString *input) {
    NSString *normalized = input.lowercaseString;

    if (normalized.length == 0 || [normalized isEqualToString:@"none"] || [normalized isEqualToString:@"0"]) return 0;
    if ([normalized isEqualToString:@"low"] || [normalized isEqualToString:@"9"]) return 9;
    if ([normalized isEqualToString:@"medium"] || [normalized isEqualToString:@"5"]) return 5;
    if ([normalized isEqualToString:@"high"] || [normalized isEqualToString:@"1"]) return 1;

    fail(@"Priority must be one of none, low, medium, high, 0, 1, 5, or 9");
    return 0;
}

static NSDate *dateFromInputString(NSString *input) {
    if (input.length == 0) return nil;

    NSISO8601DateFormatter *isoFormatter = [NSISO8601DateFormatter new];
    isoFormatter.timeZone = NSTimeZone.localTimeZone;
    isoFormatter.formatOptions = NSISO8601DateFormatWithInternetDateTime;
    NSDate *date = [isoFormatter dateFromString:input];
    if (!date) {
        isoFormatter.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
        date = [isoFormatter dateFromString:input];
    }
    if (date) return date;

    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = NSTimeZone.localTimeZone;
    formatter.lenient = NO;

    NSArray<NSString *> *formats = @[
        @"yyyy-MM-dd HH:mm:ss",
        @"yyyy-MM-dd HH:mm",
        @"yyyy-MM-dd'T'HH:mm:ss",
        @"yyyy-MM-dd'T'HH:mm",
        @"yyyy-MM-dd",
    ];

    for (NSString *format in formats) {
        formatter.dateFormat = format;
        date = [formatter dateFromString:input];
        if (date) return date;
    }

    return nil;
}

static NSDateComponents *dueDateComponentsFromInput(NSString *input) {
    NSDate *date = dateFromInputString(input);
    if (!date) {
        fail(@"Invalid due date. Use YYYY-MM-DD, YYYY-MM-DD HH:MM[:SS], or ISO 8601");
    }

    NSCalendar *calendar = NSCalendar.currentCalendar;
    calendar.timeZone = NSTimeZone.localTimeZone;
    NSCalendarUnit units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    return [calendar components:units fromDate:date];
}

static NSDictionary *normalizedReminder(id reminder) {
    id listObject = send0(reminder, "list");
    NSString *listName = stringFromObject(send0(listObject, "name"));
    NSString *title = stringFromObject(send0(reminder, "titleAsString"));
    NSString *body = stringFromObject(send0(reminder, "notesAsString"));
    NSString *dueDate = isoStringFromDateComponents(send0(reminder, "dueDateComponents"));
    NSString *priority = priorityLabel(((NSInteger(*)(id, SEL))objc_msgSend)(reminder, sel_registerName("priority")));
    NSString *reminderID = uuidStringFromReminderObjectID(send0(reminder, "objectID"));

    return @{
        @"id": reminderID ?: @"",
        @"name": title ?: @"",
        @"list": listName ?: @"",
        @"body": body.length > 0 ? body : [NSNull null],
        @"completed": @(sendBool0(reminder, "isCompleted")),
        @"priority": priority,
        @"due_date": dueDate ?: [NSNull null],
    };
}

static BOOL parseBool(NSString *value, BOOL *outValue) {
    NSString *normalized = value.lowercaseString;
    if ([normalized isEqualToString:@"true"]) {
        *outValue = YES;
        return YES;
    }
    if ([normalized isEqualToString:@"false"]) {
        *outValue = NO;
        return YES;
    }
    return NO;
}

static void commandMetadata(int argc, const char **argv) {
    id store = reminderStore();
    NSMutableArray *items = [NSMutableArray array];

    for (int i = 2; i < argc; i++) {
        NSString *uuidString = [NSString stringWithUTF8String:argv[i]];
        [items addObject:metadataForReminder(store, uuidString)];
    }

    printJSON(items);
}

static void commandGet(int argc, const char **argv) {
    if (argc != 3) fail(@"Usage: reminderkit_helper get <id>");

    id store = reminderStore();
    NSString *uuidString = [NSString stringWithUTF8String:argv[2]];
    NSError *error = nil;
    id reminder = fetchReminderByUUID(store, uuidString, &error);
    if (!reminder) fail(error ? error.localizedDescription : @"Reminder not found");

    printJSON(normalizedReminder(reminder));
}

static void commandDefaultListName(int argc, const char **argv) {
    if (argc != 2) fail(@"Usage: reminderkit_helper default-list-name");

    id store = reminderStore();
    NSError *error = nil;
    id list = ((id(*)(id, SEL, NSError **))objc_msgSend)(store, sel_registerName("fetchDefaultListWithError:"), &error);
    if (!list) fail(error ? error.localizedDescription : @"Default list could not be loaded");

    printJSON(@{@"name": stringFromObject(send0(list, "name")) ?: @""});
}

static void commandCreate(int argc, const char **argv) {
    if (argc < 4 || argc > 7) fail(@"Usage: reminderkit_helper create <list-name> <title> [body] [due-date] [priority]");

    NSString *listName = [NSString stringWithUTF8String:argv[2]];
    NSString *title = [NSString stringWithUTF8String:argv[3]];
    NSString *body = argc >= 5 ? [NSString stringWithUTF8String:argv[4]] : @"";
    NSString *dueString = argc >= 6 ? [NSString stringWithUTF8String:argv[5]] : @"";
    NSString *priorityString = argc >= 7 ? [NSString stringWithUTF8String:argv[6]] : @"";

    id store = reminderStore();
    id list = fetchedListByName(store, listName);
    if (!list) fail([NSString stringWithFormat:@"List does not exist: %@", listName]);

    id saveRequest = saveRequestForStore(store);
    id listChange = send1(saveRequest, "updateList:", list);
    id reminderChange = send2(saveRequest, "addReminderWithTitle:toListChangeItem:", title, listChange);

    if (body.length > 0) send1(reminderChange, "setNotesAsString:", body);
    if (priorityString.length > 0) sendVoidInteger(reminderChange, "setPriority:", priorityValueFromInput(priorityString));
    if (dueString.length > 0) send1(reminderChange, "setDueDateComponents:", dueDateComponentsFromInput(dueString));

    NSError *error = nil;
    if (!sendBoolError(saveRequest, "saveSynchronouslyWithError:", &error)) {
        fail(error ? error.localizedDescription : @"Failed to create reminder");
    }

    NSString *createdUUID = uuidStringFromReminderObjectID(send0(reminderChange, "objectID"));
    id reminder = fetchReminderByUUID(store, createdUUID, &error);
    if (!reminder) fail(error ? error.localizedDescription : @"Created reminder could not be reloaded");

    printJSON(normalizedReminder(reminder));
}

static void commandSearchExactName(int argc, const char **argv) {
    if (argc != 4) fail(@"Usage: reminderkit_helper search-exact-name <list-name> <title>");

    NSString *listName = [NSString stringWithUTF8String:argv[2]];
    NSString *title = [NSString stringWithUTF8String:argv[3]];
    id store = reminderStore();
    NSError *error = nil;
    id reminders = ((id(*)(id, SEL, id, id, id, id, id, id, NSError **))objc_msgSend)(
        store,
        sel_registerName("fetchRemindersMatchingTitle:dueAfter:dueBefore:isCompleted:hasLocation:location:error:"),
        title,
        nil,
        nil,
        nil,
        nil,
        nil,
        &error
    );
    if (!reminders && error) fail(error.localizedDescription);

    NSMutableArray *items = [NSMutableArray array];
    for (id reminder in reminders) {
        NSString *reminderTitle = stringFromObject(send0(reminder, "titleAsString"));
        NSString *reminderListName = stringFromObject(send0(send0(reminder, "list"), "name"));
        if ([reminderTitle isEqualToString:title] && [reminderListName isEqualToString:listName]) {
            [items addObject:normalizedReminder(reminder)];
        }
    }

    printJSON(items);
}

static void commandChildren(int argc, const char **argv) {
    if (argc < 3 || argc > 4) fail(@"Usage: reminderkit_helper children <parent-id> [list-name]");

    NSString *parentID = [NSString stringWithUTF8String:argv[2]];
    NSString *listName = argc == 4 ? [NSString stringWithUTF8String:argv[3]] : nil;
    id store = reminderStore();
    NSError *error = nil;
    id reminders = ((id(*)(id, SEL, id, id, id, id, id, id, NSError **))objc_msgSend)(
        store,
        sel_registerName("fetchRemindersMatchingTitle:dueAfter:dueBefore:isCompleted:hasLocation:location:error:"),
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        &error
    );
    if (!reminders && error) fail(error.localizedDescription);

    NSMutableArray *items = [NSMutableArray array];
    for (id reminder in reminders) {
        NSString *reminderListName = stringFromObject(send0(send0(reminder, "list"), "name"));
        NSString *reminderParentID = uuidStringFromReminderObjectID(send0(reminder, "parentReminderID"));
        if (reminderParentID && [reminderParentID isEqualToString:parentID] && (!listName || [reminderListName isEqualToString:listName])) {
            [items addObject:normalizedReminder(reminder)];
        }
    }

    printJSON(items);
}

static void commandSetUrgent(int argc, const char **argv) {
    if (argc != 4) fail(@"Usage: reminderkit_helper set-urgent <id> <true|false>");

    NSString *uuidString = [NSString stringWithUTF8String:argv[2]];
    NSString *boolString = [NSString stringWithUTF8String:argv[3]];
    BOOL urgent = NO;
    if (!parseBool(boolString, &urgent)) fail(@"Boolean value must be true or false");

    id store = reminderStore();
    NSError *error = nil;
    id reminder = fetchReminderByUUID(store, uuidString, &error);
    if (!reminder) fail(error ? error.localizedDescription : @"Reminder not found");

    id saveRequest = saveRequestForStore(store);
    id reminderChange = send1(saveRequest, "updateReminder:", reminder);
    id urgentContext = send0(reminderChange, "urgentAlarmContext");
    sendVoidBool(urgentContext, "setIsUrgentStateEnabledForCurrentUser:", urgent);

    if (!sendBoolError(saveRequest, "saveSynchronouslyWithError:", &error)) {
        fail(error ? error.localizedDescription : @"Failed to save urgent state");
    }

    printJSON(@{@"id": uuidString, @"urgent": @(urgent)});
}

static void commandSetFlagged(int argc, const char **argv) {
    if (argc != 4) fail(@"Usage: reminderkit_helper set-flagged <id> <true|false>");

    NSString *uuidString = [NSString stringWithUTF8String:argv[2]];
    NSString *boolString = [NSString stringWithUTF8String:argv[3]];
    BOOL flagged = NO;
    if (!parseBool(boolString, &flagged)) fail(@"Boolean value must be true or false");

    id store = reminderStore();
    NSError *error = nil;
    id reminder = fetchReminderByUUID(store, uuidString, &error);
    if (!reminder) fail(error ? error.localizedDescription : @"Reminder not found");

    id saveRequest = saveRequestForStore(store);
    id reminderChange = send1(saveRequest, "updateReminder:", reminder);
    id flaggedContext = send0(reminderChange, "flaggedContext");
    sendVoidBool(flaggedContext, "setFlagged:", flagged);

    if (!sendBoolError(saveRequest, "saveSynchronouslyWithError:", &error)) {
        fail(error ? error.localizedDescription : @"Failed to save flagged state");
    }

    printJSON(@{@"id": uuidString, @"flagged": @(flagged)});
}

static void commandSetPriority(int argc, const char **argv) {
    if (argc != 4) fail(@"Usage: reminderkit_helper set-priority <id> <none|low|medium|high|0|1|5|9>");

    NSString *uuidString = [NSString stringWithUTF8String:argv[2]];
    NSString *priorityString = [NSString stringWithUTF8String:argv[3]];
    NSInteger priority = priorityValueFromInput(priorityString);

    id store = reminderStore();
    NSError *error = nil;
    id reminder = fetchReminderByUUID(store, uuidString, &error);
    if (!reminder) fail(error ? error.localizedDescription : @"Reminder not found");

    id saveRequest = saveRequestForStore(store);
    id reminderChange = send1(saveRequest, "updateReminder:", reminder);
    sendVoidInteger(reminderChange, "setPriority:", priority);

    if (!sendBoolError(saveRequest, "saveSynchronouslyWithError:", &error)) {
        fail(error ? error.localizedDescription : @"Failed to save priority");
    }

    printJSON(@{@"id": uuidString, @"priority": priorityLabel(priority)});
}

static void commandDelete(int argc, const char **argv) {
    if (argc != 3) fail(@"Usage: reminderkit_helper delete <id>");

    NSString *uuidString = [NSString stringWithUTF8String:argv[2]];

    id store = reminderStore();
    NSError *error = nil;
    id reminder = fetchReminderByUUID(store, uuidString, &error);
    if (!reminder) fail(error ? error.localizedDescription : @"Reminder not found");

    id saveRequest = saveRequestForStore(store);
    id reminderChange = send1(saveRequest, "updateReminder:", reminder);
    send0(reminderChange, "removeFromList");

    if (!sendBoolError(saveRequest, "saveSynchronouslyWithError:", &error)) {
        fail(error ? error.localizedDescription : @"Failed to delete reminder");
    }

    printJSON(@{@"deleted": @YES, @"id": uuidString});
}

static void commandReparent(int argc, const char **argv) {
    if (argc != 4) fail(@"Usage: reminderkit_helper reparent <child-id> <parent-id>");

    NSString *childUUID = [NSString stringWithUTF8String:argv[2]];
    NSString *parentUUID = [NSString stringWithUTF8String:argv[3]];
    if ([childUUID caseInsensitiveCompare:parentUUID] == NSOrderedSame) {
        fail(@"Reminder cannot be its own parent");
    }

    id store = reminderStore();
    NSError *error = nil;
    id childReminder = fetchReminderByUUID(store, childUUID, &error);
    if (!childReminder) fail(error ? error.localizedDescription : @"Child reminder not found");
    id parentReminder = fetchReminderByUUID(store, parentUUID, &error);
    if (!parentReminder) fail(error ? error.localizedDescription : @"Parent reminder not found");

    id saveRequest = saveRequestForStore(store);
    id parentChange = send1(saveRequest, "updateReminder:", parentReminder);
    id parentSubtaskContext = send0(parentChange, "subtaskContext");
    id childChange = send1(saveRequest, "updateReminder:", childReminder);
    sendVoid1(parentSubtaskContext, "addReminderChangeItem:", childChange);

    if (!sendBoolError(saveRequest, "saveSynchronouslyWithError:", &error)) {
        fail(error ? error.localizedDescription : @"Failed to reparent reminder");
    }

    printJSON(@{@"id": childUUID, @"parent_id": parentUUID});
}

int main(int argc, const char **argv) {
    @autoreleasepool {
        dlopen("/System/Library/PrivateFrameworks/ReminderKit.framework/ReminderKit", RTLD_NOW);
        dlopen("/System/Library/PrivateFrameworks/ReminderKitInternal.framework/ReminderKitInternal", RTLD_NOW);

        if (argc < 2) fail(@"Usage: reminderkit_helper <metadata|get|default-list-name|create|search-exact-name|children|set-flagged|set-priority|set-urgent|delete|reparent> ...");

        NSString *command = [NSString stringWithUTF8String:argv[1]];
        if ([command isEqualToString:@"metadata"]) {
            commandMetadata(argc, argv);
            return 0;
        }
        if ([command isEqualToString:@"get"]) {
            commandGet(argc, argv);
            return 0;
        }
        if ([command isEqualToString:@"default-list-name"]) {
            commandDefaultListName(argc, argv);
            return 0;
        }
        if ([command isEqualToString:@"create"]) {
            commandCreate(argc, argv);
            return 0;
        }
        if ([command isEqualToString:@"search-exact-name"]) {
            commandSearchExactName(argc, argv);
            return 0;
        }
        if ([command isEqualToString:@"children"]) {
            commandChildren(argc, argv);
            return 0;
        }
        if ([command isEqualToString:@"set-urgent"]) {
            commandSetUrgent(argc, argv);
            return 0;
        }
        if ([command isEqualToString:@"set-flagged"]) {
            commandSetFlagged(argc, argv);
            return 0;
        }
        if ([command isEqualToString:@"set-priority"]) {
            commandSetPriority(argc, argv);
            return 0;
        }
        if ([command isEqualToString:@"delete"]) {
            commandDelete(argc, argv);
            return 0;
        }
        if ([command isEqualToString:@"reparent"]) {
            commandReparent(argc, argv);
            return 0;
        }

        fail([NSString stringWithFormat:@"Unsupported command: %@", command]);
    }
}
