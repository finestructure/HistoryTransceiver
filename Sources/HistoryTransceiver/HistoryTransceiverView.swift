//
//  HistoryTransceiverView.swift
//  HistoryTransceiver
//
//  Created by Sven A. Schmidt on 22/03/2020.
//  Copyright © 2020 finestructure. All rights reserved.
//

import CasePaths
import ComposableArchitecture
import SwiftUI


public protocol StateInitializable: Codable {
    init()
    init?(from data: Data)
}


extension StateInitializable {
    public init?(from data: Data) {
        guard let state = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = state
    }
}


public protocol StateSurfable: View {
    associatedtype State: StateInitializable
    associatedtype Action
    associatedtype Environment
    var store: Store<State, Action> { get }
    static var reducer: Reducer<State, Action, Environment> { get }
    static var environment: Environment { get }
    static func body(store: Store<State, Action>) -> Self
}


public struct HistoryTransceiverView<CV: StateSurfable>: View {
    public private(set) var store: Store<State, Action>

    public var body: some View {
        CV.body(store: store.scope(state: { $0.contentView },
                                   action: { .contentView($0) }))
    }

    public init(store: Store<State, Action>) {
        self.store = store
    }
}


extension HistoryTransceiverView {
    public struct State {
        var contentView: CV.State
    }

    public enum Action {
        case contentView(CV.Action)
        case updateState(Data?)
    }

    static var reducer: Reducer<State, Action, Any> {
        let mainReducer: Reducer<State, Action, Any> = .init { state, action, _ in
            switch action {
                case .contentView:
                    return []
                case .updateState(let data):
                    state.contentView = data.flatMap(CV.State.init(from:)) ?? .init()
                    return []
            }
        }

//        let contentViewReducer = pullback(
//            broadcast(CV.reducer),
//            value: \State.contentView,
//            action: /Action.contentView,
//            environment: { $0 })

//        return combine(mainReducer, contentViewReducer)
        return mainReducer
    }

    public init() {
        let initial = State(contentView: .init())
        self.store = Store(initialState: initial, reducer: Self.reducer, environment: Self.environment)
    }

    public func resume() {
        Transceiver.shared.receive(Message.self) { msg in
            if msg.command == .reset {
                self.store.send(.updateState(msg.state))
            }
        }
        Transceiver.shared.resume()
    }
}

