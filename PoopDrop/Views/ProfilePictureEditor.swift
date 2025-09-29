import SwiftUI
import UIKit

struct ProfilePictureEditor: View {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    @State private var showingImagePicker = false
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    
    var onSave: (UIImage) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let image = selectedImage {
                    GeometryReader { geometry in
                        VStack {
                            // Crop area indicator
                            ZStack {
                                // Background image (blurred)
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .blur(radius: 10)
                                    .opacity(0.3)
                                
                                // Crop circle overlay
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 200, height: 200)
                                
                                // Editable image
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 400, height: 400)
                                    .scaleEffect(scale)
                                    .offset(offset)
                                    .clipShape(Circle())
                                    .frame(width: 200, height: 200)
                                    .gesture(
                                        SimultaneousGesture(
                                            MagnificationGesture()
                                                .onChanged { value in
                                                    scale = lastScale * value
                                                }
                                                .onEnded { _ in
                                                    lastScale = scale
                                                    // Limit scale between 0.5x and 3x
                                                    scale = min(max(scale, 0.5), 3.0)
                                                    lastScale = scale
                                                },
                                            
                                            DragGesture()
                                                .onChanged { value in
                                                    offset = CGSize(
                                                        width: lastOffset.width + value.translation.width,
                                                        height: lastOffset.height + value.translation.height
                                                    )
                                                }
                                                .onEnded { _ in
                                                    lastOffset = offset
                                                }
                                        )
                                    )
                            }
                            
                            Spacer()
                            
                            // Instructions
                            VStack(spacing: 8) {
                                Text("Pinch to zoom, drag to move")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.caption)
                                
                                Text("Position your photo within the circle")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.caption)
                            }
                            .padding(.bottom, 20)
                        }
                    }
                } else {
                    // No image selected state
                    VStack(spacing: 20) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("No Photo Selected")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Button("Choose Photo") {
                            showingImagePicker = true
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Edit Profile Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedImage != nil {
                        Button("Choose Photo") {
                            showingImagePicker = true
                        }
                        .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedImage != nil {
                        Button("Save") {
                            saveEditedImage()
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage) { _ in
                // Reset editing state when new image is selected
                scale = 1.0
                offset = .zero
                lastScale = 1.0
                lastOffset = .zero
            }
        }
    }
    
    private func saveEditedImage() {
        guard let image = selectedImage else { return }
        
        // Create the cropped image
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
        let croppedImage = renderer.image { context in
            // Fill with background color (optional)
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))
            
            // Draw the scaled and offset image
            let drawRect = CGRect(
                x: -offset.width / scale + (200 - 400 * scale) / 2,
                y: -offset.height / scale + (200 - 400 * scale) / 2,
                width: 400 * scale,
                height: 400 * scale
            )
            
            image.draw(in: drawRect)
        }
        
        onSave(croppedImage)
        isPresented = false
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false // We'll do our own editing
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImageSelected(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ProfilePictureEditor(
        selectedImage: .constant(UIImage(systemName: "person.fill")),
        isPresented: .constant(true)
    ) { image in
        print("Saved edited image")
    }
}
