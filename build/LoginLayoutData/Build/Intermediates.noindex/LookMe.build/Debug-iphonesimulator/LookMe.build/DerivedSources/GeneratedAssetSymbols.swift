import Foundation
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "LaunchBackground" asset catalog color resource.
    static let launchBackground = DeveloperToolsSupport.ColorResource(name: "LaunchBackground", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "LaunchIcon" asset catalog image resource.
    static let launchIcon = DeveloperToolsSupport.ImageResource(name: "LaunchIcon", bundle: resourceBundle)

    /// The "LaunchLoading" asset catalog image resource.
    static let launchLoading = DeveloperToolsSupport.ImageResource(name: "LaunchLoading", bundle: resourceBundle)

    /// The "LaunchSplash" asset catalog image resource.
    static let launchSplash = DeveloperToolsSupport.ImageResource(name: "LaunchSplash", bundle: resourceBundle)

}

