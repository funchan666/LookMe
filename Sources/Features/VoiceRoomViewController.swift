import UIKit
import AVFoundation

private enum VoiceRoomTimelineItem {
    case ambient(VoiceRoomBulletin)
    case persisted(RoomConversationEntry)
}

final class VoiceRoomViewController: LMViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    private let room: InterestRoomBlueprint
    private let editorialBulletins: [VoiceRoomBulletin]
    private let audio = VoiceRoomAudioSessionController()
    private let seats = UIStackView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyState = UILabel.lm("No room messages yet\nStart the conversation when you feel ready.", size: 12, weight: .medium, color: LMTheme.muted)
    private let field = UITextField()
    private let micControl = VoiceRoomControlButton(symbol: "hand.raised.fill", title: "Take seat")
    private let speakerControl = VoiceRoomControlButton(symbol: "speaker.wave.2.fill", title: "Speaker")
    private var isOnStage = false
    private var isMuted = false
    private var speakerOn = true
    private var storeObserver: NSObjectProtocol?
    private var ambienceTimer: Timer?
    private var revealedAmbientCount = 2

    private var messages: [RoomConversationEntry] { LookMeExperienceStore.shared.voiceMessages(for: room.id) }
    private var timeline: [VoiceRoomTimelineItem] {
        let ambient = editorialBulletins.prefix(revealedAmbientCount).filter { !LookMeExperienceStore.shared.blockedUsers.contains($0.authorProfileKey) }.map(VoiceRoomTimelineItem.ambient)
        return ambient + messages.map(VoiceRoomTimelineItem.persisted)
    }
    private var members: [CommunityProfile] { room.participants }

    init(room: InterestRoomBlueprint) {
        self.room = room
        self.editorialBulletins = CommunityMediaRegistry.voiceEditorial(for: room)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }
    deinit { ambienceTimer?.invalidate(); if let storeObserver { NotificationCenter.default.removeObserver(storeObserver) } }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildBackground()
        let header = buildHeader()
        let hero = buildHero(below: header)
        let seatTitle = buildSeats(below: hero)
        let composer = buildComposer()
        let dock = buildDock(above: composer)
        buildMessages(below: seatTitle, above: dock)
        audio.activate(speaker: true)
        storeObserver = NotificationCenter.default.addObserver(forName: .lookMeStoreChanged, object: nil, queue: .main) { [weak self] _ in
            self?.refreshAfterStoreChange()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startRoomAmbience()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ambienceTimer?.invalidate()
        ambienceTimer = nil
        if isMovingFromParent { audio.deactivate() }
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func buildBackground() {
        let artwork = UIImageView(image: UIImage(named: room.image))
        artwork.contentMode = .scaleAspectFill
        artwork.alpha = 0.28
        view.addSubview(artwork)
        artwork.pin(to: view)
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        view.addSubview(blur)
        blur.pin(to: view)
        let tint = UIView()
        tint.backgroundColor = LMTheme.background.withAlphaComponent(0.72)
        view.addSubview(tint)
        tint.pin(to: view)
    }

    private func buildHeader() -> UIView {
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)
        let back = roundButton("chevron.left", selector: #selector(askToLeave))
        back.accessibilityLabel = "Leave voice room"
        let more = roundButton("ellipsis", selector: #selector(roomSafety))
        more.accessibilityLabel = "Room safety options"
        let title = UILabel.lm(room.title, size: 18, weight: .bold)
        title.textAlignment = .center
        let subtitle = UILabel.lm("VOICE ROOM · \(room.tag.uppercased())", size: 9, weight: .heavy, color: LMTheme.pinkSoft)
        subtitle.textAlignment = .center
        [title, subtitle].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; header.addSubview($0) }
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            header.heightAnchor.constraint(equalToConstant: 48),
            back.leadingAnchor.constraint(equalTo: header.leadingAnchor), back.centerYAnchor.constraint(equalTo: header.centerYAnchor), back.widthAnchor.constraint(equalToConstant: 40), back.heightAnchor.constraint(equalTo: back.widthAnchor),
            more.trailingAnchor.constraint(equalTo: header.trailingAnchor), more.centerYAnchor.constraint(equalTo: header.centerYAnchor), more.widthAnchor.constraint(equalToConstant: 40), more.heightAnchor.constraint(equalTo: more.widthAnchor),
            title.centerXAnchor.constraint(equalTo: header.centerXAnchor), title.topAnchor.constraint(equalTo: header.topAnchor, constant: 4), title.leadingAnchor.constraint(greaterThanOrEqualTo: back.trailingAnchor, constant: 8), title.trailingAnchor.constraint(lessThanOrEqualTo: more.leadingAnchor, constant: -8),
            subtitle.centerXAnchor.constraint(equalTo: title.centerXAnchor), subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 1)
        ])
        return header
    }

    private func buildHero(below header: UIView) -> UIView {
        let card = UIView()
        card.backgroundColor = LMTheme.panel.withAlphaComponent(0.78)
        card.round(22)
        card.layer.borderWidth = 0.8
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)
        let art = UIImageView(image: UIImage(named: room.image))
        art.contentMode = .scaleAspectFill
        art.round(22)
        art.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(art)
        let shade = UIView()
        shade.isUserInteractionEnabled = false
        shade.translatesAutoresizingMaskIntoConstraints = false
        art.addSubview(shade)
        let host = room.host
        let avatar = UIImageView(image: UIImage(named: host.image))
        avatar.contentMode = .scaleAspectFill
        avatar.round(25)
        avatar.layer.borderWidth = 2
        avatar.layer.borderColor = LMTheme.pinkSoft.cgColor
        avatar.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(avatar)
        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openHost)))
        let live = UILabel.lm("  ● LIVE VOICE  ", size: 9, weight: .heavy)
        live.backgroundColor = LMTheme.pink
        live.round(10)
        let name = UILabel.lm("Hosted by \(host.name)", size: 14, weight: .bold)
        let topic = UILabel.lm(room.subtitle, size: 11, weight: .medium, color: .white.withAlphaComponent(0.76))
        let count = UILabel.lm("  \(room.online) listening  ", size: 10, weight: .bold)
        count.backgroundColor = UIColor.black.withAlphaComponent(0.34)
        count.round(11)
        [live, name, topic, count].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; card.addSubview($0) }
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 10), card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14), card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14), card.heightAnchor.constraint(equalToConstant: 116),
            art.topAnchor.constraint(equalTo: card.topAnchor), art.leadingAnchor.constraint(equalTo: card.leadingAnchor), art.trailingAnchor.constraint(equalTo: card.trailingAnchor), art.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            shade.topAnchor.constraint(equalTo: art.topAnchor), shade.leadingAnchor.constraint(equalTo: art.leadingAnchor), shade.trailingAnchor.constraint(equalTo: art.trailingAnchor), shade.bottomAnchor.constraint(equalTo: art.bottomAnchor),
            avatar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14), avatar.centerYAnchor.constraint(equalTo: card.centerYAnchor), avatar.widthAnchor.constraint(equalToConstant: 50), avatar.heightAnchor.constraint(equalTo: avatar.widthAnchor),
            live.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 11), live.topAnchor.constraint(equalTo: card.topAnchor, constant: 19), live.heightAnchor.constraint(equalToConstant: 20),
            name.leadingAnchor.constraint(equalTo: live.leadingAnchor), name.topAnchor.constraint(equalTo: live.bottomAnchor, constant: 7),
            topic.leadingAnchor.constraint(equalTo: name.leadingAnchor), topic.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 3), topic.trailingAnchor.constraint(lessThanOrEqualTo: count.leadingAnchor, constant: -8),
            count.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12), count.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12), count.heightAnchor.constraint(equalToConstant: 23)
        ])
        DispatchQueue.main.async { LMTheme.gradient(shade, colors: [UIColor.black.withAlphaComponent(0.18), LMTheme.panel.withAlphaComponent(0.92)], horizontal: true) }
        return card
    }

    private func buildSeats(below hero: UIView) -> UILabel {
        let title = UILabel.lm("ON STAGE", size: 10, weight: .heavy, color: LMTheme.muted)
        title.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(title)
        seats.axis = .vertical
        seats.distribution = .fillEqually
        seats.spacing = 8
        seats.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(seats)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: hero.bottomAnchor, constant: 14), title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 17),
            seats.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 7), seats.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10), seats.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10), seats.heightAnchor.constraint(equalToConstant: 174)
        ])
        refreshSeats()
        return title
    }

    private func refreshSeats() {
        seats.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for rowIndex in 0..<2 {
            let row = UIStackView()
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 4
            for column in 0..<4 {
                let index = rowIndex * 4 + column
                let member = members.indices.contains(index) ? members[index] : nil
                let isMe = index == 7 && isOnStage
                let seat = VoiceRoomSeatView()
                seat.configure(member: member, isHost: index == 0 && member != nil, isMe: isMe, isMuted: isMe && isMuted, open: index == 7 && !isOnStage)
                seat.onTap = { [weak self] in self?.seatTapped(index: index, member: member) }
                seat.onMore = { [weak self] in guard let self, let member else { return }; self.memberSafety(member) }
                row.addArrangedSubview(seat)
            }
            seats.addArrangedSubview(row)
        }
    }

    private func buildMessages(below seatTitle: UIView, above dock: UIView) {
        let panel = UIView()
        panel.backgroundColor = UIColor.black.withAlphaComponent(0.20)
        panel.round(18)
        panel.layer.borderWidth = 0.7
        panel.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        panel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panel)
        let title = UILabel.lm("ROOM CHAT", size: 10, weight: .heavy, color: LMTheme.muted)
        let privacy = UILabel.lm("Kind words only", size: 9, weight: .medium, color: LMTheme.muted)
        [title, privacy].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; panel.addSubview($0) }
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.keyboardDismissMode = .interactive
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(VoiceRoomMessageCell.self, forCellReuseIdentifier: "voiceMessage")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(tableView)
        emptyState.numberOfLines = 0
        emptyState.textAlignment = .center
        emptyState.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(emptyState)
        NSLayoutConstraint.activate([
            panel.topAnchor.constraint(equalTo: seats.bottomAnchor, constant: 11), panel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12), panel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12), panel.bottomAnchor.constraint(equalTo: dock.topAnchor, constant: -9),
            title.topAnchor.constraint(equalTo: panel.topAnchor, constant: 12), title.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 13),
            privacy.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -13), privacy.centerYAnchor.constraint(equalTo: title.centerYAnchor),
            tableView.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 5), tableView.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 6), tableView.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -6), tableView.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -5),
            emptyState.centerXAnchor.constraint(equalTo: panel.centerXAnchor), emptyState.centerYAnchor.constraint(equalTo: panel.centerYAnchor, constant: 8), emptyState.leadingAnchor.constraint(greaterThanOrEqualTo: panel.leadingAnchor, constant: 18), emptyState.trailingAnchor.constraint(lessThanOrEqualTo: panel.trailingAnchor, constant: -18)
        ])
        refreshMessages(scroll: true)
    }

    private func buildDock(above composer: UIView) -> UIView {
        let dock = UIView()
        dock.backgroundColor = LMTheme.panel.withAlphaComponent(0.92)
        dock.round(23)
        dock.layer.borderWidth = 0.8
        dock.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
        dock.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dock)
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        dock.addSubview(stack)
        micControl.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
        let membersControl = VoiceRoomControlButton(symbol: "person.2.fill", title: "Members")
        membersControl.addTarget(self, action: #selector(showMembers), for: .touchUpInside)
        let giftControl = VoiceRoomControlButton(symbol: "gift.fill", title: "Gift")
        giftControl.addTarget(self, action: #selector(openVoiceGifts), for: .touchUpInside)
        speakerControl.addTarget(self, action: #selector(speakerTapped), for: .touchUpInside)
        let leave = VoiceRoomControlButton(symbol: "rectangle.portrait.and.arrow.right.fill", title: "Leave", destructive: true)
        leave.addTarget(self, action: #selector(askToLeave), for: .touchUpInside)
        [micControl, membersControl, giftControl, speakerControl, leave].forEach(stack.addArrangedSubview)
        NSLayoutConstraint.activate([
            dock.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12), dock.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12), dock.bottomAnchor.constraint(equalTo: composer.topAnchor, constant: -8), dock.heightAnchor.constraint(equalToConstant: 61),
            stack.topAnchor.constraint(equalTo: dock.topAnchor, constant: 4), stack.leadingAnchor.constraint(equalTo: dock.leadingAnchor, constant: 5), stack.trailingAnchor.constraint(equalTo: dock.trailingAnchor, constant: -5), stack.bottomAnchor.constraint(equalTo: dock.bottomAnchor, constant: -3)
        ])
        return dock
    }

    private func buildComposer() -> UIView {
        let composer = UIView()
        composer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(composer)
        field.delegate = self
        field.returnKeyType = .send
        field.attributedPlaceholder = NSAttributedString(string: "Say something to the room…", attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.45)])
        field.textColor = .white
        field.font = LMTheme.font(size: 13, weight: .medium)
        field.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        field.layer.borderWidth = 0.7
        field.layer.borderColor = UIColor.white.withAlphaComponent(0.13).cgColor
        field.layer.cornerRadius = 21
        field.setLeftPadding(15)
        field.translatesAutoresizingMaskIntoConstraints = false
        composer.addSubview(field)
        let send = UIButton(type: .system)
        send.setImage(UIImage(systemName: "paperplane.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)), for: .normal)
        send.tintColor = .white
        send.backgroundColor = LMTheme.pink
        send.round(21)
        send.accessibilityLabel = "Send room message"
        send.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        send.translatesAutoresizingMaskIntoConstraints = false
        composer.addSubview(send)
        NSLayoutConstraint.activate([
            composer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12), composer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12), composer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -7), composer.heightAnchor.constraint(equalToConstant: 43),
            field.leadingAnchor.constraint(equalTo: composer.leadingAnchor), field.topAnchor.constraint(equalTo: composer.topAnchor), field.bottomAnchor.constraint(equalTo: composer.bottomAnchor),
            send.leadingAnchor.constraint(equalTo: field.trailingAnchor, constant: 8), send.trailingAnchor.constraint(equalTo: composer.trailingAnchor), send.topAnchor.constraint(equalTo: composer.topAnchor), send.bottomAnchor.constraint(equalTo: composer.bottomAnchor), send.widthAnchor.constraint(equalTo: send.heightAnchor)
        ])
        return composer
    }

    private func roundButton(_ symbol: String, selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .bold)), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.09)
        button.round(20)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: selector, for: .touchUpInside)
        view.addSubview(button)
        return button
    }

    private func seatTapped(index: Int, member: CommunityProfile?) {
        if let member {
            navigationController?.pushViewController(CommunityProfileDetailViewController(member: member), animated: true)
        } else if index == 7 && !isOnStage {
            takeSeat()
        }
    }

    private func takeSeat() {
        isOnStage = true
        isMuted = false
        audio.setMicrophoneEnabled(true)
        micControl.update(symbol: "mic.fill", title: "Mute", active: true)
        refreshSeats()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        present(LMNoticeViewController(style: .success, title: "You're on stage", message: "Your microphone is live. You can mute it at any time from the room controls."), animated: true)
    }

    @objc private func micTapped() {
        guard isOnStage else { takeSeat(); return }
        isMuted.toggle()
        audio.setMicrophoneEnabled(!isMuted)
        micControl.update(symbol: isMuted ? "mic.slash.fill" : "mic.fill", title: isMuted ? "Unmute" : "Mute", active: !isMuted)
        refreshSeats()
        UISelectionFeedbackGenerator().selectionChanged()
    }

    @objc private func speakerTapped() {
        speakerOn.toggle()
        audio.setSpeakerEnabled(speakerOn)
        speakerControl.update(symbol: speakerOn ? "speaker.wave.2.fill" : "speaker.fill", title: speakerOn ? "Speaker" : "Earpiece", active: speakerOn)
        UISelectionFeedbackGenerator().selectionChanged()
    }

    @objc private func showMembers() {
        let controller = VoiceRoomMembersViewController(room: room, isOnStage: isOnStage)
        controller.onSelect = { [weak self, weak controller] member in
            controller?.dismiss(animated: true) { self?.navigationController?.pushViewController(CommunityProfileDetailViewController(member: member), animated: true) }
        }
        controller.onSafety = { [weak self, weak controller] member in
            guard let self, let controller else { return }
            SafetyCoordinator.present(from: controller, target: .init(id: "voice-member:\(self.room.id):\(member.id)", type: "voice room member", userID: member.id, displayName: member.name))
        }
        present(controller, animated: true)
    }

    @objc private func openVoiceGifts() {
        let sheet = LiveGiftSheetViewController(host: room.host.name)
        sheet.onSent = { [weak self] gift in
            guard let self else { return }
            LookMeExperienceStore.shared.sendVoiceRoomMessage("sent \(gift) to the room", roomID: self.room.id)
        }
        present(sheet, animated: true)
    }

    @objc private func openHost() { navigationController?.pushViewController(CommunityProfileDetailViewController(member: room.host), animated: true) }
    @objc private func roomSafety() { SafetyCoordinator.present(from: self, target: .init(id: "voice-room:\(room.id)", type: "voice room", userID: room.host.id, displayName: room.title)) }
    private func memberSafety(_ member: CommunityProfile) { SafetyCoordinator.present(from: self, target: .init(id: "voice-member:\(room.id):\(member.id)", type: "voice room member", userID: member.id, displayName: member.name)) }

    @objc private func askToLeave() {
        let sheet = VoiceRoomLeaveViewController(roomName: room.title, isOnStage: isOnStage)
        sheet.onLeave = { [weak self] in self?.leaveRoom() }
        present(sheet, animated: true)
    }

    private func leaveRoom() {
        audio.deactivate()
        isOnStage = false
        navigationController?.popViewController(animated: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool { sendMessage(); return true }

    @objc private func sendMessage() {
        let text = field.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return }
        guard LookMeContentPolicy.allows(text) else {
            present(LMNoticeViewController(style: .warning, title: "Message not sent", message: "Please revise content that may be unsafe, explicit, threatening or spam-like."), animated: true)
            return
        }
        LookMeExperienceStore.shared.sendVoiceRoomMessage(text, roomID: room.id)
        field.text = ""
        field.resignFirstResponder()
    }

    private func refreshMessages(scroll: Bool) {
        tableView.reloadData()
        emptyState.isHidden = !timeline.isEmpty
        if scroll, !timeline.isEmpty { tableView.scrollToRow(at: IndexPath(row: timeline.count - 1, section: 0), at: .bottom, animated: true) }
    }

    private func startRoomAmbience() {
        guard ambienceTimer == nil, revealedAmbientCount < editorialBulletins.count else { return }
        ambienceTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            self.revealedAmbientCount = min(self.revealedAmbientCount + 1, self.editorialBulletins.count)
            self.refreshMessages(scroll: true)
            if self.revealedAmbientCount >= self.editorialBulletins.count {
                timer.invalidate()
                self.ambienceTimer = nil
            }
        }
    }

    private func refreshAfterStoreChange() {
        if LookMeExperienceStore.shared.blockedUsers.contains(room.host.id) {
            audio.deactivate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self else { return }
                if let notice = self.presentedViewController as? LMNoticeViewController {
                    notice.onDone = { [weak self] in self?.navigationController?.popViewController(animated: true) }
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            }
            return
        }
        refreshSeats()
        refreshMessages(scroll: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { timeline.count }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { UITableView.automaticDimension }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat { 48 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "voiceMessage", for: indexPath) as! VoiceRoomMessageCell
        switch timeline[indexPath.row] {
        case .ambient(let bulletin): cell.configure(bulletin)
        case .persisted(let message): cell.configure(message)
        }
        return cell
    }
}

