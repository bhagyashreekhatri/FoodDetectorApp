import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FoodDetectorViewModel()
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // ── Image Card ─────────────────────────────
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGray6))
                            .frame(height: 300)

                        if let image = viewModel.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "fork.knife.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.orange)
                                Text("Upload or capture a food photo")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // ── Buttons ────────────────────────────────
                    HStack(spacing: 16) {
                        ActionButton(title: "Camera", icon: "camera.fill", color: .orange) {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                sourceType = .camera
                                showImagePicker = true
                            }
                        }
                        ActionButton(title: "Gallery", icon: "photo.fill", color: .purple) {
                            sourceType = .photoLibrary
                            showImagePicker = true
                        }
                    }
                    .padding(.horizontal)

                    // ── Error Message ──────────────────────────
                    if let error = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                    // ── Results Card ───────────────────────────
                    if viewModel.selectedImage != nil {
                        ResultsCard(viewModel: viewModel)
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
            .background(Color(.systemBackground))
            .navigationTitle("🍽️ Food Detector")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $viewModel.selectedImage, sourceType: sourceType)
        }
        .onChange(of: viewModel.selectedImage) { _ in
            viewModel.classify()
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Results Card
struct ResultsCard: View {
    @ObservedObject var viewModel: FoodDetectorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Predictions")
                .font(.title2.bold())
                .foregroundColor(.primary)

            if viewModel.isClassifying {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Analyzing food…")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()

            } else if viewModel.predictions.isEmpty {
                Text("No predictions available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()

            } else {
                VStack(spacing: 10) {
                    ForEach(Array(viewModel.predictions.enumerated()), id: \.offset) { index, pred in
                        PredictionRow(
                            rank: index + 1,
                            label: pred.label,
                            confidence: pred.confidence,
                            isTop: index == 0
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Prediction Row
struct PredictionRow: View {
    let rank: Int
    let label: String
    let confidence: Float
    let isTop: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(isTop ? Color.orange : Color(.systemGray4))
                    .frame(width: 34, height: 34)
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isTop ? .white : .primary)
            }

            // Food name
            Text(label)
                .font(.system(size: 16, weight: isTop ? .bold : .regular))
                .foregroundColor(.primary)
                .lineLimit(2)

            Spacer()

            // Confidence % + bar
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f%%", confidence * 100))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isTop ? .orange : .secondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray4))
                            .frame(height: 5)
                        Capsule()
                            .fill(isTop ? Color.orange : Color(.systemGray2))
                            .frame(width: max(geo.size.width * CGFloat(confidence), 2), height: 5)
                    }
                }
                .frame(width: 80, height: 5)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isTop ? Color.orange.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
}
