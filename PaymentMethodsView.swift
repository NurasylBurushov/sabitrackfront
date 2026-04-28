import SwiftUI

struct PaymentMethodsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var methods: [PaymentMethod] = []
    @State private var showAddCard = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.peachBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Основная карта
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Основная карта")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                    Text("•••• •••• •••• 4532")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .tracking(2)
                                }
                                Spacer()
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            HStack {
                                Text("VISA")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                Text("12/28")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.top, 20)
                        }
                        .padding(20)
                        .background(
                            LinearGradient(
                                colors: [.peachPrimary, .peachDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: .peachPrimary.opacity(0.3), radius: 12, y: 6)
                        
                        // Все способы оплаты
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Все способы оплаты")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.textPrimary)
                            
                            ForEach(methods) { method in
                                PaymentMethodRow(method: method)
                            }
                        }
                        
                        // Добавить
                        Button {
                            showAddCard = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.peachPrimary)
                                Text("Добавить способ оплаты")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.peachPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.peachLight.opacity(0.4))
                            .cornerRadius(14)
                            // ✅ ИСПРАВЛЕНО: используем StrokeStyle для пунктирной линии
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [8]))
                                    .foregroundColor(Color.peachPrimary.opacity(0.3))
                            )
                        }
                        .padding(.top, 8)
                        
                        // Другие способы
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Другие способы")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            AltPaymentRow(icon: "smartphone", name: "Kaspi Pay", subtitle: "Быстрая оплата")
                            AltPaymentRow(icon: "wave.3.right", name: "Безналичный перевод", subtitle: "Через банковское приложение")
                        }
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Способы оплаты")
            .navigationBarTitleDisplayMode(.inline)
            // ✅ ИСПРАВЛЕНО: заменили .topBarLeading на .cancellationAction
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Готово") { dismiss() }
                        .foregroundColor(.peachPrimary)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .sheet(isPresented: $showAddCard) {
                AddCardView()
            }
            .onAppear { loadMethods() }
        }
    }
    
    func loadMethods() {
        methods = [
            PaymentMethod(id: "pm1", type: "card", last4: "4532", brand: "VISA", isDefault: true),
            PaymentMethod(id: "pm2", type: "card", last4: "8901", brand: "MasterCard", isDefault: false),
        ]
    }
}

struct PaymentMethodRow: View {
    let method: PaymentMethod
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(method.brand == "VISA" ? Color.blue.opacity(0.12) : Color.orange.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 20))
                    .foregroundColor(method.brand == "VISA" ? .blue : .orange)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(method.brand ?? "Карта") •••• \(method.last4 ?? "****")")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textPrimary)
                Text(method.isDefault == true ? "Основная" : "Дополнительная")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
            }
            
            Spacer()
            
            if method.isDefault == true {
                Text("По умолч.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.peachPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.peachLight.opacity(0.5))
                    .cornerRadius(8)
            }
        }
        .padding(14)
        .background(Color.peachSurface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.peachLight, lineWidth: 1)
        )
    }
}

struct AltPaymentRow: View {
    let icon: String
    let name: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Color.peachLight.opacity(0.5)
                    .frame(width: 44, height: 44)
                    .cornerRadius(10)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.peachPrimary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.textMuted)
        }
        .padding(14)
        .background(Color.peachSurface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.peachLight, lineWidth: 1)
        )
    }
}

struct AddCardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var cardNumber = ""
    @State private var expiry = ""
    @State private var cvv = ""
    @State private var holderName = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.peachBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Превью карты
                        VStack(spacing: 0) {
                            HStack {
                                Text("Новая карта")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Text(cardNumber.isEmpty ? "•••• •••• •••• ••••" : formatCardNumber(cardNumber))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .tracking(2)
                                .padding(.top, 20)
                            
                            HStack {
                                Text(holderName.isEmpty ? "ИМЯ ВЛАДЕЛЬЦА" : holderName.uppercased())
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text(expiry.isEmpty ? "MM/ГГ" : expiry)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.top, 24)
                        }
                        .padding(20)
                        .background(
                            LinearGradient(
                                colors: [Color.peachPrimary.opacity(0.7), Color.peachDark.opacity(0.8)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: .peachPrimary.opacity(0.2), radius: 12, y: 6)
                        .padding(.top, 20)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Номер карты")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textSecondary)
                            peachTextField("0000 0000 0000 0000", text: $cardNumber)
                                .keyboardType(.numberPad)
                                .onChange(of: cardNumber) { _ in
                                    if cardNumber.count > 16 { cardNumber = String(cardNumber.prefix(16)) }
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Имя владельца")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textSecondary)
                            peachTextField("IVAN IVANOV", text: $holderName)
                                .textInputAutocapitalization(.characters)
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Срок")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.textSecondary)
                                peachTextField("MM/ГГ", text: $expiry)
                                    .keyboardType(.numberPad)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("CVV")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.textSecondary)
                                peachSecureField("•••", text: $cvv)
                                    .keyboardType(.numberPad)
                            }
                        }
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Привязать карту")
                        }
                        .peachButton()
                        .padding(.top, 8)
                        
                        Text("Данные карты защищены шифрованием")
                            .font(.system(size: 12))
                            .foregroundColor(.textMuted)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Новая карта")
            .navigationBarTitleDisplayMode(.inline)
            // ✅ ИСПРАВЛЕНО: и здесь заменили
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(.peachPrimary)
                }
            }
        }
    }
    
    func formatCardNumber(_ number: String) -> String {
        var result = ""
        for (index, char) in number.enumerated() {
            if index > 0 && index % 4 == 0 { result += " " }
            result += String(char)
        }
        return result
    }
}