private final class VoiceRoomAudioSessionController {
    private let session = AVAudioSession.sharedInstance()
    private let engine = AVAudioEngine()
    private var sink: AVAudioSinkNode?
    private(set) var microphoneEnabled = false

    func activate(speaker: Bool) {
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetoothHFP, .defaultToSpeaker])
            try session.setActive(true, options: [])
            setSpeakerEnabled(speaker)
        } catch { }
    }

    func setMicrophoneEnabled(_ enabled: Bool) {
        guard enabled != microphoneEnabled else { return }
        if enabled {
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else { microphoneEnabled = true; return }
            let node = AVAudioSinkNode { _, _, _ in noErr }
            engine.attach(node)
            engine.connect(input, to: node, format: format)
            engine.prepare()
            do {
                try engine.start()
                sink = node
                microphoneEnabled = true
            } catch {
                engine.disconnectNodeOutput(input)
                engine.detach(node)
            }
        } else {
            engine.stop()
            engine.disconnectNodeOutput(engine.inputNode)
            if let sink { engine.detach(sink) }
            sink = nil
            microphoneEnabled = false
        }
    }

    func setSpeakerEnabled(_ enabled: Bool) {
        try? session.overrideOutputAudioPort(enabled ? .speaker : .none)
    }

    func deactivate() {
        setMicrophoneEnabled(false)
        try? session.overrideOutputAudioPort(.none)
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }
}

