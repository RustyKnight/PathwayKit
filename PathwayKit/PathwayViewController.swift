//
//  PathwayViewControllr.swift
//  PathwayKit
//
//  Created by Shane Whitehead on 30/4/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import Foundation

// A destination identifer - ie segue
public struct PathwayDestination: Hashable {
	let identifier: String
	
	public init(identifier: String) {
		self.identifier = identifier
	}
}

// A router between pathways
public protocol PathwayRouter {
	func navigate(to: PathwayDestination)
}

// The primary pathway view controller, which also acts as the pathway router
// This is a really good place to start for implementations who wish for the
// parent view controller to control the navigation
open class PathViewController: UIViewController, PathwayRouter {

	// The "first" controller shown by default
	public var defaultController: PathwayDestination!
	// The avaliable destinations
	public var destinations: [PathwayDestination] = []
	
	// The current destination
	public var currentDestination: PathwayDestination!
	public private(set) var transitionInProgress: Bool = false
	
	public var destinationControllers: [PathwayDestination: UIViewController] = [:]
	
	override open func viewDidLoad() {
		super.viewDidLoad()
		currentDestination = defaultController
		performSegue(withIdentifier: currentDestination.identifier, sender: self)
	}
	
	// A reverse lookup mechanism to find a matching destination
	// from a segue identifier
	internal func destination(for segue: UIStoryboardSegue) -> PathwayDestination? {
		for destination in destinations {
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
	// This is imporant, as the "presenting" controller is what gets added to the container,
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
		if segue.identifier == defaultController.identifier && childViewControllers.count == 0 {
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
	open func navigate(to: PathwayDestination) {
		performSegue(withIdentifier: to.identifier, sender: self)
	}
	
	// Swaps to specified destination
	public func swap(to: PathwayDestination) {
		swap(from: currentDestination, to: to)
	}
	
	// Swaps from/to the sepcified destinations
	public func swap(from: PathwayDestination, to: PathwayDestination) {
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
		
		currentDestination = to
		swap(from: currentViewController, to: destinationViewController)
	}
	
	// Swaps the physical view controllers
	internal func swap(from fromViewController: UIViewController, to toViewController: UIViewController) {
		guard !transitionInProgress else {
			return
		}
		transitionInProgress = true
		performTranisition(from: fromViewController, to: toViewController) {
			self.transitionInProgress = false
		}
	}
	
	// This performs the tranisition.  The drfault implementation calls the performSwap function, which uses
	// transition(from:to:duration:options:animations:completed) to animate the swap
	// The function will, "before" set up the incoming and outgoing views
	// "during" do nothing
	// "after" remove the out going view and then call "then" to allow the API to perform it's internal clean up
	open func performTranisition(from fromViewController: UIViewController,
															 to toViewController: UIViewController,
															 then: @escaping () -> Void) {
		performSwap(from: fromViewController, to: toViewController, before: {
			toViewController.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
			self.willUnpresent(self.destinationController(toViewController))
			fromViewController.willMove(toParentViewController: nil)
			
			self.willPresent(self.destinationController(toViewController))
			self.addChildViewController(toViewController)
			toViewController.willMove(toParentViewController: self)
		}, during: {
			
		}) {
			fromViewController.removeFromParentViewController()
			toViewController.didMove(toParentViewController: self)
			self.didUnpresent(self.destinationController(fromViewController))
			self.didPresent(self.destinationController(toViewController))
			then()
		}
	}

	// This is an oppurtunity to swap out the default animation process
	// "before" will set up the incoming view controller in it's default location and add it. It will generate the required notifications for both view controllers
	// "during" is the actions to be carried out during the animation
	// "after" s the actions to be carried out after the animations, this removes the out going controller and generates the required notifications
	open func performSwap(from fromViewController: UIViewController,
												to toViewController: UIViewController,
												before: @escaping () -> Void,
												during: @escaping () -> Void,
												after: @escaping  () -> Void) {
		before()
		transition(from: fromViewController, to: toViewController, duration: 1.0, options: .transitionCrossDissolve, animations: {
			during()
		}) { (completed) in
			after()
		}
	}
	
}
