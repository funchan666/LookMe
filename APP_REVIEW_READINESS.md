# LookMe App Review Readiness

Audit date: 2026-08-17

This document records product and code readiness against the current Apple requirements most relevant to LookMe. It is not a guarantee of App Review approval.

## Review baseline

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines: Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy)
- [Requesting access to protected resources](https://developer.apple.com/documentation/UIKit/requesting-access-to-protected-resources)
- [Requesting authorization to capture and save media](https://developer.apple.com/documentation/avfoundation/requesting-authorization-to-capture-and-save-media)

## Guideline 4.3 — Design and product differentiation

Current risk: **reduced, not eliminated**.

Product-specific evidence now present:

- Signal Atelier: a curated, 24-hour social-intent canvas with tempo and visual-field choices.
- Persistent interest-room creation and re-entry rather than a non-functional room draft.
- Mutual-follow conversation doorway and per-profile conversation context.
- Dedicated story reels, live rooms, voice rooms, community moments, effect boutique, activity inbox, and Coin Vault flows.
- Product-specific community models and vocabulary instead of generic `UserModel`, `DataModel`, or `ViewModel` structures.
- Original LookMe visual asset, distinct semantic asset names, bundled typography, and separate media assignments for reels and live rooms.
- All supplied 48 image assets and 17 videos are mapped into product experiences; reel and live video sets do not overlap.

Remaining actions before submission:

- Ensure App Store screenshots and description explain Signal Atelier and interest rooms as core value, not as a generic social clone.
- Test the signed Release archive on physical devices and review the final compiled asset catalog.
- Do not submit another substantially equivalent app, metadata set, or screenshot set under any account.

## Guideline 1.1.4 — Objectionable content

Current risk: **controlled in the client; server enforcement still required for production UGC**.

Implemented:

- Curated bundled media was visually reviewed; no obvious explicit or pornographic content was found.
- `LookMeContentPolicy` classifies sexual solicitation, threats or self-harm, targeted abuse, scam/contact spam, repeated noise, and excessive length.
- Moment, comment, message, and room entry points call the content policy before persistence.
- Community rules prohibit sexual exploitation, graphic violence, harassment, hate, scams, spam, dangerous activity, and exploitative content involving minors.

Required production control:

- Re-run media and copy review whenever bundled content changes.
- Enforce equivalent or stronger content policy on the server. Client-only filtering can be bypassed.

## Guideline 1.2 — User-generated content

Current risk: **not submission-ready without a real moderation service**.

Implemented in the client:

- No anonymous or random-chat flow.
- Messages and calls require independently established mutual follows and are checked again at action time.
- Reports require a reason, persist, hide the reported item, and refresh visible lists.
- Blocking persists and hides the profile, its content, and conversation surfaces; the blacklist supports unblocking.
- Dynamic comments, reels, live rooms, profiles, conversations, and room messages expose safety actions.
- New moments remain pending rather than becoming publicly visible immediately.

Production blockers:

1. Connect reports to a real moderation queue with review ownership, response times, evidence retention, and enforcement. Local hide-only behavior does not satisfy the full requirement for timely response.
2. Connect pending moments to real review and approval. A permanently pending local record is not a production moderation workflow.
3. Publish and verify a reachable support contact in the policy pages and App Store metadata.
4. Enforce blocks, relationship state, and content removal on the server and across devices.
5. Provide reviewers a fully functional moderation test path and test account where required.

## Permissions and privacy

Implemented:

- Camera, microphone, and location are requested only after an explicit user action that needs the capability.
- The first denial quietly ends the attempted action.
- A neutral Settings choice appears only after the user later retries an action while access is already denied.
- LookMe never opens Settings automatically.
- Media-library selection uses `PHPickerViewController`, avoiding unnecessary broad photo-library permission.
- Purpose strings describe the feature that uses each capability.

Purpose strings:

- Camera: taking a photo, recording a video, or starting a video call.
- Microphone: speaking in a room, recording video sound, or starting a call.
- Location: explicitly tuning discovery to the current region.

## Purchases and account capabilities

- StoreKit 1 is used.
- The seven required product identifiers and prices remain unchanged; two additional consumable options are included.
- The tapped product is fetched from the App Store only after the user selects it.
- Transaction completion is idempotent by transaction identifier.
- No VIP feature remains.
- Messaging, follows, comments, and voice/video calls never consume coins.
- Coin spending is limited to optional live/room gifts, entrance effects, profile aura drops, and Signal Atelier visual fields.

External setup still required:

- Create and approve matching consumable products in App Store Connect.
- Verify product pricing/localization and purchases with a Sandbox Apple ID on a signed physical-device build.
- Verify Sign in with Apple provisioning, capability, first authorization, repeat authorization, revoked credentials, and name persistence on a signed build.

## Local typography and resources

- `Quicksand-Variable.ttf` is used for friendly UI copy.
- `SpaceGrotesk-Variable.ttf` is used for expressive display copy.
- Both OFL license files ship with the project.
- Resource directories and filenames use English, content-specific names.
- Images were metadata-stripped and compressed; videos were re-encoded to H.264/AAC while retaining every supplied asset.
- Current resource footprint is approximately 79 MB.

## Interface localization

- Five persistent interface languages ship as native `.lproj` resources: English, Simplified Chinese, Spanish, Japanese, and German.
- The first launch follows a supported device language and otherwise falls back to English.
- A themed language selector in Settings applies the choice immediately without changing account, relationship, message, safety, or coin state.
- Login, profile, discovery, rooms, activity tabs, Coin Vault, core safety actions, and Settings use the shared localization layer.
- The hosted Terms of Service and Privacy Policy retain the language published on their configured web pages.

## Verification evidence

- `xcodebuild build test`: succeeded.
- Unit tests: 8 passed, 0 failed.
- UI tests: 7 passed, 0 failed, including a 14-screen primary-layout and navigation screenshot audit plus a compact-width header check.
- `xcodebuild analyze`: succeeded; no application-code analyzer warnings remain.
- Automated checks cover media mapping, product identifiers/prices, content-policy categories, login validation, legal URLs, semantic profile data, five bundled language packs, persistent live language switching, welcome coins, Coin Vault content, and agreement gating.
