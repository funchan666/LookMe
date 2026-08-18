import UIKit
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

final class MomentsFeedViewController: LMViewController, UITableViewDataSource, UITableViewDelegate {
    private let table = UITableView(); private let empty = UILabel.lm("No moments to show.", size: 14, weight: .medium, color: LMTheme.muted)
    private var moments: [CommunityMomentRecord] { LookMeExperienceStore.shared.visibleMoments }
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Moments"; navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(create))
        table.backgroundColor = .clear; table.separatorStyle = .none; table.dataSource = self; table.delegate = self; table.estimatedRowHeight = 440; table.rowHeight = UITableView.automaticDimension; table.register(CommunityMomentCell.self, forCellReuseIdentifier: "moment"); view.addSubview(table); table.pin(to: view)
        empty.textAlignment = .center; empty.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(empty); NSLayoutConstraint.activate([empty.centerXAnchor.constraint(equalTo: view.centerXAnchor), empty.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
        NotificationCenter.default.addObserver(forName: .lookMeStoreChanged, object: nil, queue: .main) { [weak self] _ in self?.refresh() }; refresh()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { moments.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let moment = moments[indexPath.row]; let cell = tableView.dequeueReusableCell(withIdentifier: "moment", for: indexPath) as! CommunityMomentCell; cell.configure(moment)
        cell.onComment = { [weak self] in self?.present(ContentCommentsViewController(contentID: "moment:\(moment.id.uuidString)", title: "CommunityMomentRecord comments"), animated: true) }
        cell.onLike = { LookMeExperienceStore.shared.toggleLike(moment.id) }
        cell.onMore = { [weak self] in guard let self else { return }; SafetyCoordinator.present(from: self, target: .init(id: "moment:\(moment.id.uuidString)", type: "moment", userID: moment.authorID == "me" ? nil : moment.authorID, displayName: moment.author)) }
        return cell
    }
    @objc private func create() { navigationController?.pushViewController(CommunityMomentComposerViewController(), animated: true) }
    private func refresh() { table.reloadData(); empty.isHidden = !moments.isEmpty }
}

final class CommunityMomentCell: UITableViewCell {
    var onComment: (() -> Void)?; var onLike: (() -> Void)?; var onMore: (() -> Void)?
    private let card = UIView(); private let avatar = UIView(); private let initial = UILabel.lm(size: 13, weight: .bold); private let name = UILabel.lm(size: 15, weight: .bold); private let time = UILabel.lm(size: 10, color: LMTheme.muted); private let media = UIImageView(); private let videoBadge = UILabel.lm("  VIDEO  ", size: 9, weight: .bold); private let body = UILabel.lm(size: 14, weight: .medium); private let like = UIButton(type: .system); private let comment = UIButton(type: .system); private let more = UIButton(type: .system); private var mediaHeight: NSLayoutConstraint!
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier); backgroundColor = .clear; selectionStyle = .none; card.backgroundColor = LMTheme.panel; card.round(18); card.translatesAutoresizingMaskIntoConstraints = false; contentView.addSubview(card)
        avatar.backgroundColor = LMTheme.violet; avatar.round(20); initial.textAlignment = .center; media.contentMode = .scaleAspectFill; media.clipsToBounds = true; media.round(13); body.numberOfLines = 0; videoBadge.backgroundColor = LMTheme.pink; videoBadge.round(9)
        [like,comment].forEach { $0.tintColor = .white; $0.backgroundColor = UIColor.white.withAlphaComponent(0.06); $0.round(17) }; like.setImage(UIImage(systemName: "heart.fill"), for: .normal); comment.setImage(UIImage(systemName: "bubble.left.fill"), for: .normal); more.setImage(UIImage(systemName: "ellipsis"), for: .normal); more.tintColor = LMTheme.muted
        like.addTarget(self, action: #selector(likeTap), for: .touchUpInside); comment.addTarget(self, action: #selector(commentTap), for: .touchUpInside); more.addTarget(self, action: #selector(moreTap), for: .touchUpInside)
        [avatar,name,time,media,videoBadge,body,like,comment,more].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; card.addSubview($0) }; initial.translatesAutoresizingMaskIntoConstraints = false; avatar.addSubview(initial); mediaHeight = media.heightAnchor.constraint(equalToConstant: 315)
        NSLayoutConstraint.activate([card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8), card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12), card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12), card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8), avatar.topAnchor.constraint(equalTo: card.topAnchor, constant: 14), avatar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14), avatar.widthAnchor.constraint(equalToConstant: 40), avatar.heightAnchor.constraint(equalTo: avatar.widthAnchor), initial.centerXAnchor.constraint(equalTo: avatar.centerXAnchor), initial.centerYAnchor.constraint(equalTo: avatar.centerYAnchor), name.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 10), name.topAnchor.constraint(equalTo: avatar.topAnchor, constant: 2), time.leadingAnchor.constraint(equalTo: name.leadingAnchor), time.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 3), more.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10), more.centerYAnchor.constraint(equalTo: avatar.centerYAnchor), more.widthAnchor.constraint(equalToConstant: 40), more.heightAnchor.constraint(equalToConstant: 40), media.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 13), media.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10), media.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10), mediaHeight, videoBadge.topAnchor.constraint(equalTo: media.topAnchor, constant: 10), videoBadge.trailingAnchor.constraint(equalTo: media.trailingAnchor, constant: -10), videoBadge.heightAnchor.constraint(equalToConstant: 19), body.topAnchor.constraint(equalTo: media.bottomAnchor, constant: 13), body.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 15), body.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -15), like.topAnchor.constraint(equalTo: body.bottomAnchor, constant: 13), like.leadingAnchor.constraint(equalTo: body.leadingAnchor), like.widthAnchor.constraint(equalToConstant: 50), like.heightAnchor.constraint(equalToConstant: 34), comment.leadingAnchor.constraint(equalTo: like.trailingAnchor, constant: 9), comment.centerYAnchor.constraint(equalTo: like.centerYAnchor), comment.widthAnchor.constraint(equalToConstant: 50), comment.heightAnchor.constraint(equalToConstant: 34), like.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)])
    }
    required init?(coder: NSCoder) { fatalError() }
    override func prepareForReuse() { super.prepareForReuse(); onComment = nil; onLike = nil; onMore = nil; media.image = nil }
    func configure(_ moment: CommunityMomentRecord) { initial.text = String(moment.author.prefix(1)).uppercased(); name.text = moment.author; time.text = LookMeLanguageCenter.shared.relativeTime(from: moment.createdAt); body.text = moment.text; like.tintColor = moment.liked ? LMTheme.pink : .white; videoBadge.isHidden = moment.mediaType != "video"; if let path = moment.mediaPath { media.image = UIImage(contentsOfFile: path) ?? UIImage(systemName: "play.rectangle.fill") } else if let image = moment.image { media.image = UIImage(named: image) }; let hasMedia = moment.mediaPath != nil || moment.image != nil; mediaHeight.constant = hasMedia ? 315 : 0; media.isHidden = !hasMedia }
    @objc private func likeTap() { onLike?() }; @objc private func commentTap() { onComment?() }; @objc private func moreTap() { onMore?() }
}

