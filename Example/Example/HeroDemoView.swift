import SwiftUI
import Transmission
import UIKit

private let images = ["Landscape1", "Landscape2", "Landscape3"]

@available(iOS 17.0, *)
struct HeroDemoView: View {
    @State
    private var isPresented = false
    
    var body: some View {
        VStack {
            DemoImageGridView()
            
            Button {
                isPresented = true
            } label: {
                Text("Open Sheet")
            }
        }
        .sheet(isPresented: $isPresented) {
            DemoImageGridView()
        }
    }
    
    struct DemoImageGridView: View {
        @State
        private var viewModel = HeroDemoViewModel()
        
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
        ]
        
        var body: some View {
            GeometryReader { geometry in
                let totalSpacing = (columns.count - 1) * 20
                let itemWidth = max((
                    geometry.size.width - CGFloat(totalSpacing) - geometry.safeAreaInsets.leading - geometry
                        .safeAreaInsets.trailing
                ) / CGFloat(columns.count), 100)
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(images, id: \.self) { imageName in
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: itemWidth, height: itemWidth)
                            .clipped()
                            .cornerRadius(10)
                            .sourceViewObserver { uiView in
                                // save the uiView
                                viewModel.addSourceView(for: imageName, uiView: uiView)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation {
                                    viewModel.selectedImage = imageName
                                    viewModel.isPresented = true
                                }
                            }
                    }
                }
            }
            .padding()
            .presentation(
                transition: .zoomIfAvailable(
                    options: .init(preferredPresentationBackgroundColor: .black),
                    otherwise: .matchedGeometry(
                        .init(
                            preferredFromCornerRadius: 10,
                            prefersScaleEffect: false,
                            prefersZoomEffect: true,
                            initialOpacity: 0,
                            preferredPresentationShadow: .prominent,
                            sourceViewProvider: viewModel.getSelectedSourceView
                        ),
                        options: .init(preferredPresentationBackgroundColor: .black),
                    ),
                    // get target view for zoom transition
                    sourceViewProvider: viewModel.getSelectedSourceView
                ),
                isPresented: $viewModel.isPresented
            ) {
                DemoDestination(images: images, selectedImage: $viewModel.selectedImage)
            }
        }
    }
    
    struct DemoDestination: View {
        var images: [String]
        
        @Binding
        var selectedImage: String?
        
        @State
        private var hidesThumbnail: Bool = false
        
        var body: some View {
            ZStack {
                Color.black
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(images, id: \.self) { image in
                            Image(image)
                                .resizable()
                                .scaledToFit()
                                .id(image)
                        }
                        .containerRelativeFrame(.horizontal)
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $selectedImage)
                .opacity(hidesThumbnail ? 1 : 0)
                
                if !hidesThumbnail, let thumbnail = selectedImage ?? images.first {
                    Image(thumbnail)
                        .resizable()
                        .scaledToFit()
                        .task {
                            if selectedImage == nil {
                                selectedImage = thumbnail
                            }
                            try? await Task.sleep(for: .seconds(0.2))
                            hidesThumbnail = true
                        }
                }
            }
            .ignoresSafeArea()
        }
    }
    
    
    @Observable
    class HeroDemoViewModel {
        struct WeakUIViewWrapper {
            weak var view: UIView?
        }

        @ObservationIgnored
        var sourceViews: [String: WeakUIViewWrapper] = [:]

        var selectedImage: String?
        
        var isPresented = false
        
        func addSourceView(for image: String, uiView: UIView) {
            sourceViews[image] = WeakUIViewWrapper(view: uiView)
        }
        
        func removeSourceView(for image: String) {
            sourceViews.removeValue(forKey: image)
        }
        
        func getSelectedSourceView() -> UIView? {
            sourceViews[selectedImage ?? ""]?.view
        }
    }

}

struct SourceViewObserver: UIViewRepresentable {
    var onUpdate: (UIView) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        onUpdate(uiView)
    }
}

extension View {
    func sourceViewObserver(_ onUpdate: @escaping (UIView) -> Void) -> some View {
        background(SourceViewObserver(onUpdate: onUpdate))
    }
}


#Preview {
    if #available(iOS 17.0, *) {
        HeroDemoView()
    }
}
