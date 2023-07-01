//
//  WHSheetViewController.swift
//  
//
//  Created by shachi on 2023/05/28.
//

import UIKit

@available(iOS 13.0, *)
public class WHSheetViewController: UIViewController {
    public private(set) var options: WHOptions

    public weak var delegate: WHSheetViewDelegate?


    /// Default true
    public static var autoAdjustToKeyboard = true
    /// キーボードの大きさに合わせるかどうか? Default false
    public var autoAdjustToKeyboard = WHSheetViewController.autoAdjustToKeyboard

    /// Default true
    public static var allowPullingPastMaxHeight = true
    /// バウンス周り Default true
    public var allowPullingPastMaxHeight = WHSheetViewController.allowPullingPastMaxHeight

    /// DDefaults true
    public static var allowPullingPastMinHeight = true
    /// バウンスバック (上のはバウンストップ) Default true
    public var allowPullingPastMinHeight = WHSheetViewController.allowPullingPastMinHeight

    /// シートのpinサイズ Defaults intrinsic のみ
    public var sizes: [WHSize] = [.intrinsic] {
        didSet {
            self.updateOrderedSizes()
        }
    }
    public var orderedSizes: [WHSize] = []
    public private(set) var currentSize: WHSize = .intrinsic
    /// プルダウンでシート解除可能スイッチ
    public var dismissOnPull: Bool = true {
        didSet {
            self.updateAccessibility()
        }
    }
    /// 背景タップで解除スイッチ
    public var dismissOnOverlayTap: Bool = true {
        didSet {
            self.updateAccessibility()
        }
    }
    /// ボタンをつかんでドラッグして、シートをコントロールするかどうかのスイッチ
    public var shouldRecognizePanGestureWithUIControls: Bool = true

    /// 現在のシートビュー
    public var childViewController: UIViewController {
        return self.contentViewController.childViewController
    }

    public override var childForStatusBarStyle: UIViewController? {
        childViewController
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return childViewController.supportedInterfaceOrientations
    }

    public static var hasBlurBackground = false
    public var hasBlurBackground = WHSheetViewController.hasBlurBackground {
        didSet {
            blurView.isHidden = !hasBlurBackground
            overlayView.backgroundColor = hasBlurBackground ? .clear : self.overlayColor
        }
    }

    public static var minimumSpaceAbovePullBar: CGFloat = 0
    public var minimumSpaceAbovePullBar: CGFloat {
        didSet {
            if self.isViewLoaded {
                self.resize(to: self.currentSize)
            }
        }
    }

    /// Defaultのオーバーレイカラー
    public static var overlayColor = UIColor(white: 0, alpha: 0.25)
    /// オーバーレイ背景色
    public var overlayColor = WHSheetViewController.overlayColor {
        didSet {
            self.overlayView.backgroundColor = self.hasBlurBackground ? .clear : self.overlayColor
        }
    }

    /// default on
    public static var blurEffect: UIBlurEffect = {
        return UIBlurEffect(style: .prominent)
    }()

    public var blurEffect = WHSheetViewController.blurEffect {
        didSet {
            self.blurView.effect = blurEffect
        }
    }
    public static var allowGestureThroughOverlay: Bool = false
    public var allowGestureThroughOverlay: Bool = WHSheetViewController.allowGestureThroughOverlay {
        didSet {
            self.overlayTapView.isUserInteractionEnabled = !self.allowGestureThroughOverlay
        }
    }

    public static var cornerRadius: CGFloat = 12
    public var cornerRadius: CGFloat {
        get { return self.contentViewController.cornerRadius }
        set { self.contentViewController.cornerRadius = newValue }
    }

    public static var cornerCurve: CALayerCornerCurve = .circular

    public var cornerCurve: CALayerCornerCurve {
        get { return self.contentViewController.cornerCurve }
        set { self.contentViewController.cornerCurve = newValue }
    }

    public static var gripSize: CGSize = CGSize (width: 50, height: 6)
    public var gripSize: CGSize {
        get { return self.contentViewController.gripSize }
        set { self.contentViewController.gripSize = newValue }
    }

    public static var gripColor: UIColor = UIColor(white: 0.868, black: 0.1)
    public var gripColor: UIColor? {
        get { return self.contentViewController.gripColor }
        set { self.contentViewController.gripColor = newValue }
    }

