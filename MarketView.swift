import SwiftUI

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
            SellProductView()
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
                            withAnimation { selectedCategory = cat }
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
        products = [
            Product(id: "p1", title: "Pampers Premium Care 4 (9-14кг)", description: "Упаковка 76 шт", price: 4500, category: "Подгузники", sellerName: "Айгуль", condition: "Новое"),
            Product(id: "p2", title: "Huggies Ultra Comfort 3 (6-10кг)", description: "Упаковка 64 шт", price: 3800, category: "Подгузники", sellerName: "Мария", condition: "Новое"),
            Product(id: "p3", title: "Bepanthen крем 100г", description: "Защита от опрелостей", price: 3200, category: "Уход", sellerName: "Светлана", condition: "Новое"),
            Product(id: "p4", title: "Соска Philips Avent", description: "Силиконовая, 0-6 мес", price: 2800, category: "Аксессуары", sellerName: "Динара", condition: "Новая"),
            Product(id: "p5", title: "Комбинезон зимний", description: "Размер 80", price: 6500, category: "Одежда", sellerName: "Елена", condition: "Б/у"),
            Product(id: "p6", title: "Развивающий кубик", description: "Мягкий, звуковой", price: 1500, category: "Игрушки", sellerName: "Назира", condition: "Б/у"),
            Product(id: "p7", title: "Молочная смесь Nutrilon 2", description: "800г", price: 4200, category: "Питание", sellerName: "Айгуль", condition: "Новое"),
            Product(id: "p8", title: "Pampers Premium Care 5 (12-17кг)", description: "Упаковка 64 шт", price: 4800, category: "Подгузники", sellerName: "Мария", condition: "Новое"),
        ]
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
                
                Image(systemName: productIcon(product.category))
                    .font(.system(size: 40))
                    .foregroundColor(.peachPrimary.opacity(0.4))
                
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
        return cond == "Новое" || cond == "Новая"
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
    @State private var title = ""
    @State private var descriptionText = ""
    @State private var price = ""
    @State private var category = "Подгузники"
    @State private var condition = "Новое"
    
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
        }
    }
    
    private var addPhotoButton: some View {
        Button {} label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.peachSurface)
                    .frame(height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(Color.peachLight)
                    )
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
            dismiss()
        } label: {
            Text("Опубликовать")
        }
        .peachButton()
        .padding(.top, 8)
    }
}
