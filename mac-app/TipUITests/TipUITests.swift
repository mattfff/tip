import XCTest

final class TipUITests : XCTestCase {

  let pasteBoard = NSPasteboard.general
  let app = XCUIApplication()

  override func setUp() {
    pasteBoard.clearContents()
    pasteBoard.setString("", forType: .string)
  }

  override func tearDown() {
    app.terminate()
  }

  func testGoodProviderClickingOnText() {
    launch(withName: "good_provider")
    XCTAssertEqual("Return TestInput", getLabel(rowIndex: 0))
    click(rowIndex: 0)
    XCTAssertEqual("Return TestInput", pasteBoard.string(forType: .string))
  }
    
  func testFirstRowIsSelectedAsDefault() {
    launch(withName: "good_provider")
    XCTAssertEqual("Return TestInput", getLabel(rowIndex: 0))
    app.typeKey(XCUIKeyboardKey.`return`, modifierFlags: XCUIElement.KeyModifierFlags.init())
    XCTAssertEqual("Return TestInput", pasteBoard.string(forType: .string))
  }

  func testGoodProviderClickingOnTextWithLabel() {
    launch(withName: "good_provider")
    XCTAssertEqual("{\n  \"input\": \"TestInput\",\n  \"other\": true\n}", getLabel(rowIndex: 1))
    click(rowIndex: 1)
    XCTAssertEqual("Value TestInput", pasteBoard.string(forType: .string))
  }

  func testGoodProviderClickingOnURL() {
    launch(withName: "good_provider")
    XCTAssertEqual("Go to TestInput", getLabel(rowIndex: 2))
    click(rowIndex: 2)
    XCTAssertEqual("tanintip://TestInput", pasteBoard.string(forType: .string))
  }

  func testProviderAutoExecute() {
    launch(withName: "auto_execute_provider")
    usleep(useconds_t(1000 * 1000))
    XCTAssertEqual("Return Auto TestInput", pasteBoard.string(forType: .string))
  }

  func testNoProvider() {
    app.launchArguments = ["-test", "TestInput", "-provider", "/tmp/something-doesn-exist.rb"]
    app.launch()
    XCTAssertEqual("/tmp/something-doesn-exist.rb doesn't exist. Please make a provider script. Click to see instruction.", app.popovers.children(matching: .any).element(boundBy: 1).firstMatch.value as! String)

    app.popovers.element.click()
    usleep(useconds_t(200 * 1000))
    XCTAssertEqual("OpenProviderInstruction", pasteBoard.string(forType: .string))
  }

  func testNoTip() {
    launch(withName: "empty_provider")
    XCTAssertEqual("No tips. You can add tips through your provider script. Click to see the instruction.", app.popovers.children(matching: .any).element(boundBy: 1).firstMatch.value as! String)

    app.popovers.element.click()
    usleep(useconds_t(200 * 1000))
    XCTAssertEqual("OpenProviderInstruction", pasteBoard.string(forType: .string))
  }

  func testProviderUnexecutable() {
    launch(withName: "unexecutable_provider")
    let value = app.popovers.children(matching: .any).element(boundBy: 1).firstMatch.value as! String
    let firstSlash = value.firstIndex(of: "/") ?? value.endIndex
    XCTAssertEqual("Provider isn't executable. Please chmod 755 ", value[..<firstSlash])

    app.popovers.element.click()
    usleep(useconds_t(200 * 1000))
    XCTAssertEqual("None", pasteBoard.string(forType: .string))
  }

  func testProvideMalformedJson() {
    launch(withName: "malformed_json_provider")
    XCTAssertEqual("Malformed JSON returned from provider. Click to see logs in Console. You'll need to set the filter Process=Tip.", app.popovers.children(matching: .any).element(boundBy: 1).firstMatch.value as! String)

    app.popovers.element.click()
    usleep(useconds_t(200 * 1000))
    XCTAssertEqual("OpenConsole", pasteBoard.string(forType: .string))
  }

  func testErrorProvider() {
    launch(withName: "error_provider")
    XCTAssertEqual("Error occurred. Click to see logs in Console. You'll need to set the filter Process=Tip.", app.popovers.children(matching: .any).element(boundBy: 1).firstMatch.value as! String)

    app.popovers.element.click()
    usleep(useconds_t(200 * 1000))
    XCTAssertEqual("OpenConsole", pasteBoard.string(forType: .string))
  }

  private func launch(withName: String){
    let file = Bundle(for: type(of: self)).path(forResource: withName, ofType: "rb")
    app.launchArguments = ["-test", "TestInput", "-provider", file!]
    app.launch()
    app.activate()
    XCTAssertEqual(
        XCTWaiter.wait(for: [XCTKVOExpectation(keyPath:"exists", object: app.popovers.element, expectedValue: true)], timeout: 3),
        .completed)
  }

  private func click(rowIndex: Int)  {
    let button = app.popovers.element.tableRows.element(boundBy: rowIndex).cells.element(boundBy: 0).firstMatch
    XCTAssertEqual(
        XCTWaiter.wait(for: [XCTKVOExpectation(keyPath:"isHittable", object: button, expectedValue: true)], timeout: 3),
        .completed)
    button.click()
  }

  private func getLabel(rowIndex: Int) -> String {
    let text = app.popovers.element.tableRows.element(boundBy: rowIndex).cells.element(boundBy: 1).staticTexts.element(boundBy: 0)
    XCTAssertEqual(
        XCTWaiter.wait(for: [XCTKVOExpectation(keyPath:"exists", object: text, expectedValue: true)], timeout: 3),
        .completed)
    return text.value as! String
  }

}
