// Empty state for Tenor

struct NoResultsTenorConfiguration {

    static func configureAsIntro(_ viewController: NoResultsViewController) {
        viewController.configure(title: .tenorPlaceholderTitle,
                                 image: Constants.imageName,
                                 subtitleImage: "tenor-attribution") // we will need this image

        viewController.view.layoutIfNeeded()
    }

    static func configureAsLoading(_ viewController: NoResultsViewController) {
        viewController.configure(title: .tenorSearchLoading,
                                 image: Constants.imageName)

        viewController.view.layoutIfNeeded()
    }

    static func configure(_ viewController: NoResultsViewController) {
        viewController.configureForNoSearchResults(title: .tenorSearchNoResult)
        viewController.view.layoutIfNeeded()
    }

    private enum Constants {
        static let imageName = "media-no-results"
    }
}
