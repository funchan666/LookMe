import UIKit

final class InterestRoomsViewController: LMViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var collectionView: UICollectionView!
    private var selectedTab = "Party"
    private var selectedLanguage = "All"
    private var query = ""
    private static let editorialAudience: [String: String] = [
        "glow-after-dark": "English",
        "city-pop-lounge": "Spain",
        "coffee-good-news": "English",
        "game-night": "India",
        "travel-postcards": "Turkey",
        "late-night-cinema": "China"
    ]
    private let editorialRooms = [
        InterestRoomBlueprint(roomKey: "glow-after-dark", roomTitle: "Glow After Dark", roomSummary: "Music · stories · easy company", coverAssetName: CommunityMediaRegistry.voiceRoomCoverAssets[0], participantPortraitAssets: [CommunityMediaRegistry.images[0], CommunityMediaRegistry.images[3], CommunityMediaRegistry.images[5]], liveAudienceCount: 328, topicLabel: "Featured", hostProfileKey: "member-0", isCommunityCreated: false),
        InterestRoomBlueprint(roomKey: "city-pop-lounge", roomTitle: "City Pop Lounge", roomSummary: "Live playlist", coverAssetName: CommunityMediaRegistry.voiceRoomCoverAssets[1], participantPortraitAssets: [CommunityMediaRegistry.images[6], CommunityMediaRegistry.images[7], CommunityMediaRegistry.images[9]], liveAudienceCount: 86, topicLabel: "Music", hostProfileKey: "member-6", isCommunityCreated: false),
        InterestRoomBlueprint(roomKey: "coffee-good-news", roomTitle: "Coffee & Good News", roomSummary: "English room", coverAssetName: CommunityMediaRegistry.voiceRoomCoverAssets[2], participantPortraitAssets: [CommunityMediaRegistry.images[10], CommunityMediaRegistry.images[11], CommunityMediaRegistry.images[15]], liveAudienceCount: 42, topicLabel: "Conversation", hostProfileKey: "member-10", isCommunityCreated: false),
        InterestRoomBlueprint(roomKey: "game-night", roomTitle: "Game Night", roomSummary: "Friendly challenges", coverAssetName: CommunityMediaRegistry.voiceRoomCoverAssets[3], participantPortraitAssets: [CommunityMediaRegistry.images[17], CommunityMediaRegistry.images[18], CommunityMediaRegistry.images[19]], liveAudienceCount: 115, topicLabel: "Games", hostProfileKey: "member-17", isCommunityCreated: false),
        InterestRoomBlueprint(roomKey: "travel-postcards", roomTitle: "Travel Postcards", roomSummary: "Share your favorite view", coverAssetName: CommunityMediaRegistry.voiceRoomCoverAssets[4], participantPortraitAssets: [CommunityMediaRegistry.images[21], CommunityMediaRegistry.images[22], CommunityMediaRegistry.images[23]], liveAudienceCount: 73, topicLabel: "Travel", hostProfileKey: "member-21", isCommunityCreated: false),
        InterestRoomBlueprint(roomKey: "late-night-cinema", roomTitle: "Late Night Cinema", roomSummary: "Tonight's watch list", coverAssetName: CommunityMediaRegistry.voiceRoomCoverAssets[5], participantPortraitAssets: [CommunityMediaRegistry.images[27], CommunityMediaRegistry.images[28], CommunityMediaRegistry.images[29]], liveAudienceCount: 61, topicLabel: "Cinema", hostProfileKey: "member-27", isCommunityCreated: false)
    ]

    private var rooms: [InterestRoomBlueprint] {
        let allRooms = LookMeExperienceStore.shared.createdInterestRooms + editorialRooms
        let base: [InterestRoomBlueprint]
        switch selectedTab {
        case "Follow":
            base = allRooms.filter { LookMeExperienceStore.shared.following.contains($0.host.id) }
        case "Recent":
            base = Array(allRooms.reversed())
        default:
            base = allRooms
        }
        return base.filter {
            !LookMeExperienceStore.shared.isReported("voice-room:\($0.id)") &&
            !LookMeExperienceStore.shared.blockedUsers.contains($0.host.id) &&
            (selectedLanguage == "All" || audience(for: $0) == selectedLanguage) &&
            (query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || $0.subtitle.localizedCaseInsensitiveContains(query))
        }
    }

    private func audience(for room: InterestRoomBlueprint) -> String {
        if let audience = Self.editorialAudience[room.id] { return audience }
        switch LookMeLanguageCenter.shared.selectedLanguage {
        case .simplifiedChinese: return "China"
        case .spanish: return "Spain"
        default: return "English"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = UICollectionViewFlowLayout(); layout.minimumLineSpacing = 10; layout.minimumInteritemSpacing = 10; layout.sectionInset = UIEdgeInsets(top: 2, left: 12, bottom: 24, right: 12); layout.headerReferenceSize = CGSize(width: view.bounds.width, height: 92)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout); collectionView.backgroundColor = .clear; collectionView.showsVerticalScrollIndicator = false
        collectionView.register(InterestRoomMosaicCell.self, forCellWithReuseIdentifier: "room"); collectionView.register(InterestRoomFilterHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "partyHeader")
        collectionView.dataSource = self; collectionView.delegate = self; view.addSubview(collectionView); collectionView.pin(to: view)
        NotificationCenter.default.addObserver(forName: .lookMeStoreChanged, object: nil, queue: .main) { [weak self] _ in self?.collectionView.reloadData() }
    }

    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); navigationController?.setNavigationBarHidden(true, animated: false) }
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated); navigationController?.setNavigationBarHidden(false, animated: false) }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { rooms.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell { let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "room", for: indexPath) as! InterestRoomMosaicCell; cell.configure(rooms[indexPath.item], featured: indexPath.item == 0); return cell }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize { indexPath.item == 0 ? CGSize(width: collectionView.bounds.width - 24, height: 172) : CGSize(width: (collectionView.bounds.width - 34) / 2, height: 198) }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) { navigationController?.pushViewController(InterestRoomInvitationViewController(room: rooms[indexPath.item]), animated: true) }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "partyHeader", for: indexPath) as! InterestRoomFilterHeader
        header.configure(selectedTab: selectedTab, selectedLanguage: selectedLanguage, tabAction: { [weak self] value in self?.selectedTab = value; self?.collectionView.reloadData() }, languageAction: { [weak self] value in self?.selectedLanguage = value; self?.collectionView.reloadData() }, searchAction: { [weak self] in self?.search() }, giftAction: { [weak self] in self?.navigationController?.pushViewController(EffectBoutiqueViewController(), animated: true) }, createAction: { [weak self] in self?.createRoom() })
        return header
    }

    private func search() { let alert = UIAlertController(title: "Search rooms".lmLocalized, message: nil, preferredStyle: .alert); alert.addTextField { $0.placeholder = "Room name".lmLocalized; $0.text = self.query }; alert.addAction(UIAlertAction(title: "Cancel".lmLocalized, style: .cancel)); alert.addAction(UIAlertAction(title: "Search".lmLocalized, style: .default) { [weak self, weak alert] _ in self?.query = alert?.textFields?.first?.text ?? ""; self?.collectionView.reloadData() }); present(alert, animated: true) }
    private func createRoom() {
        let composer = InterestRoomComposerViewController()
        composer.onCreated = { [weak self] room in
            self?.collectionView.reloadData()
            self?.navigationController?.pushViewController(InterestRoomInvitationViewController(room: room), animated: true)
        }
        navigationController?.pushViewController(composer, animated: true)
    }
}

