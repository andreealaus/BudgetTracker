import UIKit
import Vision

class OCRService {
    static func scanReceipt(from image: UIImage, completion: @escaping (Double?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let request = VNRecognizeTextRequest { (request, error) in
            guard error == nil else {
                print("Eroare OCR: \(error!.localizedDescription)")
                completion(nil)
                return
            }
            
            // Recunoaștem textul pe linii separate
            let recognizedText = request.results?.compactMap { result in
                (result as? VNRecognizedTextObservation)?.topCandidates(1).first?.string
            }.joined(separator: "\n") ?? ""
            
            print("Text recunoscut:\n\(recognizedText)")
            
            // Împărțim textul în linii
            let lines = recognizedText.components(separatedBy: "\n")
            
            // Regex pentru sume (ex. "21.84", "21,84", "999" etc.)
            let pattern = #"(\d{1,3}(?:[.,]\d{1,2})?)"#
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                completion(nil)
                return
            }
            
            var foundAmounts: [Double] = []
            
            // Iterăm prin toate liniile pentru a găsi unde apare "TOTAL"
            for i in 0..<lines.count {
                let line = lines[i]
                
                // Normalizez linia (fără spații, uppercased) pentru a verifica "TOTAL"
                let normalizedLine = line.uppercased().replacingOccurrences(of: " ", with: "")
                if normalizedLine.contains("TOTAL") {
                    // 1) Încercăm să extragem sume din aceeași linie
                    let amountsInThisLine = extractAmounts(from: line, using: regex)
                    
                    if !amountsInThisLine.isEmpty {
                        foundAmounts.append(contentsOf: amountsInThisLine)
                    } else {
                        // 2) Dacă nu s-a găsit nicio sumă pe aceeași linie, verificăm linia următoare (dacă există)
                        if i+1 < lines.count {
                            let nextLine = lines[i+1]
                            let amountsInNextLine = extractAmounts(from: nextLine, using: regex)
                            if !amountsInNextLine.isEmpty {
                                foundAmounts.append(contentsOf: amountsInNextLine)
                            }
                        }
                    }
                }
            }
            
            // Dacă am găsit sume în apropierea cuvântului "TOTAL", luăm pe cea mai mare
            if !foundAmounts.isEmpty {
                let maxAmount = foundAmounts.max()!
                completion(maxAmount)
                return
            }
            
            // Fallback: dacă nu există linii cu "TOTAL" sau nicio sumă validă
            let nsrange = NSRange(recognizedText.startIndex..<recognizedText.endIndex, in: recognizedText)
            if let fallbackRegex = try? NSRegularExpression(pattern: pattern, options: []),
               let fallbackMatch = fallbackRegex.firstMatch(in: recognizedText, options: [], range: nsrange) {
                if let range = Range(fallbackMatch.range(at: 1), in: recognizedText) {
                    let amountString = recognizedText[range].replacingOccurrences(of: ",", with: ".")
                    if let amount = Double(amountString) {
                        completion(amount)
                        return
                    }
                }
            }
            completion(nil)
        }
        
        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Eroare la recunoașterea textului: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    /// Funcție auxiliară care extrage toate sumele dintr-un text, returnându-le într-un array
    private static func extractAmounts(from line: String, using regex: NSRegularExpression) -> [Double] {
        // Eliminăm eventuale spații dintre cifre (ex. "49. 99" -> "49.99")
        let cleanedLine = removeSpacesBetweenDigits(in: line)
        
        var amounts: [Double] = []
        let nsrange = NSRange(cleanedLine.startIndex..<cleanedLine.endIndex, in: cleanedLine)
        let matches = regex.matches(in: cleanedLine, options: [], range: nsrange)
        
        for match in matches {
            if let range = Range(match.range(at: 1), in: cleanedLine) {
                let amountString = cleanedLine[range].replacingOccurrences(of: ",", with: ".")
                if let amount = Double(amountString) {
                    amounts.append(amount)
                }
            }
        }
        return amounts
    }
    
    /// Elimină spațiile dintre cifre și punct/virgulă (ex. "49. 99" -> "49.99", "1 000" -> "1000")
    private static func removeSpacesBetweenDigits(in line: String) -> String {
        let pattern = #"([0-9.,])\s+([0-9])"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return line
        }
        let nsrange = NSRange(line.startIndex..<line.endIndex, in: line)
        return regex.stringByReplacingMatches(in: line, options: [], range: nsrange, withTemplate: "$1$2")
    }
}
