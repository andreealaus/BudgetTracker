import UIKit

extension UIImage {
    func cropped(to rect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
    }
}
