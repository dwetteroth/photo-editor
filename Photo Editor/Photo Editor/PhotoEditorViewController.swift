//
//  ViewController.swift
//  Photo Editor
//
//  Created by Mohamed Hamed on 4/23/17.
//  Copyright © 2017 Mohamed Hamed. All rights reserved.
//

import UIKit

public final class PhotoEditorViewController: UIViewController {
    
    /** holding the 2 imageViews original image and drawing & stickers */
    @IBOutlet weak var canvasView: UIView!
    //To hold the image
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    //To hold the drawings and stickers
    @IBOutlet weak var canvasImageView: UIImageView!

    @IBOutlet weak var topToolbar: UIView!
    @IBOutlet weak var bottomToolbar: UIView!

    @IBOutlet weak var topGradient: UIView!
    @IBOutlet weak var bottomGradient: UIView!
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var colorsCollectionView: UICollectionView!
    @IBOutlet weak var colorPickerView: UIView!
    @IBOutlet weak var colorPickerViewBottomConstraint: NSLayoutConstraint!
    
    //Controls
    @IBOutlet weak var cropButton: UIButton!
    @IBOutlet weak var stickerButton: UIButton!
    @IBOutlet weak var drawButton: UIButton!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    @objc public var image: UIImage?
    /**
     Array of Stickers -UIImage- that the user will choose from
     */
    @objc public var stickers : [UIImage] = []
    /**
     Array of Colors that will show while drawing or typing
     */
    @objc public var colors  : [UIColor] = []
    
    @objc public var photoEditorDelegate: PhotoEditorDelegate?
    var colorsCollectionViewDelegate: ColorsCollectionViewDelegate!
    
    // list of controls to be hidden
    @objc public var hiddenControls : [NSString] = []

    var stickersVCIsVisible = false
    var drawColor: UIColor = UIColor.black
    var textColor: UIColor = UIColor.white
    var isDrawing: Bool = false
    var lastPoint: CGPoint!
    var swiped = false
    var lastPanPoint: CGPoint?
    var lastTextViewTransform: CGAffineTransform?
    var lastTextViewTransCenter: CGPoint?
    var lastTextViewFont:UIFont?
    var activeTextView: UITextView?
    var imageViewToPan: UIImageView?
    var isTyping: Bool = false

    // Undo
    var undoStack: [UndoAction] = []
    var drawingSnapshotBeforeStroke: UIImage? = nil
    let maxUndoStackSize = 20

    // UI for undo and shapes
    var undoButton: UIButton!
    var shapesButton: UIButton!
    var shapeSelectionView: UIStackView!

    var stickersViewController: StickersViewController!

    //Register Custom font before we load XIB
    public override func loadView() {
        registerFont()
        super.loadView()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.setImageView(image: image!)
        
        deleteView.layer.cornerRadius = deleteView.bounds.height / 2
        deleteView.layer.borderWidth = 2.0
        deleteView.layer.borderColor = UIColor.white.cgColor
        deleteView.clipsToBounds = true
        
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
        edgePan.edges = .bottom
        edgePan.delegate = self
        self.view.addGestureRecognizer(edgePan)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow),
                                               name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(keyboardWillChangeFrame(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        
        configureCollectionView()
        stickersViewController = StickersViewController(nibName: "StickersViewController", bundle: Bundle(for: StickersViewController.self))
        hideControls()
        setupUndoButton()
        setupShapesButton()
        setupShapeSelectionView()
    }
    
    func configureCollectionView() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 30, height: 30)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        colorsCollectionView.collectionViewLayout = layout
        colorsCollectionViewDelegate = ColorsCollectionViewDelegate()
        colorsCollectionViewDelegate.colorDelegate = self
        if !colors.isEmpty {
            colorsCollectionViewDelegate.colors = colors
        }
        colorsCollectionView.delegate = colorsCollectionViewDelegate
        colorsCollectionView.dataSource = colorsCollectionViewDelegate
        