final class InterestRoomFilterHeader: UICollectionReusableView {
    private let tabs = UIStackView(); private let languageScroll = UIScrollView(); private let languages = UIStackView()
    private var tabAction: ((String) -> Void)?; private var languageAction: ((String) -> Void)?; private var searchAction: (() -> Void)?; private var giftAction: (() -> Void)?; private var createAction: (() -> Void)?
    override init(frame: CGRect) {
        super.init(frame: frame)
        tabs.axis = .horizontal; tabs.spacing = 18; tabs.translatesAutoresizingMaskIntoConstraints = false; addSubview(tabs)
        let search = icon("magnifyingglass", #selector(searchTap)); search.accessibilityIdentifier = "rooms.search"
        let gift = icon("gift.fill", #selector(giftTap)); gift.accessibilityIdentifier = "rooms.gifts"
        let create = icon("plus.circle.fill", #selector(createTap)); create.accessibilityIdentifier = "rooms.create"
        [search, gift, create].forEach(addSubview)
        languageScroll.showsHorizontalScrollIndicator = false; languageScroll.translatesAutoresizingMaskIntoConstraints = false; addSubview(languageScroll); languages.axis = .horizontal; languages.spacing = 7; languages.translatesAutoresizingMaskIntoConstraints = false; languageScroll.addSubview(languages)
        NSLayoutConstraint.activate([tabs.topAnchor.constraint(equalTo: topAnchor, constant: 3), tabs.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5), tabs.heightAnchor.constraint(equalToConstant: 40), create.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2), create.centerYAnchor.constraint(equalTo: tabs.centerYAnchor), create.widthAnchor.constraint(equalToConstant: 34), create.heightAnchor.constraint(equalToConstant: 34), gift.trailingAnchor.constraint(equalTo: create.leadingAnchor, constant: -1), gift.centerYAnchor.constraint(equalTo: create.centerYAnchor), gift.widthAnchor.constraint(equalToConstant: 34), gift.heightAnchor.constraint(equalToConstant: 34), search.trailingAnchor.constraint(equalTo: gift.leadingAnchor, constant: -1), search.centerYAnchor.constraint(equalTo: create.centerYAnchor), search.widthAnchor.constraint(equalToConstant: 34), search.heightAnchor.constraint(equalToConstant: 34), languageScroll.topAnchor.constraint(equalTo: tabs.bottomAnchor, constant: 5), languageScroll.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3), languageScroll.trailingAnchor.constraint(equalTo: trailingAnchor), languageScroll.heightAnchor.constraint(equalToConstant: 34), languages.topAnchor.constraint(equalTo: languageScroll.topAnchor), languages.bottomAnchor.constraint(equalTo: languageScroll.bottomAnchor), languages.leadingAnchor.constraint(equalTo: languageScroll.leadingAnchor), languages.trailingAnchor.constraint(equalTo: languageScroll.trailingAnchor, constant: -8), languages.heightAnchor.constraint(equalTo: languageScroll.heightAnchor)])
    }
    required init?(coder: NSCoder) { fatalError() }
    private func icon(_ name: String, _ selector: Selector) -> UIButton { let b = UIButton(type: .system); b.setImage(UIImage(systemName: name, withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)), for: .normal); b.tintColor = .white; b.translatesAutoresizingMaskIntoConstraints = false; b.addTarget(self, action: selector, for: .touchUpInside); return b }
    func configure(selectedTab: String, selectedLanguage: String, tabAction: @escaping (String) -> Void, languageAction: @escaping (String) -> Void, searchAction: @escaping () -> Void, giftAction: @escaping () -> Void, createAction: @escaping () -> Void) {
        self.tabAction = tabAction; self.languageAction = languageAction; self.searchAction = searchAction; self.giftAction = giftAction; self.createAction = createAction; tabs.arrangedSubviews.forEach { $0.removeFromSuperview() }; languages.arrangedSubviews.forEach { $0.removeFromSuperview() }
        ["Party", "Follow", "Recent"].forEach { value in let holder = UIView(); let b = UIButton(type: .system); b.accessibilityIdentifier = "rooms.tab.\(value)"; b.setTitle(value.lmLocalized, for: .normal); b.setTitleColor(value == selectedTab ? .white : LMTheme.muted, for: .normal); b.titleLabel?.font = LMTheme.font(size: 15, weight: value == selectedTab ? .bold : .medium); b.translatesAutoresizingMaskIntoConstraints = false; b.addAction(UIAction { [weak self] _ in self?.tabAction?(value) }, for: .touchUpInside); holder.addSubview(b); NSLayoutConstraint.activate([b.topAnchor.constraint(equalTo: holder.topAnchor), b.bottomAnchor.constraint(equalTo: holder.bottomAnchor), b.leadingAnchor.constraint(equalTo: holder.leadingAnchor), b.trailingAnchor.constraint(equalTo: holder.trailingAnchor)]); if value == selectedTab { let line = UIView(); line.backgroundColor = LMTheme.pink; line.round(1.5); line.translatesAutoresizingMaskIntoConstraints = false; holder.addSubview(line); NSLayoutConstraint.activate([line.bottomAnchor.constraint(equalTo: holder.bottomAnchor), line.centerXAnchor.constraint(equalTo: holder.centerXAnchor), line.widthAnchor.constraint(equalToConstant: 22), line.heightAnchor.constraint(equalToConstant: 3)]) }; tabs.addArrangedSubview(holder) }
        ["All", "English", "Spain", "India", "Turkey", "China"].forEach { value in let b = UIButton(type: .system); b.accessibilityIdentifier = "rooms.filter.\(value)"; b.setTitle(value, for: .normal); b.setTitleColor(value == selectedLanguage ? .white : .white.withAlphaComponent(0.65), for: .normal); b.titleLabel?.font = LMTheme.font(size: 11, weight: .medium); b.backgroundColor = value == selectedLanguage ? LMTheme.pink.withAlphaComponent(0.85) : UIColor.white.withAlphaComponent(0.07); b.round(13); b.widthAnchor.constraint(equalToConstant: CGFloat(value.count * 7 + 24)).isActive = true; b.addAction(UIAction { [weak self] _ in self?.languageAction?(value) }, for: .touchUpInside); languages.addArrangedSubview(b) }
    }
    @objc private func searchTap() { searchAction?() }; @objc private func giftTap() { giftAction?() }; @objc private func createTap() { createAction?() }
}

