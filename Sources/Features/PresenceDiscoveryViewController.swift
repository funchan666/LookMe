import UIKit
import CoreLocation

final class PresenceDiscoveryViewController: LMViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var onCreate: (() -> Void)?
    private var collectionView: UICollectionView!
    private var selectedCategory = "All"
    private var selectedRegion = "Global"
    private var query = ""

    private var members: [CommunityProfile] {
        LookMeExperienceStore.shared.visibleMembers().filter { member in
            let categoryOK = selectedCategory == "All"
                || (selectedCategory == "Live" && member.isLive)
                || (selectedCategory == "Follow" && LookMeExperienceStore.shared.following.contains(member.id))
                || selectedCategory == "New"
            let regionOK = selectedRegion == "Global" || member.region == selectedRegion
            let queryOK = query.isEmpty || member.name.localizedCaseInsensitiveContains(query)
            return categoryOK && regionOK && queryOK
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let aurora = UIImageView(image: UIImage(named: "discovery-aurora-field.png"))
        aurora.contentMode = .scaleAspectFill
        aurora.alpha = 0.13
        view.addSubview(aurora)
        aurora.pin(to: view)
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 6
        layout.minimumInteritemSpacing = 6
        layout.sectionInset = UIEdgeInsets(top: 4, left: 6, bottom: 22, right: 6)
        layout.headerReferenceSize = CGSize(width: view.bounds.width, height: 88)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.register(PresenceProfileCardCell.self, forCellWithReuseIdentifier: "member")
        collectionView.register(PresenceDiscoveryHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        collectionView.pin(to: view)
        NotificationCenter.default.addObserver(forName: .lookMeStoreChanged, object: nil, queue: .main) { [weak self] _ in self?.collectionView.reloadData() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { members.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "member", for: indexPath) as! PresenceProfileCardCell
        cell.configure(members[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: (collectionView.bounds.width - 18) / 2, height: 252)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let member = members[indexPath.item]
        if member.isLive {
            present(LiveRoomViewController(member: member), animated: true)
        } else {
            navigationController?.pushViewController(CommunityProfileDetailViewController(member: member), animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as! PresenceDiscoveryHeader
        header.configure(category: selectedCategory, region: selectedRegion) { [weak self] category in
            self?.selectedCategory = category; self?.collectionView.reloadData()
        } regionAction: { [weak self] region in
            self?.selectedRegion = region; self?.collectionView.reloadData()
        } searchAction: { [weak self] in
            self?.openSearch()
        } giftAction: { [weak self] in
            self?.navigationController?.pushViewController(EffectBoutiqueViewController(), animated: true)
        } createAction: { [weak self] in
            self?.onCreate?()
        } locationAction: { [weak self] in
            self?.tuneDiscoveryToCurrentRegion()
        }
        return header
    }

    private func openSearch() {
        let search = DiscoverySearchViewController(initialQuery: query)
        search.onApply = { [weak self] value in self?.query = value; self?.collectionView.reloadData() }
        present(search, animated: true)
    }

    private func tuneDiscoveryToCurrentRegion() {
        LocationPermissionManager.shared.requestFromUserAction(from: self) { [weak self] location in
            guard let self, let location else { return }
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
                let code = placemarks?.first?.isoCountryCode ?? ""
                DispatchQueue.main.async {
                    self.selectedRegion = Self.discoveryRegion(for: code)
                    self.collectionView.reloadData()
                    self.present(LMNoticeViewController(style: .success, title: "Region signal tuned", message: "Discovery now favors the \(self.selectedRegion) community. You can switch regions anytime."), animated: true)
                }
            }
        }
    }

    static func discoveryRegion(for countryCode: String) -> String {
        let europe = Set(["GB", "IE", "FR", "DE", "ES", "PT", "IT", "NL", "BE", "NO", "SE", "DK", "FI", "CH", "AT", "PL", "CZ", "GR", "TR"])
        let asia = Set(["CN", "JP", "KR", "SG", "MY", "PH", "TH", "VN", "ID", "TW", "HK"])
        let latin = Set(["MX", "BR", "AR", "CL", "CO", "PE", "UY", "EC"])
        let mena = Set(["MA", "AE", "SA", "EG", "QA", "JO", "LB", "TN", "DZ"])
        let africa = Set(["ZA", "NG", "GH", "KE", "TZ", "UG", "ET", "RW", "SN", "CI", "CM", "BW", "NA", "ZM", "ZW"])
        if countryCode == "IN" { return "India" }
        if europe.contains(countryCode) { return "Europe" }
        if asia.contains(countryCode) { return "Asia" }
        if latin.contains(countryCode) { return "Latin" }
        if mena.contains(countryCode) { return "MENA" }
        if africa.contains(countryCode) { return "Africa" }
        if ["US", "CA"].contains(countryCode) { return "North America" }
        if ["AU", "NZ"].contains(countryCode) { return "Oceania" }
        return "Global"
    }
}

private final class DiscoverySearchViewController: UIViewController {
    var onApply: ((String) -> Void)?
    private let initialQuery: String
    private let field = UITextField()

    init(initialQuery: String) {
        self.initialQuery = initialQuery
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen; modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Keep the discovery grid visually present while the search sheet is open.
        // The sheet itself already has strong contrast, so a light backdrop is enough.
        view.backgroundColor = UIColor.black.withAlphaComponent(0.44)
        let backdrop = UIButton(type: .custom); backdrop.accessibilityLabel = "Close search"; backdrop.addTarget(self, action: #selector(close), for: .touchUpInside); backdrop.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(backdrop); backdrop.pin(to: view)

        let card = UIView(); card.accessibilityIdentifier = "discover.search.card"; card.backgroundColor = LMTheme.panel; card.round(28); card.layer.borderWidth = 1; card.layer.borderColor = LMTheme.pink.withAlphaComponent(0.34).cgColor; card.layer.shadowColor = UIColor.black.cgColor; card.layer.shadowOpacity = 0.42; card.layer.shadowRadius = 26; card.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(card)
        let accent = LMGradientView(colors: [LMTheme.violet, LMTheme.pink], horizontal: true); accent.round(2); accent.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(accent)
        let halo = UIView(); halo.backgroundColor = LMTheme.violet.withAlphaComponent(0.40); halo.round(23); halo.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(halo)
        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold))); icon.tintColor = LMTheme.pinkSoft; icon.translatesAutoresizingMaskIntoConstraints = false; halo.addSubview(icon)
        let heading = UILabel.lm("Find someone", size: 22, weight: .bold); heading.font = LMTheme.displayFont(size: 22, weight: .bold)
        let note = UILabel.lm("Search the community by display name.", size: 11, weight: .medium, color: LMTheme.muted)
        let closeButton = UIButton(type: .system); closeButton.accessibilityIdentifier = "discover.search.close"; closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)), for: .normal); closeButton.tintColor = .white.withAlphaComponent(0.72); closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.07); closeButton.round(17); closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        field.accessibilityIdentifier = "discover.search.field"; field.text = initialQuery; field.textColor = .white; field.tintColor = LMTheme.pinkSoft; field.font = LMTheme.font(size: 15, weight: .semibold); field.attributedPlaceholder = NSAttributedString(string: "Type a name", attributes: [.foregroundColor: LMTheme.muted]); field.backgroundColor = LMTheme.panel2; field.round(17); field.setLeftPadding(16); field.clearButtonMode = .whileEditing; field.returnKeyType = .search; field.autocorrectionType = .no; field.autocapitalizationType = .words; field.addTarget(self, action: #selector(apply), for: .editingDidEndOnExit)
        let reset = UIButton.lm("Reset", symbol: "arrow.counterclockwise"); reset.accessibilityIdentifier = "discover.search.reset"; reset.backgroundColor = UIColor.white.withAlphaComponent(0.07); reset.round(20); reset.addTarget(self, action: #selector(resetSearch), for: .touchUpInside)
        let submit = UIButton.lm("Show results", symbol: "sparkle.magnifyingglass"); submit.accessibilityIdentifier = "discover.search.apply"; submit.backgroundColor = LMTheme.pink; submit.round(20); submit.layer.shadowColor = LMTheme.pink.cgColor; submit.layer.shadowOpacity = 0.26; submit.layer.shadowRadius = 9; submit.addTarget(self, action: #selector(apply), for: .touchUpInside)
        [heading,note,closeButton,field,reset,submit].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; card.addSubview($0) }

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18), card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18), card.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -14),
            accent.topAnchor.constraint(equalTo: card.topAnchor), accent.centerXAnchor.constraint(equalTo: card.centerXAnchor), accent.widthAnchor.constraint(equalToConstant: 70), accent.heightAnchor.constraint(equalToConstant: 4),
            halo.topAnchor.constraint(equalTo: card.topAnchor, constant: 22), halo.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20), halo.widthAnchor.constraint(equalToConstant: 46), halo.heightAnchor.constraint(equalTo: halo.widthAnchor), icon.centerXAnchor.constraint(equalTo: halo.centerXAnchor), icon.centerYAnchor.constraint(equalTo: halo.centerYAnchor),
            heading.leadingAnchor.constraint(equalTo: halo.trailingAnchor, constant: 13), heading.topAnchor.constraint(equalTo: halo.topAnchor, constant: 2), heading.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -10), note.leadingAnchor.constraint(equalTo: heading.leadingAnchor), note.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 3), note.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            closeButton.topAnchor.constraint(equalTo: card.topAnchor, constant: 20), closeButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18), closeButton.widthAnchor.constraint(equalToConstant: 34), closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor),
            field.topAnchor.constraint(equalTo: halo.bottomAnchor, constant: 19), field.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18), field.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18), field.heightAnchor.constraint(equalToConstant: 54),
            reset.topAnchor.constraint(equalTo: field.bottomAnchor, constant: 14), reset.leadingAnchor.constraint(equalTo: field.leadingAnchor), reset.widthAnchor.constraint(equalToConstant: 105), reset.heightAnchor.constraint(equalToConstant: 46), reset.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
            submit.leadingAnchor.constraint(equalTo: reset.trailingAnchor, constant: 10), submit.trailingAnchor.constraint(equalTo: field.trailingAnchor), submit.topAnchor.constraint(equalTo: reset.topAnchor), submit.heightAnchor.constraint(equalTo: reset.heightAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); field.becomeFirstResponder() }
    @objc private func close() { field.resignFirstResponder(); dismiss(animated: true) }
    @objc private func resetSearch() { finish(with: "") }
    @objc private func apply() { finish(with: field.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") }
    private func finish(with value: String) { field.resignFirstResponder(); dismiss(animated: true) { [weak self] in self?.onApply?(value) } }
}

final class PresenceDiscoveryHeader: UICollectionReusableView {
    private let categories = UIStackView()
    private let regionScroll = UIScrollView()
    private let regions = UIStackView()
    private let regionLocator = UIButton(type: .system)
    private var categoryAction: ((String) -> Void)?
    private var regionAction: ((String) -> Void)?
    private var searchAction: (() -> Void)?
    private var giftAction: (() -> Void)?
    private var createAction: (() -> Void)?
    private var locationAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        categories.axis = .horizontal; categories.distribution = .fillEqually; categories.translatesAutoresizingMaskIntoConstraints = false; addSubview(categories)
        let search = iconButton("magnifyingglass", action: #selector(searchTapped))
        search.accessibilityIdentifier = "discover.search"; search.accessibilityLabel = "Search people"
        let gift = iconButton("gift.fill", action: #selector(giftTapped))
        let create = iconButton("plus", action: #selector(createTapped))
        create.accessibilityIdentifier = "main.create"; create.accessibilityLabel = "Create"
        create.tintColor = .white; create.backgroundColor = LMTheme.pink; create.round(10)
        create.layer.shadowColor = LMTheme.pink.cgColor; create.layer.shadowOpacity = 0.28; create.layer.shadowRadius = 7
        addSubview(search); addSubview(gift); addSubview(create)
        regionScroll.showsHorizontalScrollIndicator = false; regionScroll.translatesAutoresizingMaskIntoConstraints = false; addSubview(regionScroll)
        regions.axis = .horizontal; regions.spacing = 7; regions.translatesAutoresizingMaskIntoConstraints = false; regionScroll.addSubview(regions)
        regionLocator.accessibilityIdentifier = "discover.location"; regionLocator.accessibilityLabel = "Use my region".lmLocalized
        regionLocator.setImage(UIImage(systemName: "location.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)), for: .normal)
        regionLocator.tintColor = .white; regionLocator.backgroundColor = LMTheme.violet.withAlphaComponent(0.48); regionLocator.round(9); regionLocator.translatesAutoresizingMaskIntoConstraints = false; regionLocator.addTarget(self, action: #selector(locationTapped), for: .touchUpInside); addSubview(regionLocator)
        NSLayoutConstraint.activate([
            categories.topAnchor.constraint(equalTo: topAnchor, constant: 3), categories.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 7), categories.trailingAnchor.constraint(equalTo: search.leadingAnchor, constant: -2), categories.heightAnchor.constraint(equalToConstant: 39),
            search.centerYAnchor.constraint(equalTo: categories.centerYAnchor), search.widthAnchor.constraint(equalToConstant: 38), search.heightAnchor.constraint(equalToConstant: 38),
            gift.leadingAnchor.constraint(equalTo: search.trailingAnchor, constant: 1), gift.centerYAnchor.constraint(equalTo: search.centerYAnchor), gift.widthAnchor.constraint(equalToConstant: 36), gift.heightAnchor.constraint(equalToConstant: 38),
            create.leadingAnchor.constraint(equalTo: gift.trailingAnchor, constant: 3), create.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5), create.centerYAnchor.constraint(equalTo: search.centerYAnchor), create.widthAnchor.constraint(equalToConstant: 38), create.heightAnchor.constraint(equalToConstant: 38),
            regionScroll.topAnchor.constraint(equalTo: categories.bottomAnchor, constant: 5), regionScroll.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 7), regionScroll.trailingAnchor.constraint(equalTo: regionLocator.leadingAnchor, constant: -6), regionScroll.heightAnchor.constraint(equalToConstant: 34),
            regionLocator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6), regionLocator.centerYAnchor.constraint(equalTo: regionScroll.centerYAnchor), regionLocator.widthAnchor.constraint(equalToConstant: 42), regionLocator.heightAnchor.constraint(equalToConstant: 34),
            regions.topAnchor.constraint(equalTo: regionScroll.topAnchor), regions.leadingAnchor.constraint(equalTo: regionScroll.leadingAnchor), regions.trailingAnchor.constraint(equalTo: regionScroll.trailingAnchor, constant: -8), regions.bottomAnchor.constraint(equalTo: regionScroll.bottomAnchor), regions.heightAnchor.constraint(equalTo: regionScroll.heightAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    private func iconButton(_ symbol: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .medium)), for: .normal)
        button.tintColor = .white; button.translatesAutoresizingMaskIntoConstraints = false; button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    func configure(category: String, region: String, categoryAction: @escaping (String) -> Void, regionAction: @escaping (String) -> Void, searchAction: @escaping () -> Void, giftAction: @escaping () -> Void, createAction: @escaping () -> Void, locationAction: @escaping () -> Void) {
        self.categoryAction = categoryAction; self.regionAction = regionAction; self.searchAction = searchAction; self.giftAction = giftAction; self.createAction = createAction; self.locationAction = locationAction
        categories.arrangedSubviews.forEach { $0.removeFromSuperview() }; regions.arrangedSubviews.forEach { $0.removeFromSuperview() }
        ["All", "Live", "New", "Follow"].forEach { value in
            let holder = UIView(); let button = UIButton(type: .system)
            button.accessibilityIdentifier = "discover.category.\(value)"
            button.setTitle(value.lmLocalized, for: .normal); button.setTitleColor(value == category ? .white : LMTheme.muted, for: .normal)
            button.titleLabel?.font = LMTheme.font(size: 13, weight: value == category ? .bold : .medium); button.translatesAutoresizingMaskIntoConstraints = false
            button.addAction(UIAction { [weak self] _ in self?.categoryAction?(value) }, for: .touchUpInside); holder.addSubview(button)
            NSLayoutConstraint.activate([button.topAnchor.constraint(equalTo: holder.topAnchor), button.leadingAnchor.constraint(equalTo: holder.leadingAnchor), button.trailingAnchor.constraint(equalTo: holder.trailingAnchor), button.bottomAnchor.constraint(equalTo: holder.bottomAnchor)])
            if value == category { let line = UIView(); line.backgroundColor = LMTheme.pink; line.round(1.5); line.translatesAutoresizingMaskIntoConstraints = false; holder.addSubview(line); NSLayoutConstraint.activate([line.bottomAnchor.constraint(equalTo: holder.bottomAnchor), line.centerXAnchor.constraint(equalTo: holder.centerXAnchor), line.widthAnchor.constraint(equalToConstant: 21), line.heightAnchor.constraint(equalToConstant: 3)]) }
            categories.addArrangedSubview(holder)
        }
        ["Global", "Europe", "Asia", "Latin", "India", "MENA", "Africa", "North America", "Oceania"].forEach { value in
            let button = UIButton(type: .system); button.setTitle(value, for: .normal); button.setTitleColor(value == region ? .white : UIColor.white.withAlphaComponent(0.72), for: .normal)
            button.titleLabel?.font = LMTheme.font(size: 10, weight: .medium); button.backgroundColor = value == region ? LMTheme.pink.withAlphaComponent(0.30) : UIColor.white.withAlphaComponent(0.07)
            button.layer.borderWidth = value == region ? 0.8 : 0; button.layer.borderColor = LMTheme.pink.cgColor; button.round(7); button.widthAnchor.constraint(equalToConstant: CGFloat(value.count) * 5.5 + 18).isActive = true
            button.addAction(UIAction { [weak self] _ in self?.regionAction?(value) }, for: .touchUpInside); regions.addArrangedSubview(button)
        }
    }

    @objc private func searchTapped() { searchAction?() }
    @objc private func giftTapped() { giftAction?() }
    @objc private func createTapped() { createAction?() }
    @objc private func locationTapped() { locationAction?() }
}

final class PresenceProfileCardCell: UICollectionViewCell {
    private let image = UIImageView()
    private let name = UILabel.lm(size: 15, weight: .bold)
    private let meta = UILabel.lm(size: 12, color: .white.withAlphaComponent(0.86))
    private let rank = UILabel.lm(size: 10, weight: .bold)
    private let videoBadge = UIImageView(image: UIImage(systemName: "video.fill"))

    override init(frame: CGRect) {
        super.init(frame: frame); contentView.backgroundColor = LMTheme.panel2; contentView.round(7)
        image.contentMode = .scaleAspectFill; contentView.addSubview(image); image.pin(to: contentView)
        let fade = UIView(); fade.isUserInteractionEnabled = false; contentView.addSubview(fade); fade.pin(to: contentView)
        // Preserve the portrait's original brightness through most of the card.
        // A softer lower fade is enough to keep the name and age readable.
        DispatchQueue.main.async {
            LMTheme.gradient(fade, colors: [.clear, .clear, UIColor.black.withAlphaComponent(0.68)], horizontal: false)
        }
        videoBadge.tintColor = .white; videoBadge.contentMode = .center; videoBadge.backgroundColor = LMTheme.pink; videoBadge.round(19)
        [name, meta, rank, videoBadge].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; contentView.addSubview($0) }
        rank.backgroundColor = LMTheme.pink.withAlphaComponent(0.94); rank.textAlignment = .center; rank.round(8)
        NSLayoutConstraint.activate([
            name.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 9), name.bottomAnchor.constraint(equalTo: meta.topAnchor, constant: -2), name.trailingAnchor.constraint(lessThanOrEqualTo: videoBadge.leadingAnchor, constant: -5),
            meta.leadingAnchor.constraint(equalTo: name.leadingAnchor), meta.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8), meta.trailingAnchor.constraint(lessThanOrEqualTo: videoBadge.leadingAnchor, constant: -5),
            rank.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7), rank.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -7), rank.widthAnchor.constraint(greaterThanOrEqualToConstant: 30), rank.heightAnchor.constraint(equalToConstant: 17),
            videoBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -9), videoBadge.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10), videoBadge.widthAnchor.constraint(equalToConstant: 38), videoBadge.heightAnchor.constraint(equalToConstant: 38)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ member: CommunityProfile) {
        accessibilityIdentifier = "discover.member.\(member.id)"; isAccessibilityElement = true; accessibilityLabel = "\(member.name), \(member.age), \(member.region)"
        image.image = UIImage(named: member.image)
        videoBadge.isHidden = !member.isLive
        let text = NSMutableAttributedString(string: "● ", attributes: [.foregroundColor: member.isLive ? UIColor(red: 0.20, green: 0.95, blue: 0.50, alpha: 1) : UIColor.white.withAlphaComponent(0.45)])
        text.append(NSAttributedString(string: member.name, attributes: [.foregroundColor: UIColor.white])); name.attributedText = text
        meta.text = "\(member.age)   \(member.country)"; rank.text = " \(member.rank) "
    }
}
