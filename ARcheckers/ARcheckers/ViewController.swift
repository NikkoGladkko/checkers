//
//  ViewController.swift
//  Checkers
//
//  Created by Denis Malykh on 28.01.18.
//  Copyright © 2018 MrDekk. All rights reserved.
//

import UIKit
import ARKit

enum GameMode {
    case initializing
    case black
    case white
}

class ViewController: UIViewController {

    @IBOutlet weak var closeButton: UIButton!
    
    @IBAction func closeNow(_ sender: UIButton) {
        self.dismiss(animated: true) {
            //clear gameCenterSession
        }
    }
    
    private var mode: GameMode = .initializing

    private var checkerboard: CheckerBoard? = nil

    @IBOutlet private weak var sceneView: ARSCNView! {
        didSet {
            sceneView.delegate = self

            let rec = UITapGestureRecognizer(target: self, action: #selector(didTap))
            sceneView.addGestureRecognizer(rec)
        }
    }

    private var boards: [UUID: Board] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let conf = ARWorldTrackingConfiguration()
        conf.planeDetection = .horizontal
        sceneView.session.run(conf)

        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    @objc func didTap(_ rec: UITapGestureRecognizer) {
        let pt = rec.location(in: rec.view)
        guard let hit = sceneView.hitTest(pt).first else {
            return
        }

        switch mode {
        case .initializing: hitTestAndPlaceCheckerboard(hit)
        case .white: hitTestChecker(side: .white, hit: hit)
        case .black: hitTestChecker(side: .black, hit: hit)
        }
    }

    private func hitTestAndPlaceCheckerboard(_ hit: SCNHitTestResult) {
        let hitpos = hit.worldCoordinates

        let cb = CheckerBoard()
        cb.position = hitpos
        sceneView.scene.rootNode.addChildNode(cb)

        self.checkerboard = cb

        mode = .white
    }

    private func hitTestChecker(side: Checker.Side, hit: SCNHitTestResult) {
        switch hit.node {
        case let checker as Checker:
            if checker.side == side {
                checkerboard?.took(checker)
            }

        case let cell as CheckerBoardCell:
            if let cb = checkerboard, cb.place(cell) {
                switch mode {
                case .white: mode = .black
                case .black: mode = .white
                default: break
                }
            }

        default:
            break
        }
    }
}

extension ViewController : ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let a = anchor as? ARPlaneAnchor {
            let b = Board(anchor: a)
            boards[anchor.identifier] = b
            node.addChildNode(b)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let b = boards[anchor.identifier], let a = anchor as? ARPlaneAnchor {
            b.update(a)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        boards[anchor.identifier] = nil
    }
}
