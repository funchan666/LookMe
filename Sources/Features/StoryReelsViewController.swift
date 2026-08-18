import UIKit
import AVFoundation

final class StoryReelsViewController: LMViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var collectionView: UICollectionView!
    private var likedReelAssets = Set(UserDefaults.standard.stringArray(forKey: "likedReelAssets") ?? [])
    private var reels: [(video: String, member: CommunityProfile)] {
        zip(CommunityMediaRegistry.reelVideos, LookMeCommunityDirectory.members).filter { video, member in
            !LookMeExperienceStore.shared.blockedUsers.contains(member.id) && !LookMeExperienceStore.shared.isReported("reel:\(video)")
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = UICollectionViewFlowLayout(); layout.scrollDirection = .vertical; layout.minimumLineSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true; collectionView.showsVerticalScrollIndicator = false; collectionView.backgroundColor = .black; collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.dataSource = self; collectionView.delegate = self; collectionView.register(ReelCell.self, forCellWithReuseIdentifier: "reel")
        view.addSubview(collectionView); collectionView.pin(to: view)
        NotificationCenter.default.addObserver(forName: .lookMeStoreChanged, object: nil, queue: .main) { [weak self] _ in self?.reloadAfterSafetyChange() }
    }
    override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); playVisible() }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); navigationController?.setNavigationBarHidden(true, animated: false) }
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated); visibleCell()?.pause() }
    override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews(); collectionView.collectionViewLayout.invalidateLayout() }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { reels.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = reels[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "reel", for: indexPath) as! ReelCell
        cell.configure(video: item.video, member: item.member, captionText: CommunityMediaRegistry.reelCaption(for: item.video), isLiked: likedReelAssets.contains(item.video), commentCount: LookMeExperienceStore.shared.comments(for: "reel:\(item.video)").count)
        cell.onLikeChanged = { [weak self] isLiked in
            guard let self else { return }
            if isLiked { self.likedReelAssets.insert(item.video) } else { self.likedReelAssets.remove(item.video) }
            UserDefaults.standard.set(Array(self.likedReelAssets).sorted(), forKey: "likedReelAssets")
        }
        cell.onComments = { [weak self] in self?.present(ContentCommentsViewController(contentID: "reel:\(item.video)", title: "Comments"), animated: true) }
        cell.onMore = { [weak self] in guard let self else { return }; SafetyCoordinator.present(from: self, target: .init(id: "reel:\(item.video)", type: "video", userID: item.member.id, displayName: item.member.name)) }
        cell.onProfile = { [weak self] in
            guard let self else { return }
            self.navigationController?.setNavigationBarHidden(false, animated: false)
            self.navigationController?.pushViewController(CommunityProfileDetailViewController(member: item.member), animated: true)
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize { collectionView.bounds.size }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { playVisible() }
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) { (cell as? ReelCell)?.pause() }
    private func visibleCell() -> ReelCell? { collectionView.visibleCells.first as? ReelCell }
    private func playVisible() { visibleCell()?.play() }
    private func reloadAfterSafetyChange() { visibleCell()?.pause(); collectionView.reloadData(); DispatchQueue.main.async { [weak self] in self?.playVisible() } }
}

