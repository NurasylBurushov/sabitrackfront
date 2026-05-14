import SwiftUI

struct SideSelectionView: View {
    var onComplete: () -> Void
    @State private var selectedSide: String? = nil
    @State private var searchText = ""
    @State private var selectedFilter: String = "Все"
    @State private var showFilters = false
    @State private var selectedAge: String? = nil
    @State private var selectedExperience: String? = nil
    @State private var priceRange: ClosedRange<Double> = 0...50000
    @State private var selectedRating: Double = 0
    @State private var nannies: [Nanny] = []
    @State private var loadError: String?
    
    // ✅ Правильный способ закрытия экрана
    @Environment(\.dismiss) var dismiss
    
    let filters = ["Все", "Няня", "Домработница", "Сиделка", "Гувернантка", "Репетитор"]
    let ageFilters = ["20-30", "30-40", "40-50", "50+"]
    let experienceFilters = ["От 1 года", "От 3 лет", "От 5 лет", "От 10 лет"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.peachBg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        
                        // ✅ РАБОЧАЯ КНОПКА ЗАКРЫТИЯ (КРЕСТИК)
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                    .frame(width: 40, height: 40)
                                    .background(Color.peachSurface)
                                    .cornerRadius(12)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        
                        // Заголовок
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Выберите сторону")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.textPrimary)
                            Text("Найдите идеального специалиста для вашей семьи")
                                .font(.system(size: 14)).foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        
                        // Поиск
                        HStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass").foregroundColor(.textMuted)
                                TextField("Поиск по имени, навыкам...", text: $searchText)
                                    .font(.system(size: 15))
                            }
                            .padding(.horizontal, 14).frame(height: 48).background(Color.peachSurface).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.peachLight, lineWidth: 1.5))
                            
                            Button { withAnimation { showFilters.toggle() } } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 18, weight: .medium)).foregroundColor(.white)
                                    .frame(width: 48, height: 48)
                                    .background(LinearGradient(colors: [.peachPrimary, .peachDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .cornerRadius(14)
                                    .shadow(color: .peachPrimary.opacity(0.3), radius: 8, y: 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Фильтры
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(filters, id: \.self) { filter in
                                    Button {
                                        withAnimation { selectedFilter = filter }
                                    } label: {
                                        Text(filter)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(selectedFilter == filter ? .white : .textSecondary)
                                            .padding(.horizontal, 16).padding(.vertical, 10)
                                            .background(
                                                Group {
                                                    if selectedFilter == filter {
                                                        LinearGradient(colors: [.peachPrimary, .peachDark], startPoint: .leading, endPoint: .trailing)
                                                    } else {
                                                        Color.peachSurface
                                                    }
                                                }
                                            )
                                            .cornerRadius(25)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 25)
                                                    .stroke(selectedFilter == filter ? Color.clear : Color.peachLight, lineWidth: 1.5)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 16)
                        
                        if showFilters { filterPanel.padding(.horizontal, 20).padding(.top, 16).transition(.move(edge: .top).combined(with: .opacity)) }
                        
                        // Список нянь
                        VStack(spacing: 12) {
                            ForEach(filteredNannies) { nanny in
                                NannyCard(nanny: nanny, isSelected: selectedSide == nanny.id) {
                                    withAnimation { selectedSide = nanny.id }
                                }
                            }
                        }
                        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 100)
                    }
                }
                
                // Кнопка продолжить
                VStack {
                    Spacer()
                    if selectedSide != nil {
                        Button { onComplete() } label: {
                            HStack { Text("Продолжить"); Image(systemName: "arrow.right") }
                        }
                        .peachButton().padding(.horizontal, 20).padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { loadNannies() }
            .alert("Ошибка загрузки нянь", isPresented: Binding(
                get: { loadError != nil },
                set: { if !$0 { loadError = nil } }
            )) {
                Button("OK", role: .cancel) { loadError = nil }
            } message: {
                Text(loadError ?? "")
            }
        }
    }
    
    var filterPanel: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Расширенные фильтры").font(.system(size: 16, weight: .semibold)).foregroundColor(.textPrimary)
                Spacer()
                Button("Сбросить") {
                    selectedAge = nil; selectedExperience = nil; selectedRating = 0; priceRange = 0...50000
                }
                .font(.system(size: 13, weight: .medium)).foregroundColor(.peachPrimary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Возраст").font(.system(size: 13, weight: .medium)).foregroundColor(.textSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ageFilters, id: \.self) { age in
                            Button { selectedAge = selectedAge == age ? nil : age } label: {
                                Text(age).font(.system(size: 12, weight: .medium))
                                    .foregroundColor(selectedAge == age ? .white : .textSecondary)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(selectedAge == age ? Color.peachPrimary : Color.peachSurface).cornerRadius(20)
                            }
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Опыт").font(.system(size: 13, weight: .medium)).foregroundColor(.textSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(experienceFilters, id: \.self) { exp in
                            Button { selectedExperience = selectedExperience == exp ? nil : exp } label: {
                                Text(exp).font(.system(size: 12, weight: .medium))
                                    .foregroundColor(selectedExperience == exp ? .white : .textSecondary)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(selectedExperience == exp ? Color.peachPrimary : Color.peachSurface).cornerRadius(20)
                            }
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Минимальный рейтинг").font(.system(size: 13, weight: .medium)).foregroundColor(.textSecondary)
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Button { selectedRating = selectedRating == Double(star) ? 0 : Double(star) } label: {
                            Image(systemName: star <= Int(selectedRating) ? "star.fill" : "star")
                                .font(.system(size: 22))
                                .foregroundColor(star <= Int(selectedRating) ? .peachPrimary : .textMuted)
                        }
                    }
                    if selectedRating > 0 { Text("\(Int(selectedRating)).0+").font(.system(size: 13, weight: .medium)).foregroundColor(.peachPrimary) }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Цена за час: \(Int(priceRange.lowerBound)) - \(Int(priceRange.upperBound)) ₸")
                    .font(.system(size: 13, weight: .medium)).foregroundColor(.textSecondary)
                RangeSlider(range: $priceRange, bounds: 0...50000)
            }
        }
        .padding(16).background(Color.peachSurface).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.peachLight, lineWidth: 1.5))
    }
    
    var filteredNannies: [Nanny] {
        var result = nannies
        if !searchText.isEmpty { result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) } }
        if selectedFilter != "Все" { result = result.filter { $0.categories?.contains(selectedFilter) ?? false } }
        if selectedRating > 0 { result = result.filter { $0.rating >= selectedRating } }
        result = result.filter { $0.pricePerHour >= Int(priceRange.lowerBound) && $0.pricePerHour <= Int(priceRange.upperBound) }
        return result
    }
    
    func loadNannies() {
        Task {
            await MainActor.run { loadError = nil }
            do {
                let list = try await NetworkService.shared.fetchNannies(filter: nil, search: nil)
                await MainActor.run {
                    nannies = list
                    loadError = nil
                }
            } catch {
                await MainActor.run {
                    nannies = []
                    loadError = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }
}

struct NannyCard: View {
    let nanny: Nanny
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(LinearGradient(colors: [.peachLight, .peachPrimary.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 60, height: 60)
                    Text(String(nanny.name.prefix(1))).font(.system(size: 22, weight: .bold)).foregroundColor(.peachDark)
                    if nanny.verified == true {
                        Image(systemName: "checkmark.seal.fill").font(.system(size: 14)).foregroundColor(.peachPrimary)
                            .background(Circle().fill(.white)).offset(x: 20, y: 18)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(nanny.name).font(.system(size: 16, weight: .semibold)).foregroundColor(.textPrimary)
                        Spacer()
                        if isSelected { Image(systemName: "checkmark.circle.fill").foregroundColor(.peachPrimary).font(.system(size: 22)) }
                    }
                    HStack(spacing: 12) {
                        HStack(spacing: 3) { Image(systemName: "star.fill").font(.system(size: 11)).foregroundColor(.peachPrimary); Text(String(format: "%.1f", nanny.rating)).font(.system(size: 12, weight: .medium)).foregroundColor(.textSecondary) }
                        HStack(spacing: 3) { Image(systemName: "briefcase.fill").font(.system(size: 11)).foregroundColor(.peachPrimary); Text("\(nanny.experience) лет").font(.system(size: 12, weight: .medium)).foregroundColor(.textSecondary) }
                        if let age = nanny.age { HStack(spacing: 3) { Image(systemName: "person.fill").font(.system(size: 11)).foregroundColor(.peachPrimary); Text("\(age) лет").font(.system(size: 12, weight: .medium)).foregroundColor(.textSecondary) } }
                    }
                    if let loc = nanny.location { HStack(spacing: 3) { Image(systemName: "location.fill").font(.system(size: 10)).foregroundColor(.textMuted); Text(loc).font(.system(size: 12)).foregroundColor(.textMuted).lineLimit(1) } }
                }
                VStack { Text("\(nanny.pricePerHour)").font(.system(size: 16, weight: .bold)).foregroundColor(.peachPrimary); Text("₸/час").font(.system(size: 11)).foregroundColor(.textMuted) }.padding(.leading, 4)
            }
            .padding(16)
            .background(isSelected ? Color.peachLight.opacity(0.5) : Color.peachSurface)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? Color.peachPrimary : Color.peachLight, lineWidth: isSelected ? 2 : 1.5))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RangeSlider: UIViewRepresentable {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    
    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider()
        slider.minimumValue = Float(bounds.lowerBound)
        slider.maximumValue = Float(bounds.upperBound)
        slider.value = Float(range.upperBound)
        slider.minimumTrackTintColor = UIColor(Color.peachPrimary)
        slider.maximumTrackTintColor = UIColor(Color.peachLight)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.changed), for: .valueChanged)
        return slider
    }
    
    func updateUIView(_ uiView: UISlider, context: Context) { uiView.value = Float(range.upperBound) }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject {
        var parent: RangeSlider
        init(_ parent: RangeSlider) { self.parent = parent }
        @objc func changed(_ slider: UISlider) { parent.range = parent.range.lowerBound...Double(slider.value) }
    }
}
