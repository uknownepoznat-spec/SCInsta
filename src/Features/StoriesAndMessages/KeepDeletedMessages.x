#import "../../Utils.h"
#import "../../Archive/SCIMessageArchive.h"
#import <substrate.h>
#import <objc/runtime.h>

// Do not substitute NULL IDs or stop an outgoing unsend. Keep the local text
// separately while Instagram processes the real deletion normally.
%hook IGDirectRealtimeIrisThreadDelta
+ (id)removeItemWithMessageId:(id)messageID {
    [[SCIMessageArchive sharedArchive] markDeletedMessageID:messageID];
    return %orig;
}
%end

%hook IGDirectMessageUpdate
+ (id)removeMessageWithMessageId:(id)messageID {
    [[SCIMessageArchive sharedArchive] markDeletedMessageID:messageID];
    return %orig;
}
%end

static void SCIInstallTextObserver(Class cls, SEL selector) {
    Method method = class_getInstanceMethod(cls, selector);
    if (!method) return;
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(method)];
    if (signature.numberOfArguments != 2 || signature.methodReturnType[0] != '@') return;
    __block IMP original = NULL;
    IMP observer = imp_implementationWithBlock(^id(id message) {
        id text = ((id (*)(id, SEL))original)(message, selector);
        if ([text isKindOfClass:[NSString class]] && [SCIUtils getBoolPref:@"keep_deleted_message"]) {
            [[SCIMessageArchive sharedArchive] observeMessage:message text:text];
        }
        return text;
    });
    MSHookMessageEx(cls, selector, observer, &original);
}

static void SCIInstallDeleteObserver(Class cls, SEL selector) {
    Method method = class_getInstanceMethod(cls, selector);
    if (!method) return;
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(method)];
    if (signature.numberOfArguments != 3 || signature.methodReturnType[0] != 'v'
        || [signature getArgumentTypeAtIndex:2][0] != '@') return;
    __block IMP original = NULL;
    IMP observer = imp_implementationWithBlock(^(id thread, id message) {
        [[SCIMessageArchive sharedArchive] retainDeletedMessage:message];
        ((void (*)(id, SEL, id))original)(thread, selector, message);
    });
    MSHookMessageEx(cls, selector, observer, &original);
}

static void SCIInstallSnapshotSetterObserver(Class cls, SEL selector) {
    Method method = class_getInstanceMethod(cls, selector);
    if (!method) return;
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(method)];
    if (signature.numberOfArguments != 3 || signature.methodReturnType[0] != 'v'
        || [signature getArgumentTypeAtIndex:2][0] != '@') return;
    __block IMP original = NULL;
    IMP observer = imp_implementationWithBlock(^(id message, id value) {
        ((void (*)(id, SEL, id))original)(message, selector, value);
        if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
            NSString *text = selector == NSSelectorFromString(@"setText:") && [value isKindOfClass:[NSString class]] ? value : nil;
            [[SCIMessageArchive sharedArchive] observeMessage:message text:text];
        }
    });
    MSHookMessageEx(cls, selector, observer, &original);
}

static void SCIInstallDeletedFlagObserver(Class cls) {
    SEL selector = NSSelectorFromString(@"setIsDeleted:");
    Method method = class_getInstanceMethod(cls, selector);
    if (!method) return;
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(method)];
    if (signature.numberOfArguments != 3 || signature.methodReturnType[0] != 'v') return;
    char argument = [signature getArgumentTypeAtIndex:2][0];
    if (argument != 'B' && argument != 'c') return;
    __block IMP original = NULL;
    IMP observer = imp_implementationWithBlock(^(id message, BOOL deleted) {
        if (deleted) [[SCIMessageArchive sharedArchive] retainDeletedMessage:message];
        ((void (*)(id, SEL, BOOL))original)(message, selector, deleted);
    });
    MSHookMessageEx(cls, selector, observer, &original);
}

%ctor {
    @autoreleasepool {
        %init;
        // Only install against real, ABI-checked methods present in this build.
        for (NSString *name in @[@"IGDirectMessage", @"IGDirectTextMessage"]) {
            Class cls = NSClassFromString(name);
            if (cls) {
                SCIInstallTextObserver(cls, NSSelectorFromString(@"text"));
                for (NSString *setter in @[@"setText:", @"setMessageId:", @"setMessageID:", @"setItemId:", @"setItemID:"]) {
                    SCIInstallSnapshotSetterObserver(cls, NSSelectorFromString(setter));
                }
                SCIInstallDeletedFlagObserver(cls);
            }
        }
        Class threadClass = NSClassFromString(@"IGDirectThread");
        if (threadClass) SCIInstallDeleteObserver(threadClass, NSSelectorFromString(@"deleteMessage:"));
    }
}