        colorsCollectionView.register(
            UINib(nibName: "ColorCollectionViewCell", bundle: Bundle(for: ColorCollectionViewCell.self)),
            forCellWithReuseIdentifier: "ColorCollectionViewCell")
    }
    
    func setImageView(image: UIImage) {
        imageView.image = image
        let size = image.suitableSize(widthLimit: UIScreen.main.bounds.width)
        imageViewHeightConstraint.constant = (size?.height)!
    }
    
    func hideToolbar(hide: Bool) {
        topToolbar.isHidden = hide
        topGradient.isHidden = hide
        bottomToolbar.isHidden = hide
        bottomGradient.isHidden = hide
        shapesButton?.isHidden = hide
        if hide {
            shapeSelectionView?.isHidden = true
        }
    }

    // MARK: - Undo & Shapes UI Setup

    func setupUndoButton() {
        undoButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            undoButton.setImage(UIImage(systemName: "arrow.uturn.backward", withConfiguration: config), for: .normal)
        } else {
            undoButton.setTitle("Undo", for: .normal)
        }
        undoButton.tintColor = .white
        undoButton.addTarget(self, action: #selector(undoButtonTapped), for: .touchUpInside)
        undoButton.isHidden = true
        undoButton.translatesAutoresizingMaskIntoConstraints = false
        undoButton.layer.shadowColor = UIColor.black.cgColor
        undoButton.layer.shadowOffset = CGSize(width: 1, height: 1)
        undoButton.layer.shadowOpacity = 0.5
        undoButton.layer.shadowRadius = 2
        view.addSubview(undoButton)

        NSLayoutConstraint.activate([
            undoButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            undoButton.bottomAnchor.constraint(equalTo: bottomToolbar.topAnchor, constant: -12),
            undoButton.widthAnchor.constraint(equalToConstant: 44),
            undoButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    func setupShapesButton() {
        shapesButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            shapesButton.setImage(UIImage(systemName: "square.on.circle", withConfiguration: config), for: .normal)
        } else {
            shapesButton.setTitle("Shapes", for: .normal)
        }
        shapesButton.tintColor = .white
        shapesButton.addTarget(self, action: #selector(shapesButtonTapped), for: .touchUpInside)
        shapesButton.translatesAutoresizingMaskIntoConstraints = false
        shapesButton.layer.shadowColor = UIColor.black.cgColor
        shapesButton.layer.shadowOffset = CGSize(width: 1, height: 1)
        shapesButton.layer.shadowOpacity = 0.5
        shapesButton.layer.shadowRadius = 2
        view.addSubview(shapesButton)

        NSLayoutConstraint.activate([
            shapesButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            shapesButton.topAnchor.constraint(equalTo: topToolbar.bottomAnchor, constant: 8),
            shapesButton.widthAnchor.constraint(equalToConstant: 44),
            shapesButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    func setupShapeSelectionView() {
        let rectBtn = makeShapeButton(
            systemName: "rectangle",
            fallbackTitle: "[ ]",
            action: #selector(addRectangle)
        )
        let circleBtn = makeShapeButton(
            systemName: "circle",
            fallbackTitle: "O",
            action: #selector(addCircle)
        )
        let arrowBtn = makeShapeButton(
            systemName: "arrow.right",
            fallbackTitle: "->",
            action: #selector(addArrow)
        )

        shapeSelectionView = UIStackView(arrangedSubviews: [rectBtn, circleBtn, arrowBtn])
        shapeSelectionView.axis = .horizontal
        shapeSelectionView.spacing = 4
        shapeSelectionView.distribution = .fillEqually
        shapeSelectionView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        shapeSelectionView.layer.cornerRadius = 10
        shapeSelectionView.clipsToBounds = true
        shapeSelectionView.isLayoutMarginsRelativeArrangement = true
        shapeSelectionView.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        shapeSelectionView.isHidden = true
        shapeSelectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shapeSelectionView)

        NSLayoutConstraint.activate([
            shapeSelectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            shapeSelectionView.topAnchor.constraint(equalTo: shapesButton.bottomAnchor, constant: 4),
            shapeSelectionView.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    func makeShapeButton(systemName: String, fallbackTitle: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            btn.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        } else {
            btn.setTitle(fallbackTitle, for: .normal)
        }
        btn.tintColor = .white
        btn.addTarget(self, action: action, for: .touchUpInside)
        btn.widthAnchor.constraint(equalToConstant: 48).isActive = true
        return btn
    }
}

extension PhotoEditorViewController: ColorDelegate {
    func didSelectColor(color: UIColor) {
        if isDrawing {
            self.drawColor = color
        } else if activeTextView != nil {
            activeTextView?.textColor = color
            textColor = color
        }
    }
}
