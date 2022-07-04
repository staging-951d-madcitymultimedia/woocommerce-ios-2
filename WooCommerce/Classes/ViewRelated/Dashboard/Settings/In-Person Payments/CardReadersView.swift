import SwiftUI
import WebKit
import SafariServices

struct Manual: Identifiable {
    let id: Int
    let name: String
    let urlString: String
}

let bbposChipper2XBT = Manual(
    id: 0,
    name: "BBPOS Chipper 2X BT",
    urlString: "https://stripe.com/files/docs/terminal/c2xbt_product_sheet.pdf"
)
let stripeM2 = Manual(
    id: 1,
    name: "Stripe Reader M2",
    urlString: "https://stripe.com/files/docs/terminal/m2_product_sheet.pdf"
)
let wisepad3 = Manual(
    id: 2,
    name: "Wisepad 3",
    urlString: "https://stripe.com/files/docs/terminal/wp3_product_sheet.pdf"
)

let manuals = [bbposChipper2XBT, stripeM2, wisepad3]

struct SafariView: UIViewControllerRepresentable {

    var choice: Manual
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController,
                                context: UIViewControllerRepresentableContext<SafariView>) {

    }
}
/// A view to be displayed on Card Reader Manuals screen
///
struct CardReadersView: View {
    var body: some View {
        List(manuals, id: \.name) { manual in
            NavigationLink(destination: SafariView(choice: manual, url: URL(string: manual.urlString)!)) {
                // Temporary Image placeholder using SwiftUI wrapper
                Image(uiImage: .cardReaderManualIcon)
                Text(manual.name)
            }
        }
        .navigationBarTitle(Localization.navigationTitle, displayMode: .inline)
    }
}

struct CardReadersView_Previews: PreviewProvider {
    static var previews: some View {
        CardReadersView()
    }
}

private extension CardReadersView {
    enum Localization {
        static let navigationTitle = NSLocalizedString( "Card reader manuals",
                                                        comment: "Navigation title at the top of the Card reader manuals screen")
    }
}
