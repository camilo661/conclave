import SwiftUI

/// View-local state.
///
/// In recent SDKs the `@State` spelling is a macro whose compiler plugin ships
/// only with Xcode. This alias names the underlying property wrapper directly,
/// so the package also builds with the standalone Command Line Tools.
typealias ViewState<Value> = SwiftUI.State<Value>
