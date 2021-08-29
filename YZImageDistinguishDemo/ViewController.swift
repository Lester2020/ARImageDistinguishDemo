//
//  ViewController.swift
//  YZImageDistinguishDemo
//
//  Created by Lester‘s Mac on 2021/8/29.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    private lazy var sceneView: ARSCNView = {
        let view = ARSCNView(frame: UIScreen.main.bounds)
        view.delegate = self
        //显示追踪点
        view.debugOptions = [.showFeaturePoints]
        //为3D模型（若模型本身未打光）打光
        view.autoenablesDefaultLighting = true
        view.automaticallyUpdatesLighting = true
        view.backgroundColor = .black
        return view
    }()
    
    private lazy var treeNode: SCNNode = {
        guard let scene = SCNScene(named: "art.scnassets/tree.scn"),
            let node = scene.rootNode.childNode(withName: "tree", recursively: false) else { return SCNNode() }
        let scaleFactor = 0.005
        node.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
        node.eulerAngles.x = -.pi / 2
        return node
    }()
    
    private lazy var bookNode: SCNNode = {
        guard let scene = SCNScene(named: "art.scnassets/book.scn"),
            let node = scene.rootNode.childNode(withName: "book", recursively: false) else { return SCNNode() }
        let scaleFactor  = 0.1
        node.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
        return node
    }()
    
    private lazy var mountainNode: SCNNode = {
        guard let scene = SCNScene(named: "art.scnassets/mountain.scn"),
            let node = scene.rootNode.childNode(withName: "mountain", recursively: false) else { return SCNNode() }
        let scaleFactor  = 0.25
        node.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
        node.eulerAngles.x += -.pi / 2
        return node
    }()
    
    private lazy var fadeAndSpinAction: SCNAction = {
        return .sequence([
            .fadeIn(duration: 0.3),
            .rotateBy(x: 0, y: 0, z: CGFloat.pi * 360 / 180, duration: 3.0),
            .wait(duration: 0.5),
            .fadeOut(duration: 0.3)
        ])
    }()
    
    private lazy var fadeAction: SCNAction = {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
        ])
    }()
    
    private lazy var effectView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: effect)
        view.alpha = 0.7
        return view
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel.init()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        return label
    }()
    
    private lazy var resetBtn: UIButton = {
        let btn = UIButton.init()
        btn.setTitle("重置", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.addTarget(self, action: #selector(resetTracking), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(sceneView)
        effectView.frame = CGRect(x: 0, y: view.bounds.height - UIApplication.shared.windows[0].safeAreaInsets.bottom - 50, width: view.bounds.width, height: 50 + UIApplication.shared.windows[0].safeAreaInsets.bottom)
        view.addSubview(effectView)
        messageLabel.frame = CGRect(x: 12, y: 10, width: 200, height: 30)
        effectView.contentView.addSubview(messageLabel)
        resetBtn.frame = CGRect(x: view.bounds.width - 50, y: 5, width: 40, height: 40)
        effectView.contentView.addSubview(resetBtn)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //暂停session
        sceneView.session.pause()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc private func resetTracking() {
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else { return }
        //启用世界追踪模式
        let configuration = ARWorldTrackingConfiguration()
        //类似于平面检测，这里设置为图片检测；并指定哪些图片需要被检测
        configuration.detectionImages = referenceImages
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        //运行session
        sceneView.session.run(configuration, options: options)
        
        messageLabel.text = "将相机对准要识别的图片"
        resetBtn.isSelected = false
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor,
            let imageName = imageAnchor.referenceImage.name else { return }
        
        DispatchQueue.main.async {
            let planeNode = self.getPlaneNode(withReferenceImage: imageAnchor.referenceImage)
            planeNode.opacity = 0.2
            planeNode.eulerAngles.x = -.pi / 2
            planeNode.runAction(self.fadeAction)
            node.addChildNode(planeNode)
            
            let overlayNode = self.getNode(withImageName: imageName)
            overlayNode.opacity = 0
            overlayNode.position.y = 0.2
            overlayNode.runAction(self.fadeAndSpinAction)
            node.addChildNode(overlayNode)
            
            self.messageLabel.text = "识别图片：\(imageName)"
            self.resetBtn.isSelected = true
        }
    }
    
    private func getNode(withImageName name: String) -> SCNNode {
        var node = SCNNode()
        switch name {
        case "Book":
            node = bookNode
        case "Snow Mountain":
            node = mountainNode
        case "Trees In the Dark":
            node = treeNode
        default:
            break
        }
        return node
    }
    
    private func getPlaneNode(withReferenceImage image: ARReferenceImage) -> SCNNode {
        let plane = SCNPlane(width: image.physicalSize.width,
                             height: image.physicalSize.height)
        let node = SCNNode(geometry: plane)
        return node
    }


}

