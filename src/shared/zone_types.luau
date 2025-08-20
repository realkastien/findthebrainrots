-- Zone system types for the mining game

-- Zone ID is just a string identifier
export type ZoneId = "string"

-- Player ID is a number (UserId)
export type PlayerId = "number"

-- Player zone data structure
export type PlayerZoneData = {
    current_zone: ZoneId?,
    previous_zone: ZoneId?,
    enter_time: number?
}
-- Zone information structure
export type ZoneInfo = {
    Id: ZoneId,
    Name: string,
    Model: Model?,
    ZoneInstance: any?, -- ZonePlus Zone instance
}

-- Zone enter event structure
export type ZoneEnterEvent = {
    PlayerId: PlayerId,
    ZoneId: ZoneId,
    EnterTime: number,
    PreviousZone: ZoneId?,
}

-- Zone exit event structure
export type ZoneExitEvent = {
    PlayerId: PlayerId,
    ZoneId: ZoneId,
    ExitTime: number,
    TimeSpent: number,
}

return nil
