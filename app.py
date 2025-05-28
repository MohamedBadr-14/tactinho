from flask import Flask, request, jsonify
import numpy as np
from typing import List, Dict, Any
from scipy.spatial.distance import cdist
from sklearn.preprocessing import MinMaxScaler
from sklearn.neighbors import NearestNeighbors
import json
from flask_cors import CORS

def load_sequences_from_json(json_path):
    """
    Load sequences from a JSON file.
    The JSON should be a list of sequences, where each sequence is a list of scenes.
    """
    with open(json_path, "r") as f:
        data = json.load(f)
    return data

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Your existing code (slightly modified for the API)
formation_features = [
    # Team shape features
    "team1_width",
    "team1_height",
    "team1_avg_spread",
    "team1_max_spread",
    "team1_min_pair_dist",
    "team1_avg_pair_dist",
    "team1_min_ball_dist",
    "team1_avg_ball_dist",
    "team2_width",
    "team2_height",
    "team2_avg_spread",
    "team2_max_spread",
    # Global features
    "ball_x",
    "ball_y",
]

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
        self.scaler = MinMaxScaler()
        
    def extract_features(self, scene):
        """Extract only formation-relevant features (invariant to player ordering)."""
        features = {}
        players = scene["players"]
        team1 = [p for p in players.values() if p["team"] == 1]
        team2 = [p for p in players.values() if p["team"] == 0]

        # Team sizes (critical for filtering)
        features["team1_size"] = len(team1)
        features["team2_size"] = len(team2)

        # Ball position
        ball_pos = np.array([0.5, 0.5])  # Default field center
        if scene["ball"]:
            ball = next(iter(scene["ball"].values()))
            ball_pos = np.array(ball["position_transformed"])
            features["ball_x"] = ball_pos[0]
            features["ball_y"] = ball_pos[1]

        features["team1_has_ball"] = False
        for player in team1:
            if player.get("has_ball", False):
                features["team1_has_ball"] = True
                break

        # Process each team's formation
        for team_num, team in [(1, team1), (2, team2)]:
            prefix = f"team{team_num}_"
            if not team:
                continue

            positions = np.array([p["position_transformed"] for p in team])
            centroid = np.mean(positions, axis=0)

            # 1. Formation shape descriptors
            if len(positions) > 1:
                # Bounding box dimensions
                width = np.max(positions[:, 0]) - np.min(positions[:, 0])
                height = np.max(positions[:, 1]) - np.min(positions[:, 1])
                features[f"{prefix}width"] = width
                features[f"{prefix}height"] = height
                # print("midoo", features)

                # Spread metrics
                dist_to_centroid = np.linalg.norm(positions - centroid, axis=1)
                features[f"{prefix}avg_spread"] = np.mean(dist_to_centroid)
                features[f"{prefix}max_spread"] = np.max(dist_to_centroid)

            # 2. Ball-relative positioning
            ball_dists = np.linalg.norm(positions - ball_pos, axis=1)
            features[f"{prefix}min_ball_dist"] = (
                np.min(ball_dists) if len(ball_dists) > 0 else 0
            )
            features[f"{prefix}avg_ball_dist"] = (
                np.mean(ball_dists) if len(ball_dists) > 0 else 0
            )

        return features
    
    def filter_scenes(self, query_feats, max_abs_dist=5):
        """Filter scenes in 2 stages:
        1. Exact team size match.
        2. Absolute position proximity (ball + centroids).
        """
        candidates = []

        # Stage 1: Team size matching
        for idx, scene_feats in self.features.items():
            # print('hasball,scene_feats["team1_has_ball"]', scene_feats["team1_has_ball"])
            if (
                scene_feats["team1_size"] == query_feats["team1_size"]
                and scene_feats["team2_size"] == query_feats["team2_size"]
                and scene_feats["team1_has_ball"] == True
            ):
                candidates.append(idx)

        print("Candidates after team size match:", candidates)
        if not candidates:
            return []  # No matches with same team sizes
        # Stage 2: Absolute position filtering
        filtered = []
        query_ball = np.array([query_feats["ball_x"], query_feats["ball_y"]])

        for idx in candidates:
            scene_feats = self.features[idx]
            scene_ball = np.array([scene_feats["ball_x"], scene_feats["ball_y"]])
            ball_dist = np.linalg.norm(query_ball - scene_ball)
            # print("Ball dist:", ball_dist)

            if ball_dist <= max_abs_dist:
                # and (
                #     not team_dists or all(d <= max_abs_dist for d in team_dists)
                # )

                filtered.append(idx)

        return filtered
    
    def match_formations(self, query_feats, candidate_indices):
        """Match formations using only the essential formation features."""
        if not candidate_indices:
            return None

        # Define our focused feature set

        # Build query vector
        query_vector = [query_feats.get(f, 0) for f in formation_features]
        # print(query_feats)
        # print("Query vector:", query_vector)

        # Build candidate matrix
        candidate_vectors = []
        valid_indices = []

        for idx in candidate_indices:
            scene_feats = self.features[idx]
            candidate_vec = [scene_feats.get(f, 0) for f in formation_features]
            candidate_vectors.append(candidate_vec)
            valid_indices.append(idx)

        if not valid_indices:
            return None

        # Normalize features
        all_features = np.array([query_vector] + candidate_vectors)
        means = np.mean(all_features, axis=0)
        stds = np.std(all_features, axis=0)
        stds[stds == 0] = 1  # Avoid division by zero
        print("Means:", means)
        print("Stds:", stds)
        print(all_features)

        norm_query = (query_vector - means) / stds
        norm_candidates = (np.array(candidate_vectors) - means) / stds

        # Find nearest neighbor
        nbrs = NearestNeighbors(n_neighbors=1, metric="euclidean").fit(norm_candidates)
        _, matches = nbrs.kneighbors([norm_query])

        return valid_indices[matches[0][0]]
    
    def process_sequences(self, goal_sequences):
        """Flatten all scenes into one array, each with id and next_id."""
        all_scenes = []
        features_obj = {}
        scene_id = 0

        for sequence in goal_sequences:
            for idx, scene in enumerate(sequence):
                features = self.extract_features(scene)

                # Determine next_id
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
                
        # print("Processed scenes:", all_scenes)
        return all_scenes, features_obj
    
    def get_sequence_from_match(self, initial_scene_id):
        """Follow next_id pointers to get a sequence"""
        sequence = []
        current_id = initial_scene_id
        
        while current_id is not None:
            scene = self.scenes[current_id]
            sequence.append(scene["original_scene"])
            current_id = scene.get("next_id", None)
        
        return sequence

