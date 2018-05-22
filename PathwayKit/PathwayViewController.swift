//
//  PathwayViewControllr.swift
//  PathwayKit
//
//  Created by Shane Whitehead on 30/4/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import Foundation

// A destination identifer - ie segue
@objc public class PathwayRoute: NSObject {
	@objc let identifier: String
	
	public init(identifier: String) {
		self.identifier = identifier
	}
}

// A router between pathways
@objc public protocol PathwayRouter {
	@objc func navigate(to: PathwayRoute)
}

// The primary pathway view controller, which also acts as the pathway router
// This is a really good place to start for implementations who wish for the
// parent view controller to control the navigation
@objc open class PathwayRouterViewController: UIViewController, PathwayRouter {

	// The "first" controller shown by default
	public var defaultRoute: PathwayRoute!
	// The avaliable destinations
	public var avaliableRoutes: [PathwayRoute] = []

	public var transitionAnimations: UIViewAnimationOptions = [
		.layoutSubviews,
		.allowAnimatedContent,
		.curveEaseInOut,
		.preferredFramesPerSecond60,
		.transitionCrossDissolve
	]
	
	// The current destination
	public var currentRoute: PathwayRoute!
	public private(set) var transitionInProgress: Bool = false
	
	public var transitionAnimationDuration = 0.3
	
	public var destinationControllers: [PathwayRoute: UIViewController] = [:]
	
	override open func viewDidLoad() {
		super.viewDidLoad()
		currentRoute = defaultRoute
		performSegue(withIdentifier: currentRoute.identifier, sender: self)
	}
	
	// A reverse lookup mechanism to find a matching destination
	// from a segue identifier
	internal func destination(for segue: UIStoryboardSegue) -> PathwayRoute? {
		for destination in avaliableRoutes {
			guard destination.identifier == segue.identifier else {
				continue
			}
			return destination
		}
		return nil
	}

	// This performs a conversion which allows the API to find the "destination" view controller
	// which might otherwise be contained in another container view controller, like a
	// UINavigationController.  This provides a distinction between "presenting" and "destination"
	// controllers - as generally, you won't be implementing a UINavigationController directly,
	// but instead, the first controller will be the "destination" controller, but the
	// UINavigationController will be the presenting controller.
	// This is important, as the "presenting" controller is what gets added to the container,
	// where as the "destination" is used to pass information to and from
	open func destinationController(_ viewController: UIViewController) -> UIViewController {
		guard let controller = viewController as? UINavigationController else {
			return viewController
		}
		return controller.viewControllers.first!
	}

	// Called before the controller is "presented"
	open func willPresent(_ viewController: UIViewController) {
	}
	
	// Called after the controller is "presented"
	open func didPresent(_ viewController: UIViewController) {
	}
	
	// Called before the controller is "unpresented", but before
	// "willPresent" is called for the new controller
	open func willUnpresent(_ viewController: UIViewController) {
	}
	
	// Called after the controller is "unpresented", but before
	// "didPresent" is called for the new controller
	open func didUnpresent(_ viewController: UIViewController) {
	}
	
	// Core navigation router
	override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// Only managing execpected routes here
		guard let destination = destination(for: segue) else {
			fatalError("No destination found for \(String(describing: segue.identifier))")
		}

		if destinationControllers[destination] == nil {
			destinationControllers[destination] = segue.destination
		}

		// If this is the first time through, we simply present the "default" controller
		if segue.identifier == defaultRoute.identifier && childViewControllers.count == 0 {
			guard let childView = segue.destination.view else {
				return
			}
			willPresent(destinationController(segue.destination))
			addChildViewController(segue.destination)
			childView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			childView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
			view.addSubview(childView)
			didPresent(destinationController(segue.destination))
		} else {
			// Otherwise swap to the new destination
			swap(to: destination)
		}
	}
	
	// Mechanism used to change to a new pathway destination
	open func navigate(to: PathwayRoute) {
		performSegue(withIdentifier: to.identifier, sender: self)
	}
	
	// Swaps to specified destination
	public func swap(to: PathwayRoute) {
		swap(from: currentRoute, to: to)
	}
	
	// Swaps from/to the sepcified destinations
	public func swap(from: PathwayRoute, to: PathwayRoute) {
		guard from.identifier != to.identifier else {
			return
		}
		guard var currentViewController = destinationControllers[from] else {
			fatalError("Current view controller is undefined")
		}
		guard var destinationViewController = destinationControllers[to] else {
			fatalError("Destination view controller is undefined")
		}
		
		if let parent = currentViewController.parent, parent != self {
			currentViewController = parent
		}
		if let parent = destinationViewController.parent, parent != self {
			destinationViewController = parent
		}
		
		currentRoute = to
		swap(from: currentViewController, to: destinationViewController)
	}
	
	// Swaps the physical view controllers
	internal func swap(from fromViewController: UIViewController, to toViewController: UIViewController) {
		guard !transitionInProgress else {
			return
		}
		transitionInProgress = true
		beforeSwapping(fromViewController, to: toViewController)
		
		transition(from: fromViewController, to: toViewController, duration: transitionAnimationDuration, options: transitionAnimations, animations: {
			self.whileSwapping(from: fromViewController, to: toViewController)
		}) { (completed) in
			self.afterSwapping(from: fromViewController, to: toViewController)
			self.transitionInProgress = false
		}
	}
	
	// Actions performed before a swap is animated
	// Even if you override this method, it's recommended to call this, as it generates the required notifications
	open func beforeSwapping(_ currentViewController: UIViewController, to toViewController: UIViewController) {
		toViewController.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
		self.willUnpresent(self.destinationController(toViewController))
		currentViewController.willMove(toParentViewController: nil)
		
		self.willPresent(self.destinationController(toViewController))
		self.addChildViewController(toViewController)
		toViewController.willMove(toParentViewController: self)
	}
	
	// Actions to be performed during the animation swap
	open func whileSwapping(from fromViewController: UIViewController, to toViewController: UIViewController) {
	}
	
	// Actions to be performed after the animation swap
	// Even if you override this method, it's recommended to call this, as it generates the required notifications
	open func afterSwapping(from fromViewController: UIViewController, to toViewController: UIViewController) {
		fromViewController.removeFromParentViewController()
		toViewController.didMove(toParentViewController: self)
		self.didUnpresent(self.destinationController(fromViewController))
		self.didPresent(self.destinationController(toViewController))
	}
	
}
