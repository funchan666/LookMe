import UIKit

final class InterestRoomComposerViewController: LMViewController, UITextViewDelegate {
    var onCreated: ((InterestRoomBlueprint) -> Void)?

    private let roomNameField = UITextField()
    private let roomSummaryView = UITextView()
    private let topicOptions = ["Conversation", "Music", "City notes", "Cinema", "Travel", "Creative"]
    private var selectedTopic = "Conversation"
    private var topicButtons: [UIButton] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Shape a room"

        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        scroll.keyboardDismissMode = .interactive
        view.addSubview(scroll)
        scroll.pin(to: view)

        let canvas = UIStackView()
        canvas.axis = .vertical
        canvas.spacing = 16
        canvas.layoutMargins = UIEdgeInsets(top: 12, left: 18, bottom: 34, right: 18)
        canvas.isLayoutMarginsRelativeArrangement = true
        canvas.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(canvas)
        NSLayoutConstraint.activate([
            canvas.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            canvas.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            canvas.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            canvas.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            canvas.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])

        canvas.addArrangedSubview(makeHero())
        let introduction = UILabel.lm("Give people a clear reason to gather", size: 22, weight: .bold)
        introduction.font = LMTheme.displayFont(size: 22, weight: .bold)
        canvas.addArrangedSubview(introduction)
        let guidance = UILabel.lm("Choose a focused topic and a short room note. Room titles and messages follow the same community safety rules as the rest of NightHub.", size: 12, weight: .medium, color: LMTheme.muted)
        guidance.numberOfLines = 0
        canvas.addArrangedSubview(guidance)

        canvas.addArrangedSubview(sectionLabel("ROOM NAME"))
        configureRoomNameField()
        canvas.addArrangedSubview(roomNameField)

        canvas.addArrangedSubview(sectionLabel("ROOM NOTE"))
        configureSummaryView()
        canvas.addArrangedSubview(roomSummaryView)

        canvas.addArrangedSubview(sectionLabel("CONVERSATION SIGNAL"))
        canvas.addArrangedSubview(makeTopicGrid())

        let createButton = UIButton.lm("Open this room", symbol: "waveform.circle.fill")
        createButton.backgroundColor = LMTheme.pink
        createButton.round(27)
        createButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        createButton.titleLabel?.font = LMTheme.displayFont(size: 16, weight: .bold)
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        canvas.addArrangedSubview(createButton)

