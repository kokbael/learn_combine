//
//  SignUpFormViewModel.swift
//  CombineDemo
//
//  Created by 김동영 on 4/7/25.
//

import Foundation
import Combine

enum UserNameValid {
    case valid
    case tooShort
    case notAvailable
}

class SignUpFormViewModel: ObservableObject {
    // 유저 입력 프로퍼티
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var passwordConfirmation: String = ""
    
    // 출력 프로퍼티
    @Published var usernameMessage: String = ""
    @Published var passwordMessage: String = ""
    @Published var isValid: Bool = false
    
    var authenticationService = AuthenticationService()
    
    // 유저이름 유효성 검사 (3자 이상)
    private lazy var isUsernameLengthValidPublisher: AnyPublisher<Bool, Never> = {
        $username
            .map { $0.count >= 3 }
            .eraseToAnyPublisher()
    }()
    
    private lazy var isUsernameAvaliablePublisher: AnyPublisher<Bool, Never> = {
        $username
            .debounce(for: 0.8, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .compactMap { username -> String? in
                // 유저 이름이 비어있으면 nil을 반환
                if username.isEmpty {
                    return nil
                }
                return username
            }
            .flatMap { username -> AnyPublisher<Bool, Never> in
                return self.authenticationService.checkUserNameAvailableNaive(userName: username)
            }
            .receive(on: DispatchQueue.main)
            .share()
            .eraseToAnyPublisher()
    }()
    
    private lazy var isUsernameValidPublisher: AnyPublisher<UserNameValid, Never> = {
        Publishers.CombineLatest(isUsernameLengthValidPublisher, isUsernameAvaliablePublisher)
            .map { isLengthValid, isAvailable in
                if !isLengthValid {
                    return .tooShort
                } else if !isAvailable {
                    return .notAvailable
                } else {
                    return .valid
                }
            }
            .eraseToAnyPublisher()
    }()
    
    // 비밀번호 유효성 검사 (비밀번호가 비어있음을 검사)
    private lazy var isPasswordEmptyPublisher: AnyPublisher<Bool, Never> = {
        $password
         // .map { $0.isEmpty } 을 다음과 같이 축약해서 사용할 수 있다.
            .map(\.isEmpty)
            .eraseToAnyPublisher()
    }()
    
    // 비밀번호와 비밀번호 확인 일치 검사
    private lazy var isPasswordMatchingPublisher: AnyPublisher<Bool, Never> = {
        Publishers.CombineLatest($password, $passwordConfirmation)
         // .map { $0 == $1 } 을 다음과 같이 축약해서 사용할 수 있다.
            .map(==)
            .eraseToAnyPublisher()
    }()
    
    // 위 두개의 비밀번호 검사 결과를 합쳐서 비밀번호 유효성 검사
    private lazy var isPasswordValidPublisher: AnyPublisher<Bool, Never> = {
        Publishers.CombineLatest(isPasswordEmptyPublisher, isPasswordMatchingPublisher)
        // 1. isPasswordEmptyPublisher가 true 이면 비밀번호가 비어있다는 뜻이므로 isValid가 false여야 한다.
        // 2. isPasswordMatchingPublisher가 true 이면 비밀번호와 비밀번호 확인이 일치한다는 뜻이므로 isValid가 true여야 한다.
            .map { !$0 && $1 }
            .eraseToAnyPublisher()
    }()
    
    private lazy var isFormValidPublisher: AnyPublisher<Bool, Never> = {
        Publishers.CombineLatest(isUsernameValidPublisher, isPasswordValidPublisher)
            .map { $0 == .valid && $1 }
            .eraseToAnyPublisher()
    }()
    
    init() {
        // 유저 이름 유효성 검사
        isUsernameValidPublisher
            .map { valid in
                switch valid {
                case .valid:
                    return ""
                case .tooShort:
                    return "사용자 이름은 3자 이상이어야 합니다."
                case .notAvailable:
                    return "사용자 이름이 사용 중입니다."
                }
            }
            .assign(to: &$usernameMessage)
        
        // 비밀번호 유효성 검사
        Publishers.CombineLatest(isPasswordEmptyPublisher, isPasswordMatchingPublisher)
            .map { isEmpty, isMatching in
                if isEmpty {
                    return "비밀번호를 입력하세요."
                } else if !isMatching {
                    return "비밀번호가 일치하지 않습니다."
                } else {
                    return ""
                }
            }
            .assign(to: &$passwordMessage)
        
        // 폼 유효성 검사
        isFormValidPublisher
            .assign(to: &$isValid)
    }
}
