from flask import Flask, request, jsonify
import numpy as np
from typing import List, Dict, Any
from scipy.spatial.distance import cdist
from sklearn.preprocessing import MinMaxScaler
from sklearn.neighbors import NearestNeighbors
import json
from flask_cors import CORS
from scipy.optimize import linear_sum_assignment

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
        """Extract features including player positions for matching."""
        features = {}
        players = scene["players"]
        team1 = [p for p in players.values() if p["team"] == 1]
        team2 = [p for p in players.values() if p["team"] == 0]

        # Team sizes (critical for filtering)
        features["team1_size"] = len(team1)
        features["team2_size"] = len(team2)

        # Ball position
        ball_pos = np.array([0.5, 0.5])  # Default field center
        
        # First check if any player has the ball
        for player_id, player in players.items():
            if player.get("has_ball", False):
                # If a player has the ball, use their position as ball position
                ball_pos = np.array(player["position_transformed"])
                break
                
        # If no player has the ball but there's a ball object, use its position
        if scene.get("ball") and not any(p.get("has_ball", False) for p in players.values()):
            ball = next(iter(scene["ball"].values()))
            ball_pos = np.array(ball["position_transformed"])
            
        features["ball_x"] = ball_pos[0]
        features["ball_y"] = ball_pos[1]

        features["team1_has_ball"] = False
        for player in team1:
            if player.get("has_ball", False):
                features["team1_has_ball"] = True
                break

        # Store player positions for matching
        features["team1_positions"] = np.array([p["position_transformed"] for p in team1]) if team1 else np.array([])
        features["team2_positions"] = np.array([p["position_transformed"] for p in team2]) if team2 else np.array([])

        return features
    
    def filter_scenes(self, query_feats, max_abs_dist=10):
        """Filter scenes in 2 stages:
        1. Exact team size match.
        2. Absolute position proximity (ball + centroids).
        """
        candidates = []

        # Stage 1: Team size matching
        for idx, scene_feats in self.features.items():
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

            if ball_dist <= max_abs_dist:
                filtered.append(idx)

        return filtered
    
    def calculate_player_matching_distance(self, query_positions, candidate_positions):
        """
        Calculate the minimum total distance when optimally matching players between two teams.
        Uses the Hungarian algorithm to find optimal assignment.
        Applies a proximity threshold to consider only close matches.
        """
        if len(query_positions) == 0 or len(candidate_positions) == 0:
            return 0
    
        if len(query_positions) != len(candidate_positions):
            return float('inf')
    
        # Calculate distance matrix between all query and candidate players
        distance_matrix = cdist(query_positions, candidate_positions, metric='euclidean')
    
        # Apply a proximity threshold - set very large distances for players far apart
        proximity_threshold = 10.0  # Adjust based on your data
        penalty_matrix = distance_matrix.copy()
        penalty_matrix[distance_matrix > proximity_threshold] = 1000.0  # Large penalty
    
        # Use Hungarian algorithm to find optimal assignment with the penalty matrix
        row_indices, col_indices = linear_sum_assignment(penalty_matrix)
    
        # Calculate total distance using the original distances
        matched_distances = distance_matrix[row_indices, col_indices]
    
        # Count how many matches exceed the threshold
        exceeding_threshold = matched_distances > proximity_threshold
        num_bad_matches = np.sum(exceeding_threshold)
    
        # Use original distances but apply penalties for bad matches
        total_distance = np.sum(matched_distances)
    
        # If too many bad matches, consider this a poor formation match
        if num_bad_matches > len(matched_distances) / 3:  # More than 1/3 are bad matches
            total_distance = float('inf')
    
        return total_distance
    
    def match_formations(self, query_feats, candidate_indices):
        """Match formations using player-to-player distance matching."""
        if not candidate_indices:
            return None

        query_team1_pos = query_feats["team1_positions"]
        query_team2_pos = query_feats["team2_positions"]
        
        best_match_id = None
        best_total_distance = float('inf')
        
        print(f"Matching against {len(candidate_indices)} candidates")
        
        for idx in candidate_indices:
            scene_feats = self.features[idx]
            candidate_team1_pos = scene_feats["team1_positions"]
            candidate_team2_pos = scene_feats["team2_positions"]
            
            # Calculate matching distance for team 1
            team1_distance = self.calculate_player_matching_distance(
                query_team1_pos, candidate_team1_pos
            )
            
            # Calculate matching distance for team 2
            team2_distance = self.calculate_player_matching_distance(
                query_team2_pos, candidate_team2_pos
            )
            
            # Total distance is sum of both teams
            total_distance = team1_distance + team2_distance
            
            print(f"Scene {idx}: Team1 dist={team1_distance:.3f}, Team2 dist={team2_distance:.3f}, Total={total_distance:.3f}")
            
            # Keep track of best match
            if total_distance < best_total_distance:
                best_total_distance = total_distance
                best_match_id = idx
        
        print(f"Best match: Scene {best_match_id} with total distance {best_total_distance:.3f}")
        return best_match_id
    
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
                
        return all_scenes, features_obj
    
    def get_sequence_from_match(self, initial_scene_id, query_scene):
            """Follow next_id pointers to get a sequence and match player IDs between query and matched scene"""
            sequence = []
            current_id = initial_scene_id
            
            # Get the matched scene (first scene in the sequence)
            matched_scene = None
            if current_id is not None:
                matched_scene = self.scenes[current_id]["original_scene"]
            
            # Collect the sequence
            while current_id is not None:
                scene = self.scenes[current_id]
                sequence.append(scene["original_scene"])
                current_id = scene.get("next_id", None)
            
            # Replace the initial scene with the query scene, but preserve player IDs
            if sequence and matched_scene:
                # Create a deep copy of the query scene to avoid modifying the original
                modified_query = json.loads(json.dumps(query_scene))
                
                # Separate players by team
                query_team1_players = []
                query_team2_players = []
                for player_id, player in query_scene.get("players", {}).items():
                    if "position_transformed" in player:
                        if player["team"] == 1:
                            query_team1_players.append({
                                "id": player_id,
                                "position_tranformed": np.array(player["position_transformed"]),
                                "player": player
                            })
                        else:  # team == 0
                            query_team2_players.append({
                                "id": player_id,
                                "position_tranformed": np.array(player["position_transformed"]),
                                "player": player
                            })
                
                matched_team1_players = []
                matched_team2_players = []
                for player_id, player in matched_scene.get("players", {}).items():
                    if "position_transformed" in player:
                        if player["team"] == 1:
                            matched_team1_players.append({
                                "id": player_id,
                                "position_tranformed": np.array(player["position_transformed"]),
                                "player": player
                            })
                        else:  # team == 0
                            matched_team2_players.append({
                                "id": player_id,
                                "position_tranformed": np.array(player["position_transformed"]),
                                "player": player
                            })
                
                # Initialize the new players dictionary
                new_players = {}
                
                # Match team 1 players
                if query_team1_players and matched_team1_players:
                    # Calculate distance matrix for team 1
                    query_team1_positions = np.array([p["position_tranformed"] for p in query_team1_players])
                    matched_team1_positions = np.array([p["position_tranformed"] for p in matched_team1_players])
                    
                    team1_distance_matrix = cdist(query_team1_positions, matched_team1_positions, metric='euclidean')
                    
                    # Use Hungarian algorithm for team 1
                    team1_row_indices, team1_col_indices = linear_sum_assignment(team1_distance_matrix)
                    
                    # Create mapping for team 1 players
                    for query_idx, matched_idx in zip(team1_row_indices, team1_col_indices):
                        if query_idx < len(query_team1_players) and matched_idx < len(matched_team1_players):
                            query_player_id = query_team1_players[query_idx]["id"]
                            matched_player_id = matched_team1_players[matched_idx]["id"]
                            # Use the matched scene's player ID for this query player
                            new_players[matched_player_id] = query_team1_players[query_idx]["player"]
                
                # Match team 2 players
                if query_team2_players and matched_team2_players:
                    # Calculate distance matrix for team 2
                    query_team2_positions = np.array([p["position_tranformed"] for p in query_team2_players])
                    matched_team2_positions = np.array([p["position_tranformed"] for p in matched_team2_players])
                    
                    team2_distance_matrix = cdist(query_team2_positions, matched_team2_positions, metric='euclidean')
                    
                    # Use Hungarian algorithm for team 2
                    team2_row_indices, team2_col_indices = linear_sum_assignment(team2_distance_matrix)
                    
                    # Create mapping for team 2 players
                    for query_idx, matched_idx in zip(team2_row_indices, team2_col_indices):
                        if query_idx < len(query_team2_players) and matched_idx < len(matched_team2_players):
                            query_player_id = query_team2_players[query_idx]["id"]
                            matched_player_id = matched_team2_players[matched_idx]["id"]
                            # Use the matched scene's player ID for this query player
                            new_players[matched_player_id] = query_team2_players[query_idx]["player"]
                
                # Handle extra players from matched scene that weren't matched
                matched_used_ids = set(new_players.keys())
                
                # Add unmatched team 1 players from matched scene
                for player_info in matched_team1_players:
                    player_id = player_info["id"]
                    if player_id not in matched_used_ids:
                        new_players[player_id] = player_info["player"]
                
                # Add unmatched team 2 players from matched scene
                for player_info in matched_team2_players:
                    player_id = player_info["id"]
                    if player_id not in matched_used_ids:
                        new_players[player_id] = player_info["player"]
                
                # Replace the players in the modified query
                modified_query["players"] = new_players
                
                # Preserve the action from the matched scene instead of the query scene
                if "action" in matched_scene:
                    modified_query["action"] = matched_scene["action"]
                
                # Preserve other scene elements (referees, ball, goalkeeper, goalpost)
                # These come from the query scene
                print("Preserving other scene elements from query scene")
                print("Query scene:", modified_query)
                # Replace the first scene in the sequence with the modified query
                sequence[0] = modified_query
            
            return sequence

# Initialize with your training data
# scenes=load_sequences_from_json("db.json")
# scenes = [load_sequences_from_json("AI_2.json")]
scenes = load_sequences_from_json("dbz.json")  # Load your actual training sequences
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
        
        # Convert NumPy arrays to Python lists for JSON serialization
        serializable_first_scenes = convert_numpy(first_scenes)
        
        return jsonify({"first_scenes": serializable_first_scenes, "count": len(serializable_first_scenes)}), 200
    except Exception as e:
        print(f"Error in get_all_first_scenes: {str(e)}")  # Add debugging
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
        input_scene = data.get('scene')
        
        if not input_scene:
            return jsonify({"error": "No scene provided"}), 400
        
        # 1. Extract features from input scene
        query_feats = matcher.extract_features(input_scene)
        
        # 2. Filter candidate scenes
        candidates = matcher.filter_scenes(query_feats)
        print("Filtered candidates:", candidates)
        
        # 3. Find best match using player-to-player matching
        matched_id = matcher.match_formations(query_feats, candidates)
        print("Matched ID:", matched_id)
        if matched_id is None:
            return jsonify({"error": "No matching scene found"}), 404
        
        # 4. Get the sequence
        sequence = matcher.get_sequence_from_match(matched_id, input_scene)
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