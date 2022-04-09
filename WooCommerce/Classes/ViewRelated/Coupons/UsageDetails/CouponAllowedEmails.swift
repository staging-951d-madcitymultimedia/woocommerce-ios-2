import SwiftUI

/// View to input allowed email formats for coupons
///
struct CouponAllowedEmails: View {
    @Binding var emailFormats: String

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                TextField("", text: $emailFormats)
                    .labelsHidden()
                    .padding(.horizontal, Constants.margin)
                    .padding(.horizontal, insets: geometry.safeAreaInsets)
                Divider()
                    .padding(.leading, Constants.margin)
                    .padding(.leading, insets: geometry.safeAreaInsets)
                Text(Localization.description)
                    .footnoteStyle()
                    .padding(.horizontal, Constants.margin)
                    .padding(.horizontal, insets: geometry.safeAreaInsets)
            }
            .padding(.top, Constants.topSpacing)
            .ignoresSafeArea(.container, edges: [.horizontal])
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension CouponAllowedEmails {
    enum Constants {
        static let margin: CGFloat = 16
        static let topSpacing: CGFloat = 24
    }

    enum Localization {
        static let title = NSLocalizedString("Allowed Emails", comment: "Title for the Allowed Emails screen")
        static let description = NSLocalizedString(
            "List of allowed billing emails to check against when an order is placed. " +
            "Separate email addresses with commas. You can also use an asterisk (*) " +
            "to match parts of an email. For example \"*@gmail.com\" would match all gmail addresses.",
            comment: "Description of the allowed emails field for coupons")
    }
}

struct CouponAllowedEmails_Previews: PreviewProvider {
    static var previews: some View {
        CouponAllowedEmails(emailFormats: .constant("*gmail.com, *@me.com"))
    }
}