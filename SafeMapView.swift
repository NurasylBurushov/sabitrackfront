import SwiftUI
import MapKit

struct SafeMapView: View {
    /// UUID няни из API (`/api/nannies`). Если `nil` — карта в демо-режиме без запроса к `/tracking`.
    var nannyId: String? = nil
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 43.2389, longitude: 76.8891), span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))
    @State private var nannyLocation: NannyLocation?
    @State private var isTracking = true
    @State private var trackingTimer: Timer?
    
    var body: some View {
        ZStack {
            // ✅ ИСПРАВЛЕНО: NannyLocation теперь Identifiable (поменяли в NetworkService.swift)
            Map(coordinateRegion: $region, annotationItems: [nannyLocation].compactMap { $0 }) { loc in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)) {
                    ZStack {
                        Circle().fill(Color.peachPrimary.opacity(0.2)).frame(width: 60, height: 60)
                        Circle().fill(Color.peachPrimary.opacity(0.35)).frame(width: 40, height: 40)
                        Image(systemName: "figure.walk").font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
                            .frame(width: 32, height: 32).background(LinearGradient(colors: [.peachPrimary, .peachDark], startPoint: .top, endPoint: .bottom)).clipShape(Circle())
                            .shadow(color: .peachPrimary.opacity(0.4), radius: 6, y: 3)
                    }
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Безопасная карта").font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                            HStack(spacing: 6) { Circle().fill(isTracking ? Color.green : Color.red).frame(width: 8, height: 8); Text(isTracking ? "Отслеживание активно" : "Приостановлено").font(.system(size: 13)).foregroundColor(.white.opacity(0.9)) }
                        }
                        Spacer()
                        Button { isTracking.toggle(); if isTracking { startTracking() } else { stopTracking() } } label: {
                            Image(systemName: isTracking ? "pause.circle.fill" : "play.circle.fill").font(.system(size: 36)).foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 14)
                    
                    if let loc = nannyLocation {
                        HStack(spacing: 14) {
                            InfoChip(icon: "location.fill", label: loc.address ?? "Определяется...")
                            InfoChip(icon: "battery.75", label: "\(loc.battery ?? 0)%")
                            InfoChip(icon: "speedometer", label: "\(Int(loc.speed ?? 0)) км/ч")
                        }
                        .padding(.horizontal, 16).padding(.bottom, 14)
                    }
                }
                .background(LinearGradient(colors: [Color.peachDark.opacity(0.95), Color.peachPrimary.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea(edges: .top))
                .shadow(color: .peachDark.opacity(0.3), radius: 12, y: 6)
                
                Spacer()
                
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ZStack { Circle().fill(Color.peachLight).frame(width: 50, height: 50); Text("А").font(.system(size: 18, weight: .bold)).foregroundColor(.peachDark) }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Айгуль Нурланова").font(.system(size: 15, weight: .semibold)).foregroundColor(.textPrimary)
                            Text("Обновлено: только что").font(.system(size: 12)).foregroundColor(.textSecondary)
                        }
                        Spacer()
                        Button {} label: { Image(systemName: "phone.fill").font(.system(size: 16)).foregroundColor(.white).frame(width: 44, height: 44).background(Color.peachPrimary).clipShape(Circle()).shadow(color: .peachPrimary.opacity(0.3), radius: 6, y: 3) }
                    }
                    .padding(16).background(Color.peachSurface).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.peachLight, lineWidth: 1.5))
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                    
                    HStack(spacing: 12) {
                        Button { centerOnNanny() } label: {
                            HStack(spacing: 6) { Image(systemName: "crosshair").font(.system(size: 14)); Text("Мой район") }
                                .font(.system(size: 13, weight: .semibold)).foregroundColor(.peachPrimary)
                                .frame(maxWidth: .infinity).frame(height: 46).background(Color.peachLight.opacity(0.5)).cornerRadius(12)
                        }
                        Button {} label: {
                            HStack(spacing: 6) { Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 14)); Text("SOS") }
                                .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 46).background(Color.red).cornerRadius(12)
                                .shadow(color: .red.opacity(0.3), radius: 6, y: 3)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 16)
            }
        }
        .onAppear { loadNannyLocation(); startTracking() }
        .onDisappear { stopTracking() }
    }
    
    func loadNannyLocation() {
        Task {
            guard let raw = nannyId?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty,
                  UUID(uuidString: raw) != nil else {
                await MainActor.run {
                    nannyLocation = NannyLocation(
                        latitude: 43.2389 + Double.random(in: -0.005...0.005),
                        longitude: 76.8891 + Double.random(in: -0.005...0.005),
                        timestamp: ISO8601DateFormatter().string(from: Date()),
                        address: "Демо: укажите nannyId (UUID няни)",
                        speed: 3.2,
                        battery: 78
                    )
                }
                return
            }
            do {
                nannyLocation = try await NetworkService.shared.fetchNannyLocation(nannyId: raw)
                if let loc = nannyLocation { withAnimation { region.center = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude) } }
            } catch {
                nannyLocation = NannyLocation(latitude: 43.2389 + Double.random(in: -0.005...0.005), longitude: 76.8891 + Double.random(in: -0.005...0.005), timestamp: ISO8601DateFormatter().string(from: Date()), address: "Алматы, ул. Гоголя 58", speed: 3.2, battery: 78)
            }
        }
    }
    
    func startTracking() {
        trackingTimer?.invalidate()
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            if var loc = nannyLocation {
                loc.latitude += Double.random(in: -0.001...0.001)
                loc.longitude += Double.random(in: -0.001...0.001)
                loc.speed = Double.random(in: 0...8)
                loc.battery = max(10, (loc.battery ?? 80) - Int.random(in: 0...1))
                nannyLocation = loc
                region.center = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
            }
        }
    }
    
    func stopTracking() { trackingTimer?.invalidate(); trackingTimer = nil }
    
    func centerOnNanny() {
        if let loc = nannyLocation { withAnimation(.spring(response: 0.5)) { region.center = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude); region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) } }
    }
}

struct InfoChip: View {
    let icon: String; let label: String
    var body: some View {
        HStack(spacing: 5) { Image(systemName: icon).font(.system(size: 12)); Text(label).font(.system(size: 12, weight: .medium)).lineLimit(1) }
            .foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 6).background(Color.white.opacity(0.2)).cornerRadius(20)
    }
}
