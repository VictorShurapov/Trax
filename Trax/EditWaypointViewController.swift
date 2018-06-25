//
//  EditWaypointViewController.swift
//  Trax
//
//  Created by Victor Shurapov on 6/22/18.
//  Copyright © 2018 Victor Shurapov. All rights reserved.
//

import UIKit

class EditWaypointViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Public API
    
    var waypointToEdit: EditableWaypoint? { didSet { updateUI() } }
    
    // MARK: - Private Implementation
    
    private func updateUI() {
        nameTextField?.text = waypointToEdit?.name
        infoTextField?.text = waypointToEdit?.info
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
            super.viewDidLoad()
            nameTextField.becomeFirstResponder()
            updateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startObservingTextFields()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopObservingTextFields()
    }

    // MARK: - Text Fields
    
    @IBOutlet weak var nameTextField: UITextField! { didSet { nameTextField.delegate = self } }
    @IBOutlet weak var infoTextField: UITextField! { didSet { infoTextField.delegate = self } }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    private var ntfObserver: NSObjectProtocol?
    private var itfObserver: NSObjectProtocol?
    
    private func startObservingTextFields() {
        
        let center = NotificationCenter.default
        let queue = OperationQueue.main
        
        ntfObserver = center.addObserver(forName: .UITextFieldTextDidChange, object: nameTextField, queue: queue) { (notification) in
            if let waypoint = self.waypointToEdit {
                waypoint.name = self.nameTextField.text
            }
        }
        
        itfObserver = center.addObserver(forName: .UITextFieldTextDidChange, object: infoTextField, queue: queue) { (notification) in
            if let waypoint = self.waypointToEdit {
                waypoint.info = self.infoTextField.text
            }
        }
        
    }
    
    private func stopObservingTextFields() {
        if let observer = ntfObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = itfObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
