//
//  PathwayHubViewController.swift
//  PathwayKit
//
//  Created by Shane Whitehead on 30/4/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import Foundation

// A contract used to allow child destinations to gain access back to the controlling
// router
protocol DestinationViewController {
	var hubController: PathwayRouter! { set get }
}

// The Pathway hub controller is intended to be used in situations where the child views
// need to control the navigation
class PathwayHubViewController: PathViewController {
	
	// Oppurtunity to pass information to the controller
	override func willPresent(_ viewController: UIViewController) {
		guard var viewController = viewController as? DestinationViewController else {
			return
		}
		viewController.hubController = self
	}
	
	override func didPresent(_ viewController: UIViewController) {
		
	}
	
	// Oppurtunity to grab information from the controller
	override func willUnpresent(_ viewController: UIViewController) {
		
	}
	
	override func didUnpresent(_ viewController: UIViewController) {
		guard var viewController = viewController as? DestinationViewController else {
			return
		}
		viewController.hubController = nil
	}
}