# Initialize with your training data
scenes=load_sequences_from_json("db.json")
# scenes = [load_sequences_from_json("transformed_tracks.json")]
# print("Loaded scenes:", scenes_arr)

matcher = SceneMatcher(scenes)  # Pass your actual training sequences

@app.route('/api/get_all_first_scenes', methods=['GET'])
def get_all_first_scenes():
    """
    Endpoint to retrieve only the first scene from each sequence
    """
    try:
        # Find the start ID of each sequence
        first_scene_ids = set()
        current_id = 0
        
        # Iterate through the original sequences structure to find first IDs
        sequence_count = 0
        for sequence in scenes:
            if sequence:  # Check if sequence is not empty
                first_scene_ids.add(current_id)
                current_id += len(sequence)  # Skip to next sequence
                sequence_count += 1
        
        # Get only the first scenes
        first_scenes = [scene for scene in matcher.scenes if scene['id'] in first_scene_ids]
        
        return jsonify({"first_scenes": first_scenes, "count": len(first_scenes)}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/get_all_scenes', methods=['GET'])
def get_all_scenes():
    """
    Endpoint to retrieve all scenes
    """
    try:
        return jsonify({"scenes": matcher.scenes}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/predict_sequence', methods=['POST'])
def predict_sequence():
    """
    Endpoint that takes a scene and returns predicted sequence
    Example request body: {"scene": {players: {...}, ball: {...}}}
    """
    try:
        data = request.get_json()
        # print("Received data:", data['scene'])
        input_scene = data.get('scene')
        
        if not input_scene:
            return jsonify({"error": "No scene provided"}), 400
        
        # 1. Extract features from input scene
        query_feats = matcher.extract_features(input_scene)
        
        # 2. Filter candidate scenes
        candidates = matcher.filter_scenes(query_feats)
        print("Filtered candidates:", candidates)
        
        # 3. Find best match
        matched_id = matcher.match_formations(query_feats, candidates)
        print("Matched ID:", matched_id)
        if matched_id is None:
            return jsonify({"error": "No matching scene found"}), 404
        
        # 4. Get the sequence
        sequence = matcher.get_sequence_from_match(matched_id)
        print("sequence:", sequence)
        
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