//
//  PDS.swift
//  macSup2Srt
//
//  Created by Ethan Dye on 9/7/2024.
//  Copyright © 2024 Ethan Dye. All rights reserved.
//

import Foundation
import simd

public class PDS {
    private var id: UInt8 = 0
    private var version: UInt8 = 0
    private var palette = [UInt8](repeating: 0, count: 1024)

    init(_ data: Data) throws {
        guard data.count >= 8 else {
            throw PGSError.invalidFormat
        }
        id = data[0]
        version = data[1]
        try parsePDS(data)
    }

    public func getID() -> UInt8 {
        return id
    }

    public func getVersion() -> UInt8 {
        return version
    }

    public func getPalette() -> [UInt8] {
        return palette
    }

    /// Parses the Palette Definition Segment (PDS) to extract the RGBA palette.
    /// PDS structure:
    ///   1 byte: Segment Type (0x16); already checked by the caller
    ///   1 byte: Palette ID
    ///   1 byte: Palette Version
    ///   Followed by a series of palette entries:
    ///       Each entry is 5 bytes: (Index, Y, Cr, Cb, Alpha)
    private func parsePDS(_ data: Data) throws {
        // Start reading after the first 2 bytes (Palette ID and Version)
        if (data.count - 2) % 5 != 0 {
            print("Invalid Palette Data Segment Length: \(data.count)")
            throw PGSError.invalidFormat
        }

        var i = 2
        while i + 4 <= data.count {
            let index = data[i]
            let y = data[i + 1]
            let cr = data[i + 2]
            let cb = data[i + 3]
            let alpha = data[i + 4]

            // Convert YCrCb to RGB
            let rgb = yCrCbToRGB(y: y, cr: cr, cb: cb)

            // Store RGBA values to palette table
            palette[Int(index) * 4 + 0] = rgb.red
            palette[Int(index) * 4 + 1] = rgb.green
            palette[Int(index) * 4 + 2] = rgb.blue
            palette[Int(index) * 4 + 3] = alpha
            i += 5
        }
    }

    private func yCrCbToRGB(y: UInt8, cr: UInt8, cb: UInt8) -> (red: UInt8, green: UInt8, blue: UInt8) {
        let y = min(max(Double(y) - 16.0, 0), 255.0)
        let cr = min(max(Double(cr) - 128, 0), 255.0)
        let cb = min(max(Double(cb) - 128.0, 0), 255.0)
        let yCbCr = simd_double3(y, cb, cr)

        // Color conversion matrix for BT.709
        let matrix = simd_double3x3(simd_double3(1.164, 0, 1.793),
                                    simd_double3(1.164, -0.213, -0.533),
                                    simd_double3(1.164, 2.112, 0))

        let rgb = yCbCr * matrix

        // Clamp to 0-255
        let red = UInt8(min(max(rgb[0], 0), 255))
        let green = UInt8(min(max(rgb[1], 0), 255))
        let blue = UInt8(min(max(rgb[2], 0), 255))

        return (red: red, green: green, blue: blue)
    }
}
