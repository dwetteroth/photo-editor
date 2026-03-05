//
//  PhotoEditor+Controls.swift
//  Pods
//
//  Created by Mohamed Hamed on 6/16/17.
//
//

import Foundation
import UIKit

// MARK: - Control
public enum control: String {
    case crop
    case sticker
    case draw
    case text
    case save
    case share
    case clear

    public func string() -> String {
        return self.rawValue
    }
}

extension PhotoEditorViewController {

     //MARK: Top Toolbar
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        photoEditorDelegate?.canceledEditing()
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func cropButtonTapped(_ sender: UIButton) {
        let controller = CropViewController()
        controller.delegate = self
        controller.image = image
        let navController = UINavigationController(rootViewController: controller)
        present(navController, animated: true, completion: nil)
    }

    @IBAction func stickersButtonTapped(_ sender: Any) {
        addStickersViewController()
    }

    @IBAction func drawButtonTapped(_ sender: Any) {
        isDrawing = true
        canvasImageView.isUserInteractionEnabled = false
        doneButton.isHidden = false
        colorPickerView.isHidden = false
        hideToolbar(hide: true)
    }

    @IBAction func textButtonTapped(_ sender: Any) {
        isTyping = true
        let textView = UITextView(frame: CGRect(x: 0, y: canvasImageView.center.y,
                                                width: UIScreen.main.bounds.width, height: 30))

        textView.textAlignment = .center
        textView.font = UIFont(name: "Helvetica", size: 30)
        textView.textColor = textColor
        textView.layer.shadowColor = UIColor.black.cgColor
        textView.layer.shadowOffset = CGSize(width: 1.0, height: 0.0)
        textView.layer.shadowOpacity = 0.2
        textView.layer.shadowRadius = 1.0
        textView.layer.backgroundColor = UIColor.clear.cgColor
        textView.autocorrectionType = .no
        textView.isScrollEnabled = false
        textView.delegate = self
        self.canvasImageView.addSubview(textView)
        addGestures(view: textView)
        undoStack.append(.subviewAdded(view: textView))
        trimUndoStack()
        updateUndoButtonVisibility()
        textView.becomeFirstResponder()
    }    
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        view.endEditing(true)
        doneButton.isHidden = true
        colorPickerView.isHidden = true
        canvasImageView.isUserInteractionEnabled = true
        hideToolbar(hide: false)
        isDrawing = false
    }
    
    //MARK: Bottom Toolbar
    
    @IBAction func saveButtonTapped(_ sender: AnyObject) {
        UIImageWriteToSavedPhotosAlbum(canvasView.toImage(),self, #selector(PhotoEditorViewController.image(_:withPotentialError:contextInfo:)), nil)
    }
    
    @IBAction func shareButtonTapped(_ sender: UIButton) {
        let activity = UIActivityViewController(activityItems: [canvasView.toImage()], applicationActivities: nil)
        if let popoverController = activity.popoverPresentationController {
            popoverController.barButtonItem = UIBarButtonItem(customView: sender)
        }

        present(activity, animated: true, completion: nil)
        
    }
    
    @IBAction func clearButtonTapped(_ sender: AnyObject) {
        //clear drawing
        canvasImageView.image = nil
        //clear stickers and textviews
        for subview in canvasImageView.subviews {
            subview.removeFromSuperview()
        }
        undoStack.removeAll()
        updateUndoButtonVisibility()
    }
    
    @IBAction func continueButtonPressed(_ sender: Any) {
        let image = self.canvasView.toImage()
        photoEditorDelegate?.doneEditing(image: image)
        self.dismiss(animated: true, completion: nil)
    }

    //MAKR: helper methods
    
    @objc func image(_ image: UIImage, withPotentialError error: NSErrorPointer, contextInfo: UnsafeRawPointer) {
        let alert = UIAlertController(title: "Image Saved", message: "Image successfully saved to Photos library", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func hideControls() {
        var controls = hiddenControls

        for control in controls {
            if (control == "clear") {
                clearButton.isHidden = true
            } else if (control == "crop") {
                cropButton.isHidden = true
            } else if (control == "draw") {
                drawButton.isHidden = true
            } else if (control == "save") {
                saveButton.isHidden = true
            } else if (control == "share") {
                shareButton.isHidden = true
            } else if (control == "sticker") {
                stickerButton.isHidden = true
            } else if (control == "text") {
                textButton.isHidden = true
            }
        }
    }

    // MARK: - Undo

    @objc func undoButtonTapped() {
        performUndo()
    }

    func performUndo() {
        guard let lastAction = undoStack.popLast() else { return }

        switch lastAction {
        case .drawingStroke(let previousImage):
            canvasImageView.image = previousImage
        case .subviewAdded(let view):
            view.removeFromSuperview()
        }
        updateUndoButtonVisibility()
    }

    func updateUndoButtonVisibility() {
        undoButton?.isHidden = undoStack.isEmpty
    }

    func trimUndoStack() {
        while undoStack.count > maxUndoStackSize {
            undoStack.removeFirst()
        }
    }

    // MARK: - Shapes

    @objc func shapesButtonTapped() {
        shapeSelectionView?.isHidden.toggle()
    }

    @objc func addRectangle() {
        placeShape(type: .rectangle)
        shapeSelectionView?.isHidden = true
    }

    @objc func addCircle() {
        placeShape(type: .circle)
        shapeSelectionView?.isHidden = true
    }

    @objc func addArrow() {
        placeShape(type: .arrow)
        shapeSelectionView?.isHidden = true
    }

    func placeShape(type: ShapeView.Shape) {
        let size: CGSize
        switch type {
        case .rectangle: size = CGSize(width: 150, height: 100)
        case .circle:    size = CGSize(width: 120, height: 120)
        case .arrow:     size = CGSize(width: 160, height: 80)
        }

        let shapeView = ShapeView(shape: type, color: drawColor, size: size)
        shapeView.center = canvasImageView.center
        canvasImageView.addSubview(shapeView)
        addGestures(view: shapeView)

        undoStack.append(.subviewAdded(view: shapeView))
        trimUndoStack()
        updateUndoButtonVisibility()
    }
}
