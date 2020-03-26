import UIKit

class BottomSheetViewController: UIViewController {

    enum Constants {
        static let gripHeight: CGFloat = 5
        static let cornerRadius: CGFloat = 8
        static let buttonSpacing: CGFloat = 8
        static let additionalSafeAreaInsetsRegular: UIEdgeInsets = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        static let minimumWidth: CGFloat = 300

        enum Header {
            static let spacing: CGFloat = 16
            static let insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        }

        enum Button {
            static let height: CGFloat = 54
            static let contentInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 35)
            static let titleInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
            static let imageTintColor: UIColor = .neutral(.shade30)
            static let font: UIFont = .preferredFont(forTextStyle: .callout)
            static let textColor: UIColor = .text
        }

        enum Stack {
            static let insets: UIEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        }
    }

    private weak var childViewController: UIBottomSheetPresentable?

    private var heightConstraint: NSLayoutConstraint!

    init(childViewController: UIBottomSheetPresentable) {
        self.childViewController = childViewController
        super.init(nibName: nil, bundle: nil)
    }

    func show(from presenting: UIViewController, sourceView: UIView? = nil) {
        if UIDevice.isPad() {
            modalPresentationStyle = .popover
            popoverPresentationController?.sourceView = sourceView ?? UIView()
            popoverPresentationController?.sourceRect = sourceView?.bounds ?? .zero
        } else {
            transitioningDelegate = self
            modalPresentationStyle = .custom
        }

        presenting.present(self, animated: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var gripButton: UIButton = {
        let button = GripButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        return button
    }()

    @objc func buttonPressed() {
        dismiss(animated: true, completion: nil)
    }


    private func configureView() {
        view.clipsToBounds = true
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        view.backgroundColor = .basicBackground

    }

    private func configureGripButton() {
        NSLayoutConstraint.activate([
            gripButton.heightAnchor.constraint(equalToConstant: Constants.gripHeight)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addKeyboardHandlers()
        configureView()
        configureGripButton()

        guard let childViewController = childViewController else {
            return
        }


        // Set the initial height of the child VC
        let initialHeight = childViewController.initialHeight
        heightConstraint = childViewController.view.heightAnchor.constraint(equalToConstant: initialHeight)
        heightConstraint.priority = UILayoutPriority(rawValue: 999)
        heightConstraint.isActive = true

        childViewController.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(childViewController)

        let stackView = UIStackView(arrangedSubviews: [
            gripButton,
            childViewController.view
        ])

        stackView.setCustomSpacing(Constants.Header.spacing, after: gripButton)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical

        refreshForTraits()

        view.addSubview(stackView)
        view.pinSubviewToSafeArea(stackView, insets: Constants.Stack.insets)
        
        childViewController.didMove(toParent: self)
    }

    private func setNeedsLayout() {
        self.presentationController?.containerView?.setNeedsLayout()
        self.presentationController?.containerView?.layoutIfNeeded()
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refreshForTraits()
    }

    private func refreshForTraits() {
        if presentingViewController?.traitCollection.horizontalSizeClass == .regular && presentingViewController?.traitCollection.verticalSizeClass != .compact {
            gripButton.isHidden = true
            additionalSafeAreaInsets = Constants.additionalSafeAreaInsetsRegular
        } else {
            gripButton.isHidden = false
            additionalSafeAreaInsets = .zero
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        return preferredContentSize = CGSize(width: Constants.minimumWidth, height: view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height)
    }


    private func resizeAllViewControllers(height: CGFloat) {
        (childViewController as? UINavigationController)?.viewControllers.forEach { viewController in
            var originalFrame = viewController.view.frame
            originalFrame.size.height = height
            viewController.view.frame = originalFrame
        }
    }

    //MARK: - Keyboard Handling
    private func addKeyboardHandlers() {
        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillHide(_ notification: NSNotification) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.30
        let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0
        let height = self.childViewController?.initialHeight ?? 200

        UIView.animateKeyframes(withDuration: duration,
                                delay: 0,
                                options: UIView.KeyframeAnimationOptions(rawValue: curve),
                                animations: {
                                    // Resize the bottom sheet
                                    self.heightConstraint.constant = height
                                    self.setNeedsLayout()

                                    // Resize all the subviews if the child VC is a navigation controller
                                    self.resizeAllViewControllers(height: height)
        }, completion: { _ in
            // Make sure the subviews keeps the height of the bottom sheet
            self.resizeAllViewControllers(height: height)
        })
        
        keyboardIsOpen = false
    }

    //Disable dismiss interaction when the keyboard is open
    private var keyboardIsOpen: Bool = false {
        didSet {
            bottomSheetPresentationController?.disableInteraction = keyboardIsOpen
        }
    }

    //
    private func bottomInsetFromKeyboardNote(_ note: NSNotification) -> CGFloat {
        let wrappedRect = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let keyboardRect = wrappedRect?.cgRectValue ?? CGRect.zero
        let relativeRect = view.convert(keyboardRect, from: nil)
        let bottomInset = max(relativeRect.height - relativeRect.maxY + view.frame.height, 0)

        return bottomInset
    }

    @objc func keyboardWillShow(_ notification: NSNotification) {
        keyboardIsOpen = true

        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.30
        let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0

        //Total height of the bottom view
        let heightForKeyboard: CGFloat = UIScreen.main.bounds.height - 100 //Change this to be dynamic

        // Calculates a different height for the nav controllers child views to avoid any clipping issues
        let keyboardInset: CGFloat = bottomInsetFromKeyboardNote(notification)

        let viewControllerHeight: CGFloat = (heightForKeyboard - keyboardInset - Constants.Header.spacing)

        UIView.animateKeyframes(withDuration: duration,
                                delay: 0,
                                options: UIView.KeyframeAnimationOptions(rawValue: curve),
                                animations: {
                                    // Resize the bottom sheet
                                    self.heightConstraint.constant = heightForKeyboard
                                    self.setNeedsLayout()

                                    // Resize all the subviews if the child VC is a navigation controller
                                    self.resizeAllViewControllers(height: viewControllerHeight)
        }, completion: { _ in
            // Make sure the subviews keeps the height of the bottom sheet
            self.resizeAllViewControllers(height: viewControllerHeight)
        })
    }
}

extension BottomSheetViewController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomSheetAnimationController(transitionType: .presenting)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomSheetAnimationController(transitionType: .dismissing)
    }

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentationController = BottomSheetPresentationController(presentedViewController: presented, presenting: presenting)
        return presentationController
    }

    private var bottomSheetPresentationController: BottomSheetPresentationController? {
        get {
            return (self.presentationController as? BottomSheetPresentationController)
        }
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return bottomSheetPresentationController?.interactionController
    }
}