private final class VoiceRoomSeatView: UIControl {
    var onTap: (() -> Void)?
    var onMore: (() -> Void)?
    private let avatar = UIImageView()
    private let ring = UIView()
    private let status = UIImageView()
    private let name = UILabel.lm(size: 10, weight: .bold)
    private let badge = UILabel.lm(size: 8, weight: .heavy)
    private let more = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        ring.backgroundColor = UIColor.white.withAlphaComponent(0.07)
        ring.round(25)
        ring.translatesAutoresizingMaskIntoConstraints = false
        addSubview(ring)
        avatar.contentMode = .scaleAspectFill
        avatar.round(22)
        avatar.translatesAutoresizingMaskIntoConstraints = false
        ring.addSubview(avatar)
        status.tintColor = .white
        status.backgroundColor = LMTheme.violet
        status.round(8)
        status.translatesAutoresizingMaskIntoConstraints = false
        ring.addSubview(status)
        name.textAlignment = .center
        name.translatesAutoresizingMaskIntoConstraints = false
        addSubview(name)
        badge.textAlignment = .center
        badge.round(7)
        badge.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badge)
        more.setImage(UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)), for: .normal)
        more.tintColor = .white.withAlphaComponent(0.7)
        more.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        more.round(9)
        more.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
        more.translatesAutoresizingMaskIntoConstraints = false
        addSubview(more)
        NSLayoutConstraint.activate([
            ring.topAnchor.constraint(equalTo: topAnchor), ring.centerXAnchor.constraint(equalTo: centerXAnchor), ring.widthAnchor.constraint(equalToConstant: 50), ring.heightAnchor.constraint(equalTo: ring.widthAnchor),
            avatar.centerXAnchor.constraint(equalTo: ring.centerXAnchor), avatar.centerYAnchor.constraint(equalTo: ring.centerYAnchor), avatar.widthAnchor.constraint(equalToConstant: 44), avatar.heightAnchor.constraint(equalTo: avatar.widthAnchor),
            status.trailingAnchor.constraint(equalTo: ring.trailingAnchor), status.bottomAnchor.constraint(equalTo: ring.bottomAnchor), status.widthAnchor.constraint(equalToConstant: 16), status.heightAnchor.constraint(equalTo: status.widthAnchor),
            name.topAnchor.constraint(equalTo: ring.bottomAnchor, constant: 4), name.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 1), name.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1),
            badge.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 2), badge.centerXAnchor.constraint(equalTo: centerXAnchor), badge.heightAnchor.constraint(equalToConstant: 14), badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 28),
            more.topAnchor.constraint(equalTo: topAnchor), more.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2), more.widthAnchor.constraint(equalToConstant: 18), more.heightAnchor.constraint(equalTo: more.widthAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(member: CommunityProfile?, isHost: Bool, isMe: Bool, isMuted: Bool, open: Bool) {
        if let member {
            avatar.image = UIImage(named: member.image)
            avatar.backgroundColor = .clear
            name.text = member.name
            badge.text = isHost ? "  HOST  " : "  SPEAKER  "
            badge.backgroundColor = isHost ? LMTheme.pink : LMTheme.violet.withAlphaComponent(0.8)
            status.image = UIImage(systemName: "waveform", withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .bold))
            status.isHidden = false
            more.isHidden = false
            ring.layer.borderWidth = isHost ? 1.5 : 0
            ring.layer.borderColor = LMTheme.pinkSoft.cgColor
        } else if isMe {
            avatar.image = UIImage(systemName: "person.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .bold))
            avatar.tintColor = .white
            avatar.backgroundColor = LMTheme.pink.withAlphaComponent(0.75)
            name.text = "You"
            badge.text = isMuted ? "  MUTED  " : "  ON MIC  "
            badge.backgroundColor = isMuted ? UIColor.white.withAlphaComponent(0.15) : .systemGreen.withAlphaComponent(0.8)
            status.image = UIImage(systemName: isMuted ? "mic.slash.fill" : "waveform", withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .bold))
            status.isHidden = false
            more.isHidden = true
            ring.layer.borderWidth = 1.5
            ring.layer.borderColor = (isMuted ? LMTheme.muted : UIColor.systemGreen).cgColor
        } else {
            avatar.image = UIImage(systemName: open ? "plus" : "chair.lounge.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: open ? 20 : 16, weight: .semibold))
            avatar.tintColor = .white.withAlphaComponent(open ? 0.85 : 0.25)
            avatar.backgroundColor = UIColor.white.withAlphaComponent(open ? 0.09 : 0.035)
            name.text = open ? "Take seat" : "Open"
            badge.text = ""
            badge.backgroundColor = .clear
            status.isHidden = true
            more.isHidden = true
            ring.layer.borderWidth = open ? 1 : 0
            ring.layer.borderColor = LMTheme.pink.withAlphaComponent(0.55).cgColor
        }
    }

    @objc private func tapped() { onTap?() }
    @objc private func moreTapped() { onMore?() }
}

