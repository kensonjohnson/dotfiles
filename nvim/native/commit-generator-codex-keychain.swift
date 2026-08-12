import Foundation
import Security

let service = "dev.kenson.dotfiles.commit-generator.codex"
let account = "oauth-credentials"

func reply(_ object: [String: Any]) {
  guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
    exit(1)
  }
  FileHandle.standardOutput.write(data)
  FileHandle.standardOutput.write(Data("\n".utf8))
}

func fail(_ code: String) {
  reply(["ok": false, "error": code])
}

func itemQuery() -> [CFString: Any] {
  return [
    kSecClass: kSecClassGenericPassword,
    kSecAttrService: service,
    kSecAttrAccount: account,
    kSecAttrSynchronizable: kCFBooleanFalse as Any,
  ]
}

func get() {
  var query = itemQuery()
  query[kSecReturnData] = kCFBooleanTrue
  query[kSecMatchLimit] = kSecMatchLimitOne

  var result: CFTypeRef?
  let status = SecItemCopyMatching(query as CFDictionary, &result)
  guard status != errSecItemNotFound else {
    fail("not-found")
    return
  }
  guard status == errSecSuccess, let value = result as? Data else {
    fail("keychain-failure")
    return
  }

  reply(["ok": true, "value": value.base64EncodedString()])
}

func set(_ value: Data) {
  let attributes: [CFString: Any] = [
    kSecValueData: value,
    kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
  ]
  let status = SecItemUpdate(itemQuery() as CFDictionary, attributes as CFDictionary)
  if status == errSecSuccess {
    reply(["ok": true])
    return
  }
  guard status == errSecItemNotFound else {
    fail("keychain-failure")
    return
  }

  var item = itemQuery()
  item[kSecValueData] = value
  item[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
  let addStatus = SecItemAdd(item as CFDictionary, nil)
  if addStatus == errSecSuccess {
    reply(["ok": true])
  } else if addStatus == errSecDuplicateItem {
    let retryStatus = SecItemUpdate(itemQuery() as CFDictionary, attributes as CFDictionary)
    retryStatus == errSecSuccess ? reply(["ok": true]) : fail("keychain-failure")
  } else {
    fail("keychain-failure")
  }
}

func delete() {
  let status = SecItemDelete(itemQuery() as CFDictionary)
  if status == errSecSuccess || status == errSecItemNotFound {
    reply(["ok": true])
  } else {
    fail("keychain-failure")
  }
}

let input = FileHandle.standardInput.readDataToEndOfFile()
guard let object = try? JSONSerialization.jsonObject(with: input) as? [String: Any],
      let operation = object["op"] as? String else {
  fail("invalid-request")
  exit(0)
}

switch operation {
case "get":
  guard object.count == 1 else {
    fail("invalid-request")
    break
  }
  get()
case "set":
  guard object.count == 2,
        let encoded = object["value"] as? String,
        let value = Data(base64Encoded: encoded, options: []) else {
    fail("invalid-request")
    break
  }
  set(value)
case "delete":
  guard object.count == 1 else {
    fail("invalid-request")
    break
  }
  delete()
default:
  fail("invalid-request")
}