    public static var pullBarBackgroundColor: UIColor = UIColor.clear
    public var pullBarBackgroundColor: UIColor? {
        get { return self.contentViewController.pullBarBackgroundColor }
        set { self.contentViewController.pullBarBackgroundColor = newValue }
    }

    public static var treatPullBarAsClear: Bool = false
    public var treatPullBarAsClear: Bool {
        get { return self.contentViewController.treatPullBarAsClear }
        set { self.contentViewController.treatPullBarAsClear = newValue }
    }

    let transition: WHTransition

    public var shouldDismiss: ((WHSheetViewController) -> Bool)?
    public var didDismiss: ((WHSheetViewController) -> Void)?
    public var sizeChanged: ((WHSheetViewController, WHSize, CGFloat) -> Void)?
    public var panGestureShouldBegin: ((UIPanGestureRecognizer) -> Bool?)?

    public private(set) var contentViewController: WHContentViewController
    var overlayView = UIView()
    var blurView = UIVisualEffectView()
    var overlayTapView = UIView()
    var overflowView = UIView()
    var overlayTapGesture: UITapGestureRecognizer?
    private var contentViewHeightConstraint: NSLayoutConstraint!

    private weak var childScrollView: UIScrollView?

    private var keyboardHeight: CGFloat = 0
    private var firstPanPoint: CGPoint = CGPoint.zero
    private var panOffset: CGFloat = 0
    private var panGestureRecognizer: InitialTouchPanGestureRecognizer!
    private var prePanHeight: CGFloat = 0
    private var isPanning: Bool = false

    public var contentBackgroundColor: UIColor? {
        get { self.contentViewController.contentBackgroundColor }
        set { self.contentViewController.contentBackgroundColor = newValue }
    }

    // mapMode
    public func useMapMode(_ check: Bool) {
        if (check) {
            allowPullingPastMaxHeight = false
            allowPullingPastMinHeight = true

            dismissOnPull = true
            dismissOnOverlayTap = false
            overlayColor = UIColor.clear

            allowGestureThroughOverlay = true
        }
    }

    // close Button
    public var closeFillButtonOn: Bool = false