final class InterestRoomMosaicCell: UICollectionViewCell {
    private let image = UIImageView(); private let title = UILabel.lm(size: 15, weight: .bold); private let subtitle = UILabel.lm(size: 11, weight: .medium, color: .white.withAlphaComponent(0.72)); private let tagLabel = UILabel.lm(size: 10, weight: .bold); private let count = UILabel.lm(size: 11, weight: .semibold); private let avatarStack = UIStackView()
    override init(frame: CGRect) {
        super.init(frame: frame); contentView.backgroundColor = LMTheme.panel; contentView.round(10); contentView.layer.borderWidth = 0.5; contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        image.contentMode = .scaleAspectFill; image.translatesAutoresizingMaskIntoConstraints = false; contentView.addSubview(image)
        tagLabel.backgroundColor = LMTheme.pink; tagLabel.textAlignment = .center; tagLabel.round(9); avatarStack.axis = .horizontal; avatarStack.spacing = -7
        [title, subtitle, count].forEach {
            $0.layer.shadowColor = UIColor.black.cgColor
            $0.layer.shadowOpacity = 0.9
            $0.layer.shadowRadius = 3
            $0.layer.shadowOffset = CGSize(width: 0, height: 1)
        }
        [title, subtitle, tagLabel, count, avatarStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; contentView.addSubview($0) }
        NSLayoutConstraint.activate([image.topAnchor.constraint(equalTo: contentView.topAnchor), image.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), image.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), image.bottomAnchor.constraint(equalTo: contentView.bottomAnchor), title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 11), title.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -9), title.bottomAnchor.constraint(equalTo: subtitle.topAnchor, constant: -3), subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor), subtitle.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -8), subtitle.bottomAnchor.constraint(equalTo: avatarStack.topAnchor, constant: -8), avatarStack.leadingAnchor.constraint(equalTo: title.leadingAnchor), avatarStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10), avatarStack.heightAnchor.constraint(equalToConstant: 25), count.leadingAnchor.constraint(equalTo: avatarStack.trailingAnchor, constant: 6), count.centerYAnchor.constraint(equalTo: avatarStack.centerYAnchor), tagLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 9), tagLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -9), tagLabel.heightAnchor.constraint(equalToConstant: 18), tagLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 42)])
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(_ room: InterestRoomBlueprint, featured: Bool) { accessibilityIdentifier = "room.card.\(room.id)"; isAccessibilityElement = true; accessibilityLabel = "\(room.title), \(room.online) listening"; image.image = UIImage(named: room.image); title.text = room.title; title.font = LMTheme.font(size: featured ? 20 : 15, weight: .bold); subtitle.text = room.subtitle; tagLabel.text = "  \(room.tag)  "; count.text = "\(room.online)"; avatarStack.arrangedSubviews.forEach { $0.removeFromSuperview() }; room.guests.forEach { name in let avatar = UIImageView(image: UIImage(named: name)); avatar.contentMode = .scaleAspectFill; avatar.round(12.5); avatar.layer.borderWidth = 1.5; avatar.layer.borderColor = LMTheme.panel.cgColor; avatar.widthAnchor.constraint(equalToConstant: 25).isActive = true; avatarStack.addArrangedSubview(avatar) } }
}

