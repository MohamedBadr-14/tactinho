from flask import Flask, request, jsonify
import numpy as np
from typing import List, Dict, Any
from scipy.spatial.distance import cdist
from sklearn.preprocessing import MinMaxScaler
from sklearn.neighbors import NearestNeighbors
import json
from flask_cors import CORS
from scipy.optimize import linear_sum_assignment
import random

def load_sequences_from_json(json_path):
    """
    Load sequences from a JSON file.
    The JSON should be a list of sequences, where each sequence is a list of scenes.
    """
    with open(json_path, "r") as f:
        data = json.load(f)
    return data

app = Flask(__name__)
CORS(app)

def convert_numpy(obj):
    if isinstance(obj, np.ndarray):
        return obj.tolist()
    elif isinstance(obj, dict):
        return {k: convert_numpy(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_numpy(item) for item in obj]
    return obj

class SceneMatcher:
    def __init__(self, goal_sequences):
        self.scenes, self.features = self.process_sequences(goal_sequences)
        
    def extract_features(self, scene):
        features = {}
        players = scene["players"]
        team1 = [p for p in players.values() if p["team"] == 1]
        team2 = [p for p in players.values() if p["team"] == 0]

        features["team1_size"] = len(team1)
        features["team2_size"] = len(team2)

        ball_pos = None
        
        for player_id, player in players.items():
            if player.get("has_ball", False):
                ball_pos = np.array(player["position_transformed"])
                break
                
        if ball_pos is not None:
            features["ball_x"] = ball_pos[0]
            features["ball_y"] = ball_pos[1]
        else:
            features["ball_x"] = 0.0
            features["ball_y"] = 0.0

        features["team1_has_ball"] = False
        for player in team1:
            if player.get("has_ball", False):
                features["team1_has_ball"] = True
                break

        features["team1_positions"] = np.array([p["position_transformed"] for p in team1]) if team1 else np.array([])
        features["team2_positions"] = np.array([p["position_transformed"] for p in team2]) if team2 else np.array([])

        return features
    
    def filter_scenes(self, query_feats, max_abs_dist=10):
        candidates = []

        for idx, scene_feats in self.features.items():
            if (
                scene_feats["team1_size"] == query_feats["team1_size"]
                and scene_feats["team2_size"] == query_feats["team2_size"]
                and scene_feats["team1_has_ball"] == True
            ):
                candidates.append(idx)

        if not candidates:
            return []
        
        filtered = []
        query_ball = np.array([query_feats["ball_x"], query_feats["ball_y"]])

        for idx in candidates:
            scene_feats = self.features[idx]
            scene_ball = np.array([scene_feats["ball_x"], scene_feats["ball_y"]])
            ball_dist = np.linalg.norm(query_ball - scene_ball)

            if ball_dist <= max_abs_dist:
                filtered.append(idx)

        return filtered
    
    def calculate_player_matching_distance(self, query_positions, candidate_positions):
        if len(query_positions) == 0 or len(candidate_positions) == 0:
            return 0, {}

        if len(query_positions) != len(candidate_positions):
            return 10000000, {}

        distance_matrix = cdist(query_positions, candidate_positions, metric='euclidean')

        max_dist_threshold = 10.0
        penalty_matrix = distance_matrix.copy()
        penalty_matrix[distance_matrix > max_dist_threshold] = 1000.0 

        row_indices, col_indices = linear_sum_assignment(penalty_matrix)
        matched_distances = distance_matrix[row_indices, col_indices]

        exceeding_threshold = matched_distances > max_dist_threshold
        num_bad_matches = np.sum(exceeding_threshold)

        total_distance = np.sum(matched_distances)

        if num_bad_matches > len(matched_distances) / 3:
            total_distance = 10000000

        mapping = {}
        for query_idx, candidate_idx in zip(row_indices, col_indices):
            if query_idx < len(query_positions) and candidate_idx < len(candidate_positions):
                mapping[query_idx] = candidate_idx

        return total_distance, mapping
    
    def match_formations(self, query_feats, candidate_indices):
        if not candidate_indices:
            return None, None, None
        
        query_team1_pos = query_feats["team1_positions"]
        query_team2_pos = query_feats["team2_positions"]
    
        best_match_id = None
        best_total_distance = 10000000
        best_team1_mapping = None
        best_team2_mapping = None
            
        for idx in candidate_indices:
            scene_feats = self.features[idx]
            candidate_team1_pos = scene_feats["team1_positions"]
            candidate_team2_pos = scene_feats["team2_positions"]
        
            team1_distance, team1_mapping = self.calculate_player_matching_distance(
                query_team1_pos, candidate_team1_pos
            )
            
            team2_distance, team2_mapping = self.calculate_player_matching_distance(
                query_team2_pos, candidate_team2_pos
            )
            
            total_distance = team1_distance + team2_distance
        
            if total_distance < best_total_distance:
                best_total_distance = total_distance
                best_match_id = idx
                best_team1_mapping = team1_mapping
                best_team2_mapping = team2_mapping
    
        return best_match_id, best_team1_mapping, best_team2_mapping
    
    def process_sequences(self, goal_sequences):
        all_scenes = []
        features_obj = {}
        scene_id = 0

        for sequence in goal_sequences:
            for idx, scene in enumerate(sequence):
                features = self.extract_features(scene)

                if idx < len(sequence) - 1:
                    next_id = scene_id + 1
                else:
                    next_id = None

                features_obj[scene_id] = features
                all_scenes.append(
                    {
                        "id": scene_id,
                        "original_scene": scene,
                        "features": features,
                        "next_id": next_id,
                    }
                )
                scene_id += 1
                
        return all_scenes, features_obj
    
    def get_sequence_from_match(self, initial_scene_id, query_scene, team1_mapping=None, team2_mapping=None):
        sequence = []
        current_id = initial_scene_id
        
        matched_scene = None
        if current_id is not None:
            matched_scene = self.scenes[current_id]["original_scene"]
        
        while current_id is not None:
            scene = self.scenes[current_id]
            sequence.append(scene["original_scene"])
            current_id = scene.get("next_id", None)
        
        if sequence and matched_scene and (team1_mapping is not None or team2_mapping is not None):
            modified_query = json.loads(json.dumps(query_scene))
            
            query_team1_players = []
            query_team2_players = []
            for player_id, player in query_scene.get("players", {}).items():
                if player["team"] == 1:
                    query_team1_players.append({
                        "id": player_id,
                        "position_transformed": np.array(player["position_transformed"]),
                        "player": player
                    })
                else:
                    query_team2_players.append({
                        "id": player_id,
                        "position_transformed": np.array(player["position_transformed"]),
                        "player": player
                    })
            
            matched_team1_players = []
            matched_team2_players = []
            for player_id, player in matched_scene.get("players", {}).items():
                if player["team"] == 1:
                    matched_team1_players.append({
                        "id": player_id,
                        "position_transformed": np.array(player["position_transformed"]),
                        "player": player
                    })
                else:
                    matched_team2_players.append({
                        "id": player_id,
                        "position_transformed": np.array(player["position_transformed"]),
                        "player": player
                    })
            
            new_players = {}
            
            if team1_mapping and query_team1_players and matched_team1_players:
                for query_idx, matched_idx in team1_mapping.items():
                    if query_idx < len(query_team1_players) and matched_idx < len(matched_team1_players):
                        matched_player_id = matched_team1_players[matched_idx]["id"]
                        new_players[matched_player_id] = query_team1_players[query_idx]["player"]
            
            if team2_mapping and query_team2_players and matched_team2_players:
                for query_idx, matched_idx in team2_mapping.items():
                    if query_idx < len(query_team2_players) and matched_idx < len(matched_team2_players):
                        matched_player_id = matched_team2_players[matched_idx]["id"]
                        new_players[matched_player_id] = query_team2_players[query_idx]["player"]
            
            matched_used_ids = set(new_players.keys())
            
            for player_info in matched_team1_players:
                player_id = player_info["id"]
                if player_id not in matched_used_ids:
                    new_players[player_id] = player_info["player"]
            
            for player_info in matched_team2_players:
                player_id = player_info["id"]
                if player_id not in matched_used_ids:
                    new_players[player_id] = player_info["player"]
            
            modified_query["players"] = new_players
            if "action" in matched_scene:
                modified_query["action"] = matched_scene["action"]
            

            sequence[0] = modified_query
        
        return sequence


scenes = load_sequences_from_json("dba.json")
random.shuffle(scenes)

matcher = SceneMatcher(scenes)

@app.route('/api/get_all_first_scenes', methods=['GET'])
def get_all_first_scenes():
    try:
        first_scene_ids = set()
        current_id = 0
        
        sequence_count = 0
        for sequence in scenes:
            if sequence: 
                first_scene_ids.add(current_id)
                current_id += len(sequence) 
                sequence_count += 1
        
        first_scenes = [scene for scene in matcher.scenes if scene['id'] in first_scene_ids]
        
        serializable_first_scenes = convert_numpy(first_scenes)
        
        return jsonify({"first_scenes": serializable_first_scenes, "count": len(serializable_first_scenes)}), 200
    except Exception as e:
        print(f"Error in get_all_first_scenes: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/get_all_scenes', methods=['GET'])
def get_all_scenes():
    try:
        return jsonify({"scenes": matcher.scenes}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/predict_sequence', methods=['POST'])
def predict_sequence():
    try:
        data = request.get_json()
        input_scene = data.get('scene')
        
        if not input_scene:
            return jsonify({"error": "No scene provided"}), 400
        
        query_feats = matcher.extract_features(input_scene)   
        candidates = matcher.filter_scenes(query_feats)
        
        matched_id, best_team1_mapping, best_team2_mapping = matcher.match_formations(query_feats, candidates)
        if matched_id is None:
            return jsonify({"error": "No matching scene found"}), 404
        
        sequence = matcher.get_sequence_from_match(matched_id, input_scene,best_team1_mapping, best_team2_mapping)
        serializable_sequence = convert_numpy(sequence)

        
        return jsonify({
            "status": "success",
            "matched_scene_id": matched_id,
            "sequence": serializable_sequence
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)