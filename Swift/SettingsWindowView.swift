import SwiftUI

enum SettingsTab {
    case home
    case settings
}

struct SettingsWindowView: View {
    @State private var selectedTab: SettingsTab = .home
    
    var body: some View {
        HSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // Home Tab
                SidebarButton(
                    icon: "house.fill",
                    title: "Home",
                    isSelected: selectedTab == .home
                ) {
                    selectedTab = .home
                }
                
                // Settings Tab
                SidebarButton(
                    icon: "gearshape.fill",
                    title: "Settings",
                    isSelected: selectedTab == .settings
                ) {
                    selectedTab = .settings
                }
                
                Spacer()
            }
            .frame(width: 180)
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

struct SidebarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsWindowView()
        .frame(width: 700, height: 500)
}


