import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fyp/services/HostelScoreModel.dart'; // Fallback

class DynamicHostelScoreModel {
  List<dynamic>? _trees;
  bool _isLoaded = false;
  
  // Singleton instance
  static final DynamicHostelScoreModel _instance = DynamicHostelScoreModel._internal();
  factory DynamicHostelScoreModel() => _instance;
  DynamicHostelScoreModel._internal();

  Future<void> fetchLatestWeights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? cachedModel = prefs.getString('xgboost_model_json');
      if (cachedModel != null) {
        _trees = json.decode(cachedModel);
        _isLoaded = true;
      }
      
      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/Tanveer-Hussian/NestIQ/main/assets/ml/xgboost_model.json'));

      if (response.statusCode == 200) {
        _trees = json.decode(response.body);
        _isLoaded = true;
        prefs.setString('xgboost_model_json', response.body);
      }
    } catch (e) {
      print("Failed to fetch dynamic weights: \$e");
    }
  }

  /// Evaluates the input features against the XGBoost trees.
  double predict(List<double> input) {
    if (!_isLoaded || _trees == null) {
      // Fallback to the hardcoded static model if dynamic model is unavailable
      return predictHostelScore(input);
    }
    
    double sum = 0.5; // Base score is usually 0.5 in XGBoost binary classification, but for regression it depends.
    for (var tree in _trees!) {
      sum += _evaluateTree(tree, input);
    }
    return sum;
  }

  double _evaluateTree(dynamic node, List<double> input) {
    if (node.containsKey('leaf')) {
      return (node['leaf'] as num).toDouble();
    }
    
    String splitFeature = node['split'];
    int featureIndex = int.parse(splitFeature.replaceAll('f', '')); // 'f0' -> 0
    double splitCondition = (node['split_condition'] as num).toDouble();
    
    int nextNodeId;
    if (input[featureIndex] < splitCondition) {
      nextNodeId = node['yes'];
    } else {
      nextNodeId = node['no'];
    }
    
    // Find child node
    var children = node['children'] as List;
    var nextNode = children.firstWhere((c) => c['nodeid'] == nextNodeId, orElse: () => null);
    if (nextNode == null) return 0.0; // Should not happen in a valid tree
    
    return _evaluateTree(nextNode, input);
  }
}
