import XCTest
import CoreData
@testable import Timelog

/// LifeCommitManagerTests - 人生提交管理器测试
/// 测试时间提交的核心业务逻辑
final class LifeCommitManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var lifeCommitManager: LifeCommitManager!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
        lifeCommitManager = LifeCommitManager(viewContext: viewContext)
    }
    
    override func tearDownWithError() throws {
        lifeCommitManager = nil
        persistenceController = nil
        viewContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Session Management Tests
    
    /// 测试开始新的时间会话
    func testStartNewSession() throws {
        XCTAssertFalse(lifeCommitManager.isSessionActive)
        XCTAssertNil(lifeCommitManager.currentSession)
        
        lifeCommitManager.startNewSession()
        
        XCTAssertTrue(lifeCommitManager.isSessionActive)
        XCTAssertNotNil(lifeCommitManager.currentSession)
        XCTAssertNotNil(lifeCommitManager.currentSession?.startTime)
    }
    
    /// 测试结束当前会话
    func testEndCurrentSession() throws {
        // 先开始一个会话
        lifeCommitManager.startNewSession()
        XCTAssertTrue(lifeCommitManager.isSessionActive)
        
        // 等待一小段时间
        Thread.sleep(forTimeInterval: 0.1)
        
        // 结束会话
        lifeCommitManager.endCurrentSession(message: "完成测试任务")
        
        XCTAssertFalse(lifeCommitManager.isSessionActive)
        XCTAssertNil(lifeCommitManager.currentSession)
        
        // 验证数据已保存
        let request: NSFetchRequest<TimeCommit> = TimeCommit.fetchRequest()
        let commits = try viewContext.fetch(request)
        
        XCTAssertEqual(commits.count, 1)
        XCTAssertEqual(commits.first?.message, "完成测试任务")
        XCTAssertNotNil(commits.first?.endTime)
    }
    
    /// 测试暂停和恢复会话
    func testPauseAndResumeSession() throws {
        lifeCommitManager.startNewSession()
        XCTAssertTrue(lifeCommitManager.isSessionActive)
        XCTAssertFalse(lifeCommitManager.isSessionPaused)
        
        // 暂停会话
        lifeCommitManager.pauseCurrentSession()
        XCTAssertTrue(lifeCommitManager.isSessionPaused)
        
        // 恢复会话
        lifeCommitManager.resumeCurrentSession()
        XCTAssertFalse(lifeCommitManager.isSessionPaused)
        XCTAssertTrue(lifeCommitManager.isSessionActive)
    }
    
    /// 测试会话时长计算
    func testSessionDurationCalculation() throws {
        lifeCommitManager.startNewSession()
        
        // 模拟会话运行时间
        Thread.sleep(forTimeInterval: 0.2)
        
        let duration = lifeCommitManager.currentSessionDuration
        XCTAssertGreaterThan(duration, 0.1)
        XCTAssertLessThan(duration, 1.0)
    }
    
    // MARK: - Focus Intensity Tests
    
    /// 测试专注强度更新
    func testFocusIntensityUpdate() throws {
        lifeCommitManager.startNewSession()
        
        // 模拟专注强度更新
        lifeCommitManager.updateFocusIntensity(0.8)
        
        XCTAssertEqual(lifeCommitManager.currentFocusIntensity, 0.8, accuracy: 0.01)
    }
    
    /// 测试专注强度历史记录
    func testFocusIntensityHistory() throws {
        lifeCommitManager.startNewSession()
        
        // 添加多个专注强度记录
        lifeCommitManager.updateFocusIntensity(0.6)
        lifeCommitManager.updateFocusIntensity(0.8)
        lifeCommitManager.updateFocusIntensity(0.7)
        
        let history = lifeCommitManager.focusIntensityHistory
        XCTAssertEqual(history.count, 3)
        XCTAssertEqual(history.last, 0.7, accuracy: 0.01)
    }
    
    /// 测试平均专注强度计算
    func testAverageFocusIntensity() throws {
        lifeCommitManager.startNewSession()
        
        lifeCommitManager.updateFocusIntensity(0.6)
        lifeCommitManager.updateFocusIntensity(0.8)
        lifeCommitManager.updateFocusIntensity(0.7)
        
        let average = lifeCommitManager.averageFocusIntensity
        XCTAssertEqual(average, 0.7, accuracy: 0.01)
    }
    
    // MARK: - Beautiful Moments Tests
    
    /// 测试美好时刻标记
    func testMarkBeautifulMoment() throws {
        lifeCommitManager.startNewSession()
        
        let success = lifeCommitManager.markBeautifulMoment(
            title: "重要突破",
            description: "解决了困扰已久的问题",
            emotion: "achievement"
        )
        
        XCTAssertTrue(success)
        XCTAssertTrue(lifeCommitManager.hasBeautifulMoment)
        XCTAssertEqual(lifeCommitManager.beautifulMomentTitle, "重要突破")
    }
    
    /// 测试移除美好时刻标记
    func testRemoveBeautifulMoment() throws {
        lifeCommitManager.startNewSession()
        
        // 先标记美好时刻
        lifeCommitManager.markBeautifulMoment(
            title: "测试时刻",
            description: "测试描述",
            emotion: "joy"
        )
        XCTAssertTrue(lifeCommitManager.hasBeautifulMoment)
        
        // 移除标记
        lifeCommitManager.removeBeautifulMoment()
        XCTAssertFalse(lifeCommitManager.hasBeautifulMoment)
        XCTAssertNil(lifeCommitManager.beautifulMomentTitle)
    }
    
    // MARK: - Data Persistence Tests
    
    /// 测试会话数据持久化
    func testSessionDataPersistence() throws {
        lifeCommitManager.startNewSession()
        lifeCommitManager.updateFocusIntensity(0.8)
        lifeCommitManager.markBeautifulMoment(
            title: "测试时刻",
            description: "测试描述",
            emotion: "achievement"
        )
        
        Thread.sleep(forTimeInterval: 0.1)
        
        lifeCommitManager.endCurrentSession(message: "完成测试")
        
        // 验证数据已正确保存
        let request: NSFetchRequest<TimeCommit> = TimeCommit.fetchRequest()
        let commits = try viewContext.fetch(request)
        
        XCTAssertEqual(commits.count, 1)
        
        let commit = commits.first!
        XCTAssertEqual(commit.message, "完成测试")
        XCTAssertEqual(commit.focusIntensity, 0.8, accuracy: 0.01)
        XCTAssertTrue(commit.isBeautifulMoment)
        XCTAssertEqual(commit.beautifulMomentTitle, "测试时刻")
        XCTAssertEqual(commit.emotionType, "achievement")
    }
    
    /// 测试批量会话创建
    func testMultipleSessionsCreation() throws {
        let sessionCount = 5
        
        for i in 0..<sessionCount {
            lifeCommitManager.startNewSession()
            lifeCommitManager.updateFocusIntensity(Double(i) * 0.2)
            Thread.sleep(forTimeInterval: 0.05)
            lifeCommitManager.endCurrentSession(message: "会话 \(i)")
        }
        
        // 验证所有会话都已保存
        let request: NSFetchRequest<TimeCommit> = TimeCommit.fetchRequest()
        let commits = try viewContext.fetch(request)
        
        XCTAssertEqual(commits.count, sessionCount)
    }
    
    // MARK: - Error Handling Tests
    
    /// 测试重复开始会话的处理
    func testDuplicateSessionStart() throws {
        lifeCommitManager.startNewSession()
        let firstSession = lifeCommitManager.currentSession
        
        // 尝试再次开始会话
        lifeCommitManager.startNewSession()
        let secondSession = lifeCommitManager.currentSession
        
        // 应该结束第一个会话并开始新会话
        XCTAssertNotEqual(firstSession?.id, secondSession?.id)
        XCTAssertTrue(lifeCommitManager.isSessionActive)
    }
    
    /// 测试结束不存在的会话
    func testEndNonExistentSession() throws {
        XCTAssertFalse(lifeCommitManager.isSessionActive)
        
        // 尝试结束不存在的会话
        lifeCommitManager.endCurrentSession(message: "测试")
        
        // 应该不会崩溃，也不会创建数据
        let request: NSFetchRequest<TimeCommit> = TimeCommit.fetchRequest()
        let commits = try viewContext.fetch(request)
        
        XCTAssertEqual(commits.count, 0)
    }
    
    // MARK: - Performance Tests
    
    /// 测试大量专注强度更新的性能
    func testFocusIntensityUpdatePerformance() throws {
        lifeCommitManager.startNewSession()
        
        measure {
            for i in 0..<1000 {
                lifeCommitManager.updateFocusIntensity(Double(i % 100) / 100.0)
            }
        }
    }
    
    /// 测试会话创建和结束的性能
    func testSessionCreationPerformance() throws {
        measure {
            for i in 0..<100 {
                lifeCommitManager.startNewSession()
                lifeCommitManager.updateFocusIntensity(0.8)
                lifeCommitManager.endCurrentSession(message: "性能测试 \(i)")
            }
        }
    }
}