    private lazy var closeFillButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: self.view.bounds.midX - 26, y: self.view.bounds.height, width: 52, height: 44)
        button.backgroundColor = UIColor(red: 0.298, green: 0.298, blue: 0.298, alpha: 1.0)
        button.setImage(UIImage(systemName: "xmark",
                                withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .black)), for: .normal)
        button.tintColor = .white
        button.contentEdgeInsets = UIEdgeInsets.init(top: 10, left: 17, bottom: 10, right: 17)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()

    @objc public func closeButtonTapped() {
        closeFillButton.removeFromSuperview()
        NotificationCenter.default.post(name: Notification.Name("closeView"), object: self, userInfo: ["useInlineMode": self.options.useInlineMode])
    }

    public init(controller: UIViewController, sizes: [WHSize] = [.intrinsic], options: WHOptions? = nil) {
        let options = options ?? WHOptions.default
        self.contentViewController = WHContentViewController(childViewController: controller, options: options)
        self.contentViewController.contentBackgroundColor = UIColor.systemBackground

        self.sizes = sizes.count > 0 ? sizes : [.intrinsic]
        self.options = options
        self.transition = WHTransition(options: options)
        self.minimumSpaceAbovePullBar = WHSheetViewController.minimumSpaceAbovePullBar
        super.init(nibName: nil, bundle: nil)
        self.gripColor = WHSheetViewController.gripColor
        self.gripSize = WHSheetViewController.gripSize
        self.pullBarBackgroundColor = WHSheetViewController.pullBarBackgroundColor
        self.cornerRadius = WHSheetViewController.cornerRadius
        self.updateOrderedSizes()
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
        self.view.layer.removeAllAnimations()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        if self.options.useInlineMode {
            let whView = WHView()
            whView.delegate = self
            self.view = whView
        } else {
            super.loadView()
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.compatibleAdditionalSafeAreaInsets = UIEdgeInsets(top: -self.options.pullBarHeight, left: 0, bottom: 0, right: 0)

        self.view.backgroundColor = UIColor.clear
        self.addPanGestureRecognizer()
        self.addOverlay()
        self.addBlurBackground()
        self.addContentView()
        self.addOverlayTapView()
        self.registerKeyboardObservers()
        self.registerDismissObservers()
        self.resize(to: self.sizes.first ?? .intrinsic, animated: false)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateOrderedSizes()
        self.contentViewController.updatePreferredHeight()
        self.resize(to: self.currentSize, animated: false)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let presenter = self.transition.presenter, self.options.shrinkPresentingViewController {
            self.transition.restorePresentor(presenter, completion: { _ in
                self.didDismiss?(self)
            })
        } else if !self.options.useInlineMode {
            self.didDismiss?(self)
        }
    }

    /// 上下に引っ張ると、子ビューのスクロールビューが跳ね返るのではなく、シートが大きくなったり縮んだりするように
    public func handleScrollView(_ scrollView: UIScrollView) {
        scrollView.panGestureRecognizer.require(toFail: panGestureRecognizer)
        self.childScrollView = scrollView
    }

    /// シートがピンで固定されるサイズを変更する
    public func setSizes(_ sizes: [WHSize], animated: Bool = true) {
        guard sizes.count > 0 else {
            return
        }
        self.sizes = sizes

        self.resize(to: sizes[0], animated: animated)
    }

    func updateOrderedSizes() {
        var concreteSizes: [(WHSize, CGFloat)] = self.sizes.map {
            return ($0, self.height(for: $0))
        }
        concreteSizes.sort { $0.1 < $1.1 }
        self.orderedSizes = concreteSizes.map({ size, _ in size })
        self.updateAccessibility()
    }

    private func updateAccessibility() {
        let isOverlayAccessable = !self.allowGestureThroughOverlay && (self.dismissOnOverlayTap || self.dismissOnPull)
        self.overlayTapView.isAccessibilityElement = isOverlayAccessable

        var pullBarLabel = ""
        if !isOverlayAccessable && (self.dismissOnOverlayTap || self.dismissOnPull) {
            pullBarLabel = NSLocalizedString("dismissPresentation", comment: "")
        } else if self.orderedSizes.count > 1 {
            pullBarLabel = NSLocalizedString("changeSizeOfPresentation", comment: "")
        }

        self.contentViewController.pullBarView.isAccessibilityElement = !pullBarLabel.isEmpty
        self.contentViewController.pullBarView.accessibilityLabel = pullBarLabel
    }

    private func addOverlay() {
        self.view.addSubview(self.overlayView)
        Constraints(for: self.overlayView) {
            $0.edges(.top, .left, .right, .bottom).pinToSuperview()
        }
        self.overlayView.isUserInteractionEnabled = false
        self.overlayView.backgroundColor = self.hasBlurBackground ? .clear : self.overlayColor
    }

    private func addBlurBackground() {
        self.overlayView.addSubview(self.blurView)
        blurView.effect = blurEffect
        Constraints(for: self.blurView) {
            $0.edges(.top, .left, .right, .bottom).pinToSuperview()
        }
        self.blurView.isUserInteractionEnabled = false
        self.blurView.isHidden = !self.hasBlurBackground
    }

    private func addOverlayTapView() {
        let overlayTapView = self.overlayTapView
        overlayTapView.backgroundColor = .clear
        overlayTapView.isUserInteractionEnabled = !self.allowGestureThroughOverlay
        self.view.addSubview(overlayTapView)
        self.overlayTapView.accessibilityLabel = NSLocalizedString("dismissPresentation", comment: "")
        Constraints(for: overlayTapView, self.contentViewController.view) {
            $0.top.pinToSuperview()
            $0.left.pinToSuperview()
            $0.right.pinToSuperview()
            $0.bottom.align(with: $1.top)
        }

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
        self.overlayTapGesture = tapGestureRecognizer
        overlayTapView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func overlayTapped(_ gesture: UITapGestureRecognizer) {
        guard self.dismissOnOverlayTap else { return }
        self.attemptDismiss(animated: true)
    }

    private func addContentView() {
        self.contentViewController.willMove(toParent: self)
        self.addChild(self.contentViewController)
        self.view.addSubview(self.contentViewController.view)
        self.contentViewController.didMove(toParent: self)
        self.contentViewController.delegate = self
        Constraints(for: self.contentViewController.view) {
            $0.left.pinToSuperview().priority = UILayoutPriority(999)
            $0.left.pinToSuperview(inset: self.options.horizontalPadding, relation: .greaterThanOrEqual)
            if let maxWidth = self.options.maxWidth {
                $0.width.set(maxWidth, relation: .lessThanOrEqual)
            }

            $0.centerX.alignWithSuperview()
            self.contentViewHeightConstraint = $0.height.set(self.height(for: self.currentSize))

            let top: CGFloat
            if (self.options.useFullScreenMode) {
                top = 0
            } else {
                top = max(12, UIApplication.shared.windows.first(where:  { $0.isKeyWindow })?.compatibleSafeAreaInsets.top ?? 12)
            }
            $0.bottom.pinToSuperview()
            $0.top.pinToSuperview(inset: top, relation: .greaterThanOrEqual).priority = UILayoutPriority(999)
        }
    }

    private func addPanGestureRecognizer() {
        let panGestureRecognizer = InitialTouchPanGestureRecognizer(target: self, action: #selector(panned(_:)))
        self.view.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.delegate = self
        self.panGestureRecognizer = panGestureRecognizer
    }

    @objc func panned(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.translation(in: gesture.view?.superview)
        if gesture.state == .began {
            self.firstPanPoint = point
            self.prePanHeight = self.contentViewController.view.bounds.height
            self.isPanning = true
        }

        let minHeight: CGFloat = self.height(for: self.orderedSizes.first)
        let maxHeight: CGFloat
        if self.allowPullingPastMaxHeight {
            maxHeight = self.height(for: .fullscreen) // self.view.bounds.height
        } else {
            maxHeight = max(self.height(for: self.orderedSizes.last), self.prePanHeight)
        }

        var newHeight = max(0, self.prePanHeight + (self.firstPanPoint.y - point.y))
        var offset: CGFloat = 0
        if newHeight < minHeight {
            if self.allowPullingPastMinHeight {
                offset = minHeight - newHeight
            }
            newHeight = minHeight
        }
        if newHeight > maxHeight {
            if options.isRubberBandEnabled {
                newHeight = logConstraintValueForYPosition(verticalLimit: maxHeight, yPosition: newHeight)
            } else {
                newHeight = maxHeight
            }
        }

        delegate?.scrollChanged(frame: contentViewController.view.frame, state: gesture.state)
        
        switch gesture.state {
        case .cancelled, .failed:
            self.view.layer.removeAllAnimations()
            UIView.animate(withDuration: self.options.totalDuration, delay: 0, options: [.curveEaseOut], animations: {
                self.contentViewController.view.transform = CGAffineTransform.identity
                self.contentViewHeightConstraint.constant = self.height(for: self.currentSize)
                self.transition.setPresentor(percentComplete: 0)
                self.overlayView.alpha = 1
            }, completion: { _ in
                self.isPanning = false
            })

        case .began, .changed:
            self.contentViewHeightConstraint.constant = newHeight

            if offset > 0 {
                let percent = max(0, min(1, offset / max(1, newHeight)))
                self.transition.setPresentor(percentComplete: percent)
                self.overlayView.alpha = 1 - percent
                self.contentViewController.view.transform = CGAffineTransform(translationX: 0, y: offset)
            } else {
                self.contentViewController.view.transform = CGAffineTransform.identity
            }
        case .ended:
            let velocity = (self.options.totalDuration * gesture.velocity(in: self.view).y)
            var finalHeight = newHeight - offset - velocity
            if velocity > options.pullDismissThreshod {
                // They swiped hard, always just close the sheet when they do
                finalHeight = -1
            }

            let animationDuration = TimeInterval(abs(velocity*0.0002) + 0.1)

            // マイナスの時に表示を消す処理
            guard finalHeight > 0 || !self.dismissOnPull else {
                // Dismiss
                self.view.layer.removeAllAnimations()
                UIView.animate(
                    withDuration: animationDuration,
                    delay: 0,
                    usingSpringWithDamping: self.options.transitionDampening,
                    initialSpringVelocity: self.options.transitionVelocity,
                    options: self.options.transitionAnimationOptions,
                    animations: {
                        self.contentViewController.view.transform = CGAffineTransform(translationX: 0, y: self.contentViewController.view.bounds.height)
                        self.view.backgroundColor = UIColor.clear
                        self.transition.setPresentor(percentComplete: 1)
                        self.overlayView.alpha = 0
                    }, completion: { complete in
                        self.attemptDismiss(animated: false)
                    })
                return
            }

            var newSize = self.currentSize
            if point.y < 0 {
                // 高さのマイナスチェック
                newSize = self.orderedSizes.last ?? self.currentSize
                for size in self.orderedSizes.reversed() {
                    if finalHeight < self.height(for: size) {
                        newSize = size
                    } else {
                        break
                    }
                }
                if point.y <= 0 {
                    if closeFillButtonOn && (newSize == .fullscreen) {
                        closeFillButton.removeFromSuperview()
                        self.view.addSubview(closeFillButton)
                        NSLayoutConstraint.activate([
                            self.closeFillButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                            self.closeFillButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                        ])
                        self.view.layer.removeAllAnimations()
                        UIView.animate(withDuration: self.options.totalDuration, delay: 0.1, options: [.curveEaseOut], animations: {
                            self.closeFillButton.alpha = 1
                            self.closeFillButton.frame = CGRect(x: self.closeFillButton.frame.origin.x, y: self.closeFillButton.frame.origin.y - self.view.safeAreaInsets.bottom - 60, width: self.closeFillButton.frame.width, height: self.closeFillButton.frame.height)
                        })
                    }
                    if self.view.safeAreaInsets.top < 21 && newSize == .fullscreen {
                        self.pullBarBackgroundColor = .white
                    }
                }
            } else {
                // 大きい場合
                if self.view.safeAreaInsets.top < 21 {
                    self.pullBarBackgroundColor = .clear
                }
                newSize = self.orderedSizes.first ?? self.currentSize
                for size in self.orderedSizes {
                    if finalHeight > self.height(for: size) {
                        newSize = size
                    } else {
                        break
                    }
                }
                if closeFillButtonOn {
                    closeFillButton.removeFromSuperview()
                    self.closeFillButton.alpha = 0
                    self.closeFillButton.frame = CGRect(x: self.closeFillButton.frame.origin.x, y: self.closeFillButton.frame.origin.y - self.view.safeAreaInsets.bottom, width: self.closeFillButton.frame.width, height: self.closeFillButton.frame.height)
                }
            }
            let previousSize = self.currentSize
            self.currentSize = newSize

            let newContentHeight = self.height(for: newSize)
            self.view.layer.removeAllAnimations()
            UIView.animate(
                withDuration: animationDuration,
                delay: 0,
                usingSpringWithDamping: self.options.transitionDampening,
                initialSpringVelocity: self.options.transitionVelocity,
                options: self.options.transitionAnimationOptions,
                animations: {
                    self.contentViewController.view.transform = CGAffineTransform.identity
                    self.contentViewHeightConstraint.constant = newContentHeight
                    self.transition.setPresentor(percentComplete: 0)
                    self.overlayView.alpha = 1
                    self.view.layoutIfNeeded()
                }, completion: { complete in
                    self.isPanning = false
                    if previousSize != newSize {
                        self.sizeChanged?(self, newSize, newContentHeight)
                    }
                })
        case .possible:
            break
        @unknown default:
            break
        }
    }

    private func registerKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardShown(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDismissed(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func registerDismissObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(dismissNotification(_:)), name: Notification.Name("closeView"), object: nil)
    }

    @objc func keyboardShown(_ notification: Notification) {
        guard let info:[AnyHashable: Any] = notification.userInfo, let keyboardRect:CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }

        let windowRect = self.view.convert(self.view.bounds, to: nil)
        let actualHeight = windowRect.maxY - keyboardRect.origin.y
        self.adjustForKeyboard(height: actualHeight, from: notification)
    }

    @objc func keyboardDismissed(_ notification: Notification) {
        self.adjustForKeyboard(height: 0, from: notification)
    }

    @objc func dismissNotification(_ notification: Notification) {
        if let inlineMode = notification.userInfo?["useInlineMode"] as? Bool {
            if inlineMode {
                self.animateOut {
                    self.didDismiss?(self)
                }
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        } else {
            self.attemptDismiss(animated: true)
        }
    }

    private func adjustForKeyboard(height: CGFloat, from notification: Notification) {
        guard self.autoAdjustToKeyboard, let info:[AnyHashable: Any] = notification.userInfo else { return }
        self.keyboardHeight = height

        let duration:TimeInterval = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)

        self.contentViewController.adjustForKeyboard(height: self.keyboardHeight)
        self.resize(to: self.currentSize, duration: duration, options: animationCurve, animated: true, complete: {
            self.resize(to: self.currentSize)
        })
    }

    private func height(for size: WHSize?) -> CGFloat {
        guard let size = size else { return 0 }
        let contentHeight: CGFloat
        let fullscreenHeight: CGFloat
        if self.options.useFullScreenMode {
            fullscreenHeight = self.view.bounds.height - self.minimumSpaceAbovePullBar
        } else {
            fullscreenHeight = self.view.bounds.height - self.view.compatibleSafeAreaInsets.top - self.minimumSpaceAbovePullBar
        }
        switch (size) {
        case .fixed(let height):
            contentHeight = height + self.keyboardHeight
        case .fullscreen:
            contentHeight = fullscreenHeight
        case .intrinsic:
            contentHeight = self.contentViewController.preferredHeight + self.keyboardHeight
        case .percent(let percent):
            if (percent > 1) {
                debugPrint("Size 1.0以下に設定が必要。しかし現在の数値は \(percent) となっている)")
            }
            contentHeight = (self.view.bounds.height) * CGFloat(percent) + self.keyboardHeight
        case .marginFromTop(let margin):
            contentHeight = (self.view.bounds.height) - margin + self.keyboardHeight
        }
        return min(fullscreenHeight, contentHeight)
    }

    // https://medium.com/thoughts-on-thoughts/recreating-apple-s-rubber-band-effect-in-swift-dbf981b40f35
    private func logConstraintValueForYPosition(verticalLimit: CGFloat, yPosition : CGFloat) -> CGFloat {
        return verticalLimit * (1 + log10(yPosition/verticalLimit))
    }

    public func resize(to size: WHSize,
                       duration: TimeInterval = 0.2,
                       options: UIView.AnimationOptions = [.curveEaseOut],
                       animated: Bool = true,
                       complete: (() -> Void)? = nil) {

        let previousSize = self.currentSize
        self.currentSize = size

        let oldConstraintHeight = self.contentViewHeightConstraint.constant

        let newHeight = self.height(for: size)

        guard oldConstraintHeight != newHeight else {
            return
        }

        if animated {
            self.view.layer.removeAllAnimations()
            UIView.animate(withDuration: duration, delay: 0, options: options, animations: { [weak self] in
                guard let self = self, let constraint = self.contentViewHeightConstraint else { return }
                constraint.constant = newHeight
                self.contentViewController.view.layoutIfNeeded()
            }, completion: { _ in
                if previousSize != size {
                    self.sizeChanged?(self, size, newHeight)
                }
                self.contentViewController.updateAfterLayout()
                complete?()
            })
        } else {
            self.view.layer.removeAllAnimations()
            UIView.performWithoutAnimation {
                self.contentViewHeightConstraint?.constant = self.height(for: size)
                self.contentViewController.view.layoutIfNeeded()
            }
            complete?()
        }
    }

    public func attemptDismiss(animated: Bool) {
        if self.shouldDismiss?(self) != false {
            if self.options.useInlineMode {
                if animated {
                    self.animateOut {
                        self.didDismiss?(self)
                    }
                } else {
                    self.view.removeFromSuperview()
                    self.removeFromParent()
                    self.didDismiss?(self)
                }
            } else {
                self.dismiss(animated: animated, completion: nil)
            }
        }
    }

    /// コンテンツに基づいてシートの固有高を再計算し、それに合わせてシートの高さを更新します。
    ///
    /// **Note:** `.intrinsic` の使用を想定
    public func updateIntrinsicHeight() {
        contentViewController.updatePreferredHeight()
    }

    /// インラインモードで表示している場合に限り、シートをアニメーションで表示します。
    public func animateIn(to view: UIView, in parent: UIViewController, size: WHSize? = nil, duration: TimeInterval = 0.2, completion: (() -> Void)? = nil) {

        self.willMove(toParent: parent)
        parent.addChild(self)
        view.addSubview(self.view)
        self.didMove(toParent: parent)

        self.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.view.topAnchor.constraint(equalTo: view.topAnchor),
            self.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            self.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        self.animateIn(size: size, duration: duration, completion: completion)
    }

    public func animateIn(size: WHSize? = nil, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        guard self.options.useInlineMode else { return }
        guard self.view.superview != nil else {
            print("シートが他のビューのサブビューとして設定されていないようです。アニメーションさせる前に、このビューをサブビューとして追加することを確認してください。")
            return
        }
        self.view.superview?.layoutIfNeeded()
        self.contentViewController.updatePreferredHeight()
        self.resize(to: size ?? self.sizes.first ?? self.currentSize, animated: false)
        let contentView = self.contentViewController.view!
        contentView.transform = CGAffineTransform(translationX: 0, y: contentView.bounds.height)
        self.overlayView.alpha = 0
        self.updateOrderedSizes()
        
        self.view.layer.removeAllAnimations()
        UIView.animate(
            withDuration: duration,
            animations: {
                contentView.transform = .identity
                self.overlayView.alpha = 1
            },
            completion: { _ in
                completion?()
            }
        )
    }

    /// インラインモードで表示している場合に限り、シートをアニメーションさせます。
    public func animateOut(duration: TimeInterval = 0.2, completion: (() -> Void)? = nil) {
        guard self.options.useInlineMode else { return }
        let contentView = self.contentViewController.view!

        self.view.layer.removeAllAnimations()
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: self.options.transitionDampening,
            initialSpringVelocity: self.options.transitionVelocity,
            options: self.options.transitionAnimationOptions,
            animations: {
                contentView.transform = CGAffineTransform(translationX: 0, y: contentView.bounds.height)
                self.overlayView.alpha = 0
            },
            completion: { _ in
                self.view.removeFromSuperview()
                self.removeFromParent()
                completion?()
            }
        )
    }
}

