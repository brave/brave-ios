// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

class Unzip {
    private static let zipChunkSize = 512
    
    public static func unpack_archive(data: Data, to toPath: String) throws {
        guard let path = URL(string: toPath) else {
            throw "Invalid Destination Path: \(toPath)"
        }
        
        var data = data
        let count = data.count
        let archive = archive_read_new()
        archive_read_support_format_all(archive)
        archive_read_support_compression_all(archive)
        
        if data.withUnsafeMutableBytes({ archive_read_open_memory(archive, $0.baseAddress, count) }) != ARCHIVE_OK {
            throw String(cString: archive_error_string(archive), encoding: .utf8) ?? "Error Reading Archive"
        }
        
        while true {
            var entry: OpaquePointer?
            let result = archive_read_next_header(archive, &entry)
            if result == ARCHIVE_EOF {
                break
            }
            
            if result != ARCHIVE_OK {
                throw String(cString: archive_error_string(archive), encoding: .utf8) ?? "Unknown Error Reading Archive Entry Header"
            }
            
            guard let entryName = String(cString: archive_entry_pathname(entry), encoding: .utf8) else {
                throw "Invalid Zip Entry Name"
            }
            
            let toPath = path.appendingPathComponent(entryName).absoluteString
            if !FileManager.default.createFile(atPath: toPath, contents: Data(), attributes: nil) {
                throw "Cannot Create Zip Entry File"
            }
            
            guard let fileHandle = FileHandle(forWritingAtPath: toPath) else {
                throw "Cannot Write Zip Entry"
            }
            
            if archive_read_data_into_fd(archive, fileHandle.fileDescriptor) != ARCHIVE_OK { //read_data_into_buffer
                fileHandle.closeFile()
                throw String(cString: archive_error_string(archive), encoding: .utf8) ?? "Unknown Error Reading Archive Entry into File Descriptor"
            }
            
            fileHandle.closeFile()
        }
        
        if archive_read_close(archive) != ARCHIVE_OK {
            throw String(cString: archive_error_string(archive), encoding: .utf8) ?? "Unknown Error Closing Archive"
        }
    }

    public static func unpack_archive(from fromPath: String, to toPath: String) throws {
        guard let path = URL(string: toPath) else {
            throw "Invalid Destination Path: \(toPath)"
        }
        
        let archive = archive_read_new()
        archive_read_support_format_all(archive)
        archive_read_support_compression_all(archive)
        
        guard let archiveHandle = FileHandle(forReadingAtPath: fromPath) else {
            throw "Invalid FileHandle for Reading Path: \(fromPath)"
        }
        
        do {
            try FileManager.default.createDirectory(atPath: toPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            archiveHandle.closeFile()
            throw error
        }
        
        if archive_read_open_fd(archive, archiveHandle.fileDescriptor, Unzip.zipChunkSize) != ARCHIVE_OK {
            archiveHandle.closeFile()
            throw String(cString: archive_error_string(archive), encoding: .utf8) ?? "Unknown Error Reading Archive at Path: \(fromPath)"
        }
        
        while true {
            var entry: OpaquePointer?
            let result = archive_read_next_header(archive, &entry)
            if result == ARCHIVE_EOF {
                break
            }
            
            if result != ARCHIVE_OK {
                throw String(cString: archive_error_string(archive), encoding: .utf8) ?? "Unknown Error Reading Archive Entry Header"
            }
            
            guard let entryName = String(cString: archive_entry_pathname(entry), encoding: .utf8) else {
                throw "Invalid Zip Entry Name"
            }
            
            let toPath = path.appendingPathComponent(entryName).absoluteString
            if !FileManager.default.createFile(atPath: toPath, contents: Data(), attributes: nil) {
                throw "Cannot Create Zip Entry File"
            }
            
            guard let fileHandle = FileHandle(forWritingAtPath: toPath) else {
                throw "Cannot Write Zip Entry"
            }
            
            if archive_read_data_into_fd(archive, fileHandle.fileDescriptor) != ARCHIVE_OK {
                fileHandle.closeFile()
                archiveHandle.closeFile()
                throw String(cString: archive_error_string(archive), encoding: .utf8) ?? "Unknown Error Reading Archive Entry into File Descriptor"
            }
            
            fileHandle.closeFile()
        }
        
        archiveHandle.closeFile()
        if archive_read_close(archive) != ARCHIVE_OK {
            throw String(cString: archive_error_string(archive), encoding: .utf8) ?? "Unknown Error Closing Archive"
        }
    }
}
