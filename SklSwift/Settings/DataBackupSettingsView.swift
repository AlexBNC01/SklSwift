// файл DataBackupSettingsView
import SwiftUI
import UniformTypeIdentifiers

struct DataBackupSettingsView: View {
    @State private var showExportShareSheet = false
    @State private var exportFileURL: URL?
    
    @State private var showDocumentPicker = false
    @State private var alertMessage: String?
    @State private var showAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("Резервное копирование данных")) {
                Button("Экспортировать данные") {
                    if let url = DataBackupManager.exportData() {
                        exportFileURL = url
                        showExportShareSheet = true
                    } else {
                        alertMessage = "Ошибка экспорта данных"
                        showAlert = true
                    }
                }
                Button("Импортировать данные") {
                    showDocumentPicker = true
                }
            }
        }
        .navigationTitle("Резервное копирование")
        .sheet(isPresented: $showExportShareSheet, onDismiss: {
            if let url = exportFileURL {
                try? FileManager.default.removeItem(at: url)
                exportFileURL = nil
            }
        }) {
            if let url = exportFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(documentTypes: [UTType.json]) { result in
                switch result {
                case .success(let url):
                    DataBackupManager.importData(from: url)
                    alertMessage = "Импорт данных выполнен успешно."
                case .failure(let error):
                    alertMessage = "Ошибка импорта: \(error.localizedDescription)"
                }
                showAlert = true
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Сообщение"),
                  message: Text(alertMessage ?? ""),
                  dismissButton: .default(Text("OK")))
        }
    }
}

struct DataBackupSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DataBackupSettingsView()
        }
    }
}

// Обёртка для UIDocumentPickerViewController, позволяющая выбрать JSON-файл
struct DocumentPicker: UIViewControllerRepresentable {
    var documentTypes: [UTType]
    var onPick: (Result<URL, Error>) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: documentTypes, asCopy: true)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPick: (Result<URL, Error>) -> Void
        
        init(onPick: @escaping (Result<URL, Error>) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                onPick(.success(url))
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPick(.failure(NSError(domain: "DocumentPicker",
                                      code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: "Cancelled"])))
        }
    }
}
