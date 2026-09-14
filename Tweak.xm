#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static BOOL IsTargetView(UIView *view)
{
    NSString *name = NSStringFromClass([view class]);

    NSArray *targets = @[
        @"UIStatusBar_Modern",
        @"_UIStatusBar",
        @"_UIStatusBarForegroundView",
        @"_UIStatusBarStringView",
        @"_UIStatusBarCellularSmallSignalView",
        @"_UIStatusBarCellularFlatSignalView",
        @"_UIStatusBarDualCellularSignalView",
        @"_UIStatusBarWifiSignalView",
        @"_UIBatteryView",
        @"AxsDuoCombinedView"
    ];

    for (NSString *target in targets) {
        if ([name containsString:target]) {
            return YES;
        }
    }

    return NO;
}

static void DumpView(UIView *view, NSInteger depth)
{
    if (!view)
        return;

    if (IsTargetView(view)) {

        NSString *className = NSStringFromClass([view class]);
        NSString *superName = view.superview ?
            NSStringFromClass([view.superview class]) : @"<nil>";
        NSString *windowName = view.window ?
            NSStringFromClass([view.window class]) : @"<nil>";

        NSLog(@"\n"
              @"========== STATUS TARGET ==========\n"
              @"class      = %@\n"
              @"frame      = %@\n"
              @"bounds     = %@\n"
              @"center     = %@\n"
              @"hidden     = %d\n"
              @"alpha      = %.2f\n"
              @"superview  = %@\n"
              @"window     = %@\n"
              @"====================================",
              className,
              NSStringFromCGRect(view.frame),
              NSStringFromCGRect(view.bounds),
              NSStringFromCGPoint(view.center),
              view.hidden,
              view.alpha,
              superName,
              windowName);
    }

    for (UIView *subview in view.subviews) {
        DumpView(subview, depth + 1);
    }
}

static void DumpAllWindows(void)
{
    NSLog(@"\n\n"
          @"========================================\n"
          @"===== STATUS BAR DEBUG 3 START ========\n"
          @"========================================");

    UIApplication *app = [UIApplication sharedApplication];

    if (!app) {
        NSLog(@"UIApplication = nil");
        return;
    }

    NSLog(@"UIApplication windows count = %lu",
          (unsigned long)app.windows.count);

    for (UIWindow *window in app.windows) {

        NSLog(@"\n"
              @"----- APPLICATION WINDOW -----\n"
              @"class  = %@\n"
              @"frame  = %@\n"
              @"hidden = %d\n"
              @"alpha  = %.2f",
              NSStringFromClass([window class]),
              NSStringFromCGRect(window.frame),
              window.hidden,
              window.alpha);

        DumpView(window, 0);
    }

    if (@available(iOS 13.0, *)) {

        for (UIScene *scene in app.connectedScenes) {

            NSLog(@"\n"
                  @"----- SCENE -----\n"
                  @"class = %@\n"
                  @"state = %ld",
                  NSStringFromClass([scene class]),
                  (long)scene.activationState);

            if (![scene isKindOfClass:[UIWindowScene class]])
                continue;

            UIWindowScene *windowScene = (UIWindowScene *)scene;

            NSLog(@"Scene windows count = %lu",
                  (unsigned long)windowScene.windows.count);

            for (UIWindow *window in windowScene.windows) {

                NSLog(@"\n"
                      @"----- SCENE WINDOW -----\n"
                      @"class  = %@\n"
                      @"frame  = %@\n"
                      @"hidden = %d\n"
                      @"alpha  = %.2f",
                      NSStringFromClass([window class]),
                      NSStringFromCGRect(window.frame),
                      window.hidden,
                      window.alpha);

                DumpView(window, 0);
            }
        }
    }

    NSLog(@"\n"
          @"========================================\n"
          @"===== STATUS BAR DEBUG 3 END ==========\n"
          @"========================================\n\n");
}

%ctor
{
    NSLog(@"[StatusBarLayoutDebug] Debug 3 loaded");

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC),
        dispatch_get_main_queue(),
        ^{
            DumpAllWindows();

            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC),
                dispatch_get_main_queue(),
                ^{
                    DumpAllWindows();
                }
            );
        }
    );
}
