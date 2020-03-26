//
//  HistoryTransceiver.swift
//  HistoryTransceiver
//
//  Created by Sven A. Schmidt on 17/03/2020.
//  Copyright © 2020 finestructure. All rights reserved.
//

import Combine
import ComposableArchitecture
import Foundation
import MultipeerKit


let serviceType = "Historian"


public enum Transceiver {
    public static var shared: MultipeerTransceiver = {
        var config = MultipeerConfiguration.default
        config.serviceType = serviceType
        config.security.encryptionPreference = .required
        return MultipeerTransceiver(configuration: config)
    }()

    static public var dataSource: MultipeerDataSource = {
        MultipeerDataSource(transceiver: shared)
    }()
}


// TODO: make method on Reducer?
public func broadcast<Value: Encodable, Action, Environment>(_ reducer: Reducer<Value, Action, Environment>) -> Reducer<Value, Action, Environment> {
    return .init { value, action, environment in
        let effect = reducer(&value, action, environment)
        let newValue = value
        return Publishers.Concatenate(
            prefix: Effect.fireAndForget {
                if let data = try? JSONEncoder().encode(newValue) {
                    print("📡 Broadcasting state ...")
                    let msg = Message(command: .record, action: "\(action)", state: data)
                    Transceiver.shared.broadcast(msg)
                }
            },
            suffix: effect
        )
        .eraseToEffect()
    }
}


public struct Message: Hashable, Codable {
    public enum Command: String, Codable {
        case record
        case reset
    }

    public let command: Command
    public let action: String
    public let state: Data?

    public init(command: Command, action: String, state: Data?) {
        self.command = command
        self.action = action
        self.state = state
    }
}
