import 'dart:async';

import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart' as vector64;
import 'dart:math' as math;

class ARKitTestPage extends StatefulWidget {
  const ARKitTestPage({Key? key}) : super(key: key);

  @override
  State<ARKitTestPage> createState() => _ARKitTestPageState();
}

class _ARKitTestPageState extends State<ARKitTestPage> {
  late ARKitController _arKitController;
  final _arKitControllerCompleter = Completer<ARKitController>();

  // ARKitReferenceNode? _node;

  ARKitNode? _node;
  ARKitNode? _leftEye;
  ARKitNode? _rightEye;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _arKitController.dispose();
    super.dispose();
  }

  ARKitNode _createEye(Matrix4 transform) {
    final position = vector64.Vector3(
      transform.getColumn(3).x,
      transform.getColumn(3).y,
      transform.getColumn(3).z,
    );
    final material = ARKitMaterial(
      diffuse: ARKitMaterialProperty.color(Colors.yellow),
    );
    final sphere = ARKitBox(materials: [material], width: 0.03, height: 0.03, length: 0.03);

    return ARKitNode(geometry: sphere, position: position);
  }

  void _updateEye(ARKitNode node, Matrix4 transform, double blink) {
    final scale = vector64.Vector3(1, 1 - blink, 1);
    node.scale = scale;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance?.addPostFrameCallback(
      (timeStamp) async {
        _arKitController = await _arKitControllerCompleter.future;
        // _arKitController.addCoachingOverlay(CoachingOverlayGoal.horizontalPlane);
        _arKitController.onAddNodeForAnchor = (anchor) {
          // if (anchor is ARKitPlaneAnchor) {
          //   if (_node != null) {
          //     _arKitController.remove(_node!.name);
          //   }
          //   _node = ARKitReferenceNode(
          //     url: 'models.scnassets/dash.dae',
          //     // url: 'models.scnassets/2CylinderEngine.glb', // khong duoc
          //     // url: 'models.scnassets/engine.gltf', // khong duoc
          //     scale: vector64.Vector3.all(0.3),
          //   );
          //   _arKitController.add(_node!, parentNodeName: anchor.nodeName);

          //   // _arKitController.add(ARKitNode(
          //   //   geometry: ARKitSphere(materials: [
          //   //     ARKitMaterial(
          //   //       lightingModelName: ARKitLightingModel.physicallyBased,
          //   //       diffuse: ARKitMaterialProperty.color(
          //   //         Color((math.Random().nextDouble() * 0xFFFFFF).toInt() << 0).withOpacity(1.0),
          //   //       ),
          //   //     )
          //   //   ], radius: 0.04),
          //   //   position: vector64.Vector3(0, 0, 0),
          //   // ));
          // }

          if (anchor is ARKitFaceAnchor) {
            final material = ARKitMaterial(fillMode: ARKitFillMode.lines);
            anchor.geometry.materials.value = [material];

            _node = ARKitNode(geometry: anchor.geometry);
            _arKitController.add(_node!, parentNodeName: anchor.nodeName);

            _leftEye = _createEye(anchor.leftEyeTransform);
            _arKitController.add(_leftEye!, parentNodeName: anchor.nodeName);
            _rightEye = _createEye(anchor.rightEyeTransform);
            _arKitController.add(_rightEye!, parentNodeName: anchor.nodeName);
          }
        };

        _arKitController.onUpdateNodeForAnchor = (anchor) {
          if (anchor is ARKitFaceAnchor && mounted) {
            final faceAnchor = anchor;
            _arKitController.updateFaceGeometry(_node!, anchor.identifier);
            _updateEye(
              _leftEye!,
              faceAnchor.leftEyeTransform,
              faceAnchor.blendShapes['eyeBlink_L'] ?? 0,
            );
            _updateEye(
              _rightEye!,
              faceAnchor.rightEyeTransform,
              faceAnchor.blendShapes['eyeBlink_R'] ?? 0,
            );
          }
        };
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Custom object on plane Sample')),
      body: ARKitSceneView(
        onARKitViewCreated: (controller) => _arKitControllerCompleter.complete(controller),
        // showFeaturePoints: true,
        // planeDetection: ARPlaneDetection.horizontal,
        configuration: ARKitConfiguration.faceTracking,
      ),
    );
  }
}