        let safety = UILabel.lm("You remain in control of reporting, blocking and leaving the room at any time.", size: 10, weight: .medium, color: UIColor.white.withAlphaComponent(0.48))
        safety.numberOfLines = 0
        safety.textAlignment = .center
        canvas.addArrangedSubview(safety)
    }

    private func makeHero() -> UIView {
        let hero = UIView()
        hero.heightAnchor.constraint(equalToConstant: 196).isActive = true
        hero.clipsToBounds = true
        hero.round(28)

        let art = UIImageView(image: UIImage(named: "presence-constellation-field.png"))
        art.contentMode = .scaleAspectFill
        hero.addSubview(art)
        art.pin(to: hero)

        let glass = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        glass.round(22)
        glass.translatesAutoresizingMaskIntoConstraints = false
        hero.addSubview(glass)
        let symbol = UIImageView(image: UIImage(systemName: "waveform.badge.plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 31, weight: .bold)))
        symbol.tintColor = .white
        symbol.contentMode = .center
        symbol.translatesAutoresizingMaskIntoConstraints = false
        glass.contentView.addSubview(symbol)
        let title = UILabel.lm("A room with a point of view", size: 17, weight: .bold)
        title.font = LMTheme.displayFont(size: 17, weight: .bold)
        title.translatesAutoresizingMaskIntoConstraints = false
        glass.contentView.addSubview(title)
        let note = UILabel.lm("Curated topic · live voice · calm controls", size: 10, weight: .semibold, color: .white.withAlphaComponent(0.7))
        note.translatesAutoresizingMaskIntoConstraints = false
        glass.contentView.addSubview(note)
        let affordance = UIImageView(image: UIImage(systemName: "arrow.up.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)))
        affordance.tintColor = LMTheme.pinkSoft
        affordance.backgroundColor = UIColor.black.withAlphaComponent(0.24)
        affordance.contentMode = .center
        affordance.round(15)
        affordance.translatesAutoresizingMaskIntoConstraints = false
        glass.contentView.addSubview(affordance)
        let guideButton = UIButton(type: .custom)
        guideButton.accessibilityIdentifier = "roomComposer.guide"
        guideButton.accessibilityLabel = "Open room design guide"
        guideButton.addTarget(self, action: #selector(openRoomGuide), for: .touchUpInside)
        guideButton.addTarget(self, action: #selector(heroPressed(_:)), for: .touchDown)
        guideButton.addTarget(self, action: #selector(heroReleased(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        guideButton.translatesAutoresizingMaskIntoConstraints = false
        hero.addSubview(guideButton)
        NSLayoutConstraint.activate([
            glass.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 18),
            glass.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -18),
            glass.bottomAnchor.constraint(equalTo: hero.bottomAnchor, constant: -18),
            glass.heightAnchor.constraint(equalToConstant: 84),
            symbol.leadingAnchor.constraint(equalTo: glass.contentView.leadingAnchor, constant: 14),
            symbol.centerYAnchor.constraint(equalTo: glass.contentView.centerYAnchor),
            symbol.widthAnchor.constraint(equalToConstant: 48),
            title.leadingAnchor.constraint(equalTo: symbol.trailingAnchor, constant: 10),
            title.trailingAnchor.constraint(lessThanOrEqualTo: affordance.leadingAnchor, constant: -8),
            title.topAnchor.constraint(equalTo: glass.contentView.topAnchor, constant: 20),
            note.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            note.trailingAnchor.constraint(lessThanOrEqualTo: affordance.leadingAnchor, constant: -8),
            note.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 5),
            affordance.trailingAnchor.constraint(equalTo: glass.contentView.trailingAnchor, constant: -13), affordance.centerYAnchor.constraint(equalTo: glass.contentView.centerYAnchor), affordance.widthAnchor.constraint(equalToConstant: 30), affordance.heightAnchor.constraint(equalTo: affordance.widthAnchor),
            guideButton.topAnchor.constraint(equalTo: hero.topAnchor), guideButton.leadingAnchor.constraint(equalTo: hero.leadingAnchor), guideButton.trailingAnchor.constraint(equalTo: hero.trailingAnchor), guideButton.bottomAnchor.constraint(equalTo: hero.bottomAnchor)
        ])
        return hero
    }

    private func configureRoomNameField() {
        roomNameField.placeholder = "Example: Sunday Photo Walk".lmLocalized
        roomNameField.attributedPlaceholder = NSAttributedString(string: "Example: Sunday Photo Walk".lmLocalized, attributes: [.foregroundColor: LMTheme.muted])
        roomNameField.textColor = .white
        roomNameField.font = LMTheme.font(size: 15, weight: .semibold)
        roomNameField.backgroundColor = LMTheme.panel
        roomNameField.round(17)
        roomNameField.setLeftPadding(16)
        roomNameField.heightAnchor.constraint(equalToConstant: 54).isActive = true
        roomNameField.returnKeyType = .next
        roomNameField.addTarget(self, action: #selector(nameDidReturn), for: .editingDidEndOnExit)
    }

    private func configureSummaryView() {
        roomSummaryView.text = "What would you like people to talk about?"
        roomSummaryView.textColor = LMTheme.muted
        roomSummaryView.font = LMTheme.font(size: 14, weight: .medium)
        roomSummaryView.backgroundColor = LMTheme.panel
        roomSummaryView.textContainerInset = UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 12)
        roomSummaryView.round(17)
        roomSummaryView.heightAnchor.constraint(equalToConstant: 104).isActive = true
        roomSummaryView.delegate = self
    }

    private func makeTopicGrid() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        for rowStart in stride(from: 0, to: topicOptions.count, by: 2) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8
            row.distribution = .fillEqually
            topicOptions[rowStart..<min(rowStart + 2, topicOptions.count)].forEach { topic in
                let button = UIButton(type: .system)
                button.setTitle(topic, for: .normal)
                button.titleLabel?.font = LMTheme.font(size: 12, weight: .bold)
                button.heightAnchor.constraint(equalToConstant: 44).isActive = true
                button.round(15)
                button.addAction(UIAction { [weak self, weak button] _ in
                    guard let self, let value = button?.title(for: .normal) else { return }
                    self.selectedTopic = value
                    self.refreshTopics()
                }, for: .touchUpInside)
                topicButtons.append(button)
                row.addArrangedSubview(button)
            }
            stack.addArrangedSubview(row)
        }
        refreshTopics()
        return stack
    }

    private func refreshTopics() {
        topicButtons.forEach { button in
            let selected = button.title(for: .normal) == selectedTopic
            button.backgroundColor = selected ? LMTheme.pink : LMTheme.panel
            button.setTitleColor(selected ? .white : .white.withAlphaComponent(0.72), for: .normal)
            button.layer.borderWidth = selected ? 0 : 1
            button.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        }
    }

    private func sectionLabel(_ text: String) -> UILabel { UILabel.lm(text, size: 10, weight: .heavy, color: LMTheme.pinkSoft) }

    @objc private func nameDidReturn() { roomSummaryView.becomeFirstResponder() }

    @objc private func openRoomGuide() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        present(RoomPointOfViewGuideViewController(), animated: true)
    }

    @objc private func heroPressed(_ sender: UIButton) {
        UIView.animate(withDuration: 0.14) { sender.superview?.transform = CGAffineTransform(scaleX: 0.985, y: 0.985) }
    }

    @objc private func heroReleased(_ sender: UIButton) {
        UIView.animate(withDuration: 0.18) { sender.superview?.transform = .identity }
    }

    @objc private func createTapped() {
        let title = (roomNameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let rawSummary = roomSummaryView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let summary = roomSummaryView.textColor == LMTheme.muted ? "" : rawSummary
        guard title.count >= 3, title.count <= 48, summary.count >= 8, summary.count <= 160 else {
            present(LMNoticeViewController(style: .warning, title: "A little more shape", message: "Use a 3–48 character room name and an 8–160 character note."), animated: true)
            return
        }
        for copy in [title, summary] {
            let decision = LookMeContentPolicy.evaluate(copy)
            guard decision.isAllowed else {
                present(LMNoticeViewController(style: .warning, title: "Please revise this room", message: decision.rejectionReason?.userMessage ?? "This room needs a safer, clearer description."), animated: true)
                return
            }
        }
        let room = LookMeExperienceStore.shared.createInterestRoom(title: title, summary: summary, topic: selectedTopic)
        navigationController?.popViewController(animated: false)
        onCreated?(room)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == LMTheme.muted { textView.text = ""; textView.textColor = .white }
    }
}

private final class RoomPointOfViewGuideViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMTheme.background

        let handle = UIView(); handle.backgroundColor = UIColor.white.withAlphaComponent(0.22); handle.round(2); handle.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(handle)
        let eyebrow = UILabel.lm("ROOM BLUEPRINT", size: 10, weight: .heavy, color: LMTheme.pinkSoft)
        let title = UILabel.lm("Give the room a clear point of view", size: 22, weight: .bold); title.font = LMTheme.displayFont(size: 22, weight: .bold); title.numberOfLines = 0
        let note = UILabel.lm("A strong room tells people what they will share before they enter.", size: 12, weight: .medium, color: LMTheme.muted); note.numberOfLines = 0
        let stack = UIStackView(); stack.axis = .vertical; stack.spacing = 9
        let close = UIButton.lm("Continue shaping", symbol: "waveform.badge.plus"); close.accessibilityIdentifier = "roomGuide.close"; close.backgroundColor = LMTheme.pink; close.round(24); close.addTarget(self, action: #selector(closeGuide), for: .touchUpInside)
        [eyebrow, title, note, stack, close].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; view.addSubview($0) }

        stack.addArrangedSubview(guideRow(symbol: "scope", title: "One specific promise", note: "Choose one subject people can understand at a glance."))
        stack.addArrangedSubview(guideRow(symbol: "quote.bubble.fill", title: "An easy first question", note: "Use the room note to give the first speaker somewhere to begin."))
        stack.addArrangedSubview(guideRow(symbol: "hand.raised.fill", title: "A calm hosting rhythm", note: "Welcome listeners, share the stage and keep safety controls visible."))

        NSLayoutConstraint.activate([
            handle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8), handle.centerXAnchor.constraint(equalTo: view.centerXAnchor), handle.widthAnchor.constraint(equalToConstant: 38), handle.heightAnchor.constraint(equalToConstant: 4),
            eyebrow.topAnchor.constraint(equalTo: handle.bottomAnchor, constant: 22), eyebrow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            title.topAnchor.constraint(equalTo: eyebrow.bottomAnchor, constant: 8), title.leadingAnchor.constraint(equalTo: eyebrow.leadingAnchor), title.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            note.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8), note.leadingAnchor.constraint(equalTo: title.leadingAnchor), note.trailingAnchor.constraint(equalTo: title.trailingAnchor),
            stack.topAnchor.constraint(equalTo: note.bottomAnchor, constant: 20), stack.leadingAnchor.constraint(equalTo: title.leadingAnchor), stack.trailingAnchor.constraint(equalTo: title.trailingAnchor),
            close.topAnchor.constraint(greaterThanOrEqualTo: stack.bottomAnchor, constant: 18), close.leadingAnchor.constraint(equalTo: title.leadingAnchor), close.trailingAnchor.constraint(equalTo: title.trailingAnchor), close.heightAnchor.constraint(equalToConstant: 50), close.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        preferredContentSize = CGSize(width: view.bounds.width, height: 520)
    }

    private func guideRow(symbol: String, title: String, note: String) -> UIView {
        let card = UIView(); card.backgroundColor = LMTheme.panel; card.round(17); card.heightAnchor.constraint(equalToConstant: 72).isActive = true
        let icon = UIImageView(image: UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .bold))); icon.tintColor = LMTheme.pinkSoft; icon.contentMode = .center; icon.backgroundColor = LMTheme.violet.withAlphaComponent(0.46); icon.round(19)
        let heading = UILabel.lm(title, size: 13, weight: .bold)
        let detail = UILabel.lm(note, size: 10, weight: .medium, color: LMTheme.muted); detail.numberOfLines = 2
        [icon, heading, detail].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; card.addSubview($0) }
        NSLayoutConstraint.activate([icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12), icon.centerYAnchor.constraint(equalTo: card.centerYAnchor), icon.widthAnchor.constraint(equalToConstant: 38), icon.heightAnchor.constraint(equalTo: icon.widthAnchor), heading.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 11), heading.topAnchor.constraint(equalTo: card.topAnchor, constant: 13), heading.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12), detail.leadingAnchor.constraint(equalTo: heading.leadingAnchor), detail.trailingAnchor.constraint(equalTo: heading.trailingAnchor), detail.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 3)])
        return card
    }

    @objc private func closeGuide() { dismiss(animated: true) }

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheetPresentationController {
            sheetPresentationController.detents = [.large()]
            sheetPresentationController.prefersGrabberVisible = false
            sheetPresentationController.preferredCornerRadius = 28
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}
