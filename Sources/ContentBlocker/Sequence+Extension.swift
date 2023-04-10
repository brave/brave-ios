import Foundation

public extension Sequence {
  func asyncForEach(_ operation: (Element) async throws -> Void) async rethrows {
    for element in self {
      try await operation(element)
    }
  }

  func asyncConcurrentForEach(_ operation: @escaping (Element) async throws -> Void) async rethrows {
    await withThrowingTaskGroup(of: Void.self) { group in
      for element in self {
        group.addTask { try await operation(element) }
      }
    }
  }

  func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
    var results = [T]()
    for element in self {
      try await results.append(transform(element))
    }
    return results
  }

  func asyncConcurrentMap<T>(_ transform: @escaping (Element) async throws -> T) async rethrows -> [T] {
    try await withThrowingTaskGroup(of: T.self) { group in
      for element in self {
        group.addTask { try await transform(element) }
      }

      var results = [T]()
      for try await result in group {
        results.append(result)
      }
      return results
    }
  }

  func asyncCompactMap<T>(_ transform: (Element) async throws -> T?) async rethrows -> [T] {
    var results = [T]()
    for element in self {
      if let result = try await transform(element) {
        results.append(result)
      }
    }
    return results
  }

  func asyncConcurrentCompactMap<T>(_ transform: @escaping (Element) async throws -> T?) async rethrows -> [T] {
    try await withThrowingTaskGroup(of: T?.self) { group in
      for element in self {
        group.addTask {
          try await transform(element)
        }
      }

      var results = [T]()
      for try await result in group {
        if let result = result {
          results.append(result)
        }
      }
      return results
    }
  }
}
