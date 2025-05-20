import SwiftUI

struct CropImageView: View {
    @Binding var image: UIImage?
    @Binding var croppedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            if let uiImage = image {
                GeometryReader { geometry in
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .overlay(
                            // Overlay fix: o zonă de crop centrată (50% din dimensiunea view-ului)
                            Rectangle()
                                .stroke(Color.red, lineWidth: 2)
                                .frame(width: geometry.size.width * 0.5,
                                       height: geometry.size.height * 0.5)
                                .position(x: geometry.size.width / 2,
                                          y: geometry.size.height / 2)
                        )
                }
                .frame(height: 300)
            } else {
                Text("Nu există imagine")
            }
            
            Button("Aplică Crop") {
                if let uiImage = image {
                    // Calculăm o zonă de crop fixă (centru, 50% din dimensiunea imaginii)
                    let width = uiImage.size.width * 0.5
                    let height = uiImage.size.height * 0.5
                    let x = (uiImage.size.width - width) / 2
                    let y = (uiImage.size.height - height) / 2
                    let rect = CGRect(x: x, y: y, width: width, height: height)
                    croppedImage = uiImage.cropped(to: rect)
                }
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .padding()
    }
}

struct CropImageView_Previews: PreviewProvider {
    static var previews: some View {
        CropImageView(image: .constant(UIImage(systemName: "photo")!), croppedImage: .constant(nil))
    }
}
