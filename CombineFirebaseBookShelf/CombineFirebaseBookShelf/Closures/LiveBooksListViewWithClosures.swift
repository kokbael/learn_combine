//
//  onDeandBookDetailsViewWithClosures.swift
//  CombineFirebaseBookShelf
//
//  Created by 김동영 on 4/9/25.
//

import SwiftUI
import FirebaseFirestore

private class LiveBookListViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var numberOfBooks = 0
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    private var listenerResgistration: ListenerRegistration?
    
    fileprivate func unsubscribe() {
        if listenerResgistration != nil {
            listenerResgistration?.remove()
            listenerResgistration = nil
        }
    }
    
    fileprivate func subscribe() {
        if listenerResgistration == nil {
            listenerResgistration = db.collection("books").addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("guard")
                    self?.errorMessage = error?.localizedDescription ?? "No documents in 'books' collection"
                    return
                }
                
                self?.books = documents.compactMap { querySnapshotDocument in
                    let result = Result { try querySnapshotDocument.data(as: Book.self) }
                    switch result {
                    case .success(let book):
                        print("success")
                        self?.errorMessage = nil
                        return book
                    case .failure(let error):
                        print("failure")
                        self?.errorMessage = error.localizedDescription
                        return nil
                    }
                }
            }
        }
    }
    
}

struct LiveBooksListViewWithClosures: View {
    @StateObject private var viewModel = LiveBookListViewModel()
    
    var body: some View {
        List(viewModel.books) { book in
            Text(book.title)
        }
        .onAppear {
            viewModel.subscribe()
        }
        .onDisappear {
            viewModel.unsubscribe()
        }
        .navigationTitle("Book Live")
    }
}
