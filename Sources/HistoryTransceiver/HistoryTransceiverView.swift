//
//  HistoryTransceiverView.swift
//  HistoryTransceiver
//
//  Created by Sven A. Schmidt on 22/03/2020.
//  Copyright © 2020 finestructure. All rights reserved.
//

import CasePaths
import CompArch
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
    var store: Store<State, Action> { get }
    static var reducer: Reducer<State, Action> { get }
    static func body(store: Store<State, Action>) -> Self
}


public struct HistoryTransceiverView<CV: StateSurfable>: View {
    @ObservedObject var store: Store<State, Action>

    public var body: some View {
        CV.body(store: store.view(value: { $0.contentView },
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

    static var reducer: Reducer<State, Action> {
        let mainReducer: Reducer<State, Action> = { state, action in
            switch action {
                case .contentView:
                    return []
                case .updateState(let data):
                    state.contentView = data.flatMap(CV.State.init(from:)) ?? .init()
                    return []
            }
        }

        let contentViewReducer = pullback(
            broadcast(CV.reducer),
            value: \State.contentView,
            action: /Action.contentView)

        return combine(mainReducer, contentViewReducer)
    }

    public init() {
        let initial = State(contentView: .init())
        self.store = Store(initialValue: initial, reducer: Self.reducer)
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

