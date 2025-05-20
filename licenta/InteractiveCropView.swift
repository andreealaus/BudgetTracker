import SwiftUI

struct InteractiveCropView: View {
    @Binding var image: UIImage?
    @Binding var croppedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    // Zona de crop în coordonatele view-ului (inițială: centrul view-ului, 50% din dimensiuni)
    @State private var cropRect: CGRect = .zero
    // Offset pentru mișcare (drag)
    @State private var dragOffset: CGSize = .zero
    // Factorul de scalare curent (pentru pinch)
    @State private var currentScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let uiImage = image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width,
                               height: geometry.size.height)
                        .overlay(
                            // Overlay-ul de crop, ce poate fi mutat și scalat
                            Rectangle()
                                .stroke(Color.red, lineWidth: 2)
                                .frame(width: cropRect.width, height: cropRect.height)
                                .position(x: cropRect.midX + dragOffset.width,
                                          y: cropRect.midY + dragOffset.height)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            dragOffset = value.translation
                                        }
                                        .onEnded { _ in
                                            cropRect.origin.x += dragOffset.width
                                            cropRect.origin.y += dragOffset.height
                                            dragOffset = .zero
                                        }
                                )
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            currentScale = value
                                        }
                                        .onEnded { value in
                                            cropRect.size.width *= value
                                            cropRect.size.height *= value
                                            currentScale = 1.0
                                        }
                                )
                        )
                        .onAppear {
                            // Inițial, setează cropRect-ul la centrul view-ului cu dimensiuni 50%
                            if cropRect == .zero {
                                let width = geometry.size.width * 0.5
                                let height = geometry.size.height * 0.5
                                let originX = (geometry.size.width - width) / 2
                                let originY = (geometry.size.height - height) / 2
                                cropRect = CGRect(x: originX, y: originY, width: width, height: height)
                            }
                        }
                } else {
                    Text("Nu există imagine")
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crop") {
                        // Calculează dreptunghiul de crop în coordonatele imaginii originale
                        let scaledRect = computeCropRect(in: geometry.size)
                        if let originalImage = image, let cropped = originalImage.cropped(to: scaledRect) {
                            croppedImage = cropped
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .navigationTitle("Crop Image")
    }
    
    /// Calculează dreptunghiul de crop în coordonatele imaginii originale.
    private func computeCropRect(in geometrySize: CGSize) -> CGRect {
        guard let originalImage = image else { return cropRect }
        let imageSize = originalImage.size
        
        // Calculăm factorul de scalare pentru aspectFit
        let scale = min(geometrySize.width / imageSize.width, geometrySize.height / imageSize.height)
        // Imaginea afișată are o dimensiune:
        let displayedWidth = imageSize.width * scale
        let displayedHeight = imageSize.height * scale
        // Calculăm offset-ul dacă imaginea nu umple complet view-ul:
        let xOffset = (geometrySize.width - displayedWidth) / 2
        let yOffset = (geometrySize.height - displayedHeight) / 2
        
        // Ajustăm cropRect-ul în raport cu imaginea afișată
        let adjustedX = cropRect.origin.x - xOffset
        let adjustedY = cropRect.origin.y - yOffset
        
        // Convertim coordonatele în coordonatele imaginii originale
        let originalCropRect = CGRect(x: adjustedX / scale,
                                      y: adjustedY / scale,
                                      width: cropRect.width / scale,
                                      height: cropRect.height / scale)
        return originalCropRect
    }
}

struct InteractiveCropView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InteractiveCropView(image: .constant(UIImage(systemName: "photo")!), croppedImage: .constant(nil))
        }
    }
}