private final class VoiceRoomControlButton: UIButton {
    private let icon = UIImageView()
    private let caption = UILabel.lm(size: 9, weight: .bold, color: .white.withAlphaComponent(0.72))
    private let destructive: Bool

    init(symbol: String, title: String, destructive: Bool = false) {
        self.destructive = destructive
        super.init(frame: .zero)
        icon.tintColor = destructive ? .systemRed : .white
        icon.translatesAutoresizingMaskIntoConstraints = false
        caption.textAlignment = .center
        caption.translatesAutoresizingMaskIntoConstraints = false
        [icon, caption].forEach { $0.isUserInteractionEnabled = false; addSubview($0) }
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: centerXAnchor), icon.topAnchor.constraint(equalTo: topAnchor, constant: 7), icon.widthAnchor.constraint(equalToConstant: 21), icon.heightAnchor.constraint(equalTo: icon.widthAnchor),
            caption.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 4), caption.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        update(symbol: symbol, title: title, active: false)
    }

    required init?(coder: NSCoder) { fatalError() }

    func update(symbol: String, title: String, active: Bool) {
        icon.image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .bold))
        icon.tintColor = destructive ? .systemRed : (active ? LMTheme.pinkSoft : .white)
        caption.text = title
        caption.textColor = destructive ? UIColor.systemRed.withAlphaComponent(0.85) : (active ? LMTheme.pinkSoft : .white.withAlphaComponent(0.72))
    }
}

