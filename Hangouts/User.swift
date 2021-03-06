import Foundation
import ParrotServiceExtension

/// A chat user.
public struct User: Person, Hashable, Equatable {
    public static let DEFAULT_NAME = "Unknown"
	
	/// A chat user identifier.
	public struct ID: Hashable, Equatable {
		public let chatID: String
		public let gaiaID: String
	}
	
    public let id: User.ID
	public var identifier: String {
		return id.gaiaID
	}
	public let nameComponents: [String]
    public let photoURL: String?
    public let locations: [String]
    public let isSelf: Bool
	public var me: Bool {
		return self.isSelf
	}
	
	// Initialize a User directly.
	// Handles full_name or first_name being nil by creating an approximate
	// first_name from the full_name, or setting both to DEFAULT_NAME.
	//
	// Ignores firstName value.
    public init(userID: User.ID, fullName: String? = nil, photoURL: String? = nil,
                locations: [String] = [], isSelf: Bool = false) {
		self.id = userID
		self.nameComponents = (fullName ?? User.DEFAULT_NAME).characters.split{$0 == " "}.map(String.init)
        self.photoURL = photoURL
        self.locations = locations
        self.isSelf = isSelf
    }
	
	// Parse and initialize a User from an Entity.
	// Note: If selfUser is nil, assume this is the self user.
    public init(entity: Entity, selfUser: User.ID?) {
		
		// Parse User ID and self status.
		let userID = User.ID(chatID: entity.id!.chatId!,
			gaiaID: entity.id!.gaiaId!)
		let isSelf = (selfUser != nil ? (selfUser == userID) : true)
		
		// Parse possible phone numbers.
		var phoneI18N: String? = nil // just use I18N and reformat it if needed.
		if	let r = entity.properties?._unknownFields[14] as? [AnyObject] where r.count > 0 {
			if let d = r[0][0][1] as? [AnyObject] { // retrieve the I18nData
				phoneI18N = d[1] as? String
			}
		}
		
		// Parse the user photo.
		var photo: String? = nil
		if let e = entity.properties!.photoUrl {
			photo = "https:" + e
		}
		
		// Parse possible locations.
		var locations: [String] = []
		locations += entity.properties!.email
		locations += entity.properties!.phone
		if let c = entity.properties!.canonicalEmail {
			locations.append(c)
		}
		if let p = phoneI18N {
			locations.append(p)
		}
		
		// Initialize the user.
        self.init(userID: userID,
            fullName: phoneI18N ?? entity.properties!.displayName,
            photoURL: photo, locations: locations, isSelf: isSelf
        )
    }
}

// Collection of User instances.
public class UserList: Directory, Collection {
	
	private var observer: NSObjectProtocol? // for Notification
	private var users: [User.ID: User]
	
	public let me: Person
	public var people: [String: Person] {
		var dict = [String: Person]()
		for (key, value) in self.users {
			dict[key.gaiaID] = value
		}
		return dict
	}
	public var invitations: [String: Person] {
		return [:]
	}
	public var blocked: [String: Person] {
		return [:]
	}
	
	// Returns all users as an array.
	public var allUsers: [User] {
		return Array(self.users.values)
	}
	
	// Return a User by their User.ID.
	// Logs and returns a placeholder User if not found.
	public subscript(userID: User.ID) -> User {
		if let user = self.users[userID] {
			return user
		} else {
			//log.warning("UserList returning unknown User for User.ID \(userID)")
			return User(userID: userID)
		}
	}
	
	// Initialize the list of Users.
	// Creates users from the given ClientEntity and
	// ClientConversationParticipantData instances. The latter is used only as
	// a fallback, because it doesn't include a real first_name.
	public init(client: Client, me: User, users: [User] = []) {
		var usersDict = Dictionary<User.ID, User>()
		users.forEach { usersDict[$0.id] = $0 }
		self.users = usersDict
		self.me = me
		
		self.observer = NotificationCenter.default()
			.addObserver(forName: Client.didUpdateStateNotification, object: client, queue: nil) {
				
				if let userInfo = $0.userInfo,
					state_update = userInfo[Client.didUpdateStateKey.rawValue] {
					
					if let conversation = ((state_update as! Wrapper<StateUpdate>).element).conversation {
						client.getEntitiesByID(chat_id_list: conversation.participantData.flatMap { $0.id?.chatId }) { response in
							let entities = response?.entityResult.flatMap { $0.entity } ?? []
							for entity in entities {
								let user = User(entity: entity, selfUser: (self.me as! User).id)
								if self.users[user.id] == nil {
									self.users[user.id] = user
								}
							}
						}
					}
				}
		}
	}
	
	deinit {
		NotificationCenter.default().removeObserver(self.observer!)
	}
}


/// User.ID: Hashable
public extension User.ID {
	public var hashValue: Int {
		return chatID.hashValue &+ gaiaID.hashValue
	}
}
/// User.ID: Equatable
public func ==(lhs: User.ID, rhs: User.ID) -> Bool {
	return lhs.hashValue == rhs.hashValue
}
/// User: Hashable
public extension User {
	public var hashValue: Int {
		return self.id.hashValue
	}
}
/// User: Equatable
public func ==(lhs: User, rhs: User) -> Bool {
	return lhs.id == rhs.id
}

/// UserList: Collection
public extension UserList {
	public typealias Index = DictionaryIndex<User.ID, User>
	public typealias SubSequence = Slice<LazyMapCollection<Dictionary<User.ID, User>, User>>
	public var startIndex : Index {
		return self.users.values.startIndex
	}
	public var endIndex : Index {
		return self.users.values.endIndex
	}
	public func index(after i: Index) -> Index {
		return self.users.values.index(after: i)
	}
	public func formIndex(after i: inout Index) {
		return self.users.values.formIndex(after: &i)
	}
	public subscript(index: Index) -> User {
		return self.users.values[index]
	}
	public subscript(bounds: Range<Index>) -> SubSequence {
		return self.users.values[bounds]
	}
}
