import Foundation
import CoreData
import PencilKit
import PDFKit
import UIKit

class NoteViewModel: ObservableObject {
    static let shared = NoteViewModel()

    func createNote(in context: NSManagedObjectContext, subject: Subject? = nil) -> Note {
        let note = Note(context: context)
        note.id = UUID()
        note.title = "Untitled"
        note.createdAt = Date()
        note.updatedAt = Date()
        note.subject = subject
        try? context.save()
        return note
    }

    func deleteNote(_ note: Note, in context: NSManagedObjectContext) {
        context.delete(note)
        try? context.save()
    }

    func duplicateNote(_ note: Note, in context: NSManagedObjectContext) -> Note {
        let copy = Note(context: context)
        copy.id = UUID()
        copy.title = "\(note.title ?? "Untitled") Copy"
        copy.createdAt = Date()
        copy.updatedAt = Date()
        copy.drawingData = note.drawingData
        copy.pdfData = note.pdfData
        copy.annotationsData = note.annotationsData
        copy.thumbnailData = note.thumbnailData
        copy.canvasStyle = note.canvasStyle
        copy.subject = note.subject
        try? context.save()
        return copy
    }

    func generateThumbnail(from drawingData: Data) -> Data? {
        guard !drawingData.isEmpty,
              let drawing = try? PKDrawing(data: drawingData) else { return nil }
        let bounds = drawing.bounds
        guard !bounds.isEmpty else { return nil }

        let targetSize = CGSize(width: 400, height: 300)
        let image = drawing.image(from: bounds, scale: 1.0)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let thumbnail = renderer.image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: targetSize))
            let rect = Self.aspectFitRect(for: image.size, in: targetSize)
            image.draw(in: rect)
        }

        return thumbnail.jpegData(compressionQuality: 0.7)
    }

    func generatePDFThumbnail(from pdfData: Data) -> Data? {
        guard let document = PDFDocument(data: pdfData),
              let page = document.page(at: 0) else { return nil }
        let thumbnail = page.thumbnail(of: CGSize(width: 400, height: 300), for: .mediaBox)
        return thumbnail.jpegData(compressionQuality: 0.7)
    }

    static func aspectFitRect(for imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let w = imageSize.width * scale
        let h = imageSize.height * scale
        return CGRect(x: (containerSize.width - w) / 2, y: (containerSize.height - h) / 2, width: w, height: h)
    }
}
