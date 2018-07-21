//
//  EditWaypointViewController.swift
//  Trax
//
//  Created by Victor Shurapov on 6/22/18.
//  Copyright © 2018 Victor Shurapov. All rights reserved.
//

import UIKit
import MobileCoreServices

class EditWaypointViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Public API
    
    var waypointToEdit: EditableWaypoint? { didSet { updateUI() } }
    
    // MARK: - Private Implementation
    
    private func updateUI() {
        nameTextField?.text = waypointToEdit?.name
        infoTextField?.text = waypointToEdit?.info
        updateImage()
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
    
    // MARK: - ImageView
    
    var imageView = UIImageView()
    @IBOutlet weak var imageViewContainer: UIView! {
        didSet {
            // we put a generic UIView in our autolayout
            // because it will shrink and grow as the space allows
            // (versus a UIImageView which demands space to show its image)
            // we will manage the frame of the image view ourself
            // (in makeRoomForImage() below)
            imageViewContainer.addSubview(imageView)
        }
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            // if video, check media types
            picker.mediaTypes = [kUTTypeImage] as [String]
            picker.delegate = self
            picker.allowsEditing = true
            present(picker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var image = info[UIImagePickerControllerEditedImage] as? UIImage
        if image == nil {
            image = info[UIImagePickerControllerOriginalImage] as? UIImage
        }
        imageView.image = image
        makeRoomForImage()
        saveImageInWaypoint()
        dismiss(animated: true, completion: nil)
    }
    
    // we save the image in the file system here, but we never remove it
    // obviously this demo is only the start of this application
    // not only would we need to manage the images in our filesystem
    // but we don't even save our edited waypoints from app launch to app launch
    // (we'd probably want to be able to write these edited waypoints to a gpx file too)
    // the goal here is just to show how to access the file system
    func saveImageInWaypoint() {
        if let image = imageView.image {
            if let imageData = UIImageJPEGRepresentation(image, 1.0) {
                let fileManager = FileManager()
                if let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let unique = Date.timeIntervalSinceReferenceDate
                    let url = docsDir.appendingPathComponent("\(unique).jpg")
                    let path = url.absoluteString
                    if (try? imageData.write(to: url, options: .atomic)) != nil {
                        
                        let thumbnailLink = GPX.Link(href: path)
                        thumbnailLink.type = "thumbnail"
                        
                        let imageLink = GPX.Link(href: path)
                        imageLink.type = "large"
                        
                        waypointToEdit?.links = [thumbnailLink, imageLink]
                    }
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
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
extension EditWaypointViewController {
    func updateImage() {
        if let url = waypointToEdit?.imageURL {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let strongSelf = self else { return }
                if let imageData = try? Data(contentsOf: url) {
                    if url == strongSelf.waypointToEdit?.imageURL {
                        if let image = UIImage(data: imageData) {
                            DispatchQueue.main.async {
                                strongSelf.imageView.image = image
                                self?.makeRoomForImage()
                            }
                        }
                    }
                }
                
            }
        }
    }
    
    // all we do in makeRoomForImage() is adjust our preferredContentSize
    // we assume that our preferredContentSize is what is currently desired (pre-adjustment)
    // then we adjust it to make up for any differences in the size of our image view or its container
    // if our preferredContentSize change can be accomodated, our container will get taller
    // and more of our image will show
    // if not, we tried our best to show as much of the image as possible
    // because we use the entire width of our container view and
    // show an appropriate height depending on our image's aspect ratio
    // this is sort of a "quick and dirty" way to do this
    // in a real application, one would probably want to be more exacting here
    // (perhaps apply more sophisticated autolayout to the problem)
    func makeRoomForImage() {
        var extraHeight: CGFloat = 0
        
        if imageView.image?.aspectRatio != 0 {
            if let width = imageView.superview?.frame.size.width {
                let height = width / imageView.image!.aspectRatio
                extraHeight = height - imageView.frame.height
                imageView.frame = CGRect(x: 0, y: 0, width: width, height: height)
            }
        } else {
            extraHeight = -imageView.frame.height
            imageView.frame = CGRect.zero
        }
        preferredContentSize = CGSize(width: preferredContentSize.width, height: preferredContentSize.height + extraHeight)
    }
}

extension UIImage {
    var aspectRatio: CGFloat {
        return size.height != 0 ? size.width / size.height : 0
    }
}
