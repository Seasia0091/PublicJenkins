// This file contains the fastlane.tools configuration
// You can find the documentation at https://docs.fastlane.tools
//
// For a list of all available actions, check out
//
//     https://docs.fastlane.tools/actions
//

import Foundation

/* Configuration */
protocol Configuration {
    /// file name of the certificate
    var certificate: String { get }

    /// file name of the provisioning profile
    var provisioningProfile: String { get }

    /// configuration name in xcode project
    var buildConfiguration: String { get }

    /// the app id for this configuration
    var appIdentifier: String { get }

    /// export methods, such as "ad-doc" or "appstore"
    var exportMethod: String { get }
}

struct Staging: Configuration {
    var certificate = "ios_distribution"
    var provisioningProfile = "Jenkins_Production"
    var buildConfiguration = "Release"
    var appIdentifier = "com.seasia.jenkins"
    var exportMethod = "enterprise"
}

struct Production: Configuration {
    var certificate = "ios_distribution"
    var provisioningProfile = "Jenkins_Production"
    var buildConfiguration = "Release"
    var appIdentifier = "com.seasia.jenkins"
    var exportMethod = "enterprise"
}

struct Release: Configuration {
    var certificate = "ios_distribution"
    var provisioningProfile = "Jenkins_Production"
    var buildConfiguration = "Release"
    var appIdentifier = "com.seasia.jenkins"
    var exportMethod = "enterprise"
}

enum ProjectSetting {

    static var workspace = "JenkinsExample.xcworkspace"
    static var project = "JenkinsExample.xcodeproj"
    static var scheme = "JenkinsExample"
    static var target = "JenkinsExample"
    static var productName = "JenkinsExample"
    static let devices: [String] = ["iPhone 8", "iPad Air"]
    static let codeSigningPath = environmentVariable(get: "CODESIGNING_PATH").replacingOccurrences(of: "\"", with: "")
    static let keyChainDefaultPath = "/Users/paramvir/Library/Keychains"
    static let certificatePassword = "123456"
    static let sdk = "iphoneos11.2"

}

/* Lanes */
class Fastfile: LaneFile {
    var stubKeyChainPassword: String = "mind@123"

    var keyChainName: String {
        return "\(ProjectSetting.productName).keychain"
    }

    var keyChainDefaultFilePath: String {
        return "\(ProjectSetting.keyChainDefaultPath)/\(keyChainName)-db"
    }

    func beforeAll() {
        cocoapods()
    }

    func package(config: Configuration) {
        if FileManager.default.fileExists(atPath: keyChainDefaultFilePath) {
            deleteKeychain(name: keyChainName)
        }

        createKeychain(
            name: keyChainName,
            password: stubKeyChainPassword,
            defaultKeychain: false,
            unlock: true,
            timeout: 3600,
            lockWhenSleeps: true
        )

        importCertificate(
            keychainName: keyChainName,
            keychainPassword: stubKeyChainPassword,
            certificatePath: "\(ProjectSetting.codeSigningPath)/\(config.certificate).p12",
            certificatePassword: ProjectSetting.certificatePassword
        )

        updateProjectProvisioning(
            xcodeproj: ProjectSetting.project,
            profile: "\(ProjectSetting.codeSigningPath)/\(config.provisioningProfile).mobileprovision",
            targetFilter: "^\(ProjectSetting.target)$",
            buildConfiguration: config.buildConfiguration
        )

       // runTests(workspace: ProjectSetting.workspace,
           // devices: ProjectSetting.devices,
           // scheme: ProjectSetting.scheme)

        buildApp(
            workspace: ProjectSetting.workspace,
            scheme: ProjectSetting.scheme,
            clean: true,
            outputDirectory: "./",
            outputName: "\(ProjectSetting.productName).ipa",
            configuration: config.buildConfiguration,
            silent: true,
            exportMethod: config.exportMethod,
            exportOptions: [
                "signingStyle": "manual",
                "provisioningProfiles": [config.appIdentifier: config.provisioningProfile] ],
            sdk: ProjectSetting.sdk,
            skipProfileDetection: true

        )

        //deleteKeychain(name: keyChainName)
    }

    func developerReleaseLane() {
        desc("Create a developer release")
        package(config: Staging())

        crashlytics(
            ipaPath: "./\(ProjectSetting.productName).ipa",
            apiToken:"c272a718f7390ca96d2670a946ddc80cd6d5cea2",
            buildSecret:"c610e31e5a08062c4a38bc3f17378b448fe6d5958471ab0ccf7bfee85e78e956"
        )

//        crashlytics(
//            ipaPath: "./\(ProjectSetting.productName).ipa",
//            apiToken: environmentVariable(get: "CRASHLYTICS_API_KEY").replacingOccurrences(of: "\"", with: ""),
//            buildSecret: environmentVariable(get: "CRASHLYTICS_BUILD_SECRET").replacingOccurrences(of: "\"", with: "")
//        )
    }

    func qaReleaseLane() {
        desc("Create a weekly release")
        package(config: Production())
        crashlytics(
            ipaPath: "./\(ProjectSetting.productName).ipa",
            apiToken:"c272a718f7390ca96d2670a946ddc80cd6d5cea2",
            buildSecret:"c610e31e5a08062c4a38bc3f17378b448fe6d5958471ab0ccf7bfee85e78e956"
        )
//        crashlytics(
//            ipaPath: "./\(ProjectSetting.productName).ipa",
//            apiToken: environmentVariable(get: "CRASHLYTICS_API_KEY").replacingOccurrences(of: "\"", with: ""),
//            buildSecret: environmentVariable(get: "CRASHLYTICS_BUILD_SECRET").replacingOccurrences(of: "\"", with: "")
//        )
    }

}

