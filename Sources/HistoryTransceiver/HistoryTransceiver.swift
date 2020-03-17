//
//  HistoryTransceiver.swift
//  HistoryTransceiver
//
//  Created by Sven A. Schmidt on 17/03/2020.
//  Copyright © 2020 finestructure. All rights reserved.
//

import CompArch
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


public func broadcast<Value: Encodable, Action>(_ reducer: @escaping Reducer<Value, Action>) -> Reducer<Value, Action> {
    return { value, action in
        let effects = reducer(&value, action)
        let newValue = value
        return [.fireAndForget {
            if let data = try? JSONEncoder().encode(newValue) {
                print("📡 Broadcasting state ...")
                let msg = Message(command: .record, action: "\(action)", state: data)
                Transceiver.shared.broadcast(msg)
            }
            }] + effects
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
