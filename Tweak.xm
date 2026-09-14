\
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString *SBLDebugPath(void) {
    return @"/var/mobile/Library/Preferences/StatusBarLayoutDebug.txt";
}

static void SBLAppend(NSString *text) {
    @autoreleasepool {
        NSString *path = SBLDebugPath();
        NSString *old = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];
        if (!old) old = @"";
        NSString *out = [old stringByAppendingFormat:@"%@\n", text];
        [out writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

static NSString *SBLIndent(NSUInteger level) {
    return [@"" stringByPaddingToLength:level * 2
                              withString:@" "
                         startingAtIndex:0];
}

static void SBLDumpView(UIView *view, NSUInteger level, NSMutableString *out) {
    if (!view || level > 12) return;

    CGRect f = view.frame;
    NSString *cls = NSStringFromClass([view class]);
    NSString *desc = [view description];

    [out appendFormat:@"%@%@ frame=(%.1f, %.1f, %.1f, %.1f) hidden=%d alpha=%.2f\n",
        SBLIndent(level), cls, f.origin.x, f.origin.y,
        f.size.width, f.size.height, view.hidden, view.alpha];

    // Add useful textual hints without dumping potentially huge object state.
    NSString *lower = desc.lowercaseString;
    if ([lower containsString:@"status"] ||
        [lower containsString:@"signal"] ||
        [lower containsString:@"wifi"] ||
        [lower containsString:@"battery"] ||
        [lower containsString:@"time"] ||
        [lower containsString:@"carrier"]) {
        [out appendFormat:@"%@  desc=%@\n", SBLIndent(level + 1), desc];
    }

    for (UIView *sub in view.subviews) {
        SBLDumpView(sub, level + 1, out);
    }
}

static void SBLDumpStatusWindows(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            NSMutableString *report = [NSMutableString string];
            [report appendFormat:@"\n===== StatusBarLayout DEBUG %@ =====\n",
                                  [NSDate date]];

            NSMutableArray *windows = [NSMutableArray array];

            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    [windows addObjectsFromArray:windowScene.windows];
                }
            }

            [report appendFormat:@"UIWindowScene windows: %lu\n",
                      (unsigned long)windows.count];

            BOOL found = NO;

            for (UIWindow *window in windows) {
                NSString *cls = NSStringFromClass([window class]);
                NSString *desc = [window description];
                NSString *all = [[cls stringByAppendingString:@" "] stringByAppendingString:desc];
                NSString *lower = all.lowercaseString;

                if ([lower containsString:@"statusbar"] ||
                    [lower containsString:@"status bar"]) {
                    found = YES;
                    CGRect f = window.frame;
                    [report appendFormat:@"\n--- STATUS WINDOW ---\n"];
                    [report appendFormat:@"class=%@\nframe=(%.1f, %.1f, %.1f, %.1f)\n",
                        cls, f.origin.x, f.origin.y, f.size.width, f.size.height];
                    SBLDumpView(window, 0, report);
                }
            }

            if (!found) {
                [report appendString:
                    @"\nNo window with 'StatusBar' in class/description was found.\n"];
            }

            SBLAppend(report);
        }
    });
}

%hook UIStatusBar

- (void)layoutSubviews {
    %orig;
    static int count = 0;
    if (count < 5) {
        count++;
        SBLAppend([NSString stringWithFormat:
                   @"UIStatusBar layoutSubviews hit #%d", count]);
        SBLDumpStatusWindows();
    }
}

%end

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        SBLAppend(@"===== StatusBarLayoutDebug loaded =====");
        SBLDumpStatusWindows();

        // Capture a few states after SpringBoard has settled.
        for (int i = 1; i <= 5; i++) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                           (int64_t)(i * 3 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                SBLDumpStatusWindows();
            });
        }
    });
}
