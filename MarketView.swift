import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct MarketView: View {
    @State private var products: [Product] = []
    @State private var selectedCategory = "Все"
    @State private var searchText = ""
    @State private var showSellSheet = false
    
    let categories = ["Все", "Подгузники", "Уход", "Одежда", "Игрушки", "Аксессуары", "Питание"]
    
    var body: some View {
        ZStack {
            Color.peachBg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                searchBarView
                categoryFiltersView
                productsGridView
            }
        }
        .fullScreenCover(isPresented: $showSellSheet) {
            SellProductView(onPublished: {
                Task { await loadProductsAsync() }
            })
        }
        .onAppear { loadProducts() }
    }
    
    // MARK: - Части экрана (чтобы компилятор не зависал)
    
    private var headerView: some View {
        HStack {
            Text("Маркет")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.textPrimary)
            Spacer()
            sellButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    private var sellButton: some View {
        Button {
            showSellSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                Text("Продать")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(LinearGradient(colors: [.peachPrimary, .peachDark], startPoint: .leading, endPoint: .trailing))
            .cornerRadius(12)
            .shadow(color: .peachPrimary.opacity(0.3), radius: 8, y: 4)
        }
    }
    
    private var searchBarView: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textMuted)
            TextField("Искать товары...", text: $searchText)
                .font(.system(size: 15))
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(Color.peachSurface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.peachLight, lineWidth: 1.5)
        )
        .padding(.horizontal, 20)
    }
    
    private var categoryFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    CategoryButton(
                        title: cat,
                        isSelected: selectedCategory == cat,
                        action: {
                            withAnimation {
                                selectedCategory = cat
                                loadProducts()
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 12)
    }
    
    private var productsGridView: some View {
        ScrollView(showsIndicators: false) {
            if filteredProducts.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: SFSymbol.available("cart", fallback: "bag.fill"))
                        .font(.system(size: 48))
                        .foregroundColor(.peachPrimary.opacity(0.45))
                    Text("Пока нет товаров")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text("Нажмите «Продать», чтобы добавить объявление с фото.")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(filteredProducts) { product in
                        ProductCard(product: product)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Логика
    
    var filteredProducts: [Product] {
        var result = products
        if selectedCategory != "Все" {
            result = result.filter { $0.category == selectedCategory }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }
    
    func loadProducts() {
        Task { await loadProductsAsync() }
    }
    
    private func loadProductsAsync() async {
        let cat = selectedCategory == "Все" ? nil : selectedCategory
        do {
            let list = try await NetworkService.shared.fetchProducts(category: cat)
            await MainActor.run { products = list }
        } catch {
            await MainActor.run { products = [] }
        }
    }
}

// MARK: - Кастомная кнопка категории (вынесена отдельно от тела)

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(colors: [.peachPrimary, .peachDark], startPoint: .leading, endPoint: .trailing)
                        } else {
                            Color.peachSurface
                        }
                    }
                )
                .cornerRadius(20)
                .overlay(
                    Group {
                        if !isSelected {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.peachLight, lineWidth: 1.5)
                        }
                    }
                )
        }
    }
}

// MARK: - Карточка товара (вынесена отдельно)

struct ProductCard: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.peachLight)
                    .frame(height: 140)
                    .clipped()
                
                if let img = product.image, let u = URL(string: img), !img.isEmpty {
                    AsyncImage(url: u) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 140)
                                .clipped()
                        case .failure:
                            placeholderIcon
                        case .empty:
                            ProgressView()
                        @unknown default:
                            placeholderIcon
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    placeholderIcon
                }
                
                conditionBadge
            }
            
            Text(product.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textPrimary)
                .lineLimit(2)
            
            if let desc = product.description {
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
            
            HStack {
                Text("\(Int(product.price)) ₸")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.peachPrimary)
                Spacer()
                if let seller = product.sellerName {
                    Text(seller)
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }
            }
        }
        .padding(12)
        .background(Color.peachSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.peachLight, lineWidth: 1)
        )
    }
    
    private var conditionBadge: some View {
        VStack {
            HStack {
                Text(product.condition ?? "")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(isNewCondition ? Color.green : Color.orange)
                    .cornerRadius(8)
                Spacer()
            }
            .padding(8)
            Spacer()
        }
    }
    
    private var isNewCondition: Bool {
        let cond = product.condition ?? ""
        return cond == "Новое" || cond == "Новая" || cond.lowercased() == "new"
    }
    
    private var placeholderIcon: some View {
        Image(systemName: productIcon(product.category))
            .font(.system(size: 40))
            .foregroundColor(.peachPrimary.opacity(0.4))
    }
    
    func productIcon(_ category: String) -> String {
        switch category {
        case "Подгузники": return "rectangle.inset.filled"
        case "Уход": return "heart.fill"
        case "Одежда": return "tshirt.fill"
        case "Игрушки": return "puzzlepiece.fill"
        case "Аксессуары": return "star.fill"
        case "Питание": return "cup.and.saucer.fill"
        default: return SFSymbol.available("bag.fill", fallback: "square.grid.2x2")
        }
    }
}

// MARK: - Экран продажи

struct SellProductView: View {
    @Environment(\.dismiss) var dismiss
    var onPublished: () -> Void = {}
    