enum CommunityMomentComposerMode { case mixedMedia, videoOnly }

final class CommunityMomentComposerViewController: LMViewController, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate {
    private let mode: CommunityMomentComposerMode
    private let textView = UITextView()
    private let captionPlaceholder = UILabel.lm("Add a short caption that gives this moment context…", size: 14, weight: .medium, color: LMTheme.muted)
    private let preview = UIImageView()
    private let previewShade = LMGradientView(colors: [.clear, LMTheme.background.withAlphaComponent(0.78)], horizontal: false)
    private let emptyPreviewIcon = UIImageView(image: UIImage(systemName: "play.rectangle.on.rectangle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 31, weight: .semibold)))
    private let emptyPreviewTitle = UILabel.lm("Your video preview", size: 17, weight: .bold)
    private let emptyPreviewNote = UILabel.lm("Choose a clip or capture a new scene", size: 11, weight: .medium, color: .white.withAlphaComponent(0.70))
    private let mediaLabel = UILabel.lm("  Video needed  ", size: 10, weight: .bold, color: .white)
    private var mediaPath: String?
    private var mediaType: String?

    init(mode: CommunityMomentComposerMode = .mixedMedia) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = mode == .videoOnly ? "Post a video" : "New moment"
        navigationItem.rightBarButtonItem = nil

        let backdrop = UIImageView(image: UIImage(named: "presence-constellation-field.png"))
        backdrop.contentMode = .scaleAspectFill
        backdrop.alpha = 0.14
        view.addSubview(backdrop)
        backdrop.pin(to: view)

        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .interactive
        scroll.alwaysBounceVertical = true
        let content = UIView()
        [scroll, content].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        view.addSubview(scroll)
        scroll.addSubview(content)

        let eyebrow = UILabel.lm(mode == .videoOnly ? "VIDEO MOMENT" : "NEW MOMENT", size: 10, weight: .heavy, color: LMTheme.pinkSoft)
        eyebrow.textAlignment = .center
        eyebrow.backgroundColor = LMTheme.pink.withAlphaComponent(0.12)
        eyebrow.layer.borderWidth = 0.7
        eyebrow.layer.borderColor = LMTheme.pink.withAlphaComponent(0.36).cgColor
        eyebrow.round(12)

        let heading = UILabel.lm(mode == .videoOnly ? "Share one clear moment." : "Share something real.", size: 28, weight: .bold)
        heading.font = LMTheme.displayFont(size: 28, weight: .bold)
        heading.numberOfLines = 2
        let intro = UILabel.lm(mode == .videoOnly ? "A short scene, a little context, and your point of view." : "Choose a photo or video and add the thought behind it.", size: 13, weight: .medium, color: .white.withAlphaComponent(0.70))
        intro.numberOfLines = 0

        let reviewCard = UIView()
        reviewCard.backgroundColor = LMTheme.panel.withAlphaComponent(0.92)
        reviewCard.layer.borderWidth = 0.7
        reviewCard.layer.borderColor = LMTheme.violet.withAlphaComponent(0.38).cgColor
        reviewCard.round(17)
        let reviewIcon = UIImageView(image: UIImage(systemName: "checkmark.shield.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .semibold)))
        reviewIcon.tintColor = LMTheme.pinkSoft
        reviewIcon.backgroundColor = LMTheme.violet.withAlphaComponent(0.24)
        reviewIcon.contentMode = .center
        reviewIcon.round(18)
        let reviewTitle = UILabel.lm("Reviewed before it appears", size: 13, weight: .bold)
        let reviewNote = UILabel.lm("Your post stays private while moderation is pending.", size: 10, weight: .medium, color: LMTheme.muted)

        let captionCard = UIView()
        captionCard.backgroundColor = LMTheme.panel.withAlphaComponent(0.94)
        captionCard.layer.borderWidth = 0.7
        captionCard.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        captionCard.round(20)
        let captionTitle = UILabel.lm("CAPTION", size: 10, weight: .heavy, color: LMTheme.pinkSoft)
        let captionHint = UILabel.lm("OPTIONAL", size: 9, weight: .bold, color: LMTheme.muted)
        textView.accessibilityIdentifier = "moment.caption"
        textView.delegate = self
        textView.backgroundColor = LMTheme.panel2.withAlphaComponent(0.68)
        textView.textColor = .white
        textView.tintColor = LMTheme.pinkSoft
        textView.font = LMTheme.font(size: 15, weight: .medium)
        textView.round(15)
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 11, bottom: 14, right: 11)
        captionPlaceholder.numberOfLines = 2
        captionPlaceholder.isUserInteractionEnabled = false

        let mediaTitle = UILabel.lm(mode == .videoOnly ? "VIDEO" : "MEDIA", size: 10, weight: .heavy, color: LMTheme.pinkSoft)
        mediaLabel.text = mode == .videoOnly ? "  Video needed  " : "  Media needed  "
        mediaLabel.textAlignment = .center
        mediaLabel.backgroundColor = UIColor.black.withAlphaComponent(0.42)
        mediaLabel.round(12)
        preview.image = UIImage(named: "presence-constellation-field.png")
        preview.backgroundColor = LMTheme.panel
        preview.contentMode = .scaleAspectFill
        preview.clipsToBounds = true
        preview.round(22)
        preview.layer.borderWidth = 0.8
        preview.layer.borderColor = LMTheme.violet.withAlphaComponent(0.42).cgColor
        emptyPreviewIcon.tintColor = LMTheme.pinkSoft
        emptyPreviewIcon.backgroundColor = LMTheme.violet.withAlphaComponent(0.36)
        emptyPreviewIcon.contentMode = .center
        emptyPreviewIcon.round(29)
        emptyPreviewTitle.textAlignment = .center
        emptyPreviewNote.textAlignment = .center

        let sources = UIStackView()
        sources.axis = .horizontal
        sources.spacing = 10
        sources.distribution = .fillEqually
        let sourceChoices: [(String, String, String, Int)] = mode == .videoOnly
            ? [("Choose video", "From Photos", "photo.on.rectangle.angled", 1), ("Record video", "Use camera", "video.badge.plus", 3)]
            : [("Photo", "Photos", "photo", 0), ("Video", "Photos", "video.fill", 1), ("Camera", "Take photo", "camera.fill", 2), ("Record", "New clip", "record.circle", 3)]
        sourceChoices.forEach { label, detail, symbol, tag in
            let button = ComposerMediaSourceButton(title: label, detail: detail, symbol: symbol)
            button.accessibilityIdentifier = tag == 1 ? "moment.chooseVideo" : (tag == 3 ? "moment.recordVideo" : "moment.source.\(tag)")
            button.tag = tag
            button.addTarget(self, action: #selector(sourceTap(_:)), for: .touchUpInside)
            sources.addArrangedSubview(button)
        }

        let submitButton = UIButton.lm("Send for review", symbol: "arrow.up.circle.fill")
        submitButton.accessibilityIdentifier = "moment.submit"
        submitButton.backgroundColor = LMTheme.pink
        submitButton.round(23)
        submitButton.layer.shadowColor = LMTheme.pink.cgColor
        submitButton.layer.shadowOpacity = 0.28
        submitButton.layer.shadowRadius = 13
        submitButton.layer.shadowOffset = CGSize(width: 0, height: 7)
        submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)
        let footer = UILabel.lm("Only approved posts become visible to the community.", size: 10, weight: .medium, color: LMTheme.muted)
        footer.textAlignment = .center

        [eyebrow, heading, intro, reviewCard, captionCard, mediaTitle, preview, sources, submitButton, footer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview($0)
        }
        [reviewIcon, reviewTitle, reviewNote].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; reviewCard.addSubview($0) }
        [captionTitle, captionHint, textView, captionPlaceholder].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; captionCard.addSubview($0) }
        captionPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        [previewShade, emptyPreviewIcon, emptyPreviewTitle, emptyPreviewNote, mediaLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; preview.addSubview($0) }

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor), scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor), scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor), scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor), content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor), content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor), content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor), content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),

            eyebrow.topAnchor.constraint(equalTo: content.topAnchor, constant: 20), eyebrow.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 18), eyebrow.widthAnchor.constraint(equalToConstant: 112), eyebrow.heightAnchor.constraint(equalToConstant: 25),
            heading.topAnchor.constraint(equalTo: eyebrow.bottomAnchor, constant: 13), heading.leadingAnchor.constraint(equalTo: eyebrow.leadingAnchor), heading.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -18),
            intro.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 7), intro.leadingAnchor.constraint(equalTo: heading.leadingAnchor), intro.trailingAnchor.constraint(equalTo: heading.trailingAnchor),

            reviewCard.topAnchor.constraint(equalTo: intro.bottomAnchor, constant: 16), reviewCard.leadingAnchor.constraint(equalTo: heading.leadingAnchor), reviewCard.trailingAnchor.constraint(equalTo: heading.trailingAnchor), reviewCard.heightAnchor.constraint(equalToConstant: 62),
            reviewIcon.leadingAnchor.constraint(equalTo: reviewCard.leadingAnchor, constant: 13), reviewIcon.centerYAnchor.constraint(equalTo: reviewCard.centerYAnchor), reviewIcon.widthAnchor.constraint(equalToConstant: 36), reviewIcon.heightAnchor.constraint(equalTo: reviewIcon.widthAnchor),
            reviewTitle.leadingAnchor.constraint(equalTo: reviewIcon.trailingAnchor, constant: 11), reviewTitle.topAnchor.constraint(equalTo: reviewCard.topAnchor, constant: 13), reviewTitle.trailingAnchor.constraint(equalTo: reviewCard.trailingAnchor, constant: -12),
            reviewNote.leadingAnchor.constraint(equalTo: reviewTitle.leadingAnchor), reviewNote.topAnchor.constraint(equalTo: reviewTitle.bottomAnchor, constant: 3), reviewNote.trailingAnchor.constraint(equalTo: reviewTitle.trailingAnchor),

            captionCard.topAnchor.constraint(equalTo: reviewCard.bottomAnchor, constant: 14), captionCard.leadingAnchor.constraint(equalTo: heading.leadingAnchor), captionCard.trailingAnchor.constraint(equalTo: heading.trailingAnchor),
            captionTitle.topAnchor.constraint(equalTo: captionCard.topAnchor, constant: 15), captionTitle.leadingAnchor.constraint(equalTo: captionCard.leadingAnchor, constant: 15),
            captionHint.centerYAnchor.constraint(equalTo: captionTitle.centerYAnchor), captionHint.trailingAnchor.constraint(equalTo: captionCard.trailingAnchor, constant: -15),
            textView.topAnchor.constraint(equalTo: captionTitle.bottomAnchor, constant: 10), textView.leadingAnchor.constraint(equalTo: captionTitle.leadingAnchor), textView.trailingAnchor.constraint(equalTo: captionHint.trailingAnchor), textView.heightAnchor.constraint(equalToConstant: 104), textView.bottomAnchor.constraint(equalTo: captionCard.bottomAnchor, constant: -14),
            captionPlaceholder.topAnchor.constraint(equalTo: textView.topAnchor, constant: 15), captionPlaceholder.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 16), captionPlaceholder.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -16),

            mediaTitle.topAnchor.constraint(equalTo: captionCard.bottomAnchor, constant: 20), mediaTitle.leadingAnchor.constraint(equalTo: heading.leadingAnchor),
            preview.topAnchor.constraint(equalTo: mediaTitle.bottomAnchor, constant: 10), preview.leadingAnchor.constraint(equalTo: heading.leadingAnchor), preview.trailingAnchor.constraint(equalTo: heading.trailingAnchor), preview.heightAnchor.constraint(equalTo: preview.widthAnchor, multiplier: 0.60),
            previewShade.topAnchor.constraint(equalTo: preview.topAnchor), previewShade.leadingAnchor.constraint(equalTo: preview.leadingAnchor), previewShade.trailingAnchor.constraint(equalTo: preview.trailingAnchor), previewShade.bottomAnchor.constraint(equalTo: preview.bottomAnchor),
            emptyPreviewIcon.centerXAnchor.constraint(equalTo: preview.centerXAnchor), emptyPreviewIcon.centerYAnchor.constraint(equalTo: preview.centerYAnchor, constant: -22), emptyPreviewIcon.widthAnchor.constraint(equalToConstant: 58), emptyPreviewIcon.heightAnchor.constraint(equalTo: emptyPreviewIcon.widthAnchor),
            emptyPreviewTitle.topAnchor.constraint(equalTo: emptyPreviewIcon.bottomAnchor, constant: 10), emptyPreviewTitle.centerXAnchor.constraint(equalTo: preview.centerXAnchor),
            emptyPreviewNote.topAnchor.constraint(equalTo: emptyPreviewTitle.bottomAnchor, constant: 4), emptyPreviewNote.centerXAnchor.constraint(equalTo: preview.centerXAnchor),
            mediaLabel.leadingAnchor.constraint(equalTo: preview.leadingAnchor, constant: 13), mediaLabel.bottomAnchor.constraint(equalTo: preview.bottomAnchor, constant: -13), mediaLabel.heightAnchor.constraint(equalToConstant: 24),

            sources.topAnchor.constraint(equalTo: preview.bottomAnchor, constant: 12), sources.leadingAnchor.constraint(equalTo: preview.leadingAnchor), sources.trailingAnchor.constraint(equalTo: preview.trailingAnchor), sources.heightAnchor.constraint(equalToConstant: 78),
            submitButton.topAnchor.constraint(equalTo: sources.bottomAnchor, constant: 22), submitButton.leadingAnchor.constraint(equalTo: preview.leadingAnchor), submitButton.trailingAnchor.constraint(equalTo: preview.trailingAnchor), submitButton.heightAnchor.constraint(equalToConstant: 54),
            footer.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: 10), footer.leadingAnchor.constraint(equalTo: submitButton.leadingAnchor), footer.trailingAnchor.constraint(equalTo: submitButton.trailingAnchor), footer.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -32)
        ])
    }

    func textViewDidChange(_ textView: UITextView) { captionPlaceholder.isHidden = !textView.text.isEmpty }
    @objc private func sourceTap(_ sender: UIButton) { switch sender.tag { case 0: openLibrary(videoOnly: false); case 1: openLibrary(videoOnly: true); case 2: openCamera(video: false); default: openCamera(video: true) } }
    private func openLibrary(videoOnly: Bool) { var config = PHPickerConfiguration(photoLibrary: .shared()); config.selectionLimit = 1; config.filter = videoOnly ? .videos : .images; let picker = PHPickerViewController(configuration: config); picker.delegate = self; present(picker, animated: true) }
    private func openCamera(video: Bool) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { present(LMNoticeViewController(style: .warning, title: "Camera unavailable", message: "Camera capture is not available on this device."), animated: true); return }
        CallPermissionManager.requestCameraCapture(videoIncludesAudio: video, from: self) { [weak self] in
            guard let self else { return }
            let picker = UIImagePickerController(); picker.sourceType = .camera; picker.mediaTypes = video ? [UTType.movie.identifier] : [UTType.image.identifier]; picker.cameraCaptureMode = video ? .video : .photo; picker.delegate = self; self.present(picker, animated: true)
        }
    }
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        let provider = result.itemProvider
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, _ in
                guard let self, let url, let path = self.copyMedia(from: url, fileExtension: "mov") else { return }
                DispatchQueue.main.async { self.applyVideo(at: path) }
            }
        } else {
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                guard let self, let image = object as? UIImage, let path = self.saveImage(image) else { return }
                DispatchQueue.main.async { self.mediaPath = path; self.applyMediaPreview(image, type: "image") }
            }
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let url = info[.mediaURL] as? URL, let path = copyMedia(from: url, fileExtension: "mov") {
            applyVideo(at: path)
        } else if let image = info[.originalImage] as? UIImage, let path = saveImage(image) {
            mediaPath = path
            applyMediaPreview(image, type: "image")
        }
    }
    private func applyVideo(at path: String) {
        mediaPath = path
        mediaType = "video"
        mediaLabel.text = "  Video ready  "
        let asset = AVURLAsset(url: URL(fileURLWithPath: path))
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 900, height: 900)
            let image = try? generator.copyCGImage(at: CMTime(seconds: 0.18, preferredTimescale: 600), actualTime: nil)
            DispatchQueue.main.async {
                guard let self else { return }
                self.applyMediaPreview(image.map(UIImage.init(cgImage:)) ?? UIImage(named: "presence-constellation-field.png"), type: "video")
            }
        }
    }
    private func applyMediaPreview(_ image: UIImage?, type: String) {
        mediaType = type
        preview.image = image
        previewShade.alpha = 0.34
        [emptyPreviewIcon, emptyPreviewTitle, emptyPreviewNote].forEach { $0.isHidden = true }
        mediaLabel.text = type == "video" ? "  Video ready  " : "  Photo ready  "
        mediaLabel.backgroundColor = LMTheme.pink.withAlphaComponent(0.88)
    }
    private func mediaDirectory() -> URL? { guard let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }; let dir = root.appendingPathComponent("UserMoments", isDirectory: true); try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true); return dir }
    private func saveImage(_ image: UIImage) -> String? { guard let data = image.jpegData(compressionQuality: 0.86), let url = mediaDirectory()?.appendingPathComponent("\(UUID().uuidString).jpg") else { return nil }; do { try data.write(to: url, options: .atomic); return url.path } catch { return nil } }
    private func copyMedia(from source: URL, fileExtension: String) -> String? { guard let destination = mediaDirectory()?.appendingPathComponent("\(UUID().uuidString).\(fileExtension)") else { return nil }; do { try FileManager.default.copyItem(at: source, to: destination); return destination.path } catch { return nil } }
    @objc private func submit() { let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines); if mode == .videoOnly && mediaType != "video" { present(LMNoticeViewController(style: .warning, title: "Add a video first", message: "Choose a video from Photos or record a new one before submitting."), animated: true); return }; guard !text.isEmpty || mediaPath != nil else { present(LMNoticeViewController(style: .warning, title: "Add something first", message: "Write a thought or choose a photo or video to share."), animated: true); return }; let decision = LookMeContentPolicy.evaluate(text, allowsEmpty: mediaPath != nil); guard decision.isAllowed else { present(LMNoticeViewController(style: .warning, title: "Please revise this moment", message: decision.rejectionReason?.userMessage ?? "This moment needs a safer, clearer description."), animated: true); return }; LookMeExperienceStore.shared.submitMoment(text: text, mediaPath: mediaPath, mediaType: mediaType); let notice = LMNoticeViewController(style: .review, title: "Sent for review", message: "Your moment is saved under Pending submissions and stays hidden until moderation approves it."); notice.onDone = { [weak self] in self?.navigationController?.popViewController(animated: true) }; present(notice, animated: true) }
}

