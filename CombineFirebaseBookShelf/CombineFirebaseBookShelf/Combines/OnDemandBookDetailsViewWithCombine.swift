//
//  onDeandBookDetailsViewWithClosures.swift
//  CombineFirebaseBookShelf
//
//  Created by 김동영 on 4/9/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine

private class BookDetailViewModel: ObservableObject {
    @Published var book = Book.empty
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    
    init() {
        db.collection("books").document("hitchhiker").snapshotPublisher()
            .tryMap { documentSnapshot in
                try documentSnapshot.data(as: Book.self)
            }
            .catch { error in
                self.errorMessage = error.localizedDescription
                return Just(Book.empty).eraseToAnyPublisher()
            }
            .replaceError(with: Book.empty)
            .assign(to: &$book)
    }
}

struct OnDemandBookDetailsViewWithCombine: View {
    @StateObject private var viewModel = BookDetailViewModel()
    
    var body: some View {
        Form {
            Section{
                Text(viewModel.book.title)
                    .font(.title)
                    .padding()
                Text(viewModel.book.author)
                    .font(.headline)
                    .padding()
                Text("\(viewModel.book.numberOfPages) pages")
                    .font(.subheadline)
                    .padding()
            } footer: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
        .navigationTitle("Book Details")
    }
}
