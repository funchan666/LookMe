#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.fun.lookme";

/// The "LaunchBackground" asset catalog color resource.
static NSString * const ACColorNameLaunchBackground AC_SWIFT_PRIVATE = @"LaunchBackground";

/// The "LaunchIcon" asset catalog image resource.
static NSString * const ACImageNameLaunchIcon AC_SWIFT_PRIVATE = @"LaunchIcon";

/// The "LaunchLoading" asset catalog image resource.
static NSString * const ACImageNameLaunchLoading AC_SWIFT_PRIVATE = @"LaunchLoading";

/// The "LaunchSplash" asset catalog image resource.
static NSString * const ACImageNameLaunchSplash AC_SWIFT_PRIVATE = @"LaunchSplash";

#undef AC_SWIFT_PRIVATE
