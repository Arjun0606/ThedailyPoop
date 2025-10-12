import SwiftUI
import Contacts

struct InviteFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var contactsManager = ContactsManager()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("Search Contacts", text: $searchText)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Contacts List
                    List(contactsManager.contacts.filter { searchText.isEmpty ? true : $0.givenName.contains(searchText) }) { contact in
                        HStack {
                            Text(contact.givenName)
                            Spacer()
                            Button("Invite") {
                                // TODO: Implement sending invite
                            }
                        }
                    }
                }
                .navigationTitle("Invite Friends")
                .navigationBarItems(trailing: Button("Done") {
                    dismiss()
                })
                .onAppear {
                    contactsManager.requestAccess()
                }
            }
        }
    }
}

class ContactsManager: ObservableObject {
    @Published var contacts = [CNContact]()
    
    func requestAccess() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { (granted, error) in
            if let error = error {
                print("Failed to request access", error)
                return
            }
            if granted {
                self.fetchContacts()
            } else {
                print("Access denied")
            }
        }
    }
    
    private func fetchContacts() {
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        
        do {
            try CNContactStore().enumerateContacts(with: request) { (contact, stop) in
                DispatchQueue.main.async {
                    self.contacts.append(contact)
                }
            }
        } catch {
            print("Failed to fetch contacts", error)
        }
    }
}
