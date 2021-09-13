import Yosemite
import Storage
import Combine
import struct SwiftUI.Binding

final class EditAddressFormViewModel: ObservableObject {
    /// Current site ID
    ///
    private let siteID: Int64

    /// ResultsController for stored countries.
    ///
    private lazy var countriesResultsController: ResultsController<StorageCountry> = {
        let countriesDescriptor = NSSortDescriptor(key: "name", ascending: true)
        return ResultsController<StorageCountry>(storageManager: storageManager, sortedBy: [countriesDescriptor])
    }()

    /// Trigger to sync countries.
    ///
    private let syncCountriesTrigger = PassthroughSubject<Void, Never>()

    /// Storage to fetch countries
    ///
    private let storageManager: StorageManagerType

    /// Stores to sync countries
    ///
    private let stores: StoresManager

    /// Store for publishers subscriptions
    ///
    private var subscriptions = Set<AnyCancellable>()


    init(siteID: Int64, address: Address?, storageManager: StorageManagerType = ServiceLocator.storageManager, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.originalAddress = address ?? .empty
        self.storageManager = storageManager
        self.stores = stores

        // Listen only to the first emitted event.
        onLoadTrigger.first().sink { [weak self] in
            guard let self = self else { return }
            self.bindSyncTrigger()
            self.bindSelectedCountryIntoFields()
            self.bindNavigationTrailingItemPublisher()

            self.fetchStoredCountriesAndTriggerSyncIfNeeded()
            self.setFieldsInitialValues()
        }.store(in: &subscriptions)
    }

    /// Original `Address` model.
    ///
    private let originalAddress: Address

    /// Current selected country.
    ///
    @Published private var selectedCountry: Yosemite.Country?

    /// Address form fields
    ///
    @Published var fields = FormFields()

    /// Trigger to perform any one time setups.
    ///
    let onLoadTrigger: PassthroughSubject<Void, Never> = PassthroughSubject()

    /// Tracks if a network request is being performed.
    ///
    private let performingNetworkRequest: CurrentValueSubject<Bool, Never> = .init(false)

    /// Active navigation bar trailing item.
    /// Defaults to a disabled done button.
    ///
    @Published private(set) var navigationTrailingItem: NavigationItem = .done(enabled: false)

    /// Define if the view should show placeholders instead of the real elements.
    ///
    @Published private(set) var showPlaceholders: Bool = false

    /// Creates a view model to be used when selecting a country
    ///
    func createCountryViewModel() -> CountrySelectorViewModel {
        let selectedCountryBinding = Binding(
            get: { self.selectedCountry },
            set: { self.selectedCountry = $0 }
        )
        return CountrySelectorViewModel(countries: countriesResultsController.fetchedObjects, selected: selectedCountryBinding)
    }

    /// Update the address remotely and invoke a completion block when finished
    ///
    func updateRemoteAddress(onFinish: @escaping (Bool) -> Void) {
        // TODO: perform network request
        // TODO: add success/failure notice
        performingNetworkRequest.send(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.performingNetworkRequest.send(false)
            onFinish(true)
        }
    }
}

extension EditAddressFormViewModel {
    /// Representation of possible navigation bar trailing buttons
    ///
    enum NavigationItem: Equatable {
        case done(enabled: Bool)
        case loading
    }

    /// Type to hold values from all the form fields
    ///
    struct FormFields {
        // MARK: User Fields
        var firstName: String = ""
        var lastName: String = ""
        var email: String = ""
        var phone: String = ""

        // MARK: Address Fields

        var company: String = ""
        var address1: String = ""
        var address2: String = ""
        var city: String = ""
        var postcode: String = ""
        var country: String = ""
        var state: String = ""

        mutating func update(with address: Address) {
            firstName = address.firstName
            lastName = address.lastName
            email = address.email ?? ""
            phone = address.phone ?? ""

            company = address.company ?? ""
            address1 = address.address1
            address2 = address.address2 ?? ""
            city = address.city
            postcode = address.postcode
            state = address.state
        }

        mutating func update(with selectedCountry: Yosemite.Country?) {
            country = selectedCountry?.name ?? country
        }


        func toAddress(selectedCountry: Yosemite.Country?) -> Yosemite.Address {
            Address(firstName: firstName,
                    lastName: lastName,
                    company: company.isEmpty ? nil : company,
                    address1: address1,
                    address2: address2.isEmpty ? nil : address2,
                    city: city,
                    state: state,
                    postcode: postcode,
                    country: selectedCountry?.code ?? country,
                    phone: phone.isEmpty ? nil : phone,
                    email: email.isEmpty ? nil : email)
        }
    }
}

private extension EditAddressFormViewModel {
    /// Set initial values from `originalAddress` using the stored countries to compute the current selected country.
    ///
    func setFieldsInitialValues() {
        selectedCountry = countriesResultsController.fetchedObjects.first { $0.code == originalAddress.country }
        fields.update(with: originalAddress)
    }

    /// Calculates what navigation trailing item should be shown depending on our internal state.
    ///
    func bindNavigationTrailingItemPublisher() {
        Publishers.CombineLatest3($fields, performingNetworkRequest, $selectedCountry)
            .map { [originalAddress] fields, performingNetworkRequest, selectedCountry -> NavigationItem in
                guard !performingNetworkRequest else {
                    return .loading
                }
                return .done(enabled: originalAddress != fields.toAddress(selectedCountry: selectedCountry))
            }
            .assign(to: &$navigationTrailingItem)
    }

    /// Update published fields when the selected country is updated.
    ///
    func bindSelectedCountryIntoFields() {
        $selectedCountry
            .sink { [weak self] newCountry in
                self?.fields.update(with: newCountry)
            }
            .store(in: &subscriptions)
    }

    /// Fetches countries from storage, If there are no stored countries, trigger a sync request.
    ///
    func fetchStoredCountriesAndTriggerSyncIfNeeded() {
        // Initial fetch
        try? countriesResultsController.performFetch()

        // Updates the initial fields when/if the data store changes(after sync).
        countriesResultsController.onDidChangeContent = { [weak self] in
            self?.setFieldsInitialValues()
        }

        // Trigger a sync request if there are no countries.
        guard !countriesResultsController.isEmpty else {
            return syncCountriesTrigger.send()
        }
    }

    /// Sync countries when requested. Defines the `showPlaceholderState` value depending if countries are being synced or not.
    ///
    func bindSyncTrigger() {
        syncCountriesTrigger
            .handleEvents(receiveOutput: { // Set `showPlaceholders` to `true` before initiating sync.
                self.showPlaceholders = true // I could not find a way to assign this using combine operators. :-(
            })
            .map { // Sync countries
                self.makeSyncCountriesFuture()
                    .replaceError(with: ()) // TODO: Handle errors
            }
            .switchToLatest()
            .map { _ in // Set `showPlaceholders` to `false` after sync is done.
                false
            }
            .assign(to: &$showPlaceholders)
    }

    /// Creates a publisher that syncs countries into our storage layer.
    ///
    func makeSyncCountriesFuture() -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else { return }

            let action = DataAction.synchronizeCountries(siteID: self.siteID) { result in
                let newResult = result.map { _ in } // Hides the result success type because we don't need it.
                promise(newResult)
            }
            self.stores.dispatch(action)
        }
        .eraseToAnyPublisher()
    }
}
