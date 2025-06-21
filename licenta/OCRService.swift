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
            
            // Recunoaștem textul
            let recognizedText = request.results?.compactMap { result in
                (result as? VNRecognizedTextObservation)?.topCandidates(1).first?.string
            }.joined(separator: "\n") ?? ""
            print("Text recunoscut:\n\(recognizedText)")
            
            // Împărțim textul în linii
            let lines = recognizedText.components(separatedBy: "\n").map { $0.replacingOccurrences(of: "-", with: ".").replacingOccurrences(of: ",", with: ".") }
            let pattern = #"(?<=\s|^)(\d+[.]\d{2})(?=\s|$)"#
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                completion(nil)
                return
            }
            var foundAmounts: [Double] = []
            // Iterăm prin toate liniile pentru a găsi unde apare "TOTAL"
            for i in 0..<lines.count {
                let line = lines[i]
                
                // Normalizăm linia (fără spații, uppercased) pentru a verifica "TOTAL"
                let normalizedLine = line.uppercased().replacingOccurrences(of: " ", with: "")
                if normalizedLine.contains("TOTAL") {
                    // 1) Încercăm să extragem sume din aceeași linie
                    let amountsInThisLine = extractAmounts(from: line, using: regex)
                    
                    if !amountsInThisLine.isEmpty {
                        foundAmounts.append(contentsOf: amountsInThisLine)
                        break;
                    } 
                }
                else{
                    let amountsInCurrentLine = extractAmounts(from: normalizedLine, using: regex)
                    if !amountsInCurrentLine.isEmpty {
                        foundAmounts.append(contentsOf: amountsInCurrentLine)
                    }
                }
            }
            
            // Daca am gasit sume, o luam pe cea mai mare
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
