//
//  ViewController.swift
//  Conway's Game of Life
//
//  Created by Aaron Skulsky on 4/13/24.
//

import Foundation
import UIKit
import Dispatch

class ViewController: UIViewController {
    let vm = ConwayViewModel()
    
    var gridView: UIView?
    let playPauseButton = BaseButton()
    let resetButton = BaseButton()
    
    var isPlaying: Bool = false {
        didSet {
            // Update button image based on playback state
            let imageName = vm.isPlaying ? "pause.fill" : "play.fill"
            playPauseButton.setImage(UIImage(systemName: imageName), for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.gridView = UIView(frame: CGRect(x: 0, y: 0, width: vm.width, height: vm.height))
        view.addSubview(gridView!)
        calculateCellsInCol()
        setupInitialGrid()
        
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        
        resetButton.setImage(UIImage(systemName: "arrow.counterclockwise"), for: .normal)
        
        view.addSubview(playPauseButton)
        view.addSubview(resetButton)

        // Add constraints
        NSLayoutConstraint.activate([
            playPauseButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            playPauseButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            playPauseButton.widthAnchor.constraint(equalToConstant: 50),
            playPauseButton.heightAnchor.constraint(equalToConstant: 50),
            
            resetButton.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -15),
            resetButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            resetButton.widthAnchor.constraint(equalToConstant: 50),
            resetButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        // Add action for the button
        playPauseButton.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
    }
    
    func calculateCellsInCol() {
        let cellSize = UIScreen.main.bounds.width / CGFloat(vm.numCellsPerRow)
        vm.numCellsPerCol = Int(ceil(UIScreen.main.bounds.height / cellSize))
    }
    
    func setupInitialGrid() {
        vm.isPlaying = false
        isPlaying = vm.isPlaying
        for j in 0...vm.numCellsPerCol! {
            for i in 0...vm.numCellsPerRow {
                let cellView = vm.createCell(.DEAD, i, j)
                gridView!.addSubview(cellView)
                let key = "\(i)|\(j)"
                vm.cells[key] = cellView
            }
        }
    }
    
    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        self.handleGesture(gesture)
    }
    
    @objc func handleTap(gesture: UITapGestureRecognizer) {
        self.handleGesture(gesture)
    }
    
    func handleGesture<T: UIGestureRecognizer>(_ gesture: T) {
        let location = gesture.location(in: gridView)
        let i = Int(location.x / vm.width)
        let j = Int(location.y / vm.height)
        
        let key = "\(i)|\(j)"
        guard let cellView = vm.cells[key] else { return }
        
        cellView.backgroundColor = .black
    }
    
    @objc func playPauseButtonTapped() {
        vm.isPlaying.toggle()
        vm.runConway { [weak self] (newCells, stale, reset) in
            self?.handleUpdate(newCells, stale, reset)
        }
    }
    
    @objc func resetButtonTapped() {
        EventBus.publish(ResetEvent())
        vm.isPlaying = false
        setupInitialGrid()
    }
    
    func handleUpdate(_ newCells: [String: UIView], _ stale: Bool, _ reset: Bool) {
        guard !reset && vm.shouldUpdateView else { return }
        
        vm.shouldUpdateView = false
        
        for (key, newCell) in newCells {
            if let oldView = vm.cells[key] {
                oldView.removeFromSuperview()
            }
            
            gridView!.addSubview(newCell)
        }
        
        vm.cells = newCells
        isPlaying = vm.isPlaying
        
        if stale {
            let alert = UIAlertController(title: "Alert", message: "Reached Equilibrium", preferredStyle: .alert)
            let action = UIAlertAction(title: "Dismiss", style: .default) { _ in
                self.setupInitialGrid()
            }
            
            alert.addAction(action)
            self.present(alert, animated: true)
            return
        }
        
        if isPlaying {
            vm.runConway { [weak self] (newCells, stale, reset) in
                self?.handleUpdate(newCells, stale, reset)
            }
        }
    }
}

class ResetEvent {}

class BaseButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        bind()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        bind()
    }
    
    private func bind() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.frame.size = CGSize(width: 50, height: 50)
        self.backgroundColor = .gray
        self.layer.cornerRadius = 25
        self.tintColor = .white
    }
}

public class EventBus {
    
    private static let userInfoEventKey = "EVENT"
    
    public static func publish<E: Any>(_ event: E, name: String = String(describing: E.self)) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(name), object: nil, userInfo: [userInfoEventKey: event])
        }
    }
    
    @discardableResult public static func subscribe<E: Any>(_ callback: @escaping (E) -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: NSNotification.Name(String(describing: E.self)), object: nil, queue: nil, using: { notification in
            if let event = notification.userInfo?[userInfoEventKey] as? E {
                DispatchQueue.main.async {
                    callback(event)
                }
            }
        })
    }
    
    public static func unsubscribe(_ token: NSObjectProtocol?) {
        if let token = token {
            NotificationCenter.default.removeObserver(token)
        }
    }
}
