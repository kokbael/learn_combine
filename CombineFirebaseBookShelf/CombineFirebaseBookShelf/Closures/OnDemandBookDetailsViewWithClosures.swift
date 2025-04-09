//
//  onDeandBookDetailsViewWithClosures.swift
//  CombineFirebaseBookShelf
//
//  Created by 김동영 on 4/9/25.
//

import SwiftUI
import FirebaseFirestore

private class BookDetailViewModel: ObservableObject {
    @Published var book = Book.empty
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    
    fileprivate func  fetchBook() {
        let docRef = db.collection("books").document("hitchhiker")
        
        docRef.getDocument(as: Book.self) { result in
            switch result {
            case .success(let book):
                self.book = book
                self.errorMessage = nil
            case .failure(let error):
                self.book = Book.empty
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

struct OnDemandBookDetailsViewWithClosures: View {
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
        .onAppear {
            viewModel.fetchBook()
        }
        .refreshable {
            viewModel.fetchBook()
        }
    }
}
