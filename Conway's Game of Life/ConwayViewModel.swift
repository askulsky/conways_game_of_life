//
//  ConwayViewModel.swift
//  Conway's Game of Life
//
//  Created by Aaron Skulsky on 4/18/24.
//

import Foundation
import UIKit

enum Viability {
    case DEAD
    case ALIVE
}

class ConwayViewModel {
    @Published var shouldUpdateView: Bool = true
    @Published var isPlaying: Bool = false
    
    let numCellsPerRow = 15
    var numCellsPerCol: Int?
    var selectedCell: UIView?
    
    var width: CGFloat = UIScreen.main.bounds.width / CGFloat(15)
    var height: CGFloat = UIScreen.main.bounds.width / CGFloat(15)
    var cells = [String: UIView]()
    
    private var resetEventRegistration: NSObjectProtocol?
    
    func runConway(_ shouldUpdate: (([String: UIView], Bool, Bool) -> Void)? = nil) {
        var newCells: [String: UIView] = [:]
        var stale = true
        var reset = false
        isPlaying = true
        
        resetEventRegistration = EventBus.subscribe { [weak self] (event: ResetEvent) in
            guard let self = self else { return }
            EventBus.unsubscribe(self.resetEventRegistration)
            reset = true
        }
        
        if cells.contains(where: { $0.value.backgroundColor == .black }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                for j in 0...numCellsPerCol! {
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
                shouldUpdateView = true
                shouldUpdate?(newCells, stale, reset)
            }
        } else {
            isPlaying.toggle()
        }
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
    
    func createCell(_ viability: Viability, _ i: Int, _ j: Int) -> UIView {
        let cellView = UIView()
        cellView.backgroundColor = viability == .ALIVE ? .black : .white
        cellView.frame = CGRect(x: CGFloat(i) * width, y: CGFloat(j) * height, width: width, height: height)
        cellView.layer.borderWidth = 0.5
        cellView.layer.borderColor = UIColor.black.cgColor
        return cellView
    }
}
