import SwiftUI
import PhotosUI
import UIKit

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
        .sheet(isPresented: $showSellSheet) {
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
        default: return "bag.fill"
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
    @State private var photoItem: PhotosPickerItem?
    @State private var photoPreview: UIImage?
    @State private var isPublishing = false
    @State private var publishError: String?
    @State private var showError = false
    
    let categories = ["Подгузники", "Уход", "Одежда", "Игрушки", "Аксессуары", "Питание"]
    let conditions = ["Новое", "Б/у"]
    
    var body: some View {
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
    
    private var addPhotoButton: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
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
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .onChange(of: photoItem) { _, newItem in
            Task { await loadPhoto(from: newItem) }
        }
    }
    
    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else {
            await MainActor.run { photoPreview = nil }
            return
        }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let img = UIImage(data: data) else { return }
        await MainActor.run { photoPreview = img }
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
            if let item = photoItem {
                let jpeg = try await jpegData(from: item)
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
    
    private func jpegData(from item: PhotosPickerItem) async throws -> Data {
        guard let data = try await item.loadTransferable(type: Data.self) else {
            throw NetworkError.serverError("Не удалось прочитать фото")
        }
        guard let img = UIImage(data: data), let jpeg = img.jpegData(compressionQuality: 0.85) else {
            throw NetworkError.serverError("Не удалось подготовить изображение (JPEG)")
        }
        return jpeg
    }
}
