import UIKit
import AuthenticationServices

final class LoginViewController: UIViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, UITextViewDelegate, UITextFieldDelegate {
    private let email = UITextField()
    private let password = UITextField()
    private let loginButton = UIButton(type: .system)
    private let agreementButton = UIButton(type: .system)
    private let agreementText = UITextView()
    private var hasAcceptedAgreements = false { didSet { updateAgreementState() } }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackdrop()
        configureContent()
        updateAgreementState()
    }

    private func configureBackdrop() {
        let image = UIImageView(image: UIImage(named: "account-entry-scene.png"))
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        view.addSubview(image)
        image.pin(to: view)

        let shade = UIView()
        view.addSubview(shade)
        shade.pin(to: view)
        DispatchQueue.main.async {
            LMTheme.gradient(shade, colors: [UIColor.black.withAlphaComponent(0.04), LMTheme.background.withAlphaComponent(0.99)], horizontal: false)
        }
    }

    private func configureContent() {
        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .interactive
        scroll.showsVerticalScrollIndicator = false
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissTap.cancelsTouchesInView = false
        scroll.addGestureRecognizer(dismissTap)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        let mark = UIImageView(image: UIImage(named: "lookme-presence-mark.png"))
        mark.contentMode = .scaleAspectFill
        mark.round(20)
        mark.translatesAutoresizingMaskIntoConstraints = false
        let markHolder = UIView()
        markHolder.addSubview(mark)
        let title = UILabel.lm("NightHub", size: 31, weight: .bold)
        title.accessibilityIdentifier = "login.title"
        let subtitle = UILabel.lm("Real people. Real conversations.", size: 14, weight: .medium, color: UIColor.white.withAlphaComponent(0.78))

        configureField(email, placeholder: "Email address", symbol: "envelope.fill")
        email.keyboardType = .emailAddress
        email.textContentType = .emailAddress
        email.autocapitalizationType = .none
        email.returnKeyType = .next
        email.delegate = self
        configureField(password, placeholder: "Password (6+ characters)", symbol: "lock.fill")
        password.isSecureTextEntry = true
        password.textContentType = .password
        password.returnKeyType = .go
        password.delegate = self

        loginButton.setTitle("Continue".lmLocalized, for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = LMTheme.font(size: 16, weight: .bold)
        loginButton.backgroundColor = LMTheme.pink
        loginButton.round(25)
        loginButton.accessibilityIdentifier = "login.continue"
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)

        let createAccount = UIButton(type: .system)
        createAccount.setTitle("Create an account".lmLocalized, for: .normal)
        createAccount.setTitleColor(.white.withAlphaComponent(0.82), for: .normal)
        createAccount.titleLabel?.font = LMTheme.font(size: 13, weight: .bold)
        createAccount.layer.cornerRadius = 23
        createAccount.layer.borderWidth = 1
        createAccount.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        createAccount.addTarget(self, action: #selector(register), for: .touchUpInside)

        let divider = UILabel.lm("or continue with", size: 11, weight: .semibold, color: UIColor.white.withAlphaComponent(0.55))
        divider.textAlignment = .center
        let apple = UIButton(type: .system)
        var appleConfiguration = UIButton.Configuration.plain()
        appleConfiguration.title = "Sign in with Apple".lmLocalized
        appleConfiguration.image = UIImage(systemName: "apple.logo", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium))
        appleConfiguration.imagePadding = 9
        appleConfiguration.baseForegroundColor = .black
        appleConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18)
        appleConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var updated = attributes
            updated.font = .systemFont(ofSize: 20, weight: .medium)
            return updated
        }
        apple.configuration = appleConfiguration
        apple.backgroundColor = .white
        apple.layer.cornerRadius = 25
        apple.clipsToBounds = true
        apple.accessibilityIdentifier = "login.apple"
        apple.accessibilityLabel = "Sign in with Apple".lmLocalized
        apple.addTarget(self, action: #selector(appleLogin), for: .touchUpInside)

        configureAgreementText()
        agreementButton.addTarget(self, action: #selector(toggleAgreement), for: .touchUpInside)
        agreementButton.accessibilityLabel = "Accept Terms of Service and Privacy Policy"
        agreementButton.accessibilityIdentifier = "login.agreement"
        let agreementRow = UIStackView(arrangedSubviews: [agreementButton, agreementText])
        agreementRow.axis = .horizontal
        agreementRow.alignment = .top
        agreementRow.spacing = 8

        let stack = UIStackView(arrangedSubviews: [markHolder, title, subtitle, email, password, loginButton, createAccount, divider, apple, agreementRow])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 10
        stack.setCustomSpacing(5, after: title)
        stack.setCustomSpacing(22, after: subtitle)
        stack.setCustomSpacing(14, after: password)
        stack.setCustomSpacing(12, after: createAccount)
        stack.setCustomSpacing(8, after: divider)
        stack.setCustomSpacing(14, after: apple)
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
            content.heightAnchor.constraint(greaterThanOrEqualTo: scroll.frameLayoutGuide.heightAnchor),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 27),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -27),
            stack.topAnchor.constraint(greaterThanOrEqualTo: content.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: content.safeAreaLayoutGuide.bottomAnchor, constant: -13),
            markHolder.heightAnchor.constraint(equalToConstant: 70),
            mark.centerXAnchor.constraint(equalTo: markHolder.centerXAnchor),
            mark.centerYAnchor.constraint(equalTo: markHolder.centerYAnchor),
            mark.widthAnchor.constraint(equalToConstant: 70),
            mark.heightAnchor.constraint(equalToConstant: 70),
            email.heightAnchor.constraint(equalToConstant: 52),
            password.heightAnchor.constraint(equalToConstant: 52),
            loginButton.heightAnchor.constraint(equalToConstant: 52),
            createAccount.heightAnchor.constraint(equalToConstant: 46),
            apple.heightAnchor.constraint(equalToConstant: 52),
            agreementButton.widthAnchor.constraint(equalToConstant: 27),
            agreementButton.heightAnchor.constraint(equalToConstant: 30),
            agreementText.heightAnchor.constraint(equalToConstant: 54)
        ])
        title.textAlignment = .center
        subtitle.textAlignment = .center
    }

    private func configureField(_ field: UITextField, placeholder: String, symbol: String) {
        field.attributedPlaceholder = NSAttributedString(string: placeholder.lmLocalized, attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.52)])
        field.textColor = .white
        field.tintColor = LMTheme.pinkSoft
        field.font = LMTheme.font(size: 14, weight: .medium)
        field.backgroundColor = UIColor.black.withAlphaComponent(0.34)
        field.layer.cornerRadius = 16
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.white.withAlphaComponent(0.13).cgColor

        let iconHolder = UIView(frame: CGRect(x: 0, y: 0, width: 54, height: 52))
        let configuration = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        let icon = UIImageView(image: UIImage(systemName: symbol, withConfiguration: configuration))
        icon.tintColor = .white.withAlphaComponent(0.72)
        icon.contentMode = .scaleAspectFit
        icon.frame = CGRect(x: 17, y: 16, width: 20, height: 20)
        iconHolder.addSubview(icon)
        field.leftView = iconHolder
        field.leftViewMode = .always
    }

    private func configureAgreementText() {
        agreementText.delegate = self
        agreementText.backgroundColor = .clear
        agreementText.isEditable = false
        agreementText.isScrollEnabled = false
        agreementText.textContainerInset = UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 0)
        agreementText.textContainer.lineFragmentPadding = 0
        agreementText.linkTextAttributes = [.foregroundColor: LMTheme.pinkSoft, .underlineStyle: NSUnderlineStyle.single.rawValue]
        let text = NSMutableAttributedString(
            string: "I have read and agree to the Terms of Service and Privacy Policy.",
            attributes: [.font: LMTheme.font(size: 11, weight: .medium), .foregroundColor: UIColor.white.withAlphaComponent(0.68)]
        )
        let source = text.string as NSString
        text.addAttribute(.link, value: "lookme://terms", range: source.range(of: "Terms of Service"))
        text.addAttribute(.link, value: "lookme://privacy", range: source.range(of: "Privacy Policy"))
        agreementText.attributedText = text
        agreementText.accessibilityIdentifier = "login.legal"
    }

    private func updateAgreementState() {
        let symbol = hasAcceptedAgreements ? "checkmark.circle.fill" : "circle"
        agreementButton.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 23, weight: .semibold)), for: .normal)
        agreementButton.tintColor = hasAcceptedAgreements ? LMTheme.pinkSoft : UIColor.white.withAlphaComponent(0.58)
        agreementButton.accessibilityValue = hasAcceptedAgreements ? "Accepted" : "Not accepted"
    }

    @objc private func toggleAgreement() {
        hasAcceptedAgreements.toggle()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func login() {
        guard requireAgreement() else { return }
        guard let credentials = validatedCredentials() else { return }
        storeEmailIdentity(email: credentials.email)
        showAuthProgress(title: "Signing you in", detail: "Opening your NightHub world…")
    }

    @objc private func register() {
        guard requireAgreement() else { return }
        guard let credentials = validatedCredentials() else { return }
        storeEmailIdentity(email: credentials.email)
        showAuthProgress(title: "Creating your profile", detail: "Saving your details and preparing your space…")
    }

    private func validatedCredentials() -> (email: String, password: String)? {
        let emailValue = email.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let passwordValue = password.text ?? ""
        guard LoginValidation.isValidEmail(emailValue), LoginValidation.isValidPassword(passwordValue) else {
            present(LMNoticeViewController(style: .warning, title: "Check your details", message: "Enter a valid email address and a password with at least 6 characters."), animated: true)
            return nil
        }
        return (emailValue, passwordValue)
    }

    private func requireAgreement() -> Bool {
        guard hasAcceptedAgreements else {
            let prompt = AgreementRequiredViewController()
            prompt.onReview = { [weak self] in self?.emphasizeAgreement() }
            present(prompt, animated: true)
            return false
        }
        return true
    }

    private func emphasizeAgreement() {
        agreementButton.layer.removeAllAnimations()
        UIView.animateKeyframes(withDuration: 0.48, delay: 0) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.25) { self.agreementButton.transform = CGAffineTransform(translationX: -7, y: 0) }
            UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25) { self.agreementButton.transform = CGAffineTransform(translationX: 7, y: 0) }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.25) { self.agreementButton.transform = CGAffineTransform(translationX: -4, y: 0) }
            UIView.addKeyframe(withRelativeStartTime: 0.75, relativeDuration: 0.25) { self.agreementButton.transform = .identity }
        }
    }

    private func storeEmailIdentity(email: String) {
        let defaults = UserDefaults.standard
        defaults.set(email, forKey: "currentUserEmail")
        defaults.set("email", forKey: "loginMethod")
        let localName = email.split(separator: "@").first.map(String.init) ?? ""
        let displayName = localName.replacingOccurrences(of: ".", with: " ").replacingOccurrences(of: "_", with: " ").capitalized
        if !displayName.isEmpty { LookMeExperienceStore.shared.nickname = displayName }
    }

    private func showAuthProgress(title: String, detail: String) {
        view.endEditing(true)
        let progress = AuthProgressViewController(title: title, detail: detail) { [weak self] in self?.completeLogin() }
        present(progress, animated: true)
    }

    @objc private func appleLogin() {
        guard requireAgreement() else { return }
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            present(LMNoticeViewController(style: .warning, title: "Sign in unavailable", message: "Apple did not return a usable account credential."), animated: true)
            return
        }
        let defaults = UserDefaults.standard
        defaults.set(credential.user, forKey: "appleUserIdentifier")
        defaults.set("apple", forKey: "loginMethod")
        if let value = credential.email { defaults.set(value, forKey: "currentUserEmail") }

        let formatter = PersonNameComponentsFormatter()
        let returnedName = credential.fullName.map(formatter.string(from:))?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let returnedName, !returnedName.isEmpty {
            defaults.set(returnedName, forKey: "appleDisplayName")
            LookMeExperienceStore.shared.nickname = returnedName
        } else if let savedName = defaults.string(forKey: "appleDisplayName"), !savedName.isEmpty {
            LookMeExperienceStore.shared.nickname = savedName
        }
        showAuthProgress(title: "Welcome to NightHub", detail: "Apple verified your identity. Syncing your profile…")
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if (error as? ASAuthorizationError)?.code != .canceled {
            present(LMNoticeViewController(style: .warning, title: "Sign in unavailable", message: "Apple sign in could not be completed. Please try again."), animated: true)
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor { view.window ?? ASPresentationAnchor() }

    private func completeLogin() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        UserDefaults.standard.set(true, forKey: "didQuickLogin")
        UserDefaults.standard.set(true, forKey: "acceptedLegalAgreements")
        let welcomeCoins = LookMeExperienceStore.shared.grantWelcomeCoinsIfNeeded()
        AppRouter.shared.showMain(welcomeCoins: welcomeCoins)
    }

    @available(iOS 17.0, *)
    func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
        guard case .link(let policyURL) = textItem.content else { return defaultAction }
        return UIAction { [weak self] _ in
            self?.openPolicy(for: policyURL)
        }
    }

    func textView(_ textView: UITextView, shouldInteractWith policyURL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        openPolicy(for: policyURL)
        return false
    }

    private func openPolicy(for policyURL: URL) {
        let kind: PolicyKind = policyURL.host == "privacy" ? .privacy : .terms
        present(UINavigationController(rootViewController: PolicyViewController(kind: kind)), animated: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === email { password.becomeFirstResponder() }
        else { textField.resignFirstResponder(); login() }
        return true
    }
}
