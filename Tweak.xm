#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString *SBLDebugPath(void) {
    return @"/var/mobile/Library/Preferences/StatusBarLayoutDebug2.txt";
}

static void SBLAppend(NSString *text) {
    @autoreleasepool {
        NSString *old =
            [NSString stringWithContentsOfFile:SBLDebugPath()
                                       encoding:NSUTF8StringEncoding
                                          error:nil];

        if (!old) {
            old = @"";
        }

        NSString *out = [old stringByAppendingFormat:@"%@\n", text];

        [out writeToFile:SBLDebugPath()
              atomically:YES
                encoding:NSUTF8StringEncoding
                   error:nil];
    }
}

static void SBLDumpView(UIView *view,
                        NSUInteger level,
                        NSMutableString *out) {

    if (!view || level > 20) {
        return;
    }

    CGRect f = view.frame;

    NSString *cls = NSStringFromClass([view class]);

    BOOL interesting =
        [cls containsString:@"StatusBar"] ||
        [cls containsString:@"Battery"] ||
        [cls containsString:@"Wifi"] ||
        [cls containsString:@"WiFi"] ||
        [cls containsString:@"Cellular"] ||
        [cls containsString:@"Signal"] ||
        [cls containsString:@"String"] ||
        [cls containsString:@"Time"] ||
        [cls containsString:@"Clock"] ||
        [cls containsString:@"Duo"];

    if (interesting) {

        NSString *superCls =
            view.superview
            ? NSStringFromClass([view.superview class])
            : @"<nil>";

        NSString *windowCls =
            view.window
            ? NSStringFromClass([view.window class])
            : @"<nil>";

        [out appendFormat:
            @"%@%@\n"
             "%@frame=(%.1f, %.1f, %.1f, %.1f)\n"
             "%@hidden=%d alpha=%.2f\n"
             "%@superview=%@\n"
             "%@window=%@\n\n",
            [@"" stringByPaddingToLength:level * 2
                              withString:@" "
                         startingAtIndex:0],
            cls,

            [@"" stringByPaddingToLength:level * 2 + 2
                              withString:@" "
                         startingAtIndex:0],
            f.origin.x,
            f.origin.y,
            f.size.width,
            f.size.height,

            [@"" stringByPaddingToLength:level * 2 + 2
                              withString:@" "
                         startingAtIndex:0],
            view.hidden,
            view.alpha,

            [@"" stringByPaddingToLength:level * 2 + 2
                              withString:@" "
                         startingAtIndex:0],
            superCls,

            [@"" stringByPaddingToLength:level * 2 + 2
                              withString:@" "
                         startingAtIndex:0],
            windowCls
        ];
    }

    for (UIView *subview in view.subviews) {
        SBLDumpView(subview, level + 1, out);
    }
}

static void SBLDumpStatusBars(void) {

    dispatch_async(dispatch_get_main_queue(), ^{

        @autoreleasepool {

            NSMutableString *report =
                [NSMutableString string];

            [report appendFormat:
                @"\n\n===== STATUS BAR DEBUG 2 %@ =====\n",
                [NSDate date]];

            NSSet *scenes =
                [UIApplication sharedApplication].connectedScenes;

            for (UIScene *scene in scenes) {

                if (![scene isKindOfClass:[UIWindowScene class]]) {
                    continue;
                }

                UIWindowScene *windowScene =
                    (UIWindowScene *)scene;

                for (UIWindow *window in windowScene.windows) {

                    NSString *windowClass =
                        NSStringFromClass([window class]);

                    NSString *windowDescription =
                        [window description];

                    NSString *all =
                        [[windowClass stringByAppendingString:@" "]
                         stringByAppendingString:windowDescription];

                    NSString *lower =
                        all.lowercaseString;

                    if ([lower containsString:@"statusbar"]) {

                        [report appendFormat:
                            @"\n--- STATUS WINDOW ---\n"
                             "class=%@\n"
                             "frame=(%.1f, %.1f, %.1f, %.1f)\n"
                             "hidden=%d alpha=%.2f\n\n",
                            windowClass,
                            window.frame.origin.x,
                            window.frame.origin.y,
                            window.frame.size.width,
                            window.frame.size.height,
                            window.hidden,
                            window.alpha
                        ];

                        SBLDumpView(window, 0, report);
                    }
                }
            }

            SBLAppend(report);
        }
    });
}

%ctor {

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW,
                      (int64_t)(3 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{

            SBLAppend(
                @"===== StatusBarLayoutDebug2 loaded ====="
            );

            SBLDumpStatusBars();

            for (int i = 1; i <= 4; i++) {

                dispatch_after(
                    dispatch_time(DISPATCH_TIME_NOW,
                                  (int64_t)(i * 3 * NSEC_PER_SEC)),
                    dispatch_get_main_queue(),
                    ^{
                        SBLDumpStatusBars();
                    }
                );
            }
        }
    );
}
