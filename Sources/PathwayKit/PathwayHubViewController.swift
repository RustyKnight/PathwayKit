//
//  PathwayHubViewController.swift
//  PathwayKit
//
//  Created by Shane Whitehead on 30/4/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import Foundation
import UIKit

// A contract used to allow child destinations to gain access back to the controlling
// router
@objc public protocol DestinationViewController {
	@objc var hubController: PathwayRouter? { set get }
}

// The Pathway hub controller is intended to be used in situations where the child views
// need to control the navigation
@objc open class PathwayHubViewController: PathwayRouterViewController {
	
	// Oppurtunity to pass information to the controller
	override open func willPresent(_ viewController: UIViewController) {
		guard let viewController = viewController as? DestinationViewController else {
			return
		}
		viewController.hubController = self
	}
	
	override open func didPresent(_ viewController: UIViewController) {
		
	}
	
	// Oppurtunity to grab information from the controller
	override open func willUnpresent(_ viewController: UIViewController) {
		
	}
	
	override open func didUnpresent(_ viewController: UIViewController) {
		guard let viewController = viewController as? DestinationViewController else {
			return
		}
		viewController.hubController = nil
	}
}
