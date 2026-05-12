import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            BridgeWebView(url: AppConfig.privacyPolicyURL)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(Palette.jungleDeep.opacity(0.78))
                        .frame(width: 36, height: 36)
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(Palette.textLight)
                }
                .overlay(
                    Circle().stroke(Palette.aqua.opacity(0.18), lineWidth: 0.5)
                )
            }
            .padding(.top, 12)
            .padding(.trailing, 16)
        }
        .background(Palette.jungleDeep.ignoresSafeArea())
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
