//
//  Localizing.swift
//
//
//  Created by Amir Abbas Mousavian on 9/16/23.
//

import Foundation

extension Bundle {
    func forLocale(_ locale: Locale) -> Bundle {
        if let url = urls(forResourcesWithExtension: "stringsdict", subdirectory: nil, localization: locale.identifier)?.first?.baseURL {
            return Bundle(url: url) ?? .module
        } else if let url = Bundle.module.urls(forResourcesWithExtension: "stringsdict", subdirectory: nil, localization: locale.languageCode)?.first?.baseURL {
            return Bundle(url: url) ?? .module
        }
        return .module
    }
}

extension String {
    init(localizingKey key: String) {
        let bundle: Bundle
        if JSONWebKit.locale != .autoupdatingCurrent, JSONWebKit.locale != .current {
            bundle = Bundle.module.forLocale(JSONWebKit.locale)
        } else {
            bundle = Bundle.module
        }
        self = bundle.localizedString(forKey: key, value: nil, table: nil)
    }
    
    init(localizingKey key: String, _ arguments: CVarArg...) {
        self = .init(format: .init(localizingKey: key), arguments: arguments)
    }
    
    init(localizingKey key: String, arguments: [CVarArg]) {
        self = .init(format: .init(localizingKey: key), arguments: arguments)
    }
}

extension Locale {
    fileprivate var languageIdentifier: String? {
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, *) {
            return language.languageCode?.identifier
        } else {
            return languageCode
        }
    }
    
    fileprivate var countryCode: String? {
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, *) {
            return region?.identifier
        } else {
            return regionCode
        }
    }
    
    fileprivate var writeScript: String? {
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, *) {
            return language.script?.identifier
        } else {
            return scriptCode
        }
    }
    
    var bcp47: String {
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, *) {
            return identifier(.bcp47)
        } else {
            return identifier.replacingOccurrences(of: "_", with: "-")
        }
    }
    
    init(bcp47: String) {
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, *) {
            self.init(components: .init(identifier: bcp47))
        } else {
            self.init(identifier: bcp47.replacingOccurrences(of: "-", with: "_"))
        }
    }
    
    func bestMatch(in locales: [Locale]) -> Locale? {
        guard !locales.isEmpty, let languageIdentifier = languageIdentifier else { return nil }
        let matchedLanguages = locales.filter { $0.languageIdentifier == languageIdentifier }
        switch matchedLanguages.count {
        case 0:
            return nil
        case 1:
            return matchedLanguages[0]
        default:
            break
        }
        let matchedScript: [Locale]
        if let writeScript = writeScript {
            matchedScript = matchedLanguages.filter { $0.writeScript == writeScript }
            switch matchedScript.count {
            case 0:
                return matchedLanguages[0]
            case 1:
                return matchedScript[0]
            default:
                break
            }
        } else {
            matchedScript = matchedLanguages
        }
        if let countryCode = countryCode {
            let matchedCountry = matchedScript.filter { $0.countryCode == countryCode }
            switch matchedCountry.count {
            case 0:
                return matchedScript[0]
            default:
                return matchedCountry[0]
            }
        } else {
            return matchedScript[0]
        }
    }
}
