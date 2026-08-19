import XCTest

final class LookMeUITests: XCTestCase {
    private func launchSignedIn(_ app: XCUIApplication) {
        let scenarioArguments = app.launchArguments
        app.launchArguments = ["-didQuickLogin", "YES", "-acceptedLegalAgreements", "YES", "-loginMethod", "email", "-welcomeCoinsGranted", "YES", "-lookMe.interfaceLanguage", "en"] + scenarioArguments
        app.launch()
        XCTAssertTrue(app.buttons["main.tab.1"].waitForExistence(timeout: 6))
    }

    private func keepScreenshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }

    func testAppLaunches() {
        let app = XCUIApplication(); app.launchArguments = ["-lookMe.interfaceLanguage", "en"]; app.launch(); XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }

    func testLoginCannotContinueWithoutBothAgreements() {
        let app = XCUIApplication()
        app.launchArguments = ["-didQuickLogin", "NO", "-acceptedLegalAgreements", "NO", "-lookMe.interfaceLanguage", "en"]
        app.launch()
        let continueButton = app.buttons["login.continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 4))
        XCTAssertEqual(app.buttons["login.apple"].label, "Sign in with Apple")
        continueButton.tap()
        XCTAssertTrue(app.staticTexts["One thoughtful tap"].waitForExistence(timeout: 2))
    }

    func testFirstLoginShowsWelcomeCoinDrop() {
        let app = XCUIApplication()
        app.launchArguments = ["-didQuickLogin", "NO", "-acceptedLegalAgreements", "NO", "-welcomeCoinsGranted", "NO", "-coins", "0", "-lookMe.interfaceLanguage", "en"]
        app.launch()
        let email = app.textFields["Email address"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap(); email.typeText("newuser@example.com")
        let password = app.secureTextFields["Password (6+ characters)"]
        password.tap(); password.typeText("123456")
        app.staticTexts["login.title"].tap()
        app.buttons["login.agreement"].tap()
        app.buttons["login.continue"].tap()
        XCTAssertTrue(app.staticTexts["Your NightHub signal is live"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["888"].waitForExistence(timeout: 3))
        let welcomeShot = XCTAttachment(screenshot: app.screenshot())
        welcomeShot.name = "WelcomeCoinDrop"
        welcomeShot.lifetime = .keepAlways
        add(welcomeShot)
    }

    func testCoinVaultShowsBalanceAndSpendingGuide() {
        let app = XCUIApplication()
        app.launchArguments = ["-didQuickLogin", "YES", "-acceptedLegalAgreements", "YES", "-loginMethod", "email", "-coins", "888", "-lookMe.interfaceLanguage", "en"]
        app.launch()
        let profile = app.buttons["Profile"]
        XCTAssertTrue(profile.waitForExistence(timeout: 5)); profile.tap()
        let vault = app.buttons["profile.coinVault"]
        if !vault.waitForExistence(timeout: 3) { profile.tap() }
        XCTAssertTrue(vault.waitForExistence(timeout: 3)); vault.tap()
        XCTAssertTrue(app.navigationBars["Coin Vault"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["WHERE COINS GO"].exists)
        XCTAssertEqual(app.staticTexts["coin.balance"].label, "888")
        let vaultShot = XCTAttachment(screenshot: app.screenshot())
        vaultShot.name = "CoinVault"
        vaultShot.lifetime = .keepAlways
        add(vaultShot)
    }

    func testProfileRelationshipCountersOpenDetailLists() {
        let app = XCUIApplication(); launchSignedIn(app)
        app.buttons["main.tab.4"].tap()

        let friends = app.buttons["profile.relationship.friends"]
        XCTAssertTrue(friends.waitForExistence(timeout: 4)); friends.tap()
        XCTAssertTrue(app.navigationBars["Friends"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tables["relationship.list.friends"].exists)

        app.navigationBars.buttons.firstMatch.tap()
        let following = app.buttons["profile.relationship.following"]
        XCTAssertTrue(following.waitForExistence(timeout: 3)); following.tap()
        XCTAssertTrue(app.navigationBars["Following"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tables["relationship.list.following"].exists)

        app.navigationBars.buttons.firstMatch.tap()
        let followers = app.buttons["profile.relationship.followers"]
        XCTAssertTrue(followers.waitForExistence(timeout: 3)); followers.tap()
        XCTAssertTrue(app.navigationBars["Followers"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tables["relationship.list.followers"].exists)
    }

    func testPlatformShortcutOpensPersistentUpdates() {
        let app = XCUIApplication(); launchSignedIn(app)
        app.buttons["main.tab.3"].tap()
        let platform = app.buttons["activity.service.platform"]
        XCTAssertTrue(platform.waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["activity.service.likes"].exists)
        XCTAssertFalse(app.buttons["activity.service.support"].exists)
        platform.tap()
        XCTAssertTrue(app.navigationBars["Platform updates"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tables["platform.updates.list"].exists)
    }

    func testProfileRemovesSignalAtelierWithoutAffectingStoreTools() {
        let app = XCUIApplication(); launchSignedIn(app)
        app.buttons["main.tab.4"].tap()
        XCTAssertFalse(app.buttons["profile.menu.signalatelier"].exists)
        XCTAssertFalse(app.buttons["profile.menu.safetycenter"].exists)
        XCTAssertTrue(app.buttons["profile.menu.store"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["profile.menu.backpack"].exists)
    }

    func testReelCopyChangesWithEachVideo() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-test-reset-reel-conversations"]; launchSignedIn(app)
        app.buttons["main.tab.0"].tap()
        XCTAssertTrue(app.staticTexts["reel.caption.sunlit-sidewalk.mp4"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["reel.caption.sunlit-sidewalk.mp4"].label, "Morning light and nowhere to rush.  ·  #citywalk #daylight")
        XCTAssertEqual(app.buttons["reel.comments"].value as? String, "2 replies")

        app.swipeUp()
        XCTAssertTrue(app.staticTexts["reel.caption.evening-driving-range.mp4"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["reel.caption.evening-driving-range.mp4"].label, "One last swing before the sky turns blue.  ·  #drivingrange")
        XCTAssertEqual(app.buttons["reel.comments"].value as? String, "4 replies")
    }

    func testDailyCoinDropCanOnlyBeCollectedOncePerDay() {
        let app = XCUIApplication()
        app.launchArguments = ["-didQuickLogin", "YES", "-acceptedLegalAgreements", "YES", "-loginMethod", "email", "-welcomeCoinsGranted", "YES", "-coins", "888", "-lookMe.interfaceLanguage", "en", "--ui-test-reset-daily-coin"]
        app.launch()
        XCTAssertTrue(app.buttons["Profile"].waitForExistence(timeout: 5)); app.buttons["Profile"].tap()
        let claim = app.buttons["profile.dailyCoinClaim"]
        XCTAssertTrue(claim.waitForExistence(timeout: 3)); XCTAssertTrue(claim.isEnabled); XCTAssertEqual(claim.label, "Claim")
        claim.tap()
        XCTAssertTrue(app.staticTexts["+50 coins"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Got it"].waitForExistence(timeout: 2)); app.buttons["Got it"].tap()
        let wallet = app.buttons["profile.coinVault"]
        XCTAssertTrue(wallet.waitForExistence(timeout: 2)); XCTAssertEqual(wallet.value as? String, "938 coins")
        XCTAssertFalse(claim.isEnabled); XCTAssertEqual(claim.label, "Collected")

        app.terminate(); launchSignedIn(app)
        app.buttons["Profile"].tap()
        let claimAfterRestart = app.buttons["profile.dailyCoinClaim"]
        XCTAssertTrue(claimAfterRestart.waitForExistence(timeout: 3)); XCTAssertFalse(claimAfterRestart.isEnabled); XCTAssertEqual(claimAfterRestart.label, "Collected")
        XCTAssertEqual(app.buttons["profile.coinVault"].value as? String, "938 coins")
    }

    func testLanguageChoicePersistsAndRebuildsTheInterface() {
        let app = XCUIApplication()
        app.launchArguments = ["-didQuickLogin", "YES", "-acceptedLegalAgreements", "YES", "-loginMethod", "email", "-lookMe.interfaceLanguage", "en"]
        app.launch()
        XCTAssertTrue(app.buttons["Profile"].waitForExistence(timeout: 5)); app.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["profile.settings"].waitForExistence(timeout: 3)); app.buttons["profile.settings"].tap()
        XCTAssertTrue(app.buttons["settings.language"].waitForExistence(timeout: 3)); app.buttons["settings.language"].tap()
        XCTAssertTrue(app.buttons["简体中文"].waitForExistence(timeout: 2)); app.buttons["简体中文"].tap()

        XCTAssertTrue(app.buttons["我的"].waitForExistence(timeout: 5)); app.buttons["我的"].tap()
        XCTAssertTrue(app.buttons["profile.settings"].waitForExistence(timeout: 3)); app.buttons["profile.settings"].tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "SimplifiedChineseSettings"; shot.lifetime = .keepAlways; add(shot)
    }

    func testDiscoveryHeaderStaysInsideCompactWidth() {
        let app = XCUIApplication(); launchSignedIn(app)
        let locator = app.buttons["discover.location"]
        XCTAssertTrue(locator.waitForExistence(timeout: 4))
        XCTAssertFalse(app.buttons["discover.category.Game"].exists)
        XCTAssertGreaterThanOrEqual(locator.frame.minX, 0)
        XCTAssertLessThanOrEqual(locator.frame.maxX, app.frame.maxX - 4)
        keepScreenshot(app, "Compact-DiscoveryHeader")
    }

    func testInterestRoomAudienceFiltersActuallySwitchTheList() {
        let app = XCUIApplication(); launchSignedIn(app)
        app.buttons["main.tab.2"].tap()
        let china = app.buttons["rooms.filter.China"]
        XCTAssertTrue(china.waitForExistence(timeout: 4)); china.tap()
        XCTAssertTrue(app.descendants(matching: .any)["room.card.late-night-cinema"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.descendants(matching: .any)["room.card.glow-after-dark"].exists)

        let spain = app.buttons["rooms.filter.Spain"]
        XCTAssertTrue(spain.exists); spain.tap()
        XCTAssertTrue(app.descendants(matching: .any)["room.card.city-pop-lounge"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.descendants(matching: .any)["room.card.late-night-cinema"].exists)
    }

    func testRoomComposerHeroOpensTheDesignGuide() {
        let app = XCUIApplication(); launchSignedIn(app)
        app.buttons["main.tab.2"].tap()
        let create = app.buttons["rooms.create"]
        XCTAssertTrue(create.waitForExistence(timeout: 4)); create.tap()
        let guide = app.buttons["roomComposer.guide"]
        XCTAssertTrue(guide.waitForExistence(timeout: 4)); guide.tap()
        XCTAssertTrue(app.staticTexts["Give the room a clear point of view"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["One specific promise"].exists)
        XCTAssertTrue(app.staticTexts["An easy first question"].exists)
        XCTAssertTrue(app.staticTexts["A calm hosting rhythm"].exists)
        app.buttons["roomGuide.close"].tap()
        XCTAssertTrue(app.textFields["Example: Sunday Photo Walk"].waitForExistence(timeout: 3))
    }

    func testGlobalCreateEntryOpensLiveAndVideoPublishingFlows() {
        let app = XCUIApplication(); launchSignedIn(app)
        let create = app.buttons["main.create"]
        XCTAssertTrue(create.waitForExistence(timeout: 4))
        XCTAssertLessThan(create.frame.maxY, app.buttons["main.tab.0"].frame.minY)
        create.tap()
        XCTAssertTrue(app.buttons["create.goLive"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["create.postVideo"].exists)

        app.buttons["create.postVideo"].tap()
        XCTAssertTrue(app.navigationBars["Post a video"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["moment.chooseVideo"].exists)
        XCTAssertTrue(app.buttons["moment.recordVideo"].exists)
        XCTAssertTrue(app.staticTexts["Share one clear moment."].exists)
        XCTAssertTrue(app.staticTexts["Reviewed before it appears"].exists)
        keepScreenshot(app, "Video-Composer-Redesign")
        app.navigationBars.buttons.firstMatch.tap()

        XCTAssertTrue(create.waitForExistence(timeout: 3)); create.tap()
        XCTAssertTrue(app.buttons["create.goLive"].waitForExistence(timeout: 3)); app.buttons["create.goLive"].tap()
        XCTAssertTrue(app.navigationBars["Go live"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.textFields["goLive.title"].exists)
        XCTAssertTrue(app.buttons["goLive.start"].exists)
    }

    func testDiscoveryUsesThemedSearchAndFiltersPeople() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-test-reset-reel-conversations"]; launchSignedIn(app)
        let search = app.buttons["discover.search"]
        XCTAssertTrue(search.waitForExistence(timeout: 4)); search.tap()
        XCTAssertTrue(app.staticTexts["Find someone"].waitForExistence(timeout: 3))
        let field = app.textFields["discover.search.field"]
        XCTAssertTrue(field.exists)
        keepScreenshot(app, "Discovery-Themed-Search")
        field.typeText("Mia Calder")
        app.buttons["discover.search.apply"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["discover.member.member-0"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.descendants(matching: .any)["discover.member.member-1"].exists)

        search.tap(); XCTAssertTrue(app.buttons["discover.search.reset"].waitForExistence(timeout: 3)); app.buttons["discover.search.reset"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["discover.member.member-1"].waitForExistence(timeout: 3))
    }

    func testPrimaryScreenLayoutAudit() {
        let app = XCUIApplication(); launchSignedIn(app)
        let regionLocator = app.buttons["discover.location"]
        XCTAssertTrue(regionLocator.waitForExistence(timeout: 4))
        XCTAssertLessThanOrEqual(regionLocator.frame.maxX, app.frame.maxX - 4)
        keepScreenshot(app, "Audit-01-Discover")

        let offlineMember = app.descendants(matching: .any)["discover.member.member-1"]
        XCTAssertTrue(offlineMember.waitForExistence(timeout: 4)); offlineMember.tap()
        XCTAssertTrue(app.navigationBars.buttons.firstMatch.waitForExistence(timeout: 3)); keepScreenshot(app, "Audit-02-ProfileDetail")
        app.navigationBars.buttons.firstMatch.tap()

        let liveCategory = app.buttons["discover.category.Live"]; XCTAssertTrue(liveCategory.waitForExistence(timeout: 3)); liveCategory.tap()
        sleep(1)
        let stableLiveMember = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'discover.member.'")).firstMatch
        XCTAssertTrue(stableLiveMember.waitForExistence(timeout: 3)); keepScreenshot(app, "Audit-03-LiveGrid"); stableLiveMember.tap()
        XCTAssertTrue(app.buttons["Close live room"].waitForExistence(timeout: 4)); sleep(1); keepScreenshot(app, "Audit-04-LiveRoom"); app.buttons["Close live room"].tap()

        app.buttons["main.tab.2"].tap(); XCTAssertTrue(app.buttons["rooms.create"].waitForExistence(timeout: 4)); keepScreenshot(app, "Audit-05-InterestRooms")
        let firstRoom = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'room.card.'")).firstMatch
        XCTAssertTrue(firstRoom.waitForExistence(timeout: 3)); firstRoom.tap()
        XCTAssertTrue(app.buttons["room.enter"].waitForExistence(timeout: 3)); keepScreenshot(app, "Audit-06-RoomInvitation")

        addUIInterruptionMonitor(withDescription: "Microphone") { alert in
            if alert.buttons.count > 0 { alert.buttons.element(boundBy: alert.buttons.count - 1).tap(); return true }
            return false
        }
        app.buttons["room.enter"].tap(); app.tap()
        if app.buttons["Leave voice room"].waitForExistence(timeout: 5) { keepScreenshot(app, "Audit-07-VoiceRoom") }

        app.terminate(); launchSignedIn(app)
        app.buttons["main.tab.3"].tap(); keepScreenshot(app, "Audit-08-ActivityInbox")
        app.buttons["main.tab.4"].tap(); XCTAssertTrue(app.buttons["profile.settings"].waitForExistence(timeout: 4)); keepScreenshot(app, "Audit-09-Profile")
        XCTAssertFalse(app.buttons["profile.menu.signalatelier"].exists)
        app.buttons["profile.settings"].tap(); keepScreenshot(app, "Audit-10-Settings")
        app.buttons["settings.language"].tap(); XCTAssertTrue(app.buttons["简体中文"].waitForExistence(timeout: 3)); keepScreenshot(app, "Audit-11-LanguagePicker"); app.buttons["Not now"].tap()

        app.terminate(); launchSignedIn(app)
        app.buttons["main.tab.0"].tap()
        let likeButton = app.buttons["reel.like"]
        XCTAssertTrue(likeButton.waitForExistence(timeout: 4))
        XCTAssertEqual(likeButton.value as? String, "Not liked")
        keepScreenshot(app, "Audit-12-Reels")
        let reelAvatar = app.buttons["reel.avatar"]
        XCTAssertTrue(reelAvatar.waitForExistence(timeout: 3)); reelAvatar.tap()
        XCTAssertTrue(app.navigationBars.buttons.firstMatch.waitForExistence(timeout: 4))
        keepScreenshot(app, "Audit-13-ReelProfileDetail")
    }

    func testLiveCardOpensSameRoomFromAllAndLiveCategories() {
        let app = XCUIApplication(); launchSignedIn(app)
        let liveMember = app.descendants(matching: .any)["discover.member.member-0"]
        XCTAssertTrue(liveMember.waitForExistence(timeout: 4)); liveMember.tap()
        XCTAssertTrue(app.buttons["Close live room"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Mia Calder"].exists)
        app.buttons["Close live room"].tap()

        let liveCategory = app.buttons["discover.category.Live"]
        XCTAssertTrue(liveCategory.waitForExistence(timeout: 3)); liveCategory.tap()
        XCTAssertTrue(liveMember.waitForExistence(timeout: 3)); liveMember.tap()
        XCTAssertTrue(app.buttons["Close live room"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Mia Calder"].exists)
    }

    func testLiveRoomHostAvatarOpensMatchingProfileAndReturnsToRoom() {
        let app = XCUIApplication(); launchSignedIn(app)
        let liveMember = app.descendants(matching: .any)["discover.member.member-0"]
        XCTAssertTrue(liveMember.waitForExistence(timeout: 4)); liveMember.tap()
        let hostAvatar = app.buttons["live.hostAvatar"]
        XCTAssertTrue(hostAvatar.waitForExistence(timeout: 4)); hostAvatar.tap()
        XCTAssertTrue(app.staticTexts["Mia Calder, 22"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["Close profile"].exists); app.buttons["Close profile"].tap()
        XCTAssertTrue(app.buttons["Close live room"].waitForExistence(timeout: 4))
    }

    func testLiveAndVoiceRoomsExposeActiveRoomSpecificTimelines() {
        let app = XCUIApplication(); launchSignedIn(app)
        let liveMember = app.descendants(matching: .any)["discover.member.member-0"]
        XCTAssertTrue(liveMember.waitForExistence(timeout: 4)); liveMember.tap()
        XCTAssertTrue(app.staticTexts["live.viewerCount"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["live.appreciationCount"].exists)
        XCTAssertTrue(app.staticTexts["live.roomPrompt"].exists)
        XCTAssertTrue(app.staticTexts["live.bulletin"].exists)
        XCTAssertTrue(app.staticTexts["live.giftActivity"].exists)
        XCTAssertFalse(app.buttons["Mute"].exists)
        keepScreenshot(app, "LiveRoom-ActivityTimeline")
        app.buttons["Close live room"].tap()

        app.buttons["main.tab.2"].tap()
        let room = app.descendants(matching: .any)["room.card.glow-after-dark"]
        XCTAssertTrue(room.waitForExistence(timeout: 4)); room.tap()
        XCTAssertTrue(app.buttons["room.enter"].waitForExistence(timeout: 3))
        addUIInterruptionMonitor(withDescription: "Microphone") { alert in
            if alert.buttons.count > 0 { alert.buttons.element(boundBy: alert.buttons.count - 1).tap(); return true }
            return false
        }
        app.buttons["room.enter"].tap(); app.tap()
        XCTAssertTrue(app.buttons["Leave voice room"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["voice.message.ambient"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["voice.giftActivity"].exists)
        keepScreenshot(app, "VoiceRoom-ActivityTimeline")
    }

    func testReelCommentsSupportSafetyAndMyReplyUsesMyAvatar() {
        let app = XCUIApplication()
        app.launchArguments = ["-didQuickLogin", "YES", "-acceptedLegalAgreements", "YES", "-loginMethod", "email", "-welcomeCoinsGranted", "YES", "-nickname", "Avery Lane", "-lookMe.interfaceLanguage", "en", "--ui-test-reset-reel-conversations"]
        app.launch()
        XCTAssertTrue(app.buttons["main.tab.0"].waitForExistence(timeout: 6)); app.buttons["main.tab.0"].tap()
        let comments = app.buttons["reel.comments"]
        if !comments.waitForExistence(timeout: 2) { app.buttons["main.tab.0"].tap() }
        XCTAssertTrue(comments.waitForExistence(timeout: 4)); XCTAssertEqual(comments.value as? String, "2 replies"); comments.tap()

        XCTAssertTrue(app.staticTexts["Community replies · 2"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["The morning light makes this whole street feel cinematic."].exists)
        XCTAssertTrue(app.images["comment.avatar.member-8"].exists)
        let input = app.textFields["comments.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 2)); input.tap(); input.typeText("The tree-lined view feels wonderfully calm.")
        app.buttons["comments.send"].tap()
        XCTAssertTrue(app.staticTexts["The tree-lined view feels wonderfully calm."].waitForExistence(timeout: 3))
        let myAvatar = app.images["comment.avatar.me"]
        XCTAssertTrue(myAvatar.exists); XCTAssertEqual(myAvatar.value as? String, "riverside-black-dress.jpg")

        let firstSafety = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'comment.safety.'")).firstMatch
        XCTAssertTrue(firstSafety.exists); firstSafety.tap()
        XCTAssertTrue(app.buttons["Report"].waitForExistence(timeout: 2)); XCTAssertTrue(app.buttons["Block user"].exists); app.buttons["Report"].tap()
        XCTAssertTrue(app.buttons["Submit report"].waitForExistence(timeout: 2)); app.buttons["Submit report"].tap()
        XCTAssertTrue(app.staticTexts["Report received"].waitForExistence(timeout: 3)); app.buttons["Got it"].tap()
        XCTAssertTrue(app.staticTexts["Community replies · 2"].waitForExistence(timeout: 3))

        let nextSafety = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'comment.safety.'")).firstMatch
        XCTAssertTrue(nextSafety.exists); nextSafety.tap()
        XCTAssertTrue(app.buttons["Block user"].waitForExistence(timeout: 2)); app.buttons["Block user"].tap()
        XCTAssertTrue(app.staticTexts["Blocked"].waitForExistence(timeout: 3)); app.buttons["Got it"].tap()
        XCTAssertTrue(app.staticTexts["Community replies · 1"].waitForExistence(timeout: 3))
    }
}
