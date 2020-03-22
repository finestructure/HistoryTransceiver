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


public protocol StateInitializable {
    init()
    init?(from data: Data)
}


public protocol StateSurfable: View {
    associatedtype State: Codable, StateInitializable
    associatedtype Action
    var store: Store<State, Action> { get set }
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

    public static func store() -> Store<State, Action> {
        let initial = State(contentView: .init())
        return Store(initialValue: initial, reducer: reducer)
    }
}