private final class ComposerMediaSourceButton: UIButton {
    init(title: String, detail: String, symbol: String) {
        super.init(frame: .zero)
        backgroundColor = LMTheme.panel.withAlphaComponent(0.96)
        layer.borderWidth = 0.8
        layer.borderColor = LMTheme.violet.withAlphaComponent(0.38).cgColor
        round(16)

        let iconHolder = UIView()
        iconHolder.isUserInteractionEnabled = false
        iconHolder.backgroundColor = LMTheme.violet.withAlphaComponent(0.30)
        iconHolder.round(17)
        let icon = UIImageView(image: UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)))
        icon.tintColor = LMTheme.pinkSoft
        icon.contentMode = .center
        let heading = UILabel.lm(title, size: 11, weight: .bold)
        heading.textAlignment = .center
        heading.adjustsFontSizeToFitWidth = true
        heading.minimumScaleFactor = 0.78
        let note = UILabel.lm(detail, size: 8, weight: .medium, color: LMTheme.muted)
        note.textAlignment = .center
        note.adjustsFontSizeToFitWidth = true
        note.minimumScaleFactor = 0.75
        [iconHolder, icon, heading, note].forEach { $0.isUserInteractionEnabled = false; $0.translatesAutoresizingMaskIntoConstraints = false }
        addSubview(iconHolder)
        iconHolder.addSubview(icon)
        addSubview(heading)
        addSubview(note)
        NSLayoutConstraint.activate([
            iconHolder.topAnchor.constraint(equalTo: topAnchor, constant: 9), iconHolder.centerXAnchor.constraint(equalTo: centerXAnchor), iconHolder.widthAnchor.constraint(equalToConstant: 34), iconHolder.heightAnchor.constraint(equalTo: iconHolder.widthAnchor),
            icon.centerXAnchor.constraint(equalTo: iconHolder.centerXAnchor), icon.centerYAnchor.constraint(equalTo: iconHolder.centerYAnchor),
            heading.topAnchor.constraint(equalTo: iconHolder.bottomAnchor, constant: 5), heading.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4), heading.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            note.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 1), note.leadingAnchor.constraint(equalTo: heading.leadingAnchor), note.trailingAnchor.constraint(equalTo: heading.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.72 : 1
            transform = isHighlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
        }
    }
}
