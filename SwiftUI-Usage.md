## Usage of SwiftUI in brave-ios

Now that the iOS deployment target of Brave is set to iOS 13 we can begin to use SwiftUI within the codebase. Due to the newness of using SwiftUI, these guidelines will be put in place to ensure its usage doesn't cause issues.

1. Use SwiftUI in isolation to replace basic static UI hierarchies.

    If you have some simple UI to build that is going to be displayed and not updated anymore using `UIViewController`, consider using SwiftUI & `UIHostingController` instead. The easiest views to replace are settings style screens or basic informative screens

2. Test against lowest deployment target

    Early iOS 13 versions had many SwiftUI bugs, since our deployment target is 13.0, ensure that any SwiftUI code you write is tested on a iOS 13.0 simulator as its possible it does not render the exact same way as on iOS 14. There are some public collections of these bugs such as [ryangittings/swiftui-bugs](https://github.com/ryangittings/swiftui-bugs), and [SwiftUI Lab's bug watch](https://swiftui-lab.com/bug-watch) 

3. Avoid SwiftUI's pain points/Be aware of SwiftUI's shortcomings

    There are sets of SwiftUI controls that are harder to get working correctly across multiple iOS versions. Aside from very simple use-cases, avoid using:

    - `TextField`/`SecureField`
        - Keyboard avoidance is a nightmare on iOS 13, best to avoid SwiftUI for views that when a keyboard is shown must update it's scroll inset or move views
        - Missing many key APIs (FB6494028)
    - `NavigationView`
    - `TabView`
        - iOS 13 TabView was buggy, and caused issues with NavigationView's inside resetting
    - `ScrollView`
        - SwiftUI's scroll view is missing many customization points such as content inset, scroll indicator insets, all of the delegate methods, etc. Best to put your SwiftUI inside a `UIScrollView` if you need anything more complex than a simple single-axis scroll container
    - Complex gestures
        - Anything besides simple TapGesture's are usually easier in UIKit

4. Make sure you're aware of SwiftUI magic defaults

    SwiftUI has a lot of special defaults that can cause issues if you do not know about them. Consider understanding some of these such as

    - `Form` 
        - Uses different table styles based on OS version: grouped on iOS 13, grouped inset on iOS 14
        - Items within it are styled accordingly (Picker's become inline for options, etc.)
    - `Button` can obtain special hit testing around it (similar to `Button.hitTestSlop`)
    - `padding` view modifier without provided values defaults based on the context

5. Don't be afraid to mix-and-match UIKit & SwiftUI.

    SwiftUI in its current form is not complete and cannot accomplish everything UIKit can, if you do choose to use SwiftUI, do not be afraid to create UIKit representables as needed to accomplish your goal

6. Watch-out for shadowed definitions

    We have a number of declared types that match `SwiftUI` specific types, such as BraveUI's `Button` and BraveRewards' `Environment`. If you get weird errors for simple SwiftUI you expect to compile, look out to make sure something like `@Environment` isn't being shadowed and thus needs to be named `@SwiftUI.Environment` until we update the names causing shadowed classes/structs.