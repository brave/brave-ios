//
//  DomainParserDownloader.swift
//  DomainParser
//
//  Created by Jason Akakpo on 20/07/2018.
//  Copyright © 2018 Dashlane. All rights reserved.
//

// Run this script from terminal to update the PSL data file in Resource folder
import Foundation

enum ErrorType: Error {
    case notUTF8Convertible(data: Data)
    case fetchingError(details: Error?)
}
enum Result<T> {
    case success(T)
    case error(Error)
}


struct PublicSuffistListFetcher {
    typealias PublicSuffistListClosure = (Result<Data>) -> Void
    
    static let url = URL(string: "https://publicsuffix.org/list/public_suffix_list.dat")!
    func load(callback: @escaping PublicSuffistListClosure) {
        URLSession.shared.dataTask(with: PublicSuffistListFetcher.url) { (data, _, error) in
            do {
                guard let data = data else {
                    throw ErrorType.fetchingError(details: error)
                }
                try callback(.success(PublicSuffixListMinimifier(data: data).minimify()))
            } catch {
                callback(.error(error))
            }
            }.resume()
    }
}

struct PublicSuffixListMinimifier {
    
    
    let data: Data
    
    init(data: Data) {
        self.data = data
    }
    // A valid line is a non-empty, non-comment line
    func isLineValid(line: String) -> Bool {
        return !line.isEmpty && !line.starts(with: "//")
    }
    
    func minimify() throws -> Data {
        guard let stringifiedData = String.init(data: data, encoding: .utf8) else { throw ErrorType.notUTF8Convertible(data: data) }
        
        let validLinesArray = stringifiedData.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
            .compactMap { $0.components(separatedBy: CharacterSet.whitespaces).first }
            /// Filter out useless Lines (Comments or empty ones)
            .filter(isLineValid)
        
        return validLinesArray.joined(separator: "\n").data(using: .utf8)!
    }
}





func main() {
    let sema = DispatchSemaphore( value: 0)

    let fileRelativePath = "../Resources/public_suffix_list.dat"
    PublicSuffistListFetcher().load() { result in
        defer {
            sema.signal()
        }
        switch result {
        case let .success(data):
            let fileManager = FileManager.default
            let url = URL.init(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent(fileRelativePath)
            do {
                try data.write(to: url)
                print("Done :)")
                
            }
            catch { showError(error: error) }
        case let .error(error):
            showError(error: error)
        }
    }
    /// Wait for the Async Task finish
    sema.wait()
}

func showError(error: Error) {
    print("Unexpected Error occured: \(error)")
}

main()
