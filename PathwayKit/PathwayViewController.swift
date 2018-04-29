//
//  PathwayViewControllr.swift
//  PathwayKit
//
//  Created by Shane Whitehead on 30/4/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import Foundation

// A destination identifer - ie segue
struct PathwayDestination: Hashable {
	let identifier: String
}

// A router between pathways
protocol PathwayRouter {
	func navigate(to: PathwayDestination)
}

//extension PathwayDestination {
//	static let navigationContoller = PathwayDestination(identifier: "ToNavigationView")
//	static let tabController = PathwayDestination(identifier: "ToTabView")
//}

// The primary pathway view controller, which also acts as the pathway router
// This is a really good place to start for implementations who wish for the
// parent view controller to control the navigation
class PathViewController: UIViewController, PathwayRouter {

	// The "first" controller shown by default
	var defaultController: PathwayDestination!
	// The avaliable destinations
	var destinations: [PathwayDestination] = []
	
	// The current destination
	var currentDestination: PathwayDestination!
	var transitionInProgress: Bool = false
	
	var destinationControllers: [PathwayDestination: UIViewController] = [:]
	
	override func viewDidLoad() {
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
	func destinationController(_ viewController: UIViewController) -> UIViewController {
		guard let controller = viewController as? UINavigationController else {
			return viewController
		}
		return controller.viewControllers.first!
	}

	// Called before the controller is "presented"
	func willPresent(_ viewController: UIViewController) {
	}
	
	// Called after the controller is "presented"
	func didPresent(_ viewController: UIViewController) {
	}
	
	// Called before the controller is "unpresented", but before
	// "willPresent" is called for the new controller
	func willUnpresent(_ viewController: UIViewController) {
	}
	
	// Called after the controller is "unpresented", but before
	// "didPresent" is called for the new controller
	func didUnpresent(_ viewController: UIViewController) {
	}
	
	// Core navigation router
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
	func navigate(to: PathwayDestination) {
		performSegue(withIdentifier: to.identifier, sender: self)
	}
	
	// Swaps to specified destination
	func swap(to: PathwayDestination) {
		swap(from: currentDestination, to: to)
	}
	
	// Swaps from/to the sepcified destinations
	func swap(from: PathwayDestination, to: PathwayDestination) {
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
	func swap(from fromViewController: UIViewController, to toViewController: UIViewController) {
		guard !transitionInProgress else {
			return
		}
		transitionInProgress = true
		toViewController.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
		willUnpresent(destinationController(toViewController))
		fromViewController.willMove(toParentViewController: nil)
		
		willPresent(destinationController(toViewController))
		addChildViewController(toViewController)
		toViewController.willMove(toParentViewController: self)
		
		transition(from: fromViewController, to: toViewController, duration: 1.0, options: .transitionCrossDissolve, animations: {
			
		}) { (completed) in
			fromViewController.removeFromParentViewController()
			toViewController.didMove(toParentViewController: self)
			self.transitionInProgress = false
			self.didUnpresent(self.destinationController(fromViewController))
			self.didPresent(self.destinationController(toViewController))
		}
	}
	
}