@available(iOS 13.0, *)
extension WHSheetViewController: WHViewDelegate {
    func sheetPoint(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let isInOverlay = self.overlayTapView.bounds.contains(point)
        if self.allowGestureThroughOverlay, isInOverlay {
            return false
        } else {
            return true
        }
    }
}

@available(iOS 13.0, *)
extension WHSheetViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // UIControlでジェスチャー認識を許可すると、そのイベントが正しく実行されないことがあるようです。
        if !shouldRecognizePanGestureWithUIControls {
            if let view = touch.view {
                return !(view is UIControl)
            }
        }
        return true
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGestureRecognizer = gestureRecognizer as? InitialTouchPanGestureRecognizer, let childScrollView = self.childScrollView, let point = panGestureRecognizer.initialTouchLocation else { return true }

        if let pan = gestureRecognizer as? UIPanGestureRecognizer, let closure = panGestureShouldBegin, let should = closure(pan) {
            return should
        }

        let pointInChildScrollView = self.view.convert(point, to: childScrollView).y - childScrollView.contentOffset.y

        let velocity = panGestureRecognizer.velocity(in: panGestureRecognizer.view?.superview)
        guard pointInChildScrollView > 0, pointInChildScrollView < childScrollView.bounds.height else {
            if keyboardHeight > 0 {
                childScrollView.endEditing(true)
            }
            return true
        }
        let topInset = childScrollView.contentInset.top

        guard abs(velocity.y) > abs(velocity.x), childScrollView.contentOffset.y <= -topInset else { return false }

        if velocity.y < 0 {
            let containerHeight = height(for: self.currentSize)
            return height(for: self.orderedSizes.last) > containerHeight && containerHeight < height(for: WHSize.fullscreen)
        } else {
            return true
        }
    }
}

