//
//  onDeandBookDetailsViewWithClosures.swift
//  CombineFirebaseBookShelf
//
//  Created by 김동영 on 4/9/25.
//

import SwiftUI
import FirebaseFirestore
import Combine

private class BookListViewModel : ObservableObject {
    @Published var books: [Book] = []
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    
    init() {
        db.collection("books").snapshotPublisher()
            .map { querySnapshot in
                querySnapshot.documents.compactMap { documentSnapshot in
                    try? documentSnapshot.data(as: Book.self)
                }
            }
            .catch { error in
                self.errorMessage = error.localizedDescription
                return Just([Book]()).eraseToAnyPublisher()
            }
            .replaceError(with: [Book]())
            .assign(to: &$books)
    }
}

struct CombineBookListView: View {
    @StateObject private var viewModel = BookListViewModel()
    
    var body: some View {
        List(viewModel.books) { book in
            Text(book.title)
            Text(book.author)
            Text("\(book.numberOfPages)")
        }
        .navigationTitle("Book List")
    }
}
