# PathwayKit
A implementation of [mluton/EmbeddedSwapping](https://github.com/mluton/EmbeddedSwapping) and [Container View Controllers in the Storyboard](https://orderoo.wordpress.com/2012/02/23/container-view-controllers-in-the-storyboard/) in Swift, which allows a `ContainerView` to be used as a "pathway" to any number of subviews.

The API provides for routing to be performed either from the parent view controller or via the child view controllers (or both is desired) depending on what is required.

# Motivations
The desire for the API has come about from a number of previous implementations and requirements, where a view was required to present a number of "smaller", "embedded" views one at a time, which the user could navigate between (think active call view, with the ability to switch between the dialpad and audio options views).

The desire was to provide a workflow which didn't require ALL the functionality to be stored in a single view controller and overcome the mess that would create.

More complicated implementations require the switching between a `UINavigationViewController` and `UITabBarViewController` to facilitate a customer's desired solution.  Because `UITabBarViewController` can't be contained within in a `UINavigationViewController`, I needed a solution which could allow me to switch between these two routes from a common hub point.

While other solutions could be used, there were also "common" UI elements which are shared between ALL the views in the App, this meant either repeating a lot of common layout and initialisation code or coming up with a solution which isolated these features in a way which would allow them to be changed independently of each other