@available(iOS 13.0, *)
extension WHSheetViewController: WHContentViewDelegate {
    func pullBarTapped() {
        // プルバーのタップはあくまでアクセシビリティのためのものです
        guard UIAccessibility.isVoiceOverRunning else { return }
        let shouldDismiss = self.allowGestureThroughOverlay && (self.dismissOnOverlayTap || self.dismissOnPull)
        guard !shouldDismiss else {
            self.attemptDismiss(animated: true)
            return
        }

        if self.sizes.count > 1 {
            let index = (self.sizes.firstIndex(of: self.currentSize) ?? 0) + 1
            if index >= self.sizes.count {
                self.resize(to: self.sizes[0])
            } else {
                self.resize(to: self.sizes[index])
            }
        }
    }

    func preferredHeightChanged(oldHeight: CGFloat, newSize: CGFloat) {
        if self.sizes.contains(.intrinsic) {
            self.updateOrderedSizes()
        }
        // サイズが変わって、それが現在のサイズになったのであればそのまま使う
        if self.currentSize == .intrinsic, !self.isPanning {
            self.resize(to: .intrinsic)
        }
    }
}

@available(iOS 13.0, *)
extension WHSheetViewController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.presenting = true
        return transition
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.presenting = false
        return transition
    }
}


public protocol WHSheetViewDelegate: AnyObject {
    func scrollChanged(frame:CGRect, state:UIGestureRecognizer.State)
}
