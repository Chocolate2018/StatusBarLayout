#import <UIKit/UIKit.h>

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

static void DumpView(UIView *view)
{
    if (!view)
        return;

    if (IsTargetView(view)) {

        NSString *className = NSStringFromClass([view class]);

        NSString *superName = view.superview ?
            NSStringFromClass([view.superview class]) :
            @"<nil>";

        NSString *windowName = view.window ?
            NSStringFromClass([view.window class]) :
            @"<nil>";

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
        DumpView(subview);
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

    /*
     * iOS 13+:
     * 不再使用 UIApplication.windows，
     * 避免 iOS 15+ SDK deprecated 错误。
     */

    if (@available(iOS 13.0, *)) {

        NSSet<UIScene *> *scenes = app.connectedScenes;

        NSLog(@"Connected scenes count = %lu",
              (unsigned long)scenes.count);

        for (UIScene *scene in scenes) {

            NSLog(@"\n"
                  @"----- SCENE -----\n"
                  @"class      = %@\n"
                  @"state      = %ld",
                  NSStringFromClass([scene class]),
                  (long)scene.activationState);

            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }

            UIWindowScene *windowScene = (UIWindowScene *)scene;

            NSArray<UIWindow *> *windows = windowScene.windows;

            NSLog(@"Scene windows count = %lu",
                  (unsigned long)windows.count);

            for (UIWindow *window in windows) {

                NSLog(@"\n"
                      @"----- SCENE WINDOW -----\n"
                      @"class      = %@\n"
                      @"frame      = %@\n"
                      @"bounds     = %@\n"
                      @"hidden     = %d\n"
                      @"alpha      = %.2f\n"
                      @"rootView   = %@",
                      NSStringFromClass([window class]),
                      NSStringFromCGRect(window.frame),
                      NSStringFromCGRect(window.bounds),
                      window.hidden,
                      window.alpha,
                      window.rootViewController ?
                      NSStringFromClass(
                          [window.rootViewController class]
                      ) :
                      @"<nil>");

                DumpView(window);
            }
        }

    } else {

        NSLog(@"iOS version < 13 detected");

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
        dispatch_time(
            DISPATCH_TIME_NOW,
            5 * NSEC_PER_SEC
        ),
        dispatch_get_main_queue(),
        ^{
            DumpAllWindows();

            dispatch_after(
                dispatch_time(
                    DISPATCH_TIME_NOW,
                    5 * NSEC_PER_SEC
                ),
                dispatch_get_main_queue(),
                ^{
                    DumpAllWindows();
                }
            );
        }
    );
}