private final class VoiceRoomMessageCell: UITableViewCell {
    private static let clock: DateFormatter = { let formatter = DateFormatter(); formatter.dateFormat = "HH:mm"; return formatter }()
    private let avatar = UIView()
    private let initial = UILabel.lm(size: 10, weight: .heavy)
    private let name = UILabel.lm(size: 10, weight: .bold, color: LMTheme.pinkSoft)
    private let body = UILabel.lm(size: 12, weight: .medium, color: .white.withAlphaComponent(0.86))
    private let time = UILabel.lm(size: 8, weight: .medium, color: LMTheme.muted)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        avatar.backgroundColor = LMTheme.violet
        avatar.round(14)
        avatar.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(avatar)
        initial.textAlignment = .center
        initial.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(initial)
        body.numberOfLines = 0
        [name, body, time].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; contentView.addSubview($0) }
        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 7), avatar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7), avatar.widthAnchor.constraint(equalToConstant: 28), avatar.heightAnchor.constraint(equalTo: avatar.widthAnchor),
            initial.centerXAnchor.constraint(equalTo: avatar.centerXAnchor), initial.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            name.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 8), name.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            time.leadingAnchor.constraint(equalTo: name.trailingAnchor, constant: 6), time.centerYAnchor.constraint(equalTo: name.centerYAnchor),
            body.leadingAnchor.constraint(equalTo: name.leadingAnchor), body.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 2), body.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8), body.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -7)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ message: RoomConversationEntry) {
        apply(author: message.authorName, text: message.text, marker: Self.clock.string(from: message.sentAt), gift: nil)
        accessibilityIdentifier = "voice.message.persisted"
    }

    func configure(_ bulletin: VoiceRoomBulletin) {
        apply(author: bulletin.authorDisplayName, text: bulletin.activityText, marker: "LIVE", gift: bulletin.giftSymbol)
        accessibilityIdentifier = bulletin.giftSymbol == nil ? "voice.message.ambient" : "voice.giftActivity"
    }

    private func apply(author: String, text: String, marker: String, gift: String?) {
        initial.text = gift ?? String(author.prefix(1)).uppercased()
        name.text = author
        body.text = text
        body.textColor = gift == nil ? .white.withAlphaComponent(0.86) : UIColor(red: 1, green: 0.80, blue: 0.34, alpha: 1)
        avatar.backgroundColor = gift == nil ? LMTheme.violet : LMTheme.pink.withAlphaComponent(0.68)
        time.text = marker
    }
}

