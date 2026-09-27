import ComposableArchitecture
import Foundation
import os
import Testing
@testable import SuperSoccer2

@Suite
@MainActor
struct CareerPersistenceTests {
    @Test func aResolvedMatchALineupAndAdvanceWeekAreSaved() async throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        let box = CareerBox()
        let writes = OSAllocatedUnfairLock(initialState: 0)
        let store = TestStore(initialState: MatchweekFeature.State(userClubID: "manchester-city", season: season)) {
            MatchweekFeature()
        } withDependencies: {
            $0.entropy.nextSeed = { 7 }
            $0.careerStore = countingStore(box: box, writes: writes)
        }
        store.exhaustivity = .off

        await store.send(.view(.tabSelected(.match)))
        await store.send(.view(.leadersButtonTapped))
        await store.send(.view(.kickOffButtonTapped))
        await store.finish()
        #expect(writes.withLock { $0 } == 0)
        #expect(await box.load() == nil)

        await store.send(.highlight(.presented(.view(.skipButtonTapped))))
        await store.send(.highlight(.presented(.view(.backButtonTapped))))
        await store.skipReceivedActions()
        await store.finish()
        #expect(writes.withLock { $0 } == 1)
        let resolved = try #require(await box.load())
        #expect(resolved.committedWeeks == 1)
        #expect(resolved.weekIndex == 0)
        #expect(resolved.pending != nil)
        #expect(resolved.standings.allSatisfy { $0.played == 1 })
        #expect(resolved.userClubID == "manchester-city")

        let club = try #require(store.state.userClub)
        let starter = try #require(club.starters.first { WeekBetween.bestFit(replacing: $0, in: club.players) != nil })
        await store.send(.view(.restStarter(starter.id)))
        await store.finish()
        #expect(writes.withLock { $0 } == 1)
        let unchanged = try #require(await box.load())
        let unchangedClub = try #require(unchanged.clubs.first { $0.id == "manchester-city" })
        #expect(unchangedClub.starters.contains { $0.id == starter.id })

        let incoming = try #require(store.state.substitution?.candidates.first?.id)
        await store.send(.substitution(.presented(.view(.nameTapped(incoming)))))
        await store.finish()
        #expect(writes.withLock { $0 } == 2)
        let linedUp = try #require(await box.load())
        let savedClub = try #require(linedUp.clubs.first { $0.id == "manchester-city" })
        #expect(savedClub.starters.contains { $0.id == starter.id } == false)

