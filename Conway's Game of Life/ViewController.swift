//
//  ViewController.swift
//  Conway's Game of Life
//
//  Created by Aaron Skulsky on 4/13/24.
//

import UIKit

class ViewController: UIViewController {
    
    enum Viability {
        case DEAD
        case ALIVE
    }
    
    let numCellsPerRow = 15
    var selectedCell: UIView?
    var gridView: UIView?
    var width: CGFloat = UIScreen.main.bounds.width / CGFloat(15)
    var height: CGFloat = UIScreen.main.bounds.width / CGFloat(15)
    var cells = [String: UIView]()
    
    let playPauseButton = BaseButton()
    let resetButton = BaseButton()
    
    
    var isPlaying: Bool = false {
        didSet {
            // Update button image based on playback state
            let imageName = isPlaying ? "pause.fill" : "play.fill"
            playPauseButton.setImage(UIImage(systemName: imageName), for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.gridView = UIView(frame: CGRect(x: 0, y: 0, width: self.width, height: self.height))
        view.addSubview(gridView!)
        setupInitialGrid()
        
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
        
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
    
    func setupInitialGrid() {
        isPlaying = false
        for j in 0...35 {
            for i in 0...numCellsPerRow {
                let cellView = createCell(.DEAD, i, j)
                gridView!.addSubview(cellView)
                let key = "\(i)|\(j)"
                cells[key] = cellView
            }
        }
    }
    
    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: gridView)
        let i = Int(location.x / self.width)
        let j = Int(location.y / self.height)
        
        let key = "\(i)|\(j)"
        guard let cellView = cells[key] else { return }
        
        if selectedCell != cellView {
            self.selectedCell?.backgroundColor = .black
        }
        
        selectedCell = cellView
    }
    
    @objc func playPauseButtonTapped() {
        isPlaying.toggle()
        runConway()
    }
    
    @objc func resetButtonTapped() {
        setupInitialGrid()
    }
    
    func runConway() {
        var newCells: [String: UIView] = [:]
        var stale = true
        if cells.contains(where: { $0.value.backgroundColor == .black }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                for j in 0...35 {
                    for i in 0...self.numCellsPerRow {
                        let key = "\(i)|\(j)"
                        let liveNeighbors = self.countAliveNeighbors(i, j)
                        if cells[key]?.backgroundColor == .black {
                            if liveNeighbors < 2 || liveNeighbors > 3 {
                                let cellView = createCell(.DEAD, i, j)
                                newCells[key] = cellView
                                stale = false
                            } else {
                                newCells[key] = cells[key]
                            }
                        } else {
                            if liveNeighbors == 3 {
                                let cellView = createCell(.ALIVE, i, j)
                                newCells[key] = cellView
                                stale = false
                            } else {
                                newCells[key] = cells[key]
                            }
                        }
                    }
                }
                
                
                
                for (key, newCell) in newCells {
                    if let oldView = cells[key] {
                        oldView.removeFromSuperview()
                    }
                    // Add the new view to the parent view
                    gridView!.addSubview(newCell)
                }
                
                cells = newCells
                
                if stale {
                    isPlaying = false
                    let alert = UIAlertController(title: "Alert", message: "Reached Equilibrium", preferredStyle: .alert)
                    let action = UIAlertAction(title: "Dismiss", style: .default) { _ in
                        self.setupInitialGrid()
                    }
                    
                    alert.addAction(action)
                    self.present(alert, animated: true)
                }
                
                if isPlaying {
                    runConway()
                }
            }
        } else {
            isPlaying.toggle()
        }
    }
    
    func createCell(_ viability: Viability, _ i: Int, _ j: Int) -> UIView {
        let cellView = UIView()
        cellView.backgroundColor = viability == .ALIVE ? .black : .white
        cellView.frame = CGRect(x: CGFloat(i) * width, y: CGFloat(j) * height, width: width, height: height)
        cellView.layer.borderWidth = 0.5
        cellView.layer.borderColor = UIColor.black.cgColor
        return cellView
    }
    
    func countAliveNeighbors(_ row: Int, _ col: Int) -> Int {
        var count = 0
        for i in -1...1 {
            for j in -1...1 {
                if i == 0 && j == 0 {
                    continue
                }
                let neighborRow = row + i
                let neighborCol = col + j
                if let neighborCell = cells["\(neighborRow)|\(neighborCol)"], neighborCell.backgroundColor == .black {
                    count += 1
                }
            }
        }
        
        return count
    }
}

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

