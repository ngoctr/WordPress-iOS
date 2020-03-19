import UIKit
import PanModal

extension PrepublishingViewController: PanModalPresentable {

    var panScrollable: UIScrollView? {
        return self.tableView
    }
}

class PrepublishingNavigationController: UINavigationController, PanModalPresentable {
    var panScrollable: UIScrollView? {
        return (topViewController as? PanModalPresentable)?.panScrollable
    }

    var longFormHeight: PanModalHeight {
        return .maxHeight
    }

    var shortFormHeight: PanModalHeight {
        return .contentHeight(200)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

    }

    @objc func keyboardWillShow(_ notification: NSNotification) {
        panModalSetNeedsLayoutUpdate()
        panModalTransition(to: .longForm)
    }

    @objc func keyboardWillHide(_ notification: NSNotification) {
//        panModalSetNeedsLayoutUpdate()
//        panModalTransition(to: .shortForm)
    }
}


class PrepublishingViewController: UITableViewController {
    private let post: Post

    init(post: Post) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(WPTableViewCell.self, forCellReuseIdentifier: Constants.reuseIdentifier)

    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.reuseIdentifier)

        cell?.accessoryType = .disclosureIndicator
        cell?.textLabel?.text = "Tags"

        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewController = PostTagPickerViewController(tags: post.tags ?? "", blog: post.blog)

        viewController.onValueChanged = { [weak self] tags in
            self?.post.tags = tags
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

    private enum Constants {
        static let reuseIdentifier = "wpTableViewCell"
    }
}
