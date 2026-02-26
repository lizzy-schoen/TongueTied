import CloudKit
import Foundation

struct LeaderboardEntry {
    let screenName: String
    let totalScore: Int
    let recordID: CKRecord.ID?
}

class CloudKitService {

    static let shared = CloudKitService()

    private let container: CKContainer
    private let publicDB: CKDatabase
    private let recordType = "LeaderboardEntry"

    private init() {
        container = CKContainer(identifier: "iCloud.com.tonguetied.app")
        publicDB = container.publicCloudDatabase
    }

    // MARK: - Fetch leaderboard

    func fetchLeaderboard(limit: Int = 50,
                          completion: @escaping (Result<[LeaderboardEntry], Error>) -> Void) {
        let query = CKQuery(recordType: recordType,
                            predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "totalScore", ascending: false)]

        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = limit
        operation.desiredKeys = ["screenName", "totalScore"]

        var fetched: [LeaderboardEntry] = []

        operation.recordMatchedBlock = { _, result in
            if case .success(let record) = result {
                let entry = LeaderboardEntry(
                    screenName: record["screenName"] as? String ?? "???",
                    totalScore: record["totalScore"] as? Int ?? 0,
                    recordID: record.recordID
                )
                fetched.append(entry)
            }
        }

        operation.queryResultBlock = { result in
            switch result {
            case .success:
                let sorted = fetched.sorted { $0.totalScore > $1.totalScore }
                completion(.success(sorted))
            case .failure(let error):
                completion(.failure(error))
            }
        }

        publicDB.add(operation)
    }

    // MARK: - Submit score

    func submitScore(screenName: String, totalScore: Int,
                     completion: @escaping (Result<Void, Error>) -> Void) {
        let recordName = "player_\(screenName.stableHash)"
        let recordID = CKRecord.ID(recordName: recordName)

        publicDB.fetch(withRecordID: recordID) { [weak self] existing, _ in
            guard let self else { return }
            let record: CKRecord
            if let existing {
                record = existing
            } else {
                record = CKRecord(recordType: self.recordType, recordID: recordID)
            }

            record["screenName"] = screenName as CKRecordValue
            record["totalScore"] = totalScore as CKRecordValue

            self.publicDB.save(record) { _, error in
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    // MARK: - Account status

    func checkAccountStatus(completion: @escaping (Bool) -> Void) {
        container.accountStatus { status, _ in
            completion(status == .available)
        }
    }
}

// MARK: - Stable hash for record names

extension String {
    var stableHash: String {
        var hash: UInt64 = 5381
        for byte in self.utf8 {
            hash = ((hash &<< 5) &+ hash) &+ UInt64(byte)
        }
        return String(hash, radix: 36)
    }
}
