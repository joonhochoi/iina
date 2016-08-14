//
//  QuickSettingView.swift
//  mpvx
//
//  Created by lhc on 12/8/16.
//  Copyright © 2016年 lhc. All rights reserved.
//

import Cocoa

class QuickSettingView: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

  override var nibName: String {
    return "QuickSettingView"
  }
  
  let distanceBetweenSliderAndIndicator: CGFloat = 18
  let sliderIndicatorHalfWidth:CGFloat = 16
  
  weak var playerController: PlayerController!
  weak var mainWindow: MainWindow!
  
  @IBOutlet weak var videoTabBtn: NSButton!
  @IBOutlet weak var audioTabBtn: NSButton!
  @IBOutlet weak var subTabBtn: NSButton!
  @IBOutlet weak var tabView: NSTabView!
  
  @IBOutlet weak var videoTableView: NSTableView!
  @IBOutlet weak var audioTableView: NSTableView!
  @IBOutlet weak var subTableView: NSTableView!
  @IBOutlet weak var secSubTableView: NSTableView!
  
  @IBOutlet weak var rotateSegment: NSSegmentedControl!
  
  @IBOutlet weak var aspectSegment: NSSegmentedControl!
  @IBOutlet weak var customAspectTextField: NSTextField!
  
  @IBOutlet weak var speedSlider: NSSlider!
  @IBOutlet weak var speedSliderIndicator: NSTextField!
  @IBOutlet weak var customSpeedTextField: NSTextField!
  
  @IBOutlet weak var customAudioDelayTextField: NSTextField!
  @IBOutlet weak var audioDelaySliderIndicator: NSTextField!
  
  @IBOutlet weak var customSubDelayTextField: NSTextField!
  @IBOutlet weak var subDelaySliderIndicator: NSTextField!
  
  @IBOutlet weak var slideUpBtn: NSButton!
  
  override func viewDidLoad() {
    withAllTableViews { (view, _) in
      view.delegate = self
      view.dataSource = self
      view.superview?.superview?.layer?.cornerRadius = 4
    }
    customSpeedTextField.formatter = DecimalFormatter()
    slideUpBtn.resetCursorRects()
  }
  
  // MARK: NSTableView delegate
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    if tableView == videoTableView {
      return playerController.info.videoTracks.count + 1
    } else if tableView == audioTableView {
      return playerController.info.audioTracks.count + 1
    } else if tableView == subTableView || tableView == secSubTableView {
      return playerController.info.subTracks.count + 1
    } else {
      return 0
    }
  }
  
  func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
    // get track according to tableview
    // row=0: <None> row=1~: tracks[row-1]
    let track: MPVTrack?
    let activeId: Int
    let columnName = tableColumn?.identifier
    if tableView == videoTableView {
      track = row == 0 ? nil : playerController.info.videoTracks[row-1]
      activeId = playerController.info.vid!
    } else if tableView == audioTableView {
      track = row == 0 ? nil : playerController.info.audioTracks[row-1]
      activeId = playerController.info.aid!
    } else if tableView == subTableView {
      track = row == 0 ? nil : playerController.info.subTracks[row-1]
      activeId = playerController.info.sid!
    } else if tableView == secSubTableView {
      track = row == 0 ? nil : playerController.info.subTracks[row-1]
      activeId = playerController.info.secondSid!
    } else {
      return nil
    }
    // return track data
    if columnName == "IsChosen" {
      let isChosen = track == nil ? (activeId == 0) : (track!.id == activeId)
      return isChosen ? "●" : ""
    } else { // if columnName == "TrackName" {
      return track?.readableTitle ?? "<None>"
    }
  }
  
  func tableViewSelectionDidChange(_ notification: Notification) {
    withAllTableViews { (view, type) in
      if view.numberOfSelectedRows > 0 {
        // note that track ids start from 1
        self.playerController.setTrack(view.selectedRow, forType: type)
        view.deselectAll(self)
        view.reloadData()
      }
    }
  }
  
  private func withAllTableViews (_ block: (NSTableView, MPVTrack.TrackType) -> Void) {
    block(audioTableView, .audio)
    block(subTableView, .sub)
    block(secSubTableView, .secondSub)
    block(videoTableView, .video)
  }
  
  // MARK: Actions
  
  // Tab buttons
  
  @IBAction func tabBtnAction(_ sender: NSButton) {
    tabView.selectTabViewItem(at: sender.tag)
  }
  
  @IBAction func slideUpBtnAction(_ sender: AnyObject) {
    mainWindow.hideSettingsView()
  }
  
  // Video tab
  
  @IBAction func aspectChangedAction(_ sender: NSSegmentedControl) {
    if let value = sender.label(forSegment: sender.selectedSegment) {
      playerController.setVideoAspect(value)
      mainWindow.displayOSD(.aspect(value))
    }
  }
  
  @IBAction func rotationChangedAction(_ sender: NSSegmentedControl) {
    let value = [0, 90, 180, 270][sender.selectedSegment]
    playerController.setVideoRotate(value)
    mainWindow.displayOSD(.rotate(value))
  }
  
  @IBAction func customAspectEditFinishedAction(_ sender: AnyObject?) {
    let value = customAspectTextField.stringValue
    if value != "" {
      aspectSegment.setSelected(false, forSegment: aspectSegment.selectedSegment)
      playerController.setVideoAspect(value)
      mainWindow.displayOSD(.aspect(value))
    }
  }
  
  @IBAction func speedChangedAction(_ sender: NSSlider) {
    //   0     1 ..     7  8    9 ..  26
    // -5x -4.5x .. -1.5x 1x 1.5x .. 10x
    let sliderValue = sender.doubleValue
    let value = sliderValue >= 8 ? (sliderValue / 2.0 - 3) : (sliderValue / 2.0 - 5)
    speedSliderIndicator.stringValue = "\(value)x"
    let knobPos = sender.knobPointPosition()
    speedSliderIndicator.setFrameOrigin(NSPoint(x: knobPos - sliderIndicatorHalfWidth, y: sender.frame.origin.y + distanceBetweenSliderAndIndicator))
    if let event = NSApp.currentEvent {
      if event.type == .leftMouseUp {
        playerController.setSpeed(value)
        mainWindow.displayOSD(.speed(value))
      }
    }
  }
  
  @IBAction func customSpeedEditFinishedAction(_ sender: NSTextField) {
    let value = customSpeedTextField.doubleValue
    if (value >= 1 || value <= -1 || value == 0) && playerController.info.playSpeed != value {
      let finalValue = value == 0 ? 1 : value
      playerController.setSpeed(finalValue)
      mainWindow.displayOSD(.speed(finalValue))
    }
    if let window = sender.window {
      window.makeFirstResponder(window.contentView)
    }
  }
  
  // Audio tab
  
  @IBAction func loadExternalAudioAction(_ sender: NSButton) {
    Utility.quickOpenPanel(title: "Load external audio file") { url in
      self.playerController.loadExternalAudioFile(url)
    }
    audioTableView.reloadData()
  }
  
  @IBAction func audioDelayChangedAction(_ sender: NSSlider) {
    let sliderValue = sender.doubleValue
    audioDelaySliderIndicator.stringValue = "\(sliderValue)s"
    let knobPos = sender.knobPointPosition()
    audioDelaySliderIndicator.setFrameOrigin(NSPoint(x: knobPos - sliderIndicatorHalfWidth, y: sender.frame.origin.y + distanceBetweenSliderAndIndicator))
    if let event = NSApp.currentEvent {
      if event.type == .leftMouseUp {
        playerController.setAudioDelay(sliderValue)
        mainWindow.displayOSD(.audioDelay(sliderValue))
      }
    }
  }
  
  @IBAction func customAudioDelayEditFinishedAction(_ sender: AnyObject?) {
    let value = customAudioDelayTextField.doubleValue
    playerController.setAudioDelay(value)
    mainWindow.displayOSD(.audioDelay(value))
  }
  
  // Sub tab
  
  @IBAction func loadExternalSubAction(_ sender: NSButton) {
    Utility.quickOpenPanel(title: "Load external subtitle") { url in
      self.playerController.loadExternalSubFile(url)
    }
    subTableView.reloadData()
    secSubTableView.reloadData()
  }
  
  @IBAction func subDelayChangedAction(_ sender: NSSlider) {
    let sliderValue = sender.doubleValue
    subDelaySliderIndicator.stringValue = "\(sliderValue)s"
    let knobPos = sender.knobPointPosition()
    subDelaySliderIndicator.setFrameOrigin(NSPoint(x: knobPos - sliderIndicatorHalfWidth, y: sender.frame.origin.y + distanceBetweenSliderAndIndicator))
    if let event = NSApp.currentEvent {
      if event.type == .leftMouseUp {
        playerController.setSubDelay(sliderValue)
        mainWindow.displayOSD(.subDelay(sliderValue))
      }
    }
  }
  
  @IBAction func customSubDelayEditFinishedAction(_ sender: AnyObject?) {
    let value = customSubDelayTextField.doubleValue
    playerController.setSubDelay(value)
    mainWindow.displayOSD(.subDelay(value))
  }
  
}