    @State private var title = ""
    @State private var descriptionText = ""
    @State private var price = ""
    @State private var category = "Подгузники"
    @State private var condition = "Новое"
    @State private var showLibraryPicker = false
    @State private var photoPreview: UIImage?
    @State private var photoLoadHint: String?
    @State private var isPublishing = false
    @State private var publishError: String?
    @State private var showError = false
    
    let categories = ["Подгузники", "Уход", "Одежда", "Игрушки", "Аксессуары", "Питание"]
    let conditions = ["Новое", "Б/у"]
    
    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    Color.peachBg.ignoresSafeArea()
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            addPhotoButton
                            
                            titleInput
                            descriptionInput
                            
                            HStack(spacing: 12) {
                                priceInput
                                conditionPicker
                            }
                            
                            categoryPicker
                            
                            publishButton
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                    }
                }
                .navigationTitle("Продать товар")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") { dismiss() }
                            .foregroundColor(.peachPrimary)
                    }
                }
                .alert("Ошибка", isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(publishError ?? "")
                }
            }
        }
        .sheet(isPresented: $showLibraryPicker) {
            MarketPhotoLibraryPicker(isPresented: $showLibraryPicker) { result in
                switch result {
                case .cancelled:
                    break
                case .decodeFailed:
                    photoLoadHint = "Не удалось открыть фото. Попробуйте другое изображение."
                case .picked(let image):
                    photoPreview = image
                    photoLoadHint = nil
                }
            }
        }
    }
    
    private var addPhotoButton: some View {
        Button {
            guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
                photoLoadHint = "Галерея на этом устройстве недоступна."
                return
            }
            showLibraryPicker = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.peachSurface)
                    .frame(height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(Color.peachLight)
                    )
                if let photoPreview {
                    Image(uiImage: photoPreview)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(16)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.peachPrimary)
                        Text("Добавить фото")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                        Text("Галерея (симулятор: добавьте фото через меню устройства)")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                        if let hint = photoLoadHint {
                            Text(hint)
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var titleInput: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Название")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textSecondary)
            peachTextField("Что продаёте?", text: $title)
        }
    }
    
    private var descriptionInput: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Описание")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textSecondary)
            TextEditor(text: $descriptionText)
                .frame(height: 100)
                .padding(12)
                .background(Color.peachSurface)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.peachLight, lineWidth: 1.5)
                )
                .font(.system(size: 15))
        }
    }
    
    private var priceInput: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Цена (₸)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textSecondary)
            peachTextField("0", text: $price)
                .keyboardType(.numberPad)
        }
    }
    
    private var conditionPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Состояние")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textSecondary)
            Picker("", selection: $condition) {
                ForEach(conditions, id: \.self) { c in
                    Text(c).tag(c)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color.peachSurface)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.peachLight, lineWidth: 1.5)
            )
        }
    }
    
    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Категория")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textSecondary)
            Picker("", selection: $category) {
                ForEach(categories, id: \.self) { c in
                    Text(c).tag(c)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color.peachSurface)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.peachLight, lineWidth: 1.5)
            )
        }
    }
    
    private var publishButton: some View {
        Button {
            Task { await publishProduct() }
        } label: {
            Text(isPublishing ? "Публикация…" : "Опубликовать")
        }
        .peachButton(isPublishing)
        .padding(.top, 8)
        .disabled(isPublishing || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    private func publishProduct() async {
        let titleTrim = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !titleTrim.isEmpty else { return }
        let priceInt = Int(price.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        guard priceInt > 0 else {
            publishError = "Укажите цену больше 0"
            showError = true
            return
        }
        await MainActor.run { isPublishing = true }
        do {
            var imageUrl: String?
            if let img = photoPreview, let jpeg = img.jpegData(compressionQuality: 0.85) {
                imageUrl = try await NetworkService.shared.uploadImage(data: jpeg, purpose: "market_product")
            }
            let cond = condition == "Новое" ? "new" : "used"
            _ = try await NetworkService.shared.createMarketProduct(
                title: titleTrim,
                description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : descriptionText,
                price: priceInt,
                category: category,
                condition: cond,
                imageUrl: imageUrl
            )
            await MainActor.run {
                isPublishing = false
                onPublished()
                dismiss()
            }
        } catch {
            await MainActor.run {
                isPublishing = false
                publishError = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Галерея для маркета (UIImagePicker: стабильно в симуляторе; PHPicker/SwiftUI sheet часто ломаются)

enum MarketPhotoPickResult {
    case cancelled
    case decodeFailed
    case picked(UIImage)
}

/// Классический выбор из медиатеки — надёжнее вложенных SwiftUI-пикеров при `fullScreenCover` + `sheet`.
struct MarketPhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onResult: (MarketPhotoPickResult) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        if let types = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
            let imagesOnly = types.filter { t in
                !(t.contains("movie") || t.contains("video") || t.contains("Video"))
            }
            picker.mediaTypes = imagesOnly.isEmpty ? [UTType.image.identifier] : imagesOnly
        } else {
            picker.mediaTypes = [UTType.image.identifier]
        }
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: MarketPhotoLibraryPicker

        init(parent: MarketPhotoLibraryPicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            Task { @MainActor in
                parent.onResult(.cancelled)
                parent.isPresented = false
            }
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let img = (info[.originalImage] as? UIImage) ?? (info[.editedImage] as? UIImage)
            Task { @MainActor in
                if let img {
                    parent.onResult(.picked(img))
                } else {
                    parent.onResult(.decodeFailed)
                }
                parent.isPresented = false
            }
        }
    }
}
