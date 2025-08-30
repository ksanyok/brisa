import SwiftUI

/// Представление списка задач. В MVP отображает заглушку, что задач пока нет.
struct TasksView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Очередь задач")
                .font(.title)
                .padding(.top, 8)
            Text("Пока задач нет")
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 400, minHeight: 300)
        .padding()
    }
}

struct TasksView_Previews: PreviewProvider {
    static var previews: some View {
        TasksView()
    }
}