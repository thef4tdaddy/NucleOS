import SwiftUI

extension Binding where Value == String? {
    /// A derived `Binding<Bool>` that is true when the wrapped string is non-nil and non-empty.
    /// Used to drive `.alert(isPresented:)` from an optional error string.
    var isNotEmpty: Binding<Bool> {
        Binding<Bool>(
            get: { wrappedValue != nil && !wrappedValue!.isEmpty },
            set: { if !$0 { wrappedValue = nil } }
        )
    }
}
