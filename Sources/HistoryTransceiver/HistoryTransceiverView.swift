//
//  HistoryTransceiverView.swift
//  HistoryTransceiver
//
//  Created by Sven A. Schmidt on 22/03/2020.
//  Copyright © 2020 finestructure. All rights reserved.
//

import ComposableArchitecture
import SwiftUI


// FIXME: see if we can avoid constraining to `Equatable`
public protocol StateInitializable: Codable, Equatable {
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
    let store: Store<State, Action>
    @ObservedObject var viewStore: ViewStore<State, Action>

    public var body: some View {
        CV.body(store: store.scope(state: { $0.contentView },
                                   action: { .contentView($0) }))
    }

//    public init(store: Store<State, Action>) {
//        self.store = store
//        self.viewStore = self.store.view()
//    }

    public init() {
        let initial = State(contentView: .init())
        store = Store(initialState: initial, reducer: Self.reducer, environment: CV.environment)
        viewStore = self.store.view()
//        self.init(store: store)
    }
}


extension HistoryTransceiverView {
    public struct State: Equatable {
        var contentView: CV.State
    }

    public enum Action {
        case contentView(CV.Action)
        case updateState(Data?)
    }

    static var reducer: Reducer<State, Action, CV.Environment> {
        let mainReducer: Reducer<State, Action, CV.Environment> = .init { state, action, _ in
            switch action {
                case .contentView:
                    return .noop
                case .updateState(let data):
                    state.contentView = data.flatMap(CV.State.init(from:)) ?? .init()
                    return .noop
            }
        }

        let contentViewReducer = broadcast(CV.reducer)
            .pullback(state: \State.contentView,
                      action: /Action.contentView,
                      environment: { $0 })

        return Reducer.combine(mainReducer, contentViewReducer)
    }

    public func resume() {
        Transceiver.shared.receive(Message.self) { msg in
            if msg.command == .reset {
                self.viewStore.send(.updateState(msg.state))
            }
        }
        Transceiver.shared.resume()
    }
}

