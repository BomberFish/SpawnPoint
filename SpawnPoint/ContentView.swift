// bomberfish
// ContentView.swift – SpawnPoint
// created on 2023-11-28

import SwiftUI

struct ContentView: View {
    var dir: URL = .init(fileURLWithPath: "/")
    @State var popupShown: Bool = true
    var body: some View {
        NavigationStack {
            List {
                ForEach(getFiles(dir), id: \.self) { file in
                    if file.isDirectory || file.isSymLink {
                        NavigationLink(destination: ContentView(dir: file)) {
                            HStack {
                                Image(systemName: "folder")
                                Text(file.lastPathComponent)
                            }
                        }
                    } else {
                        let analysis = analyzeMachO(file)
                        if analysis != nil {
                            Button(action: {
                                popupShown = true
                            }, label: {
                                HStack {
                                    Image(systemName: analysis == nil ? "doc" : "terminal.fill")
                                    VStack(alignment: .leading) {
                                        Text(file.lastPathComponent)
                                        if analysis != nil {
                                            Text(analysis?.rawValue ?? "Regular file")
                                                .foregroundColor(.secondary)
                                                .font(.footnote)
                                        }
                                    }
                                }
                            })
                            .disabled(analysis == nil)
                            .confirmationDialog("Select user to run \(file.lastPathComponent)", isPresented: $popupShown, actions: {
                                Button(action: {
                                    spawnRoot(file.path, [], nil, nil)
                                }, label: {
                                    Text("root")
                                })
                                
                                Button(action: {
                                    spawnNonRoot(file.path, [], nil, nil)
                                }, label: {
                                    Text("mobile")
                                })
                            })
                        }
                    }
                }
            }
            .navigationTitle(dir == .init(fileURLWithPath: "/") ? "SpawnPoint" : dir.lastPathComponent)
        }
    }
}

enum MachOFileType: String {
    case thirtytwoLE = "Mach-O 32-bit Little Endian"
    case sixtyFourLE = "Mach-O 64-bit Little Endian"
    case thirtytwoBE = "Mach-O 32-bit Big Endian"
    case sixtyFourBE = "Mach-O 64-bit Big Endian"
    case fat = "Mach-O Universal Binary"
}

func analyzeMachO(_ file: URL) -> MachOFileType? {
    do {
        let data: Data = try .init(contentsOf: file)
        let magic = data.subdata(in: 0..<4)
        
        switch magic {
        case Data([]):
            throw "File was empty"
        case Data([0xCE, 0xFA, 0xED, 0xFE]):
            return .thirtytwoLE
        case Data([0xCF, 0xFA, 0xED, 0xFE]):
            return .sixtyFourLE
        case Data([0xFE, 0xED, 0xFA, 0xCE]):
            return .thirtytwoBE
        case Data([0xFE, 0xED, 0xFA, 0xCF]):
            return .sixtyFourBE
        case Data([0xCA, 0xFE, 0xBA, 0xBE]):
            return .fat
        default:
            throw "File is not Mach-O"
        }
    } catch {
        print("Error occurred checking: \(error). Silently failing.")
        return nil
    }
}

func getFiles(_ dir: URL) -> [URL] {
    do {
        return try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
    } catch {
        print(error)
        UIApplication.shared.alert(body: error.localizedDescription)
        return []
    }
}
