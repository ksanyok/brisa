import SwiftUI

/// Представление, отображающее поток экрана агента и текущий шаг.
struct CloneView: View {
    // В MVP поток экрана пока не реализован, поэтому отображается заглушка.
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("Clone View")
                .font(.title)
            Text("Поток экрана агента будет отображаться здесь.")
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

struct CloneView_Previews: PreviewProvider {
    static var previews: some View {
        CloneView()
    }
}