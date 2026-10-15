import Foundation
import Testing

@testable import KerNotchCore

/// A pet's whole life on the island at random: icons arriving and leaving,
/// the island opening and closing, moods coming and going, and news of every
/// kind, at any moment — mid-hop, mid-skip, asleep or in the middle of a
/// reaction. Whatever happens, the pet never jumps and is only ever shown in
/// poses its sheet draws.
@Suite("Pet life")
struct PetLifeTests {
    private static let moods: [PetMood] = [
        .calm, .idle(since: 0), .listening, .digging, .onCall, .napping, .asking, .hiding,
    ]
    private static let stages: [PetStage] = [.roaming, .roaming, .resting, .away]

    @Test("led through any run of changes, the pet never jumps", arguments: PetSpecies.allCases, Array(UInt64(1)...6))
    func randomLifeNeverJumps(species: PetSpecies, seed: UInt64) {
        let pet = IslandPet(species: species)
        let pill = pet.stageGeometry()
        let open = pet.openIslandStageGeometry(stripWidth: 85)
        var events = PetDice(seed: seed &* 7919)
        var dice = PetDice(seed: seed)
        var tracker = PetRoutineTracker(species: species)
        var now: TimeInterval = 1_000
        var previous: PetPerformance?

        for _ in 0..<120 {
            now += Double.random(in: 0.05...4, using: &events)
            let isOpen = events.roll(0.2)
            let stage = isOpen ? .roaming : Self.stages.randomElement(using: &events)!
            var mood = Self.moods.randomElement(using: &events)!
            if case .idle = mood {
                mood = .idle(since: now - Double.random(in: 0...400, using: &events))
            }
            let moments = events.roll(0.5) ? [PetMoment.allCases.randomElement(using: &events)!] : []
            let scene = PetScene(stage: stage, geometry: isOpen ? open : pill, mood: mood)
            tracker.follow(scene, moments: moments, at: now, dice: &dice)

            guard let performance = tracker.performance else { continue }
            let routine = performance.routine
            if performance != previous, let previous {
                #expect(
                    routine.entrance.firstPose.position == previous.pose(at: now).position,
                    "\(species) jumped at \(now) into \(mood) on \(stage)"
                )
            }
            for timeline in [routine.entrance, routine.loop].compactMap({ $0 }) {
                #expect(PetChoreographerTests.largestStep(in: timeline) <= 1, "\(species) \(mood) \(moments)")
                #expect(
                    timeline.keyframes.allSatisfy { ($0.pose.lift > 0) == ($0.pose.frame == .hop) },
                    "\(species) \(mood) \(moments)"
                )
                #expect(
                    timeline.keyframes.allSatisfy { pet.sprites.frames[$0.pose.frame] != nil },
                    "\(species) shown undrawn in \(mood) \(moments)"
                )
                for track in timeline.effects {
                    #expect(track.keyframes.first?.time == 0)
                    #expect(track.keyframes.last?.point == nil, "\(species)'s \(track.effect) is left showing")
                }
            }
            if let loop = routine.loop {
                #expect(routine.entrance.lastPose == loop.firstPose, "\(species) \(mood) \(moments)")
            }
            previous = performance
        }
    }
}
