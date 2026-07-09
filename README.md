#NodeDa Kit

**Current version: `1.1.0`** &nbsp;·&nbsp; available at runtime as `Nrova.version`.

The official Swift package for the **Nrova** HTTP APIs. One typed
client, one auth scheme, every public service Nrova exposes — built
on `async`/`await`, `Codable`, and pure `URLSession`. No third-party
dependencies.

```swift
import Nrova

// Reads `NrovaAPIKey` (and optional `NrovaOrganizationId`) from Info.plist.
let client = try NrovaClient.fromInfoPlist()

let latest = try await client.distribution.latest(
    appId: "acme-notes",
    platform: .macos,
    channel: .stable
)
print("Latest version:", latest.artifact.version ?? latest.release.version)
print("SDK version:", Nrova.version) // "1.0.0"
```

## Table of contents

- [Version](#version)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration via Info.plist](#configuration-via-infoplist)
- [Authentication](#authentication)
- [Top-level client](#top-level-client)
- [Services](#services)
  - [Distribution API](#distribution-api)
  - [Support API](#support-api)
  - [Sales API](#sales-api)
  - [Careers API](#careers-api)
  - [Newsroom API](#newsroom-api)
  - [Feature Flags API](#feature-flags-api)
  - [System Status API](#system-status-api)
  - [Legal Policies API](#legal-policies-api)
- [Error handling](#error-handling)
- [Custom transports & testing](#custom-transports--testing)
- [Configuration reference](#configuration-reference)
- [License](#license)

---

## Version

| | |
| --- | --- |
| **SDK version** | `1.0.0` |
| **Runtime constant** | `Nrova.version` |
| **Schema** | `nrova.distribution.v1` (Distribution API) |

`Nrova.version` is updated in lockstep with the released git tag — log
it at startup to make support tickets easier to triage:

```swift
print("Nrova SDK \(Nrova.version) booted at \(Date())")
```

## Requirements

| Platform | Minimum |
| --- | --- |
| iOS | 15.0 |
| macOS | 12.0 |
| tvOS | 15.0 |
| watchOS | 8.0 |
| visionOS | 1.0 |
| Swift | 5.9+ |

Tested on Swift 6.x. No third-party dependencies — only Foundation.

## Installation

### Swift Package Manager (Xcode)

1. **File → Add Package Dependencies…**
2. Paste the repo URL: `https://github.com/Nrova-LLC/Nrova-Swift.git`
3. **Dependency Rule:** *Up to Next Major Version* → **`1.0.0`**
4. Add the `Nrova` product to your app target.

### Swift Package Manager (`Package.swift`)

Pin to the **1.x** line:

```swift
dependencies: [
    .package(
        url: "https://github.com/Nrova-LLC/Nrova-Swift.git",
        from: "1.0.0"          // 1.0.0 ≤ Nrova < 2.0.0
    )
]
```

Then declare the dependency on the `Nrova` library:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "Nrova", package: "Nrova-Swift")
    ]
)
```

## Configuration via Info.plist

> **Don't hardcode your API key.** Drop it into your target's
> `Info.plist` and load it with
> `NrovaClient.fromInfoPlist()` — that way you keep secrets out of
> source control and out of compiled binaries (e.g. via per-build
> `.xcconfig` or CI substitution).

### 1. Add the keys

Open your app target's `Info.plist` in Xcode and add:

| Key | Type | Required | Description |
| --- | --- | --- | --- |
| `NrovaAPIKey` | String | ✅ | API key issued by the Nrova dashboard. |
| `NrovaOrganizationId` | String | ✅ recommended | The in-source default (`NrovaConfiguration.defaultOrganizationId`) is a placeholder decoy — production apps must override it with their real organization id. |

Source-level equivalent:

```xml
<key>NrovaAPIKey</key>
<string>sk_live_replace_me</string>

<key>NrovaOrganizationId</key>
<string>YOUR_ORG_ID_HERE</string>
```

### 2. Build the client

```swift
import Nrova

@main
struct MyApp: App {
    let nrova: NrovaClient

    init() {
        do {
            self.nrova = try NrovaClient.fromInfoPlist()
        } catch {
            fatalError("Nrova: \(error.localizedDescription)")
        }
    }

    var body: some Scene { /* … */ }
}
```

`fromInfoPlist()` throws `NrovaConfiguration.InfoPlistError` if the
required entries are missing — fail fast at launch instead of
mysteriously 401'ing later:

```swift
do {
    let client = try NrovaClient.fromInfoPlist()
} catch NrovaConfiguration.InfoPlistError.missingAPIKey(let key, _) {
    print("Add `\(key)` to Info.plist before launching.")
}
```

### 3. (Optional) Rename the plist keys

If you want to namespace under your app's bundle identifier:

```swift
let keys = NrovaConfiguration.InfoPlistKeys(
    apiKey: "MyApp.NrovaAPIKey",
    organizationId: "MyApp.NrovaOrganizationId"
)
let client = try NrovaClient.fromInfoPlist(keys: keys)
```

### 4. (Optional) Keep the key out of `Info.plist` itself

For higher-security setups, leave `NrovaAPIKey` as `$(NROVA_API_KEY)`
in `Info.plist` and inject the real value via an `.xcconfig`
(`NROVA_API_KEY = $(NROVA_API_KEY_PROD)`) or CI environment variable
before the build. Xcode rewrites the placeholder at build time, so
the compiled binary still resolves it through `NrovaClient.fromInfoPlist()`.

### Loading from a non-Info.plist file

`NrovaConfiguration` can also be built from any in-memory dictionary
(useful for reading a custom plist, a JSON config, the Keychain, or a
remote config):

```swift
let plistURL = Bundle.main.url(forResource: "Nrova", withExtension: "plist")!
let data = try Data(contentsOf: plistURL)
let dictionary = try PropertyListSerialization
    .propertyList(from: data, options: [], format: nil) as! [String: Any]

let client = try NrovaClient.fromInfoDictionary(dictionary)
```

## Authentication

Every authenticated request sends **both** the `Authorization: Bearer
<key>` and `X-API-Key: <key>` headers — the API accepts either.
`GET /health` is the only endpoint that does not require a key, and
the Distribution API exposes a `GET /applications/public` feed that
is also unauthenticated.

The recommended path is the [Info.plist loader](#configuration-via-infoplist):

```swift
let client = try NrovaClient.fromInfoPlist()
```

If you absolutely need to construct the client by hand (CLI tools,
server-side Swift, tests) you can pass an explicit `apiKey` — but
read it from an environment variable, keychain, or remote config,
never a hardcoded string literal:

```swift
let env = ProcessInfo.processInfo.environment
guard let apiKey = env["NROVA_API_KEY"],
      let orgId  = env["NROVA_ORGANIZATION_ID"] else {
    fatalError("NROVA_API_KEY / NROVA_ORGANIZATION_ID missing from environment")
}
let client = NrovaClient(
    apiKey: apiKey,
    organizationId: orgId // never a hardcoded literal
)
```

Scopes you'll see across the SDK:

| Scope | Used by |
| --- | --- |
| `distribution:read` / `distribution:write` | `client.distribution` |
| `crm:support` | `client.support` |
| `crm:sales` | `client.sales` |
| `careers:read` / `careers:apply` | `client.careers` |
| `newsroom:read` / `newsroom:write` | `client.newsroom` |
| `flags:read` / `evaluate` | `client.featureFlags` |
| `status:read` / `status:write` | `client.systemStatus` |
| `legal:read` / `legal:write` | `client.legal` |

## Top-level client

`NrovaClient` is the entry point and exposes one strongly-typed
service per Nrova API:

```swift
client.distribution    // DistributionService
client.support         // SupportService
client.sales           // SalesService
client.careers         // CareersService
client.newsroom        // NewsroomService
client.featureFlags    // FeatureFlagsService
client.systemStatus    // SystemStatusService
client.legal           // LegalService
```

Quick health check across every service in parallel:

```swift
let client = try NrovaClient.fromInfoPlist()
let report = try await client.healthAll()
report.forEach { print("\($0.key): \($0.value.ok)") }
```

## Services

### Distribution API

Distribute Windows and macOS application binaries. Resolve the
latest release per `platform` + `channel`, list every published
release, fetch a direct download URL, publish a new release, or yank
one. Backed by `distributionApi`.

| Method | Endpoint | Scope |
| --- | --- | --- |
| `distribution.health()` | `GET /health` | none |
| `distribution.listPublicApplications()` | `GET /v1/organizations/{orgId}/applications/public` | **none** |
| `distribution.listApplications()` | `GET …/applications` | `distribution:read` |
| `distribution.getApplication(appId:)` | `GET …/applications/{appId}` | `distribution:read` |
| `distribution.listReleases(appId:channel:platform:limit:)` | `GET …/applications/{appId}/releases` | `distribution:read` |
| `distribution.getRelease(appId:releaseId:)` | `GET …/applications/{appId}/releases/{releaseId}` | `distribution:read` |
| `distribution.latest(appId:platform:channel:purpose:)` | `GET …/applications/{appId}/latest` | `distribution:read` |
| `distribution.resolveDownloadURL(appId:platform:channel:purpose:)` | `GET …/applications/{appId}/download` (302) | `distribution:read` |
| `distribution.icon(appId:format:)` | `GET …/applications/{appId}/icon` | `distribution:read` |
| `distribution.publishRelease(appId:request:)` | `POST …/applications/{appId}/releases` | `distribution:write` |
| `distribution.updateRelease(appId:releaseId:update:)` | `PATCH …/applications/{appId}/releases/{releaseId}` | `distribution:write` |

```swift
// Resolve the latest macOS stable release (auto-update .zip).
let latest = try await client.distribution.latest(
    appId: "acme-notes",
    platform: .macos,
    channel: .stable
)

// Or the user-facing installer (.dmg if uploaded, falls back to .zip).
let install = try await client.distribution.latest(
    appId: "acme-notes",
    platform: .macos,
    channel: .stable,
    purpose: .install
)

// Resolve the 302 redirect target without downloading the binary.
let downloadURL = try await client.distribution.resolveDownloadURL(
    appId: "acme-notes",
    platform: .macos
)

// Public feed (no API key required) for marketing sites.
let publicApps = try await client.distribution.listPublicApplications()

// Publish a new release.
let release = try await client.distribution.publishRelease(
    appId: "acme-notes",
    request: PublishReleaseRequest(
        version: "1.2.4",
        channel: .stable,
        buildNumber: "457",
        notes: "Adds quick capture from the menubar.",
        artifacts: [
            DistributionArtifact(
                platform: .macos,
                fileName: "Acme-Notes-1.2.4.zip",
                downloadUrl: "https://firebasestorage.googleapis.com/…",
                sizeBytes: 22_612_001,
                contentType: "application/zip",
                sha256: "<hex>",
                version: "1.2.4",
                buildNumber: "457",
                minOsVersion: "13.0",
                architecture: .universal,
                installPurpose: .update,
                metadataAutoDetected: false
            )
        ]
    )
)

// Yank a bad release.
try await client.distribution.updateRelease(
    appId: "acme-notes",
    releaseId: release.id,
    update: UpdateReleaseRequest(isYanked: true)
)
```

### Support API

Create and manage CRM support tickets. Backed by `crmSupportApi`.

| Method | Endpoint | Scope |
| --- | --- | --- |
| `support.health()` | `GET /health` | none |
| `support.createTicket(_:)` | `POST …/support/tickets` | `crm:support` |
| `support.listTickets(contactEmail:)` | `GET …/support/tickets` | `crm:support` |
| `support.getTicket(ticketId:)` | `GET …/support/tickets/{ticketId}` | `crm:support` |
| `support.listComments(ticketId:)` | `GET …/support/tickets/{ticketId}/comments` | `crm:support` |
| `support.addComment(ticketId:request:)` | `POST …/support/tickets/{ticketId}/comments` | `crm:support` |

```swift
let ticket = try await client.support.createTicket(
    CreateSupportTicketRequest(
        contactEmail: "user@example.com",
        applicationName: "Acme Notes",
        subject: "Sync stopped working",
        body: "Sync has been stuck on \"connecting\" for an hour.",
        priority: .high,
        category: .technical,
        environment: "macOS 14.4 (M3)"
    )
)

let comment = try await client.support.addComment(
    ticketId: ticket.id,
    request: CreateSupportCommentRequest(
        body: "Rebuilt your sync index — please try again.",
        authorDisplayName: "Acme Support"
    )
)
```

### Sales API

Capture marketing form submissions and run an inline conversation
with the lead. Backed by `crmSalesApi`.

| Method | Endpoint | Scope |
| --- | --- | --- |
| `sales.health()` | `GET /health` | none |
| `sales.createSubmission(_:)` | `POST …/sales/submissions` | `crm:sales` |
| `sales.listSubmissions(contactEmail:limit:)` | `GET …/sales/submissions` | `crm:sales` |
| `sales.getSubmission(submissionId:)` | `GET …/sales/submissions/{id}` | `crm:sales` |
| `sales.listComments(submissionId:)` | `GET …/sales/submissions/{id}/comments` | `crm:sales` |
| `sales.addComment(submissionId:request:)` | `POST …/sales/submissions/{id}/comments` | `crm:sales` |

```swift
let submission = try await client.sales.createSubmission(
    CreateSalesSubmissionRequest(
        contactEmail: "ada@example.com",
        formName: "contact_us",
        firstName: "Ada",
        lastName: "Lovelace",
        message: "Looking for a 50-seat licence for Acme Notes.",
        leadStatus: .new,
        leadSource: "website",
        company: "Analytical Engines Inc.",
        companySize: "11-50"
    )
)
```

### Careers API

Fetch open postings, render the dynamic application form, and submit
applications. Backed by `careersApi`.

| Method | Endpoint | Scope |
| --- | --- | --- |
| `careers.health()` | `GET /health` | none |
| `careers.listPostings()` | `GET …/careers/postings` | `careers:read` |
| `careers.getPosting(requisitionNodeId:)` | `GET …/careers/postings/{id}` | `careers:read` |
| `careers.applicationTemplate()` | `GET …/careers/application-template` | `careers:read` |
| `careers.listApplications(applicantEmail:contactEmail:status:limit:)` | `GET …/careers/applications` | `careers:read` |
| `careers.getApplication(applicationId:)` | `GET …/careers/applications/{id}` | `careers:read` |
| `careers.submitApplication(_:)` | `POST …/careers/applications` | `careers:apply` |

```swift
let template = try await client.careers.applicationTemplate()
let posting = try await client.careers.listPostings().first!

let application = try await client.careers.submitApplication(
    SubmitCareerApplicationRequest(
        requisitionNodeId: posting.requisitionNodeId,
        templateVersion: template.templateVersion,
        applicantEmail: "ada@example.com",
        answers: [
            "first_name": .string("Ada"),
            "last_name": .string("Lovelace"),
            "authorized_to_work": .string("yes"),
            "years_of_experience": .int(7)
        ]
    )
)
```

### Newsroom API

CMS for the public newsroom. Supports drafts, scheduled publishing,
markdown bodies, and an optional canonical `document` block.

| Method | Endpoint | Scope |
| --- | --- | --- |
| `newsroom.health()` | `GET /health` | none |
| `newsroom.listCategories()` | `GET …/newsroom/categories` | `newsroom:read` |
| `newsroom.listPosts(status:categoryId:tag:limit:includeDocument:)` | `GET …/newsroom/posts` | `newsroom:read` *(write to see drafts)* |
| `newsroom.getPost(idOrSlug:includeDocument:)` | `GET …/newsroom/posts/{idOrSlug}` | `newsroom:read` |
| `newsroom.createPost(_:)` | `POST …/newsroom/posts` | `newsroom:write` |
| `newsroom.updatePost(postId:update:)` | `PATCH …/newsroom/posts/{postId}` | `newsroom:write` |
| `newsroom.deletePost(postId:)` | `DELETE …/newsroom/posts/{postId}` | `newsroom:write` |

```swift
let categories = try await client.newsroom.listCategories()
let published = try await client.newsroom.listPosts(status: .published, limit: 20)

let draft = try await client.newsroom.createPost(
    CreateNewsroomPostRequest(
        title: "Acme Notes 1.2.4 ships today",
        categoryId: categories.first!.id,
        body: "## What's new\n\n- Quick capture from the menubar.",
        excerpt: "Quick capture and a faster sync.",
        tags: ["release", "macos"],
        status: .scheduled,
        scheduledFor: "2026-06-10T15:00:00.000Z"
    )
)
```

### Feature Flags API

Read flag definitions or evaluate them server-side for a given
subject. Backed by `developerApi`.

| Method | Endpoint | Scope |
| --- | --- | --- |
| `featureFlags.health()` | `GET /health` | none |
| `featureFlags.listFlags()` | `GET …/flags` | `flags:read` |
| `featureFlags.evaluate(_:)` | `POST …/evaluate` | `evaluate` |
| `featureFlags.isEnabled(flagKey:subjectId:countryCode:)` | `POST …/evaluate` (sugar) | `evaluate` |

```swift
let allFlags = try await client.featureFlags.listFlags()

let evaluation = try await client.featureFlags.evaluate(
    EvaluateFlagsRequest(
        subjectId: "user_42",
        countryCode: "US",
        flagKeys: ["dark_mode", "experimental_sync"]
    )
)
print(evaluation.results["dark_mode"] ?? false)

// One-liner sugar.
let darkMode = try await client.featureFlags.isEnabled(
    flagKey: "dark_mode",
    subjectId: "user_42"
)
```

### System Status API

Read or maintain the public status page components. Backed by
`systemStatusApi`.

| Method | Endpoint | Scope |
| --- | --- | --- |
| `systemStatus.health()` | `GET /health` | none |
| `systemStatus.rollup()` | `GET …/status` | `status:read` |
| `systemStatus.getComponent(componentId:)` | `GET …/status/components/{id}` | `status:read` |
| `systemStatus.createComponent(_:)` | `POST …/status/components` | `status:write` |
| `systemStatus.updateComponent(componentId:update:)` | `PUT …/status/components/{id}` | `status:write` |
| `systemStatus.deleteComponent(componentId:)` | `DELETE …/status/components/{id}` | `status:write` |

```swift
let rollup = try await client.systemStatus.rollup()
print("Overall status:", rollup.status ?? .unknown)
rollup.components.forEach { print(" •", $0.name ?? $0.id, $0.status ?? .unknown) }

// Mark a component degraded.
try await client.systemStatus.updateComponent(
    componentId: "api-edge",
    update: UpdateStatusComponentRequest(status: .degraded)
)
```

### Legal Policies API

CMS for legal policies (`privacy`, `privacy_choices`, `terms`).
Backed by `legalPoliciesApi`.

| Method | Endpoint | Scope |
| --- | --- | --- |
| `legal.health()` | `GET /health` | none |
| `legal.listPolicies()` | `GET …/legal-policies` | `legal:read` |
| `legal.getPolicy(byKey:)` | `GET …/legal-policies/by-key/{key}` | `legal:read` |
| `legal.getPolicy(byId:)` | `GET …/legal-policies/{id}` | `legal:read` |
| `legal.createPolicy(_:)` | `POST …/legal-policies` | `legal:write` |
| `legal.updatePolicy(policyId:update:)` | `PUT …/legal-policies/{id}` | `legal:write` |
| `legal.deletePolicy(policyId:)` | `DELETE …/legal-policies/{id}` | `legal:write` |
| `legal.createSection(policyId:request:)` | `POST …/legal-policies/{id}/sections` | `legal:write` |
| `legal.updateSection(policyId:sectionId:update:)` | `PUT …/legal-policies/{id}/sections/{sid}` | `legal:write` |
| `legal.deleteSection(policyId:sectionId:)` | `DELETE …/legal-policies/{id}/sections/{sid}` | `legal:write` |

```swift
let privacy = try await client.legal.getPolicy(byKey: LegalPolicyKey.privacy)
print(privacy.policy.title)
for section in privacy.sections.sorted(by: { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }) {
    print("##", section.title ?? "")
    print(section.body)
}
```

## Error handling

Every call throws `NrovaError`. The API-level failure case carries
the documented slug (`invalid_api_key`, `not_found`, …) so you can
branch on it without parsing strings:

```swift
do {
    _ = try await client.distribution.getApplication(appId: "missing")
} catch let NrovaError.api(error) where error.code == "not_found" {
    // App was recycled or never existed.
} catch let NrovaError.api(error) where error.status == 401 {
    // Bad / missing key.
} catch {
    // Transport, decoding, or unexpected status.
}
```

`NrovaError` cases:

- `invalidURL(String)` – path could not be composed (programmer error)
- `transport(Error)` – underlying `URLSession` failure
- `api(APIError)` – server returned a 4xx/5xx with a structured body
- `decoding(Error, data: Data?)` – successful response failed to decode
- `unexpectedStatus(Int, data: Data?)` – non-success status with no parsable body

## Custom transports & testing

The SDK talks to the network through the `NrovaTransport` protocol:

```swift
public protocol NrovaTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}
```

`URLSession` already conforms, but you can plug in your own:

```swift
struct LoggingTransport: NrovaTransport {
    let underlying: NrovaTransport
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        print("→", request.httpMethod ?? "?", request.url?.absoluteString ?? "")
        return try await underlying.send(request)
    }
}

let client = NrovaClient(
    apiKey: "…",
    transport: LoggingTransport(underlying: URLSession.shared)
)
```

This is also how the package tests stub the network — see
`Tests/NrovaTests/MockTransport.swift` for a reference
implementation.

## Configuration reference

The canonical way to build a configuration is from `Info.plist`
(see [Configuration via Info.plist](#configuration-via-infoplist)),
but the underlying struct is fully public if you need to compose it
manually:

```swift
let configuration = NrovaConfiguration(
    apiKey: keychainStoredKey,                                     // never hardcoded
    organizationId: NrovaConfiguration.defaultOrganizationId,
    endpoints: .production,                                        // override per-service URL for staging
    defaultHeaders: ["X-Trace-Id": traceId],
    timeout: 60
)

let client = NrovaClient(configuration: configuration)
```

You can also build it from any dictionary — handy when reading from a
custom plist, JSON file, or remote config:

```swift
let configuration = try NrovaConfiguration.fromInfoDictionary([
    "NrovaAPIKey": keychainStoredKey,
    "NrovaOrganizationId": tenantId
])
```

`ServiceEndpoints.production` returns the default URLs for every
service. To redirect a single service (handy for local development
against the emulator) replace just that URL:

```swift
var endpoints = ServiceEndpoints.production
endpoints.distribution = URL(string: "http://localhost:5001/nrovallc/us-central1/distributionApi")!
let configuration = NrovaConfiguration(apiKey: "local", endpoints: endpoints)
```

## License

Copyright © 2026 NodeDa LLC. All rights reserved.