        await store.send(.view(.nextFixtureButtonTapped))
        await store.finish()
        #expect(writes.withLock { $0 } == 3)
        let advanced = try #require(await box.load())
        #expect(advanced.weekIndex == 1)
        #expect(advanced.pending == nil)
        #expect(advanced.committedWeeks == 1)
        #expect(advanced.standings == linedUp.standings)
    }

    @Test func aSkillPickIsSaved() async throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        var state = MatchweekFeature.State(userClubID: "manchester-city", season: season)
        let player = try #require(state.userClub?.starters.first)
        let stat = PlayerStat.shooting
        let points = WeekTuning.current.points(for: stat)
        state.committedWeeks = 1
        state.skillOffers = [SkillOffer(id: "offer-1", playerID: player.id, clubID: "manchester-city")]
        let box = CareerBox()
        let store = TestStore(initialState: state) {
            MatchweekFeature()
        } withDependencies: {
            $0.careerStore = .inMemory(box)
        }
        store.exhaustivity = .off

        await store.send(.view(.nextFixtureButtonTapped))
        let choice = try #require(store.state.skillChoice)
        #expect(store.state.weekIndex == 0)
        #expect(choice.player.position == player.position)
        #expect(choice.player.ratings == player.ratings)
        await store.send(.skillChoice(.presented(.view(.statTapped(stat)))))
        await store.skipReceivedActions()
        await store.finish()
        let saved = try #require(await box.load())
        #expect(saved.skillOffers.isEmpty)
        #expect(saved.weekIndex == 1)
        let updated = try #require(saved.clubs.first { $0.id == "manchester-city" }?.players.first { $0.id == player.id })
        #expect(updated.ratings.shooting == player.ratings.shooting + points)
        #expect(updated.skillsEarned == player.skillsEarned + 1)
    }

    @Test func simulatingTheSeasonWritesOnce() async throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        let box = CareerBox()
        let writes = OSAllocatedUnfairLock(initialState: 0)
        let store = TestStore(initialState: MatchweekFeature.State(userClubID: "manchester-city", season: season)) {
            MatchweekFeature()
        } withDependencies: {
            $0.entropy.nextSeed = { 11 }
            $0.careerStore = countingStore(box: box, writes: writes)
        }
        store.exhaustivity = .off

        await store.send(.view(.simulateSeasonButtonTapped))
        await store.finish()
        #expect(writes.withLock { $0 } == 0)

        await store.send(.seasonAlert(.presented(.confirm)))
        await store.finish()
        #expect(writes.withLock { $0 } == 1)
        let saved = try #require(await box.load())
        #expect(saved.record?.awards.map(\.kind) == AwardKind.allCases)
        #expect(saved.standings.allSatisfy { $0.played == 38 })
        #expect(saved.clubs == store.state.clubs)
    }

    @Test func continueOpensTheClubTab() async throws {
        let season = LeagueDraft.makeLeague(seed: 9)
        var career = Career(matchweek: MatchweekFeature.State(userClubID: "norwich-city", season: season))
        career.weekIndex = 4
        career.committedWeeks = 4
        let box = CareerBox()
        await box.save(career)

        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.careerStore = .inMemory(box)
        }
        store.exhaustivity = .off

        await store.send(.frontDoor(.view(.onAppear)))
        await store.skipReceivedActions()
        #expect(store.state.frontDoor.canContinue)
        #expect(store.state.game == nil)
        await store.send(.frontDoor(.view(.continueButtonTapped)))
        await store.skipReceivedActions()
        let week = try #require(store.state.game)
        #expect(week.tab == .club)
        #expect(week.weekIndex == 4)
        #expect(week.committedWeeks == 4)
        #expect(week.userClubID == "norwich-city")
        #expect(store.state.selection == nil)
        #expect(store.state.menu == nil)
    }

    @Test func newGameReplacesTheSavedCareer() async throws {
        let season = LeagueDraft.makeLeague(seed: 9)
        var career = Career(matchweek: MatchweekFeature.State(userClubID: "norwich-city", season: season))
        career.weekIndex = 4
        let box = CareerBox()
        await box.save(career)

        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.entropy.nextSeed = { 42 }
            $0.careerStore = .inMemory(box)
        }
        store.exhaustivity = .off

        await store.send(.frontDoor(.view(.onAppear)))
        await store.skipReceivedActions()
        #expect(store.state.frontDoor.canContinue)
        await store.send(.frontDoor(.view(.newGameButtonTapped)))
        await store.skipReceivedActions()
        #expect(store.state.selection != nil)
        #expect(store.state.game == nil)
        await store.send(.selection(.presented(.view(.onAppear))))
        await store.send(.selection(.presented(.view(.clubTapped("manchester-city")))))
        await store.skipReceivedActions()
        await store.finish()

        let saved = try #require(await box.load())
        #expect(saved.userClubID == "manchester-city")
        #expect(saved.weekIndex == 0)
        #expect(saved.committedWeeks == 0)
        #expect(saved.record == nil)
        let week = try #require(store.state.game)
        #expect(week.tab == .club)
        #expect(week.userClubID == "manchester-city")
        #expect(store.state.selection == nil)
        #expect(store.state.menu == nil)
    }

    @Test func continueIsUnavailableWhenNoCareerExists() async throws {
        let store = TestStore(initialState: FrontDoorFeature.State()) {
            FrontDoorFeature()
        } withDependencies: {
            $0.careerStore = .inMemory()
        }

        await store.send(.view(.onAppear))
        await store.receive(\.availabilityChecked) {
            $0.hasChecked = true
            $0.canContinue = false
        }
        await store.send(.view(.continueButtonTapped))
        await store.send(.view(.newGameButtonTapped)) {
            $0.newGameTaps = 1
        }
        await store.receive(\.delegate.newGame)
    }

    @Test func aCareerThatWillNotOpenStaysOffTheClubTab() async throws {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.careerStore.exists = { true }
            $0.careerStore.load = { nil }
        }
        store.exhaustivity = .off

        await store.send(.frontDoor(.view(.onAppear)))
        await store.skipReceivedActions()
        #expect(store.state.frontDoor.canContinue)
        await store.send(.frontDoor(.view(.continueButtonTapped)))
        await store.skipReceivedActions()
        #expect(store.state.frontDoor.failedToOpen)
        #expect(store.state.frontDoor.canContinue == false)
        #expect(store.state.game == nil)
        #expect(store.state.selection == nil)
    }

    @Test func continueDoesNothingFromTheMenu() async throws {
        var state = FrontDoorFeature.State(mode: .menu)
        state.hasChecked = true
        state.canContinue = true
        let store = TestStore(initialState: state) {
            FrontDoorFeature()
        } withDependencies: {
            $0.careerStore.load = {
                Issue.record("Continue loaded a career from the menu")
                return nil
            }
        }

        await store.send(.view(.continueButtonTapped))
        await store.send(.view(.dismissButtonTapped))
        await store.receive(\.delegate.dismiss)
        await store.send(.view(.newGameButtonTapped)) {
            $0.newGameTaps = 1
        }
        await store.receive(\.delegate.newGame)
    }

    @Test func theCareerFileRoundTripsTableSquadsAndAwards() async throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        let played = TestStore(initialState: MatchweekFeature.State(userClubID: "manchester-city", season: season)) {
            MatchweekFeature()
        } withDependencies: {
            $0.entropy.nextSeed = { 11 }
            $0.careerStore = .inMemory()
        }
        played.exhaustivity = .off
        await played.send(.view(.simulateSeasonButtonTapped))
        await played.send(.seasonAlert(.presented(.confirm)))
        await played.finish()
        let career = Career(matchweek: played.state)
        #expect(career.record != nil)
        #expect(career.clubs.contains { club in club.players.contains { $0.injury != nil || $0.skillsEarned > 0 || $0.condition != 100 } })

        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("ss2-career-\(UUID().uuidString)", isDirectory: true)
        let url = folder.appendingPathComponent(CareerLocation.fileName)
        defer { try? FileManager.default.removeItem(at: folder) }

        let file = CareerStore.file(at: url)
        #expect(await file.exists() == false)
        await file.save(career)
        #expect(await file.exists())
        let loaded = try #require(await file.load())
        #expect(loaded == career)
        let restored = MatchweekFeature.State(career: loaded)
        #expect(restored.tab == .club)
        #expect(restored.clubs == career.clubs)
        #expect(restored.standings == career.standings)
        #expect(restored.record == career.record)
        #expect(restored.skillOffers == career.skillOffers)
    }
}

private func countingStore(box: CareerBox, writes: OSAllocatedUnfairLock<Int>) -> CareerStore {
    var store = CareerStore.inMemory(box)
    let save = store.save
    store.save = { career in
        writes.withLock { $0 += 1 }
        await save(career)
    }
    return store
}