private final class VoiceRoomMembersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var onSelect: ((CommunityProfile) -> Void)?
    var onSafety: ((CommunityProfile) -> Void)?
    private let room: InterestRoomBlueprint
    private let isOnStage: Bool
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var members: [CommunityProfile] { room.participants }

    init(room: InterestRoomBlueprint, isOnStage: Bool) {
        self.room = room
        self.isOnStage = isOnStage
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheetPresentationController { sheetPresentationController.detents = [.medium(), .large()]; sheetPresentationController.prefersGrabberVisible = true }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMTheme.background
        let title = UILabel.lm("Room members", size: 22, weight: .bold)
        let count = UILabel.lm("\(room.online) listening · \(members.count + (isOnStage ? 1 : 0)) on stage", size: 11, weight: .medium, color: LMTheme.muted)
        [title, count].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; view.addSubview($0) }
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18), title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            count.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4), count.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: count.bottomAnchor, constant: 12), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        NotificationCenter.default.addObserver(forName: .lookMeStoreChanged, object: nil, queue: .main) { [weak self] _ in self?.tableView.reloadData() }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { members.count + (isOnStage ? 1 : 0) }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 66 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.textLabel?.font = LMTheme.font(size: 14, weight: .bold)
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.font = LMTheme.font(size: 10, weight: .medium)
        cell.detailTextLabel?.textColor = LMTheme.muted
        if indexPath.row < members.count {
            let member = members[indexPath.row]
            cell.textLabel?.text = member.name
            cell.detailTextLabel?.text = indexPath.row == 0 ? "Host · \(member.country)" : "Speaker · \(member.country)"
            cell.imageView?.image = UIImage(named: member.image)
            let more = UIButton(type: .system)
            more.tag = indexPath.row
            more.setImage(UIImage(systemName: "ellipsis"), for: .normal)
            more.tintColor = .white
            more.addTarget(self, action: #selector(moreTapped(_:)), for: .touchUpInside)
            cell.accessoryView = more
        } else {
            cell.textLabel?.text = "You"
            cell.detailTextLabel?.text = "On stage"
            cell.imageView?.image = UIImage(systemName: "person.crop.circle.fill")
            cell.imageView?.tintColor = LMTheme.pink
        }
        cell.imageView?.layer.cornerRadius = 21
        cell.imageView?.clipsToBounds = true
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { if indexPath.row < members.count { onSelect?(members[indexPath.row]) } }
    @objc private func moreTapped(_ sender: UIButton) { guard members.indices.contains(sender.tag) else { return }; onSafety?(members[sender.tag]) }
}

