//
//  ConstellationUserSubscribedPacket.swift
//  Pods
//
//  Created by Jack Cook on 8/10/16.
//
//

import SwiftyJSON

/// A user subscribed packet is sent down when a user subscribes to a channel.
public class ConstellationUserSubscribedPacket: ConstellationLivePacket {
    
    /// The id of the user who this event corresponds to.
    public let userId: Int
    
    /// The id of the channel that the user has subscribed to.
    public let channelId: Int
    
    /// Initializes a user subscribed packet with JSON data.
    override init?(data: [String: JSON]) {
        if let channel = data["channel"]?.string, payload = data["payload"], channelId = payload["channel"].int {
            self.userId = Int(channel.componentsSeparatedByString(":")[1])!
            self.channelId = channelId
            
            super.init(data: data)
        } else {
            return nil
        }
    }
}