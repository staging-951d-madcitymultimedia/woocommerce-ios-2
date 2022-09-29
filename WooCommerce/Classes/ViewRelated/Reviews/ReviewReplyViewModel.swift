import Foundation
import Combine
import Yosemite

/// View model for the `ReviewReply` screen.
///
final class ReviewReplyViewModel: ObservableObject {

    private let siteID: Int64

    /// ID for the product review being replied to.
    ///
    private let reviewID: Int64

    /// New reply to send
    ///
    @Published var newReply: String = ""

    /// Defaults to a disabled send button.
    ///
    @Published private(set) var navigationTrailingItem: ReviewReplyNavigationItem = .send(enabled: false)

    /// Tracks if a network request is being performed.
    ///
    private let performingNetworkRequest: CurrentValueSubject<Bool, Never> = .init(false)

    /// Action dispatcher
    ///
    private let stores: StoresManager

    /// Presents a success notice in the tab bar context.
    ///
    private let noticePresenter: NoticePresenter

    /// Presents an error notice in the current modal presentation context.
    ///
    var modalNoticePresenter: NoticePresenter?

    init(siteID: Int64,
         reviewID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {
        self.siteID = siteID
        self.reviewID = reviewID
        self.stores = stores
        self.noticePresenter = noticePresenter
        bindNavigationTrailingItemPublisher()
    }

    /// Called when the user taps on the Send button.
    ///
    /// Use this method to send the reply and invoke a completion block when finished
    ///
    func sendReply(onCompletion: @escaping (Bool) -> Void) {
        guard newReply.isNotEmpty else {
            return
        }

        let action = CommentAction.replyToComment(siteID: siteID, commentID: reviewID, content: newReply) { [weak self] result in
            guard let self = self else { return }

            self.performingNetworkRequest.send(false)

            switch result {
            case .success:
                self.displayReplySuccessNotice()
                onCompletion(true)
            case .failure(let error):
                self.displayReplyErrorNotice(onCompletion: onCompletion)
                DDLogError("⛔️ Error replying to product review: \(error)")
                onCompletion(false)
            }
        }

        performingNetworkRequest.send(true)
        stores.dispatch(action)
    }
}

// MARK: Helper Methods
private extension ReviewReplyViewModel {
    /// Calculates what navigation trailing item should be shown depending on our internal state.
    ///
    func bindNavigationTrailingItemPublisher() {
        Publishers.CombineLatest($newReply, performingNetworkRequest)
            .map { newReply, performingNetworkRequest in
                guard !performingNetworkRequest else {
                    return .loading
                }
                return .send(enabled: newReply.isNotEmpty)
            }
            .assign(to: &$navigationTrailingItem)
    }

    /// Enqueues the `Reply sent` success notice.
    ///
    func displayReplySuccessNotice() {
        noticePresenter.enqueue(notice: Notice(title: Localization.success, feedbackType: .success))
    }

    /// Enqueues the `Error sending reply` notice.
    ///
    func displayReplyErrorNotice(onCompletion: @escaping (Bool) -> Void) {
        let noticeIdentifier = UUID().uuidString
        let notice = Notice(title: Localization.error,
                            feedbackType: .error,
                            notificationInfo: NoticeNotificationInfo(identifier: noticeIdentifier),
                            actionTitle: Localization.retry) { [weak self] in
            self?.sendReply(onCompletion: onCompletion)
        }

        modalNoticePresenter?.enqueue(notice: notice)
    }
}

// MARK: Localization
private extension ReviewReplyViewModel {
    enum Localization {
        static let success = NSLocalizedString("Reply sent!", comment: "Notice text after sending a reply to a product review successfully")
        static let error = NSLocalizedString("There was an error sending the reply", comment: "Notice text after failing to send a reply to a product review")
        static let retry = NSLocalizedString("Retry", comment: "Retry Action")
    }
}

/// Representation of possible navigation bar trailing buttons
///
enum ReviewReplyNavigationItem: Equatable {
    case send(enabled: Bool)
    case loading
}
