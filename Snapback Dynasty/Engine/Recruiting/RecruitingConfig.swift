import Foundation

enum RecruitingConfig {

    enum AI {
        static let baseWeeklyGainRange: (Double, Double) = (1.2, 3.0)
        static let phaseMultipliers: [RecruitPhase: Double] = [
            .discovery: 1.0, .pitch: 1.3, .close: 1.8
        ]
        static let swoopChance: Double = 0.04
        static let swoopGainRange: (Double, Double) = (10.0, 15.0)
        static let needMultiplierFull: Double = 0.3
        static let needMultiplierEmpty: Double = 2.0
        static let minimumScoreToAddBoard: Double = 0.7
    }

    enum Decommit {
        static let startingLoyalty: Double = 20.0
        static let loyaltyFloor4And5Star: Double = 5.0
        static let passiveDriftRange: (Double, Double) = (1.0, 3.0)
        static let rivalGapThreshold: Double = 15.0
        static let eventHitBigLoss: Double = -8.0
        static let eventHitOversign: Double = -12.0
        static let eventHitSwoop: Double = -10.0
        static let reassureHourCost: Int = 30
        static let reassureLoyaltyGain: Double = 6.0
        static let loyaltyWarningThreshold: Double = 10.0
    }

    enum Portal {
        static let starterFR: Double = 0.03
        static let starterSO: Double = 0.06
        static let starterJRSR: Double = 0.10
        static let nonStarterFR: Double = 0.12
        static let nonStarterSO: Double = 0.25
        static let nonStarterJRSR: Double = 0.38
        static let starterPushedOut: Double = 0.15
        static let belowFiveHundred: Double = 0.12
        static let missedBowl: Double = 0.08
        static let highOVRBonus: Double = 0.05
        static let lowOVRBonus: Double = 0.08
        static let globalPoolCap: Int = 300
        static let portalBoardCap: Int = 15
        static let baseRetentionOffers: Int = 4
        static let silverTongueBonus: Int = 2
        static let retentionSuccessStarter: Double = 0.75
        static let retentionSuccessNonStarter: Double = 0.50
        static let lockdownBonus: Double = 0.15
        static let offerInterestThreshold: Double = 70.0
        static let fourStarLegacyMinRank: Int = 25
        static let dmInterestGain: Double = 4.0
        static let allInInterestGain: Double = 14.0
    }
}
