import Foundation

enum VaultError : ErrorType {
	case WrongPassword
	case UnknownError
}

struct Vault {
	private static var masterKey : COpaquePointer? = nil
	private static var vaultObj : COpaquePointer? = nil
	private static var entriesKey : COpaquePointer? = nil
	private static var filePath : String? = nil
	private static var isOpen = false
	
	static func open(path: String, userName: String, password: String) throws {
		masterKey = rusterpassword_gen_master_key(password, userName)
		if masterKey == COpaquePointer.init(nilLiteral: ()) {
			throw VaultError.UnknownError
		}

		let fm = NSFileManager.defaultManager()
		if fm.isReadableFileAtPath(path) {
			filePath = path
			let outerKey = freepass_gen_outer_key(masterKey!)
			vaultObj = freepass_open_vault(path, outerKey)
			freepass_free_outer_key(outerKey)
		} else {
			vaultObj = freepass_new_vault()
		}

		if vaultObj == COpaquePointer.init(nilLiteral: ()) {
			rusterpassword_free_master_key(masterKey!)
			throw VaultError.WrongPassword
		}
		isOpen = true
	}
	
	static func entryNames() -> [String] {
		guard let vaultObj = vaultObj else { return [] }
		let names_iter = freepass_vault_get_entry_names_iterator(vaultObj)
		var names = [String]()
		var curr = freepass_entry_names_iterator_next(names_iter)
		while curr != UnsafeMutablePointer.init(nilLiteral: ()) {
			names.append(String.fromCString(curr)!)
			freepass_free_entry_name(curr)
			curr = freepass_entry_names_iterator_next(names_iter)
		}
		freepass_free_entry_names_iterator(names_iter)
		return names
	}
	
	static func close() {
		if let masterKey = masterKey {
			rusterpassword_free_master_key(masterKey)
		}
		masterKey = nil
		
		if let vaultObj = vaultObj {
			freepass_close_vault(vaultObj)
		}
		isOpen = false
	}
}