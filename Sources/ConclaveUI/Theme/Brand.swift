import AppKit
import SwiftUI

/// The browser's name and logo.
enum Brand {
    static let name = "CONCLAVE"

    /// `logo.png` from the app bundle's resources.
    static let logo: NSImage? = Bundle.main.image(forResource: "logo")
}

struct BrandLogo: View {
    let size: CGFloat

    var body: some View {
        if let logo = Brand.logo {
            Image(nsImage: logo)
                .resizable()
                .interpolation(.high)
                .frame(width: size, height: size)
                .accessibilityLabel(Brand.name)
        }
    }
}
