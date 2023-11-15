//
//  ContentView.swift
//  Exam3_Maxey_Ethan
//
//  Created by user235933 on 11/14/23.
//

import SwiftUI
import NaturalLanguage
import CoreML
import PhotosUI
import CoreImage


@MainActor
final class PhotoPickerViewModel: ObservableObject {
    
    @Published var selectedFilter = "Original"

    @Published private(set) var selectedImage: UIImage? = UIImage(named: "fall")
    
    @Published var imageSelection: PhotosPickerItem? = nil {
        didSet {
            setImage(from: imageSelection)
        }
    }
    
    @Published var filterIntensity: Double = 0.0
    
    private func setImage(from selection: PhotosPickerItem?) {
        guard let selection else {return}
        
        Task {
            do {
                let data = try await selection.loadTransferable(type: Data.self)
                
                guard let data, let uiImage = UIImage(data: data) else {
                    throw URLError(.badServerResponse)
                }
                
                selectedImage = uiImage
            } catch {
                print(error)
            }
        }
    }
}

extension PhotoPickerViewModel {
    var filteredImage: UIImage {
        guard let image = selectedImage else { return UIImage() }
        switch selectedFilter {
        case "Blur":
            return applyFilter(to: image, filterName: "CIGaussianBlur", intensity: filterIntensity)
        case "Binarized":
            return applyFilter(to: image, filterName: "CIColorThreshold", intensity: filterIntensity)
        case "Sepia":
            return applyFilter(to: image, filterName: "CISepiaTone", intensity: filterIntensity)
        default:
            return image
        }
    }
}


extension UISegmentedControl {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.setContentHuggingPriority(.defaultLow, for: .vertical)  // << here !!
    }
}

struct ContentView: View {
    
    @StateObject private var viewModel = PhotoPickerViewModel()
    
    @ObservedObject var classifier: ImageClassifier
    
    let filters = ["Original", "Blur", "Binarized", "Sepia"]

    var syncService = SyncService()
    
    @State private var imageClassText: String = ""
    
    var body: some View {
        
        VStack {
            
            Spacer().frame(height: 125)
            
            Text("ML Model vs Image Filters")
                .foregroundStyle(.black)
                .font(.custom("American Typewriter", size: 24))
            
            Spacer()
            
            Picker("Filter", selection: $viewModel.selectedFilter) {
                ForEach(filters, id: \.self) {
                    Text($0)
                }
            }
            .frame(height: 40)
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 40)
            .onChange(of: viewModel.selectedFilter) { _ in
                handleImageChange()
                viewModel.filterIntensity = 0.0
            }
            
            Spacer()
            
            if let _ = viewModel.selectedImage {
                           Image(uiImage: viewModel.filteredImage)
                               .resizable()
                               .frame(width: 350, height: 200)
                               .onAppear {
                                   handleImageChange()
                               }
                               .onTapGesture {
                                   handleImageChange()
                               }
                       }
            
            Spacer()
                
            VStack {
                HStack {
                    Spacer()

                    PhotosPicker(selection: $viewModel.imageSelection) {
                        Image(systemName: "photo")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundColor(Color("blue"))
                    }
                    .padding()


                    Slider(value: $viewModel.filterIntensity, in: 0...3.0, step: 0.01)
                        .onChange(of: viewModel.filterIntensity) { _ in
                            handleImageChange()
                        }
                        .disabled(viewModel.selectedFilter == "Original")
                        .frame(width: 200)

                    Spacer()
                }
            }

        
            Group {
                HStack {
                    Text(imageClassText) // Update this line
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(7)
                }
                .foregroundStyle(.white)
            }
            .font(.subheadline)
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
        .edgesIgnoringSafeArea(.all)
    }
    
    private func handleImageChange() {
        let filteredImage = viewModel.filteredImage
        classifier.detectObj(uiImage: filteredImage)
        self.imageClassText = classifier.imageClass ?? "" // Update the state variable
        syncService.sendMessage("object", imageClassText) { error in
            // Handle error here, if necessary
        }
    }
}

func applyFilter(to inputImage: UIImage, filterName: String, intensity: Double) -> UIImage {
    let context = CIContext()
    guard let filter = CIFilter(name: filterName), let beginImage = CIImage(image: inputImage) else {
        return inputImage
    }
    
    filter.setValue(beginImage, forKey: kCIInputImageKey)
    
    let finalIntensity = intensity == 0.0 ? 1.0 : intensity

    if filterName == "CIGaussianBlur" {
        filter.setValue(1.0 * finalIntensity, forKey: kCIInputRadiusKey)
    } else if filterName == "CIColorThreshold" {
        filter.setValue(0.1 * finalIntensity, forKey: "inputThreshold")
    } else if filterName == "CISepiaTone" {
        filter.setValue(0.5 * finalIntensity, forKey: kCIInputIntensityKey)
    }

    guard let outputImage = filter.outputImage, let cgimg = context.createCGImage(outputImage, from: outputImage.extent) else { return inputImage }

    return UIImage(cgImage: cgimg)
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(classifier: ImageClassifier())
    }
}