final class ReelCell: UICollectionViewCell {
    var onComments: (() -> Void)?; var onMore: (() -> Void)?; var onProfile: (() -> Void)?; var onLikeChanged: ((Bool) -> Void)?
    private let videoView = PlayerSurfaceView(); private let name = UIButton(type: .system); private let caption = UILabel.lm(size: 14, weight: .medium); private let avatar = UIButton(type: .custom)
    private let like = UIButton(type: .system); private let comments = UIButton(type: .system); private let commentBadge = UILabel.lm(size: 9, weight: .heavy); private let more = UIButton(type: .system); private let playMark = UIImageView()
    private var player: AVPlayer?; private var endObserver: NSObjectProtocol?; private var isPausedByUser = false
    override init(frame: CGRect) {
        super.init(frame: frame); backgroundColor = .black; videoView.videoGravity = .resizeAspectFill; contentView.addSubview(videoView); videoView.pin(to: contentView)
        videoView.isUserInteractionEnabled = true; videoView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(togglePlayback)))
        let shade = LMGradientView(colors: [.clear, UIColor.black.withAlphaComponent(0.16), UIColor.black.withAlphaComponent(0.78)], horizontal: false); shade.translatesAutoresizingMaskIntoConstraints = false; contentView.addSubview(shade)
        NSLayoutConstraint.activate([shade.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), shade.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), shade.bottomAnchor.constraint(equalTo: contentView.bottomAnchor), shade.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.38)])
        name.setTitleColor(.white, for: .normal); name.titleLabel?.font = LMTheme.font(size: 19, weight: .bold); name.contentHorizontalAlignment = .leading; name.addTarget(self, action: #selector(profileTap), for: .touchUpInside); name.titleLabel?.layer.shadowColor = UIColor.black.cgColor; name.titleLabel?.layer.shadowOpacity = 0.72; name.titleLabel?.layer.shadowRadius = 5; name.titleLabel?.layer.shadowOffset = CGSize(width: 0, height: 2)
        caption.numberOfLines = 2; caption.layer.shadowColor = UIColor.black.cgColor; caption.layer.shadowOpacity = 0.72; caption.layer.shadowRadius = 5; caption.layer.shadowOffset = CGSize(width: 0, height: 2)
        let actions = UIStackView(); actions.axis = .vertical; actions.spacing = 12; actions.alignment = .center; configureAction(like, symbol: "heart.fill"); configureAction(comments, symbol: "bubble.left.fill")
        avatar.accessibilityIdentifier = "reel.avatar"; avatar.contentHorizontalAlignment = .fill; avatar.contentVerticalAlignment = .fill; avatar.imageView?.contentMode = .scaleAspectFill; avatar.imageView?.clipsToBounds = true; avatar.clipsToBounds = true; avatar.round(26); avatar.layer.borderWidth = 2; avatar.layer.borderColor = LMTheme.pinkSoft.cgColor; avatar.widthAnchor.constraint(equalToConstant: 52).isActive = true; avatar.heightAnchor.constraint(equalToConstant: 52).isActive = true; avatar.addTarget(self, action: #selector(profileTap), for: .touchUpInside)
        like.accessibilityIdentifier = "reel.like"; like.addTarget(self, action: #selector(toggleLike), for: .touchUpInside); comments.accessibilityIdentifier = "reel.comments"; comments.addTarget(self, action: #selector(commentsTap), for: .touchUpInside)
        comments.layer.masksToBounds = false
        commentBadge.backgroundColor = LMTheme.pink; commentBadge.textAlignment = .center; commentBadge.round(10); commentBadge.layer.borderWidth = 2; commentBadge.layer.borderColor = UIColor.black.withAlphaComponent(0.55).cgColor; commentBadge.layer.masksToBounds = true; commentBadge.isAccessibilityElement = false; commentBadge.translatesAutoresizingMaskIntoConstraints = false; comments.addSubview(commentBadge)
        NSLayoutConstraint.activate([commentBadge.trailingAnchor.constraint(equalTo: comments.trailingAnchor, constant: 4), commentBadge.topAnchor.constraint(equalTo: comments.topAnchor, constant: -4), commentBadge.heightAnchor.constraint(equalToConstant: 20), commentBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20)])
        actions.addArrangedSubview(avatar); actions.addArrangedSubview(like); actions.addArrangedSubview(comments)
        more.setImage(UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: .bold)), for: .normal); more.tintColor = .white; more.backgroundColor = UIColor.black.withAlphaComponent(0.38); more.layer.borderWidth = 0.8; more.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor; more.round(21); more.layer.shadowColor = UIColor.black.cgColor; more.layer.shadowOpacity = 0.3; more.layer.shadowRadius = 8; more.layer.shadowOffset = CGSize(width: 0, height: 3); more.addTarget(self, action: #selector(moreTap), for: .touchUpInside)
        playMark.image = UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 36, weight: .bold)); playMark.tintColor = .white; playMark.contentMode = .center; playMark.backgroundColor = UIColor.black.withAlphaComponent(0.42); playMark.round(36); playMark.alpha = 0
        [name, caption, actions, more, playMark].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; contentView.addSubview($0) }
        NSLayoutConstraint.activate([
            more.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 12), more.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14), more.widthAnchor.constraint(equalToConstant: 42), more.heightAnchor.constraint(equalTo: more.widthAnchor),
            actions.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16), actions.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            name.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18), name.trailingAnchor.constraint(lessThanOrEqualTo: actions.leadingAnchor, constant: -12), name.bottomAnchor.constraint(equalTo: caption.topAnchor, constant: -4), name.heightAnchor.constraint(equalToConstant: 28),
            caption.leadingAnchor.constraint(equalTo: name.leadingAnchor), caption.trailingAnchor.constraint(equalTo: actions.leadingAnchor, constant: -14), caption.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            playMark.centerXAnchor.constraint(equalTo: contentView.centerXAnchor), playMark.centerYAnchor.constraint(equalTo: contentView.centerYAnchor), playMark.widthAnchor.constraint(equalToConstant: 72), playMark.heightAnchor.constraint(equalTo: playMark.widthAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    deinit { if let endObserver { NotificationCenter.default.removeObserver(endObserver) } }
    override func prepareForReuse() { super.prepareForReuse(); pause(); if let endObserver { NotificationCenter.default.removeObserver(endObserver); self.endObserver = nil }; player = nil; videoView.player = nil; avatar.setImage(nil, for: .normal); isPausedByUser = false; playMark.alpha = 0; onComments = nil; onMore = nil; onProfile = nil; onLikeChanged = nil }
    func configure(video: String, member: CommunityProfile, captionText: String, isLiked: Bool, commentCount: Int) {
        comments.accessibilityIdentifier = "reel.comments"
        if let url = Bundle.main.url(forResource: video, withExtension: nil) {
            let player = AVPlayer(url: url); player.isMuted = false; self.player = player; videoView.player = player
            endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { [weak self, weak player] _ in guard self?.isPausedByUser == false else { return }; player?.seek(to: .zero); player?.play() }
        } else {
            player = nil; videoView.player = nil
        }
        name.setTitle("@\(member.name.lowercased())", for: .normal); caption.text = captionText; caption.accessibilityIdentifier = "reel.caption.\(video)"; avatar.setImage(UIImage(named: member.image), for: .normal); avatar.accessibilityLabel = "View \(member.name)'s profile"; like.isSelected = isLiked; updateLikeAppearance()
        commentBadge.text = " \(commentCount) "; commentBadge.isHidden = commentCount == 0; comments.accessibilityLabel = "Comments"; comments.accessibilityValue = "\(commentCount) replies"; more.accessibilityLabel = "Report or block"
    }
    func play() { guard !isPausedByUser else { return }; player?.play() }
    func pause() { player?.pause() }
    private func configureAction(_ button: UIButton, symbol: String) { button.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 23, weight: .bold)), for: .normal); button.tintColor = .white; button.backgroundColor = UIColor.black.withAlphaComponent(0.40); button.layer.borderWidth = 0.8; button.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor; button.round(26); button.layer.shadowColor = UIColor.black.cgColor; button.layer.shadowOpacity = 0.32; button.layer.shadowRadius = 9; button.layer.shadowOffset = CGSize(width: 0, height: 4); button.widthAnchor.constraint(equalToConstant: 52).isActive = true; button.heightAnchor.constraint(equalToConstant: 52).isActive = true }
    @objc private func togglePlayback() { guard let player else { return }; isPausedByUser.toggle(); if isPausedByUser { player.pause(); playMark.alpha = 1 } else { player.play(); UIView.animate(withDuration: 0.22) { self.playMark.alpha = 0 } }; UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    @objc private func toggleLike() { like.isSelected.toggle(); updateLikeAppearance(); onLikeChanged?(like.isSelected); UIView.animate(withDuration: 0.16, animations: { self.like.transform = CGAffineTransform(scaleX: 1.12, y: 1.12) }) { _ in UIView.animate(withDuration: 0.16) { self.like.transform = .identity } }; UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    private func updateLikeAppearance() {
        let symbol = like.isSelected ? "heart.fill" : "heart"
        like.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 23, weight: .bold)), for: .normal)
        like.backgroundColor = like.isSelected ? LMTheme.pink : UIColor.black.withAlphaComponent(0.40)
        like.tintColor = .white
        like.layer.borderColor = (like.isSelected ? LMTheme.pink.withAlphaComponent(0.55) : UIColor.white.withAlphaComponent(0.18)).cgColor
        like.accessibilityLabel = "Like"
        like.accessibilityValue = like.isSelected ? "Liked" : "Not liked"
    }
    @objc private func commentsTap() { onComments?() }
    @objc private func moreTap() { onMore?() }
    @objc private func profileTap() { onProfile?() }
}

final class PlayerSurfaceView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    var player: AVPlayer? { get { playerLayer.player } set { playerLayer.player = newValue } }
    var videoGravity: AVLayerVideoGravity { get { playerLayer.videoGravity } set { playerLayer.videoGravity = newValue } }
}
