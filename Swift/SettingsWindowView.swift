import SwiftUI

enum SettingsTab {
    case home
    case settings
}

struct SettingsWindowView: View {
    @State private var selectedTab: SettingsTab = .home
    
    
    var body: some View {
        HSplitView {
            // Minimal Sidebar with Icons Only
            VStack(spacing: 8) {
                // Home Tab
                SidebarIconButton(
                    icon: "house.fill",
                    isSelected: selectedTab == .home
                ) {
                    selectedTab = .home
                }
                
                // Settings Tab
                SidebarIconButton(
                    icon: "gearshape.fill",
                    isSelected: selectedTab == .settings
                ) {
                    selectedTab = .settings
                }
                
                Spacer()
            }
            .frame(width: 60)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Content Area
            Group {
                switch selectedTab {
                case .home:
                    HomeTabView()
                case .settings:
                    SettingsTabView()
                }
            }
            .frame(minWidth: 400, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        }
    }
}

struct SidebarIconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsWindowView()
        .frame(width: 700, height: 500)
}


