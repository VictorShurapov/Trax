//
//  ImageViewController.swift
//  Cassini
//
//  Created by Victor Shurapov on 10/24/17.
//  Copyright © 2017 VVV. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {
    
    // our Model
    // publicly settable
    // when it changes (but only if we are on screen)
    //   we'll fetch the image from the imageURL
    // if we're off screen when this happens (view.window == nil)
    //   viewWillAppear will get it for us later
    var imageURL: URL? {
        didSet {
            image = nil
            if view.window != nil {
                fetchImage()
            }
        }
    }
    
    private func fetchImage() {
        guard let url = imageURL else {
            return
        }
        spinner?.startAnimating()
        DispatchQueue.global(qos: .userInitiated).async {
            let imageDataOpt = try? Data(contentsOf: url) // this blocks the thread it is on
            DispatchQueue.main.async {
                // only do something with this image
                // if the url we fetched is the current imageURL we want
                // (that might have changed while we were off fetching this one)
                if url == self.imageURL {
                    guard let imageData = imageDataOpt else {
                        self.image = nil
                        return
                    }
                    self.image = UIImage(data: imageData)
                }
            }
        }
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.contentSize = imageView.frame.size // critical to set this!
            scrollView.delegate = self                    // required for zooming
            scrollView.minimumZoomScale = 0.03            // required for zooming
            scrollView.maximumZoomScale = 1.0             // required for zooming
        }
    }
    
    // UIScrollViewDelegate method
    // required for zooming
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    private var imageView = UIImageView()
    
    // convenience computed property
    // lets us get involved every time we set an image in imageView
    // we can do things like resize the imageView,
    //   set the scroll view's contentSize,
    //   and stop the spinner
    private var image: UIImage? {
        get { return imageView.image }
        set {
            imageView.image = newValue
            imageView.sizeToFit()
            scrollView?.contentSize = imageView.frame.size
            spinner?.stopAnimating()
        }
    }
    
    // put our imageView into the view hierarchy
    // as a subview of the scrollView
    // (will install it into the content area of the scroll view)
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.addSubview(imageView)
    }
    
    // for efficiency, we will only actually fetch the image
    // when we know we are going to be on screen
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if image == nil {
            fetchImage()
        }
    }
}