private final class VoiceRoomLeaveViewController: UIViewController {
    var onLeave: (() -> Void)?
    private let roomName: String
    private let isOnStage: Bool

    init(roomName: String, isOnStage: Bool) {
        self.roomName = roomName
        self.isOnStage = isOnStage
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.68)
        let card = UIView()
        card.backgroundColor = LMTheme.panel
        card.round(28)
        card.layer.borderWidth = 1
        card.layer.borderColor = LMTheme.pink.withAlphaComponent(0.25).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)
        let iconHost = UIView()
        iconHost.backgroundColor = LMTheme.violet
        iconHost.round(31)
        let icon = UIImageView(image: UIImage(systemName: "waveform.badge.minus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .bold)))
        icon.tintColor = .white
        let title = UILabel.lm("Leave the room?", size: 21, weight: .bold)
        title.textAlignment = .center
        let message = UILabel.lm(isOnStage ? "Leaving \(roomName) will also take you off the mic." : "You can come back to \(roomName) whenever the room is open.", size: 12, weight: .medium, color: .white.withAlphaComponent(0.7))
        message.numberOfLines = 0
        message.textAlignment = .center
        let leave = UIButton.lm("Leave room", symbol: "rectangle.portrait.and.arrow.right.fill")
        leave.backgroundColor = .systemRed.withAlphaComponent(0.92)
        leave.round(22)
        leave.addTarget(self, action: #selector(confirm), for: .touchUpInside)
        let stay = UIButton.lm("Stay in room")
        stay.backgroundColor = UIColor.white.withAlphaComponent(0.07)
        stay.round(22)
        stay.addTarget(self, action: #selector(close), for: .touchUpInside)
        [iconHost, title, message, leave, stay].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; card.addSubview($0) }
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconHost.addSubview(icon)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28), card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28), card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            iconHost.topAnchor.constraint(equalTo: card.topAnchor, constant: 25), iconHost.centerXAnchor.constraint(equalTo: card.centerXAnchor), iconHost.widthAnchor.constraint(equalToConstant: 62), iconHost.heightAnchor.constraint(equalTo: iconHost.widthAnchor),
            icon.centerXAnchor.constraint(equalTo: iconHost.centerXAnchor), icon.centerYAnchor.constraint(equalTo: iconHost.centerYAnchor),
            title.topAnchor.constraint(equalTo: iconHost.bottomAnchor, constant: 17), title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18), title.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            message.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8), message.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 25), message.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -25),
            leave.topAnchor.constraint(equalTo: message.bottomAnchor, constant: 22), leave.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16), leave.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16), leave.heightAnchor.constraint(equalToConstant: 47),
            stay.topAnchor.constraint(equalTo: leave.bottomAnchor, constant: 8), stay.leadingAnchor.constraint(equalTo: leave.leadingAnchor), stay.trailingAnchor.constraint(equalTo: leave.trailingAnchor), stay.heightAnchor.constraint(equalToConstant: 46), stay.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }

    @objc private func close() { dismiss(animated: true) }
    @objc private func confirm() { dismiss(animated: true) { [weak self] in self?.onLeave?() } }
}