final class InterestRoomInvitationViewController: LMViewController {
    private let room: InterestRoomBlueprint
    init(room: InterestRoomBlueprint) { self.room = room; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); title = room.title
        let hero = UIImageView(image: UIImage(named: room.image)); hero.contentMode = .scaleAspectFill; hero.clipsToBounds = true; hero.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(hero)
        let shade = UIView(); shade.translatesAutoresizingMaskIntoConstraints = false; hero.addSubview(shade); DispatchQueue.main.async { LMTheme.gradient(shade, colors: [.clear, LMTheme.background], horizontal: false) }
        let title = UILabel.lm(room.title, size: 27, weight: .bold); let subtitle = UILabel.lm(room.subtitle, size: 14, weight: .medium, color: .white.withAlphaComponent(0.72)); let online = UILabel.lm("●  \(room.online) people here", size: 13, weight: .semibold, color: .systemGreen)
        let note = UILabel.lm("A focused room built around a shared interest. Listen first, join the stage when you're ready, and use the safety menu whenever you need it.", size: 15, weight: .medium, color: .white.withAlphaComponent(0.82)); note.numberOfLines = 0
        let join = UIButton.lm("Enter room", symbol: "arrow.right.circle.fill"); join.accessibilityIdentifier = "room.enter"; join.backgroundColor = LMTheme.pink; join.round(25); join.addAction(UIAction { [weak self] _ in self?.joined() }, for: .touchUpInside)
        [title, subtitle, online].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; hero.addSubview($0) }
        [note, join].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; view.addSubview($0) }
        NSLayoutConstraint.activate([hero.topAnchor.constraint(equalTo: view.topAnchor), hero.leadingAnchor.constraint(equalTo: view.leadingAnchor), hero.trailingAnchor.constraint(equalTo: view.trailingAnchor), hero.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.46), shade.topAnchor.constraint(equalTo: hero.topAnchor), shade.leadingAnchor.constraint(equalTo: hero.leadingAnchor), shade.trailingAnchor.constraint(equalTo: hero.trailingAnchor), shade.bottomAnchor.constraint(equalTo: hero.bottomAnchor), title.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 20), title.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -20), subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6), subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor), subtitle.trailingAnchor.constraint(lessThanOrEqualTo: hero.trailingAnchor, constant: -20), online.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 12), online.leadingAnchor.constraint(equalTo: title.leadingAnchor), online.bottomAnchor.constraint(equalTo: hero.bottomAnchor, constant: -20), note.topAnchor.constraint(equalTo: hero.bottomAnchor, constant: 24), note.leadingAnchor.constraint(equalTo: title.leadingAnchor), note.trailingAnchor.constraint(equalTo: title.trailingAnchor), note.bottomAnchor.constraint(lessThanOrEqualTo: join.topAnchor, constant: -22), join.leadingAnchor.constraint(equalTo: title.leadingAnchor), join.trailingAnchor.constraint(equalTo: title.trailingAnchor), join.heightAnchor.constraint(equalToConstant: 52), join.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18)])
    }
    private func joined() {
        CallPermissionManager.request(video: false, from: self) { [weak self] in
            guard let self else { return }
            self.navigationController?.pushViewController(VoiceRoomViewController(room: self.room), animated: true)
        }
    }
}
