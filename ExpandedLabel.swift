//
//  ExpandedLabel.swift
//
//  Created by Konstantin Kulakov on 17.01.2021.
//  Copyright © 2021 Konstantin Kulakov. All rights reserved.
//
import UIKit

final class ExpandedLabel: UILabel {
    var trailingAttributedText: NSAttributedString?

    override func drawText(in rect: CGRect) {
        guard let trailingAttributedText = trailingAttributedText,
              let attributedText = attributedText,
              let context = UIGraphicsGetCurrentContext(),
              attributedText.length > 0,
              numberOfLines > 0 else {
            super.drawText(in: rect)
            return
        }

        context.saveGState()

        // Текст перевернутый в CoreGraphics, поэтому переворачивваем
        context.textMatrix = CGAffineTransform.identity
        context.translateBy(x: 0, y: rect.height)
        context.scaleBy(x: 1.0, y: -1.0)

        let path = CGPath(rect: rect, transform: nil)

        let frameSetter = CTFramesetterCreateWithAttributedString(attributedText)

        let frame = CTFramesetterCreateFrame(frameSetter, CFRange(location: 0, length: attributedText.length), path, nil)

        if (CTFrameGetVisibleStringRange(frame).length as Int) < attributedText.length {

            var lines = CTFrameGetLines(frame) as? [CTLine] ?? []

            let lastCTLine = lines.removeLast()

            let truncateToken: CTLine = CTLineCreateWithAttributedString(trailingAttributedText)

            let lineWidth = CTLineGetTypographicBounds(lastCTLine, nil, nil, nil)
            let tokenWidth = CTLineGetTypographicBounds(truncateToken, nil, nil, nil)

            let lastLineRange = CTLineGetStringRange(lastCTLine)
            let lastLineText = NSMutableAttributedString(attributedString: attributedText.attributedSubstring(from: NSRange(location: lastLineRange.location,
                                                                                                                                length: lastLineRange.length)))
            let maxWidth = Double(rect.size.width)

            if lastLineText.string.last == " " {
                lastLineText.deleteCharacters(in: NSRange(location: lastLineText.length - 1, length: 1))
            }

            if lineWidth + tokenWidth <= maxWidth {
                lastLineText.append(trailingAttributedText)

                let truncatedLine = CTLineCreateWithAttributedString(lastLineText)
                lines.append(truncatedLine)
            } else {
                var trimmedLineWidth: Double = lineWidth
                var wasSpace: Bool = false

                while lastLineText.length > 0 && (trimmedLineWidth + tokenWidth > maxWidth || !wasSpace) {
                    wasSpace = false

                    let deletedRange = NSRange(location: lastLineText.length - 1, length: 1)

                    if lastLineText.attributedSubstring(from: deletedRange).string.contains(" ") {
                        wasSpace = true
                    }

                    lastLineText.deleteCharacters(in: NSRange(location: lastLineText.length - 1, length: 1))

                    trimmedLineWidth = CTLineGetTypographicBounds(CTLineCreateWithAttributedString(lastLineText), nil, nil, nil)
                }

                if !wasSpace {
                    let widthTruncationBegins = lineWidth - tokenWidth

                    if let truncatedLine = CTLineCreateTruncatedLine(lastCTLine, widthTruncationBegins, .end, truncateToken) {
                        lines.append(truncatedLine)
                    }
                } else {
                    lastLineText.append(trailingAttributedText)
                    let line = CTLineCreateWithAttributedString(lastLineText)
                    lines.append(line)
                }
            }

            var lineOrigins = [CGPoint](repeating: CGPoint.zero, count: lines.count)
            CTFrameGetLineOrigins(frame, CFRange(location: 0, length: lines.count), &lineOrigins)

            let boundingBoxOfPath = path.boundingBoxOfPath

            for (index, line) in lines.enumerated() {
                context.textPosition = CGPoint(x: lineOrigins[index].x + boundingBoxOfPath.origin.x, y: lineOrigins[index].y + boundingBoxOfPath.origin.y)
                CTLineDraw(line, context)
            }
        } else {
            CTFrameDraw(frame, context)
        }

        context.restoreGState()
    }
}
